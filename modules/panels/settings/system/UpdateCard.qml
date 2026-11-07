import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components
import "../network/" as Net
import "../general/" as G

// Thẻ "Cập nhật" trong Cài đặt → Hệ thống: trạng thái, nút Kiểm tra / Cập nhật / Tải lại, bật tắt tự kiểm tra.
Rectangle {
  id: root

  readonly property string st: UpdateService.state
  function tr(key) { return LanguageService.t("update", key); }

  readonly property color accent: {
    if (st === "available") return theme.normal.yellow;
    if (st === "error") return theme.normal.red;
    if (st === "uptodate" || st === "baseline" || st === "done") return theme.normal.green;
    return theme.button.text;
  }
  readonly property string statusText: {
    switch (st) {
    case "checking": return tr("checking");
    case "uptodate": return tr("up_to_date");
    case "baseline": return tr("baseline");
    case "available": return tr("available");
    case "updating": return tr(UpdateService.stepKey !== "" ? UpdateService.stepKey : "updating");
    case "done": return tr("done");
    case "error": return UpdateService.errorText();
    default: return tr("check");
    }
  }
  readonly property string statusIcon: {
    switch (st) {
    case "available": return "system_update_alt";
    case "error": return "error";
    case "uptodate": case "baseline": case "done": return "check_circle";
    case "checking": case "updating": return "sync";
    default: return "update";
    }
  }

  Layout.fillWidth: true
  implicitHeight: col.implicitHeight + ScalerService.s(28)
  radius: ScalerService.s(Settings.appearance.radius2)
  color: Qt.alpha(theme.primary.dim_background, 0.5)
  border.width: ScalerService.s(1)
  border.color: st === "available" ? theme.normal.yellow : theme.button.border

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: ScalerService.s(14)
    spacing: ScalerService.s(10)

    // Tiêu đề + trạng thái
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(12)

      IconText {
        name: root.statusIcon
        size: "normal"
        textColor: root.accent
        property real spin: 0
        rotation: UpdateService.busy ? spin : 0
        NumberAnimation on spin {
          running: UpdateService.busy
          from: 0
          to: 360
          duration: 1100
          loops: Animation.Infinite
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(2)
        CustomText {
          name: root.tr("title")
          size: "small"
          isBold: true
          Layout.fillWidth: true
        }
        CustomText {
          name: root.statusText
          size: "xs"
          textColor: root.accent
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }
      }
    }

    // Phiên bản (mã commit rút gọn)
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(20)
      visible: UpdateService.localCommit !== "" || UpdateService.remoteCommit !== "" || UpdateService.version !== ""

      CustomText {
        name: root.tr("current")
        size: "xs"
        textColor: theme.primary.dim_foreground
        Layout.preferredWidth: ScalerService.s(120)
      }
      CustomText {
        name: (UpdateService.version !== "" ? "v" + UpdateService.version + "  ·  " : "") + (UpdateService.shortLocal || root.tr("unknown"))
        size: "xs"
        isBold: true
        Layout.fillWidth: true
      }
    }
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(20)
      visible: UpdateService.remoteCommit !== "" || UpdateService.remoteVersion !== ""

      CustomText {
        name: root.tr("latest")
        size: "xs"
        textColor: theme.primary.dim_foreground
        Layout.preferredWidth: ScalerService.s(120)
      }
      CustomText {
        name: [UpdateService.remoteVersion !== "" ? "v" + UpdateService.remoteVersion : "", UpdateService.shortRemote, UpdateService.message].filter(x => x !== "").join("  ·  ")
        size: "xs"
        isBold: true
        textColor: root.st === "available" ? theme.normal.yellow : theme.primary.foreground
        Layout.fillWidth: true
        wrapMode: Text.WordWrap
      }
    }

    CustomText {
      visible: UpdateService.backupPath !== "" && (root.st === "done" || root.st === "updating")
      name: root.tr("backup") + ": " + UpdateService.backupPath
      size: "2xs"
      textColor: theme.primary.dim_foreground
      Layout.fillWidth: true
      wrapMode: Text.WrapAnywhere
    }

    // Nút
    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(10)

      Net.NetButton {
        icon: "refresh"
        label: root.st === "checking" ? root.tr("checking") : root.tr("check")
        busy: root.st === "checking" || root.st === "updating"
        visible: root.st !== "done"
        onClicked: UpdateService.check(true)
      }
      Net.NetButton {
        icon: "download"
        label: root.st === "updating" ? root.tr("updating") : root.tr("update_now")
        active: true
        busy: root.st === "updating"
        visible: root.st === "available" || root.st === "updating"
        onClicked: UpdateService.apply()
      }
      Net.NetButton {
        icon: "restart_alt"
        label: root.tr("reload")
        active: true
        visible: root.st === "done"
        onClicked: UpdateService.reloadShell()
      }
    }

    G.SettingDivider {}

    G.SettingRow {
      title: root.tr("auto_check")
      desc: root.tr("auto_check_desc")
      CustomToggleSwitch {
        adapter: Settings.behavior.updateAutoCheck
        onClicked: Settings.behavior.updateAutoCheck = !Settings.behavior.updateAutoCheck
      }
    }
  }
}
