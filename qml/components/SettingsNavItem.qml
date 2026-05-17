import QtQuick
import Loom

Item {
    id: control

    signal clicked()

    property string text: ""
    property string iconName: ""
    property bool selected: false
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool down: tapHandler.pressed

    implicitHeight: 44
    opacity: control.enabled ? 1 : 0.64
    scale: control.down && control.enabled ? 0.985 : 1.0

    Rectangle {
        anchors.fill: parent
        radius: Theme.cardRadius
        color: control.selected ? Theme.selected : (control.hovered ? Theme.controlHover : "transparent")
        border.width: 1
        border.color: control.selected ? Theme.accentHover : (control.hovered ? Theme.controlBorder : "transparent")

        Behavior on color {
            enabled: !control.selected
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
        spacing: 11
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        height: 20

        Item {
            id: iconSlot
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: control.iconName
                size: 16
                color: control.selected ? Theme.icon : Theme.icon
            }
        }

        Text {
            id: navText
            text: control.text
            width: Math.max(0, parent.width - iconSlot.width - parent.spacing)
            height: parent.height
            color: control.selected ? Theme.accentHover : Theme.text
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
}
