import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    property int settingsTab: 0
    property string settingsMessage: ""

    readonly property int navWidth: 248
    readonly property int maxContentWidth: 760
    readonly property var themes: ["Dark", "Light"]
    readonly property var densities: ["Comfortable", "Compact"]
    readonly property var backupWindows: ["7 days", "14 days", "30 days"]
    readonly property var languages: ["en", "zh"]
    readonly property var languageNames: ["English", "Chinese"]
    readonly property var accentColors: [Theme.accentBlue, Theme.accentGreen, Theme.accentAmber]
    readonly property var accentNames: ["Blue", "Green", "Amber"]

    function displayMessage() {
        if (settingsMessage.length > 0) {
            return I18n.status(settingsMessage)
        }
        return settingsManager.statusMessage.length > 0 ? I18n.status(settingsManager.statusMessage) : I18n.t("Settings are local")
    }

    function indexFor(values, value) {
        for (var i = 0; i < values.length; ++i) {
            if (values[i] === value) {
                return i
            }
        }
        return 0
    }

    function tabTitle() {
        if (settingsTab === 1) {
            return I18n.t("Behavior")
        }
        if (settingsTab === 2) {
            return I18n.t("Storage & Privacy")
        }
        return I18n.t("Appearance")
    }

    function tabDetail() {
        if (settingsTab === 1) {
            return I18n.t("Startup, restore, and confirmation preferences.")
        }
        if (settingsTab === 2) {
            return I18n.t("Local data, backups, and secret visibility.")
        }
        return I18n.t("Theme, density, and accent preferences.")
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cardRadius
        color: "transparent"
        border.width: 1
        border.color: Theme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 24

            ColumnLayout {
                Layout.fillHeight: true
                Layout.preferredWidth: page.navWidth
                Layout.maximumWidth: page.navWidth
                spacing: 10

                Text {
                    text: I18n.t("SOFTWARE")
                    color: Theme.muted
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    Layout.leftMargin: 12
                    Layout.preferredHeight: 18
                    verticalAlignment: Text.AlignVCenter
                }

                SettingsNavItem {
                    text: I18n.t("Appearance")
                    iconName: "sliders-horizontal"
                    selected: page.settingsTab === 0
                    Layout.fillWidth: true
                    onClicked: page.settingsTab = 0
                }

                SettingsNavItem {
                    text: I18n.t("Behavior")
                    iconName: "activity"
                    selected: page.settingsTab === 1
                    Layout.fillWidth: true
                    onClicked: page.settingsTab = 1
                }

                SettingsNavItem {
                    text: I18n.t("Storage & Privacy")
                    iconName: "shield-check"
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
                Layout.maximumWidth: page.maxContentWidth
                spacing: 18

                Column {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: page.tabTitle()
                        color: Theme.text
                        font.pixelSize: 22
                        font.weight: Font.Bold
                        width: parent.width
                        height: 28
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    Text {
                        text: page.tabDetail()
                        color: Theme.muted
                        font.pixelSize: 12
                        width: parent.width
                        height: 18
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }

                ScrollView {
                    id: settingsScroll
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

                    StackLayout {
                        currentIndex: page.settingsTab
                        width: settingsScroll.availableWidth
                        height: Math.max(implicitHeight, settingsScroll.availableHeight)

                        ColumnLayout {
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Color Theme")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: I18n.t(themeBox.currentText)
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    FormComboBox {
                                        id: themeBox
                                        Layout.preferredWidth: 180
                                        translateItems: true
                                        model: page.themes
                                        currentIndex: settingsManager.darkTheme ? 0 : 1
                                        onActivated: function(index) {
                                            settingsManager.darkTheme = index === 0
                                            page.settingsMessage = settingsManager.darkTheme ? "Dark theme enabled" : "Light theme enabled"
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Interface Density")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: I18n.t(densityBox.currentText)
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    FormComboBox {
                                        id: densityBox
                                        Layout.preferredWidth: 180
                                        translateItems: true
                                        model: page.densities
                                        currentIndex: page.indexFor(page.densities, settingsManager.density)
                                        onActivated: function(index) {
                                            settingsManager.density = page.densities[index]
                                            page.settingsMessage = I18n.arg(I18n.t("%1 density enabled"), I18n.t(page.densities[index]))
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Accent Color")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: I18n.t(page.accentNames[Theme.accentIndex])
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    Row {
                                        spacing: 10
                                        Layout.preferredWidth: 118
                                        Layout.preferredHeight: 28

                                        Repeater {
                                            model: page.accentColors

                                            Rectangle {
                                                width: 28
                                                height: 28
                                                radius: 14
                                                color: modelData
                                                border.width: Theme.accentIndex === index ? 2 : 1
                                                border.color: Theme.accentIndex === index ? Theme.text : Theme.border

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        settingsManager.accentIndex = index
                                                        page.settingsMessage = I18n.arg(I18n.t("%1 accent enabled"), I18n.t(page.accentNames[index]))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Language")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: I18n.t(languageBox.currentText)
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    FormComboBox {
                                        id: languageBox
                                        Layout.preferredWidth: 180
                                        translateItems: true
                                        model: page.languageNames
                                        currentIndex: page.indexFor(page.languages, settingsManager.language)
                                        onActivated: function(index) {
                                            settingsManager.language = page.languages[index]
                                            page.settingsMessage = "Language changed"
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Launch at Login")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: settingsManager.launchAtLogin ? I18n.t("On") : I18n.t("Off")
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    ToggleSwitch {
                                        checked: settingsManager.launchAtLogin
                                        onToggled: {
                                            settingsManager.launchAtLogin = checked
                                            page.settingsMessage = checked ? "Launch at login enabled" : "Launch at login disabled"
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Restore Last Section")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: settingsManager.restoreLastSection ? I18n.t("On") : I18n.t("Off")
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    ToggleSwitch {
                                        checked: settingsManager.restoreLastSection
                                        onToggled: {
                                            settingsManager.restoreLastSection = checked
                                            page.settingsMessage = checked ? "Last section restore enabled" : "Last section restore disabled"
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Confirm Profile Deletion")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: settingsManager.confirmProfileDeletion ? I18n.t("Required") : I18n.t("Off")
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    ToggleSwitch {
                                        checked: settingsManager.confirmProfileDeletion
                                        enabled: false
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Health Check on Activate")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: settingsManager.healthCheckOnActivate ? I18n.t("On") : I18n.t("Off")
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    ToggleSwitch {
                                        checked: settingsManager.healthCheckOnActivate
                                        onToggled: {
                                            settingsManager.healthCheckOnActivate = checked
                                            page.settingsMessage = checked ? "Health check on activate enabled" : "Health check on activate disabled"
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 12

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Data Location")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: settingsManager.dataLocation
                                            color: Theme.muted
                                            font.pixelSize: 12
                                            width: parent.width
                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    ActionButton {
                                        text: I18n.t("Reveal")
                                        iconName: "file-cog"
                                        onClicked: page.settingsMessage = settingsManager.settingsPath
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Mask Secrets")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: settingsManager.maskSecrets ? I18n.t("On") : I18n.t("Off")
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    ToggleSwitch {
                                        checked: settingsManager.maskSecrets
                                        onToggled: {
                                            settingsManager.maskSecrets = checked
                                            page.settingsMessage = checked ? "Secret masking enabled" : "Secret masking disabled"
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Local Backups")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: settingsManager.keepBackups ? I18n.t("On") : I18n.t("Off")
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    ToggleSwitch {
                                        checked: settingsManager.keepBackups
                                        onToggled: {
                                            settingsManager.keepBackups = checked
                                            page.settingsMessage = checked ? "Local backups enabled" : "Local backups disabled"
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 74
                                radius: Theme.cardRadius
                                color: Theme.panelRaised
                                border.width: 1
                                border.color: Theme.border

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 18

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        Text {
                                            text: I18n.t("Backup Retention")
                                            color: Theme.text
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: I18n.t(backupWindowBox.currentText)
                                            color: Theme.muted
                                            font.pixelSize: 12
                                        }
                                    }

                                    FormComboBox {
                                        id: backupWindowBox
                                        Layout.preferredWidth: 180
                                        translateItems: true
                                        model: page.backupWindows
                                        currentIndex: page.indexFor(page.backupWindows, settingsManager.backupRetention)
                                        onActivated: function(index) {
                                            settingsManager.backupRetention = page.backupWindows[index]
                                            page.settingsMessage = I18n.arg(I18n.t("%1 backup retention enabled"), I18n.t(page.backupWindows[index]))
                                        }
                                    }
                                }
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

                    Text {
                        text: page.displayMessage()
                        color: Theme.muted
                        font.pixelSize: 12
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    ActionButton {
                        text: I18n.t("Clear Cache")
                        iconName: "trash-2"
                        onClicked: page.settingsMessage = "Cache cleared"
                    }

                    ActionButton {
                        text: I18n.t("Save Settings")
                        iconName: "save"
                        variant: "primary"
                        onClicked: {
                            settingsManager.save()
                            page.settingsMessage = settingsManager.statusMessage
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }
            }

            Item {
                Layout.preferredWidth: Math.max(0, parent.width - page.navWidth - page.maxContentWidth - 48)
                Layout.fillHeight: true
            }
        }
    }
}
