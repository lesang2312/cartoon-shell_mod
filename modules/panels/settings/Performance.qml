// Cài đặt Hiệu suất / tiết kiệm điện
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

Item {
  id: root

  Component.onCompleted: QuickSettingsService.refresh()

  readonly property var profiles: [
    {
      "id": "power-saver",
      "icon": "eco",
      "label": "Tiết kiệm pin"
    },
    {
      "id": "balanced",
      "icon": "balance",
      "label": "Cân bằng"
    },
    {
      "id": "performance",
      "icon": "bolt",
      "label": "Hiệu suất cao"
    }
  ]

  ScrollView {
    anchors.fill: parent
    anchors.margins: ScalerService.s(20)
    clip: true

    ColumnLayout {
      width: parent.width
      spacing: ScalerService.s(15)

      CustomText {
        name: "Hiệu suất"
        size: "large"
        isBold: true
        Layout.topMargin: ScalerService.s(10)
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: theme.primary.foreground
      }

      // ---- Chế độ tiết kiệm điện tổng hợp ----
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: saverRow.implicitHeight + ScalerService.s(24)
        radius: ScalerService.s(Settings.appearance.radius2)
        color: QuickSettingsService.powerSaverMode ? Qt.alpha(theme.button.text, 0.2) : Qt.alpha(theme.button.background, 0.4)
        border.width: ScalerService.s(1)
        border.color: QuickSettingsService.powerSaverMode ? theme.button.text : theme.button.border

        RowLayout {
          id: saverRow
          anchors.fill: parent
          anchors.margins: ScalerService.s(12)
          spacing: ScalerService.s(12)

          IconText {
            name: "battery_saver"
            size: "large"
            textColor: theme.button.text
          }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(2)
            CustomText {
              name: "Chế độ tiết kiệm điện"
              size: "small"
              isBold: true
            }
            CustomText {
              Layout.fillWidth: true
              name: "Một chạm: profile Tiết kiệm pin + tắt animation/blur/đổ bóng + tắt Liquid Glass."
              size: "xs"
              textColor: theme.primary.dim_foreground
              wrapMode: Text.WordWrap
            }
          }
          CustomToggleSwitch {
            adapter: QuickSettingsService.powerSaverMode
            onClicked: QuickSettingsService.setPowerSaverMode(!QuickSettingsService.powerSaverMode)
          }
        }
      }

      // ---- Profile nguồn ----
      CustomText {
        name: "Chế độ nguồn"
        size: "small"
        isBold: true
      }
      CustomText {
        Layout.fillWidth: true
        visible: !QuickSettingsService.hasPowerProfiles
        name: "Không tìm thấy powerprofilesctl. Cài power-profiles-daemon để dùng mục này."
        size: "xs"
        textColor: theme.primary.dim_foreground
        wrapMode: Text.WordWrap
      }
      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(10)
        opacity: QuickSettingsService.hasPowerProfiles ? 1 : 0.4

        Repeater {
          model: root.profiles
          delegate: Rectangle {
            required property var modelData
            readonly property bool selected: QuickSettingsService.powerProfile === modelData.id
            Layout.fillWidth: true
            implicitHeight: ScalerService.s(72)
            radius: ScalerService.s(Settings.appearance.radius2)
            color: selected ? Qt.alpha(theme.button.text, 0.25) : (pa.containsMouse ? Qt.alpha(theme.button.background_select, 0.4) : Qt.alpha(theme.button.background, 0.4))
            border.width: ScalerService.s(1)
            border.color: selected ? theme.button.text : theme.button.border
            Behavior on color {
              ColorAnimation {
                duration: 150
              }
            }
            ColumnLayout {
              anchors.centerIn: parent
              spacing: ScalerService.s(4)
              IconText {
                Layout.alignment: Qt.AlignHCenter
                name: modelData.icon
                size: "normal"
                textColor: selected ? theme.button.text : theme.primary.foreground
              }
              CustomText {
                Layout.alignment: Qt.AlignHCenter
                name: modelData.label
                size: "xs"
                isBold: selected
              }
            }
            MouseArea {
              id: pa
              anchors.fill: parent
              hoverEnabled: true
              enabled: QuickSettingsService.hasPowerProfiles
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                SoundService.playSound("pick");
                QuickSettingsService.setPowerProfile(modelData.id);
              }
            }
          }
        }
      }

      // ---- Hiệu ứng ----
      CustomText {
        name: "Hiệu ứng hình ảnh"
        size: "small"
        isBold: true
        Layout.topMargin: ScalerService.s(6)
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(12)
        ColumnLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(2)
          CustomText {
            name: "Animation, blur, đổ bóng (Hyprland)"
            size: "small"
          }
          CustomText {
            Layout.fillWidth: true
            name: "Tắt để giảm tải GPU."
            size: "xs"
            textColor: theme.primary.dim_foreground
            wrapMode: Text.WordWrap
          }
        }
        CustomToggleSwitch {
          adapter: QuickSettingsService.effectsEnabled
          onClicked: QuickSettingsService.setEffects(!QuickSettingsService.effectsEnabled)
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(12)
        ColumnLayout {
          Layout.fillWidth: true
          spacing: ScalerService.s(2)
          CustomText {
            name: "Liquid Glass"
            size: "small"
          }
          CustomText {
            Layout.fillWidth: true
            name: "Hiệu ứng kính tốn GPU nhất. Tắt đi để tiết kiệm điện."
            size: "xs"
            textColor: theme.primary.dim_foreground
            wrapMode: Text.WordWrap
          }
        }
        CustomToggleSwitch {
          adapter: GlassService.enabled
          onClicked: GlassService.toggle()
        }
      }

      Item {
        Layout.fillHeight: true
      }
    }
  }
}
