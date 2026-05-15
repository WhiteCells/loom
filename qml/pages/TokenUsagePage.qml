import QtQuick
import QtQuick.Layouts
import Loom

Item {
    id: page

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
            spacing: 22

            Text {
                text: "Token Usage"
                color: Theme.text
                font.pixelSize: 26
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width < 820 ? 1 : 3
                columnSpacing: 20
                rowSpacing: 14

                StatCard {
                    title: "Usage Today"
                    value: page.formatNumber(profileManager.dashboard.tokensToday)
                    detail: profileManager.dashboard.tokenDetail
                    iconName: "chart-no-axes-column"
                    iconColor: Theme.danger
                }

                StatCard {
                    title: "Tracked Profiles"
                    value: String(profileManager.dashboard.profileCount)
                    detail: profileManager.dashboard.activeProfile + " active"
                    iconName: "users-round"
                    iconColor: Theme.accentHover
                }

                StatCard {
                    title: "Health"
                    value: profileManager.dashboard.systemHealth
                    detail: profileManager.dashboard.healthDetail
                    iconName: "activity"
                    iconColor: Theme.success
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.cardRadius
                color: Theme.panelRaised
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 18

                    Repeater {
                        model: profileManager.tokenUsage

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 78
                            radius: Theme.cardRadius
                            color: modelData.active ? "#1d2425" : "transparent"
                            border.width: 1
                            border.color: modelData.active ? Theme.borderStrong : Theme.border

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: modelData.name
                                        color: Theme.text
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: page.formatNumber(modelData.tokens) + " / " + page.formatNumber(modelData.limit)
                                        color: Theme.muted
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 8
                                    radius: 4
                                    color: Theme.panel

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: Math.max(8, parent.width * Math.min(1.0, modelData.ratio))
                                        radius: 4
                                        color: modelData.active ? Theme.accent : Theme.success

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 220
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
