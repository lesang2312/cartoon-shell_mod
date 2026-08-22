import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.components

// Banner hiện lên khi đến đúng giờ báo thức.
Item {
  id: root

  readonly property bool alarmActive: ReminderService.activeAlarm !== null

  implicitWidth: card.width
  implicitHeight: card.height
  visible: card.opacity > 0.01

  Rectangle {
    id: card
    width: ScalerService.s(280)
    height: ScalerService.s(56)
    radius: ScalerService.s(16)
    color: theme.primary.background
    border.color: theme.button.border
    border.width: ScalerService.s(1)

    opacity: 0
    scale: 0.9
    transformOrigin: Item.Top

    layer.enabled: true
    layer.effect: DropShadow {
      horizontalOffset: 0
      verticalOffset: ScalerService.s(6)
      radius: ScalerService.s(16)
      samples: 28
      color: "#70000000"
      transparentBorder: true
    }

    states: State {
      name: "shown"
      when: root.alarmActive
      PropertyChanges {
        target: card
        opacity: 1
        scale: 1
      }
    }

    transitions: Transition {
      ParallelAnimation {
        NumberAnimation {
          property: "opacity"
          duration: 220
          easing.type: Easing.OutExpo
        }
        NumberAnimation {
          property: "scale"
          duration: 240
          easing.type: Easing.OutExpo
        }
      }
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: ScalerService.s(14)
      anchors.rightMargin: ScalerService.s(8)
      spacing: ScalerService.s(10)

      Rectangle {
        Layout.preferredWidth: ScalerService.s(34)
        Layout.preferredHeight: ScalerService.s(34)
        radius: width / 2
        color: theme.button.text

        ButtonIconText {
          anchors.centerIn: parent
          name: "notifications_active"
          textColor: theme.button.background
          enabled: false
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        CustomText {
          name: root.alarmActive ? (ReminderService.activeAlarm.time + "  ·  " + I18nService.tr("alarm_label")) : ""
          isBold: true
          size: "small"
        }
        CustomText {
          name: root.alarmActive ? ReminderService.activeAlarm.text : ""
          size: "small"
          opacity: 0.7
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }

      Rectangle {
        Layout.preferredWidth: ScalerService.s(30)
        Layout.preferredHeight: ScalerService.s(30)
        radius: width / 2
        color: theme.button.background

        ButtonIconText {
          anchors.fill: parent
          name: "close"
          enabled: false
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: ReminderService.dismissAlarm()
        }
      }
    }
  }
}