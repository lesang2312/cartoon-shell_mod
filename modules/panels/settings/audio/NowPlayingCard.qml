import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services
import qs.components
import qs.commons

// Thẻ "đang phát": đĩa than, thông tin bài hát, spectrum động, tiến trình và điều khiển.
Rectangle {
    id: root
    readonly property var player: Players.mprisPlayer
    readonly property bool playing: player ? player.isPlaying : false
    readonly property color accent: theme.button.text
    readonly property var sink: Pipewire.defaultAudioSink
    // Compact mode is reserved for the independently resizable desktop widget.
    // Settings and the Music popup keep the full-size presentation.
    property bool compact: false
    // "short" is the compact 32-bar strip for the desktop widget; "long" is the fuller
    // 52-bar spectrum used by the Music popup and Audio Settings.
    property string visualizerMode: compact ? "short" : "long"
    readonly property bool shortVisualizer: visualizerMode === "short"
    readonly property real pad: ScalerService.s(compact ? 10 : 20)

    Layout.fillWidth: true
    // Cao theo nội dung (trước đây cố định 200px nên hàng nút bị tràn đè lên viền dưới).
    implicitHeight: row.implicitHeight + pad * 2
    radius: ScalerService.s(Settings.appearance.radius2)
    color: Qt.alpha(theme.primary.dim_background, 0.6)
    border.width: Settings.appearance.enableBorder ? ScalerService.s(2) : 0
    border.color: theme.button.border

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    // phát positionChanged mỗi giây khi đang phát
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }

    // ---------- Icon vẽ bằng vector (không phụ thuộc font emoji) ----------
    component Glyph: Shape {
        id: g
        property string kind: "play"        // play | pause | prev | next
        property color tint: "white"
        implicitWidth: ScalerService.s(18)
        implicitHeight: implicitWidth
        layer.enabled: true
        layer.samples: 4

        function pt(x, y) {
            return Qt.point(x * width, y * height);
        }
        function rc(x, y, w, h) {
            return [pt(x, y), pt(x + w, y), pt(x + w, y + h), pt(x, y + h), pt(x, y)];
        }
        readonly property var tri: kind === "play" ? [pt(0.28, 0.14), pt(0.88, 0.5), pt(0.28, 0.86), pt(0.28, 0.14)]
            : kind === "prev" ? [pt(0.90, 0.16), pt(0.38, 0.5), pt(0.90, 0.84), pt(0.90, 0.16)]
            : kind === "next" ? [pt(0.10, 0.16), pt(0.62, 0.5), pt(0.10, 0.84), pt(0.10, 0.16)] : []
        readonly property var bar1: kind === "pause" ? rc(0.22, 0.16, 0.2, 0.68)
            : kind === "prev" ? rc(0.10, 0.18, 0.13, 0.64)
            : kind === "next" ? rc(0.77, 0.18, 0.13, 0.64) : []
        readonly property var bar2: kind === "pause" ? rc(0.58, 0.16, 0.2, 0.68) : []

        ShapePath {
            fillColor: g.tri.length ? g.tint : "transparent"
            strokeColor: g.tri.length ? g.tint : "transparent"
            strokeWidth: g.tri.length ? g.width * 0.1 : -1
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: g.tri }
        }
        ShapePath {
            fillColor: g.bar1.length ? g.tint : "transparent"
            strokeColor: g.bar1.length ? g.tint : "transparent"
            strokeWidth: g.bar1.length ? g.width * 0.1 : -1
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: g.bar1 }
        }
        ShapePath {
            fillColor: g.bar2.length ? g.tint : "transparent"
            strokeColor: g.bar2.length ? g.tint : "transparent"
            strokeWidth: g.bar2.length ? g.width * 0.1 : -1
            joinStyle: ShapePath.RoundJoin
            PathPolyline { path: g.bar2 }
        }
    }

    component Speaker: Shape {
        id: sp
        property color tint: "white"
        property bool muted: false
        implicitWidth: ScalerService.s(14)
        implicitHeight: implicitWidth
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            fillColor: sp.tint
            strokeColor: sp.tint
            strokeWidth: 1
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: [Qt.point(sp.width * 0.06, sp.height * 0.38), Qt.point(sp.width * 0.28, sp.height * 0.38), Qt.point(sp.width * 0.54, sp.height * 0.15), Qt.point(sp.width * 0.54, sp.height * 0.85), Qt.point(sp.width * 0.28, sp.height * 0.62), Qt.point(sp.width * 0.06, sp.height * 0.62), Qt.point(sp.width * 0.06, sp.height * 0.38)]
            }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: sp.muted ? "transparent" : sp.tint
            strokeWidth: ScalerService.s(1.4)
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: sp.width * 0.54; centerY: sp.height * 0.5; radiusX: sp.width * 0.2; radiusY: sp.width * 0.2; startAngle: -45; sweepAngle: 90 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: sp.muted ? "transparent" : sp.tint
            strokeWidth: ScalerService.s(1.4)
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: sp.width * 0.54; centerY: sp.height * 0.5; radiusX: sp.width * 0.38; radiusY: sp.width * 0.38; startAngle: -45; sweepAngle: 90 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: sp.muted ? sp.tint : "transparent"
            strokeWidth: ScalerService.s(1.6)
            capStyle: ShapePath.RoundCap
            startX: sp.width * 0.68; startY: sp.height * 0.34
            PathLine { x: sp.width * 0.96; y: sp.height * 0.66 }
        }
        ShapePath {
            fillColor: "transparent"
            strokeColor: sp.muted ? sp.tint : "transparent"
            strokeWidth: ScalerService.s(1.6)
            capStyle: ShapePath.RoundCap
            startX: sp.width * 0.96; startY: sp.height * 0.34
            PathLine { x: sp.width * 0.68; y: sp.height * 0.66 }
        }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: ScalerService.s(root.compact ? 9 : 22)

        // ================= Đĩa than =================
        Item {
            id: discBox
            readonly property real ringW: ScalerService.s(4)
            Layout.preferredWidth: ScalerService.s(root.compact ? 88 : 150)
            Layout.preferredHeight: ScalerService.s(root.compact ? 88 : 150)
            Layout.alignment: Qt.AlignVCenter

            // quầng nhịp nhẹ quanh đĩa khi đang phát
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + ScalerService.s(14)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: ScalerService.s(7)
                border.color: Qt.alpha(root.accent, root.playing ? 0.14 : 0.04)
                Behavior on border.color { ColorAnimation { duration: 500 } }
            }

            // phần xoay: quán tính khi bắt đầu/dừng, giữ nguyên góc khi tạm dừng
            Item {
                id: disc
                anchors.fill: parent
                anchors.margins: ScalerService.s(3)
                property real angle: 0
                property real speed: 0
                rotation: angle

                // 30 fps là đủ cho đĩa quay chậm; mỗi khung vẽ còn kéo theo lớp kính phía sau nên giảm tải đáng kể.
                Timer {
                    interval: 33
                    repeat: true
                    running: (root.playing || disc.speed > 0.002) && !Settings.behavior.reduceMotion
                    onTriggered: {
                        const dt = 0.033;
                        const target = root.playing ? 1 : 0;
                        const k = 1 - Math.exp(-dt * (root.playing ? 2.2 : 1.6));
                        disc.speed += (target - disc.speed) * k;
                        disc.angle = (disc.angle + disc.speed * dt * 30) % 360;
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: theme.primary.dim_background

                    Image {
                        id: art
                        anchors.fill: parent
                        source: Players.getArtUrl(root.player)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                        opacity: status === Image.Ready ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 350 } }
                    }

                    // không có ảnh bìa => kiểu đĩa than: rãnh + nhãn
                    Item {
                        anchors.fill: parent
                        opacity: art.status === Image.Ready ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 350 } }
                        Repeater {
                            model: [0.94, 0.82, 0.70, 0.58]
                            delegate: Rectangle {
                                required property real modelData
                                anchors.centerIn: parent
                                width: parent.width * modelData
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: Qt.alpha(theme.primary.foreground, 0.07)
                            }
                        }
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width * 0.40
                            height: width
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: root.accent }
                                GradientStop { position: 1.0; color: Qt.darker(root.accent, 1.35) }
                            }
                        }
                    }
                }

                // lỗ giữa
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.12
                    height: width
                    radius: width / 2
                    color: theme.primary.background
                    border.width: ScalerService.s(1.5)
                    border.color: Qt.alpha(root.accent, 0.7)
                }
            }

            // viền cố định (không xoay) => mép luôn mịn, không răng cưa
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                antialiasing: true
                border.width: discBox.ringW
                border.color: root.accent
            }
        }

        // ================= Thông tin + điều khiển =================
        ColumnLayout {
            id: info
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: ScalerService.s(root.compact ? 3 : 6)

            Text {
                Layout.fillWidth: true
                text: root.player && root.player.trackTitle ? root.player.trackTitle : AutoTranslateService.t("No song playing")
                elide: Text.ElideRight
                color: theme.primary.foreground
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.compact ? 14 : 20); bold: true }
            }
            Text {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackArtist ? root.player.trackArtist : "Unknown Artist") : AutoTranslateService.t("Play something to get started")
                elide: Text.ElideRight
                color: theme.primary.dim_foreground
                font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.compact ? 9 : 13); weight: Font.DemiBold }
            }

            // chip thiết bị + nguồn
            RowLayout {
                spacing: ScalerService.s(root.compact ? 5 : 8)
                Rectangle {
                    implicitWidth: devRow.implicitWidth + ScalerService.s(root.compact ? 12 : 18)
                    implicitHeight: ScalerService.s(root.compact ? 19 : 26)
                    radius: height / 2
                    color: Qt.alpha(theme.button.background, 0.7)
                    border.width: ScalerService.s(1)
                    border.color: theme.button.border
                    RowLayout {
                        id: devRow
                        anchors.centerIn: parent
                        spacing: ScalerService.s(root.compact ? 3 : 6)
                        Speaker {
                            tint: theme.primary.foreground
                            muted: root.sink && root.sink.audio ? root.sink.audio.muted : false
                        }
                        Text {
                            text: root.sink ? (root.sink.nickname || root.sink.description || root.sink.name) : AutoTranslateService.t("No device")
                            color: theme.primary.foreground
                            elide: Text.ElideRight
                            Layout.maximumWidth: ScalerService.s(root.compact ? 96 : 170)
                            font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.compact ? 8 : 11); weight: Font.Medium }
                        }
                    }
                }
                Text {
                    visible: root.player !== null
                    text: "via " + (root.player ? root.player.identity : "")
                    color: theme.primary.dim_foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.compact ? 8 : 11); italic: true }
                }
            }

            // ---------- visualizer sóng nhạc ----------
            // Dải spectrum luôn hiện: nhịp động khi phát, dạng chờ dịu khi chưa phát.
            Item {
                id: spectrum
                Layout.fillWidth: true
                // Widget: short, compact bars. Popup/Settings: taller and denser spectrum.
                Layout.preferredHeight: ScalerService.s(root.shortVisualizer ? 18 : 34)
                property real phase: 0

                Timer {
                    interval: 42
                    repeat: true
                    running: root.playing && !Settings.behavior.reduceMotion
                    onTriggered: {
                        spectrum.phase = (spectrum.phase + (root.shortVisualizer ? 0.24 : 0.19)) % (Math.PI * 2);
                        spectrumCanvas.requestPaint();
                    }
                }

                Canvas {
                    id: spectrumCanvas
                    anchors.fill: parent
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const compactBars = root.shortVisualizer;
                        const count = compactBars ? 32 : 52;
                        const slot = width / count;
                        const stroke = Math.max(ScalerService.s(2), Math.min(ScalerService.s(compactBars ? 4 : 3.5), slot * (compactBars ? 0.58 : 0.62)));
                        const center = height / 2;
                        ctx.lineCap = "round";
                        for (let i = 0; i < count; i++) {
                            const a = (Math.sin(i * 0.72 + spectrum.phase) + 1) / 2;
                            const b = (Math.sin(i * 1.61 - spectrum.phase * 1.37) + 1) / 2;
                            const c = (Math.sin(i * 0.29 + spectrum.phase * 0.63) + 1) / 2;
                            const mix = a * 0.48 + b * 0.34 + c * 0.18;
                            const envelope = 0.48 + 0.52 * Math.sin((i / Math.max(1, count - 1)) * Math.PI);
                            // Keep a clearly visible short waveform even while idle. The long popup
                            // spectrum has more columns and greater height for a fuller presentation.
                            const h = compactBars
                                ? (root.playing
                                    ? ScalerService.s(5) + ScalerService.s(14) * mix * envelope
                                    : ScalerService.s(5) + ScalerService.s(11) * mix * envelope)
                                : (root.playing
                                    ? ScalerService.s(7) + ScalerService.s(24) * mix * envelope
                                    : ScalerService.s(5) + ScalerService.s(12) * mix * envelope);
                            const x = slot * (i + 0.5);
                            ctx.globalAlpha = root.playing ? 0.98 : (compactBars ? 0.82 : 0.62);
                            ctx.strokeStyle = root.playing ? root.accent : theme.primary.dim_foreground;
                            ctx.lineWidth = stroke;
                            ctx.beginPath();
                            ctx.moveTo(x, center - h / 2);
                            ctx.lineTo(x, center + h / 2);
                            ctx.stroke();
                        }
                        ctx.globalAlpha = 1;
                    }
                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Connections {
                    target: root
                    function onPlayingChanged() { spectrumCanvas.requestPaint(); }
                    function onVisualizerModeChanged() { spectrumCanvas.requestPaint(); }
                }
            }

            // Keep the waveform and seek bar close together in the compact widget.
            Item { Layout.preferredHeight: ScalerService.s(root.compact ? 1 : 2) }

            // ---------- thanh tiến trình dạng sóng ----------
            Item {
                id: bar
                Layout.fillWidth: true
                Layout.preferredHeight: ScalerService.s(root.compact ? 18 : 28)

                readonly property real ratio: root.player && root.player.length > 0 ? Math.max(0, Math.min(1, root.player.position / root.player.length)) : 0
                property real shown: 0               // vị trí hiển thị (đã làm mượt)
                property bool dragging: false
                property bool jump: false
                property real lastRatio: 0
                readonly property real wavelength: ScalerService.s(root.compact ? 14 : 22)
                property real phase: 0
                // biên độ: lượn khi phát, thẳng dần khi dừng
                property real amp: root.playing && !Settings.behavior.reduceMotion ? ScalerService.s(root.compact ? 2 : 4) : 0
                Behavior on amp { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }

                // Vị trí từ MPRIS nhảy theo từng giây => trượt đều (linear) giữa các lần cập nhật; tua = trượt nhanh.
                Behavior on shown {
                    enabled: !bar.dragging
                    NumberAnimation {
                        duration: bar.jump ? 280 : (root.playing ? 1000 : 0)
                        easing.type: bar.jump ? Easing.OutCubic : Easing.Linear
                    }
                }
                onRatioChanged: {
                    const len = root.player ? root.player.length : 0;
                    jump = Math.abs(ratio - lastRatio) * len > 2.5;
                    lastRatio = ratio;
                    if (!dragging)
                        shown = ratio;
                }
                Component.onCompleted: {
                    lastRatio = ratio;
                    shown = ratio;
                }
                onShownChanged: waveCanvas.requestPaint()
                onPhaseChanged: waveCanvas.requestPaint()
                onAmpChanged: waveCanvas.requestPaint()

                Timer {
                    interval: 50
                    repeat: true
                    running: root.playing || bar.amp > 0.05
                    onTriggered: bar.phase = (bar.phase + 0.21) % (Math.PI * 2)
                }

                Canvas {
                    id: waveCanvas
                    anchors.fill: parent
                    renderTarget: Canvas.FramebufferObject
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const cy = height / 2;
                        const lw = ScalerService.s(root.compact ? 3 : 4);
                        const gap = ScalerService.s(root.compact ? 5 : 8);
                        const xp = Math.max(0, Math.min(width, width * bar.shown));
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        // phần chưa phát: đường thẳng mờ
                        if (xp + gap < width - lw / 2) {
                            ctx.strokeStyle = Qt.alpha(theme.primary.foreground, 0.18);
                            ctx.lineWidth = lw * 0.85;
                            ctx.beginPath();
                            ctx.moveTo(xp + gap, cy);
                            ctx.lineTo(width - lw / 2, cy);
                            ctx.stroke();
                        }

                        // phần đã phát: sóng, thu nhỏ biên độ ở hai đầu để chạm núm thật êm
                        const end = xp - gap;
                        if (end > lw / 2) {
                            const ramp = ScalerService.s(root.compact ? 10 : 16);
                            ctx.strokeStyle = root.accent;
                            ctx.lineWidth = lw;
                            ctx.beginPath();
                            const yAt = x => {
                                const env = Math.min(1, (x - lw / 2) / ramp) * Math.min(1, (end - x) / ramp);
                                return cy + bar.amp * env * Math.sin((x / bar.wavelength) * Math.PI * 2 - bar.phase);
                            };
                            ctx.moveTo(lw / 2, yAt(lw / 2));
                            for (let x = lw / 2 + 2; x < end; x += 2)
                                ctx.lineTo(x, yAt(x));
                            ctx.lineTo(end, cy);
                            ctx.stroke();
                        }
                    }
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                // núm dạng viên thuốc, phình ra khi rê/kéo
                Rectangle {
                    id: handle
                    readonly property bool hot: seek.pressed || seek.containsMouse
                    width: ScalerService.s(hot ? 6 : 5)
                    height: ScalerService.s(seek.pressed ? 26 : (hot ? 24 : 20))
                    radius: width / 2
                    color: root.accent
                    x: Math.max(0, Math.min(bar.width - width, bar.width * bar.shown - width / 2))
                    y: (bar.height - height) / 2
                    Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    Behavior on width { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                }

                MouseArea {
                    id: seek
                    anchors.fill: parent
                    anchors.topMargin: -ScalerService.s(6)
                    anchors.bottomMargin: -ScalerService.s(6)
                    enabled: !!root.player && root.player.canSeek && root.player.length > 0
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    function ratioAt(x) {
                        return Math.max(0, Math.min(1, x / width));
                    }
                    onPressed: m => {
                        bar.dragging = true;
                        bar.shown = ratioAt(m.x);
                    }
                    onPositionChanged: m => {
                        if (pressed)
                            bar.shown = ratioAt(m.x);
                    }
                    onReleased: m => {
                        const r = ratioAt(m.x);
                        bar.dragging = false;
                        root.player.position = r * root.player.length;
                    }
                    onCanceled: bar.dragging = false
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: Players.formatTime(root.player ? (bar.dragging ? bar.shown * root.player.length : root.player.position) : 0)
                    color: bar.dragging ? root.accent : theme.primary.dim_foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.compact ? 8 : 11); weight: Font.Medium }
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Players.formatTime(root.player ? root.player.length : 0)
                    color: theme.primary.dim_foreground
                    font { family: Settings.appearance.font; pixelSize: ScalerService.s(root.compact ? 8 : 11); weight: Font.Medium }
                }
            }

            // ---------- điều khiển ----------
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: ScalerService.s(root.compact ? 0 : 2)
                spacing: ScalerService.s(root.compact ? 6 : 12)

                Repeater {
                    model: ["prev", "pp", "next"]
                    delegate: Rectangle {
                        id: btn
                        required property string modelData
                        readonly property bool primary: modelData === "pp"
                        readonly property bool can: primary ? !!root.player
                            : (root.player ? (modelData === "prev" ? root.player.canGoPrevious : root.player.canGoNext) : false)
                        property real nudge: 0

                        implicitWidth: ScalerService.s(root.compact ? (primary ? 38 : 28) : (primary ? 60 : 42))
                        implicitHeight: ScalerService.s(root.compact ? (primary ? 30 : 26) : (primary ? 44 : 38))
                        radius: height / 2
                        opacity: can ? 1 : 0.35
                        color: primary
                            ? (ma.containsMouse ? Qt.lighter(root.accent, 1.12) : root.accent)
                            : (ma.containsMouse ? Qt.alpha(theme.button.background_select, 0.85) : Qt.alpha(theme.button.background, 0.7))
                        scale: ma.pressed ? 0.9 : (ma.containsMouse ? 1.06 : 1)
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        SequentialAnimation {
                            id: nudgeAnim
                            NumberAnimation { target: btn; property: "nudge"; to: (btn.modelData === "prev" ? -1 : 1) * ScalerService.s(5); duration: 90; easing.type: Easing.OutQuad }
                            NumberAnimation { target: btn; property: "nudge"; to: 0; duration: 260; easing.type: Easing.OutBack }
                        }

                        // prev / next
                        Glyph {
                            visible: !btn.primary
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: btn.nudge
                            kind: btn.modelData
                            tint: theme.primary.foreground
                        }
                        // play <-> pause: xoay + co giãn chéo nhau
                        Glyph {
                            visible: btn.primary
                            anchors.centerIn: parent
                            kind: "play"
                            tint: theme.primary.background
                            opacity: root.playing ? 0 : 1
                            scale: root.playing ? 0.4 : 1
                            rotation: root.playing ? -80 : 0
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                            Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        }
                        Glyph {
                            visible: btn.primary
                            anchors.centerIn: parent
                            kind: "pause"
                            tint: theme.primary.background
                            opacity: root.playing ? 1 : 0
                            scale: root.playing ? 1 : 0.4
                            rotation: root.playing ? 0 : 80
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                            Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }
                            Behavior on rotation { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: btn.can ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (!btn.can)
                                    return;
                                if (btn.modelData === "prev") {
                                    nudgeAnim.restart();
                                    Players.previous();
                                } else if (btn.modelData === "next") {
                                    nudgeAnim.restart();
                                    Players.next();
                                } else {
                                    Players.playPause();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
