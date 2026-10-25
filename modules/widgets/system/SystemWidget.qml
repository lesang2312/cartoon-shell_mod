import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.components
import qs.services
import qs.services.ram
import qs.services.cpu

Item {
    id: root
    implicitWidth: ScalerService.s(450)
    implicitHeight: ScalerService.s(220)

    Component.onCompleted: DiskService.acquire()
    Component.onDestruction: DiskService.release()

    function mixedPanelColor(alpha) {
        const c = Qt.color(theme.primary.background);
        return Qt.rgba(c.r, c.g, c.b, alpha);
    }

    Rectangle {
        anchors.fill: parent
        radius: ScalerService.s(20)
        // A stronger tinted surface keeps text legible while still showing the wallpaper.
        color: root.mixedPanelColor(glass.active ? 0.73 : 0.94)
        border.color: Qt.rgba(0.86, 0.91, 1.0, 0.88)
        border.width: ScalerService.s(1.5)
        clip: true

        GlassPanel {
            id: glass
            tint: 0.30
            frostAmount: 0.16
            rim: 0.82
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: ScalerService.s(13)
            spacing: ScalerService.s(8)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(8)
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(28)
                    Layout.preferredHeight: ScalerService.s(28)
                    radius: ScalerService.s(9)
                    color: Qt.rgba(0.36, 0.58, 1.0, 0.22)
                    border.color: Qt.rgba(0.62, 0.75, 1.0, 0.72)
                    Text {
                        anchors.centerIn: parent
                        text: "◉"
                        color: "#DCE7FF"
                        font.pixelSize: ScalerService.s(16)
                        font.bold: true
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "Activity Monitor"
                        color: "#F5F7FF"
                        font.pixelSize: ScalerService.s(16)
                        font.bold: true
                    }
                    Text {
                        text: "CPU và RAM đã dùng · cập nhật mỗi 2 giây"
                        color: "#CCD5EB"
                        font.pixelSize: ScalerService.s(10)
                    }
                }
                Rectangle {
                    Layout.preferredWidth: ScalerService.s(9)
                    Layout.preferredHeight: ScalerService.s(9)
                    radius: width / 2
                    color: "#72DCA2"
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: ScalerService.s(8)
                CircularUsage {
                    title: "CPU"
                    value: CpuSimpleService.cpuPercent
                    progressColor: "#FF647C"
                    trackColor: "#59647B"
                    textColor: "#F5F7FF"
                    strokeWidth: ScalerService.s(7)
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                }
                CircularUsage {
                    title: "RAM"
                    value: RamSimpleService.ramPercent
                    progressColor: "#A4E18A"
                    trackColor: "#59647B"
                    textColor: "#F5F7FF"
                    strokeWidth: ScalerService.s(7)
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                }
                CircularUsage {
                    title: "Disk"
                    value: DiskService.diskPercents
                    progressColor: "#80B4FF"
                    trackColor: "#59647B"
                    textColor: "#F5F7FF"
                    strokeWidth: ScalerService.s(7)
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.minimumHeight: 0
                }
            }
        }
    }
}
