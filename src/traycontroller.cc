#include "traycontroller.h"

#include "settingsmanager.h"

#include <utility>

TrayController::TrayController(const QIcon &appIcon, SettingsManager *settingsManager, QObject *parent)
    : QObject(parent)
    , m_settingsManager(settingsManager)
    , m_trayIcon(appIcon, this)
{
    m_menu.setStyleSheet(menuStyle());

    m_visibilityAction = m_menu.addAction(QString());
    m_menu.addSeparator();
    m_restartAction = m_menu.addAction(QString());
    m_quitAction = m_menu.addAction(QString());

    connect(m_visibilityAction, &QAction::triggered, this, &TrayController::toggleMainWindow);
    connect(m_restartAction, &QAction::triggered, this, &TrayController::restartRequested);
    connect(m_quitAction, &QAction::triggered, this, &TrayController::quitRequested);

    if (m_settingsManager) {
        connect(m_settingsManager, &SettingsManager::languageChanged, this, &TrayController::updateText);
    }

    m_trayIcon.setToolTip(QStringLiteral("Loom"));
    m_trayIcon.setContextMenu(&m_menu);
    connect(&m_trayIcon, &QSystemTrayIcon::activated, this, [this](QSystemTrayIcon::ActivationReason reason) {
        if (reason == QSystemTrayIcon::Trigger || reason == QSystemTrayIcon::DoubleClick) {
            toggleMainWindow();
        }
    });

    updateText();
}

bool TrayController::isAvailable() const
{
    return QSystemTrayIcon::isSystemTrayAvailable();
}

void TrayController::setMainWindow(QWindow *window)
{
    if (m_mainWindow == window) {
        return;
    }

    for (const QMetaObject::Connection &connection : std::as_const(m_windowConnections)) {
        disconnect(connection);
    }
    m_windowConnections.clear();

    m_mainWindow = window;
    reconnectMainWindowSignals();
    updateText();
}

void TrayController::show()
{
    m_trayIcon.show();
}

QString TrayController::menuStyle()
{
    return QStringLiteral(R"(
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
}

QString TrayController::text(const QString &key) const
{
    const QString language = m_settingsManager ? m_settingsManager->language() : QStringLiteral("en");
    if (language != QStringLiteral("zh")) {
        return key;
    }

    if (key == QStringLiteral("Show Interface")) {
        return QStringLiteral("显示界面");
    }
    if (key == QStringLiteral("Hide Interface")) {
        return QStringLiteral("隐藏界面");
    }
    if (key == QStringLiteral("Restart")) {
        return QStringLiteral("重启");
    }
    if (key == QStringLiteral("Quit")) {
        return QStringLiteral("退出");
    }
    return key;
}

bool TrayController::isMainWindowShown() const
{
    return m_mainWindow && m_mainWindow->isVisible() && m_mainWindow->visibility() != QWindow::Minimized;
}

void TrayController::showMainWindow()
{
    if (!m_mainWindow) {
        return;
    }

    if (m_mainWindow->visibility() == QWindow::Minimized) {
        m_mainWindow->setVisibility(QWindow::Windowed);
    }
    m_mainWindow->show();
    m_mainWindow->raise();
    m_mainWindow->requestActivate();
    updateText();
}

void TrayController::toggleMainWindow()
{
    if (!m_mainWindow) {
        return;
    }

    if (isMainWindowShown()) {
        m_mainWindow->hide();
    } else {
        showMainWindow();
    }
    updateText();
}

void TrayController::updateText()
{
    m_visibilityAction->setText(text(isMainWindowShown() ? QStringLiteral("Hide Interface")
                                                         : QStringLiteral("Show Interface")));
    m_restartAction->setText(text(QStringLiteral("Restart")));
    m_quitAction->setText(text(QStringLiteral("Quit")));
}

void TrayController::reconnectMainWindowSignals()
{
    if (!m_mainWindow) {
        return;
    }

    m_windowConnections.append(connect(m_mainWindow, &QWindow::visibleChanged, this, [this](bool) {
        updateText();
    }));
    m_windowConnections.append(connect(m_mainWindow, &QWindow::visibilityChanged, this, [this](QWindow::Visibility) {
        updateText();
    }));
}
