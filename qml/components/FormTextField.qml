import QtQuick
import QtQuick.Controls
import Loom

TextField {
    id: control

    property bool secret: false
    property bool secretVisible: false

    implicitHeight: 40
    leftPadding: 14
    rightPadding: secret ? 44 : 14
    color: Theme.text
    placeholderTextColor: Theme.dim
    selectedTextColor: Theme.accentText
    selectionColor: Theme.accent
    echoMode: secret && !secretVisible ? TextInput.Password : TextInput.Normal
    font.pixelSize: 13
    verticalAlignment: TextInput.AlignVCenter
    selectByMouse: true

    background: Rectangle {
        radius: Theme.controlRadius
        color: !control.enabled ? Theme.controlDisabled : (control.activeFocus ? Theme.controlHover : Theme.control)
        border.width: 1
        border.color: !control.enabled ? Theme.border : (control.activeFocus ? Theme.accent : (control.hovered ? Theme.controlBorderStrong : Theme.controlBorder))

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

    ActionButton {
        visible: control.secret
        text: ""
        iconName: control.secretVisible ? "eye-off" : "eye"
        tooltip: control.secretVisible ? I18n.t("Hide") : I18n.t("Show")
        implicitWidth: 28
        implicitHeight: 28
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        onClicked: {
            control.secretVisible = !control.secretVisible
            control.forceActiveFocus()
        }
    }
}
