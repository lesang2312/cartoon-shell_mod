import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Kiểu iPhone (màn hình khoá): ngày nhỏ ở trên, giờ cực lớn, đậm, căn giữa
Item {
  id: root

  implicitWidth: column.implicitWidth
  implicitHeight: column.implicitHeight

  ColumnLayout {
    id: column
    anchors.centerIn: parent
    spacing: -ScalerService.s(18)

    CustomText {
      name: `${DateTimeService.currentDay}, ${DateTimeService.currentOfDays} ${DateTimeService.currentMonth}`
      textColor: "#ffffff"
      opacity: 0.85
      isBold: true
      font.pixelSize: ScalerService.s(34)
      Layout.alignment: Qt.AlignHCenter
    }

    CustomText {
      name: DateTimeService.currentTime
      textColor: "#ffffff"
      opacity: 0.95
      isBold: true
      font.pixelSize: ScalerService.s(170)
      Layout.alignment: Qt.AlignHCenter
    }
  }
}
