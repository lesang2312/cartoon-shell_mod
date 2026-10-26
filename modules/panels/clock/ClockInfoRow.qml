import QtQuick
import QtQuick.Layouts
import Quickshell.Services.UPower
import qs.services
import qs.commons
import qs.components

// Dải thông tin kiểu Android "At a glance": pin, thời tiết, wifi
Item {
  id: root

  readonly property int percent: Math.round(UPower.displayDevice.percentage * 100)
  readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery || UPower.displayDevice.isPresent
  readonly property bool charging: UPowerDeviceState.toString(UPower.displayDevice.state) === "Charging"
  readonly property var weather: WeatherService.dataModel?.current ?? null

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  component Pill: Rectangle {
    default property alias content: inner.data
    implicitWidth: inner.implicitWidth + ScalerService.s(28)
    implicitHeight: ScalerService.s(46)
    radius: height / 2
    color: Qt.rgba(1, 1, 1, 0.16)
    border.color: Qt.rgba(1, 1, 1, 0.28)
    border.width: ScalerService.s(1)

    RowLayout {
      id: inner
      anchors.centerIn: parent
      spacing: ScalerService.s(8)
    }
  }

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: ScalerService.s(12)

    // Pin
    Pill {
      visible: root.hasBattery
      BatteryIcon {
        percent: root.percent
        textColor: "#ffffff"
        iconWidth: ScalerService.s(34)
        iconHeight: ScalerService.s(16)
        Layout.rightMargin: ScalerService.s(4)
      }
      CustomText {
        name: `${root.percent}%${root.charging ? " ⚡" : ""}`
        textColor: "#ffffff"
        isBold: true
        size: "xs"
      }
    }

    // Thời tiết
    Pill {
      visible: root.weather !== null
      IconImage {
        path: root.weather ? WeatherService.getWeatherIcon(root.weather.condition.code, root.weather.is_day) : ""
        size: "xs"
      }
      CustomText {
        name: root.weather ? `${Math.round(root.weather.temp_c)}°C` : ""
        textColor: "#ffffff"
        isBold: true
        size: "xs"
      }
    }

    // Wifi
    Pill {
      visible: NetworkService.connectedWifi !== "" && NetworkService.connectedWifi !== "Checking..."
      IconText {
        name: "wifi"
        textColor: "#ffffff"
        size: "xs"
      }
      CustomText {
        name: NetworkService.connectedWifi
        textColor: "#ffffff"
        size: "xs"
        elide: Text.ElideRight
        Layout.maximumWidth: ScalerService.s(160)
      }
    }
  }
}
