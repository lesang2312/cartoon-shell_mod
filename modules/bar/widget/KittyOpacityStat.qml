import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Hyprland
import qs.commons
import qs.components
import qs.services

Item {
    id: root

    property bool isVertical: false
    // Màu nhấn dùng chung cho check-mark, viền hover, highlight... đồng bộ với viền cyan của card
    readonly property color accentColor: Qt.rgba(0x4F / 255, 0xC3 / 255, 0xF7 / 255, 1)

    implicitWidth: gauge.implicitWidth
    implicitHeight: gauge.implicitHeight

    WaterDropGauge {
        id: gauge
        anchors.centerIn: parent
        fillValue: KittyOpacityService.displayOpacity
        
        // Hiệu ứng phóng to nảy nhẹ khi rê chuột vào icon giọt nước
        scale: mouseArea.containsMouse ? 1.15 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            SoundService.playSound("pick");
            popup.visible = !popup.visible;
        }

        onWheel: wheel => {
            const step = 5;
            const next = KittyOpacityService.displayOpacity + (wheel.angleDelta.y > 0 ? step : -step);
            SoundService.playSound("pop");
            KittyOpacityService.setOpacity(Math.max(0, Math.min(100, next)));
        }
    }

    onVisibleChanged: if (!visible) popup.visible = false

    Connections {
        target: VisibleService
        function onPanelChanged(panelName, visible) {
            if (visible && popup.visible)
                popup.visible = false;
        }
    }

    Timer {
        interval: 4000
        repeat: true
        running: popup.visible
        onTriggered: KittyOpacityService.refreshInstances()
    }

    HyprlandFocusGrab {
        id: focusGrab
        windows: [popup]
        onCleared: popup.visible = false
    }

    // ============ POPUP NEO VÀO ICON ============
    PopupWindow {
        id: popup
        visible: false
        grabFocus: false
        
        // TRIỆT ĐỂ VIỀN TRẮNG: Đặt nền PopupWindow trong suốt hoàn toàn
        color: "transparent"

        implicitWidth: ScalerService.s(300)
        implicitHeight: Math.ceil(cardContent.implicitHeight + ScalerService.s(28))

        anchor {
            item: root
            edges: root.isVertical ? Edges.Right : Edges.Bottom
            gravity: root.isVertical ? Edges.Right : Edges.Bottom
            margins {
                left: root.isVertical ? ScalerService.s(10) : 0
                top: root.isVertical ? 0 : ScalerService.s(10)
            }
        }

        onVisibleChanged: {
            if (visible) {
                SoundService.playSound("pick");
                KittyOpacityService.refreshInstances();
                VisibleService.closeAllPanels();
                openAnimation.restart();
            } else {
                openAnimation.stop();
                card.opacity = 0; card.scale = 0.85; card.rotation = -2;
                headerRow.opacity = 0; headerRow.scale = 0.9;
                opacitySlider.opacity = 0; opacitySlider.scale = 0.9;
                sessionRow.opacity = 0; sessionRow.scale = 0.9;
                chipsFlow.opacity = 0; chipsFlow.scale = 0.9;
                themeSection.opacity = 0; themeSection.scale = 0.9;
                fontSection.opacity = 0; fontSection.scale = 0.9;
                colorSection.opacity = 0; colorSection.scale = 0.9;
                // Nếu đang preview theme/font dở dang mà đóng popup -> khôi phục về trạng thái đã lưu
                KittyOpacityService.cancelPreview();
                KittyOpacityService.cancelFontPreview();
            }
            focusGrab.active = visible;
        }

        // ---- Hiệu ứng xuất hiện tầng bậc cực mượt & ngầu ----
        SequentialAnimation {
            id: openAnimation

            ParallelAnimation {
                NumberAnimation { target: card; property: "opacity"; to: 1; duration: 180; easing.type: Easing.OutCubic }
                NumberAnimation { target: card; property: "scale"; to: 1; duration: 250; easing.type: Easing.OutBack; easing.overshoot: 1.6 }
                NumberAnimation { target: card; property: "rotation"; to: 0; duration: 220; easing.type: Easing.OutBack }
            }
            PauseAnimation { duration: 20 }
            ParallelAnimation {
                NumberAnimation { target: headerRow; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: headerRow; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
            PauseAnimation { duration: 30 }
            ParallelAnimation {
                NumberAnimation { target: opacitySlider; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: opacitySlider; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
            PauseAnimation { duration: 30 }
            ParallelAnimation {
                NumberAnimation { target: sessionRow; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: sessionRow; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
            PauseAnimation { duration: 30 }
            ParallelAnimation {
                NumberAnimation { target: chipsFlow; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: chipsFlow; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
            PauseAnimation { duration: 30 }
            ParallelAnimation {
                NumberAnimation { target: themeSection; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: themeSection; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
            PauseAnimation { duration: 30 }
            ParallelAnimation {
                NumberAnimation { target: fontSection; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: fontSection; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
            PauseAnimation { duration: 30 }
            ParallelAnimation {
                NumberAnimation { target: colorSection; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
                NumberAnimation { target: colorSection; property: "scale"; to: 1; duration: 200; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: ScalerService.s(Settings.appearance.radius1)
            color: theme.primary.background
            clip: true
            opacity: 0
            scale: 0.85
            transformOrigin: Item.Top

            // Viền Cyan hi-tech tinh tế
            border.width: ScalerService.s(1)
            border.color: Qt.rgba(0x4F / 255, 0xC3 / 255, 0xF7 / 255, 0.3)

            ColumnLayout {
                id: cardContent
                anchors {
                    fill: parent
                    margins: ScalerService.s(16)
                }
                spacing: ScalerService.s(14)

                // Header
                RowLayout {
                    id: headerRow
                    Layout.fillWidth: true
                    spacing: ScalerService.s(12)
                    opacity: 0
                    scale: 0.9
                    transformOrigin: Item.Left

                    WaterDropGauge {
                        fillValue: KittyOpacityService.displayOpacity
                    }

                    ColumnLayout {
                        spacing: 0
                        CustomText {
                            name: "Kitty Opacity"
                            isBold: true
                            size: "small"
                        }
                        CustomText {
                            name: Math.round(KittyOpacityService.displayOpacity) + "%"
                            color: theme.primary.dim_foreground
                            size: "xs"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Nút đóng
                    Rectangle {
                        id: closeBtn
                        width: ScalerService.s(24)
                        height: ScalerService.s(24)
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, closeArea.containsMouse ? 0.15 : 0)
                        scale: closeArea.containsMouse ? 1.15 : 1.0

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 150 } }

                        IconText {
                            anchors.centerIn: parent
                            name: "close"
                            size: "xs"
                            textColor: theme.button.text
                        }

                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                SoundService.playSound("pick");
                                popup.visible = false;
                            }
                        }
                    }
                }

                // Slider
                OpacitySlider {
                    id: opacitySlider
                    Layout.fillWidth: true
                    opacity: 0
                    scale: 0.9
                    transformOrigin: Item.Left
                    from: KittyOpacityService.minOpacity * 100
                    to: KittyOpacityService.maxOpacity * 100
                    onMoved: KittyOpacityService.setOpacity(value)

                    Binding {
                        target: opacitySlider
                        property: "value"
                        value: KittyOpacityService.displayOpacity
                        when: !opacitySlider.pressed
                        restoreMode: Binding.RestoreBindingOrValue
                    }
                }

                // Danh sách phiên kitty
                RowLayout {
                    id: sessionRow
                    Layout.fillWidth: true
                    opacity: 0
                    scale: 0.9
                    transformOrigin: Item.Left
                    CustomText {
                        name: "Sessions"
                        size: "xs"
                        color: theme.primary.dim_foreground
                    }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: ScalerService.s(24)
                        height: ScalerService.s(24)
                        radius: width / 2
                        color: Qt.rgba(1, 1, 1, refreshArea.containsMouse ? 0.15 : 0)
                        scale: refreshArea.containsMouse ? 1.15 : 1.0

                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        IconText {
                            anchors.centerIn: parent
                            name: "refresh"
                            size: "xs"
                            textColor: theme.button.text
                        }
                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: KittyOpacityService.refreshInstances()
                        }
                    }
                }

                CustomText {
                    visible: !KittyOpacityService.hasInstances
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    size: "xs"
                    color: theme.primary.dim_foreground
                    name: "No kitty sessions found"
                }

                Flow {
                    id: chipsFlow
                    Layout.fillWidth: true
                    spacing: ScalerService.s(6)
                    visible: KittyOpacityService.hasInstances
                    opacity: 0
                    scale: 0.9
                    transformOrigin: Item.TopLeft

                    CustomRectangle {
                        height: ScalerService.s(26)
                        width: allLabel.implicitWidth + ScalerService.s(18)
                        radius: height / 2
                        color: KittyOpacityService.selectedSockets.length === 0
                            ? theme.button.text
                            : theme.button.background
                        border.width: ScalerService.s(1)
                        border.color: theme.button.border

                        CustomText {
                            id: allLabel
                            anchors.centerIn: parent
                            name: "All"
                            size: "xs"
                            textColor: KittyOpacityService.selectedSockets.length === 0
                                ? theme.primary.background
                                : theme.primary.foreground
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: KittyOpacityService.selectAll()
                            onEntered: parent.scale = 1.08
                            onExited: parent.scale = 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        }
                    }

                    Repeater {
                        model: KittyOpacityService.instances
                        delegate: CustomRectangle {
                            required property var modelData
                            readonly property bool selected: KittyOpacityService.selectedSockets.includes(modelData.socket)

                            height: ScalerService.s(26)
                            width: chipLabel.implicitWidth + ScalerService.s(18)
                            radius: height / 2
                            color: selected ? theme.button.text : theme.button.background
                            border.width: ScalerService.s(1)
                            border.color: theme.button.border

                            CustomText {
                                id: chipLabel
                                anchors.centerIn: parent
                                name: modelData.label
                                size: "xs"
                                textColor: selected ? theme.primary.background : theme.primary.foreground
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KittyOpacityService.toggleSelected(modelData.socket)
                                onEntered: parent.scale = 1.08
                                onExited: parent.scale = 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                }

                // ============ CHỌN THEME ============
                // Rê chuột vào 1 theme -> xem trước ngay trên các kitty đang mở (chưa lưu).
                // Bấm chọn -> áp dụng thật sự và hiện dấu tích bên cạnh theme đó.
                ColumnLayout {
                    id: themeSection
                    Layout.fillWidth: true
                    spacing: ScalerService.s(6)
                    opacity: 0
                    scale: 0.9
                    transformOrigin: Item.TopLeft

                    RowLayout {
                        Layout.fillWidth: true
                        CustomText {
                            name: "Theme"
                            size: "xs"
                            color: theme.primary.dim_foreground
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: ScalerService.s(24)
                            height: ScalerService.s(24)
                            radius: width / 2
                            color: Qt.rgba(1, 1, 1, themeRefreshArea.containsMouse ? 0.15 : 0)
                            scale: themeRefreshArea.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                            IconText {
                                anchors.centerIn: parent
                                name: "refresh"
                                size: "xs"
                                textColor: theme.button.text
                            }
                            MouseArea {
                                id: themeRefreshArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KittyOpacityService.scanThemes()
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(ScalerService.s(150), Math.max(themeColumn.implicitHeight, ScalerService.s(30)))
                        contentWidth: width
                        contentHeight: themeColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: themeColumn
                            width: parent.width
                            spacing: ScalerService.s(2)

                            Repeater {
                                model: KittyOpacityService.themes
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isCurrent: KittyOpacityService.currentThemeName === modelData.name

                                    Layout.fillWidth: true
                                    height: ScalerService.s(30)
                                    radius: ScalerService.s(6)
                                    color: isCurrent
                                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                                        : Qt.rgba(1, 1, 1, themeItemArea.containsMouse ? 0.07 : 0)
                                    border.width: isCurrent ? ScalerService.s(1) : 0
                                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: ScalerService.s(8)
                                        anchors.rightMargin: ScalerService.s(8)
                                        spacing: ScalerService.s(8)

                                        // Chấm màu xem trước (nền/viền chữ) của theme
                                        Rectangle {
                                            width: ScalerService.s(14)
                                            height: ScalerService.s(14)
                                            radius: width / 2
                                            color: modelData.background
                                            border.width: ScalerService.s(1)
                                            border.color: modelData.foreground
                                        }

                                        CustomText {
                                            name: modelData.name
                                            size: "xs"
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Dấu tích: chỉ hiện ở theme ĐANG được áp dụng chính thức
                                        IconText {
                                            visible: isCurrent
                                            name: "check"
                                            size: "xs"
                                            textColor: root.accentColor
                                        }
                                    }

                                    MouseArea {
                                        id: themeItemArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        // Di chuột vào -> xem trước live, chưa lưu
                                        onEntered: KittyOpacityService.previewTheme(modelData.path)
                                        // Rời chuột ra mà chưa bấm chọn -> khôi phục màu cũ
                                        onExited: KittyOpacityService.cancelPreview()
                                        // Bấm chọn -> áp dụng thật, hiện dấu tích
                                        onClicked: {
                                            SoundService.playSound("pick");
                                            KittyOpacityService.applyTheme(modelData.path, modelData.name);
                                        }
                                    }
                                }
                            }

                            CustomText {
                                visible: KittyOpacityService.themes.length === 0
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                size: "xs"
                                color: theme.primary.dim_foreground
                                name: "No themes found"
                            }
                        }
                    }
                }

                // ============ CHỌN FONT ============
                // Rê chuột vào 1 font -> xem trước ngay trên các kitty đang mở (chưa lưu).
                // Bấm chọn -> ghi vào kitty.conf và hiện dấu tích bên cạnh font đó.
                ColumnLayout {
                    id: fontSection
                    Layout.fillWidth: true
                    spacing: ScalerService.s(6)
                    opacity: 0
                    scale: 0.9
                    transformOrigin: Item.TopLeft

                    RowLayout {
                        Layout.fillWidth: true
                        CustomText {
                            name: "Font"
                            size: "xs"
                            color: theme.primary.dim_foreground
                        }
                        Item { Layout.fillWidth: true }
                        Rectangle {
                            width: ScalerService.s(24)
                            height: ScalerService.s(24)
                            radius: width / 2
                            color: Qt.rgba(1, 1, 1, fontRefreshArea.containsMouse ? 0.15 : 0)
                            scale: fontRefreshArea.containsMouse ? 1.15 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                            IconText {
                                anchors.centerIn: parent
                                name: "refresh"
                                size: "xs"
                                textColor: theme.button.text
                            }
                            MouseArea {
                                id: fontRefreshArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: KittyOpacityService.scanFonts()
                            }
                        }
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.min(ScalerService.s(150), Math.max(fontColumn.implicitHeight, ScalerService.s(30)))
                        contentWidth: width
                        contentHeight: fontColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: fontColumn
                            width: parent.width
                            spacing: ScalerService.s(2)

                            Repeater {
                                model: KittyOpacityService.fonts
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool isCurrent: KittyOpacityService.currentFontName === modelData.name

                                    Layout.fillWidth: true
                                    height: ScalerService.s(30)
                                    radius: ScalerService.s(6)
                                    color: isCurrent
                                        ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.16)
                                        : Qt.rgba(1, 1, 1, fontItemArea.containsMouse ? 0.07 : 0)
                                    border.width: isCurrent ? ScalerService.s(1) : 0
                                    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.5)

                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: ScalerService.s(8)
                                        anchors.rightMargin: ScalerService.s(8)
                                        spacing: ScalerService.s(8)

                                        // Chữ "Aa" hiển thị bằng chính font đó để xem trước nhanh kiểu chữ
                                        CustomText {
                                            name: "Aa"
                                            size: "xs"
                                            font.family: modelData.name
                                            color: theme.primary.dim_foreground
                                        }

                                        CustomText {
                                            name: modelData.name
                                            size: "xs"
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }

                                        // Dấu tích: chỉ hiện ở font ĐANG được áp dụng chính thức
                                        IconText {
                                            visible: isCurrent
                                            name: "check"
                                            size: "xs"
                                            textColor: root.accentColor
                                        }
                                    }

                                    MouseArea {
                                        id: fontItemArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        // Rê chuột vào -> preview live font đó trên terminal thật (chưa lưu)
                                        onEntered: KittyOpacityService.previewFont(modelData.name)
                                        // Rê chuột ra mà CHƯA bấm chọn -> tự khôi phục về font trước đó
                                        onExited: KittyOpacityService.cancelFontPreview()
                                        // Bấm chọn -> mới thực sự ghi vào kitty.conf và áp dụng cho terminal, hiện dấu tích
                                        onClicked: {
                                            SoundService.playSound("pick");
                                            KittyOpacityService.applyFont(modelData.name);
                                        }
                                    }
                                }
                            }

                            CustomText {
                                visible: KittyOpacityService.fonts.length === 0
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                size: "xs"
                                color: theme.primary.dim_foreground
                                name: "No fonts found in " + (KittyOpacityService.userFontDir || "~/.local/share/fonts")
                            }
                        }
                    }
                }

                // ============ MÀU CHỮ TÙY CHỈNH (độc lập với theme) ============
                RowLayout {
                    id: colorSection
                    Layout.fillWidth: true
                    spacing: ScalerService.s(10)
                    opacity: 0
                    scale: 0.9
                    transformOrigin: Item.TopLeft

                    CustomText {
                        name: "Custom Text Color"
                        size: "xs"
                        color: theme.primary.dim_foreground
                    }

                    Item { Layout.fillWidth: true }

                    // Nút chọn màu: vòng nhấn cyan bao quanh, đẹp và nổi bật hơn ô vuông thường
                    Rectangle {
                        width: ScalerService.s(28)
                        height: ScalerService.s(28)
                        radius: width / 2
                        color: "transparent"
                        border.width: ScalerService.s(1.5)
                        border.color: fgSwatchArea.containsMouse
                            ? root.accentColor
                            : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.35)
                        scale: fgSwatchArea.containsMouse ? 1.1 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width - ScalerService.s(8)
                            height: width
                            radius: width / 2
                            color: KittyOpacityService.customForeground
                        }

                        MouseArea {
                            id: fgSwatchArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                fgColorDialog.selectedColor = KittyOpacityService.customForeground;
                                fgColorDialog.open();
                            }
                        }
                    }
                }
            }
        }
    }

    // Chuyển QColor -> "#rrggbb" (bỏ kênh alpha) để truyền cho kitty set-colors
    function hexOf(c) {
        return "#" + c.toString().slice(-6);
    }

    ColorDialog {
        id: fgColorDialog
        title: "Choose Kitty Text Color"
        onAccepted: KittyOpacityService.applyCustomForegroundColor(root.hexOf(selectedColor))
    }
}