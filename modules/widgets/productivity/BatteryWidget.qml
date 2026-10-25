import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.commons
import qs.components
import qs.services

Item {
    id: root
    implicitWidth: ScalerService.s(238)
    implicitHeight: ScalerService.s(276)

    readonly property bool hasBattery: UPower.displayDevice && UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
    readonly property int percent: root.hasBattery ? Math.max(0, Math.min(100, Math.round(UPower.displayDevice.percentage * 100))) : 0
    readonly property string rawState: root.hasBattery ? UPowerDeviceState.toString(UPower.displayDevice.state) : ""
    readonly property bool charging: root.rawState === "Charging"
    readonly property string batteryState: {
        if (!UPower.displayDevice || !UPower.displayDevice.ready)
            return "Đang đọc dữ liệu pin…";
        if (!root.hasBattery)
            return "Không tìm thấy pin laptop";
        if (root.charging) return "Đang sạc";
        if (root.rawState === "Discharging") return "Đang dùng pin";
        if (root.rawState === "FullyCharged") return "Đã sạc đầy";
        if (root.rawState === "Empty") return "Pin yếu";
        return root.rawState;
    }

    function alphaColor(value, alpha) {
        const c = Qt.color(value);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    Rectangle {
        anchors.fill: parent
        radius: ScalerService.s(22)
        color: root.alphaColor(theme.primary.background, glass.active ? 0.76 : 0.94)
        border.color: Qt.rgba(0.84, 0.90, 1.0, 0.94)
        border.width: ScalerService.s(1.5)
        clip: true

        GlassPanel {
            id: glass
            tint: 0.20
            frostAmount: 0.10
            rim: 0.90
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(12)
            spacing: ScalerService.s(6)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(7)
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(30)
                    Layout.preferredHeight: ScalerService.s(30)
                    radius: ScalerService.s(10)
                    color: root.charging ? "#203E35" : "#263650"
                    border.color: root.charging ? "#7FE0AE" : "#9BBEFF"
                    Text {
                        anchors.centerIn: parent
                        text: root.charging ? "ϟ" : "▱"
                        color: root.charging ? "#9CF0BE" : "#B6CCFF"
                        font.pixelSize: ScalerService.s(18)
                        font.bold: true
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: "Battery"; color: "#F7F8FF"; font.pixelSize: ScalerService.s(15); font.bold: true }
                    Text { text: "Battery health · live"; color: "#C9D4EB"; font.pixelSize: ScalerService.s(9) }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(7)
                    Layout.preferredHeight: ScalerService.s(7)
                    radius: width / 2
                    color: root.percent <= 20 ? "#FF6D83" : root.charging ? "#7FE0AE" : "#8FB8FF"
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: ScalerService.s(154)

                Canvas {
                    id: ringCanvas
                    width: ScalerService.s(142)
                    height: ScalerService.s(142)
                    anchors.centerIn: parent

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const cx = width / 2;
                        const cy = height / 2;
                        const radius = Math.min(width, height) / 2 - ScalerService.s(10);
                        const stroke = ScalerService.s(8);
                        ctx.lineWidth = stroke;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = "#44506A";
                        ctx.beginPath();
                        ctx.arc(cx, cy, radius, 0, Math.PI * 2, false);
                        ctx.stroke();

                        const tint = root.percent <= 20 ? "#FF6B80" : root.charging ? "#7FE0AE" : "#87B3FF";
                        if (root.hasBattery && root.percent > 0) {
                            ctx.strokeStyle = tint;
                            ctx.beginPath();
                            ctx.arc(cx, cy, radius, -Math.PI / 2, -Math.PI / 2 + (Math.PI * 2 * root.percent / 100), false);
                            ctx.stroke();
                        }
                    }

                    Component.onCompleted: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                }

                Connections {
                    target: root
                    function onPercentChanged() { ringCanvas.requestPaint(); }
                    function onChargingChanged() { ringCanvas.requestPaint(); }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: ScalerService.s(2)
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.hasBattery ? root.percent + "%" : "—"
                        color: root.percent <= 20 && root.hasBattery ? "#FF8193" : "#F6F8FF"
                        font.pixelSize: ScalerService.s(29)
                        font.bold: true
                        font.family: "Sans Serif"
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.charging ? "ϟ Power" : "Battery"
                        color: root.charging ? "#9CF0BE" : "#BCC9E4"
                        font.pixelSize: ScalerService.s(10)
                        font.bold: true
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(6)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: ScalerService.s(1)
                    Text { text: root.batteryState; color: "#F3F6FF"; font.pixelSize: ScalerService.s(10); font.bold: true; Layout.fillWidth: true; elide: Text.ElideRight }
                    Text { text: root.hasBattery ? "UPower · cập nhật trực tiếp" : "Kiểm tra dịch vụ UPower"; color: "#C5D0E7"; font.pixelSize: ScalerService.s(8); Layout.fillWidth: true; elide: Text.ElideRight }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(72)
                    Layout.preferredHeight: ScalerService.s(27)
                    radius: ScalerService.s(9)
                    color: "#344B70"
                    border.color: "#9BBEFF"
                    Text { anchors.centerIn: parent; text: "Chi tiết ↗"; color: "#FFFFFF"; font.pixelSize: ScalerService.s(9); font.bold: true }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: VisibleService.togglePanel("battery") }
                }
            }
        }
    }
}
