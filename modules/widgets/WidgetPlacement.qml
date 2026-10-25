import QtQuick
import qs.commons
import qs.services

Item {
    id: root

    property string widgetId: ""
    property string widgetName: widgetId
    property real defaultXRatio: 0.02
    property real defaultYRatio: 0.05
    property url sourceUrl
    property bool widgetVisible: true
    property bool widgetMinimized: WidgetLayoutService.isWidgetMinimized(widgetId)
    property string iconGlyph: "▦"
    readonly property real sceneWidth: parent ? parent.width : 1920
    readonly property real sceneHeight: parent ? parent.height : 1080

    // Intrinsic widget size comes from its own QML root. A separate content host scales
    // the actual rendered widget while the placement item tracks its visual dimensions.
    readonly property real widgetScale: WidgetLayoutService.widgetScale(widgetId)
    readonly property real baseWidgetWidth: widgetLoader.item ? (widgetLoader.item.implicitWidth > 0 ? widgetLoader.item.implicitWidth : ScalerService.s(320)) : ScalerService.s(320)
    readonly property real baseWidgetHeight: widgetLoader.item ? (widgetLoader.item.implicitHeight > 0 ? widgetLoader.item.implicitHeight : ScalerService.s(240)) : ScalerService.s(240)

    width: root.widgetMinimized ? ScalerService.s(166) : root.baseWidgetWidth * root.widgetScale
    height: root.widgetMinimized ? ScalerService.s(40) : root.baseWidgetHeight * root.widgetScale
    x: WidgetLayoutService.xFor(widgetId, defaultXRatio, sceneWidth, width)
    y: WidgetLayoutService.yFor(widgetId, defaultYRatio, sceneHeight, height)
    visible: widgetVisible

    Item {
        id: contentHost
        x: 0
        y: 0
        width: root.baseWidgetWidth
        height: root.baseWidgetHeight
        scale: root.widgetScale
        transformOrigin: Item.TopLeft
        visible: root.widgetVisible && !root.widgetMinimized

        Loader {
            id: widgetLoader
            anchors.fill: parent
            source: root.sourceUrl
            active: root.widgetVisible && !root.widgetMinimized
            visible: root.widgetVisible && !root.widgetMinimized
            onStatusChanged: {
                if (status === Loader.Error)
                    console.warn("[WidgetPlacement] Failed to load widget", root.widgetId, root.sourceUrl);
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: root.widgetVisible && widgetLoader.status === Loader.Error
        radius: ScalerService.s(16)
        color: Qt.rgba(0.10, 0.13, 0.21, 0.94)
        border.color: "#FF9AA9"
        border.width: ScalerService.s(2)
        z: 90
        Text {
            anchors.centerIn: parent
            width: parent.width - ScalerService.s(24)
            text: "Không tải được widget\n" + root.widgetId
            horizontalAlignment: Text.AlignHCenter
            color: "#FFFFFF"
            wrapMode: Text.Wrap
            font.pixelSize: ScalerService.s(12)
            font.bold: true
        }
    }

    // Small macOS-like minimize control appears on hover (or in arrange mode).
    HoverHandler { id: widgetHover }

    Rectangle {
        id: minimizeButton
        x: root.width - width - ScalerService.s(8)
        y: ScalerService.s(8)
        width: ScalerService.s(27)
        height: ScalerService.s(27)
        radius: height / 2
        visible: root.widgetVisible && !root.widgetMinimized && (widgetHover.hovered || WidgetLayoutService.editMode)
        color: Qt.rgba(0.10, 0.13, 0.21, 0.92)
        border.color: Qt.rgba(0.78, 0.85, 1.0, 0.92)
        border.width: 1
        z: 95
        Text { anchors.centerIn: parent; text: "−"; color: "#FFFFFF"; font.pixelSize: ScalerService.s(19); font.bold: true }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WidgetLayoutService.setWidgetMinimized(root.widgetId, true)
        }
    }

    Rectangle {
        id: minimizedChip
        anchors.fill: parent
        visible: root.widgetVisible && root.widgetMinimized
        radius: height / 2
        color: Qt.rgba(0.10, 0.13, 0.21, 0.95)
        border.color: Qt.rgba(0.68, 0.78, 1.0, 0.95)
        border.width: ScalerService.s(1.5)
        z: 94

        Row {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(11)
            anchors.rightMargin: ScalerService.s(8)
            spacing: ScalerService.s(7)
            Text { anchors.verticalCenter: parent.verticalCenter; text: root.iconGlyph; color: "#AFC7FF"; font.pixelSize: ScalerService.s(14) }
            Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - ScalerService.s(54); text: root.widgetName || root.widgetId; color: "#F5F7FF"; font.pixelSize: ScalerService.s(10); font.bold: true; elide: Text.ElideRight }
            Text { anchors.verticalCenter: parent.verticalCenter; text: "↗"; color: "#A6E7C2"; font.pixelSize: ScalerService.s(14); font.bold: true }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: WidgetLayoutService.setWidgetMinimized(root.widgetId, false)
        }
    }

    Rectangle {
        id: dragHandle
        x: ScalerService.s(8)
        y: -height - ScalerService.s(4)
        width: ScalerService.s(112)
        height: ScalerService.s(26)
        radius: height / 2
        visible: root.widgetVisible && WidgetLayoutService.editMode
        color: Qt.rgba(Qt.color(theme.normal.blue).r, Qt.color(theme.normal.blue).g, Qt.color(theme.normal.blue).b, 0.90)
        border.color: Qt.rgba(1, 1, 1, 0.78)
        border.width: 1
        z: 100

        Text {
            anchors.centerIn: parent
            text: "⠿  Kéo widget"
            color: "#ffffff"
            font.pixelSize: ScalerService.s(11)
            font.bold: true
        }

        MouseArea{
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            
            DragHandler {
                id: dragHandler
                enabled: root.widgetVisible && WidgetLayoutService.editMode
                target: null
                property real startWidgetX: 0
                property real startWidgetY: 0
                cursorShape: Qt.PointingHandCursor

                onActiveChanged: {
                    WidgetLayoutService.draggingWidget = active;
                    WidgetLayoutService.draggingWidgetId = active ? root.widgetId : "";
                    if (active) {
                        startWidgetX = root.x;
                        startWidgetY = root.y;
                    } else {
                        WidgetLayoutService.save();
                    }
                }

                onTranslationChanged: {
                    if (!active)
                        return;
                    WidgetLayoutService.moveWidget(
                        root.widgetId,
                        startWidgetX + translation.x,
                        startWidgetY + translation.y,
                        root.sceneWidth,
                        root.sceneHeight,
                        root.width,
                        root.height
                    );
                }
            }
    }
    }

    Rectangle {
        id: hideButton
        x: root.width - width - ScalerService.s(8)
        y: -height - ScalerService.s(4)
        width: ScalerService.s(55)
        height: ScalerService.s(26)
        radius: height / 2
        visible: root.widgetVisible && WidgetLayoutService.editMode
        color: Qt.rgba(Qt.color(theme.normal.red).r, Qt.color(theme.normal.red).g, Qt.color(theme.normal.red).b, 0.90)
        border.color: Qt.rgba(1, 1, 1, 0.75)
        border.width: 1
        z: 101
        Text { anchors.centerIn: parent; text: "Ẩn ×"; color: "#ffffff"; font.pixelSize: ScalerService.s(10); font.bold: true }
        MouseArea { anchors.fill: parent;cursorShape: Qt.PointingHandCursor ;onClicked: WidgetLayoutService.setWidgetVisible(root.widgetId, false) }
    }
}
