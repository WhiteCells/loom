import QtQuick
import QtQuick.Layouts
import Loom

Rectangle {
    id: card

    property string title: ""
    property string value: ""
    property string detail: ""
    property string iconName: ""
    property color iconColor: Theme.accent

    Layout.fillWidth: true
    Layout.preferredHeight: 120
    radius: Theme.cardRadius
    color: Theme.panelRaised
    border.width: 1
    border.color: Theme.border

    Behavior on color {
        ColorAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            width: parent.width

            Text {
                text: card.title
                color: Theme.muted
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Item {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20

                Icon {
                    anchors.centerIn: parent
                    name: card.iconName
                    color: card.iconColor
                    size: 18
                }
            }
        }

        Text {
            text: card.value
            color: Theme.text
            font.pixelSize: 20
            font.weight: Font.Bold
            width: parent.width
            elide: Text.ElideRight
        }

        Text {
            text: card.detail
            color: Theme.muted
            font.pixelSize: 12
            width: parent.width
            elide: Text.ElideRight
        }
    }
}
