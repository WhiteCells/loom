import QtQuick
import QtQuick.Controls
import Loom

Item {
    id: control

    signal clicked()

    property string text: ""
    property string iconName: ""
    property string tooltip: text
    property string variant: "secondary"
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool down: tapHandler.pressed
    readonly property int contentGap: control.iconName.length > 0 && control.text.length > 0 ? 8 : 0
    readonly property int contentHorizontalInset: control.text.length > 0 ? 28 : 0
    readonly property int labelNaturalWidth: (control.iconName.length > 0 ? 16 : 0) + control.contentGap + (control.text.length > 0 ? Math.ceil(control.text.length * 7.8) : 0)

    implicitHeight: 36
    implicitWidth: control.text.length > 0 ? Math.max(96, control.labelNaturalWidth + control.contentHorizontalInset) : implicitHeight
    opacity: control.enabled ? 1 : 0.64
    scale: control.down && control.enabled ? 0.98 : 1.0

    Rectangle {
        anchors.fill: parent
        radius: control.text.length === 0 ? height / 2 : Theme.cardRadius
        color: {
            if (!control.enabled) {
                return Theme.controlDisabled
            }
            if (control.variant === "primary") {
                return control.down ? Theme.accentSoft : (control.hovered ? Theme.accentHover : Theme.accent)
            }
            if (control.variant === "danger") {
                return control.down ? Theme.dangerPressed : (control.hovered ? Theme.dangerHover : Theme.dangerSoft)
            }
            return control.down ? Theme.controlPressed : (control.hovered ? Theme.controlHover : Theme.control)
        }
        border.width: control.variant === "primary" ? 0 : 1
        border.color: control.variant === "danger" ? Theme.danger : (control.hovered ? Theme.controlBorderStrong : Theme.controlBorder)

        Behavior on color {
            ColorAnimation {
                duration: 70
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 70
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: labelRow
        anchors.centerIn: parent
        spacing: control.contentGap
        height: 18

        Item {
            id: iconSlot
            visible: control.iconName.length > 0
            width: visible ? 16 : 0
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: control.iconName
                size: 16
                color: control.enabled ? (control.variant === "primary" ? Theme.accentText : (control.variant === "danger" ? Theme.dangerText : Theme.icon)) : Theme.dim
            }
        }

        Text {
            id: textLabel
            visible: control.text.length > 0
            text: control.text
            width: Math.min(implicitWidth, Math.max(0, control.width - control.contentHorizontalInset - (iconSlot.visible ? iconSlot.width + labelRow.spacing : 0)))
            height: parent.height
            color: control.enabled ? (control.variant === "primary" ? Theme.accentText : (control.variant === "danger" ? Theme.dangerText : Theme.text)) : Theme.dim
            font.pixelSize: 13
            font.weight: Font.DemiBold
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler {
        id: hoverHandler
        enabled: control.enabled
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        id: tapHandler
        enabled: control.enabled
        acceptedButtons: Qt.LeftButton
        onTapped: control.clicked()
    }

    Behavior on scale {
        NumberAnimation {
            duration: 70
            easing.type: Easing.OutCubic
        }
    }

    ToolTip.visible: control.hovered && control.text.length === 0 && control.tooltip.length > 0
    ToolTip.delay: 450
    ToolTip.text: control.tooltip
}
