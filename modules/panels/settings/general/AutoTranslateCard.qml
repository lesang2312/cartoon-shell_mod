import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components
import "../network/" as Net
import "./" as G

// Bật/tắt dịch tự động giao diện + dịch toàn bộ một lượt + xóa cache.
Rectangle {
  id: root
  readonly property string st: AutoTranslateService.state
  function tr(key) { return LanguageService.t("autotr", key); }

  Layout.fillWidth: true
  implicitHeight: col.implicitHeight + ScalerService.s(28)
  radius: ScalerService.s(Settings.appearance.radius2)
  color: Qt.alpha(theme.primary.dim_background, 0.5)
  border.width: ScalerService.s(1)
  border.color: theme.button.border

  ColumnLayout {
    id: col
    anchors.fill: parent
    anchors.margins: ScalerService.s(14)
    spacing: ScalerService.s(10)

    G.SettingRow {
      title: root.tr("title")
      desc: root.tr("desc")
      CustomToggleSwitch {
        adapter: Settings.behavior.autoTranslate
        onClicked: Settings.behavior.autoTranslate = !Settings.behavior.autoTranslate
      }
    }

    CustomText {
      Layout.fillWidth: true
      size: "xs"
      wrapMode: Text.WordWrap
      textColor: root.st === "error" ? theme.normal.red : theme.primary.dim_foreground
      name: root.st === "translating"
            ? root.tr("translating") + " " + AutoTranslateService.done + "/" + AutoTranslateService.total
            : root.st === "error" ? root.tr("err_" + AutoTranslateService.errorCode) !== ("err_" + AutoTranslateService.errorCode)
                                    ? root.tr("err_" + AutoTranslateService.errorCode) : root.tr("err_generic")
            : root.tr("cached") + ": " + AutoTranslateService.cachedCount
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: ScalerService.s(10)
      Net.NetButton {
        icon: "translate"
        label: root.tr("translate_all")
        active: true
        busy: root.st === "translating"
        enabled: Settings.behavior.autoTranslate
        onClicked: AutoTranslateService.translateAll()
      }
      Net.NetButton {
        icon: "delete"
        label: root.tr("clear")
        onClicked: AutoTranslateService.clearCache()
      }
    }
  }
}
