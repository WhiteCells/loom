import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    function configLines(profile) {
        return [
            "model_provider = \"" + profile.modelProvider + "\"",
            "model = \"" + profile.model + "\"",
            "model_reasoning_effort = \"" + profile.reasoningEffort + "\""
        ]
    }

    function authLines(profile) {
        return [
            "\"auth_mode\": \"apikey\"",
            "\"OPENAI_API_KEY\": \"" + profile.maskedApiKey + "\""
        ]
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cardRadius
        color: "transparent"
        border.width: 1
        border.color: Theme.border
        clip: true

        RowLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 284
                color: "#14191a"
                border.width: 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        Layout.leftMargin: 14
                        Layout.rightMargin: 14

                        Text {
                            text: "Profiles"
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        ActionButton {
                            text: ""
                            iconName: "plus"
                            tooltip: "Create Profile"
                            variant: "primary"
                            implicitWidth: 28
                            implicitHeight: 28
                            onClicked: profileManager.createProfile()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.border
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: profileManager.profiles
                        clip: true

                        delegate: SidebarItem {
                            title: modelData.name
                            subtitle: modelData.agentType
                            selected: modelData.index === profileManager.selectedProfileIndex
                            activeProfile: modelData.active
                            onClicked: profileManager.selectProfile(modelData.index)
                        }
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.border
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 104
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    spacing: 16

                    Column {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: profileManager.currentProfile.name
                            color: Theme.text
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            width: parent.width
                            elide: Text.ElideRight
                        }

                        Text {
                            text: profileManager.currentProfile.description
                            color: Theme.muted
                            font.pixelSize: 13
                            width: parent.width
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        text: "Activate"
                        iconName: "power"
                        variant: profileManager.currentProfile.active ? "secondary" : "primary"
                        enabled: !profileManager.currentProfile.active
                        onClicked: profileManager.activateSelectedProfile()
                    }

                    ActionButton {
                        text: "Edit"
                        iconName: "pencil"
                        onClicked: profileManager.editSelectedProfile()
                    }

                    ActionButton {
                        text: "Delete"
                        iconName: "trash-2"
                        variant: "danger"
                        onClicked: profileManager.deleteSelectedProfile()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.border
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 22
                    columns: width < 760 ? 1 : 2
                    columnSpacing: 20
                    rowSpacing: 18

                    CodeCard {
                        iconName: "file-cog"
                        title: "config.toml"
                        lines: page.configLines(profileManager.currentProfile)
                    }

                    CodeCard {
                        iconName: "shield-check"
                        title: "auth.json"
                        lines: page.authLines(profileManager.currentProfile)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 116
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    Layout.topMargin: 8
                    radius: Theme.cardRadius
                    color: Theme.panelRaised
                    border.width: 1
                    border.color: Theme.border

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 18
                        columns: width < 720 ? 1 : 3
                        columnSpacing: 18
                        rowSpacing: 14

                        Column {
                            spacing: 7
                            Layout.fillWidth: true

                            Text {
                                text: "Base URL"
                                color: Theme.muted
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: profileManager.currentProfile.baseUrl
                                color: Theme.text
                                font.pixelSize: 13
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        Column {
                            spacing: 7
                            Layout.fillWidth: true

                            Text {
                                text: "HTTP Proxy"
                                color: Theme.muted
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: profileManager.currentProfile.httpProxy.length > 0 ? profileManager.currentProfile.httpProxy : "Disabled"
                                color: Theme.text
                                font.pixelSize: 13
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        Column {
                            spacing: 7
                            Layout.fillWidth: true

                            Text {
                                text: "HTTPS Proxy"
                                color: Theme.muted
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: profileManager.currentProfile.httpsProxy.length > 0 ? profileManager.currentProfile.httpsProxy : "Disabled"
                                color: Theme.text
                                font.pixelSize: 13
                                width: parent.width
                                elide: Text.ElideRight
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
