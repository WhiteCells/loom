import QtQuick
import QtQuick.Controls
import Loom

Button {
    id: control

    property string iconName: ""
    property bool active: false

    implicitHeight: 38
    implicitWidth: Math.max(118, navRow.implicitWidth + 28)
    padding: 0
    hoverEnabled: true

    background: Rectangle {
        radius: height / 2
        color: control.active ? Theme.accent : (control.hovered ? Theme.panelSoft : "transparent")
        border.width: 0

        Behavior on color {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Row {
        id: navRow
        spacing: 8
        anchors.centerIn: parent
        height: Math.max(iconSlot.implicitHeight, navLabel.implicitHeight)

        Item {
            id: iconSlot
            implicitWidth: 16
            implicitHeight: 16
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: control.iconName
                size: 16
                color: control.active ? "white" : Theme.text
            }
        }

        Text {
            id: navLabel
            text: control.text
            color: control.active ? "white" : Theme.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
