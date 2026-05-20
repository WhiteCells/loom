import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

ApplicationWindow {
    id: root

    readonly property int outerMargin: 12
    readonly property int pagePadding: 22
    readonly property int currentPageIndex: {
        switch (profileManager.activeSection) {
        case "Profiles":
            return 1
        case "Health Checks":
            return 2
        case "Token Usage":
            return 3
        case "Settings":
            return 4
        default:
            return 0
        }
    }
    width: 1280
    height: 720
    minimumWidth: 980
    minimumHeight: 620
    visible: true
    title: "Loom"
    color: Theme.window

    Binding {
        target: I18n
        property: "language"
        value: settingsManager.language
    }

    Component.onCompleted: {
        Theme.dark = settingsManager.darkTheme
        Theme.accentIndex = settingsManager.accentIndex
    }

    Connections {
        target: settingsManager

        function onDarkThemeChanged() {
            Theme.dark = settingsManager.darkTheme
        }

        function onAccentIndexChanged() {
            Theme.accentIndex = settingsManager.accentIndex
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: root.outerMargin
        radius: Theme.pageRadius
        color: Theme.window
        border.width: 1
        border.color: Theme.border
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.pagePadding
            spacing: 16

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 50

                Rectangle {
                    id: navBar
                    width: Math.min(parent.width, navContent.implicitWidth + 26)
                    height: 46
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    radius: height / 2
                    color: Theme.panelRaised
                    border.width: 1
                    border.color: Theme.border
                    clip: true

                    Row {
                        id: navContent
                        anchors.centerIn: parent
                        spacing: 12
                        height: 38

                        Item {
                            id: brandSlot
                            height: 38
                            width: brandContent.implicitWidth + 14

                            Row {
                                id: brandContent
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 0

                                Text {
                                    id: brandText
                                    text: I18n.t("LOOM")
                                    color: Theme.text
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    height: brandSlot.height
                                    verticalAlignment: Text.AlignVCenter
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        NavButton {
                            text: I18n.t("Dashboard")
                            iconName: "layout-dashboard"
                            active: profileManager.activeSection === "Dashboard"
                            onClicked: profileManager.selectSection("Dashboard")
                        }

                        NavButton {
                            text: I18n.t("Profiles")
                            iconName: "users-round"
                            active: profileManager.activeSection === "Profiles"
                            onClicked: profileManager.selectSection("Profiles")
                        }

                        NavButton {
                            text: I18n.t("Health Checks")
                            iconName: "activity"
                            active: profileManager.activeSection === "Health Checks"
                            onClicked: profileManager.selectSection("Health Checks")
                        }

                        NavButton {
                            text: I18n.t("Token Usage")
                            iconName: "chart-no-axes-column"
                            active: profileManager.activeSection === "Token Usage"
                            onClicked: profileManager.selectSection("Token Usage")
                        }

                        NavButton {
                            text: I18n.t("Settings")
                            iconName: "settings"
                            active: profileManager.activeSection === "Settings"
                            onClicked: profileManager.selectSection("Settings")
                        }
                    }
                }
            }

            StackLayout {
                id: pageHost
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.currentPageIndex
                opacity: 1
                scale: 1

                onCurrentIndexChanged: {
                    pageTransition.restart()
                }

                ParallelAnimation {
                    id: pageTransition
                    NumberAnimation {
                        target: pageHost
                        property: "opacity"
                        from: 0.88
                        to: 1
                        duration: 130
                        easing.type: Easing.OutCubic
                    }

                    NumberAnimation {
                        target: pageHost
                        property: "scale"
                        from: 0.997
                        to: 1
                        duration: 130
                        easing.type: Easing.OutCubic
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.currentPageIndex === 0 || status === Loader.Ready
                    sourceComponent: active ? dashboardPageComponent : null
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.currentPageIndex === 1 || status === Loader.Ready
                    sourceComponent: active ? profilesPageComponent : null
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.currentPageIndex === 2 || status === Loader.Ready
                    sourceComponent: active ? healthChecksPageComponent : null
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.currentPageIndex === 3 || status === Loader.Ready
                    sourceComponent: active ? tokenUsagePageComponent : null
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: root.currentPageIndex === 4 || status === Loader.Ready
                    sourceComponent: active ? settingsPageComponent : null
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                spacing: 12

                Text {
                    text: I18n.t("Current: ") + I18n.status(profileManager.dashboard.activeProfile)
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Text {
                    text: I18n.status(profileManager.statusMessage)
                    color: Theme.muted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredWidth: 360
                    Layout.maximumWidth: Math.min(360, root.width * 0.45)
                    elide: Text.ElideRight
                }
            }
        }
    }

    Component {
        id: dashboardPageComponent

        DashboardPage {
        }
    }

    Component {
        id: profilesPageComponent

        ProfilesPage {
        }
    }

    Component {
        id: healthChecksPageComponent

        HealthChecksPage {
        }
    }

    Component {
        id: tokenUsagePageComponent

        TokenUsagePage {
        }
    }

    Component {
        id: settingsPageComponent

        SettingsPage {
        }
    }
}
