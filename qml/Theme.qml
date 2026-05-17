pragma Singleton

import QtQuick

QtObject {
    property bool dark: true
    property int accentIndex: 0

    readonly property color window: dark ? "#0d1112" : "#eef2f1"
    readonly property color panel: dark ? "#151a1b" : "#f8faf9"
    readonly property color panelRaised: dark ? "#1a2022" : "#f6f8f7"
    readonly property color panelSoft: dark ? "#252c2e" : "#e9eeee"
    readonly property color panelHover: dark ? "#2b3335" : "#dde6e5"
    readonly property color control: dark ? "#2c3639" : "#ffffff"
    readonly property color controlHover: dark ? "#374245" : "#f2f6f5"
    readonly property color controlPressed: dark ? "#252e30" : "#e6eeec"
    readonly property color controlDisabled: dark ? "#1d2426" : "#edf2f1"
    readonly property color controlBorder: dark ? "#5a676b" : "#b8c5c2"
    readonly property color controlBorderStrong: dark ? "#7a878b" : "#8fa09c"
    readonly property color selected: accentIndex === 1
                                      ? (dark ? "#0d3022" : "#d7efe2")
                                      : (accentIndex === 2 ? (dark ? "#342710" : "#f5e7c9") : (dark ? "#172846" : "#dce8f6"))
    readonly property color sidebar: dark ? "#121718" : "#e3eaea"
    readonly property color overlay: dark ? "#99000000" : "#660b1720"
    readonly property color border: dark ? "#30393b" : "#cbd5d3"
    readonly property color borderStrong: dark ? "#4b575a" : "#aab8b6"
    readonly property color text: dark ? "#f2f6f7" : "#182121"
    readonly property color icon: dark ? "#ffffff" : "#182121"
    readonly property color iconSubtle: dark ? "#e6eeee" : "#647271"
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
    readonly property color accent: accentIndex === 1 ? accentGreen : (accentIndex === 2 ? accentAmber : accentBlue)
    readonly property color accentHover: accentIndex === 1 ? accentGreenHover : (accentIndex === 2 ? accentAmberHover : accentBlueHover)
    readonly property color accentSoft: accentIndex === 1 ? accentGreenSoft : (accentIndex === 2 ? accentAmberSoft : accentBlueSoft)
    readonly property color success: dark ? "#18c278" : "#087f4d"
    readonly property color successSoft: dark ? "#073d26" : "#d7efe2"
    readonly property color warning: dark ? "#ffba49" : "#9a6500"
    readonly property color warningSoft: dark ? "#45320d" : "#f5e7c9"
    readonly property color danger: dark ? "#fb6b6b" : "#c93333"
    readonly property color dangerSoft: dark ? "#321b1c" : "#f6dddd"
    readonly property color dangerHover: dark ? "#5b2626" : "#efcccc"
    readonly property color dangerPressed: dark ? "#4d1f1f" : "#e8bcbc"
    readonly property color dangerText: dark ? "#ffffff" : danger
    readonly property color accentText: accentIndex === 2 && dark ? "#1f1705" : "white"
    readonly property int cardRadius: 8
}
