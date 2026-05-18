#include <QCoreApplication>
#include <QAction>
#include <QApplication>
#include <QDir>
#include <QIcon>
#include <QIODevice>
#include <QLocalServer>
#include <QLocalSocket>
#include <QMenu>
#include <QProcess>
#include <QStandardPaths>
#include <QString>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QSystemTrayIcon>
#include <QVariantList>
#include <QVariantMap>
#include <QWindow>

#include "profilemanager.h"
#include "settingsmanager.h"

#ifdef Q_OS_WIN
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <dwmapi.h>
#endif

#ifndef LOOM_QML_MODULE_URI
#define LOOM_QML_MODULE_URI "LoomQML"
#endif

namespace {
constexpr int kInstanceWaitMs = 350;

#ifdef Q_OS_WIN
#ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
#define DWMWA_USE_IMMERSIVE_DARK_MODE 20
#endif
#ifndef DWMWA_BORDER_COLOR
#define DWMWA_BORDER_COLOR 34
#endif
#ifndef DWMWA_CAPTION_COLOR
#define DWMWA_CAPTION_COLOR 35
#endif
#ifndef DWMWA_TEXT_COLOR
#define DWMWA_TEXT_COLOR 36
#endif

void applyWindowsTitleBarTheme(QWindow *window, bool dark)
{
    if (!window) {
        return;
    }

    const HWND hwnd = reinterpret_cast<HWND>(window->winId());
    if (!hwnd) {
        return;
    }

    const BOOL useDarkMode = dark ? TRUE : FALSE;
    DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &useDarkMode, sizeof(useDarkMode));

    const COLORREF captionColor = dark ? RGB(0x1a, 0x20, 0x22) : RGB(0xf8, 0xfa, 0xf9);
    const COLORREF textColor = dark ? RGB(0xf2, 0xf6, 0xf7) : RGB(0x18, 0x21, 0x21);
    const COLORREF borderColor = dark ? RGB(0x30, 0x39, 0x3b) : RGB(0xcb, 0xd5, 0xd3);

    DwmSetWindowAttribute(hwnd, DWMWA_CAPTION_COLOR, &captionColor, sizeof(captionColor));
    DwmSetWindowAttribute(hwnd, DWMWA_TEXT_COLOR, &textColor, sizeof(textColor));
    DwmSetWindowAttribute(hwnd, DWMWA_BORDER_COLOR, &borderColor, sizeof(borderColor));
}
#else
void applyWindowsTitleBarTheme(QWindow *, bool)
{
}
#endif

QString singleInstanceRuntimePath(const QString &fileName)
{
    QString runtimePath = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (runtimePath.isEmpty()) {
        runtimePath = QDir::tempPath();
    }

    QDir runtimeDir(runtimePath);
    runtimeDir.mkpath(QStringLiteral("."));
    return runtimeDir.absoluteFilePath(fileName);
}

QString singleInstanceServerName()
{
#ifdef Q_OS_UNIX
    return singleInstanceRuntimePath(QStringLiteral("loom-desktop.sock"));
#else
    return QStringLiteral("LoomDesktop.SingleInstance");
#endif
}

bool notifyRunningInstance(const QString &serverName)
{
    QLocalSocket instanceSocket;
    instanceSocket.connectToServer(serverName, QIODevice::WriteOnly);
    if (!instanceSocket.waitForConnected(kInstanceWaitMs)) {
        return false;
    }

    instanceSocket.write("show");
    instanceSocket.flush();
    instanceSocket.waitForBytesWritten(kInstanceWaitMs);
    instanceSocket.disconnectFromServer();
    return true;
}

bool listenForSingleInstance(QLocalServer &server, const QString &serverName)
{
    server.setSocketOptions(QLocalServer::UserAccessOption);
    if (server.listen(serverName)) {
        return true;
    }

    if (notifyRunningInstance(serverName)) {
        return false;
    }

    QLocalServer::removeServer(serverName);
    return server.listen(serverName);
}

bool hasArgument(int argc, char *argv[], const QString &argument)
{
    for (int i = 1; i < argc; ++i) {
        if (QString::fromLocal8Bit(argv[i]) == argument) {
            return true;
        }
    }
    return false;
}
}

