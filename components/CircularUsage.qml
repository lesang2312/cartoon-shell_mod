import QtQuick
import QtQuick.Layouts
import qs.commons
import qs.services

Item {
    id: root

    property string title: ""
    property real value: 0
    property color progressColor: "#80B4FF"
    property color trackColor: "#59647B"
    property color textColor: "#F5F7FF"
    property real strokeWidth: 7

    implicitWidth: ScalerService.s(122)
    implicitHeight: ScalerService.s(140)

    readonly property real clampedValue: Math.max(0, Math.min(100, Number(value) || 0))
    property real animatedValue: clampedValue
    Behavior on animatedValue {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    onClampedValueChanged: animatedValue = clampedValue
    onAnimatedValueChanged: ring.requestPaint()
    onWidthChanged: ring.requestPaint()
    onHeightChanged: ring.requestPaint()

    ColumnLayout {
        anchors.fill: parent
        spacing: ScalerService.s(4)

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            color: root.textColor
            font.pixelSize: ScalerService.s(11)
            font.bold: true
            elide: Text.ElideRight
        }

        Item {
            id: ringArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: ScalerService.s(78)

            Canvas {
                id: ring
                width: Math.min(parent.width, parent.height, ScalerService.s(104))
                height: width
                anchors.centerIn: parent
                antialiasing: true
                renderTarget: Canvas.Image

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const cx = width / 2;
                    const cy = height / 2;
                    const line = Math.max(3, root.strokeWidth);
                    const radius = Math.max(8, Math.min(width, height) / 2 - line - 2);
                    ctx.lineWidth = line;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
                    ctx.strokeStyle = root.trackColor;
                    ctx.stroke();
                    if (root.animatedValue > 0) {
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, -Math.PI / 2,
                                -Math.PI / 2 + root.animatedValue / 100 * Math.PI * 2, false);
                        ctx.strokeStyle = root.progressColor;
                        ctx.stroke();
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 0
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(root.animatedValue) + "%"
                    color: "#FFFFFF"
                    font.pixelSize: ScalerService.s(18)
                    font.bold: true
                    font.family: "Sans Serif"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.title === "Memory" ? "RAM" : root.title
                    color: "#D5DDF0"
                    font.pixelSize: ScalerService.s(8)
                }
            }
        }
    }
}
