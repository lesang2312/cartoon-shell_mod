import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// Kiểu Pixel: HH:MM dot-matrix (giờ xanh dương, phút xanh lá), dấu ":" nhấp nháy, ngày ở dưới
Item {
  id: root

  property color hourColor: "#68b6e3"
  property color minColor: "#30c933"
  property bool colonOn: true

  implicitWidth: column.implicitWidth
  implicitHeight: column.implicitHeight

  SystemClock {
    id: tick
    precision: SystemClock.Seconds
    onDateChanged: root.colonOn = (tick.date.getSeconds() % 2 === 0)
  }

  ColumnLayout {
    id: column
    anchors.centerIn: parent
    spacing: ScalerService.s(16)

    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: ScalerService.s(14)

      PixelDigit { ch: DateTimeService.currentHours.charAt(0); litColor: root.hourColor }
      PixelDigit { ch: DateTimeService.currentHours.charAt(1); litColor: root.hourColor }

      PixelDigit {
        ch: ":"
        litColor: "#ffffff"
        opacity: root.colonOn ? 1.0 : 0.25
        Behavior on opacity { NumberAnimation { duration: 150 } }
      }

      PixelDigit { ch: DateTimeService.currentMinutes.charAt(0); litColor: root.minColor }
      PixelDigit { ch: DateTimeService.currentMinutes.charAt(1); litColor: root.minColor }
    }

    CustomText {
      name: `${DateTimeService.currentDay} ${DateTimeService.currentOfDays}/${DateTimeService.currentMonth}`
      textColor: "#ffffff"
      opacity: 0.8
      fontFamily: "BigBlueTerm437 Nerd Font"
      font.pixelSize: ScalerService.s(22)
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
