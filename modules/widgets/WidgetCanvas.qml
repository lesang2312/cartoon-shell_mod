import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.commons
import qs.components
import qs.services
import "." as Widgets

PanelWindow {
    id: root

    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    margins { top: 0; bottom: 0; left: 0; right: 0 }

    property bool managerOpen: false
    property var widgetRegistry: [
        { id: "main-clock", name: "Pixel clock", emoji: "◷" },
        { id: "calendar", name: "Lịch tháng", emoji: "▦" },
        { id: "clock-summary", name: "Thời tiết & giờ", emoji: "☁" },
        { id: "music-player", name: "Trình phát nhạc", emoji: "♫" },
        { id: "sticky-note", name: "Sticky note", emoji: "✎" },
        { id: "calculator", name: "Máy tính", emoji: "✧" },
        { id: "battery", name: "Pin hệ thống", emoji: "▰" },
        { id: "cute-habits", name: "Cute habits", emoji: "♡" },
        { id: "system-usage", name: "Activity Monitor", emoji: "◌" },
        { id: "photo-frame", name: "Photo Frame", emoji: "▧" }
    ]

    function allHidden(...items) {
        return items.every(item => !VisibleService.getPanelVisible(item) || false);
    }

    property bool visibleCalendarWidget: root.allHidden("launcher", "music", "cpu", "ram", "dashboard", "weather", "keybind", "packagePanel")
    property bool visibleClockSummaryWidget: root.allHidden("launcher", "music", "cpu", "ram", "dashboard", "weather", "keybind", "packagePanel")
    property bool visibleMusicWidget: root.allHidden("cpu", "ram", "dashboard", "weather", "keybind", "packagePanel")
    property bool visibleProductivityWidget: root.allHidden("cpu", "ram", "dashboard", "weather", "keybind", "packagePanel", "wifi", "bluetooth", "mixer")
    property bool visibleSystemWidget: root.allHidden("cpu", "ram", "dashboard", "weather", "keybind", "packagePanel", "wifi")
    property bool visibleCuteWidgets: root.allHidden("cpu", "ram", "dashboard", "weather", "keybind", "packagePanel", "wifi", "bluetooth", "mixer")

    // Every widget is an independent placement. Drag coordinates and visibility persist across restarts.
    Widgets.WidgetPlacement {
        widgetId: "main-clock"
        widgetName: "Pixel clock"
        iconGlyph: "◷"
        defaultXRatio: 0.39
        defaultYRatio: 0.13
        sourceUrl: "clock/Clock2.qml"
        widgetVisible: WidgetLayoutService.isWidgetVisible("main-clock")
        z: 1
    }

    Widgets.WidgetPlacement {
        widgetId: "calendar"
        widgetName: "Lịch tháng"
        iconGlyph: "▦"
        defaultXRatio: 0.01
        defaultYRatio: 0.075
        sourceUrl: "calendar/CalendarWidget.qml"
        widgetVisible: root.visibleCalendarWidget && WidgetLayoutService.isWidgetVisible("calendar")
        z: 2
    }

    Widgets.WidgetPlacement {
        widgetId: "clock-summary"
        widgetName: "Thời tiết & giờ"
        iconGlyph: "☁"
        defaultXRatio: 0.01
        defaultYRatio: 0.455
        sourceUrl: "clock/ClockWidget.qml"
        widgetVisible: root.visibleClockSummaryWidget && WidgetLayoutService.isWidgetVisible("clock-summary")
        z: 2
    }

    Widgets.WidgetPlacement {
        widgetId: "music-player"
        widgetName: "Trình phát nhạc"
        iconGlyph: "♫"
        defaultXRatio: 0.01
        defaultYRatio: 0.695
        sourceUrl: "player/PlayerWidget.qml"
        widgetVisible: root.visibleMusicWidget && WidgetLayoutService.isWidgetVisible("music-player")
        z: 2
    }

    Widgets.WidgetPlacement {
        widgetId: "sticky-note"
        widgetName: "Sticky note"
        iconGlyph: "✎"
        defaultXRatio: 0.26
        defaultYRatio: 0.38
        sourceUrl: Qt.resolvedUrl("productivity/NotesWidget.qml")
        widgetVisible: WidgetLayoutService.isWidgetVisible("sticky-note")
        z: 4
    }

    Widgets.WidgetPlacement {
        widgetId: "calculator"
        widgetName: "Máy tính"
        iconGlyph: "✧"
        defaultXRatio: 0.505
        defaultYRatio: 0.355
        sourceUrl: "productivity/CalculatorWidget.qml"
        widgetVisible: WidgetLayoutService.isWidgetVisible("calculator")
        z: 4
    }

    Widgets.WidgetPlacement {
        widgetId: "battery"
        widgetName: "Pin hệ thống"
        iconGlyph: "◉"
        defaultXRatio: 0.515
        defaultYRatio: 0.72
        sourceUrl: "productivity/BatteryWidget.qml"
        widgetVisible: WidgetLayoutService.isWidgetVisible("battery")
        z: 4
    }

    Widgets.WidgetPlacement {
        widgetId: "cute-habits"
        widgetName: "Cute habits"
        iconGlyph: "♡"
        defaultXRatio: 0.755
        defaultYRatio: 0.425
        sourceUrl: "cute/CuteWidgets.qml"
        widgetVisible: root.visibleCuteWidgets && WidgetLayoutService.isWidgetVisible("cute-habits")
        z: 3
    }

    Widgets.WidgetPlacement {
        widgetId: "system-usage"
        widgetName: "Activity Monitor"
        iconGlyph: "◌"
        defaultXRatio: 0.755
        defaultYRatio: 0.69
        sourceUrl: "system/SystemWidget.qml"
        widgetVisible: root.visibleSystemWidget && WidgetLayoutService.isWidgetVisible("system-usage")
        z: 3
    }

    Widgets.WidgetPlacement {
        widgetId: "photo-frame"
        widgetName: "Photo Frame"
        iconGlyph: "▧"
        defaultXRatio: 0.27
        defaultYRatio: 0.69
        sourceUrl: Qt.resolvedUrl("productivity/PhotoWidget.qml")
        widgetVisible: WidgetLayoutService.isWidgetVisible("photo-frame")
        z: 4
    }

    // Widget manager remains available even when every widget is hidden.
    Rectangle {
        id: managerPanel
        width: ScalerService.s(340)
        height: ScalerService.s(500)
        x: Math.max(ScalerService.s(8), (root.width - width) / 2)
        y: Math.max(ScalerService.s(8), Math.min(root.height - height - ScalerService.s(8), layoutToolbar.y - height - ScalerService.s(10)))
        radius: ScalerService.s(18)
        visible: root.managerOpen
        z: 1001
        color: Qt.rgba(Qt.color(theme.primary.background).r, Qt.color(theme.primary.background).g, Qt.color(theme.primary.background).b, 0.96)
        border.color: WidgetLayoutService.editMode ? theme.normal.blue : Qt.rgba(Qt.color(theme.button.border).r, Qt.color(theme.button.border).g, Qt.color(theme.button.border).b, 0.82)
        border.width: ScalerService.s(2)
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(10)
            spacing: ScalerService.s(6)

            RowLayout {
                Layout.fillWidth: true
                Text { text: "▦"; color: theme.normal.blue; font.pixelSize: ScalerService.s(20) }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: "Quản lý widget"; color: theme.button.text; font.pixelSize: ScalerService.s(15); font.bold: true }
                    Text { text: "Bật/tắt, kéo thả và đổi kích thước"; color: theme.primary.dim_foreground; font.pixelSize: ScalerService.s(9) }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(25)
                    Layout.preferredHeight: ScalerService.s(25)
                    radius: ScalerService.s(8)
                    color: Qt.rgba(1, 1, 1, 0.06)
                    Text { anchors.centerIn: parent; text: "×"; color: theme.button.text; font.pixelSize: ScalerService.s(17) }
                    MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor ;onClicked: root.managerOpen = false }
                }
            }

            Repeater {
                model: root.widgetRegistry
                delegate: Rectangle {
                    id: managerRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScalerService.s(27)
                    radius: ScalerService.s(8)
                    property bool enabledWidget: WidgetLayoutService.isWidgetVisible(modelData.id)
                    property bool compactWidget: WidgetLayoutService.isWidgetMinimized(modelData.id)
                    property real scaleValue: WidgetLayoutService.widgetScale(modelData.id)
                    color: Qt.rgba(Qt.color(enabledWidget ? theme.normal.green : theme.normal.red).r,
                                   Qt.color(enabledWidget ? theme.normal.green : theme.normal.red).g,
                                   Qt.color(enabledWidget ? theme.normal.green : theme.normal.red).b, 0.10)
                    border.color: Qt.rgba(Qt.color(enabledWidget ? theme.normal.green : theme.normal.red).r,
                                          Qt.color(enabledWidget ? theme.normal.green : theme.normal.red).g,
                                          Qt.color(enabledWidget ? theme.normal.green : theme.normal.red).b, 0.28)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: ScalerService.s(9)
                        anchors.rightMargin: ScalerService.s(138)
                        spacing: ScalerService.s(6)
                        Text { text: managerRow.modelData.emoji; color: theme.button.text; font.pixelSize: ScalerService.s(13) }
                        Text { text: managerRow.modelData.name; color: theme.button.text; font.pixelSize: ScalerService.s(11); Layout.fillWidth: true; elide: Text.ElideRight }
                        Text { text: managerRow.enabledWidget ? "Hiện ✓" : "Ẩn  ○"; color: managerRow.enabledWidget ? theme.normal.green : theme.primary.dim_foreground; font.pixelSize: ScalerService.s(10); font.bold: true }
                    }
                    MouseArea {
                        anchors.fill: parent
                        anchors.rightMargin: ScalerService.s(138)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WidgetLayoutService.toggleWidgetVisible(managerRow.modelData.id)
                    }
                    // Decrease actual rendered size by 5% per click.
                    Rectangle {
                        x: parent.width - width - ScalerService.s(117)
                        y: (parent.height - height) / 2
                        width: ScalerService.s(21)
                        height: ScalerService.s(21)
                        radius: ScalerService.s(7)
                        color: Qt.rgba(1, 1, 1, 0.07)
                        border.color: Qt.rgba(Qt.color(theme.button.border).r, Qt.color(theme.button.border).g, Qt.color(theme.button.border).b, 0.45)
                        Text { anchors.centerIn: parent; text: "−"; color: theme.button.text; font.pixelSize: ScalerService.s(15); font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WidgetLayoutService.adjustWidgetScale(managerRow.modelData.id, -0.05)
                        }
                    }
                    Rectangle {
                        x: parent.width - width - ScalerService.s(84)
                        y: (parent.height - height) / 2
                        width: ScalerService.s(30)
                        height: ScalerService.s(21)
                        radius: ScalerService.s(6)
                        color: Qt.rgba(Qt.color(theme.normal.blue).r, Qt.color(theme.normal.blue).g, Qt.color(theme.normal.blue).b, 0.13)
                        Text { anchors.centerIn: parent; text: Math.round(managerRow.scaleValue * 100) + "%"; color: theme.button.text; font.pixelSize: ScalerService.s(8); font.bold: true }
                    }
                    Rectangle {
                        x: parent.width - width - ScalerService.s(60)
                        y: (parent.height - height) / 2
                        width: ScalerService.s(21)
                        height: ScalerService.s(21)
                        radius: ScalerService.s(7)
                        color: Qt.rgba(1, 1, 1, 0.07)
                        border.color: Qt.rgba(Qt.color(theme.button.border).r, Qt.color(theme.button.border).g, Qt.color(theme.button.border).b, 0.45)
                        Text { anchors.centerIn: parent; text: "+"; color: theme.button.text; font.pixelSize: ScalerService.s(14); font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WidgetLayoutService.adjustWidgetScale(managerRow.modelData.id, 0.05)
                        }
                    }
                    Rectangle {
                        x: parent.width - width - ScalerService.s(5)
                        y: (parent.height - height) / 2
                        width: ScalerService.s(51)
                        height: ScalerService.s(21)
                        radius: ScalerService.s(7)
                        color: managerRow.compactWidget ? Qt.rgba(Qt.color(theme.normal.blue).r, Qt.color(theme.normal.blue).g, Qt.color(theme.normal.blue).b, 0.22) : Qt.rgba(1, 1, 1, 0.07)
                        border.color: Qt.rgba(Qt.color(theme.button.border).r, Qt.color(theme.button.border).g, Qt.color(theme.button.border).b, 0.45)
                        Text { anchors.centerIn: parent; text: managerRow.compactWidget ? "Mở rộng ↗" : "Thu gọn"; color: theme.button.text; font.pixelSize: ScalerService.s(8); font.bold: true }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WidgetLayoutService.toggleWidgetMinimized(managerRow.modelData.id)
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(6)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScalerService.s(28)
                    radius: ScalerService.s(8)
                    color: Qt.rgba(Qt.color(theme.normal.green).r, Qt.color(theme.normal.green).g, Qt.color(theme.normal.green).b, 0.16)
                    Text { anchors.centerIn: parent; text: "Hiện tất cả"; color: theme.button.text; font.pixelSize: ScalerService.s(10); font.bold: true }
                    MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor ;onClicked: WidgetLayoutService.setAllWidgetsVisible(true, ["main-clock", "calendar", "clock-summary", "music-player", "sticky-note", "calculator", "battery", "cute-habits", "system-usage", "photo-frame"]) }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: ScalerService.s(28)
                    radius: ScalerService.s(8)
                    color: Qt.rgba(Qt.color(theme.normal.red).r, Qt.color(theme.normal.red).g, Qt.color(theme.normal.red).b, 0.13)
                    Text { anchors.centerIn: parent; text: "Ẩn tất cả"; color: theme.button.text; font.pixelSize: ScalerService.s(10); font.bold: true }
                    MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor ;onClicked: WidgetLayoutService.setAllWidgetsVisible(false, ["main-clock", "calendar", "clock-summary", "music-player", "sticky-note", "calculator", "battery", "cute-habits", "system-usage", "photo-frame"]) }
                }
            }
        }
    }

    // Layout tools stay visible even if widgets are hidden.
    Item {
        id: layoutToolbar
        width: ScalerService.s(320)
        height: ScalerService.s(38)
        x: Math.max(ScalerService.s(8), (root.width - width) / 2)
        y: Math.max(ScalerService.s(8), root.height - height - ScalerService.s(14))
        z: 1002

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(Qt.color(theme.primary.background).r, Qt.color(theme.primary.background).g, Qt.color(theme.primary.background).b, 0.94)
            border.color: WidgetLayoutService.editMode ? theme.normal.blue : Qt.rgba(Qt.color(theme.button.border).r, Qt.color(theme.button.border).g, Qt.color(theme.button.border).b, 0.76)
            border.width: WidgetLayoutService.editMode ? ScalerService.s(2) : 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: ScalerService.s(4)
                spacing: ScalerService.s(4)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: ScalerService.s(82)
                    radius: height / 2
                    color: WidgetLayoutService.editMode ? Qt.rgba(Qt.color(theme.normal.blue).r, Qt.color(theme.normal.blue).g, Qt.color(theme.normal.blue).b, 0.21) : "transparent"
                    Text { anchors.centerIn: parent; text: WidgetLayoutService.editMode ? "✥  Đang sắp xếp" : "✥  Sắp xếp"; color: theme.button.text; font.pixelSize: ScalerService.s(11); font.bold: true }
                    MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor ;onClicked: WidgetLayoutService.editMode = !WidgetLayoutService.editMode }
                }

                Rectangle {
                    Layout.preferredWidth: ScalerService.s(82)
                    Layout.fillHeight: true
                    radius: height / 2
                    color: root.managerOpen ? Qt.rgba(Qt.color(theme.normal.blue).r, Qt.color(theme.normal.blue).g, Qt.color(theme.normal.blue).b, 0.28) : Qt.rgba(1, 1, 1, 0.06)
                    border.color: root.managerOpen ? theme.normal.blue : Qt.rgba(Qt.color(theme.button.border).r, Qt.color(theme.button.border).g, Qt.color(theme.button.border).b, 0.28)
                    Text { anchors.centerIn: parent; text: "▦  Widget"; color: theme.button.text; font.pixelSize: ScalerService.s(11); font.bold: true }
                    MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor ;onClicked: root.managerOpen = !root.managerOpen }
                }

                Rectangle {
                    visible: WidgetLayoutService.editMode
                    Layout.preferredWidth: ScalerService.s(52)
                    Layout.fillHeight: true
                    radius: height / 2
                    color: Qt.rgba(Qt.color(theme.normal.yellow).r, Qt.color(theme.normal.yellow).g, Qt.color(theme.normal.yellow).b, 0.18)
                    Text { anchors.centerIn: parent; text: "Đặt lại"; color: theme.button.text; font.pixelSize: ScalerService.s(10) }
                    MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor;onClicked: WidgetLayoutService.resetPositions() }
                }

                Rectangle {
                    visible: WidgetLayoutService.editMode
                    Layout.preferredWidth: ScalerService.s(57)
                    Layout.fillHeight: true
                    radius: height / 2
                    color: Qt.rgba(Qt.color(theme.normal.green).r, Qt.color(theme.normal.green).g, Qt.color(theme.normal.green).b, 0.25)
                    Text { anchors.centerIn: parent; text: "Xong ✓"; color: theme.button.text; font.pixelSize: ScalerService.s(10); font.bold: true }
                    MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor;onClicked: WidgetLayoutService.editMode = false }
                }
            }
        }
    }
}
