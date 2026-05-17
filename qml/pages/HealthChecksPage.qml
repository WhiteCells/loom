import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    readonly property int tableRowHeight: 52

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
                        text: "Health Checks"
                        color: Theme.text
                        font.pixelSize: 26
                        font.weight: Font.Bold
                        height: 32
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        text: profileManager.dashboard.healthDetail
                        color: Theme.muted
                        font.pixelSize: 13
                        height: 18
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                ActionButton {
                    text: "Run Health Check"
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

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44

                        Text {
                            text: "Profile"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 160
                            Layout.minimumWidth: 110
                            Layout.leftMargin: 16
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "Endpoint"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            Layout.preferredWidth: parent.width * 0.34
                            verticalAlignment: Text.AlignVCenter
                        }

                        Text {
                            text: "Checked At"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.preferredWidth: 118
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
                        id: healthChecksScroll
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
                            width: healthChecksScroll.availableWidth
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
                                            Layout.preferredWidth: 160
                                            Layout.minimumWidth: 110
                                            Layout.leftMargin: 16
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.endpoint
                                            color: Theme.muted
                                            font.pixelSize: 12
                                            Layout.fillWidth: true
                                            Layout.preferredWidth: parent.width * 0.34
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            text: modelData.checkedAt
                                            color: Theme.muted
                                            font.pixelSize: 12
                                            Layout.preferredWidth: 118
                                            verticalAlignment: Text.AlignVCenter
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
