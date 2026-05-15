import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

ApplicationWindow {
    id: root

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

    Rectangle {
        anchors.fill: parent
        anchors.margins: 12
        color: Theme.window
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 18

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 48

                Rectangle {
                    id: navBar
                    width: Math.min(parent.width, navContent.implicitWidth + 28)
                    height: 46
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    radius: height / 2
                    color: Theme.panelRaised
                    border.width: 1
                    border.color: Theme.border

                    Row {
                        id: navContent
                        anchors.centerIn: parent
                        spacing: 8

                        Row {
                            height: 38
                            spacing: 9

                            Icon {
                                name: "bot"
                                size: 18
                                color: Theme.accentHover
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "LOOM"
                                color: Theme.text
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                anchors.verticalCenter: parent.verticalCenter
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

                onCurrentIndexChanged: {
                    pageTransition.restart()
                }

                SequentialAnimation {
                    id: pageTransition
                    NumberAnimation {
                        target: pageHost
                        property: "opacity"
                        from: 0.72
                        to: 1
                        duration: 150
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

                Text {
                    text: "Current: " + profileManager.dashboard.activeProfile
                    color: Theme.muted
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: profileManager.statusMessage
                    color: Theme.muted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 360
                    elide: Text.ElideRight
                }
            }
        }
    }
}
