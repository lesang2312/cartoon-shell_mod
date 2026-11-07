import QtQuick
import QtQuick.Layouts
import qs.services
import qs.commons
import qs.components
import "." as Com

GridLayout {
  id: root
  property real animationProgress: 0

  columns: 3
  rows: 2
  columnSpacing: ScalerService.s(15)
  rowSpacing: ScalerService.s(15)

  Com.WeatherDetailCard {
    icon: "water_drops"
    label: AutoTranslateService.t("Humidity")
    value: `${WeatherService.dataModel.current.humidity} %`
    animationProgress: root.animationProgress
  }

  Com.WeatherDetailCard {
    icon: "air"
    label: AutoTranslateService.t("Winds")
    value: `${WeatherService.dataModel.current.wind_kph} Km/h`
    animationProgress: root.animationProgress
  }

  Com.WeatherDetailCard {
    icon: "blood_pressure"
    label: AutoTranslateService.t("Pressure")
    value: `${WeatherService.dataModel.current.pressure_mb} hPa`
    animationProgress: root.animationProgress
  }

  Com.WeatherDetailCard {
    icon: "visibility"
    label: AutoTranslateService.t("Visibility")
    value: `${WeatherService.dataModel.current.vis_km} km`
    animationProgress: root.animationProgress
  }

  Com.WeatherDetailCard {
    icon: "wb_sunny"
    label: AutoTranslateService.t("UV")
    value: `${WeatherService.dataModel.current.uv}`
    animationProgress: root.animationProgress
  }

  Com.WeatherDetailCard {
    icon: "rainy"
    label: AutoTranslateService.t("Chance of rain")
    value: `${WeatherService.dataModel.current.chance_of_rain}%`
    animationProgress: root.animationProgress
  }
}
