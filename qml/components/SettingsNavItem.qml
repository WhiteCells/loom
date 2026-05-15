import QtQuick
import QtQuick.Controls
import Loom

Button {
    id: control

    property string iconName: ""
    property bool selected: false

    implicitHeight: 30
    padding: 0

    background: Rectangle {
        radius: 6
        color: control.selected ? Theme.panelSoft : (control.hovered ? "#1b2122" : "transparent")

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Row {
        spacing: 9
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        height: Math.max(iconSlot.implicitHeight, navText.implicitHeight)

        Item {
            id: iconSlot
            implicitWidth: 16
            implicitHeight: 16
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: control.iconName
                size: 15
                color: control.selected ? Theme.accentHover : Theme.text
            }
        }

        Text {
            id: navText
            text: control.text
            color: control.selected ? Theme.accentHover : Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            width: parent.width - 26
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
