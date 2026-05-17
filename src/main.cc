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

#ifndef LOOM_QML_MODULE_URI
#define LOOM_QML_MODULE_URI "LoomQML"
#endif

namespace {
constexpr int kInstanceWaitMs = 350;

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
    });

    QObject::connect(&profileManager, &ProfileManager::selectedProfileIndexChanged, &settingsManager, [&profileManager, &settingsManager] {
        const QVariantMap profile = profileManager.currentProfile();
        settingsManager.setSelectedProfileFolder(profile.value(QStringLiteral("folderName")).toString());
    });

    QObject::connect(&profileManager, &ProfileManager::currentProfileChanged, &settingsManager, [&profileManager, &settingsManager] {
        const QVariantMap profile = profileManager.currentProfile();
        settingsManager.setSelectedProfileFolder(profile.value(QStringLiteral("folderName")).toString());
    });

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

    const auto rebuildProfilesMenu = [&profileManager, &settingsManager, profilesMenu] {
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

    rebuildProfilesMenu();

    QObject::connect(showAction, &QAction::triggered, &app, showMainWindow);
    QObject::connect(profilesMenu, &QMenu::aboutToShow, &app, rebuildProfilesMenu);
    QObject::connect(&profileManager, &ProfileManager::profilesChanged, &app, rebuildProfilesMenu);
    QObject::connect(&profileManager, &ProfileManager::selectedProfileIndexChanged, &app, rebuildProfilesMenu);

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
