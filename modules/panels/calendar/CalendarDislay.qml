import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.components
import "." as Com

Rectangle {
  id: calendar

  property date currentDate: new Date()
  property int currentMonth: currentDate.getMonth()
  property int currentYear: currentDate.getFullYear()
  property date selectedDate: new Date()
  property real animationProgress: 0

  // Giờ hẹn và âm thanh báo được chọn cho lời nhắc sắp thêm
  property string reminderTime: "00:00"
  // false = người dùng chưa chọn giờ (tránh lỡ tay tạo lời nhắc lúc 00:00 mà không biết).
  property bool reminderTimeSet: false
  property string reminderSoundUrl: ""
  property string reminderSoundName: "Mặc định"

  SequentialAnimation on animationProgress {
    running: true

    NumberAnimation {
      from: 0
      to: 0.4
      duration: 200
      easing.type: Easing.Linear
    }
  }

  width: ScalerService.s(400)
  height: ScalerService.s(400)
  color: "transparent"
  radius: ScalerService.s(10)

  property var weekdayLabels: {
    const w = lang?.calendar?.weekdays;
    return w ? [w.sunday || "CN", w.monday || "T2", w.tuesday || "T3", w.wednesday || "T4", w.thursday || "T5", w.friday || "T6", w.saturday || "T7"] : ["CN", "T2", "T3", "T4", "T5", "T6", "T7"];
  }

  property var monthLabels: {
    const m = lang?.dateFormat?.month;
    return m ? [m.january || "Tháng 1", m.february || "Tháng 2", m.march || "Tháng 3", m.april || "Tháng 4", m.may || "Tháng 5", m.june || "Tháng 6", m.july || "Tháng 7", m.august || "Tháng 8", m.september || "Tháng 9", m.october || "Tháng 10", m.november || "Tháng 11", m.december || "Tháng 12"] : ["Tháng 1", "Tháng 2", "Tháng 3", "Tháng 4", "Tháng 5", "Tháng 6", "Tháng 7", "Tháng 8", "Tháng 9", "Tháng 10", "Tháng 11", "Tháng 12"];
  }

  signal dateSelected(date selectedDate)

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: ScalerService.s(10)
    spacing: ScalerService.s(15)

    // Header
    RowLayout {
      Layout.fillWidth: true

      ButtonIconText{
        name: "arrow_circle_left"
        opacity: calendar.animationProgress > 0.1 ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: 200
          }
        }
        onClicked: previousMonth()
      }

      CustomText{
        name: monthLabels[currentMonth] + " " + currentYear

        opacity: calendar.animationProgress > 0.2 ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: 200
          }
        }
        isBold: true
        size: "normal"
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true

      }
      ButtonIconText{
        name: "arrow_circle_right"
        opacity: calendar.animationProgress > 0.3 ? 1 : 0
        Behavior on opacity {
          NumberAnimation {
            duration: 200
          }
        }
        onClicked: nextMonth()
      }
    }

    // Calendar grid với Flickable để cuộn
    Flickable {
      id: flickable
      Layout.fillWidth: true
      Layout.fillHeight: true
      contentWidth: calendarGrid.width
      contentHeight: calendarGrid.height
      clip: true

      GridLayout {
        id: calendarGrid
        width: flickable.width
        columns: 7
        rowSpacing: ScalerService.s(8)
        columnSpacing: ScalerService.s(8)

        // Week day headers
        Repeater {
          model: weekdayLabels
          CustomText{
            opacity: 0

            SequentialAnimation on opacity {
              running: true

              PauseAnimation {
                duration: index * 50
              }

              NumberAnimation {
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
              }
            }
            name: modelData
            isBold: true
            size: "normal"
            horizontalAlignment: Text.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(30)

          }
        }

        // Days
        Repeater {
          id: daysRepeater
          model: getDaysInMonth(currentMonth, currentYear)

          Rectangle {
            id: dayRect
            Layout.preferredWidth: ScalerService.s(40)
            Layout.preferredHeight: ScalerService.s(40)

            opacity: 0

            SequentialAnimation on opacity {
              running: true

              PauseAnimation {
                duration: index * 15
              }

              NumberAnimation {
                to: 1
                duration: 200
                easing.type: Easing.OutCubic
              }
            }
            color: {
              if (modelData.isToday && modelData.isCurrentMonth)
              return theme.button.text;
              else
              return "transparent";
            }
            radius: ScalerService.s(20)

            CustomText {
              name: modelData.day
              anchors.centerIn: parent
              size: "small"
              textColor: {
                if (!modelData.isCurrentMonth)
                return theme.primary.dim_foreground;
                else if (modelData.isToday)
                return theme.button.background;
                else
                return theme.button.text;
              }
            }

            // Chấm nhỏ báo ngày có lời nhắc
            Rectangle {
              id: reminderDot
              visible: modelData.isCurrentMonth && ReminderService.hasReminders(modelData.fullDate)
              width: ScalerService.s(5)
              height: ScalerService.s(5)
              radius: width / 2
              color: modelData.isToday ? theme.button.background : theme.button.text
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.bottom: parent.bottom
              anchors.bottomMargin: ScalerService.s(3)
              scale: 0
              transformOrigin: Item.Center

              onVisibleChanged: if (visible)
              dotAppear.start()

              NumberAnimation {
                id: dotAppear
                target: reminderDot
                property: "scale"
                to: 1
                duration: 220
                easing.type: Easing.OutBack
                easing.overshoot: 3
              }
            }

            MouseArea {
              anchors.fill: parent
              onClicked: {
                if (modelData.isCurrentMonth) {
                  selectedDate = modelData.fullDate;
                  calendar.dateSelected(selectedDate);
                  reminderPopup.targetDate = modelData.fullDate;
                  calendar.reminderTime = "00:00";
                  calendar.reminderTimeSet = false;
                  calendar.reminderSoundUrl = "";
                  calendar.reminderSoundName = "Mặc định";
                  reminderPopup.open();
                }
              }
            }
          }
        }
      }
    }
  }

  // --- Popup xem / thêm / xoá lời nhắc cho ngày được chọn ---
  Popup {
    id: reminderPopup
    modal: true
    focus: true
    x: (calendar.width - width) / 2
    y: (calendar.height - height) / 2
    width: ScalerService.s(320)
    height: ScalerService.s(380)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    padding: ScalerService.s(18)

    property date targetDate: new Date()

    transformOrigin: Item.Center

    enter: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "opacity"
          from: 0
          to: 1
          duration: 260
          easing.type: Easing.OutExpo
        }
        NumberAnimation {
          property: "scale"
          from: 0.92
          to: 1
          duration: 320
          easing.type: Easing.OutExpo
        }
      }
    }

    exit: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "opacity"
          from: 1
          to: 0
          duration: 150
          easing.type: Easing.InCubic
        }
        NumberAnimation {
          property: "scale"
          from: 1
          to: 0.94
          duration: 150
          easing.type: Easing.InCubic
        }
      }
    }

    onOpened: {
      headerReveal.restart();
      listReveal.restart();
      optionsReveal.restart();
      inputReveal.restart();
    }
    onClosed: {
      headerRow.opacity = 0;
      headerTranslate.y = -Number(ScalerService.s(10));
      reminderList.opacity = 0;
      optionsRow.opacity = 0;
      optionsTranslate.y = Number(ScalerService.s(10));
      inputRow.opacity = 0;
      inputTranslate.y = Number(ScalerService.s(10));
      alarmSoundPicker.stopPreview();
    }

    background: Rectangle {
      id: popupBg
      color: theme.primary.background
      border.color: theme.button.border
      border.width: ScalerService.s(1)
      radius: ScalerService.s(18)

      layer.enabled: true
      layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: ScalerService.s(8)
        radius: ScalerService.s(20)
        samples: 32
        color: "#70000000"
        transparentBorder: true
      }
    }

    contentItem: ColumnLayout {
      spacing: ScalerService.s(14)

      // Header: thanh accent + ngày + thứ + nút đóng
      RowLayout {
        id: headerRow
        Layout.fillWidth: true
        spacing: ScalerService.s(10)
        opacity: 0

        transform: Translate {
          id: headerTranslate
          y: -Number(ScalerService.s(10))
        }

        SequentialAnimation {
          id: headerReveal
          ParallelAnimation {
            NumberAnimation {
              target: headerRow
              property: "opacity"
              to: 1
              duration: 240
              easing.type: Easing.OutExpo
            }
            NumberAnimation {
              target: headerTranslate
              property: "y"
              to: 0
              duration: 260
              easing.type: Easing.OutExpo
            }
          }
        }

        Rectangle {
          Layout.preferredWidth: ScalerService.s(4)
          Layout.preferredHeight: ScalerService.s(32)
          radius: ScalerService.s(2)
          color: theme.button.text
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(1)

          CustomText {
            name: Qt.formatDate(reminderPopup.targetDate, "dd/MM/yyyy")
            isBold: true
            size: "normal"
          }
          CustomText {
            name: weekdayFullLabel(reminderPopup.targetDate)
            size: "small"
            opacity: 0.55
          }
        }

        ButtonIconText {
          name: "close"
          onClicked: reminderPopup.close()
        }
      }

      // Danh sách lời nhắc
      Item {
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(180)

        ListView {
          id: reminderList
          anchors.fill: parent
          clip: true
          opacity: 0
          model: ReminderService.getRemindersForDate(reminderPopup.targetDate)
          spacing: ScalerService.s(6)

          OpacityAnimator {
            id: listReveal
            target: reminderList
            from: 0
            to: 1
            duration: 280
            easing.type: Easing.OutExpo
          }

          add: Transition {
            NumberAnimation {
              property: "opacity"
              from: 0
              to: 1
              duration: 200
              easing.type: Easing.OutExpo
            }
            NumberAnimation {
              property: "scale"
              from: 0.85
              to: 1
              duration: 220
              easing.type: Easing.OutExpo
            }
          }

          remove: Transition {
            NumberAnimation {
              property: "opacity"
              to: 0
              duration: 140
              easing.type: Easing.InCubic
            }
            NumberAnimation {
              property: "scale"
              to: 0.85
              duration: 140
              easing.type: Easing.InCubic
            }
          }

          displaced: Transition {
            NumberAnimation {
              properties: "y"
              duration: 200
              easing.type: Easing.OutExpo
            }
          }

          delegate: Item {
            width: reminderList.width
            height: ScalerService.s(46)

            Rectangle {
              anchors.fill: parent
              radius: ScalerService.s(10)
              color: theme.button.background
              opacity: hoverArea.containsMouse ? 0.32 : 0.16
              Behavior on opacity {
                NumberAnimation {
                  duration: 150
                }
              }
            }

            Rectangle {
              width: ScalerService.s(3)
              height: parent.height - ScalerService.s(14)
              anchors.verticalCenter: parent.verticalCenter
              anchors.left: parent.left
              anchors.leftMargin: ScalerService.s(8)
              radius: ScalerService.s(2)
              color: theme.button.text
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: ScalerService.s(22)
              anchors.rightMargin: ScalerService.s(10)
              spacing: ScalerService.s(8)

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                CustomText {
                  name: modelData.time
                  isBold: true
                  size: "small"
                }
                CustomText {
                  name: modelData.text
                  size: "small"
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  opacity: 0.7
                }
              }

              ButtonIconText {
                name: "delete"
                opacity: hoverArea.containsMouse ? 1 : 0.3
                Behavior on opacity {
                  NumberAnimation {
                    duration: 150
                  }
                }
                onClicked: ReminderService.removeReminder(reminderPopup.targetDate, modelData.id)
              }
            }

            MouseArea {
              id: hoverArea
              anchors.fill: parent
              hoverEnabled: true
              acceptedButtons: Qt.NoButton
            }
          }
        }

        // Trạng thái rỗng
        ColumnLayout {
          anchors.centerIn: parent
          visible: reminderList.count === 0
          spacing: ScalerService.s(6)

          ButtonIconText {
            name: "event_available"
            Layout.alignment: Qt.AlignHCenter
            opacity: 0.35
            enabled: false
          }
          CustomText {
            name: "Chưa có lời nhắc nào"
            size: "small"
            textColor: theme.primary.dim_foreground
            horizontalAlignment: Text.AlignHCenter
          }
        }
      }

      // Hai "chip" chọn giờ báo & âm thanh báo cho lời nhắc
      RowLayout {
        id: optionsRow
        Layout.fillWidth: true
        spacing: ScalerService.s(8)
        opacity: 0

        transform: Translate {
          id: optionsTranslate
          y: Number(ScalerService.s(10))
        }

        SequentialAnimation {
          id: optionsReveal
          PauseAnimation {
            duration: 40
          }
          ParallelAnimation {
            NumberAnimation {
              target: optionsRow
              property: "opacity"
              to: 1
              duration: 260
              easing.type: Easing.OutExpo
            }
            NumberAnimation {
              target: optionsTranslate
              property: "y"
              to: 0
              duration: 280
              easing.type: Easing.OutExpo
            }
          }
        }

        Rectangle {
          id: timeChip
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(38)
          radius: height / 2
          color: theme.button.background

          function pulseAttention() {
            attentionShake.restart();
          }

          transform: Translate {
            id: timeChipShake
            x: 0
          }

          SequentialAnimation {
            id: attentionShake
            NumberAnimation {
              target: timeChipShake
              property: "x"
              to: -ScalerService.s(6)
              duration: 60
            }
            NumberAnimation {
              target: timeChipShake
              property: "x"
              to: ScalerService.s(6)
              duration: 60
            }
            NumberAnimation {
              target: timeChipShake
              property: "x"
              to: -ScalerService.s(4)
              duration: 60
            }
            NumberAnimation {
              target: timeChipShake
              property: "x"
              to: 0
              duration: 60
            }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(12)
            anchors.rightMargin: ScalerService.s(10)
            spacing: ScalerService.s(6)

            ButtonIconText {
              name: "schedule"
            }
            CustomText {
              name: calendar.reminderTimeSet ? calendar.reminderTime : "Chọn giờ"
              size: "small"
              opacity: calendar.reminderTimeSet ? 1 : 0.6
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: {
              timePickerDial.setInitialTime(calendar.reminderTime);
              timePickerPopup.open();
            }
          }
        }

        Rectangle {
          id: soundChip
          Layout.fillWidth: true
          Layout.preferredHeight: ScalerService.s(38)
          radius: height / 2
          color: theme.button.background

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: ScalerService.s(12)
            anchors.rightMargin: ScalerService.s(10)
            spacing: ScalerService.s(6)

            ButtonIconText {
              name: "music_note"
            }
            CustomText {
              name: calendar.reminderSoundName
              size: "small"
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: soundPickerPopup.open()
          }
        }
      }

      // Ô nhập lời nhắc kiểu "pill"
      Rectangle {
        id: inputRow
        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(46)
        radius: height / 2
        color: theme.button.background
        opacity: 0

        transform: Translate {
          id: inputTranslate
          y: Number(ScalerService.s(10))
        }

        SequentialAnimation {
          id: inputReveal
          PauseAnimation {
            duration: 60
          }
          ParallelAnimation {
            NumberAnimation {
              target: inputRow
              property: "opacity"
              to: 1
              duration: 260
              easing.type: Easing.OutExpo
            }
            NumberAnimation {
              target: inputTranslate
              property: "y"
              to: 0
              duration: 280
              easing.type: Easing.OutExpo
            }
          }
        }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: ScalerService.s(16)
          anchors.rightMargin: ScalerService.s(5)
          spacing: ScalerService.s(8)

          TextField {
            id: textField
            placeholderText: "Thêm lời nhắc..."
            Layout.fillWidth: true
            background: Item {}
            color: theme.button.text
            onAccepted: submitReminder()
          }

          Rectangle {
            id: addBtnBg
            Layout.preferredWidth: ScalerService.s(36)
            Layout.preferredHeight: ScalerService.s(36)
            radius: width / 2
            color: theme.button.text

            SequentialAnimation {
              id: addPulse
              NumberAnimation {
                target: addBtnBg
                property: "scale"
                to: 0.85
                duration: 80
                easing.type: Easing.OutCubic
              }
              NumberAnimation {
                target: addBtnBg
                property: "scale"
                to: 1
                duration: 160
                easing.type: Easing.OutBack
                easing.overshoot: 2.5
              }
            }

            ButtonIconText {
              anchors.fill: parent
              name: "add"
              textColor: theme.button.background
              enabled: false
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: reminderPopup.submitReminder()
            }
          }
        }
      }
    }

    function submitReminder() {
      if (textField.text.trim().length === 0)
      return;
      // Bắt buộc chọn giờ trước khi thêm, tránh tạo nhầm lời nhắc lúc 00:00.
      if (!calendar.reminderTimeSet) {
        timeChip.pulseAttention();
        return;
      }

      ReminderService.addReminder(reminderPopup.targetDate, calendar.reminderTime, textField.text.trim(), calendar.reminderSoundUrl);
      textField.text = "";
      calendar.reminderTime = "00:00";
      calendar.reminderTimeSet = false;
      calendar.reminderSoundUrl = "";
      calendar.reminderSoundName = "Mặc định";
      addPulse.restart();
    }
  }

  // --- Popup chọn giờ báo bằng mặt đồng hồ xoay (kiểu Android) ---
  Popup {
    id: timePickerPopup
    modal: true
    focus: true
    x: (calendar.width - width) / 2
    y: (calendar.height - height) / 2
    padding: ScalerService.s(18)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    transformOrigin: Item.Center
    enter: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "opacity"
          from: 0
          to: 1
          duration: 220
          easing.type: Easing.OutExpo
        }
        NumberAnimation {
          property: "scale"
          from: 0.9
          to: 1
          duration: 260
          easing.type: Easing.OutExpo
        }
      }
    }
    exit: Transition {
      NumberAnimation {
        property: "opacity"
        from: 1
        to: 0
        duration: 140
        easing.type: Easing.InCubic
      }
    }

    background: Rectangle {
      color: theme.primary.background
      border.color: theme.button.border
      border.width: ScalerService.s(1)
      radius: ScalerService.s(18)

      layer.enabled: true
      layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: ScalerService.s(8)
        radius: ScalerService.s(20)
        samples: 32
        color: "#70000000"
        transparentBorder: true
      }
    }

    contentItem: Com.TimePickerDial {
      id: timePickerDial

      onTimeConfirmed: function (timeStr) {
        calendar.reminderTime = timeStr;
        calendar.reminderTimeSet = true;
        timePickerPopup.close();
      }
      onCancelled: timePickerPopup.close()
    }
  }

  // --- Popup chọn âm thanh báo từ thư mục "sounds" ---
  Popup {
    id: soundPickerPopup
    modal: true
    focus: true
    x: (calendar.width - width) / 2
    y: (calendar.height - height) / 2
    padding: ScalerService.s(18)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    transformOrigin: Item.Center
    enter: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "opacity"
          from: 0
          to: 1
          duration: 220
          easing.type: Easing.OutExpo
        }
        NumberAnimation {
          property: "scale"
          from: 0.9
          to: 1
          duration: 260
          easing.type: Easing.OutExpo
        }
      }
    }
    exit: Transition {
      NumberAnimation {
        property: "opacity"
        from: 1
        to: 0
        duration: 140
        easing.type: Easing.InCubic
      }
    }

    background: Rectangle {
      color: theme.primary.background
      border.color: theme.button.border
      border.width: ScalerService.s(1)
      radius: ScalerService.s(18)

      layer.enabled: true
      layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: ScalerService.s(8)
        radius: ScalerService.s(20)
        samples: 32
        color: "#70000000"
        transparentBorder: true
      }
    }

    onClosed: alarmSoundPicker.stopPreview()

    contentItem: Com.AlarmSoundPicker {
      id: alarmSoundPicker

      selectedFileUrl: calendar.reminderSoundUrl

      onSoundSelected: function (fileUrl, fileName) {
        calendar.reminderSoundUrl = fileUrl;
        calendar.reminderSoundName = fileName;
        soundPickerPopup.close();
      }
      onClosed: soundPickerPopup.close()
    }
  }

  function weekdayFullLabel(d) {
    const names = ["Chủ Nhật", "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy"];
    return names[d.getDay()];
  }

  function getDaysInMonth(month, year) {
    var days = [];
    var firstDay = new Date(year, month, 1);
    var lastDay = new Date(year, month + 1, 0);
    var startingDay = firstDay.getDay();

    // Ngày từ tháng trước
    var prevMonthLastDay = new Date(year, month, 0).getDate();
    for (var i = 0; i < startingDay; i++) {
      days.push({
          day: prevMonthLastDay - startingDay + i + 1,
          isCurrentMonth: false,
          isToday: false,
          fullDate: new Date(year, month - 1, prevMonthLastDay - startingDay + i + 1)
      });
    }

    // Ngày của tháng hiện tại
    var today = new Date();
    for (var j = 1; j <= lastDay.getDate(); j++) {
      var isToday = today.getDate() === j && today.getMonth() === month && today.getFullYear() === year;
      days.push({
          day: j,
          isCurrentMonth: true,
          isToday: isToday,
          fullDate: new Date(year, month, j)
      });
    }

    // Ngày từ tháng sau
    var totalCells = 42;
    var nextMonthDay = 1;
    while (days.length < totalCells) {
      days.push({
          day: nextMonthDay,
          isCurrentMonth: false,
          isToday: false,
          fullDate: new Date(year, month + 1, nextMonthDay)
      });
      nextMonthDay++;
    }

    return days;
  }

  function previousMonth() {
    currentDate = new Date(currentYear, currentMonth - 1, 1);
    currentMonth = currentDate.getMonth();
    currentYear = currentDate.getFullYear();
    // Không gán tay daysRepeater.model nữa: binding khai báo ở "model:" của Repeater
    // (getDaysInMonth(currentMonth, currentYear)) đã tự động chạy lại khi 2 property này
    // đổi. Gán tay ở đây từng phá vỡ binding đó vĩnh viễn, chỉ "chữa cháy" tạm mà thôi.
  }

  function nextMonth() {
    currentDate = new Date(currentYear, currentMonth + 1, 1);
    currentMonth = currentDate.getMonth();
    currentYear = currentDate.getFullYear();
  }

  function goToToday() {
    currentDate = new Date();
    currentMonth = currentDate.getMonth();
    currentYear = currentDate.getFullYear();
    selectedDate = new Date();
  }
}
