#include "proxyserver.h"

#include "profilemanager.h"
#include "settingsmanager.h"

#include <QHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QJsonValue>
#include <QMetaObject>
#include <QNetworkAccessManager>
#include <QNetworkProxy>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QPointer>
#include <QSet>
#include <QTcpServer>
#include <QTcpSocket>
#include <QUrl>

namespace {
QByteArray reasonPhrase(int statusCode)
{
    switch (statusCode) {
    case 200:
        return "OK";
    case 400:
        return "Bad Request";
    case 502:
        return "Bad Gateway";
    case 503:
        return "Service Unavailable";
    default:
        return "Error";
    }
}

bool isHopByHopHeader(const QByteArray &name)
{
    const QByteArray lower = name.toLower();
    return lower == "connection"
        || lower == "content-length"
        || lower == "host"
        || lower == "keep-alive"
        || lower == "proxy-authenticate"
        || lower == "proxy-authorization"
        || lower == "te"
        || lower == "trailer"
        || lower == "transfer-encoding"
        || lower == "upgrade";
}

bool isProxyManagedHeader(const QByteArray &name)
{
    const QByteArray lower = name.toLower();
    return lower == "authorization"
        || lower == "x-api-key";
}

QByteArray statusLine(int statusCode)
{
    return QByteArrayLiteral("HTTP/1.1 ") + QByteArray::number(statusCode) + QByteArrayLiteral(" ") + reasonPhrase(statusCode) + QByteArrayLiteral("\r\n");
}

QByteArray jsonErrorBody(const QByteArray &message)
{
    QByteArray escaped = message;
    escaped.replace('\\', "\\\\");
    escaped.replace('"', "\\\"");
    return QByteArrayLiteral("{\"error\":\"") + escaped + QByteArrayLiteral("\"}");
}

QUrl upstreamUrl(QString baseUrl, const QString &target)
{
    baseUrl = baseUrl.trimmed();
    while (baseUrl.endsWith(QLatin1Char('/'))) {
        baseUrl.chop(1);
    }

    QUrl targetUrl(target);
    QString path = targetUrl.path().startsWith(QLatin1Char('/')) ? targetUrl.path() : QStringLiteral("/") + targetUrl.path();
    if (path == QStringLiteral("/v1")) {
        path = QStringLiteral("/");
    } else if (path.startsWith(QStringLiteral("/v1/"))) {
        path = path.mid(3);
    }

    QUrl url(baseUrl + path);
    url.setQuery(targetUrl.query());
    return url;
}

QNetworkProxy proxyFromUrl(const QString &value)
{
    const QUrl url(value.trimmed());
    if (!url.isValid() || url.host().isEmpty()) {
        return QNetworkProxy::NoProxy;
    }

    QNetworkProxy proxy(url.scheme().compare(QStringLiteral("socks5"), Qt::CaseInsensitive) == 0
                            ? QNetworkProxy::Socks5Proxy
                            : QNetworkProxy::HttpProxy,
                        url.host(),
                        static_cast<quint16>(url.port(0)),
                        url.userName(),
                        url.password());
    return proxy.port() == 0 ? QNetworkProxy::NoProxy : proxy;
}

QString listenUrlForPort(int port)
{
    return QStringLiteral("http://127.0.0.1:%1/v1").arg(port);
}

QString profileSignature(const QVariantMap &profile)
{
    return QStringList {
        profile.value(QStringLiteral("name")).toString(),
        profile.value(QStringLiteral("model")).toString(),
        profile.value(QStringLiteral("reasoningEffort")).toString(),
        profile.value(QStringLiteral("baseUrl")).toString(),
        profile.value(QStringLiteral("apiKey")).toString(),
        profile.value(QStringLiteral("httpProxy")).toString(),
        profile.value(QStringLiteral("httpsProxy")).toString(),
        profile.value(QStringLiteral("disableResponseStorage")).toString(),
        profile.value(QStringLiteral("wireApi")).toString(),
        profile.value(QStringLiteral("requiresOpenAiAuth")).toString()
    }.join(QLatin1Char('\n'));
}
}

