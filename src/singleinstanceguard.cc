#include "singleinstanceguard.h"

#include <QDir>
#include <QFile>
#include <QSocketNotifier>
#include <QStandardPaths>

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#else
#include <cerrno>
#include <fcntl.h>
#include <signal.h>
#include <unistd.h>
#endif

namespace {
#ifndef Q_OS_WIN
int g_activationPipe[2] = {-1, -1};

void handleActivationSignal(int)
{
    const char token = 1;
    if (g_activationPipe[1] != -1) {
        const ssize_t written = ::write(g_activationPipe[1], &token, sizeof(token));
        Q_UNUSED(written);
    }
}
#endif

bool processExists(qint64 pid)
{
    if (pid <= 0) {
        return false;
    }

#ifdef Q_OS_WIN
    HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, static_cast<DWORD>(pid));
    if (!process) {
        return GetLastError() == ERROR_ACCESS_DENIED;
    }

    const DWORD waitResult = WaitForSingleObject(process, 0);
    CloseHandle(process);
    return waitResult == WAIT_TIMEOUT;
#else
    if (::kill(static_cast<pid_t>(pid), 0) == 0) {
        return true;
    }
    return errno == EPERM;
#endif
}
} // namespace

SingleInstanceGuard::SingleInstanceGuard(QObject *parent)
    : QObject(parent)
    , m_lockFile(lockFilePath())
{
    m_lockFile.setStaleLockTime(0);
}

SingleInstanceGuard::~SingleInstanceGuard()
{
    release();
}

bool SingleInstanceGuard::start()
{
    installActivationHandler();

    if (m_lockFile.tryLock(0)) {
        return true;
    }

    if (requestActivationFromLock()) {
        return false;
    }

    if (!clearInactiveLock()) {
        return false;
    }

    if (!m_lockFile.tryLock(0)) {
        return false;
    }

    return true;
}

void SingleInstanceGuard::release()
{
    if (m_lockFile.isLocked()) {
        m_lockFile.unlock();
    }
}

bool SingleInstanceGuard::clearInactiveLock()
{
    qint64 pid = 0;
    QString hostname;
    QString appname;
    if (m_lockFile.getLockInfo(&pid, &hostname, &appname) && processExists(pid)) {
        return false;
    }

    return QFile::remove(m_lockFile.fileName()) || !QFile::exists(m_lockFile.fileName());
}

void SingleInstanceGuard::installActivationHandler()
{
#ifndef Q_OS_WIN
    if (m_activationNotifier) {
        return;
    }

    if (g_activationPipe[0] == -1 || g_activationPipe[1] == -1) {
        if (::pipe(g_activationPipe) != 0) {
            return;
        }

        const int readFlags = ::fcntl(g_activationPipe[0], F_GETFL, 0);
        if (readFlags != -1) {
            ::fcntl(g_activationPipe[0], F_SETFL, readFlags | O_NONBLOCK);
        }
        const int writeFlags = ::fcntl(g_activationPipe[1], F_GETFL, 0);
        if (writeFlags != -1) {
            ::fcntl(g_activationPipe[1], F_SETFL, writeFlags | O_NONBLOCK);
        }
    }

    struct sigaction action;
    action.sa_handler = handleActivationSignal;
    sigemptyset(&action.sa_mask);
    action.sa_flags = SA_RESTART;
    sigaction(SIGUSR1, &action, nullptr);

    m_activationNotifier = new QSocketNotifier(g_activationPipe[0], QSocketNotifier::Read, this);
    connect(m_activationNotifier, &QSocketNotifier::activated, this, [this] {
        char buffer[32];
        while (::read(g_activationPipe[0], buffer, sizeof(buffer)) > 0) {
        }
        emit activationRequested();
    });
#endif
}

bool SingleInstanceGuard::requestActivationFromLock() const
{
    qint64 pid = 0;
    QString hostname;
    QString appname;
    if (!m_lockFile.getLockInfo(&pid, &hostname, &appname) || !processExists(pid)) {
        return false;
    }

#ifdef Q_OS_WIN
    return false;
#else
    return ::kill(static_cast<pid_t>(pid), SIGUSR1) == 0;
#endif
}

QString SingleInstanceGuard::runtimePath(const QString &fileName)
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (path.isEmpty()) {
        path = QDir::tempPath();
    }

    QDir runtimeDir(path);
    runtimeDir.mkpath(QStringLiteral("."));
    return runtimeDir.absoluteFilePath(fileName);
}

QString SingleInstanceGuard::lockFilePath()
{
    return runtimePath(QStringLiteral("loom-desktop.lock"));
}
