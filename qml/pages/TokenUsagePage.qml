import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Loom

Item {
    id: page

    property var summary: profileManager.tokenSummary
    property var dailySeries: profileManager.tokenDailySeries

    function formatNumber(value) {
        return Number(value || 0).toLocaleString(Qt.locale("en_US"), "f", 0)
    }

    function dateToString(date) {
        var year = date.getFullYear()
        var month = String(date.getMonth() + 1).padStart(2, "0")
        var day = String(date.getDate()).padStart(2, "0")
        return year + "-" + month + "-" + day
    }

    function recentStartString(days) {
        var date = new Date()
        date.setDate(date.getDate() - Math.max(0, days - 1))
        return dateToString(date)
    }

    Component.onCompleted: {
        if (profileManager.activeSection === "Token Usage") {
            profileManager.refreshTokenUsage()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cardRadius
        color: "transparent"
        border.width: 1
        border.color: Theme.border
        clip: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 22
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 130
                radius: Theme.cardRadius
                color: Theme.panelRaised
                border.width: 1
                border.color: Theme.border
                clip: false

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 16
                    anchors.bottomMargin: 16
                    spacing: 18

                    ColumnLayout {
                        Layout.preferredWidth: Math.max(238, Math.min(304, parent.width * 0.3))
                        Layout.minimumWidth: 220
                        Layout.fillHeight: true
                        spacing: 4

                        Text {
                            text: I18n.t("Token Usage")
                            color: Theme.text
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            Layout.preferredHeight: 22
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Text {
                            text: page.formatNumber(summary.totalTokens)
                            color: Theme.text
                            font.pixelSize: 27
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Text {
                            text: I18n.arg(I18n.t("%1 sessions"), page.formatNumber(summary.sessionCount))
                            color: Theme.muted
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }

                        Text {
                            text: summary.date || ""
                            color: Theme.dim
                            font.pixelSize: 11
                            Layout.fillWidth: true
                            Layout.preferredHeight: 14
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: Theme.tableDivider
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    DateRangeControls {
                        Layout.preferredWidth: Math.min(500, Math.max(360, parent.width * 0.48))
                        Layout.minimumWidth: 320
                        Layout.preferredHeight: 40
                        Layout.maximumHeight: 40
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        startDate: summary.startDate || ""
                        endDate: summary.endDate || ""
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: page.width < 1120 ? 158 : 102
                radius: Theme.cardRadius
                color: Theme.panelRaised
                border.width: 1
                border.color: Theme.border
                clip: true

                GridLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.topMargin: 13
                    anchors.bottomMargin: 13
                    columns: page.width < 1120 ? 3 : 6
                    columnSpacing: 12
                    rowSpacing: 12

                    SummaryMetric { label: I18n.t("Input Tokens"); value: page.formatNumber(summary.inputTokens); iconName: "chart-no-axes-column"; markerColor: Theme.accent }
                    SummaryMetric { label: I18n.t("Cached"); value: page.formatNumber(summary.cachedInputTokens); iconName: "shield-check"; markerColor: Theme.success }
                    SummaryMetric { label: I18n.t("Output Tokens"); value: page.formatNumber(summary.outputTokens); iconName: "activity"; markerColor: Theme.warning }
                    SummaryMetric { label: I18n.t("Reasoning"); value: page.formatNumber(summary.reasoningOutputTokens); iconName: "bot"; markerColor: Theme.danger }
                    SummaryMetric { label: I18n.t("Range Usage"); value: page.formatNumber(summary.totalTokens); iconName: "network"; markerColor: Theme.accentHover }
                    SummaryMetric { label: I18n.t("Updated"); value: I18n.status(summary.lastUpdated); iconName: "refresh-cw"; markerColor: Theme.dim }
                }
            }

            Panel {
                Layout.fillWidth: true
                Layout.fillHeight: true
                title: summary.startDate === summary.endDate ? I18n.t("Hourly Flow") : I18n.t("Daily Flow")
                trailingText: I18n.status(summary.dateLabel || "")

                TokenWaveCanvas {
                    anchors.fill: parent.body
                    model: page.dailySeries
                    hourly: summary.startDate === summary.endDate
                }
            }
        }
    }

    component Panel: Rectangle {
        id: panel

        property alias title: titleText.text
        property alias trailingText: trailingText.text
        property alias body: panelBody

        radius: Theme.cardRadius
        color: Theme.panelRaised
        border.width: 1
        border.color: Theme.border
        clip: true

        RowLayout {
            id: panelHeader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 14
            height: 24

            Text {
                id: titleText
                color: Theme.text
                font.pixelSize: 15
                font.weight: Font.Bold
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            Text {
                id: trailingText
                color: Theme.muted
                font.pixelSize: 11
                font.weight: Font.DemiBold
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }

        Item {
            id: panelBody
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: panelHeader.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            anchors.topMargin: 12
            anchors.bottomMargin: 16
        }
    }

    component DateRangeControls: Item {
        id: rangeControls

        property string startDate: ""
        property string endDate: ""
        property date visibleMonth: startDate.length > 0 ? new Date(startDate + "T00:00:00") : new Date()
        property string draftStartDate: startDate
        property string draftEndDate: endDate
        property bool selectingRange: false
        readonly property string displayText: startDate.length === 0
                                              ? I18n.t("Date Range")
                                              : (endDate.length === 0 || startDate === endDate
                                                 ? startDate
                                                 : startDate + "  -  " + endDate)
        readonly property string draftDisplayText: draftStartDate.length === 0
                                                  ? displayText
                                                  : (draftStartDate === draftEndDate || draftEndDate.length === 0
                                                     ? draftStartDate
                                                     : draftStartDate + "  -  " + draftEndDate)

        implicitWidth: 460
        implicitHeight: 40

        function overlayItem() {
            return calendarPopup.parent || page
        }

        function popupWidth() {
            var overlay = overlayItem()
            return Math.min(536, Math.max(456, overlay.width - 32))
        }

        function popupHeight() {
            var overlay = overlayItem()
            return Math.min(392, Math.max(360, overlay.height - 32))
        }

        function popupX() {
            var overlay = overlayItem()
            var point = rangeControls.mapToItem(overlay, 0, rangeControls.height + 8)
            var maxX = Math.max(16, overlay.width - calendarPopup.width - 16)
            return Math.max(16, Math.min(point.x + rangeControls.width - calendarPopup.width, maxX))
        }

        function popupY() {
            var overlay = overlayItem()
            var point = rangeControls.mapToItem(overlay, 0, rangeControls.height + 8)
            var maxY = Math.max(16, overlay.height - calendarPopup.height - 16)
            return Math.max(16, Math.min(point.y, maxY))
        }

        function repositionPopup() {
            calendarPopup.width = popupWidth()
            calendarPopup.height = popupHeight()
            calendarPopup.x = popupX()
            calendarPopup.y = popupY()
        }

        onWidthChanged: {
            if (calendarPopup.opened) {
                repositionPopup()
            }
        }

        onHeightChanged: {
            if (calendarPopup.opened) {
                repositionPopup()
            }
        }

        function monthTitle(date) {
            return date.getFullYear() + "." + String(date.getMonth() + 1).padStart(2, "0")
        }

        function addMonths(date, months) {
            return new Date(date.getFullYear(), date.getMonth() + months, 1)
        }

        function addYears(date, years) {
            return new Date(date.getFullYear() + years, date.getMonth(), 1)
        }

        function firstGridDate(date) {
            var first = new Date(date.getFullYear(), date.getMonth(), 1)
            return new Date(first.getFullYear(), first.getMonth(), first.getDate() - first.getDay())
        }

        function isSelected(dayString) {
            return dayString === draftStartDate || dayString === draftEndDate
        }

        function isBetween(dayString) {
            return draftStartDate !== draftEndDate
                && dayString > draftStartDate
                && dayString < draftEndDate
        }

        function chooseDate(dayString) {
            if (!selectingRange) {
                draftStartDate = dayString
                draftEndDate = dayString
                selectingRange = true
                return
            }

            if (dayString < draftStartDate) {
                draftEndDate = draftStartDate
                draftStartDate = dayString
            } else {
                draftEndDate = dayString
            }
            selectingRange = false
        }

        function openCalendar() {
            draftStartDate = startDate
            draftEndDate = endDate
            selectingRange = false
            visibleMonth = startDate.length > 0 ? new Date(startDate + "T00:00:00") : new Date()
            repositionPopup()
            calendarPopup.open()
        }

        function commitDraft() {
            if (draftStartDate.length === 0) {
                return
            }

            profileManager.setTokenDateRange(draftStartDate, draftEndDate.length > 0 ? draftEndDate : draftStartDate)
            selectingRange = false
            calendarPopup.close()
        }

        function setDraftRecentRange(days) {
            draftStartDate = page.recentStartString(days)
            draftEndDate = page.dateToString(new Date())
            selectingRange = false
            visibleMonth = new Date(draftEndDate + "T00:00:00")
        }

        onStartDateChanged: visibleMonth = startDate.length > 0 ? new Date(startDate + "T00:00:00") : visibleMonth

        RowLayout {
            id: rangeHeader

            anchors.fill: parent
            spacing: 10

            RangeButton {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredHeight: 36
                text: rangeControls.displayText
                onClicked: rangeControls.openCalendar()
            }

            ActionButton {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                iconName: "refresh-cw"
                tooltip: I18n.t("Refresh")
                onClicked: profileManager.refreshTokenUsage()
            }
        }

        Popup {
            id: calendarPopup

            parent: Overlay.overlay
            width: 536
            height: 392
            modal: false
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
            padding: 0

            onOpened: rangeControls.repositionPopup()

            background: Rectangle {
                radius: Theme.cardRadius
                color: Theme.panelRaised
                border.width: 1
                border.color: Theme.borderStrong
            }

            contentItem: ColumnLayout {
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    Layout.topMargin: 12
                    spacing: 10

                    CalendarStepper {
                        Layout.preferredWidth: 154
                        label: I18n.t("Year")
                        value: String(rangeControls.visibleMonth.getFullYear())
                        previousTooltip: I18n.t("Previous Year")
                        nextTooltip: I18n.t("Next Year")
                        onPrevious: rangeControls.visibleMonth = rangeControls.addYears(rangeControls.visibleMonth, -1)
                        onNext: rangeControls.visibleMonth = rangeControls.addYears(rangeControls.visibleMonth, 1)
                    }

                    CalendarStepper {
                        Layout.preferredWidth: 136
                        label: I18n.t("Month")
                        value: String(rangeControls.visibleMonth.getMonth() + 1).padStart(2, "0")
                        previousTooltip: I18n.t("Previous Month")
                        nextTooltip: I18n.t("Next Month")
                        onPrevious: rangeControls.visibleMonth = rangeControls.addMonths(rangeControls.visibleMonth, -1)
                        onNext: rangeControls.visibleMonth = rangeControls.addMonths(rangeControls.visibleMonth, 1)
                    }

                    Text {
                        text: rangeControls.draftDisplayText
                        color: Theme.muted
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    spacing: 6

                    Repeater {
                        model: [I18n.t("Sun"), I18n.t("Mon"), I18n.t("Tue"), I18n.t("Wed"), I18n.t("Thu"), I18n.t("Fri"), I18n.t("Sat")]

                        delegate: Text {
                            Layout.fillWidth: true
                            text: modelData
                            color: Theme.dim
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                GridLayout {
                    id: calendarGrid

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    columns: 7
                    columnSpacing: 6
                    rowSpacing: 6

                    WheelHandler {
                        target: null
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: function(event) {
                            var direction = event.angleDelta.y > 0 ? -1 : 1
                            rangeControls.visibleMonth = rangeControls.addMonths(rangeControls.visibleMonth, direction)
                            event.accepted = true
                        }
                    }

                    Repeater {
                        model: 42

                        delegate: CalendarDay {
                            required property int index

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            dayDate: {
                                var base = rangeControls.firstGridDate(rangeControls.visibleMonth)
                                return new Date(base.getFullYear(), base.getMonth(), base.getDate() + index)
                            }
                            currentMonth: dayDate.getMonth() === rangeControls.visibleMonth.getMonth()
                                          && dayDate.getFullYear() === rangeControls.visibleMonth.getFullYear()
                            selected: rangeControls.isSelected(dayString)
                            inRange: rangeControls.isBetween(dayString)
                            pending: rangeControls.selectingRange && rangeControls.draftStartDate === dayString
                            rangeStart: dayString === rangeControls.draftStartDate && rangeControls.draftStartDate !== rangeControls.draftEndDate
                            rangeEnd: dayString === rangeControls.draftEndDate && rangeControls.draftStartDate !== rangeControls.draftEndDate
                            onClicked: rangeControls.chooseDate(dayString)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    Layout.bottomMargin: 14
                    spacing: 8

                    PresetChip {
                        text: I18n.t("Today")
                        selected: rangeControls.draftStartDate === rangeControls.draftEndDate
                                  && rangeControls.draftEndDate === page.dateToString(new Date())
                        onClicked: rangeControls.setDraftRecentRange(1)
                    }

                    PresetChip {
                        text: I18n.t("Last 7 Days")
                        selected: rangeControls.draftStartDate === page.recentStartString(7)
                                  && rangeControls.draftEndDate === page.dateToString(new Date())
                        onClicked: rangeControls.setDraftRecentRange(7)
                    }

                    PresetChip {
                        text: I18n.t("Last 30 Days")
                        selected: rangeControls.draftStartDate === page.recentStartString(30)
                                  && rangeControls.draftEndDate === page.dateToString(new Date())
                        onClicked: rangeControls.setDraftRecentRange(30)
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ActionButton {
                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 34
                        text: I18n.t("Confirm")
                        iconName: "check"
                        variant: "primary"
                        enabled: rangeControls.draftStartDate.length > 0
                        onClicked: rangeControls.commitDraft()
                    }
                }
            }
        }
    }

    component CalendarStepper: Rectangle {
        id: stepper

        signal previous()
        signal next()

        property string label: ""
        property string value: ""
        property string previousTooltip: ""
        property string nextTooltip: ""

        Layout.preferredHeight: 34
        radius: Theme.controlRadius
        color: Theme.control
        border.width: 1
        border.color: Theme.controlBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: stepper.label
                color: Theme.muted
                font.pixelSize: 10
                font.weight: Font.DemiBold
                Layout.preferredWidth: 34
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            ActionButton {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "chevron-down"
                rotation: 90
                tooltip: stepper.previousTooltip
                onClicked: stepper.previous()
            }

            Text {
                text: stepper.value
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.Bold
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            ActionButton {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                iconName: "chevron-down"
                rotation: -90
                tooltip: stepper.nextTooltip
                onClicked: stepper.next()
            }
        }
    }

    component RangeButton: Rectangle {
        id: rangeButton

        signal clicked()

        property string text: ""
        readonly property bool hovered: hoverHandler.hovered

        radius: Theme.controlRadius
        color: hovered ? Theme.controlHover : Theme.control
        border.width: 1
        border.color: hovered ? Theme.controlBorderStrong : Theme.controlBorder
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 8

            Icon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                name: "calendar-days"
                color: Theme.icon
            }

            Text {
                text: rangeButton.text
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
                Layout.fillWidth: true
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            Icon {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                name: "chevron-down"
                color: Theme.iconSubtle
            }
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: rangeButton.clicked()
        }
    }

    component PresetChip: Rectangle {
        id: chip

        signal clicked()

        property string text: ""
        property bool selected: false
        readonly property bool hovered: hoverHandler.hovered

        Layout.preferredWidth: Math.max(76, chipLabel.implicitWidth + 24)
        Layout.preferredHeight: 34
        radius: height / 2
        color: selected ? Theme.accentSoft : (hovered ? Theme.controlHover : Theme.control)
        border.width: 1
        border.color: selected ? Theme.accent : (hovered ? Theme.controlBorderStrong : Theme.controlBorder)

        Text {
            id: chipLabel
            anchors.centerIn: parent
            text: chip.text
            color: chip.selected ? Theme.accentHover : Theme.text
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: chip.clicked()
        }
    }

    component CalendarDay: Rectangle {
        id: dayCell

        signal clicked()

        property date dayDate: new Date()
        property bool currentMonth: true
        property bool selected: false
        property bool inRange: false
        property bool pending: false
        property bool rangeStart: false
        property bool rangeEnd: false
        readonly property bool hovered: hoverHandler.hovered
        readonly property string dayString: page.dateToString(dayDate)

        radius: Theme.controlRadius
        color: "transparent"
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Math.min(parent.height - 6, 30)
            radius: Theme.controlRadius
            color: dayCell.inRange ? Theme.accentSoft : "transparent"
            opacity: dayCell.currentMonth ? 1 : 0.5
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Theme.controlRadius
            color: dayCell.selected || dayCell.pending ? Theme.accent : (dayCell.hovered ? Theme.controlHover : "transparent")
            border.width: dayCell.rangeStart || dayCell.rangeEnd ? 1 : 0
            border.color: Theme.accentHover
        }

        Text {
            anchors.centerIn: parent
            text: String(dayCell.dayDate.getDate())
            color: dayCell.selected || dayCell.pending ? Theme.accentText : (dayCell.currentMonth ? Theme.text : Theme.dim)
            opacity: dayCell.currentMonth ? 1 : 0.45
            font.pixelSize: 12
            font.weight: dayCell.selected || dayCell.pending ? Font.Bold : Font.DemiBold
        }

        HoverHandler {
            id: hoverHandler
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            acceptedButtons: Qt.LeftButton
            onTapped: {
                dayCell.clicked()
            }
        }
    }

    component SummaryMetric: Rectangle {
        id: summaryMetric

        property string label: ""
        property string value: ""
        property string iconName: ""
        property color markerColor: Theme.accent

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 48
        radius: Theme.smallRadius
        color: Theme.panel
        border.width: 1
        border.color: Theme.tableDivider
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 8
            anchors.bottomMargin: 8
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 22
                spacing: 8

                Item {
                    Layout.preferredWidth: 22
                    Layout.preferredHeight: 22

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.smallRadius
                        color: summaryMetric.markerColor
                        opacity: 0.16
                    }

                    Icon {
                        anchors.centerIn: parent
                        name: summaryMetric.iconName
                        size: 13
                        color: summaryMetric.markerColor
                    }
                }

                Text {
                    text: summaryMetric.label
                    color: Theme.muted
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            Text {
                text: summaryMetric.value
                color: Theme.text
                font.pixelSize: 17
                font.weight: Font.Bold
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                elide: Text.ElideRight
            }
        }
    }

    component TokenWaveCanvas: Item {
        id: chart

        property var model: []
        property bool hourly: false
        readonly property int hourlyLabelStep: width >= 720 ? 4 : (width >= 460 ? 6 : 8)
        readonly property int labelCount: hourly ? Math.floor(24 / hourlyLabelStep) + 1 : Math.min(6, model.length || 0)
        readonly property int labelWidth: hourly ? 34 : 48
        readonly property int labelFontSize: 10
        readonly property var labelModel: {
            var labels = []
            if (hourly) {
                for (var hour = 0; hour <= 24; hour += hourlyLabelStep) {
                    labels.push({
                        "position": hour / 24,
                        "label": String(hour).padStart(2, "0")
                    })
                }
                return labels
            }

            var count = model.length || 0
            if (count <= 0) {
                return labels
            }

            for (var i = 0; i < labelCount; ++i) {
                var index = labelCount === 1 ? 0 : Math.round(i * (count - 1) / (labelCount - 1))
                var item = model[index]
                if (item) {
                    labels.push({
                        "position": count === 1 ? 0.5 : index / (count - 1),
                        "label": item.label || item.date || ""
                    })
                }
            }
            return labels
        }
        readonly property real maxTokens: {
            var maxValue = 0
            for (var i = 0; i < model.length; ++i) {
                maxValue = Math.max(maxValue, Number(model[i].tokens || 0))
            }
            return Math.max(1, maxValue)
        }

        function seriesPosition(index, count) {
            if (hourly && count > 0) {
                return (index + 0.5) / count
            }

            return count === 1 ? 0.5 : index / (count - 1)
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                var count = chart.model.length
                var left = 8
                var right = width - 8
                var top = 12
                var bottom = height - (chart.hourly ? 34 : 28)
                var plotWidth = Math.max(1, right - left)
                var plotHeight = Math.max(1, bottom - top)

                ctx.strokeStyle = Theme.tableDivider
                ctx.lineWidth = 1
                ctx.globalAlpha = 1
                for (var grid = 0; grid < 3; ++grid) {
                    var gy = top + (plotHeight / 2) * grid
                    ctx.beginPath()
                    ctx.moveTo(left, gy)
                    ctx.lineTo(right, gy)
                    ctx.stroke()
                }

                if (count === 0) {
                    return
                }

                var points = []
                for (var i = 0; i < count; ++i) {
                    var x = left + plotWidth * chart.seriesPosition(i, count)
                    var value = Number(chart.model[i].tokens || 0)
                    var y = bottom - (value / chart.maxTokens) * plotHeight
                    points.push({ "x": x, "y": y, "value": value })
                }

                ctx.beginPath()
                ctx.moveTo(chart.hourly ? left : points[0].x, bottom)
                ctx.lineTo(points[0].x, bottom)
                ctx.lineTo(points[0].x, points[0].y)
                for (var p = 1; p < points.length; ++p) {
                    var midX = (points[p - 1].x + points[p].x) / 2
                    ctx.bezierCurveTo(midX, points[p - 1].y, midX, points[p].y, points[p].x, points[p].y)
                }
                ctx.lineTo(points[points.length - 1].x, bottom)
                if (chart.hourly) {
                    ctx.lineTo(right, bottom)
                }
                ctx.closePath()
                ctx.fillStyle = Theme.accentSoft
                ctx.fill()

                ctx.beginPath()
                ctx.moveTo(points[0].x, points[0].y)
                for (p = 1; p < points.length; ++p) {
                    midX = (points[p - 1].x + points[p].x) / 2
                    ctx.bezierCurveTo(midX, points[p - 1].y, midX, points[p].y, points[p].x, points[p].y)
                }
                ctx.strokeStyle = Theme.accent
                ctx.lineWidth = 2.5
                ctx.lineCap = "round"
                ctx.stroke()

                if (count <= 80) {
                    ctx.fillStyle = Theme.panelRaised
                    ctx.strokeStyle = Theme.accent
                    ctx.lineWidth = 2
                    for (p = 0; p < points.length; ++p) {
                        ctx.beginPath()
                        ctx.arc(points[p].x, points[p].y, 3.5, 0, Math.PI * 2)
                        ctx.fill()
                        ctx.stroke()
                    }
                }
            }

            Connections {
                target: Theme

                function onDarkChanged() {
                    canvas.requestPaint()
                }

                function onAccentIndexChanged() {
                    canvas.requestPaint()
                }
            }
        }

        Repeater {
            model: chart.labelModel

            delegate: Text {
                width: chart.labelWidth
                x: Math.max(0, Math.min(chart.width - width, modelData.position * (chart.width - 16) + 8 - width / 2))
                y: chart.height - (chart.hourly ? 23 : 18)
                text: modelData.label
                color: Theme.muted
                font.pixelSize: chart.labelFontSize
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        Text {
            anchors.left: parent.left
            anchors.top: parent.top
            text: page.formatNumber(chart.maxTokens)
            color: Theme.dim
            font.pixelSize: 10
        }

        onModelChanged: canvas.requestPaint()
        onHourlyChanged: canvas.requestPaint()
        onWidthChanged: canvas.requestPaint()
        onHeightChanged: canvas.requestPaint()
    }
}
