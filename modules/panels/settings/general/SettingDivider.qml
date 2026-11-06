import QtQuick
import QtQuick.Layouts
import qs.services

Rectangle {
    property var theme: ThemeService.theme
    Layout.fillWidth: true
    height: 1
    color: Qt.alpha(theme.primary.foreground, 0.08)
}
