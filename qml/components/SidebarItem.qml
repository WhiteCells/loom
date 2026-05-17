import QtQuick
import Loom

Item {
    id: control

    signal clicked()

    property string title: ""
    property string subtitle: ""
    property bool selected: false
    property bool activeProfile: false
    readonly property bool hovered: hoverHandler.hovered

    implicitHeight: 68
    height: implicitHeight
    width: ListView.view ? ListView.view.width : 260

    Rectangle {
        anchors.fill: parent
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

    Rectangle {
        width: 3
        height: parent.height - 18
        radius: 2
        anchors.left: parent.left
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        color: control.selected ? Theme.accentHover : "transparent"
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: statusPill.visible ? statusPill.left : parent.right
        anchors.rightMargin: statusPill.visible ? 12 : 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

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
        anchors.verticalCenter: parent.verticalCenter
        horizontalPadding: 12
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: control.clicked()
    }
}
