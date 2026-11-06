import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

// Nút nhỏ có icon + chữ
Rectangle {
  id: root
  property string icon: ""
  property string label: ""
  property bool active: false
  property bool busy: false
  signal clicked

  Layout.fillWidth: true
  Layout.preferredWidth: 1
  implicitHeight: ScalerService.s(44)
  implicitWidth: row.implicitWidth + ScalerService.s(24)
  radius: ScalerService.s(Settings.appearance.radius2)
  color: active ? Qt.alpha(theme.button.text, 0.25) : (ma.containsMouse ? Qt.alpha(theme.button.background_select, 0.36) : Qt.alpha(theme.primary.dim_background, 0.28))
  border.width: ScalerService.s(1)
  border.color: active ? theme.button.text : theme.button.border
  scale: ma.containsPress ? 0.97 : 1
  opacity: busy ? 0.6 : 1

  Behavior on color {
    ColorAnimation {
      duration: 150
    }
  }
  Behavior on scale {
    NumberAnimation {
      duration: 120
    }
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: ScalerService.s(6)
    IconText {
      visible: root.icon !== ""
      name: root.icon
      size: "xs"
      textColor: root.active ? theme.button.text : theme.primary.foreground
      RotationAnimation on rotation {
        running: root.busy
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
      }
    }
    CustomText {
      name: root.label
      size: "xs"
      isBold: root.active
    }
  }

  MouseArea {
    id: ma
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    enabled: !root.busy
    onClicked: {
      SoundService.playSound("pick");
      root.clicked();
    }
  }
}
