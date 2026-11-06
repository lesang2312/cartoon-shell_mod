import QtQuick
import QtQuick.Layouts
import qs.components
import qs.services
import qs.commons

ColumnLayout {
  id: root
  Layout.fillWidth: true
  spacing: ScalerService.s(10)

  function choose(style, workspaceIcon) {
    SoundService.playSound("pick");
    Settings.appearance.styleIcons = style;
    if (workspaceIcon) {
      Settings.bar.styleWorkspace = "image";
      Settings.bar.iconWorkspace = workspaceIcon;
    }
  }

  CustomText {
    name: LanguageService.t("icons", "style")
    size: "small"
    isBold: true
  }

  GridLayout {
    Layout.fillWidth: true
    columns: 3
    columnSpacing: ScalerService.s(8)
    rowSpacing: ScalerService.s(8)

    Repeater {
      model: [
        { id: "cute", style: "image", icon: "chopper", title: "cute", desc: "cute_desc", path: "workspace/chopper/active.png" },
        { id: "anime", style: "image", icon: "nami", title: "anime", desc: "anime_desc", path: "workspace/nami/active.png" },
        { id: "minimal", style: "icon", icon: "", title: "minimal", desc: "minimal_desc", path: "" }
      ]
      delegate: Rectangle {
        required property var modelData
        readonly property bool selected: modelData.id === "minimal"
          ? Settings.appearance.styleIcons === "icon"
          : Settings.appearance.styleIcons === "image" && Settings.bar.iconWorkspace === modelData.icon

        Layout.fillWidth: true
        Layout.preferredHeight: ScalerService.s(112)
        radius: ScalerService.s(Settings.appearance.radius2)
        color: selected ? Qt.alpha(theme.button.background_select, 0.5) : Qt.alpha(theme.button.background, 0.22)
        border.width: ScalerService.s(selected ? 2 : 1)
        border.color: selected ? theme.button.border_select : theme.button.border

        Behavior on color { ColorAnimation { duration: 150 } }

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: ScalerService.s(7)
          spacing: ScalerService.s(3)
          Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            IconImage {
              anchors.centerIn: parent
              visible: modelData.path !== ""
              path: modelData.path
              size: "large"
              width: ScalerService.s(42)
              height: ScalerService.s(42)
            }
            IconText {
              anchors.centerIn: parent
              visible: modelData.path === ""
              name: "auto_awesome"
              size: "large"
              textColor: selected ? theme.button.text : theme.primary.foreground
            }
          }
          CustomText {
            Layout.fillWidth: true
            name: LanguageService.t("icons", modelData.title)
            size: "xs"
            isBold: selected
            horizontalAlignment: Text.AlignHCenter
          }
          CustomText {
            Layout.fillWidth: true
            name: LanguageService.t("icons", modelData.desc)
            size: "2xs"
            textColor: theme.primary.dim_foreground
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.choose(modelData.style, modelData.icon)
        }
      }
    }
  }
}
