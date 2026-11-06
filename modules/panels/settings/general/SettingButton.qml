import QtQuick
import qs.services
import qs.commons

// Nút dạng viên thuốc. confirm: true => bấm lần đầu chỉ "lên đạn" (đổi chữ + đỏ),
// bấm lần nữa trong 2,5 giây mới phát tín hiệu activated().
Rectangle {
    id: btn

    property var theme: ThemeService.theme
    property string text: ""
    property string icon: ""
    property bool danger: false
    property bool confirm: false
    property string confirmText: "Bấm lần nữa để xác nhận"
    property bool armed: false
    property string flashText: ""
    property bool primary: false
    signal activated

    readonly property string shownText: flashText !== "" ? flashText : (armed ? confirmText : text)
    readonly property color accent: theme.button.text
    readonly property color hot: danger || armed ? theme.normal.red : accent

    function flash(t) {
        flashText = t;
        flashTimer.restart();
    }

    width: implicitWidth
    height: implicitHeight
    implicitWidth: row.implicitWidth + ScalerService.s(26)
    implicitHeight: ScalerService.s(34)
    radius: height / 2
    scale: ma.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }
    color: armed ? btn.theme.normal.red
         : (ma.containsMouse ? Qt.alpha(danger ? theme.normal.red : theme.button.background_select, danger ? 0.3 : 0.9)
                             : Qt.alpha(danger ? theme.normal.red : theme.button.background, danger ? 0.16 : 0.7))
    border.width: danger && !armed ? ScalerService.s(1) : 0
    border.color: Qt.alpha(theme.normal.red, 0.5)
    Behavior on color { ColorAnimation { duration: 140 } }

    Timer {
        id: armTimer
        interval: 2500
        onTriggered: btn.armed = false
    }
    Timer {
        id: flashTimer
        interval: 1800
        onTriggered: btn.flashText = ""
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: ScalerService.s(7)
        Text {
            visible: btn.icon !== ""
            text: btn.icon
            anchors.verticalCenter: parent.verticalCenter
            color: btn.armed ? btn.theme.primary.background : btn.hot
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(14) }
        }
        Text {
            text: btn.shownText
            anchors.verticalCenter: parent.verticalCenter
            color: btn.armed ? btn.theme.primary.background : (btn.danger ? btn.theme.normal.red : btn.theme.primary.foreground)
            font { family: Settings.appearance.font; pixelSize: ScalerService.s(12); weight: Font.Medium }
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (btn.confirm && !btn.armed) {
                btn.armed = true;
                armTimer.restart();
                return;
            }
            btn.armed = false;
            armTimer.stop();
            btn.activated();
        }
    }
}
