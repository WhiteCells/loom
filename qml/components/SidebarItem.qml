import QtQuick
import QtQuick.Controls
import Loom

Button {
    id: control

    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property bool activeProfile: false

    height: 68
    width: ListView.view ? ListView.view.width : 260
    padding: 0

    background: Rectangle {
        color: control.selected ? "#3a4141" : (control.hovered ? "#1c2223" : "transparent")
        border.width: 0

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Item {
        anchors.fill: parent

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: statusPill.visible ? statusPill.left : parent.right
            anchors.rightMargin: statusPill.visible ? 12 : 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: control.title
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                width: parent.width
                elide: Text.ElideRight
            }

            Text {
                text: control.subtitle
                color: Theme.muted
                font.pixelSize: 12
                width: parent.width
                elide: Text.ElideRight
            }
        }

        Pill {
            id: statusPill
            visible: control.activeProfile
            text: "Active"
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 16
            horizontalPadding: 12
        }
    }
}
