import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    readonly property int sideWidth: 284
    readonly property int contentMargin: 22
    readonly property int editorHorizontalPadding: 24
    readonly property int editorFieldHeight: 68
    property string profileQuery: ""
    property bool editorCreating: false
    property bool deleteClosesEditor: false
    property string deleteProfileName: ""
    property string editorWarning: ""
    property var editorModelOptions: ["gpt-5.5", "gpt-5.4", "gpt-5.3-codex"]
    property bool editorModelOptionsReady: false
    property string editorModelMessageKey: "Enter an endpoint to load model options."
    property string editorModelMessageProvider: ""
    readonly property string editorModelMessage: editorModelMessageKey === "%1 model options loaded"
            ? I18n.arg(I18n.t(editorModelMessageKey), editorModelMessageProvider)
            : I18n.t(editorModelMessageKey)
    readonly property var providers: ["OpenAI", "Anthropic", "Custom"]
    readonly property var efforts: ["low", "medium", "high", "xhigh"]
    readonly property var wireApis: ["responses", "chat"]
    readonly property var openAiModels: ["gpt-5.5", "gpt-5.4", "gpt-5.4-mini", "gpt-5.3-codex", "gpt-5.2"]
    readonly property var anthropicModels: ["claude-sonnet-4.5", "claude-opus-4.1", "claude-haiku-4.5"]
    readonly property var customModels: ["custom-model"]
    readonly property int previewLineCount: Math.max(page.configLines(profileManager.currentProfile).length,
                                                     page.authLines(profileManager.currentProfile).length,
                                                     page.envLines(profileManager.currentProfile).length)

    function configLines(profile) {
        return [
            "model_provider = \"" + profile.modelProvider + "\"",
            "model = \"" + profile.model + "\"",
            "model_reasoning_effort = \"" + profile.reasoningEffort + "\"",
            "disable_response_storage = " + (profile.disableResponseStorage ? "true" : "false"),
            "",
            "[model_providers." + profile.modelProvider + "]",
            "name = \"" + profile.modelProvider + "\"",
            "base_url = \"" + profile.baseUrl + "\"",
            "wire_api = \"" + profile.wireApi + "\"",
            "requires_openai_auth = " + (profile.requiresOpenAiAuth ? "true" : "false")
        ]
    }

    function authLines(profile) {
        return [
            "\"auth_mode\": \"apikey\"",
            "\"OPENAI_API_KEY\": \"" + profile.maskedApiKey + "\""
        ]
    }

    function envLines(profile) {
        var lines = []
        if (profile.httpProxy && profile.httpProxy.length > 0) {
            lines.push("HTTP_PROXY=\"" + profile.httpProxy + "\"")
        }
        if (profile.httpsProxy && profile.httpsProxy.length > 0) {
            lines.push("HTTPS_PROXY=\"" + profile.httpsProxy + "\"")
        }
        return lines.length > 0 ? lines : [I18n.t("# No proxy configured")]
    }

    function displayHost(url) {
        var value = (url || "").trim()
        if (value.length === 0) {
            return I18n.t("Not configured")
        }

        value = value.replace(/^https?:\/\//, "")
        var slash = value.indexOf("/")
        return slash === -1 ? value : value.substring(0, slash)
    }

    function displayPath(url) {
        var value = (url || "").trim().replace(/^https?:\/\//, "")
        var slash = value.indexOf("/")
        return slash === -1 ? "/" : value.substring(slash)
    }

    function proxyLabel(value) {
        return value && value.length > 0 ? value : I18n.t("Disabled")
    }

    function proxyDetail(value) {
        return value && value.length > 0 ? I18n.t("Enabled") : I18n.t("Direct")
    }

    function filteredProfiles() {
        var source = profileManager.profiles
        var query = page.profileQuery.trim().toLowerCase()
        if (query.length === 0) {
            return source
        }

        var result = []
        for (var i = 0; i < source.length; ++i) {
            var profile = source[i]
            var haystack = [
                profile.name,
                profile.agentType,
                profile.modelProvider,
                profile.model,
                profile.baseUrl
            ].join(" ").toLowerCase()

            if (haystack.indexOf(query) !== -1) {
                result.push(profile)
            }
        }
        return result
    }

    function indexFor(values, value) {
        for (var i = 0; i < values.length; ++i) {
            if (values[i] === value) {
                return i
            }
        }
        return 0
    }

    function cleanEndpoint(endpoint) {
        return (endpoint || "").trim()
    }

    function providerForEndpoint(endpoint, fallbackProvider) {
        var normalized = page.cleanEndpoint(endpoint).toLowerCase()
        if (normalized.indexOf("anthropic") !== -1) {
            return "Anthropic"
        }
        if (normalized.indexOf("openai") !== -1) {
            return "OpenAI"
        }
        return fallbackProvider && fallbackProvider.length > 0 ? fallbackProvider : "Custom"
    }

    function agentTypeForProvider(provider) {
        return provider === "Anthropic" ? "Claude" : "Codex"
    }

    function modelOptionsForProvider(provider, preferredModel) {
        var result = page.customModels.slice()
        if (provider === "Anthropic") {
            result = page.anthropicModels.slice()
        } else if (provider === "OpenAI") {
            result = page.openAiModels.slice()
        } else if (preferredModel && preferredModel.trim().length > 0) {
            result = [preferredModel.trim()]
        }

        var preferred = preferredModel ? preferredModel.trim() : ""
        if (preferred.length > 0 && result.indexOf(preferred) === -1) {
            result.unshift(preferred)
        }
        return result
    }

    function refreshEditorModelOptions(preferredModel) {
        var endpoint = page.cleanEndpoint(editorBaseUrlField.text)
        if (endpoint.length === 0) {
            page.editorModelOptions = []
            editorModelBox.currentIndex = -1
            page.editorModelMessageProvider = ""
            page.editorModelMessageKey = "Endpoint required before loading model options."
            return
        }

        var provider = page.providerForEndpoint(endpoint, editorProviderBox.currentText)
        editorProviderBox.currentIndex = page.indexFor(page.providers, provider)

        var options = page.modelOptionsForProvider(provider, preferredModel || "")
        var target = preferredModel && preferredModel.trim().length > 0 ? preferredModel.trim() : options[0]
        page.editorModelOptions = options
        editorModelBox.currentIndex = page.indexFor(options, target)
        page.editorModelOptionsReady = true
        page.editorModelMessageProvider = provider
        page.editorModelMessageKey = "%1 model options loaded"
    }

    function markEndpointChanged() {
        page.editorModelOptionsReady = false
        page.editorModelMessageProvider = ""
        page.editorModelMessageKey = page.cleanEndpoint(editorBaseUrlField.text).length === 0
                ? "Endpoint required before loading model options."
                : "Endpoint changed. Load options before choosing a model."
    }

    function saveCurrentInterfaceConfig() {
        settingsManager.saveInterfaceConfig(
                    editorNameField.text,
                    editorProviderBox.currentText,
                    editorModelBox.currentText,
                    editorEffortBox.currentText,
                    editorBaseUrlField.text,
                    editorHttpProxyField.text,
                    editorHttpsProxyField.text,
                    editorStorageSwitch.checked,
                    editorWireApiBox.currentText,
                    editorOpenAiAuthSwitch.checked)
    }

    function loadEditor() {
        page.editorWarning = ""
        if (page.editorCreating) {
            var defaults = settingsManager.interfaceConfig
            editorNameField.text = defaults.profileName || ""
            editorProviderBox.currentIndex = page.indexFor(page.providers, defaults.modelProvider || "OpenAI")
            editorBaseUrlField.text = defaults.baseUrl || "https://api.openai.com/v1"
            editorApiKeyField.text = ""
            editorApiKeyField.placeholderText = "sk-..."
            editorHttpProxyField.text = defaults.httpProxy || ""
            editorHttpsProxyField.text = defaults.httpsProxy || ""
            editorStorageSwitch.checked = defaults.disableResponseStorage !== false
            editorWireApiBox.currentIndex = page.indexFor(page.wireApis, defaults.wireApi || "responses")
            editorOpenAiAuthSwitch.checked = defaults.requiresOpenAiAuth !== false
            page.refreshEditorModelOptions(defaults.model || "gpt-5.5")
            editorEffortBox.currentIndex = page.indexFor(page.efforts, defaults.reasoningEffort || "high")
            return
        }

        var profile = profileManager.currentProfile
        editorNameField.text = profile.name || ""
        editorProviderBox.currentIndex = page.indexFor(page.providers, profile.modelProvider || "OpenAI")
        editorBaseUrlField.text = profile.baseUrl || ""
        editorApiKeyField.text = profile.apiKey || ""
        editorApiKeyField.placeholderText = "sk-..."
        editorHttpProxyField.text = profile.httpProxy || ""
        editorHttpsProxyField.text = profile.httpsProxy || ""
        editorStorageSwitch.checked = profile.disableResponseStorage !== false
        editorWireApiBox.currentIndex = page.indexFor(page.wireApis, profile.wireApi || "responses")
        editorOpenAiAuthSwitch.checked = profile.requiresOpenAiAuth !== false
        page.refreshEditorModelOptions(profile.model || "")
        editorEffortBox.currentIndex = page.indexFor(page.efforts, profile.reasoningEffort || "high")
    }

    function openEditor(creating) {
        page.editorCreating = creating
        page.loadEditor()
        profileEditor.open()
        editorNameField.forceActiveFocus()
    }

    function createAndEditProfile() {
        searchField.text = ""
        page.profileQuery = ""
        page.openEditor(true)
    }

    function saveEditor() {
        page.editorWarning = ""
        if (editorNameField.text.trim().length === 0) {
            page.editorWarning = I18n.t("Profile name is required.")
            editorNameField.forceActiveFocus()
            return
        }
        if (editorNameField.text.indexOf("/") !== -1 || editorNameField.text.indexOf("\\") !== -1) {
            page.editorWarning = I18n.t("Profile name cannot contain / or \\.")
            editorNameField.forceActiveFocus()
            return
        }

        var saved = false
        if (page.editorCreating) {
            saved = profileManager.createProfileWithConfiguration(
                        editorNameField.text,
                        page.agentTypeForProvider(editorProviderBox.currentText),
                        editorProviderBox.currentText,
                        editorModelBox.currentText,
                        editorEffortBox.currentText,
                        editorBaseUrlField.text,
                        editorApiKeyField.text,
                        editorHttpProxyField.text,
                        editorHttpsProxyField.text,
                        editorStorageSwitch.checked,
                        editorWireApiBox.currentText,
                        editorOpenAiAuthSwitch.checked)
            if (saved) {
                page.saveCurrentInterfaceConfig()
                profileEditor.close()
            } else {
                page.editorWarning = I18n.status(profileManager.statusMessage)
            }
            return
        }

        saved = profileManager.saveConfiguration(
                    editorNameField.text,
                    page.agentTypeForProvider(editorProviderBox.currentText),
                    editorProviderBox.currentText,
                    editorModelBox.currentText,
                    editorEffortBox.currentText,
                    editorBaseUrlField.text,
                    editorApiKeyField.text,
                    editorHttpProxyField.text,
                    editorHttpsProxyField.text,
                    editorStorageSwitch.checked,
                    editorWireApiBox.currentText,
                    editorOpenAiAuthSwitch.checked)
        if (saved) {
            page.saveCurrentInterfaceConfig()
            profileEditor.close()
        } else {
            page.editorWarning = I18n.status(profileManager.statusMessage)
        }
    }

    function requestDeleteSelectedProfile(closeEditorAfterDelete) {
        var profile = profileManager.currentProfile
        page.deleteProfileName = profile.name || I18n.t("Selected Profile")
        page.deleteClosesEditor = closeEditorAfterDelete
        deleteConfirmDialog.open()
    }

    function confirmDeleteSelectedProfile() {
        profileManager.deleteSelectedProfile()
        deleteConfirmDialog.close()
        if (page.deleteClosesEditor) {
            profileEditor.close()
        }
        page.deleteClosesEditor = false
        page.deleteProfileName = ""
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
                Layout.preferredWidth: page.sideWidth
                color: Theme.sidebar
                border.width: 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 56
                        Layout.leftMargin: 14
                        Layout.rightMargin: 14
                        spacing: 10

                        Text {
                            text: I18n.t("Profiles")
                            color: Theme.text
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                        }

                        ActionButton {
                            text: ""
                            iconName: "plus"
                            tooltip: I18n.t("Create Profile")
                            variant: "primary"
                            implicitWidth: 28
                            implicitHeight: 28
                            onClicked: page.createAndEditProfile()
                        }
                    }

                    FormTextField {
                        id: searchField
                        Layout.fillWidth: true
                        Layout.leftMargin: 14
                        Layout.rightMargin: 14
                        Layout.bottomMargin: 14
                        placeholderText: I18n.t("Search profiles")
                        onTextEdited: page.profileQuery = text
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.border
                    }

                    ListView {
                        id: profileList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: page.filteredProfiles()
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        currentIndex: profileManager.selectedProfileIndex
                        highlightMoveDuration: 120
                        ScrollBar.horizontal: StyledScrollBar {
                            policy: ScrollBar.AlwaysOff
                        }
                        ScrollBar.vertical: StyledScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: SidebarItem {
                            width: ListView.view.width
                            title: modelData.name
                            subtitle: modelData.agentType
                            selected: modelData.index === profileManager.selectedProfileIndex
                            activeProfile: modelData.active
                            onClicked: profileManager.selectProfile(modelData.index)
                        }
                    }

                    Text {
                        visible: profileList.count === 0
                        text: I18n.t("No profiles found")
                        color: Theme.dim
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? 32 : 0
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
                    Layout.preferredHeight: 108
                    Layout.leftMargin: page.contentMargin
                    Layout.rightMargin: page.contentMargin
                    spacing: 16

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 8

                        Text {
                            text: profileManager.currentProfile.name
                            color: Theme.text
                            font.pixelSize: 24
                            font.weight: Font.Bold
                            width: parent.width
                            height: 30
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Text {
                            text: I18n.status(profileManager.currentProfile.description)
                            color: Theme.muted
                            font.pixelSize: 13
                            width: parent.width
                            height: 18
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    ActionButton {
                        text: I18n.t("Activate")
                        iconName: "power"
                        variant: profileManager.currentProfile.active ? "secondary" : "primary"
                        enabled: profileManager.profiles.length > 0 && !profileManager.currentProfile.active
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            if (profileManager.activateSelectedProfile()) {
                                settingsManager.activeProfileFolder = profileManager.currentProfile.folderName || ""
                            }
                        }
                    }

                    ActionButton {
                        text: I18n.t("Edit")
                        iconName: "pencil"
                        enabled: profileManager.profiles.length > 0
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: page.openEditor(false)
                    }

                    ActionButton {
                        text: I18n.t("Delete")
                        iconName: "trash-2"
                        variant: "danger"
                        enabled: profileManager.profiles.length > 1
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: page.requestDeleteSelectedProfile(false)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.border
                }

                ScrollView {
                    id: profileDetailScroll
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
                        width: profileDetailScroll.availableWidth
                        spacing: 18

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: page.contentMargin
                            Layout.rightMargin: page.contentMargin
                            Layout.topMargin: 20
                            columns: width < 760 ? 1 : 3
                            columnSpacing: 16
                            rowSpacing: 16

                            DetailTile {
                                iconName: "bot"
                                title: I18n.t("Runtime")
                                value: I18n.status(profileManager.currentProfile.agentType)
                                detail: profileManager.currentProfile.active ? I18n.t("Currently active") : I18n.t("Ready to activate")
                                accent: profileManager.currentProfile.active ? Theme.success : Theme.accent
                                accentFill: profileManager.currentProfile.active ? Theme.successSoft : Theme.accentSoft
                            }

                            DetailTile {
                                iconName: "sliders-horizontal"
                                title: I18n.t("Model")
                                value: profileManager.currentProfile.model
                                detail: profileManager.currentProfile.modelProvider
                                accent: Theme.accentHover
                                accentFill: Theme.accentSoft
                            }

                            DetailTile {
                                iconName: "activity"
                                title: I18n.t("Effort")
                                value: profileManager.currentProfile.reasoningEffort
                                detail: I18n.t("Reasoning intensity")
                                accent: Theme.warning
                                accentFill: Theme.warningSoft
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: page.contentMargin
                            Layout.rightMargin: page.contentMargin
                            Layout.preferredHeight: connectionLayout.implicitHeight + 36
                            radius: Theme.cardRadius
                            color: Theme.panelRaised
                            border.width: 1
                            border.color: Theme.border

                            ColumnLayout {
                                id: connectionLayout
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    spacing: 10

                                    Icon {
                                        name: "shield-check"
                                        size: 16
                                        color: Theme.icon
                                    }

                                    Text {
                                        text: I18n.t("Connection & Security")
                                        color: Theme.text
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        Layout.fillWidth: true
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    Pill {
                                        text: profileManager.currentProfile.maskedApiKey.length > 0 ? I18n.t("Key saved") : I18n.t("No key")
                                        iconName: profileManager.currentProfile.maskedApiKey.length > 0 ? "check" : "triangle-alert"
                                        fill: profileManager.currentProfile.maskedApiKey.length > 0 ? Theme.successSoft : Theme.warningSoft
                                        foreground: profileManager.currentProfile.maskedApiKey.length > 0 ? Theme.success : Theme.warning
                                    }
                                }

                                DetailValueRow {
                                    iconName: "network"
                                    label: I18n.t("Base URL")
                                    value: profileManager.currentProfile.baseUrl
                                    detail: I18n.t("Host: ") + page.displayHost(profileManager.currentProfile.baseUrl)
                                    accent: Theme.accent
                                }

                                DetailValueRow {
                                    iconName: "key-round"
                                    label: I18n.t("API Key")
                                    value: profileManager.currentProfile.maskedApiKey.length > 0 ? profileManager.currentProfile.maskedApiKey : I18n.t("Not configured")
                                    detail: I18n.t("Secret")
                                    accent: profileManager.currentProfile.maskedApiKey.length > 0 ? Theme.success : Theme.warning
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: page.contentMargin
                            Layout.rightMargin: page.contentMargin
                            Layout.preferredHeight: proxyLayout.implicitHeight + 36
                            radius: Theme.cardRadius
                            color: Theme.panelRaised
                            border.width: 1
                            border.color: Theme.border

                            ColumnLayout {
                                id: proxyLayout
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 14

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    spacing: 10

                                    Icon {
                                        name: "network"
                                        size: 16
                                        color: Theme.icon
                                    }

                                    Text {
                                        text: I18n.t("Proxy Routing")
                                        color: Theme.text
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        Layout.fillWidth: true
                                        verticalAlignment: Text.AlignVCenter
                                        elide: Text.ElideRight
                                    }

                                    Pill {
                                        text: profileManager.currentProfile.httpProxy.length > 0 || profileManager.currentProfile.httpsProxy.length > 0 ? I18n.t("Proxy on") : I18n.t("Direct")
                                        iconName: profileManager.currentProfile.httpProxy.length > 0 || profileManager.currentProfile.httpsProxy.length > 0 ? "check" : "network"
                                        fill: profileManager.currentProfile.httpProxy.length > 0 || profileManager.currentProfile.httpsProxy.length > 0 ? Theme.accentSoft : Theme.panelSoft
                                        foreground: profileManager.currentProfile.httpProxy.length > 0 || profileManager.currentProfile.httpsProxy.length > 0 ? Theme.accentHover : Theme.muted
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: width < 820 ? 1 : 2
                                    columnSpacing: 14
                                    rowSpacing: 14

                                    DetailValueRow {
                                        iconName: "network"
                                        label: I18n.t("HTTP Proxy")
                                        value: page.proxyLabel(profileManager.currentProfile.httpProxy)
                                        detail: page.proxyDetail(profileManager.currentProfile.httpProxy)
                                        accent: profileManager.currentProfile.httpProxy.length > 0 ? Theme.accent : Theme.muted
                                    }

                                    DetailValueRow {
                                        iconName: "network"
                                        label: I18n.t("HTTPS Proxy")
                                        value: page.proxyLabel(profileManager.currentProfile.httpsProxy)
                                        detail: page.proxyDetail(profileManager.currentProfile.httpsProxy)
                                        accent: profileManager.currentProfile.httpsProxy.length > 0 ? Theme.accent : Theme.muted
                                    }
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: page.contentMargin
                            Layout.rightMargin: page.contentMargin
                            columns: width < 760 ? 1 : 3
                            columnSpacing: 20
                            rowSpacing: 18

                            CodeCard {
                                iconName: "file-cog"
                                title: "config.toml"
                                lines: page.configLines(profileManager.currentProfile)
                                matchedLineCount: page.previewLineCount
                            }

                            CodeCard {
                                iconName: "network"
                                title: ".env"
                                lines: page.envLines(profileManager.currentProfile)
                                matchedLineCount: page.previewLineCount
                            }

                            CodeCard {
                                iconName: "shield-check"
                                title: "auth.json"
                                lines: page.authLines(profileManager.currentProfile)
                                matchedLineCount: page.previewLineCount
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: profileEditor

        modal: true
        focus: true
        padding: 0
        width: Math.max(520, Math.min(820, page.width - 72))
        height: Math.max(460, Math.min(660, page.height - 72))
        x: Math.round((page.width - width) / 2)
        y: Math.round((page.height - height) / 2)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 100
                easing.type: Easing.InCubic
            }
        }

        Overlay.modal: Rectangle {
            color: Theme.overlay
        }

        background: Rectangle {
            radius: Theme.cardRadius
            color: Theme.panelRaised
            border.width: 1
            border.color: Theme.borderStrong
        }

        contentItem: ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                Layout.leftMargin: page.editorHorizontalPadding
                Layout.rightMargin: 20
                spacing: 12

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Text {
                        text: page.editorCreating ? I18n.t("Create Profile") : I18n.t("Edit Profile")
                        color: Theme.text
                        font.pixelSize: 20
                        font.weight: Font.Bold
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: profileManager.currentProfile.name
                        visible: !page.editorCreating
                        color: Theme.muted
                        font.pixelSize: 12
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }

                ActionButton {
                    text: ""
                    iconName: "x"
                    tooltip: I18n.t("Close")
                    implicitWidth: 30
                    implicitHeight: 30
                    onClicked: profileEditor.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            ScrollView {
                id: editorScroll
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
                    width: editorScroll.availableWidth
                    spacing: 22

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        Layout.topMargin: 22
                        spacing: 6

                        Text {
                            text: I18n.t("Identity")
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: I18n.t("Name the profile and choose its model provider.")
                            color: Theme.muted
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        columns: width < 560 ? 1 : 2
                        columnSpacing: 16
                        rowSpacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorWarning.length > 0 ? 88 : page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("Profile Name")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormTextField {
                                id: editorNameField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                onTextEdited: page.editorWarning = ""
                            }

                            Text {
                                text: page.editorWarning
                                visible: page.editorWarning.length > 0
                                color: Theme.warning
                                font.pixelSize: 11
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("Model Provider")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormComboBox {
                                id: editorProviderBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                model: page.providers
                                onActivated: page.refreshEditorModelOptions("")
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        spacing: 6

                        Text {
                            text: I18n.t("Codex Runtime")
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: I18n.t("Provider table options written into config.toml.")
                            color: Theme.muted
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        columns: width < 560 ? 1 : 2
                        columnSpacing: 16
                        rowSpacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("Wire API")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormComboBox {
                                id: editorWireApiBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                model: page.wireApis
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 12

                            Column {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: I18n.t("Disable Response Storage")
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: editorStorageSwitch.checked ? "true" : "false"
                                    color: Theme.muted
                                    font.pixelSize: 12
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            ToggleSwitch {
                                id: editorStorageSwitch
                                checked: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 12

                            Column {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: I18n.t("Requires OpenAI Auth")
                                    color: Theme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: editorOpenAiAuthSwitch.checked ? "true" : "false"
                                    color: Theme.muted
                                    font.pixelSize: 12
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            ToggleSwitch {
                                id: editorOpenAiAuthSwitch
                                checked: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        spacing: 6

                        Text {
                            text: I18n.t("Connection")
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: I18n.t("Endpoint and key used to load available models.")
                            color: Theme.muted
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        columns: width < 560 ? 1 : 2
                        columnSpacing: 16
                        rowSpacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("Base URL")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormTextField {
                                id: editorBaseUrlField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "https://api.openai.com/v1"
                                onTextEdited: page.markEndpointChanged()
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("API Key")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormTextField {
                                id: editorApiKeyField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                secret: true
                                placeholderText: "sk-..."
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        spacing: 14

                        Column {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: I18n.t("Model & Effort")
                                color: Theme.text
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                width: parent.width
                            }

                            Text {
                                text: page.editorModelMessage
                                color: Theme.muted
                                font.pixelSize: 12
                                width: parent.width
                                elide: Text.ElideRight
                            }
                        }

                        ActionButton {
                            text: I18n.t("Load from Endpoint")
                            iconName: "refresh-cw"
                            enabled: page.cleanEndpoint(editorBaseUrlField.text).length > 0
                            Layout.alignment: Qt.AlignVCenter
                            onClicked: page.refreshEditorModelOptions("")
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        columns: width < 560 ? 1 : 2
                        columnSpacing: 16
                        rowSpacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("Model")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormComboBox {
                                id: editorModelBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                enabled: page.editorModelOptionsReady
                                model: page.editorModelOptions
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("Reasoning Effort")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormComboBox {
                                id: editorEffortBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                enabled: page.editorModelOptionsReady
                                model: page.efforts
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        spacing: 6

                        Text {
                            text: I18n.t("Proxy")
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        Text {
                            text: I18n.t("Optional local routing applied after the provider and model are selected.")
                            color: Theme.muted
                            font.pixelSize: 12
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: page.editorHorizontalPadding
                        Layout.rightMargin: page.editorHorizontalPadding
                        columns: width < 560 ? 1 : 2
                        columnSpacing: 16
                        rowSpacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("HTTP Proxy")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormTextField {
                                id: editorHttpProxyField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "http://127.0.0.1:2080"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: page.editorFieldHeight
                            spacing: 8

                            Text {
                                text: I18n.t("HTTPS Proxy")
                                color: Theme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            FormTextField {
                                id: editorHttpsProxyField
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                placeholderText: "http://127.0.0.1:2080"
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 4
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
                Layout.preferredHeight: 62
                Layout.leftMargin: page.editorHorizontalPadding
                Layout.rightMargin: page.editorHorizontalPadding
                spacing: 10

                ActionButton {
                    text: I18n.t("Delete")
                    iconName: "trash-2"
                    variant: "danger"
                    visible: !page.editorCreating
                    enabled: !page.editorCreating && profileManager.profiles.length > 1
                    onClicked: page.requestDeleteSelectedProfile(true)
                }

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    text: I18n.t("Cancel")
                    iconName: "x"
                    onClicked: profileEditor.close()
                }

                ActionButton {
                    text: I18n.t("Save Profile")
                    iconName: "save"
                    variant: "primary"
                    onClicked: page.saveEditor()
                }
            }
        }
    }

    Popup {
        id: deleteConfirmDialog

        modal: true
        focus: true
        padding: 0
        width: Math.max(360, Math.min(480, page.width - 48))
        height: 236
        x: Math.round((page.width - width) / 2)
        y: Math.round((page.height - height) / 2)
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 140
                easing.type: Easing.OutCubic
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 100
                easing.type: Easing.InCubic
            }
        }

        Overlay.modal: Rectangle {
            color: Theme.overlay
        }

        background: Rectangle {
            radius: Theme.cardRadius
            color: Theme.panelRaised
            border.width: 1
            border.color: Theme.borderStrong
        }

        contentItem: ColumnLayout {
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 74
                Layout.leftMargin: 22
                Layout.rightMargin: 18
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    Layout.alignment: Qt.AlignVCenter
                    radius: Theme.cardRadius
                    color: Theme.dangerSoft
                    border.width: 1
                    border.color: Theme.danger

                    Icon {
                        anchors.centerIn: parent
                        name: "trash-2"
                        size: 18
                        color: Theme.icon
                    }
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    Text {
                        text: I18n.t("Delete Profile?")
                        color: Theme.text
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: page.deleteProfileName
                        color: Theme.muted
                        font.pixelSize: 12
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }

                ActionButton {
                    text: ""
                    iconName: "x"
                    tooltip: I18n.t("Cancel")
                    implicitWidth: 30
                    implicitHeight: 30
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: deleteConfirmDialog.close()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.border
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                Layout.topMargin: 18
                spacing: 8

                Text {
                    text: I18n.t("This will remove the selected configuration from Loom.")
                    color: Theme.text
                    font.pixelSize: 13
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: I18n.t("This action cannot be undone.")
                    color: Theme.danger
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                Layout.leftMargin: 22
                Layout.rightMargin: 22
                spacing: 10

                Item {
                    Layout.fillWidth: true
                }

                ActionButton {
                    text: I18n.t("Cancel")
                    iconName: "x"
                    onClicked: deleteConfirmDialog.close()
                }

                ActionButton {
                    text: I18n.t("Delete")
                    iconName: "trash-2"
                    variant: "danger"
                    onClicked: page.confirmDeleteSelectedProfile()
                }
            }
        }
    }
}
