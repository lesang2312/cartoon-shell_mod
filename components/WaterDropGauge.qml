import QtQuick
import qs.commons
import qs.services

// Giọt nước với nước xanh dâng lên / hạ xuống theo fillValue (0-100)
Item {
    id: root

    property real fillValue: 90          // 0 - 100
    property color waveColor: "#4FC3F7"  // màu nước
    property color emptyColor: theme.button.background
    property color outlineColor: theme.button.dim_foreground
    property real phase: 0

    implicitWidth: ScalerService.s(28)
    implicitHeight: ScalerService.s(28)

    Behavior on fillValue {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: 45
        running: true
        repeat: true
        onTriggered: {
            root.phase += 0.09;
            if (root.phase > Math.PI * 2) root.phase -= Math.PI * 2;
            canvas.requestPaint();
        }
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        function dropPath(ctx, x, y, r) {
            ctx.beginPath();
            ctx.moveTo(x, y - r * 1.5);
            ctx.bezierCurveTo(x + r * 1.55, y - r * 0.15, x + r * 1.05, y + r * 1.05, x, y + r * 1.05);
            ctx.bezierCurveTo(x - r * 1.05, y + r * 1.05, x - r * 1.55, y - r * 0.15, x, y - r * 1.5);
            ctx.closePath();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const w = width, h = height;
            const cx = w / 2, cy = h * 0.56;
            const r = Math.min(w, h) * 0.34;

            ctx.save();
            dropPath(ctx, cx, cy, r);
            ctx.clip();

            // nền rỗng của giọt nước
            ctx.fillStyle = root.emptyColor;
            ctx.fillRect(0, 0, w, h);

            // mực nước theo fillValue
            const top = h - (h * (root.fillValue / 100));
            ctx.beginPath();
            for (let x = 0; x <= w; x += 4) {
                const y = top + Math.sin(x * 0.28 + root.phase) * (h * 0.035);
                if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.lineTo(w, h);
            ctx.lineTo(0, h);
            ctx.closePath();
            ctx.fillStyle = root.waveColor;
            ctx.fill();

            ctx.restore();

            // viền giọt nước
            dropPath(ctx, cx, cy, r);
            ctx.lineWidth = Math.max(1, w * 0.045);
            ctx.strokeStyle = root.outlineColor;
            ctx.stroke();
        }

        Component.onCompleted: requestPaint()
    }

    onFillValueChanged: canvas.requestPaint()
    onWaveColorChanged: canvas.requestPaint()
}
