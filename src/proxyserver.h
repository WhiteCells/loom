#pragma once

#include <QObject>
#include <QThread>
#include <QVariantMap>

class ProfileManager;
class ProxyWorker;
class SettingsManager;

class ProxyServer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool running READ running NOTIFY runningChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(QString listenUrl READ listenUrl NOTIFY listenChanged)

public:
    explicit ProxyServer(ProfileManager *profileManager, SettingsManager *settingsManager, QObject *parent = nullptr);
    ~ProxyServer() override;

    bool running() const;
    QString statusMessage() const;
    QString listenUrl() const;

public slots:
    void reconcile();

signals:
    void runningChanged();
    void statusMessageChanged();
    void listenChanged();

private:
    void applyWorkerState(bool running, int boundPort, const QString &statusMessage);
    void setRunning(bool running);
    void setStatusMessage(const QString &message);

    ProfileManager *m_profileManager = nullptr;
    SettingsManager *m_settingsManager = nullptr;
    QThread m_workerThread;
    ProxyWorker *m_worker = nullptr;
    bool m_running = false;
    int m_boundPort = 0;
    QString m_configurationSignature;
    QString m_statusMessage;
};