class ProxyWorker : public QObject
{
    Q_OBJECT

public:
    explicit ProxyWorker(QObject *parent = nullptr)
        : QObject(parent)
    {
    }

public slots:
    void configure(bool enabled, int port, const QVariantMap &profile)
    {
        m_enabled = enabled;
        m_requestedPort = port;
        m_profile = profile;

        if (!m_enabled) {
            stop(QStringLiteral("Loom proxy disabled"));
            return;
        }

        if (m_server && m_boundPort == m_requestedPort) {
            publishState(QStringLiteral("Loom proxy listening on %1").arg(listenUrlForPort(m_boundPort)));
            return;
        }

        stop(QString());
        start();
    }

    void shutdown()
    {
        stop(QStringLiteral("Loom proxy disabled"));
    }

signals:
    void stateChanged(bool running, int boundPort, const QString &statusMessage);

private:
    struct ClientRequest
    {
        QByteArray buffer;
        QByteArray method;
        QString target;
        QList<QPair<QByteArray, QByteArray>> headers;
        QByteArray body;
        qsizetype contentLength = 0;
        bool headerParsed = false;
    };

    struct PendingReply
    {
        QPointer<QTcpSocket> socket;
        bool headerWritten = false;
    };

    static constexpr qint64 kReplyReadChunkSize = 32 * 1024;
    static constexpr qint64 kSocketWriteBufferLimit = 256 * 1024;

    void start()
    {
        m_server = new QTcpServer(this);
        connect(m_server, &QTcpServer::newConnection, this, &ProxyWorker::acceptConnection);

        const quint16 requestedPort = static_cast<quint16>(m_requestedPort);
        if (!m_server->listen(QHostAddress::LocalHost, requestedPort)) {
            delete m_server;
            m_server = nullptr;
            m_boundPort = 0;
            publishState(QStringLiteral("Failed to start Loom proxy on port %1").arg(requestedPort));
            return;
        }

        m_boundPort = m_server->serverPort();
        publishState(QStringLiteral("Loom proxy listening on %1").arg(listenUrlForPort(m_boundPort)));
    }

    void stop(const QString &statusMessage)
    {
        for (QNetworkReply *reply : m_pending.keys()) {
            reply->abort();
            reply->deleteLater();
        }
        m_pending.clear();

        for (QTcpSocket *socket : m_clients.keys()) {
            socket->disconnectFromHost();
            socket->deleteLater();
        }
        m_clients.clear();

        delete m_server;
        m_server = nullptr;
        m_boundPort = 0;

        if (!statusMessage.isEmpty()) {
            publishState(statusMessage);
        }
    }

    void acceptConnection()
    {
        while (m_server && m_server->hasPendingConnections()) {
            QTcpSocket *socket = m_server->nextPendingConnection();
            m_clients.insert(socket, ClientRequest());
            connect(socket, &QTcpSocket::readyRead, this, [this, socket] {
                readClient(socket);
            });
            connect(socket, &QTcpSocket::disconnected, this, [this, socket] {
                m_clients.remove(socket);
                for (QNetworkReply *reply : m_pending.keys()) {
                    if (m_pending.value(reply).socket == socket) {
                        m_pending[reply].socket.clear();
                    }
                }
                socket->deleteLater();
            });
        }
    }

    void readClient(QTcpSocket *socket)
    {
        if (!m_clients.contains(socket)) {
            return;
        }

        ClientRequest &request = m_clients[socket];
        request.buffer += socket->readAll();
        if (!parseClientRequest(socket, &request)) {
            return;
        }

        if (m_profile.isEmpty()) {
            writeError(socket, 503, QByteArrayLiteral("No active Loom profile"));
            return;
        }

        forwardRequest(socket, request);
        m_clients.remove(socket);
    }

