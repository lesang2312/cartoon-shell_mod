import QtQuick
import QtQuick.Effects
import qs.services

// Kính lỏng dựng hoàn toàn bằng hiệu ứng có sẵn của Qt (MultiEffect) — KHÔNG cần shader .qsb tùy chỉnh.
//  * Lớp giữa: hình nền làm mờ + đậm màu + nền đen.
//  * Vòng viền (bezel): cùng hình nền nhưng phóng to + ít mờ => giả khúc xạ sâu ở mép kính.
//  * Viền sáng (rim), ánh sheen phía trên và viền trong để có cảm giác dày/bóng như kính thật.
Item {
    id: root

    property Item src: null
    property real topLeftRadius: 0
    property real topRightRadius: 0
    property real bottomLeftRadius: 0
    property real bottomRightRadius: 0
    property real bezel: 14
    property real rim: GlassService.rimStrength
    property real darkness: GlassService.blackBacking
    property real depth: GlassService.refractionDepth
    property real nest: 0

    readonly property real ringWidth: Math.max(8, Math.min(bezel * 2.0, Math.min(width, height) * 0.4))

    // ---- mask hình dạng ----
    Rectangle {
        id: shapeMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        color: "black"
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }

    // Mặt nạ vòng viền có mép trong MỀM (blur) để không lộ hình vuông giữa vùng viền và vùng giữa.
    Item {
        id: ringMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1.0
            blurMax: Math.max(8, Math.round(root.ringWidth * 1.4))
        }

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "black"
            border.width: root.ringWidth * 0.9
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
        }
    }

    // ---- lớp giữa: mờ + nền đen ----
    MultiEffect {
        anchors.fill: parent
        source: root.src
        autoPaddingEnabled: false
        blurEnabled: true
        blur: 0.10
        blurMax: 20
        saturation: 0.88
        brightness: 0.0
        maskEnabled: true
        maskSource: shapeMask
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: root.darkness
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }

    // ---- vòng khúc xạ ở mép: phóng to hình nền, ít mờ, sáng hơn ----
    Item {
        id: ring
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: ringMask
        }

        MultiEffect {
            anchors.fill: parent
            source: root.src
            autoPaddingEnabled: false
            scale: root.depth
            blurEnabled: true
            blur: 0.10
            blurMax: 20
            saturation: 0.88
            brightness: 0.0
            contrast: 0.0
        }
    }

    // ---- sheen phía trên (ánh sáng quét trên mặt kính) ----
    Rectangle {
        anchors.fill: parent
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.15 * root.rim) }
            GradientStop { position: 0.28; color: Qt.rgba(1, 1, 1, 0.045 * root.rim) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }

    // ---- viền phản chiếu ngoài + viền trong ----
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1.5
        border.color: Qt.rgba(1, 1, 1, Math.min(0.75, 0.55 * root.rim))
        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: "transparent"
        border.width: Math.max(1, root.ringWidth * 0.35)
        border.color: Qt.rgba(1, 1, 1, 0.10 * root.rim)
        topLeftRadius: Math.max(0, root.topLeftRadius - 2)
        topRightRadius: Math.max(0, root.topRightRadius - 2)
        bottomLeftRadius: Math.max(0, root.bottomLeftRadius - 2)
        bottomRightRadius: Math.max(0, root.bottomRightRadius - 2)
    }
}
