import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Fusion
import Quickshell
import qs.services
import qs.components
import qs.commons

import "." as Com

ColumnLayout {
  id: root
  Layout.preferredWidth: ScalerService.s(90)
  spacing: ScalerService.s(15)
  property real animationProgress: 0

  // Confirm popup state
  property bool showConfirmDialog: false
  property string confirmTitle: "Confirm"
  property string confirmMessage: ""
  property var pendingCommand: []

  function requestAction(message, command) {
    root.confirmMessage = message
    root.pendingCommand = command
    root.showConfirmDialog = true
  }

  RowLayout {
    spacing: ScalerService.s(15)

    // 1. Logout button
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(110)

      Rectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0.4 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.4 ? parent.height : 0
        Behavior on implicitHeight { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        color: mouseAreaLogout.containsMouse ? theme.button.background_select : theme.primary.background
        border.color: mouseAreaLogout.containsPress ? theme.button.border_select : theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

        IconImage {
          path: "system/sys-exit.png"
          size: "2xl"
          rotation: mouseAreaLogout.containsMouse ? -5 : 0
          anchors.centerIn: parent
          opacity: root.animationProgress > 0.9 ? 1 : 0
        }

        MouseArea {
          id: mouseAreaLogout
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestAction("Are you sure you want to log out?", ["loginctl", "terminate-user", ""])
        }
      }
    }

    // 2. Sleep button
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(110)

      Rectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0.45 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.45 ? parent.height : 0
        Behavior on implicitHeight { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        color: mouseAreaSleep.containsMouse ? theme.button.background_select : theme.primary.background
        border.color: mouseAreaSleep.containsPress ? theme.button.border_select : theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

        IconImage {
          path: "system/sys-sleep.png"
          anchors.centerIn: parent
          size: "2xl"
          rotation: mouseAreaSleep.containsMouse ? 5 : 0
          opacity: root.animationProgress > 0.95 ? 1 : 0
        }

        MouseArea {
          id: mouseAreaSleep
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestAction("Are you sure you want to enter Sleep mode?", ["systemctl", "suspend"])
        }
      }
    }
  }

  RowLayout {
    spacing: ScalerService.s(15)

    // 3. Reboot button
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(110)

      Rectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0.5 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.5 ? parent.height : 0
        Behavior on implicitHeight { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        color: mouseAreaRestart.containsMouse ? theme.button.background_select : theme.primary.background
        border.color: mouseAreaRestart.containsPress ? theme.button.border_select : theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

        IconImage {
          path: "system/sys-reboot.png"
          rotation: mouseAreaRestart.containsMouse ? 180 : 0
          anchors.centerIn: parent
          size: "2xl"
          opacity: root.animationProgress > 1 ? 1 : 0
        }

        MouseArea {
          id: mouseAreaRestart
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestAction("Are you sure you want to restart?", ["systemctl", "reboot"])
        }
      }
    }

    // 4. Shutdown button
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: ScalerService.s(110)

      Rectangle {
        anchors.centerIn: parent
        implicitWidth: root.animationProgress > 0.55 ? parent.width : 0
        implicitHeight: root.animationProgress > 0.55 ? parent.height : 0
        Behavior on implicitHeight { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        Behavior on implicitWidth { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
        color: mouseAreaShutdown.containsMouse ? theme.button.background_select : theme.primary.background
        border.color: mouseAreaShutdown.containsPress ? theme.button.border_select : theme.button.border
        radius: ScalerService.s(Settings.appearance.radius1)
        border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : 0

        IconImage {
          path: "system/poweroff.png"
          scale: mouseAreaShutdown.containsMouse ? 1.1 : 1
          anchors.centerIn: parent
          size: "2xl"
          opacity: root.animationProgress > 1.05 ? 1 : 0
        }

        MouseArea {
          id: mouseAreaShutdown
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.requestAction("Are you sure you want to shut down?", ["systemctl", "poweroff"])
        }
      }
    }
  }

  // --- CONFIRMATION DIALOG (STYLED POPUP + BACKGROUND BLUR) ---
  Popup {
    id: confirmModal
    visible: root.showConfirmDialog
    anchors.centerIn: Overlay.overlay
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    onClosed: root.showConfirmDialog = false

    // Dark overlay layer to highlight the popup
    Overlay.modal: Rectangle {
      color: "#a0000000"
      Behavior on opacity {
        NumberAnimation { duration: 200 }
      }
    }

    // Zoom + fade-in effect on appearance
    enter: Transition {
      NumberAnimation { property: "scale"; from: 0.85; to: 1.0; duration: 200; easing.type: Easing.OutBack }
      NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: 150 }
    }
    exit: Transition {
      NumberAnimation { property: "scale"; from: 1.0; to: 0.85; duration: 150; easing.type: Easing.InCubic }
      NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 150 }
    }

    padding: ScalerService.s(25)

    background: Rectangle {
      implicitWidth: ScalerService.s(360)
      color: theme.primary.background
      radius: ScalerService.s(20)
      border.color: theme.button.border
      border.width: Settings.appearance.enableBorder ? ScalerService.s(3) : ScalerService.s(2)
    }

    contentItem: ColumnLayout {
      spacing: ScalerService.s(18)

      // Title
      CustomText {
        name: root.confirmTitle
        isBold: true
        font.pixelSize: ScalerService.s(22)
        Layout.alignment: Qt.AlignHCenter
      }

      // Question content
      CustomText {
        name: root.confirmMessage
        font.pixelSize: ScalerService.s(14)
        Layout.alignment: Qt.AlignHCenter
      }

      Item { Layout.preferredHeight: ScalerService.s(5) }

      // "No" and "Yes" button row
      RowLayout {
        spacing: ScalerService.s(20)
        Layout.alignment: Qt.AlignHCenter

        // "No" button
        Rectangle {
          implicitWidth: ScalerService.s(120)
          implicitHeight: ScalerService.s(42)
          radius: ScalerService.s(14)
          color: btnNoMouse.containsMouse ? theme.button.background_select : theme.primary.background
          border.color: btnNoMouse.containsMouse ? theme.button.border_select : theme.button.border
          border.width: ScalerService.s(2)

          Behavior on color { ColorAnimation { duration: 120 } }

          CustomText {
            anchors.centerIn: parent
            name: "No"
            isBold: btnNoMouse.containsMouse
          }

          MouseArea {
            id: btnNoMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.showConfirmDialog = false
          }
        }

        // "Yes" button (highlighted with a soft pink/red border, matching the reference design)
        Rectangle {
          implicitWidth: ScalerService.s(120)
          implicitHeight: ScalerService.s(42)
          radius: ScalerService.s(14)
          color: btnYesMouse.containsMouse ? "#30e78284" : theme.primary.background
          border.color: btnYesMouse.containsMouse ? "#f38ba8" : "#e78284"
          border.width: ScalerService.s(2)

          Behavior on color { ColorAnimation { duration: 120 } }

          CustomText {
            anchors.centerIn: parent
            name: "Yes"
            isBold: true
          }

          MouseArea {
            id: btnYesMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.showConfirmDialog = false
              if (root.pendingCommand.length > 0) {
                Quickshell.execDetached(root.pendingCommand)
              }
            }
          }
        }
      }
    }
  }
}