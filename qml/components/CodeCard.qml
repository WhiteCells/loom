import QtQuick
import QtQuick.Layouts
import Loom

Rectangle {
    id: card

    property string iconName: ""
    property string title: ""
    property var lines: []
    property int matchedLineCount: lines.length

    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(148, 80 + card.matchedLineCount * 20)
    radius: Theme.cardRadius
    color: Theme.panelRaised
    border.width: 1
    border.color: Theme.border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            spacing: 10

            Item {
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18

                Icon {
                    anchors.centerIn: parent
                    name: card.iconName
                    size: 16
                    color: Theme.icon
                }
            }

            Text {
                text: card.title
                color: Theme.text
                font.pixelSize: 14
                font.weight: Font.Bold
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.controlRadius
            color: Theme.controlDisabled
            border.width: 1
            border.color: Theme.border

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Repeater {
                    model: card.lines

                    Text {
                        width: parent.width
                        height: 12
                        text: modelData
                        color: modelData.length > 0 ? Theme.text : Theme.dim
                        font.family: "monospace"
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