    bool parseClientRequest(QTcpSocket *socket, ClientRequest *request)
    {
        if (!request->headerParsed) {
            const qsizetype headerEnd = request->buffer.indexOf("\r\n\r\n");
            if (headerEnd < 0) {
                return false;
            }

            const QList<QByteArray> lines = request->buffer.left(headerEnd).split('\n');
            if (lines.isEmpty()) {
                writeError(socket, 400, QByteArrayLiteral("Malformed request"));
                return false;
            }

            const QList<QByteArray> requestLine = lines.first().trimmed().split(' ');
            if (requestLine.size() < 2) {
                writeError(socket, 400, QByteArrayLiteral("Malformed request line"));
                return false;
            }

            request->method = requestLine.at(0).trimmed().toUpper();
            request->target = QString::fromUtf8(requestLine.at(1).trimmed());
            for (int i = 1; i < lines.size(); ++i) {
                const QByteArray line = lines.at(i).trimmed();
                const qsizetype colon = line.indexOf(':');
                if (colon <= 0) {
                    continue;
                }

                const QByteArray name = line.left(colon).trimmed();
                const QByteArray value = line.mid(colon + 1).trimmed();
                if (name.compare("content-length", Qt::CaseInsensitive) == 0) {
                    request->contentLength = value.toLongLong();
                }
                request->headers.append({name, value});
            }

            request->body = request->buffer.mid(headerEnd + 4);
            request->buffer.clear();
            request->headerParsed = true;
        } else {
            request->body += request->buffer;
            request->buffer.clear();
        }

        return request->body.size() >= request->contentLength;
    }

    void forwardRequest(QTcpSocket *socket, const ClientRequest &request)
    {
        ensureNetworkManager();

        const QString baseUrl = m_profile.value(QStringLiteral("baseUrl")).toString();
        if (baseUrl.trimmed().isEmpty()) {
            writeError(socket, 502, QByteArrayLiteral("Active profile has no base URL"));
            return;
        }

        QNetworkRequest upstreamRequest(upstreamUrl(baseUrl, request.target));
        for (const auto &header : request.headers) {
            if (!isHopByHopHeader(header.first) && !isProxyManagedHeader(header.first)) {
                upstreamRequest.setRawHeader(header.first, header.second);
            }
        }

        const QString apiKey = m_profile.value(QStringLiteral("apiKey")).toString();
        if (!apiKey.isEmpty()) {
            upstreamRequest.setRawHeader("Authorization", QByteArrayLiteral("Bearer ") + apiKey.toUtf8());
        }
        upstreamRequest.setRawHeader("Host", upstreamRequest.url().host().toUtf8());

        const QString proxyUrl = m_profile.value(QStringLiteral("httpsProxy")).toString().trimmed().isEmpty()
                                     ? m_profile.value(QStringLiteral("httpProxy")).toString()
                                     : m_profile.value(QStringLiteral("httpsProxy")).toString();
        m_network->setProxy(proxyFromUrl(proxyUrl));

        QNetworkReply *reply = m_network->sendCustomRequest(upstreamRequest, request.method, rewriteJsonBody(request.body));
        m_pending.insert(reply, {socket, false});
        connect(reply, &QNetworkReply::readyRead, this, [this, reply] {
            PendingReply *pending = m_pending.contains(reply) ? &m_pending[reply] : nullptr;
            if (!pending || !pending->socket) {
                return;
            }
            drainReply(reply, pending);
        });
        connect(reply, &QNetworkReply::finished, this, [this, reply] {
            finishReply(reply);
        });
    }

    QByteArray rewriteJsonBody(const QByteArray &body) const
    {
        if (body.trimmed().isEmpty()) {
            return body;
        }

        QJsonParseError error;
        const QJsonDocument document = QJsonDocument::fromJson(body, &error);
        if (error.error != QJsonParseError::NoError || !document.isObject()) {
            return body;
        }

        QJsonObject object = document.object();
        bool changed = false;

        const QString model = m_profile.value(QStringLiteral("model")).toString().trimmed();
        if (!model.isEmpty() && object.contains(QStringLiteral("model")) && object.value(QStringLiteral("model")).toString() != model) {
            object.insert(QStringLiteral("model"), model);
            changed = true;
        }

        const QString reasoningEffort = m_profile.value(QStringLiteral("reasoningEffort")).toString().trimmed();
        if (!reasoningEffort.isEmpty()) {
            if (object.value(QStringLiteral("reasoning")).isObject()) {
                QJsonObject reasoning = object.value(QStringLiteral("reasoning")).toObject();
                if (reasoning.value(QStringLiteral("effort")).toString() != reasoningEffort) {
                    reasoning.insert(QStringLiteral("effort"), reasoningEffort);
                    object.insert(QStringLiteral("reasoning"), reasoning);
                    changed = true;
                }
            }

            if (object.contains(QStringLiteral("reasoning_effort"))
                && object.value(QStringLiteral("reasoning_effort")).toString() != reasoningEffort) {
                object.insert(QStringLiteral("reasoning_effort"), reasoningEffort);
                changed = true;
            }
        }

        if (object.contains(QStringLiteral("store"))) {
            const bool nextStore = !m_profile.value(QStringLiteral("disableResponseStorage")).toBool();
            if (!object.value(QStringLiteral("store")).isBool() || object.value(QStringLiteral("store")).toBool() != nextStore) {
                object.insert(QStringLiteral("store"), nextStore);
                changed = true;
            }
        }

        return changed ? QJsonDocument(object).toJson(QJsonDocument::Compact) : body;
    }

