import QtQuick
import Loom

Rectangle {
    id: pill

    property string text: ""
    property string iconName: ""
    property color fill: Theme.successSoft
    property color foreground: Theme.success
    property int horizontalPadding: 14

    implicitWidth: pillContent.implicitWidth + horizontalPadding * 2
    implicitHeight: 22
    radius: height / 2
    color: fill

    Row {
        id: pillContent
        anchors.centerIn: parent
        spacing: pill.iconName.length > 0 ? 5 : 0
        height: Math.max(iconSlot.implicitHeight, pillText.implicitHeight)

        Item {
            id: iconSlot
            visible: pill.iconName.length > 0
            implicitWidth: 12
            implicitHeight: 12
            anchors.verticalCenter: parent.verticalCenter

            Icon {
                anchors.centerIn: parent
                name: pill.iconName
                size: 12
                color: pill.foreground
            }
        }

        Text {
            id: pillText
            text: pill.text
            color: pill.foreground
            font.pixelSize: 12
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
