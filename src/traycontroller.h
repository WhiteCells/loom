#pragma once

#include <QAction>
#include <QIcon>
#include <QMenu>
#include <QMetaObject>
#include <QObject>
#include <QPointer>
#include <QString>
#include <QSystemTrayIcon>
#include <QVector>
#include <QWindow>

class SettingsManager;

class TrayController : public QObject
{
    Q_OBJECT

public:
    explicit TrayController(const QIcon &appIcon, SettingsManager *settingsManager, QObject *parent = nullptr);

    bool isAvailable() const;
    void setMainWindow(QWindow *window);
    void show();

signals:
    void restartRequested();
    void quitRequested();

private:
    static QString menuStyle();

    QString text(const QString &key) const;
    bool isMainWindowShown() const;
    void showMainWindow();
    void toggleMainWindow();
    void updateText();
    void reconnectMainWindowSignals();

    SettingsManager *m_settingsManager = nullptr;
    QPointer<QWindow> m_mainWindow;
    QVector<QMetaObject::Connection> m_windowConnections;
    QMenu m_menu;
    QAction *m_visibilityAction = nullptr;
    QAction *m_restartAction = nullptr;
    QAction *m_quitAction = nullptr;
    QSystemTrayIcon m_trayIcon;
};
