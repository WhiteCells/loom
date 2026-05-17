import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    readonly property int tableRowHeight: 50

    function formatNumber(value) {
        return Number(value).toLocaleString(Qt.locale("en_US"), "f", 0)
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cardRadius
        color: "transparent"
        border.width: 1
        border.color: Theme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 26

            Text {
                text: "Overview"
                color: Theme.text
                font.pixelSize: 28
                font.weight: Font.Bold
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                verticalAlignment: Text.AlignVCenter
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width < 860 ? 1 : 3
                columnSpacing: 20
                rowSpacing: 14

                StatCard {
                    title: "Active Profile"
                    value: profileManager.dashboard.activeProfile
                    detail: profileManager.dashboard.activeAgent
                    iconName: "users-round"
                    iconColor: Theme.accentHover
                }

                StatCard {
                    title: "System Health"
                    value: profileManager.dashboard.systemHealth
                    detail: profileManager.dashboard.lastChecked
                    iconName: "activity"
                    iconColor: Theme.success
                }

                StatCard {
                    title: "Token Usage (Today)"
                    value: page.formatNumber(profileManager.dashboard.tokensToday)
                    detail: profileManager.dashboard.tokenDetail
                    iconName: "chart-no-axes-column"
                    iconColor: Theme.danger
                }
            }

            Text {
                text: "Recent Health Checks"
                color: Theme.text
                font.pixelSize: 20
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.cardRadius
                color: Theme.panelRaised
                border.width: 1
                border.color: Theme.border
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        spacing: 0

                        Text {
                            text: "Profile"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 170
                            Layout.minimumWidth: 120
                            Layout.leftMargin: 16
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "Endpoint"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            Layout.preferredWidth: parent.width * 0.32
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "Status"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 118
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "Latency"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 94
                            Layout.rightMargin: 16
                            horizontalAlignment: Text.AlignRight
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.border
                    }

                    ScrollView {
                        id: recentChecksScroll
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        contentWidth: availableWidth
                        ScrollBar.horizontal: StyledScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }
                        ScrollBar.vertical: StyledScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        ColumnLayout {
                            width: recentChecksScroll.availableWidth
                            spacing: 0

                            Repeater {
                                model: profileManager.healthChecks

                                delegate: Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: page.tableRowHeight
                                    implicitHeight: page.tableRowHeight

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 0

                                        Text {
                                            text: modelData.profile
                                            color: Theme.text
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            Layout.preferredWidth: 170
                                            Layout.minimumWidth: 120
                                            Layout.leftMargin: 16
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.endpoint
                                            color: Theme.muted
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: parent.width * 0.32
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        Item {
                                            Layout.preferredWidth: 118
                                            Pill {
                                                text: modelData.status
                                                iconName: modelData.status === "OK" ? "check" : "triangle-alert"
                                                fill: modelData.status === "OK" ? Theme.successSoft : Theme.warningSoft
                                                foreground: modelData.status === "OK" ? Theme.success : Theme.warning
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }

                                        Text {
                                            text: modelData.latency
                                            color: Theme.muted
                                            font.pixelSize: 12
                                            Layout.preferredWidth: 94
                                            Layout.rightMargin: 16
                                            horizontalAlignment: Text.AlignRight
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.bottom: parent.bottom
                                        height: 1
                                        color: Theme.border
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
