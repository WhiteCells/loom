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
                        spacing: 7
                        height: 38

                        Item {
                            id: brandSlot
                            height: 38
                            width: brandContent.implicitWidth + 8

                            Row {
                                id: brandContent
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 8

                                Icon {
                                    id: brandIcon
                                    name: "bot"
                                    size: 18
                                    color: Theme.icon
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: brandText
                                    text: "LOOM"
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
                            text: "Dashboard"
                            iconName: "layout-dashboard"
                            active: profileManager.activeSection === "Dashboard"
                            onClicked: profileManager.selectSection("Dashboard")
                        }

                        NavButton {
                            text: "Profiles"
                            iconName: "users-round"
                            active: profileManager.activeSection === "Profiles"
                            onClicked: profileManager.selectSection("Profiles")
                        }

                        NavButton {
                            text: "Health Checks"
                            iconName: "activity"
                            active: profileManager.activeSection === "Health Checks"
                            onClicked: profileManager.selectSection("Health Checks")
                        }

                        NavButton {
                            text: "Token Usage"
                            iconName: "chart-no-axes-column"
                            active: profileManager.activeSection === "Token Usage"
                            onClicked: profileManager.selectSection("Token Usage")
                        }

                        NavButton {
                            text: "Settings"
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

                DashboardPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                ProfilesPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                HealthChecksPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                TokenUsagePage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                SettingsPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                spacing: 12

                Text {
                    text: "Current: " + profileManager.dashboard.activeProfile
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }

                Text {
                    text: profileManager.statusMessage
                    color: Theme.muted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    Layout.preferredWidth: 360
                    Layout.maximumWidth: parent.width * 0.45
                    elide: Text.ElideRight
                }
            }
        }
    }
}
