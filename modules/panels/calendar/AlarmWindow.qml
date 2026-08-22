import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import "." as Com

PanelWindow {
  id: alarmWindow

  readonly property bool noticeActive: ReminderService.activeNotice !== null
  readonly property bool alarmActive: ReminderService.activeAlarm !== null
  readonly property bool hasActiveItem: noticeActive || alarmActive

  readonly property int activeCount: (noticeActive ? 1 : 0) + (alarmActive ? 1 : 0)

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

  implicitWidth: hasActiveItem ? ScalerService.s(300) : 1
  implicitHeight: hasActiveItem ? ScalerService.s(activeCount * 64 + (activeCount - 1) * 6) : 1

  Behavior on implicitWidth {
    NumberAnimation {
      duration: 200
      easing.type: Easing.OutCubic
    }
  }
  Behavior on implicitHeight {
    NumberAnimation {
      duration: 200
      easing.type: Easing.OutCubic
    }
  }

  anchors.top: true
  margins.top: ScalerService.s(10)

  exclusiveZone: 0
  color: "transparent"
  mask: hasActiveItem ? null : emptyMask

  Region {
    id: emptyMask
  }

  ColumnLayout {
    anchors.centerIn: parent
    spacing: ScalerService.s(6)

    Com.NoticeBanner {
      visible: alarmWindow.noticeActive
    }

    Com.AlarmBanner {
      visible: alarmWindow.alarmActive
    }
  }
}