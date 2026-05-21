import QtQuick
import Loom

Item {
    id: control

    signal clicked()

    property string text: ""
    property string iconName: ""
    property bool active: false
    readonly property bool hovered: hoverHandler.hovered
    readonly property bool down: tapHandler.pressed
    readonly property int contentGap: control.iconName.length > 0 && control.text.length > 0 ? 8 : 0

    TextMetrics {
        id: labelMetrics
        text: control.text
        font.pixelSize: 14
        font.weight: Font.DemiBold
    }

    implicitHeight: 40
    implicitWidth: Math.max(116, Math.ceil(labelMetrics.advanceWidth) + 32 + (control.iconName.length > 0 ? 16 + control.contentGap : 0))
    opacity: control.enabled ? 1 : 0.64
    scale: 1.0

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: control.active ? Theme.accent : Theme.controlHover
        opacity: control.active ? 1 : (control.hovered ? 1 : 0)
        border.width: 1
        border.color: control.active ? Theme.accentHover : Theme.controlBorder

        Behavior on color {
            enabled: !control.active
            ColorAnimation {
                duration: Theme.hoverDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Theme.hoverDuration
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.hoverDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    Row {
        id: navRow
        anchors.centerIn: parent
        spacing: control.contentGap
        height: 20

        Item {
            id: iconSlot
            visible: control.iconName.length > 0
            width: visible ? 16 : 0
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: control.iconName
                size: 16
                color: control.active ? Theme.accentText : Theme.icon
            }
        }

        Text {
            id: navLabel
            text: control.text
            width: Math.min(implicitWidth, Math.max(0, control.width - 48))
            height: parent.height
            color: control.active ? Theme.accentText : Theme.text
            font.pixelSize: 14
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
            duration: Theme.hoverDuration
            easing.type: Easing.OutCubic
        }
    }
}
