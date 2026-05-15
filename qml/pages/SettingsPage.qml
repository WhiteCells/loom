import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    property int settingsTab: 0
    readonly property var agentTypes: ["Codex", "Claude"]
    readonly property var providers: ["OpenAI", "Anthropic", "Custom"]
    readonly property var efforts: ["low", "medium", "high", "xhigh"]

    function indexFor(values, value) {
        for (var i = 0; i < values.length; ++i) {
            if (values[i] === value) {
                return i
            }
        }
        return 0
    }

    function loadProfile() {
        var profile = profileManager.currentProfile
        profileNameField.text = profile.name || ""
        agentTypeBox.currentIndex = indexFor(agentTypes, profile.agentType || "Codex")
        providerBox.currentIndex = indexFor(providers, profile.modelProvider || "OpenAI")
        modelField.text = profile.model || ""
        effortBox.currentIndex = indexFor(efforts, profile.reasoningEffort || "high")
        baseUrlField.text = profile.baseUrl || ""
        apiKeyField.text = profile.maskedApiKey || ""
        httpProxyField.text = profile.httpProxy || ""
        httpsProxyField.text = profile.httpsProxy || ""
    }

    function saveProfile() {
        profileManager.saveConfiguration(
                    profileNameField.text,
                    agentTypeBox.currentText,
                    providerBox.currentText,
                    modelField.text,
                    effortBox.currentText,
                    baseUrlField.text,
                    apiKeyField.text,
                    httpProxyField.text,
                    httpsProxyField.text)
    }

    Component.onCompleted: loadProfile()

    Connections {
        target: profileManager

        function onCurrentProfileChanged() {
            page.loadProfile()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cardRadius
        color: "transparent"
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 24

            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                spacing: 8

                Text {
                    text: "CONFIGURATION"
                    color: Theme.muted
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    Layout.leftMargin: 10
                    Layout.topMargin: 2
                }

                SettingsNavItem {
                    text: "General Settings"
                    iconName: "sliders-horizontal"
                    selected: page.settingsTab === 0
                    Layout.fillWidth: true
                    onClicked: page.settingsTab = 0
                }

                SettingsNavItem {
                    text: "Authentication"
                    iconName: "key-round"
                    selected: page.settingsTab === 1
                    Layout.fillWidth: true
                    onClicked: page.settingsTab = 1
                }

                SettingsNavItem {
                    text: "Network & Proxy"
                    iconName: "network"
                    selected: page.settingsTab === 2
                    Layout.fillWidth: true
                    onClicked: page.settingsTab = 2
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: 620
                spacing: 18

                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: page.settingsTab === 0 ? "General Settings" : (page.settingsTab === 1 ? "Authentication" : "Network & Proxy")
                        color: Theme.text
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: page.settingsTab === 0
                              ? "Manage agent type, model provider, and run behavior."
                              : (page.settingsTab === 1 ? "Manage credentials and provider endpoint." : "Manage local proxy routing.")
                        color: Theme.muted
                        font.pixelSize: 12
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }

                ScrollView {
                    id: formScroll
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    StackLayout {
                        id: settingsStack
                        currentIndex: page.settingsTab
                        width: formScroll.availableWidth
                        height: Math.max(implicitHeight, formScroll.availableHeight)

                        ColumnLayout {
                            spacing: 16

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Profile Name"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormTextField {
                                    id: profileNameField
                                    Layout.fillWidth: true
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Agent Type"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormComboBox {
                                    id: agentTypeBox
                                    Layout.fillWidth: true
                                    model: page.agentTypes
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Model Provider"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormComboBox {
                                    id: providerBox
                                    Layout.fillWidth: true
                                    model: page.providers
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Model"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormTextField {
                                    id: modelField
                                    Layout.fillWidth: true
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Reasoning Effort"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormComboBox {
                                    id: effortBox
                                    Layout.fillWidth: true
                                    model: page.efforts
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 16

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "Base URL"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormTextField {
                                    id: baseUrlField
                                    Layout.fillWidth: true
                                    placeholderText: "https://api.openai.com/v1"
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "API Key"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormTextField {
                                    id: apiKeyField
                                    Layout.fillWidth: true
                                    secret: true
                                    placeholderText: "sk-..."
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }

                        ColumnLayout {
                            spacing: 16

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "HTTP Proxy"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormTextField {
                                    id: httpProxyField
                                    Layout.fillWidth: true
                                    placeholderText: "http://127.0.0.1:2080"
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "HTTPS Proxy"
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                FormTextField {
                                    id: httpsProxyField
                                    Layout.fillWidth: true
                                    placeholderText: "http://127.0.0.1:2080"
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.border
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item {
                        Layout.fillWidth: true
                    }

                    ActionButton {
                        text: "Cancel"
                        iconName: "x"
                        onClicked: page.loadProfile()
                    }

                    ActionButton {
                        text: "Save Configuration"
                        iconName: "save"
                        variant: "primary"
                        onClicked: page.saveProfile()
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
