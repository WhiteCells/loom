pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: root

    property var model: []
    property bool showCheckedAt: false

    signal runRequested()

    readonly property bool compactTable: width < 780
    readonly property int tableHeaderHeight: 44
    readonly property int tableRowHeight: 52
    readonly property int tableHorizontalPadding: compactTable ? 18 : 24
    readonly property int tableColumnGap: compactTable ? 14 : 18
    readonly property int tableProfileWidth: compactTable ? 132 : 156
    readonly property int tableEndpointWidth: 320
    readonly property int tableCheckedAtWidth: compactTable ? 0 : 126
    readonly property int tableStatusWidth: 112
    readonly property int tableLatencyWidth: 86
    readonly property int rowCount: root.model && root.model.length !== undefined ? root.model.length : 0

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.tableHeaderHeight

            Rectangle {
                anchors.fill: parent
                color: Theme.tableHeader
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: root.tableHorizontalPadding
                anchors.rightMargin: root.tableHorizontalPadding
                spacing: root.tableColumnGap

                Text {
                    text: I18n.t("Profile")
                    color: Theme.dim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    Layout.preferredWidth: root.tableProfileWidth
                    Layout.minimumWidth: 112
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: I18n.t("Endpoint")
                    color: Theme.dim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.tableEndpointWidth
                    Layout.minimumWidth: 180
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    visible: root.showCheckedAt && !root.compactTable
                    text: I18n.t("Checked At")
                    color: Theme.dim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    Layout.preferredWidth: root.tableCheckedAtWidth
                    Layout.minimumWidth: root.compactTable ? 0 : 112
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: I18n.t("Status")
                    color: Theme.dim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    Layout.preferredWidth: root.tableStatusWidth
                    Layout.minimumWidth: 96
                    verticalAlignment: Text.AlignVCenter
                }

                Text {
                    text: I18n.t("Latency")
                    color: Theme.dim
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    Layout.preferredWidth: root.tableLatencyWidth
                    Layout.minimumWidth: 72
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: Theme.tableDivider
            }
        }

        ScrollView {
            id: checksScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal: StyledScrollBar {
                policy: ScrollBar.AlwaysOff
                parent: checksScroll
            }
            ScrollBar.vertical: StyledScrollBar {
                policy: ScrollBar.AsNeeded
                parent: checksScroll
            }

            ColumnLayout {
                width: checksScroll.availableWidth
                spacing: 0

                Item {
                    visible: root.rowCount === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(180, checksScroll.availableHeight)

                    Column {
                        anchors.centerIn: parent
                        spacing: 14

                        Rectangle {
                            width: 44
                            height: 44
                            radius: height / 2
                            color: Theme.panelSoft
                            anchors.horizontalCenter: parent.horizontalCenter

                            Icon {
                                anchors.centerIn: parent
                                name: "activity"
                                size: 20
                                color: Theme.iconSubtle
                            }
                        }

                        Text {
                            text: I18n.t("No checks yet")
                            color: Theme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        ActionButton {
                            text: I18n.t("Run Health Check")
                            iconName: "refresh-cw"
                            variant: "secondary"
                            anchors.horizontalCenter: parent.horizontalCenter
                            onClicked: root.runRequested()
                        }
                    }
                }

                Repeater {
                    model: root.model

                    delegate: Item {
                        id: tableRow

                        required property int index
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: root.tableRowHeight
                        implicitHeight: root.tableRowHeight
                        readonly property bool hovered: rowHover.hovered
                        readonly property bool ok: tableRow.modelData.status === "OK"
                        readonly property color statusColor: ok ? Theme.success : Theme.warning
                        readonly property color statusFill: ok ? Theme.successSoft : Theme.warningSoft

                        Rectangle {
                            anchors.fill: parent
                            color: tableRow.hovered ? Theme.tableRowHover : "transparent"
                            opacity: tableRow.hovered ? 1 : (tableRow.ok ? 0 : 0.16)

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Theme.hoverDuration
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: root.tableHorizontalPadding
                            anchors.rightMargin: root.tableHorizontalPadding
                            spacing: root.tableColumnGap

                            Text {
                                text: tableRow.modelData.profile
                                color: Theme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                Layout.preferredWidth: root.tableProfileWidth
                                Layout.minimumWidth: 112
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                text: tableRow.modelData.endpoint
                                color: Theme.muted
                                font.pixelSize: 13
                                Layout.fillWidth: true
                                Layout.preferredWidth: root.tableEndpointWidth
                                Layout.minimumWidth: 180
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: root.showCheckedAt && !root.compactTable
                                text: tableRow.modelData.checkedAt
                                color: Theme.muted
                                font.pixelSize: 13
                                Layout.preferredWidth: root.tableCheckedAtWidth
                                Layout.minimumWidth: root.compactTable ? 0 : 112
                                verticalAlignment: Text.AlignVCenter
                            }

                            Item {
                                Layout.preferredWidth: root.tableStatusWidth
                                Layout.minimumWidth: 96

                                Pill {
                                    text: tableRow.modelData.status
                                    iconName: tableRow.ok ? "check" : "triangle-alert"
                                    fill: tableRow.statusFill
                                    foreground: tableRow.statusColor
                                    horizontalPadding: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                text: tableRow.modelData.latency
                                color: tableRow.ok ? Theme.muted : Theme.warning
                                font.pixelSize: 13
                                font.weight: tableRow.ok ? Font.Normal : Font.DemiBold
                                Layout.preferredWidth: root.tableLatencyWidth
                                Layout.minimumWidth: 72
                                horizontalAlignment: Text.AlignRight
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: root.tableHorizontalPadding
                            anchors.rightMargin: root.tableHorizontalPadding
                            height: 1
                            color: Theme.tableDivider
                            opacity: tableRow.index < root.rowCount - 1 ? 0.72 : 0
                        }

                        HoverHandler {
                            id: rowHover
                        }
                    }
                }
            }
        }
    }
}
