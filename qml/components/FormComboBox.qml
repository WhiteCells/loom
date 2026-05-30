import QtQuick
import QtQuick.Controls
import Loom

ComboBox {
    id: control

    property bool translateItems: false
    property int maxVisibleRows: 6
    readonly property int popupRowHeight: 36
    readonly property int effectiveMaxVisibleRows: Math.max(1, maxVisibleRows)
    readonly property int popupVisibleRows: Math.min(count, effectiveMaxVisibleRows)
    readonly property bool popupScrollable: count > effectiveMaxVisibleRows

    implicitWidth: 220
    implicitHeight: 40
    leftPadding: 14
    rightPadding: 38
    font.pixelSize: 13

    background: Rectangle {
        radius: Theme.controlRadius
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
        text: control.translateItems ? I18n.t(control.displayText) : control.displayText
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
        implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
        leftPadding: 4
        rightPadding: 4
        topPadding: 4
        bottomPadding: 4

        background: Rectangle {
            radius: Theme.controlRadius
            color: Theme.panelRaised
            border.width: 1
            border.color: Theme.controlBorderStrong
        }

        contentItem: ListView {
            clip: true
            implicitHeight: control.popupVisibleRows * control.popupRowHeight
            interactive: control.popupScrollable
            boundsBehavior: Flickable.StopAtBounds
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollBar.horizontal: StyledScrollBar {
                policy: ScrollBar.AlwaysOff
                parent: control.popup.contentItem
            }
            ScrollBar.vertical: StyledScrollBar {
                policy: control.popupScrollable ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                parent: control.popup.contentItem
            }
        }
    }

    delegate: ItemDelegate {
        width: ListView.view ? ListView.view.width : control.width - 8
        height: 36
        highlighted: control.highlightedIndex === index
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        background: Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Theme.itemRadius
            color: highlighted ? Theme.accentSoft : (hovered ? Theme.controlHover : "transparent")
        }

        contentItem: Text {
            text: control.translateItems ? I18n.t(modelData) : modelData
            color: Theme.text
            font.pixelSize: 13
            leftPadding: 14
            rightPadding: 14
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
}
