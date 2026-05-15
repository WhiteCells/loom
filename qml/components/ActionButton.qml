import QtQuick
import QtQuick.Controls
import Loom

Button {
    id: control

    property string iconName: ""
    property string tooltip: text
    property string variant: "secondary"

    implicitHeight: 36
    implicitWidth: control.text.length > 0 ? Math.max(96, labelRow.implicitWidth + 28) : implicitHeight
    padding: 0
    hoverEnabled: true

    background: Rectangle {
        radius: control.text.length === 0 ? height / 2 : Theme.cardRadius
        color: {
            if (!control.enabled) {
                return Theme.panel
            }
            if (control.variant === "primary") {
                return control.down ? Theme.accentSoft : (control.hovered ? Theme.accentHover : Theme.accent)
            }
            if (control.variant === "danger") {
                return control.down ? "#4d1f1f" : (control.hovered ? "#5b2626" : "#321b1c")
            }
            return control.down ? Theme.panelSoft : (control.hovered ? "#1d2425" : Theme.panel)
        }
        border.width: control.variant === "primary" ? 0 : 1
        border.color: control.variant === "danger" ? "#7a3536" : (control.hovered ? Theme.borderStrong : Theme.border)

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Row {
        id: labelRow
        spacing: control.iconName.length > 0 && control.text.length > 0 ? 8 : 0
        anchors.centerIn: parent
        height: Math.max(iconSlot.implicitHeight, textLabel.implicitHeight)

        Item {
            id: iconSlot
            visible: control.iconName.length > 0
            implicitWidth: 16
            implicitHeight: 16
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: control.iconName
                size: 16
                color: control.enabled ? (control.variant === "primary" ? "white" : (control.variant === "danger" ? Theme.danger : Theme.text)) : Theme.dim
            }
        }

        Text {
            id: textLabel
            visible: control.text.length > 0
            text: control.text
            width: Math.min(implicitWidth, Math.max(0, control.width - 28 - (control.iconName.length > 0 ? 24 : 0)))
            color: control.enabled ? (control.variant === "primary" ? "white" : (control.variant === "danger" ? Theme.danger : Theme.text)) : Theme.dim
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    ToolTip.visible: control.hovered && control.text.length === 0 && control.tooltip.length > 0
    ToolTip.delay: 450
    ToolTip.text: control.tooltip
}