    void writeError(QTcpSocket *socket, int statusCode, const QByteArray &message)
    {
        const QByteArray body = jsonErrorBody(message);
        socket->write(statusLine(statusCode));
        socket->write(QByteArrayLiteral("Content-Type: application/json\r\n"));
        socket->write(QByteArrayLiteral("Content-Length: ") + QByteArray::number(body.size()) + QByteArrayLiteral("\r\n"));
        socket->write(QByteArrayLiteral("Connection: close\r\n\r\n"));
        socket->write(body);
        socket->disconnectFromHost();
        m_clients.remove(socket);
    }

    void writeReplyHeaders(QNetworkReply *reply, PendingReply *pending)
    {
        if (pending->headerWritten || !pending->socket) {
            return;
        }

        const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        pending->socket->write(statusLine(statusCode > 0 ? statusCode : 502));

        bool hasContentType = false;
        for (const QNetworkReply::RawHeaderPair &header : reply->rawHeaderPairs()) {
            if (isHopByHopHeader(header.first)) {
                continue;
            }
            if (header.first.compare("content-type", Qt::CaseInsensitive) == 0) {
                hasContentType = true;
            }
            pending->socket->write(header.first + QByteArrayLiteral(": ") + header.second + QByteArrayLiteral("\r\n"));
        }
        if (!hasContentType) {
            pending->socket->write(QByteArrayLiteral("Content-Type: application/json\r\n"));
        }
        pending->socket->write(QByteArrayLiteral("Connection: close\r\n\r\n"));
        pending->headerWritten = true;
    }

    void finishReply(QNetworkReply *reply)
    {
        PendingReply pending = m_pending.take(reply);
        if (pending.socket) {
            drainReply(reply, &pending);
            pending.socket->disconnectFromHost();
        }
        reply->deleteLater();
    }

    void drainReply(QNetworkReply *reply, PendingReply *pending)
    {
        if (!pending || !pending->socket) {
            return;
        }

        writeReplyHeaders(reply, pending);
        if (pending->socket->bytesToWrite() >= kSocketWriteBufferLimit) {
            if (!m_pausedReplies.contains(reply)) {
                reply->setReadBufferSize(kSocketWriteBufferLimit);
                m_pausedReplies.insert(reply);
                connect(pending->socket, &QTcpSocket::bytesWritten, reply, [this, reply](qint64) {
                    PendingReply *pendingReply = m_pending.contains(reply) ? &m_pending[reply] : nullptr;
                    if (!pendingReply || !pendingReply->socket) {
                        m_pausedReplies.remove(reply);
                        return;
                    }
                    if (pendingReply->socket->bytesToWrite() <= kSocketWriteBufferLimit / 2) {
                        reply->setReadBufferSize(0);
                        m_pausedReplies.remove(reply);
                        drainReply(reply, pendingReply);
                    }
                }, Qt::SingleShotConnection);
            }
            return;
        }

        while (reply->bytesAvailable() > 0 && pending->socket->bytesToWrite() < kSocketWriteBufferLimit) {
            const qint64 capacity = kSocketWriteBufferLimit - pending->socket->bytesToWrite();
            const QByteArray chunk = reply->read(std::min(kReplyReadChunkSize, capacity));
            if (chunk.isEmpty()) {
                break;
            }
            pending->socket->write(chunk);
        }

        if (reply->bytesAvailable() > 0) {
            drainReply(reply, pending);
        }
    }

