pragma Singleton

import QtQuick

QtObject {
    property bool dark: true
    property int accentIndex: 0

    function palette(values) {
        if (!values || values.length === 0) {
            return ""
        }

        var index = accentIndex
        if (index < 0) {
            index = 0
        }
        if (index >= values.length) {
            index = values.length - 1
        }
        return values[index]
    }

    readonly property color window: dark ? "#0d1112" : "#eef2f1"
    readonly property color panel: dark ? "#151a1b" : "#f8faf9"
    readonly property color panelRaised: dark ? "#1a2022" : "#f6f8f7"
    readonly property color panelSoft: dark ? "#252c2e" : "#e9eeee"
    readonly property color panelHover: dark ? "#2b3335" : "#dde6e5"
    readonly property color control: dark ? "#2c3639" : "#fbfcfb"
    readonly property color controlHover: dark ? "#374245" : "#f2f6f5"
    readonly property color controlPressed: dark ? "#252e30" : "#e6eeec"
    readonly property color controlDisabled: dark ? "#1d2426" : "#edf2f1"
    readonly property color controlBorder: dark ? "#5a676b" : "#b8c5c2"
    readonly property color controlBorderStrong: dark ? "#7a878b" : "#8fa09c"
    readonly property color tableHeader: dark ? "#202729" : "#eef4f2"
    readonly property color tableRowHover: dark ? "#243033" : "#e8f0ee"
    readonly property color tableDivider: dark ? "#293335" : "#dfe7e5"
    readonly property color sidebar: dark ? "#121718" : "#e3eaea"
    readonly property color overlay: dark ? "#99000000" : "#660b1720"
    readonly property color border: dark ? "#30393b" : "#cbd5d3"
    readonly property color borderStrong: dark ? "#4b575a" : "#aab8b6"
    readonly property color text: dark ? "#f2f6f7" : "#182121"
    readonly property color icon: dark ? "#f2f6f7" : "#182121"
    readonly property color iconSubtle: dark ? "#c3cccb" : "#647271"
    readonly property color muted: dark ? "#a8b1b0" : "#647271"
    readonly property color dim: dark ? "#74807f" : "#8a9795"
    readonly property color accentBlue: dark ? "#0b63d9" : "#0b63d9"
    readonly property color accentBlueHover: dark ? "#0e72f0" : "#0958c2"
    readonly property color accentBlueSoft: dark ? "#083b77" : "#d6e6f7"
    readonly property color accentGreen: dark ? "#18c278" : "#087f4d"
    readonly property color accentGreenHover: dark ? "#20d58a" : "#066b42"
    readonly property color accentGreenSoft: dark ? "#073d26" : "#d7efe2"
    readonly property color accentAmber: dark ? "#ffba49" : "#9a6500"
    readonly property color accentAmberHover: dark ? "#ffc76a" : "#825300"
    readonly property color accentAmberSoft: dark ? "#45320d" : "#f5e7c9"
    readonly property color accentSky: dark ? "#67c3ff" : "#a7d9ff"
    readonly property color accentSkyHover: dark ? "#86d1ff" : "#7cbcf0"
    readonly property color accentSkySoft: dark ? "#11354d" : "#d9efff"
    readonly property color accentMint: dark ? "#7fe1b2" : "#bdeccb"
    readonly property color accentMintHover: dark ? "#9ae9c5" : "#8cd7ab"
    readonly property color accentMintSoft: dark ? "#103d2e" : "#daf6eb"
    readonly property color accentPeach: dark ? "#ffd29c" : "#ffe0bb"
    readonly property color accentPeachHover: dark ? "#ffddb1" : "#f0c58f"
    readonly property color accentPeachSoft: dark ? "#49311a" : "#faecd7"
    readonly property var accentBases: [accentBlue, accentGreen, accentAmber, accentSky, accentMint, accentPeach]
    readonly property var accentHovers: [accentBlueHover, accentGreenHover, accentAmberHover, accentSkyHover, accentMintHover, accentPeachHover]
    readonly property var accentSofts: [accentBlueSoft, accentGreenSoft, accentAmberSoft, accentSkySoft, accentMintSoft, accentPeachSoft]
    readonly property var selectedDark: ["#172846", "#0d3022", "#342710", "#14354d", "#103d2e", "#49311a"]
    readonly property var selectedLight: ["#dce8f6", "#d7efe2", "#f5e7c9", "#d9efff", "#daf6eb", "#faecd7"]
    readonly property var selectedBordersDark: ["#2b415f", "#244a3b", "#574321", "#2a4c61", "#265442", "#60452d"]
    readonly property var selectedBordersLight: ["#c4d8ec", "#b9dcc8", "#dfcea7", "#bfe0f7", "#c2e9da", "#ead2b8"]
    readonly property var accentTextColors: ["#f8fbfb", "#f8fbfb", dark ? "#1f1705" : "#f8fbfb", "#182121", "#182121", "#182121"]
    readonly property color selected: palette(dark ? selectedDark : selectedLight)
    readonly property color selectedBorder: palette(dark ? selectedBordersDark : selectedBordersLight)
    readonly property color accent: palette(accentBases)
    readonly property color accentHover: palette(accentHovers)
    readonly property color accentSoft: palette(accentSofts)
    readonly property color success: dark ? "#18c278" : "#087f4d"
    readonly property color successSoft: dark ? "#073d26" : "#d7efe2"
    readonly property color warning: dark ? "#ffba49" : "#9a6500"
    readonly property color warningSoft: dark ? "#45320d" : "#f5e7c9"
    readonly property color danger: dark ? "#fb6b6b" : "#c93333"
    readonly property color dangerSoft: dark ? "#321b1c" : "#f6dddd"
    readonly property color dangerHover: dark ? "#5b2626" : "#efcccc"
    readonly property color dangerPressed: dark ? "#4d1f1f" : "#e8bcbc"
    readonly property color dangerText: dark ? "#f8fbfb" : danger
    readonly property color accentText: palette(accentTextColors)
    readonly property int pageRadius: 18
    readonly property int cardRadius: 14
    readonly property int controlRadius: 11
    readonly property int itemRadius: 9
    readonly property int smallRadius: 7
    readonly property int hoverDuration: 110
}
