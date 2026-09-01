import QtQuick
import QtQuick.Controls
import Quickshell.Wayland
import QtQuick.Layouts
import Quickshell
import qs.commons
import qs.components
import qs.services

PanelWindow {
    id: root
    
    width: ScalerService.s(370)
    height: ScalerService.s(370) 
    
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        top: true
    }

    margins {
        top: ScalerService.s(40) 
    }

    color: "transparent"

    Loader {
        anchors.fill: parent
        source: "../widgets/clock/Clock2.qml"
        active: true
    }
}