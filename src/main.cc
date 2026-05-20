#include <QCoreApplication>
#include <QApplication>
#include <QIcon>
#include <QProcess>
#include <QString>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QVariantMap>
#include <QWindow>

#include "profilemanager.h"
#include "proxyserver.h"
#include "settingsmanager.h"
#include "singleinstanceguard.h"
#include "traycontroller.h"

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

bool hasArgument(int argc, char *argv[], const QString &argument)
{
    for (int i = 1; i < argc; ++i) {
        if (QString::fromLocal8Bit(argv[i]) == argument) {
            return true;
        }
    }
    return false;
}
} // namespace

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

    SingleInstanceGuard instanceGuard;
    if (!instanceGuard.start()) {
        return 0;
    }

    ProfileManager profileManager;
    SettingsManager settingsManager;
    profileManager.setCodexRoutesThroughLoom(settingsManager.codexRoutesThroughLoom());
    ProxyServer proxyServer(&profileManager, &settingsManager);
    profileManager.setActiveProfileByFolderName(settingsManager.activeProfileFolder());
    profileManager.selectProfileByFolderName(settingsManager.selectedProfileFolder());
    proxyServer.reconcile();
    if (settingsManager.restoreLastSection()) {
        profileManager.setActiveSection(settingsManager.lastSection());
    }

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("profileManager"), &profileManager);
    engine.rootContext()->setContextProperty(QStringLiteral("proxyServer"), &proxyServer);
    engine.rootContext()->setContextProperty(QStringLiteral("settingsManager"), &settingsManager);

    QObject::connect(
        &profileManager,
        &ProfileManager::activeSectionChanged,
        &settingsManager,
        [&profileManager, &settingsManager] {
            if (settingsManager.restoreLastSection()) {
                settingsManager.setLastSection(profileManager.activeSection());
            }
        },
        Qt::QueuedConnection);

    QObject::connect(&settingsManager, &SettingsManager::codexRoutesThroughLoomChanged, &profileManager, [&profileManager, &settingsManager] {
        profileManager.setCodexRoutesThroughLoom(settingsManager.codexRoutesThroughLoom());
    });

    QObject::connect(
        &profileManager, &ProfileManager::currentProfileChanged, &settingsManager, [&profileManager, &settingsManager] {
            const QVariantMap profile = profileManager.currentProfile();
            const QString folderName = profile.value(QStringLiteral("folderName")).toString();
            settingsManager.setSelectedProfileFolder(folderName);
            if (profile.value(QStringLiteral("active")).toBool()) {
                settingsManager.setActiveProfileFolder(folderName);
            }
        },
        Qt::QueuedConnection);

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
    QObject::connect(&instanceGuard, &SingleInstanceGuard::activationRequested, &app, showMainWindow);

    TrayController trayController(appIcon, &settingsManager);
    trayController.setMainWindow(mainWindow);
    app.setQuitOnLastWindowClosed(!trayController.isAvailable());

    QObject::connect(&trayController, &TrayController::restartRequested, &app, [&app, &instanceGuard] {
        QStringList arguments = QCoreApplication::arguments();
        if (!arguments.isEmpty()) {
            arguments.removeFirst();
        }

        instanceGuard.release();
        QProcess::startDetached(QCoreApplication::applicationFilePath(), arguments);
        app.quit();
    });

    QObject::connect(&trayController, &TrayController::quitRequested, &app, &QCoreApplication::quit);

    if (trayController.isAvailable()) {
        trayController.show();
    }

    return app.exec();
}