    void publishState(const QString &statusMessage)
    {
        if (m_lastPublishedRunning == (m_server != nullptr)
            && m_lastPublishedPort == m_boundPort
            && m_lastPublishedStatus == statusMessage) {
            return;
        }

        m_lastPublishedRunning = m_server != nullptr;
        m_lastPublishedPort = m_boundPort;
        m_lastPublishedStatus = statusMessage;
        emit stateChanged(m_server != nullptr, m_boundPort, statusMessage);
    }

    void ensureNetworkManager()
    {
        if (!m_network) {
            m_network = new QNetworkAccessManager(this);
        }
    }

    bool m_enabled = false;
    int m_requestedPort = 14567;
    int m_boundPort = 0;
    QVariantMap m_profile;
    QTcpServer *m_server = nullptr;
    QNetworkAccessManager *m_network = nullptr;
    QHash<QTcpSocket *, ClientRequest> m_clients;
    QHash<QNetworkReply *, PendingReply> m_pending;
    QSet<QNetworkReply *> m_pausedReplies;
    bool m_lastPublishedRunning = false;
    int m_lastPublishedPort = 0;
    QString m_lastPublishedStatus;
};

ProxyServer::ProxyServer(ProfileManager *profileManager, SettingsManager *settingsManager, QObject *parent)
    : QObject(parent)
    , m_profileManager(profileManager)
    , m_settingsManager(settingsManager)
    , m_worker(new ProxyWorker())
{
    m_worker->moveToThread(&m_workerThread);

    connect(&m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);
    connect(m_worker, &ProxyWorker::stateChanged, this, &ProxyServer::applyWorkerState, Qt::QueuedConnection);

    connect(m_settingsManager, &SettingsManager::loomProxyEnabledChanged, this, &ProxyServer::reconcile);
    connect(m_settingsManager, &SettingsManager::loomProxyPortChanged, this, &ProxyServer::reconcile);
    connect(m_settingsManager, &SettingsManager::activeProfileFolderChanged, this, &ProxyServer::reconcile);
    connect(m_profileManager, &ProfileManager::currentProfileChanged, this, &ProxyServer::reconcile);
    connect(m_profileManager, &ProfileManager::profilesChanged, this, &ProxyServer::reconcile);

    m_workerThread.start(QThread::LowPriority);
}

ProxyServer::~ProxyServer()
{
    if (m_worker) {
        QMetaObject::invokeMethod(m_worker, "shutdown", Qt::BlockingQueuedConnection);
    }
    m_workerThread.quit();
    m_workerThread.wait();
}

bool ProxyServer::running() const
{
    return m_running;
}

QString ProxyServer::statusMessage() const
{
    return m_statusMessage;
}

QString ProxyServer::listenUrl() const
{
    return listenUrlForPort(m_running ? m_boundPort : m_settingsManager->loomProxyPort());
}

void ProxyServer::reconcile()
{
    const bool enabled = m_settingsManager->loomProxyEnabled();
    const int port = m_settingsManager->loomProxyPort();
    const QVariantMap profile = enabled ? m_profileManager->activeProfileProxyConfig() : QVariantMap();
    const QString signature = QStringLiteral("%1|%2|%3").arg(enabled).arg(port).arg(profileSignature(profile));
    if (signature == m_configurationSignature) {
        return;
    }
    m_configurationSignature = signature;

    QMetaObject::invokeMethod(m_worker,
                              "configure",
                              Qt::QueuedConnection,
                              Q_ARG(bool, enabled),
                              Q_ARG(int, port),
                              Q_ARG(QVariantMap, profile));
}

void ProxyServer::applyWorkerState(bool running, int boundPort, const QString &statusMessage)
{
    const bool listenChanged = m_boundPort != boundPort;
    m_boundPort = boundPort;
    setRunning(running);
    setStatusMessage(statusMessage);

    if (listenChanged) {
        emit this->listenChanged();
    }
}

void ProxyServer::setRunning(bool running)
{
    if (m_running == running) {
        return;
    }

    m_running = running;
    emit runningChanged();
    emit listenChanged();
}

void ProxyServer::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message) {
        return;
    }

    m_statusMessage = message;
    emit statusMessageChanged();
}

#include "proxyserver.moc"
