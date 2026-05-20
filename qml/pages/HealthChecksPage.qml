import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    PageFrame {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: 20

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 56
                spacing: 18

                Column {
                    Layout.fillWidth: true
                    spacing: 7

                    Text {
                        text: I18n.t("Health Checks")
                        color: Theme.text
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        height: 30
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: I18n.status(profileManager.dashboard.healthDetail)
                        color: Theme.muted
                        font.pixelSize: 13
                        height: 18
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: Theme.controlRadius
                    color: refreshArea.pressed ? Theme.accentSoft : (refreshArea.containsMouse ? Theme.controlHover : Theme.control)
                    border.width: 1
                    border.color: refreshArea.containsMouse ? Theme.controlBorderStrong : Theme.controlBorder

                    Icon {
                        anchors.centerIn: parent
                        name: "refresh-cw"
                        size: 18
                        color: refreshArea.containsMouse ? Theme.accent : Theme.icon
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: profileManager.refreshHealthChecks()
                    }

                    ToolTip.visible: refreshArea.containsMouse
                    ToolTip.delay: 450
                    ToolTip.text: I18n.t("Refresh all profiles")

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.hoverDuration
                            easing.type: Easing.OutCubic
                        }
                    }
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

                HealthChecksTable {
                    anchors.fill: parent
                    model: profileManager.healthChecks
                    showCheckedAt: true
                    onRunRequested: profileManager.refreshHealthChecks()
                }
            }
        }
    }
}
