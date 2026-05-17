import QtQuick
import QtQuick.Layouts
import Loom

Rectangle {
    id: tile

    property string iconName: ""
    property string title: ""
    property string value: ""
    property string detail: ""
    property color accent: Theme.accent
    property color accentFill: Theme.accentSoft

    Layout.fillWidth: true
    Layout.preferredHeight: 118
    radius: Theme.cardRadius
    color: Theme.panelRaised
    border.width: 1
    border.color: Theme.border
    clip: true

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 3
        color: tile.accent
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 8
                color: tile.accentFill

                Icon {
                    anchors.centerIn: parent
                    name: tile.iconName
                    size: 16
                    color: Theme.icon
                }
            }

            Text {
                text: tile.title
                color: Theme.muted
                font.pixelSize: 12
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Text {
            text: tile.value
            color: Theme.text
            font.pixelSize: 17
            font.weight: Font.Bold
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Text {
            text: tile.detail
            color: Theme.muted
            font.pixelSize: 12
            Layout.fillWidth: true
            Layout.preferredHeight: 18
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
