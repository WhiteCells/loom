import QtQuick
import QtQuick.Controls.impl
import Loom

Item {
    id: root

    property string name: ""
    property color color: Theme.icon
    property int size: 16

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size
    visible: name.length > 0
    baselineOffset: height

    IconImage {
        anchors.fill: parent
        source: root.name.length > 0 ? "qrc:/assets/icons/" + root.name + ".svg" : ""
        sourceSize.width: root.size * Screen.devicePixelRatio
        sourceSize.height: root.size * Screen.devicePixelRatio
        fillMode: Image.PreserveAspectFit
        smooth: true
        color: root.color
    }
}
