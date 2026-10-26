import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.components

// Kiểu "Hiện tại": giờ / phút xếp dọc | vạch ngăn | thứ + ngày tháng
Item {
  id: root

  property string currentHour: ""
  property string currentMin: ""
  property string currentDay: ""
  property string currentDate: ""

  implicitWidth: content.implicitWidth
  implicitHeight: content.implicitHeight

  SystemClock {
    id: clock
    precision: SystemClock.Seconds
    onDateChanged: root.updateDateTime()
  }

  function updateDateTime() {
    const now = new Date();
    const dayData = lang?.dateFormat?.day;
    const weekdays = dayData ? [dayData.sunday || "CN", dayData.monday || "T2", dayData.tuesday || "T3", dayData.wednesday || "T4", dayData.thursday || "T5", dayData.friday || "T6", dayData.saturday || "T7"] : ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];

    const monthData = lang?.dateFormat?.month;
    const months = monthData ? [monthData.january || "Th1", monthData.february || "Th2", monthData.march || "Th3", monthData.april || "Th4", monthData.may || "Th5", monthData.june || "Th6", monthData.july || "Th7", monthData.august || "Th8", monthData.september || "Th9", monthData.october || "Th10", monthData.november || "Th11", monthData.december || "Th12"] : ["Th1", "Th2", "Th3", "Th4", "Th5", "Th6", "Th7", "Th8", "Th9", "Th10", "Th11", "Th12"];

    root.currentDay = `${weekdays[now.getDay()]}`;
    root.currentHour = Qt.formatTime(now, "HH");
    root.currentMin = Qt.formatTime(now, "mm");
    root.currentDate = `${now.getDate()} ${months[now.getMonth()]} ${now.getFullYear()}`;
  }

  RowLayout {
    id: content
    anchors.centerIn: parent
    spacing: ScalerService.s(33)

    ColumnLayout {
      spacing: ScalerService.s(5)
      CustomText {
        name: root.currentHour
        isBold: true
        textColor: "#ffffff"
        font.pixelSize: ScalerService.s(124)
      }
      CustomText {
        name: root.currentMin
        isBold: true
        textColor: "#ffffff"
        font.pixelSize: ScalerService.s(124)
      }
    }

    Rectangle {
      Layout.preferredWidth: ScalerService.s(10)
      Layout.preferredHeight: content.implicitHeight / 2
      color: "#ffffff"
      radius: ScalerService.s(10)
    }

    ColumnLayout {
      spacing: ScalerService.s(5)
      CustomText {
        name: root.currentDay
        isBold: true
        textColor: "#ffffff"
        font.pixelSize: ScalerService.s(124)
      }
      CustomText {
        name: root.currentDate
        isBold: true
        textColor: "#ffffff"
        font.pixelSize: ScalerService.s(64)
      }
    }
  }

  Component.onCompleted: updateDateTime()
}
