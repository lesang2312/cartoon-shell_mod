import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Chọn giờ bằng cách xoay/chạm lên mặt đồng hồ, giống TimePicker của Android.
// Kết quả trả về qua signal timeConfirmed(timeStr) với định dạng "HH:mm".
Item {
  id: root

  signal timeConfirmed(string timeStr)
  signal cancelled

  property int hours24: 8
  property int minutes: 0
  property bool isPM: hours24 >= 12
  property string mode: "hour" // "hour" | "minute"

  // Góc hiện tại (độ) của kim, 0 = 12 giờ / phút 00, tăng theo chiều kim đồng hồ
  readonly property real handDeg: mode === "hour" ? (hour12() % 12) * 30 : minutes * 6

  implicitWidth: ScalerService.s(280)
  implicitHeight: ScalerService.s(360)

  function setInitialTime(timeStr) {
    const m = /^([0-1][0-9]|2[0-3]):([0-5][0-9])$/.exec(timeStr || "");
    if (m) {
      root.hours24 = parseInt(m[1], 10);
      root.minutes = parseInt(m[2], 10);
      // isPM ban đầu là 1 binding, nhưng setPM() gán tay nên binding có thể đã bị phá
      // từ trước. Gán lại tường minh ở đây để không bị lệch AM/PM khi mở lại dialog.
      root.isPM = root.hours24 >= 12;
    }
    root.mode = "hour";
  }

  function hour12() {
    var h = root.hours24 % 12;
    return h === 0 ? 12 : h;
  }

  function setHour12(h12) {
    if (root.isPM)
      root.hours24 = (h12 === 12) ? 12 : h12 + 12;
    else
      root.hours24 = (h12 === 12) ? 0 : h12;
  }

  function setPM(pm) {
    var h12 = hour12();
    root.isPM = pm;
    setHour12(h12);
  }

  function pad2(n) {
    return (n < 10 ? "0" : "") + n;
  }

  function currentTimeString() {
    return pad2(root.hours24) + ":" + pad2(root.minutes);
  }

  ColumnLayout {
    anchors.fill: parent
    spacing: ScalerService.s(14)

    // Đồng hồ số + AM/PM
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: ScalerService.s(10)

      RowLayout {
        spacing: ScalerService.s(2)

        Rectangle {
          Layout.preferredWidth: ScalerService.s(56)
          Layout.preferredHeight: ScalerService.s(50)
          radius: ScalerService.s(10)
          color: root.mode === "hour" ? theme.button.text : "transparent"

          CustomText {
            anchors.centerIn: parent
            name: root.pad2(root.hour12())
            isBold: true
            size: "large"
            textColor: root.mode === "hour" ? theme.button.background : theme.button.text
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.mode = "hour"
          }
        }

        CustomText {
          name: ":"
          isBold: true
          size: "large"
        }

        Rectangle {
          Layout.preferredWidth: ScalerService.s(56)
          Layout.preferredHeight: ScalerService.s(50)
          radius: ScalerService.s(10)
          color: root.mode === "minute" ? theme.button.text : "transparent"

          CustomText {
            anchors.centerIn: parent
            name: root.pad2(root.minutes)
            isBold: true
            size: "large"
            textColor: root.mode === "minute" ? theme.button.background : theme.button.text
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.mode = "minute"
          }
        }
      }

      ColumnLayout {
        spacing: ScalerService.s(2)

        Rectangle {
          Layout.preferredWidth: ScalerService.s(36)
          Layout.preferredHeight: ScalerService.s(24)
          radius: ScalerService.s(6)
          color: !root.isPM ? theme.button.text : theme.button.background

          CustomText {
            anchors.centerIn: parent
            name: "AM"
            size: "small"
            textColor: !root.isPM ? theme.button.background : theme.button.text
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.setPM(false)
          }
        }

        Rectangle {
          Layout.preferredWidth: ScalerService.s(36)
          Layout.preferredHeight: ScalerService.s(24)
          radius: ScalerService.s(6)
          color: root.isPM ? theme.button.text : theme.button.background

          CustomText {
            anchors.centerIn: parent
            name: "PM"
            size: "small"
            textColor: root.isPM ? theme.button.background : theme.button.text
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.setPM(true)
          }
        }
      }
    }

    // Mặt đồng hồ
    Item {
      id: dialCircle
      Layout.alignment: Qt.AlignHCenter
      width: ScalerService.s(220)
      height: ScalerService.s(220)

      readonly property real ringR: width / 2 - ScalerService.s(28)

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: theme.button.background
        opacity: 0.5
      }

      Rectangle {
        width: ScalerService.s(8)
        height: ScalerService.s(8)
        radius: width / 2
        anchors.centerIn: parent
        color: theme.button.text
      }

      // Kim chỉ giờ/phút đang chọn
      Rectangle {
        width: ScalerService.s(2)
        height: dialCircle.ringR
        color: theme.button.text
        opacity: 0.8
        anchors.bottom: dialCircle.verticalCenter
        anchors.horizontalCenter: dialCircle.horizontalCenter
        transformOrigin: Item.Bottom
        rotation: root.handDeg

        Behavior on rotation {
          RotationAnimation {
            duration: 120
            direction: RotationAnimation.Shortest
          }
        }
      }

      // Núm tròn ở đầu kim, có thể chạm/kéo để xoay
      Rectangle {
        id: knob
        width: ScalerService.s(34)
        height: ScalerService.s(34)
        radius: width / 2
        color: theme.button.text
        x: dialCircle.width / 2 + dialCircle.ringR * Math.cos((root.handDeg - 90) * Math.PI / 180) - width / 2
        y: dialCircle.height / 2 + dialCircle.ringR * Math.sin((root.handDeg - 90) * Math.PI / 180) - height / 2

        Behavior on x {
          NumberAnimation {
            duration: 120
          }
        }
        Behavior on y {
          NumberAnimation {
            duration: 120
          }
        }
      }

      // Các số trên mặt đồng hồ (1-12 khi chọn giờ, 00-55 khi chọn phút)
      Repeater {
        model: 12
        Item {
          id: numItem
          readonly property real angleDeg: index * 30 - 90
          readonly property real rad: angleDeg * Math.PI / 180
          readonly property int valueForMode: root.mode === "hour" ? (index === 0 ? 12 : index) : (index * 5)

          x: dialCircle.width / 2 + dialCircle.ringR * Math.cos(rad) - width / 2
          y: dialCircle.height / 2 + dialCircle.ringR * Math.sin(rad) - height / 2
          width: ScalerService.s(30)
          height: ScalerService.s(30)

          CustomText {
            anchors.centerIn: parent
            name: root.mode === "hour" ? String(numItem.valueForMode) : root.pad2(numItem.valueForMode)
            size: "small"
            isBold: root.mode === "hour" ? root.hour12() === numItem.valueForMode : root.minutes === numItem.valueForMode
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              if (root.mode === "hour") {
                root.setHour12(numItem.valueForMode);
                root.mode = "minute";
              } else {
                root.minutes = numItem.valueForMode;
              }
            }
          }
        }
      }

      // Kéo ở bất kỳ đâu trên mặt đồng hồ để xoay kim, giống Android
      MouseArea {
        anchors.fill: parent
        onPressed: updateFromPos(mouseX, mouseY)
        onPositionChanged: if (pressed)
          updateFromPos(mouseX, mouseY)
        onReleased: if (root.mode === "hour")
          root.mode = "minute"

        function updateFromPos(mx, my) {
          var cx = dialCircle.width / 2;
          var cy = dialCircle.height / 2;
          var dx = mx - cx;
          var dy = my - cy;
          var angle = Math.atan2(dy, dx) * 180 / Math.PI + 90;
          if (angle < 0)
            angle += 360;

          if (root.mode === "hour") {
            var h = Math.round(angle / 30) % 12;
            if (h === 0)
              h = 12;
            root.setHour12(h);
          } else {
            var mnt = Math.round(angle / 6) % 60;
            root.minutes = mnt;
          }
        }
      }
    }

    // Huỷ / Xác nhận
    RowLayout {
      Layout.fillWidth: true
      Layout.alignment: Qt.AlignHCenter
      spacing: ScalerService.s(24)

      ButtonIconText {
        name: "close"
        onClicked: root.cancelled()
      }
      ButtonIconText {
        name: "check_circle"
        onClicked: root.timeConfirmed(root.currentTimeString())
      }
    }
  }
}
