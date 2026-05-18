import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    readonly property int tableHorizontalPadding: 36
    readonly property int usageContentWidth: 820

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
                text: I18n.t("Token Usage")
                color: Theme.text
                font.pixelSize: 26
                font.weight: Font.Bold
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                verticalAlignment: Text.AlignVCenter
            }

            GridLayout {
                Layout.fillWidth: true
                columns: width < 820 ? 1 : 3
                columnSpacing: 20
                rowSpacing: 14

                StatCard {
                    title: I18n.t("Usage Today")
                    value: page.formatNumber(profileManager.dashboard.tokensToday)
                    detail: I18n.status(profileManager.dashboard.tokenDetail)
                    iconName: "chart-no-axes-column"
                    iconColor: Theme.danger
                }

                StatCard {
                    title: I18n.t("Tracked Profiles")
                    value: String(profileManager.dashboard.profileCount)
                    detail: I18n.arg(I18n.t("%1 active"), I18n.status(profileManager.dashboard.activeProfile))
                    iconName: "users-round"
                    iconColor: Theme.accentHover
                }

                StatCard {
                    title: I18n.t("Health")
                    value: I18n.status(profileManager.dashboard.systemHealth)
                    detail: I18n.status(profileManager.dashboard.healthDetail)
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
                clip: true

                ScrollView {
                    id: tokenUsageScroll
                    anchors.fill: parent
                    anchors.leftMargin: page.tableHorizontalPadding
                    anchors.rightMargin: page.tableHorizontalPadding
                    anchors.topMargin: 20
                    anchors.bottomMargin: 20
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal: StyledScrollBar {
                        policy: ScrollBar.AlwaysOff
                        parent: tokenUsageScroll
                    }
                    ScrollBar.vertical: StyledScrollBar {
                        policy: ScrollBar.AsNeeded
                        parent: tokenUsageScroll
                    }

                    ColumnLayout {
                        width: Math.min(tokenUsageScroll.availableWidth, page.usageContentWidth)
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 18

                        Repeater {
                            model: profileManager.tokenUsage

                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 78
                                radius: Theme.cardRadius
                                color: modelData.active ? Theme.selected : "transparent"
                                border.width: 1
                                border.color: modelData.active ? Theme.borderStrong : Theme.border

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 18
                                    anchors.rightMargin: 18
                                    anchors.topMargin: 14
                                    anchors.bottomMargin: 14
                                    spacing: 10

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 18

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
                                            Layout.preferredWidth: 210
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideRight
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
                                            width: modelData.ratio <= 0 ? 0 : Math.max(8, parent.width * Math.min(1.0, modelData.ratio))
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
                    }
                }
            }
        }
    }
}
