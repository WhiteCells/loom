import QtQuick
import QtQuick.Effects
import Loom

Item {
    id: root

    property string name: ""
    property color color: Theme.text
    property int size: 16

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size
    visible: name.length > 0
    baselineOffset: height

    Image {
        id: iconSource
        anchors.fill: parent
        source: root.name.length > 0 ? "qrc:/assets/icons/" + root.name + ".svg" : ""
        sourceSize.width: root.size * Screen.devicePixelRatio
        sourceSize.height: root.size * Screen.devicePixelRatio
        fillMode: Image.PreserveAspectFit
        smooth: true
        visible: false
    }

    MultiEffect {
        anchors.fill: iconSource
        source: iconSource
        colorization: 1.0
        colorizationColor: root.color
    }
}
