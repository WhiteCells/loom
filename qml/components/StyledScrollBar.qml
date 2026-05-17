import QtQuick
import QtQuick.Controls
import Loom

ScrollBar {
    id: control

    policy: ScrollBar.AsNeeded
    interactive: true
    hoverEnabled: true
    minimumSize: 0.08
    implicitWidth: 10
    implicitHeight: 10
    padding: 2
    visible: policy !== ScrollBar.AlwaysOff && size < 1.0

    background: Rectangle {
        implicitWidth: 10
        implicitHeight: 10
        radius: Math.min(width, height) / 2
        color: control.hovered || control.active || control.pressed ? Theme.panelSoft : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: Math.min(width, height) / 2
        color: control.pressed ? Theme.accent : (control.hovered || control.active ? Theme.borderStrong : Theme.border)
        opacity: control.policy === ScrollBar.AlwaysOff || control.size >= 1.0 ? 0 : (control.hovered || control.active || control.pressed ? 0.95 : 0.58)

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }
}
