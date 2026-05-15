import QtQuick
import QtQuick.Controls
import Loom

ComboBox {
    id: control

    implicitHeight: 34
    leftPadding: 12
    rightPadding: 34
    font.pixelSize: 13

    background: Rectangle {
        radius: 6
        color: Theme.panel
        border.width: 1
        border.color: control.activeFocus ? Theme.accent : (control.hovered ? Theme.borderStrong : Theme.border)
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: 34
        text: control.displayText
        color: Theme.text
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Icon {
        name: "chevron-down"
        size: 16
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.muted
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 0

        background: Rectangle {
            radius: 6
            color: Theme.panelRaised
            border.width: 1
            border.color: Theme.border
        }

        contentItem: ListView {
            clip: true
            implicitHeight: Math.min(contentHeight, 168)
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
        }
    }

    delegate: ItemDelegate {
        width: control.width
        height: 34
        highlighted: control.highlightedIndex === index

        background: Rectangle {
            color: highlighted ? Theme.accentSoft : (hovered ? Theme.panelSoft : "transparent")
        }

        contentItem: Text {
            text: modelData
            color: Theme.text
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
