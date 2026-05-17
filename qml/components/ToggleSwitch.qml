import QtQuick
import QtQuick.Controls
import Loom

Switch {
    id: control

    implicitWidth: 48
    implicitHeight: 28
    padding: 0
    spacing: 0
    hoverEnabled: true
    opacity: enabled ? 1 : 0.56

    indicator: Item {
        implicitWidth: 48
        implicitHeight: 28
        width: 48
        height: 28
        x: Math.round((control.width - width) / 2)
        y: Math.round((control.height - height) / 2)

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: control.checked ? Theme.accent : (control.hovered ? Theme.controlHover : Theme.control)
            border.width: 1
            border.color: control.checked ? Theme.accentHover : (control.hovered ? Theme.controlBorderStrong : Theme.controlBorder)

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        Rectangle {
            width: 20
            height: 20
            radius: height / 2
            x: control.checked ? parent.width - width - 4 : 4
            y: 4
            color: control.checked ? Theme.accentText : Theme.text
            opacity: control.enabled ? 1 : 0.72

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    contentItem: Item {
        implicitWidth: 0
        implicitHeight: 0
    }
}
