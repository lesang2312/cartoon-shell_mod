import QtQuick
import qs.commons
import qs.services

Item {
    id: dropItem

    property real fillValue: root.newCurrentKittyOpacy // Bind trực tiếp với Opacity
    property color waveColor: "#4FC3F7"
    property color emptyColor: '#707c93'
    property color outlineColor: '#1d4d83'
    property real phase: 0

    implicitWidth: ScalerService.s(30)
    implicitHeight: ScalerService.s(30)

    Behavior on fillValue {
        NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
    }

    Timer {
        interval: 45
        running: true
        repeat: true
        onTriggered: {
            dropItem.phase += 0.09;
            if (dropItem.phase > Math.PI * 2) dropItem.phase -= Math.PI * 2;
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

            // Nền rỗng của giọt nước
            ctx.fillStyle = dropItem.emptyColor;
            ctx.fillRect(0, 0, w, h);

            // Mực nước theo fillValue
            const top = h - (h * (dropItem.fillValue / 100));
            ctx.beginPath();
            for (let x = 0; x <= w; x += 4) {
                const y = top + Math.sin(x * 0.28 + dropItem.phase) * (h * 0.035);
                if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
            }
            ctx.lineTo(w, h);
            ctx.lineTo(0, h);
            ctx.closePath();
            ctx.fillStyle = dropItem.waveColor;
            ctx.fill();

            ctx.restore();

            // Viền giọt nước
            dropPath(ctx, cx, cy, r);
            ctx.lineWidth = Math.max(1, w * 0.045);
            ctx.strokeStyle = dropItem.outlineColor;
            ctx.stroke();
        }

        Component.onCompleted: requestPaint()
    }

    onFillValueChanged: canvas.requestPaint()
    onWaveColorChanged: canvas.requestPaint()
}