#pragma once

#include <QLockFile>
#include <QObject>
#include <QString>

class QSocketNotifier;

class SingleInstanceGuard : public QObject
{
    Q_OBJECT

public:
    explicit SingleInstanceGuard(QObject *parent = nullptr);
    ~SingleInstanceGuard() override;

    bool start();
    void release();

signals:
    void activationRequested();

private:
    bool clearInactiveLock();
    void installActivationHandler();
    bool requestActivationFromLock() const;
    static QString runtimePath(const QString &fileName);
    static QString lockFilePath();

    QLockFile m_lockFile;
    QSocketNotifier *m_activationNotifier = nullptr;
};