int main(int argc, char *argv[])
{
    if (hasArgument(argc, argv, QStringLiteral("--init-settings"))) {
        QCoreApplication app(argc, argv);
        QCoreApplication::setApplicationName(QStringLiteral("Loom"));
        QCoreApplication::setOrganizationName(QStringLiteral("Loom"));

        SettingsManager settingsManager;
        return settingsManager.save() ? 0 : 1;
    }

    QApplication app(argc, argv);
    QCoreApplication::setApplicationName(QStringLiteral("Loom"));
    QCoreApplication::setOrganizationName(QStringLiteral("Loom"));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const QIcon appIcon(QStringLiteral(":/assets/icons/loom-app.svg"));
    app.setWindowIcon(appIcon);

    const QString instanceServerName = singleInstanceServerName();
    QLocalServer instanceServer;
    if (!listenForSingleInstance(instanceServer, instanceServerName)) {
        return 0;
    }

    ProfileManager profileManager;
    SettingsManager settingsManager;
    profileManager.setActiveProfileByFolderName(settingsManager.activeProfileFolder());
    profileManager.selectProfileByFolderName(settingsManager.selectedProfileFolder());
    if (settingsManager.restoreLastSection()) {
        profileManager.setActiveSection(settingsManager.lastSection());
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("profileManager"), &profileManager);
    engine.rootContext()->setContextProperty(QStringLiteral("settingsManager"), &settingsManager);

    QObject::connect(&profileManager, &ProfileManager::activeSectionChanged, &settingsManager, [&profileManager, &settingsManager] {
        if (settingsManager.restoreLastSection()) {
            settingsManager.setLastSection(profileManager.activeSection());
        }
    }, Qt::QueuedConnection);

    QObject::connect(&profileManager, &ProfileManager::currentProfileChanged, &settingsManager, [&profileManager, &settingsManager] {
        const QVariantMap profile = profileManager.currentProfile();
        const QString folderName = profile.value(QStringLiteral("folderName")).toString();
        settingsManager.setSelectedProfileFolder(folderName);
        if (profile.value(QStringLiteral("active")).toBool()) {
            settingsManager.setActiveProfileFolder(folderName);
        }
    }, Qt::QueuedConnection);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        [] {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.loadFromModule(QStringLiteral(LOOM_QML_MODULE_URI), QStringLiteral("Main"));

    QWindow *mainWindow = engine.rootObjects().isEmpty()
                              ? nullptr
                              : qobject_cast<QWindow *>(engine.rootObjects().first());
    applyWindowsTitleBarTheme(mainWindow, settingsManager.darkTheme());

    if (mainWindow) {
        QObject::connect(&settingsManager, &SettingsManager::darkThemeChanged, mainWindow, [mainWindow, &settingsManager] {
            applyWindowsTitleBarTheme(mainWindow, settingsManager.darkTheme());
        });
    }

    const auto showMainWindow = [mainWindow] {
        if (!mainWindow) {
            return;
        }

        if (mainWindow->visibility() == QWindow::Minimized) {
            mainWindow->setVisibility(QWindow::Windowed);
        }
        mainWindow->show();
        mainWindow->raise();
        mainWindow->requestActivate();
    };

    const auto handleInstanceActivation = [&instanceServer, showMainWindow] {
        while (QLocalSocket *client = instanceServer.nextPendingConnection()) {
            client->readAll();
            showMainWindow();
            client->disconnectFromServer();
            client->deleteLater();
        }
    };

    QObject::connect(&instanceServer, &QLocalServer::newConnection, &app, handleInstanceActivation);
    handleInstanceActivation();

    const bool trayAvailable = QSystemTrayIcon::isSystemTrayAvailable();
    app.setQuitOnLastWindowClosed(!trayAvailable);

    QMenu trayMenu;
    const QString trayMenuStyle = QStringLiteral(R"(
        QMenu {
            padding: 7px 0;
        }
        QMenu::item {
            min-width: 184px;
            padding: 7px 36px 7px 18px;
        }
        QMenu::item:selected {
            background: rgba(14, 114, 240, 0.14);
        }
        QMenu::separator {
            height: 1px;
            margin: 6px 12px;
            background: rgba(127, 127, 127, 0.24);
        }
        QMenu::right-arrow {
            width: 12px;
            height: 12px;
            padding-right: 14px;
        }
        QMenu::indicator {
            width: 16px;
            height: 16px;
            left: 12px;
        }
    )");
    trayMenu.setStyleSheet(trayMenuStyle);

    QAction *showAction = trayMenu.addAction(QStringLiteral("Show Loom"));
    trayMenu.addSeparator();

    QMenu *profilesMenu = trayMenu.addMenu(QStringLiteral("Switch Profile"));
    profilesMenu->setStyleSheet(trayMenuStyle);
    trayMenu.addSeparator();

    QAction *restartAction = trayMenu.addAction(QStringLiteral("Restart"));
    QAction *quitAction = trayMenu.addAction(QStringLiteral("Quit Loom"));

    bool profilesMenuDirty = true;
    const auto rebuildProfilesMenu = [&profileManager, &settingsManager, profilesMenu, &profilesMenuDirty] {
        profilesMenuDirty = false;
        profilesMenu->clear();

        const QVariantList profiles = profileManager.profiles();
        if (profiles.isEmpty()) {
            QAction *emptyAction = profilesMenu->addAction(QStringLiteral("No profiles"));
            emptyAction->setEnabled(false);
            return;
        }

        for (const QVariant &item : profiles) {
            const QVariantMap profile = item.toMap();
            const QString name = profile.value(QStringLiteral("name")).toString();
            const QString provider = profile.value(QStringLiteral("modelProvider")).toString();
            const int index = profile.value(QStringLiteral("index")).toInt();

            QAction *profileAction = profilesMenu->addAction(QStringLiteral("%1  ·  %2").arg(name, provider));
            profileAction->setCheckable(true);
            profileAction->setChecked(profile.value(QStringLiteral("active")).toBool());

            QObject::connect(profileAction, &QAction::triggered, profilesMenu, [&profileManager, &settingsManager, index] {
                profileManager.selectProfile(index);
                const bool activated = profileManager.activateSelectedProfile();
                if (activated) {
                    settingsManager.setActiveProfileFolder(profileManager.currentProfile().value(QStringLiteral("folderName")).toString());
                }
                if (activated && settingsManager.healthCheckOnActivate()) {
                    profileManager.runHealthCheck();
                }
            });
        }
    };
    const auto markProfilesMenuDirty = [&profilesMenuDirty] {
        profilesMenuDirty = true;
    };

    rebuildProfilesMenu();

    QObject::connect(showAction, &QAction::triggered, &app, showMainWindow);
    QObject::connect(profilesMenu, &QMenu::aboutToShow, &app, [&rebuildProfilesMenu, &profilesMenuDirty] {
        if (profilesMenuDirty) {
            rebuildProfilesMenu();
        }
    });
    QObject::connect(&profileManager, &ProfileManager::profilesChanged, &app, markProfilesMenuDirty);

    QObject::connect(restartAction, &QAction::triggered, &app, [&app, &instanceServer, instanceServerName] {
        QStringList arguments = QCoreApplication::arguments();
        if (!arguments.isEmpty()) {
            arguments.removeFirst();
        }

        instanceServer.close();
        QLocalServer::removeServer(instanceServerName);
        QProcess::startDetached(QCoreApplication::applicationFilePath(), arguments);
        app.quit();
    });

    QObject::connect(quitAction, &QAction::triggered, &app, &QCoreApplication::quit);

    QSystemTrayIcon trayIcon(appIcon);
    trayIcon.setToolTip(QStringLiteral("Loom"));
    trayIcon.setContextMenu(&trayMenu);

    QObject::connect(&trayIcon, &QSystemTrayIcon::activated, &app, [showMainWindow](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
            showMainWindow();
        }
    });

    if (trayAvailable) {
        trayIcon.show();
    }

    return app.exec();
}
