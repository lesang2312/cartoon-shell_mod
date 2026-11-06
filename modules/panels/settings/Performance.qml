// Balanced, compact performance controls.
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components

Item {
  id: root

  Component.onCompleted: QuickSettingsService.refresh()
  function tr(key) { return LanguageService.t("performance", key); }

  readonly property var profiles: [
    { id: "power-saver", icon: "eco", label: "power_saver", desc: "power_saver_desc" },
    { id: "balanced", icon: "balance", label: "balanced", desc: "balanced_desc" },
    { id: "performance", icon: "bolt", label: "performance", desc: "performance_desc" }
  ]

  ScrollView {
    anchors.fill: parent
    anchors.margins: ScalerService.s(18)
    clip: true
    contentWidth: availableWidth
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

    ColumnLayout {
      width: parent.width
      spacing: ScalerService.s(12)

      CustomText {
        name: root.tr("title")
        size: "large"
        isBold: true
        Layout.topMargin: ScalerService.s(8)
      }
      Rectangle { Layout.fillWidth: true; height: 1; color: theme.primary.foreground; opacity: 0.28 }

      // One-touch profile, with a clear compact status line.
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: saverRow.implicitHeight + ScalerService.s(22)
        radius: ScalerService.s(Settings.appearance.radius2)
        color: QuickSettingsService.powerSaverMode ? Qt.alpha(theme.normal.green, 0.18) : Qt.alpha(theme.button.background, 0.25)
        border.width: ScalerService.s(1)
        border.color: QuickSettingsService.powerSaverMode ? Qt.alpha(theme.normal.green, 0.8) : theme.button.border

        RowLayout {
          id: saverRow
          anchors.fill: parent
          anchors.margins: ScalerService.s(11)
          spacing: ScalerService.s(10)
          IconText { name: "battery_saver"; size: "large"; textColor: QuickSettingsService.powerSaverMode ? theme.normal.green : theme.button.text }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(3)
            CustomText { name: root.tr("saver_mode"); size: "small"; isBold: true }
            CustomText { Layout.fillWidth: true; name: root.tr("saver_mode_desc"); size: "xs"; textColor: theme.primary.dim_foreground; wrapMode: Text.WordWrap }
          }
          CustomToggleSwitch {
            adapter: QuickSettingsService.powerSaverMode
            onClicked: QuickSettingsService.setPowerSaverMode(!QuickSettingsService.powerSaverMode)
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        CustomText { name: root.tr("current_profile"); size: "small"; isBold: true }
        Item { Layout.fillWidth: true }
        CustomText {
          name: {
            var id = QuickSettingsService.powerProfile;
            for (var i = 0; i < root.profiles.length; i++) if (root.profiles[i].id === id) return root.tr(root.profiles[i].label);
            return root.tr("balanced");
          }
          size: "xs"
          textColor: theme.button.text
          isBold: true
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: ScalerService.s(8)
        rowSpacing: ScalerService.s(8)
        opacity: QuickSettingsService.hasPowerProfiles ? 1 : 0.45

        Repeater {
          model: root.profiles
          delegate: Rectangle {
            required property var modelData
            readonly property bool selected: QuickSettingsService.powerProfile === modelData.id
            Layout.fillWidth: true
            Layout.preferredHeight: ScalerService.s(104)
            radius: ScalerService.s(Settings.appearance.radius2)
            color: selected ? Qt.alpha(theme.button.background_select, 0.54) : Qt.alpha(theme.button.background, 0.22)
            border.width: ScalerService.s(selected ? 2 : 1)
            border.color: selected ? theme.button.border_select : theme.button.border

            Behavior on color { ColorAnimation { duration: 140 } }
            ColumnLayout {
              anchors.fill: parent
              anchors.margins: ScalerService.s(7)
              spacing: ScalerService.s(4)
              IconText {
                Layout.alignment: Qt.AlignHCenter
                name: modelData.icon
                size: "normal"
                textColor: selected ? theme.button.text : theme.primary.foreground
              }
              CustomText {
                Layout.fillWidth: true
                name: root.tr(modelData.label)
                size: "xs"
                isBold: selected
                horizontalAlignment: Text.AlignHCenter
              }
              CustomText {
                Layout.fillWidth: true
                name: root.tr(modelData.desc)
                size: "2xs"
                textColor: theme.primary.dim_foreground
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
              }
            }
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              enabled: QuickSettingsService.hasPowerProfiles
              cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
              onClicked: {
                SoundService.playSound("pick");
                QuickSettingsService.setPowerProfile(modelData.id);
              }
            }
          }
        }
      }

      CustomText {
        Layout.fillWidth: true
        visible: !QuickSettingsService.hasPowerProfiles
        name: root.tr("profiles_unavailable")
        size: "xs"
        textColor: theme.normal.yellow
        wrapMode: Text.WordWrap
      }

      // Visual controls share a single glassy group to avoid oversized gaps.
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: effectsColumn.implicitHeight + ScalerService.s(20)
        radius: ScalerService.s(Settings.appearance.radius2)
        color: Qt.alpha(theme.button.background, 0.22)
        border.width: ScalerService.s(1)
        border.color: theme.button.border

        ColumnLayout {
          id: effectsColumn
          anchors.fill: parent
          anchors.margins: ScalerService.s(10)
          spacing: ScalerService.s(10)

          CustomText { name: root.tr("visual_effects"); size: "small"; isBold: true }
          RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(10)
            IconText { name: "auto_awesome"; size: "normal"; textColor: theme.button.text }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: ScalerService.s(2)
              CustomText { name: root.tr("effects_title"); size: "small"; isBold: true }
              CustomText { Layout.fillWidth: true; name: root.tr("effects_desc"); size: "xs"; textColor: theme.primary.dim_foreground; wrapMode: Text.WordWrap }
            }
            CustomToggleSwitch { adapter: QuickSettingsService.effectsEnabled; onClicked: QuickSettingsService.setEffects(!QuickSettingsService.effectsEnabled) }
          }
          Rectangle { Layout.fillWidth: true; height: 1; color: theme.button.border; opacity: 0.38 }
          RowLayout {
            Layout.fillWidth: true
            spacing: ScalerService.s(10)
            IconText { name: "blur_on"; size: "normal"; textColor: theme.button.text }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: ScalerService.s(2)
              CustomText { name: root.tr("liquid_glass"); size: "small"; isBold: true }
              CustomText { Layout.fillWidth: true; name: root.tr("glass_desc"); size: "xs"; textColor: theme.primary.dim_foreground; wrapMode: Text.WordWrap }
            }
            CustomToggleSwitch { adapter: GlassService.enabled; onClicked: GlassService.toggle() }
          }
        }
      }
      Item { Layout.preferredHeight: ScalerService.s(8) }
    }
  }
}
