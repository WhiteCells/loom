import QtQuick
import QtQuick.Layouts
import Loom

Item {
    id: page

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

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: I18n.t("Health Checks")
                        color: Theme.text
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        height: 32
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

                ActionButton {
                    text: I18n.t("Run Health Check")
                    iconName: "refresh-cw"
                    variant: "primary"
                    onClicked: profileManager.runHealthCheck()
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
                    onRunRequested: profileManager.runHealthCheck()
                }
            }
        }
    }
}
