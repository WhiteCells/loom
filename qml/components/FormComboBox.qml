import QtQuick
import QtQuick.Controls
import Loom

ComboBox {
    id: control

    implicitHeight: 40
    leftPadding: 14
    rightPadding: 38
    font.pixelSize: 13

    background: Rectangle {
        radius: 8
        color: !control.enabled ? Theme.controlDisabled : (control.activeFocus || control.popup.visible ? Theme.controlHover : Theme.control)
        border.width: 1
        border.color: !control.enabled ? Theme.border : (control.activeFocus || control.popup.visible ? Theme.accent : (control.hovered ? Theme.controlBorderStrong : Theme.controlBorder))

        Behavior on color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 120
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Text {
        leftPadding: 14
        rightPadding: 38
        text: control.displayText
        color: control.enabled ? Theme.text : Theme.dim
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Icon {
        name: "chevron-down"
        size: 16
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        color: control.enabled ? Theme.icon : Theme.dim
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: contentItem.implicitHeight
        padding: 0

        background: Rectangle {
            radius: 8
            color: Theme.control
            border.width: 1
            border.color: Theme.controlBorderStrong
        }

        contentItem: ListView {
            clip: true
            implicitHeight: Math.min(contentHeight, 168)
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollBar.horizontal: StyledScrollBar {
                policy: ScrollBar.AlwaysOff
            }
            ScrollBar.vertical: StyledScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }
    }

    delegate: ItemDelegate {
        width: control.width
        height: 38
        highlighted: control.highlightedIndex === index

        background: Rectangle {
            color: highlighted ? Theme.accentSoft : (hovered ? Theme.controlHover : "transparent")
        }

        contentItem: Text {
            text: modelData
            color: Theme.text
            font.pixelSize: 13
            leftPadding: 14
            rightPadding: 14
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
