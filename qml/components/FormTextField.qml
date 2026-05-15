import QtQuick
import QtQuick.Controls
import Loom

TextField {
    id: control

    property bool secret: false

    implicitHeight: 34
    leftPadding: 12
    rightPadding: 12
    color: Theme.text
    placeholderTextColor: Theme.dim
    selectedTextColor: "white"
    selectionColor: Theme.accent
    echoMode: secret ? TextInput.Password : TextInput.Normal
    font.pixelSize: 13

    background: Rectangle {
        radius: 6
        color: Theme.panel
        border.width: 1
        border.color: control.activeFocus ? Theme.accent : (control.hovered ? Theme.borderStrong : Theme.border)
    }
}
