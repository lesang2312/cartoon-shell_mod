import QtQuick
import QtQuick.Effects

// Ảnh đại diện tròn viền mảnh. Không có ảnh (hoặc renderer phần mềm) -> chữ cái đầu trên nền gradient
Item {
    id: av
    property string source: ""            // ảnh do cartoon-shell đồng bộ (ưu tiên)
    property string fallbackSource: ""    // ảnh của hệ thống (AccountsService / ~/.face)
    property string name: ""
    property color accent: "#FFB347"
    property string fontFamily: ""

    // MultiEffect không vẽ được ở renderer phần mềm -> dùng chữ cái đầu
    readonly property bool primaryOk: img.status === Image.Ready
    readonly property bool hasPhoto: (primaryOk || imgFallback.status === Image.Ready) && GraphicsInfo.api !== GraphicsInfo.Software

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(av.accent, 1.15) }
            GradientStop { position: 1.0; color: Qt.darker(av.accent, 1.35) }
        }
    }
    Text {
        visible: !av.hasPhoto
        anchors.centerIn: parent
        text: av.name.length > 0 ? av.name.charAt(0).toUpperCase() : "?"
        font.family: av.fontFamily
        font.pixelSize: av.height * 0.46
        font.weight: Font.DemiBold
        color: "#FFFFFF"
    }

    Image {
        id: img
        anchors.fill: parent
        source: av.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: false
        sourceSize.width: 400
        sourceSize.height: 400
    }
    Image {
        id: imgFallback
        anchors.fill: parent
        source: av.primaryOk ? "" : av.fallbackSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
        sourceSize.width: 400
        sourceSize.height: 400
    }
    Rectangle {
        id: maskShape
        anchors.fill: parent
        radius: width / 2
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        visible: av.hasPhoto
        anchors.fill: parent
        source: av.primaryOk ? img : imgFallback
        maskEnabled: true
        maskSource: maskShape
    }

    // vòng viền ngoài
    Rectangle {
        anchors.fill: parent
        anchors.margins: -3
        radius: width / 2
        color: "transparent"
        border.width: 1.5
        border.color: Qt.rgba(1, 1, 1, 0.55)
    }
}
