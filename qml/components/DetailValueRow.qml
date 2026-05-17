import QtQuick
import QtQuick.Layouts
import Loom

Item {
    id: row

    property string iconName: ""
    property string label: ""
    property string value: ""
    property string detail: ""
    property color accent: Theme.accent

    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(78, textColumn.implicitHeight + 30)

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.controlDisabled
        border.width: 1
        border.color: Theme.controlBorder
    }

    Rectangle {
        id: iconBox
        width: 34
        height: 34
        radius: 8
        color: Theme.control
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter

        Icon {
            anchors.centerIn: parent
            name: row.iconName
            size: 16
            color: Theme.icon
        }
    }

    Column {
        id: textColumn
        anchors.left: iconBox.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            width: parent.width
            text: row.label
            color: Theme.muted
            font.pixelSize: 11
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: row.value
            color: Theme.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideMiddle
        }

        Text {
            width: parent.width
            text: row.detail
            visible: row.detail.length > 0
            color: Theme.dim
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }
}
