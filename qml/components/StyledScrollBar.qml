import QtQuick
import QtQuick.Controls
import Loom

ScrollBar {
    id: control

    readonly property bool isVertical: orientation === Qt.Vertical
    readonly property int thickness: 12
    readonly property int minThumbLength: 38

    policy: ScrollBar.AsNeeded
    interactive: true
    hoverEnabled: false
    minimumSize: Math.min(0.45, control.minThumbLength / Math.max(1, control.isVertical ? control.height : control.width))
    implicitWidth: control.isVertical ? control.thickness : control.minThumbLength
    implicitHeight: control.isVertical ? control.minThumbLength : control.thickness
    width: control.isVertical ? control.thickness : (control.parent ? control.parent.width : control.implicitWidth)
    height: control.isVertical ? (control.parent ? control.parent.height : control.implicitHeight) : control.thickness
    x: control.isVertical && control.parent ? Math.max(0, control.parent.width - control.width) : 0
    y: !control.isVertical && control.parent ? Math.max(0, control.parent.height - control.height) : 0
    padding: 3
    z: 20
    visible: policy !== ScrollBar.AlwaysOff
    opacity: control.policy === ScrollBar.AlwaysOff || control.size >= 1.0 ? 0 : 0.62

    contentItem: Rectangle {
        implicitWidth: control.isVertical ? 6 : control.minThumbLength
        implicitHeight: control.isVertical ? control.minThumbLength : 6
        radius: Math.min(width, height) / 2
        color: Theme.borderStrong
    }
}
