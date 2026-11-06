import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

RowLayout {
  property string label: ""
  property string value: ""
  Layout.fillWidth: true
  spacing: ScalerService.s(16)

  CustomText {
    name: parent.label
    size: "xs"
    textColor: theme.primary.dim_foreground
    Layout.preferredWidth: ScalerService.s(110)
  }
  CustomText {
    name: parent.value !== "" ? parent.value : "—"
    size: "xs"
    isBold: true
    Layout.fillWidth: true
    elide: Text.ElideRight
  }
}
