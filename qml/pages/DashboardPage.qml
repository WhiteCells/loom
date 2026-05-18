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
            spacing: 26

            Text {
                text: I18n.t("Overview")
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
                    title: I18n.t("Active Profile")
                    value: I18n.status(profileManager.dashboard.activeProfile)
                    detail: I18n.status(profileManager.dashboard.activeAgent)
                    iconName: "users-round"
                    iconColor: Theme.accentHover
                }

                StatCard {
                    title: I18n.t("System Health")
                    value: I18n.status(profileManager.dashboard.systemHealth)
                    detail: I18n.status(profileManager.dashboard.lastChecked)
                    iconName: "activity"
                    iconColor: Theme.success
                }

                StatCard {
                    title: I18n.t("Token Usage (Today)")
                    value: page.formatNumber(profileManager.dashboard.tokensToday)
                    detail: I18n.status(profileManager.dashboard.tokenDetail)
                    iconName: "chart-no-axes-column"
                    iconColor: Theme.danger
                }
            }

            Text {
                text: I18n.t("Recent Health Checks")
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

                HealthChecksTable {
                    anchors.fill: parent
                    model: profileManager.healthChecks
                    showCheckedAt: false
                    onRunRequested: profileManager.runHealthCheck()
                }
            }
        }
    }
}
