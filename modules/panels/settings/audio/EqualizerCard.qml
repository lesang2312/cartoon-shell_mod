import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.commons

// Equalizer 10 băng tần.
//  - Một hệ toạ độ duy nhất (stage.yOf) cho đường cong, thanh và núm => luôn khớp nhau.
//  - Kéo ngang qua nhiều band để "vẽ" đường cong; cuộn chuột = ±0.5 dB;
//    chuột phải / nhấp đúp = về 0 dB; gần 0 dB có hút từ (detent).
//  - Đổi preset: các band dâng lên lần lượt như sóng (ripple), có nảy nhẹ.
//  - Chỉ vẽ lại khi có thay đổi (không có animation chạy nền => không tốn CPU lúc rảnh).
Rectangle {
    id: root

    readonly property var eq: EqualizerService
    readonly property color accent: theme.button.text
    // màu thứ hai suy ra từ accent của theme (lệch hue) => hợp mọi theme
    readonly property color accent2: Qt.hsla((Math.max(0, accent.hslHue) + 0.09) % 1, accent.hslSaturation, Math.max(0.52, Math.min(0.78, accent.hslLightness)), 1)

    // 0 = tắt, 1 = bật (chạy mượt)
    property real power: eq.enabled ? 1 : 0
    Behavior on power { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
    onPowerChanged: wave.requestPaint()
    onAccentChanged: wave.requestPaint()

    property bool armed: false      // false => các band nằm ở 0, true => dâng lên đúng giá trị (intro)
    property bool ripple: true      // true => các band chạy lệch pha theo thứ tự
    property int hoverBand: -1
    property int activeBand: -1
    property var shown: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]   // giá trị đang hiển thị (đã animate)

    function fmtDb(v) {
        if (v === 0)
            return "0 dB";
        return (v > 0 ? "+" : "−") + Math.abs(v).toFixed(1) + " dB";
    }

    function triggerRipple() {
        ripple = true;
        rippleOff.restart();
    }

    Timer {
        id: introTimer
        interval: 90
        running: true
        onTriggered: root.armed = true
    }
    Timer {
        id: rippleOff
        interval: 1200
        running: true
        onTriggered: root.ripple = false
    }

    Layout.fillWidth: true
    implicitHeight: col.implicitHeight + ScalerService.s(36)
    radius: ScalerService.s(Settings.appearance.radius2)
    color: Qt.alpha(theme.primary.dim_background, 0.6)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
    border.color: theme.button.border

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: ScalerService.s(18)
        spacing: ScalerService.s(14)

        // ================= Header =================
        RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(10)

            ColumnLayout {
                spacing: 0
                Text {
                    text: AutoTranslateService.t("Equalizer")
                    color: root.accent
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(17); bold: true }
                }
                Text {
                    text: root.eq.enabled ? (root.eq.preset + "  ·  10 band") : AutoTranslateService.t("Off  ·  bật công tắc để áp dụng")
                    color: theme.primary.dim_foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
                }
            }

            Item { Layout.fillWidth: true }

            // "Saved"
            Rectangle {
                visible: opacity > 0.01
                opacity: root.eq.justSaved ? 1 : 0
                scale: root.eq.justSaved ? 1 : 0.85
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                implicitWidth: savedText.implicitWidth + ScalerService.s(18)
                implicitHeight: ScalerService.s(24)
                radius: height / 2
                color: Qt.alpha(root.accent, 0.18)
                border.width: ScalerService.s(1)
                border.color: Qt.alpha(root.accent, 0.5)
                Text {
                    id: savedText
                    anchors.centerIn: parent
                    text: AutoTranslateService.t("✓ Saved")
                    color: root.accent
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); bold: true }
                }
            }

            // Reset (chỉ hiện khi khác Flat)
            Rectangle {
                id: resetBtn
                readonly property bool needed: root.eq.preset !== "Flat"
                visible: opacity > 0.01
                opacity: needed ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 220 } }
                implicitWidth: resetText.implicitWidth + ScalerService.s(22)
                implicitHeight: ScalerService.s(26)
                radius: height / 2
                color: resetMa.containsMouse ? Qt.alpha(theme.button.background_select, 0.9) : Qt.alpha(theme.button.background, 0.7)
                scale: resetMa.pressed ? 0.93 : 1
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Text {
                    id: resetText
                    anchors.centerIn: parent
                    text: AutoTranslateService.t("↺  Reset")
                    color: theme.primary.foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
                }
                MouseArea {
                    id: resetMa
                    anchors.fill: parent
                    enabled: resetBtn.needed
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.triggerRipple();
                        root.eq.setPreset("Flat");
                    }
                }
            }

            CustomToggleSwitch {
                adapter: root.eq.enabled
                onClicked: root.eq.setEnabled(!root.eq.enabled)
            }
        }

        Text {
            visible: root.eq.lastError !== ""
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "⚠ " + root.eq.lastError
            color: theme.normal.red
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(11) }
        }

        // ================= Mặt đài =================
        Rectangle {
            id: plate
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(246)
            radius: ScalerService.s(16)
            color: Qt.alpha("#000000", 0.20)
            border.width: ScalerService.s(1)
            border.color: Qt.alpha("#ffffff", 0.07)

            Item {
                id: stage
                anchors.fill: parent
                anchors.leftMargin: ScalerService.s(6)
                anchors.rightMargin: ScalerService.s(10)
                anchors.topMargin: ScalerService.s(12)
                anchors.bottomMargin: ScalerService.s(8)

                // --- hình học dùng chung ---
                readonly property real gutter: ScalerService.s(34)
                readonly property real plotX: gutter
                readonly property real plotW: width - gutter
                readonly property real cw: plotW / 10
                readonly property real tTop: ScalerService.s(6)
                readonly property real labelH: ScalerService.s(22)
                readonly property real tH: height - tTop - labelH
                readonly property real inset: ScalerService.s(10)
                readonly property real yHi: tTop + inset
                readonly property real yLo: tTop + tH - inset

                function yOf(v) {
                    return yHi + (1 - (v + 12) / 24) * (yLo - yHi);
                }
                function valueAt(y) {
                    return Math.max(-12, Math.min(12, 12 - 24 * (y - yHi) / (yLo - yHi)));
                }

                onWidthChanged: wave.requestPaint()
                onHeightChanged: wave.requestPaint()

                // --- thang dB bên trái ---
                Repeater {
                    model: [12, 6, 0, -6, -12]
                    delegate: Text {
                        required property int modelData
                        x: 0
                        width: stage.plotX - ScalerService.s(10)
                        y: stage.yOf(modelData) - height / 2
                        horizontalAlignment: Text.AlignRight
                        text: (modelData > 0 ? "+" : (modelData < 0 ? "−" : "")) + Math.abs(modelData)
                        color: modelData === 0 ? theme.primary.foreground : theme.primary.dim_foreground
                        opacity: modelData === 0 ? 0.95 : 0.55
                        font { family: Settings.appearance.font; pixelSize: ScalerService.s(10); weight: Font.Medium }
                    }
                }

                // --- lưới + đường cong + vùng tô ---
                Canvas {
                    id: wave
                    anchors.fill: parent

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const px = stage.plotX;
                        const cw = stage.cw;
                        const pw = root.power;
                        const k = 0.40 + 0.60 * pw;       // độ "sáng" theo trạng thái bật/tắt
                        const y0 = stage.yOf(0);

                        // lưới ngang
                        const levels = [12, 6, 0, -6, -12];
                        ctx.lineWidth = 1;
                        for (let g = 0; g < levels.length; g++) {
                            const gy = Math.round(stage.yOf(levels[g])) + 0.5;
                            ctx.beginPath();
                            ctx.setLineDash(levels[g] === 0 ? [] : [2, 7]);
                            ctx.moveTo(px, gy);
                            ctx.lineTo(width, gy);
                            ctx.strokeStyle = levels[g] === 0 ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.06);
                            ctx.stroke();
                        }
                        ctx.setLineDash([]);

                        // điểm điều khiển: 10 band + 2 điểm neo hai đầu (kéo đường cong ra sát mép)
                        const pts = [];
                        pts.push({ x: px, y: stage.yOf(root.shown[0]) });
                        for (let i = 0; i < 10; i++)
                            pts.push({ x: px + (i + 0.5) * cw, y: stage.yOf(root.shown[i]) });
                        pts.push({ x: width, y: stage.yOf(root.shown[9]) });
                        const m = pts.length;

                        // Catmull-Rom => đường mượt đi qua đúng tâm từng núm
                        const samples = [];
                        const steps = 14;
                        for (let s = 0; s < m - 1; s++) {
                            const p0 = pts[Math.max(0, s - 1)];
                            const p1 = pts[s];
                            const p2 = pts[s + 1];
                            const p3 = pts[Math.min(m - 1, s + 2)];
                            for (let j = 0; j < steps; j++) {
                                const u = j / steps;
                                const u2 = u * u;
                                const u3 = u2 * u;
                                samples.push({
                                    x: 0.5 * ((2 * p1.x) + (-p0.x + p2.x) * u + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * u2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * u3),
                                    y: 0.5 * ((2 * p1.y) + (-p0.y + p2.y) * u + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * u2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * u3)
                                });
                            }
                        }
                        samples.push(pts[m - 1]);

                        function traceLine() {
                            ctx.beginPath();
                            ctx.moveTo(samples[0].x, samples[0].y);
                            for (let q = 1; q < samples.length; q++)
                                ctx.lineTo(samples[q].x, samples[q].y);
                        }
                        function traceArea() {
                            traceLine();
                            ctx.lineTo(samples[samples.length - 1].x, y0);
                            ctx.lineTo(samples[0].x, y0);
                            ctx.closePath();
                        }

                        // vùng tô giữa đường cong và 0 dB: phía trên (boost) tông hồng, phía dưới (cut) tông tím
                        ctx.save();
                        ctx.beginPath();
                        ctx.rect(0, 0, width, y0);
                        ctx.clip();
                        const gUp = ctx.createLinearGradient(0, y0, 0, stage.yOf(12));
                        gUp.addColorStop(0, Qt.alpha(root.accent, 0.04 * k));
                        gUp.addColorStop(1, Qt.alpha(root.accent, 0.40 * k));
                        ctx.fillStyle = gUp;
                        traceArea();
                        ctx.fill();
                        ctx.restore();

                        ctx.save();
                        ctx.beginPath();
                        ctx.rect(0, y0, width, height - y0);
                        ctx.clip();
                        const gDn = ctx.createLinearGradient(0, y0, 0, stage.yOf(-12));
                        gDn.addColorStop(0, Qt.alpha(root.accent2, 0.04 * k));
                        gDn.addColorStop(1, Qt.alpha(root.accent2, 0.38 * k));
                        ctx.fillStyle = gDn;
                        traceArea();
                        ctx.fill();
                        ctx.restore();

                        // nét: halo rộng -> halo vừa -> lõi
                        const stroke = ctx.createLinearGradient(px, 0, width, 0);
                        stroke.addColorStop(0, root.accent);
                        stroke.addColorStop(0.5, root.accent2);
                        stroke.addColorStop(1, root.accent);
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";
                        ctx.setLineDash(pw > 0.5 ? [] : [5, 6]);
                        ctx.strokeStyle = stroke;
                        ctx.globalAlpha = 0.07 * k;
                        ctx.lineWidth = ScalerService.s(11);
                        traceLine();
                        ctx.stroke();
                        ctx.globalAlpha = 0.16 * k;
                        ctx.lineWidth = ScalerService.s(6);
                        traceLine();
                        ctx.stroke();
                        ctx.globalAlpha = 0.45 + 0.55 * pw;
                        ctx.lineWidth = ScalerService.s(2.4);
                        traceLine();
                        ctx.stroke();
                        ctx.globalAlpha = 1;
                        ctx.setLineDash([]);
                    }
                    Component.onCompleted: requestPaint()
                }

                // --- 10 band ---
                Repeater {
                    model: 10
                    delegate: Item {
                        id: band
                        required property int index

                        readonly property real target: root.eq.bands[index]
                        property real shown: root.armed ? target : 0
                        readonly property bool pressed: root.activeBand === index
                        readonly property bool focused: pressed || (root.activeBand < 0 && root.hoverBand === index)
                        readonly property real cy: stage.yOf(shown)
                        readonly property real zy: stage.yOf(0)

                        x: stage.plotX + index * stage.cw
                        width: stage.cw
                        height: stage.height
                        z: focused ? 5 : 0

                        // Chuyển động giá trị: kéo tay = bám sát (90ms); preset/intro = sóng lệch pha + nảy nhẹ.
                        Behavior on shown {
                            SequentialAnimation {
                                PauseAnimation { duration: root.ripple && !Settings.behavior.reduceMotion ? band.index * 26 : 0 }
                                NumberAnimation {
                                    duration: root.ripple && !Settings.behavior.reduceMotion ? 560 : 90
                                    easing.type: root.ripple && !Settings.behavior.reduceMotion ? Easing.OutBack : Easing.OutQuad
                                    easing.overshoot: 1.2
                                }
                            }
                        }
                        onShownChanged: {
                            root.shown[index] = shown;
                            wave.requestPaint();
                        }
                        Component.onCompleted: root.shown[index] = shown
                        onPressedChanged: if (pressed) pulseAnim.restart()

                        // nền cột khi rê chuột
                        Rectangle {
                            anchors.fill: parent
                            anchors.leftMargin: ScalerService.s(1)
                            anchors.rightMargin: ScalerService.s(1)
                            radius: ScalerService.s(12)
                            color: Qt.alpha(root.accent, band.focused ? 0.085 : 0)
                            Behavior on color { ColorAnimation { duration: 170 } }
                        }

                        // rãnh
                        Rectangle {
                            id: track
                            x: (band.width - width) / 2
                            y: stage.tTop
                            width: ScalerService.s(8)
                            height: stage.tH
                            radius: width / 2
                            color: Qt.alpha("#ffffff", 0.08)
                        }

                        // phần tô từ 0 dB tới núm
                        Rectangle {
                            x: track.x
                            width: track.width
                            y: Math.min(band.cy, band.zy)
                            height: Math.abs(band.cy - band.zy)
                            radius: width / 2
                            opacity: 0.35 + 0.65 * root.power
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: band.shown >= 0 ? root.accent2 : root.accent }
                                GradientStop { position: 1.0; color: band.shown >= 0 ? root.accent : root.accent2 }
                            }
                        }

                        // núm
                        Item {
                            id: knob
                            x: (band.width - width) / 2
                            y: band.cy - height / 2
                            width: ScalerService.s(20)
                            height: width
                            scale: band.pressed ? 1.2 : (band.focused ? 1.1 : 1)
                            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

                            // quầng sáng gọn, không dính sang band bên cạnh
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * (band.pressed ? 2.1 : (band.focused ? 1.7 : 1.35))
                                height: width
                                radius: width / 2
                                color: Qt.alpha(root.accent, (band.pressed ? 0.30 : (band.focused ? 0.20 : 0.09)) * (0.4 + 0.6 * root.power))
                                Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                            // sóng lan khi nhấn
                            Rectangle {
                                id: pulse
                                anchors.centerIn: parent
                                width: knob.width
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: ScalerService.s(2)
                                border.color: root.accent
                                opacity: 0
                            }
                            ParallelAnimation {
                                id: pulseAnim
                                NumberAnimation { target: pulse; property: "width"; from: knob.width; to: knob.width * 3.1; duration: 540; easing.type: Easing.OutCubic }
                                NumberAnimation { target: pulse; property: "opacity"; from: 0.7; to: 0; duration: 540; easing.type: Easing.OutQuad }
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: theme.primary.foreground
                                border.width: ScalerService.s(3)
                                border.color: Qt.alpha(root.accent, 0.35 + 0.65 * root.power)
                                Behavior on border.color { ColorAnimation { duration: 250 } }
                            }
                        }

                        // bong bóng giá trị
                        Rectangle {
                            id: bubble
                            readonly property bool below: band.cy - height - ScalerService.s(18) < 0
                            width: bubbleText.implicitWidth + ScalerService.s(18)
                            height: ScalerService.s(24)
                            x: (band.width - width) / 2
                            y: below ? band.cy + ScalerService.s(18) : band.cy - height - ScalerService.s(18)
                            radius: height / 2
                            color: root.accent
                            opacity: band.focused ? 1 : 0
                            scale: band.focused ? 1 : 0.6
                            visible: opacity > 0.01
                            transformOrigin: below ? Item.Top : Item.Bottom
                            Behavior on opacity { NumberAnimation { duration: 130 } }
                            Behavior on scale { NumberAnimation { duration: 210; easing.type: Easing.OutBack } }
                            Text {
                                id: bubbleText
                                anchors.centerIn: parent
                                text: root.fmtDb(band.target)
                                color: theme.primary.background
                                font { family: Settings.appearance.font; pixelSize: ScalerService.s(11); bold: true }
                            }
                        }

                        // nhãn tần số
                        Text {
                            x: 0
                            width: band.width
                            y: stage.tTop + stage.tH + ScalerService.s(6)
                            horizontalAlignment: Text.AlignHCenter
                            text: root.eq.freqLabels[band.index]
                            color: band.focused ? root.accent : theme.primary.dim_foreground
                            Behavior on color { ColorAnimation { duration: 150 } }
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(10); weight: band.focused ? Font.Bold : Font.Medium }
                        }
                    }
                }

                // --- tương tác: một vùng chuột cho cả mặt đài ---
                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor

                    function bandAt(x) {
                        return Math.max(0, Math.min(9, Math.floor((x - stage.plotX) / stage.cw)));
                    }
                    function apply(mx, my) {
                        const i = bandAt(mx);
                        let v = stage.valueAt(my);
                        if (Math.abs(v) < 0.6)    // hút về 0 dB
                            v = 0;
                        v = Math.round(v * 2) / 2;
                        root.activeBand = i;
                        if (root.eq.bands[i] !== v)
                            root.eq.setBand(i, v);
                    }

                    onPressed: m => {
                        if (m.button === Qt.RightButton) {
                            root.eq.setBand(bandAt(m.x), 0);
                            return;
                        }
                        root.ripple = false;
                        apply(m.x, m.y);
                    }
                    onPositionChanged: m => {
                        root.hoverBand = m.x >= stage.plotX ? bandAt(m.x) : -1;
                        if (pressed && (m.buttons & Qt.LeftButton))
                            apply(m.x, m.y);
                    }
                    onReleased: root.activeBand = -1
                    onCanceled: root.activeBand = -1
                    onExited: {
                        root.hoverBand = -1;
                        root.activeBand = -1;
                    }
                    onDoubleClicked: m => {
                        if (m.button === Qt.LeftButton)
                            root.eq.setBand(bandAt(m.x), 0);
                    }
                    onWheel: w => {
                        const i = root.hoverBand >= 0 ? root.hoverBand : bandAt(w.x);
                        const step = (w.modifiers & Qt.ControlModifier ? 1 : 0.5) * (w.angleDelta.y > 0 ? 1 : -1);
                        const v = Math.max(-12, Math.min(12, root.eq.bands[i] + step));
                        root.ripple = false;
                        if (v !== root.eq.bands[i])
                            root.eq.setBand(i, v);
                    }
                }
            }
        }

        // ================= Preset =================
        Item {
            id: presets
            Layout.fillWidth: true
            readonly property int cols: 4
            readonly property real gap: ScalerService.s(8)
            readonly property real cellW: (width - gap * (cols - 1)) / cols
            readonly property real cellH: ScalerService.s(40)
            readonly property int selIndex: root.eq.presetNames.indexOf(root.eq.preset)
            Layout.preferredHeight: cellH * 2 + gap

            // nền các ô
            Repeater {
                model: root.eq.presetNames
                delegate: Rectangle {
                    required property int index
                    x: (index % presets.cols) * (presets.cellW + presets.gap)
                    y: Math.floor(index / presets.cols) * (presets.cellH + presets.gap)
                    width: presets.cellW
                    height: presets.cellH
                    radius: ScalerService.s(Settings.appearance.radius3)
                    color: chipMa.containsMouse ? Qt.alpha(theme.button.background_select, 0.8) : Qt.alpha(theme.button.background, 0.65)
                    Behavior on color { ColorAnimation { duration: 140 } }
                    scale: chipMa.pressed ? 0.95 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
                    MouseArea {
                        id: chipMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.triggerRipple();
                            root.eq.setPreset(root.eq.presetNames[index]);
                        }
                    }
                }
            }

            // ô sáng trượt giữa các preset
            Rectangle {
                id: pill
                readonly property int idx: Math.max(0, presets.selIndex)
                visible: opacity > 0.01
                opacity: presets.selIndex >= 0 ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                width: presets.cellW
                height: presets.cellH
                radius: ScalerService.s(Settings.appearance.radius3)
                x: (idx % presets.cols) * (presets.cellW + presets.gap)
                y: Math.floor(idx / presets.cols) * (presets.cellH + presets.gap)
                Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: root.accent }
                    GradientStop { position: 1.0; color: root.accent2 }
                }
            }

            // nội dung ô: hình đường cong thu nhỏ + tên
            Repeater {
                model: root.eq.presetNames
                delegate: Item {
                    id: chip
                    required property int index
                    required property string modelData
                    readonly property bool selected: presets.selIndex === index
                    x: (index % presets.cols) * (presets.cellW + presets.gap)
                    y: Math.floor(index / presets.cols) * (presets.cellH + presets.gap)
                    width: presets.cellW
                    height: presets.cellH

                    Row {
                        anchors.centerIn: parent
                        spacing: ScalerService.s(7)

                        Canvas {
                            id: mini
                            width: ScalerService.s(26)
                            height: ScalerService.s(16)
                            anchors.verticalCenter: parent.verticalCenter
                            readonly property color ink: chip.selected ? theme.primary.background : theme.primary.dim_foreground
                            onInkChanged: requestPaint()
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                const v = root.eq.presets[chip.modelData];
                                const n = v.length;
                                const pts = [];
                                for (let i = 0; i < n; i++)
                                    pts.push({ x: 1.5 + i * (width - 3) / (n - 1), y: height / 2 - (v[i] / 8) * (height / 2 - 2) });
                                ctx.strokeStyle = ink;
                                ctx.lineWidth = 1.6;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";
                                ctx.beginPath();
                                ctx.moveTo(pts[0].x, pts[0].y);
                                for (let i = 1; i < n - 1; i++) {
                                    const mx = (pts[i].x + pts[i + 1].x) / 2;
                                    const my = (pts[i].y + pts[i + 1].y) / 2;
                                    ctx.quadraticCurveTo(pts[i].x, pts[i].y, mx, my);
                                }
                                ctx.lineTo(pts[n - 1].x, pts[n - 1].y);
                                ctx.stroke();
                            }
                            Component.onCompleted: requestPaint()
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: chip.modelData
                            color: chip.selected ? theme.primary.background : theme.primary.foreground
                            Behavior on color { ColorAnimation { duration: 200 } }
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(13); bold: chip.selected }
                        }
                    }
                }
            }
        }

        // chừa chỗ cho phần trang trí (tai mèo) ở đáy panel
        Item { Layout.preferredHeight: ScalerService.s(4) }
    }
}
