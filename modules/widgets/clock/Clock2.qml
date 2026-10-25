import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

Item {
    id: root
    implicitWidth: ScalerService.s(400)
    implicitHeight: columnLayout.implicitHeight

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        ColumnLayout {
            id: columnLayout
            anchors.centerIn: parent
            spacing: - ScalerService.s(25)  //De am de khoang cah gio va phut gan nhau hon

            //Ve gio
            CustomText {
                id: textCurrentHours
                name: DateTimeService.currentHour
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: ScalerService.s(150)
                color: '#68b6e3' //theme.primary.dim_foreground
                isBold: true
                fontFamily: "BigBlueTerm437 Nerd Font"
            }

            //Ve phut
            CustomText {
                id: textCurrentMin
                name: DateTimeService.currentMinutes
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: ScalerService.s(150)
                color: '#30c933' //theme.primary.dim_foreground
                isBold: true
                fontFamily: "BigBlueTerm437 Nerd Font"
            }
        }
    }
}

// Note mau: -#83e2ec-#00f0ff, -#f8f9fa-#38bdf8, -#ffffff-#fbbf24, -#a78bfa-#38bdf8, -#4ade80-#22d3ee, -#f43f5e-#fb7185, -#fb923c-#facc15, -#c084fc-#e879f9, -#2dd4bf-#99f6e4