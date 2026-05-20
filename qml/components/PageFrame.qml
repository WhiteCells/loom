import QtQuick
import Loom

Rectangle {
    id: frame

    default property alias contentData: contentHost.data
    property alias contentItem: contentHost
    property int padding: 26
    property color frameBorderColor: Theme.border
    property int frameBorderWidth: 1

    radius: Theme.cardRadius
    color: "transparent"
    border.width: 0

    Item {
        id: contentHost
        anchors.fill: parent
        anchors.margins: frame.padding
    }

    Rectangle {
        anchors.fill: parent
        z: 1
        enabled: false
        radius: frame.radius
        color: "transparent"
        border.width: frame.frameBorderWidth
        border.color: frame.frameBorderColor
    }
}
