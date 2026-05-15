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
                        text: "Health Checks"
                        color: Theme.text
                        font.pixelSize: 26
                        font.weight: Font.Bold
                    }

                    Text {
                        text: profileManager.dashboard.healthDetail
                        color: Theme.muted
                        font.pixelSize: 13
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
                            Layout.fillWidth: true
                            Layout.leftMargin: 16
                        }

                        Text {
                            text: "Endpoint"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            Layout.preferredWidth: parent.width * 0.34
                        }

                        Text {
                            text: "Checked At"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Status"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "Latency"
                            color: Theme.muted
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            Layout.rightMargin: 16
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.border
                    }

                    Repeater {
                        model: profileManager.healthChecks

                        delegate: Item {
                            Layout.fillWidth: true
                            height: 52

                            RowLayout {
                                anchors.fill: parent

                                Text {
                                    text: modelData.profile
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    Layout.fillWidth: true
                                    Layout.leftMargin: 16
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.endpoint
                                    color: Theme.muted
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: parent.width * 0.34
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.checkedAt
                                    color: Theme.muted
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Pill {
                                        text: modelData.status
                                        iconName: modelData.status === "OK" ? "check" : "triangle-alert"
                                        fill: modelData.status === "OK" ? Theme.successSoft : "#45320d"
                                        foreground: modelData.status === "OK" ? Theme.success : Theme.warning
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                Text {
                                    text: modelData.latency
                                    color: Theme.muted
                                    font.pixelSize: 12
                                    Layout.fillWidth: true
                                    Layout.rightMargin: 16
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

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
