import QtQuick
import QtQuick.Layouts
import Loom

Rectangle {
    id: card

    property string iconName: ""
    property string title: ""
    property var lines: []

    Layout.fillWidth: true
    Layout.preferredHeight: 128
    radius: Theme.cardRadius
    color: Theme.panelRaised
    border.width: 1
    border.color: Theme.border

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Row {
            spacing: 10

            Item {
                width: 18
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                Icon {
                    anchors.centerIn: parent
                    name: card.iconName
                    size: 16
                    color: Theme.text
                }
            }

            Text {
                text: card.title
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Bold
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            width: parent.width
            spacing: 8

            Repeater {
                model: card.lines

                Text {
                    width: parent.width
                    text: modelData
                    color: Theme.text
                    font.family: "monospace"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }
    }
}
