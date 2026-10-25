import QtQuick
import qs.services

// Lớp ShaderEffect vẽ kính lỏng. Tên property trùng với uniform trong shaders/liquid_glass.frag.
ShaderEffect {
    id: root

    property variant src
    property real topLeftRadius: 1
    property real topRightRadius: 1
    property real bottomLeftRadius: 1
    property real bottomRightRadius: 1
    property color tintColor: GlassService.base
    property real tintAmount: 0
    property real bezel: Math.max(5, Math.min(26, Math.min(width, height) * 0.36))
    property real thickness: bezel * 1.15
    property real ior: 1.5
    property real dispersion: 0.11
    property real frost: 1.5
    property real rim: 0.45
    property real saturation: 1.25
    property rect sourceRect: Qt.rect(0, 0, 1, 1)
    property point cursorPos: Qt.point(0, 0)
    property real hover: 0
    property real clear: 0
    property real glassPad: 0
    property real shadowAmt: 0
    property real energy: 0
    property real nest: 0
    property real morph: 0
    property real motion: 0
    property vector2d filletDir: Qt.vector2d(0, 0)
    property real filletRadius: 0
    property real filletInset: 0
    property bool earsOnly: false
    property rect boxRect: Qt.rect(0, 0, 0, 0)
    property rect validRect: Qt.rect(0, 0, 1, 1)
    property real unpremul: 0

    // Uniform thực sự được shader đọc
    property vector2d itemSize: Qt.vector2d(width, height)
    property vector4d radii: Qt.vector4d(topLeftRadius, topRightRadius, bottomRightRadius, bottomLeftRadius)
    property vector4d srcRect: Qt.vector4d(sourceRect.x, sourceRect.y, sourceRect.width, sourceRect.height)
    property vector2d cursor: Qt.vector2d(cursorPos.x, cursorPos.y)
    property vector4d sampleBounds: Qt.vector4d(validRect.x, validRect.y, validRect.x + validRect.width, validRect.y + validRect.height)
    property vector4d fillet: Qt.vector4d(filletDir.x, filletDir.y, filletRadius, earsOnly ? 1 : 0)
    property vector4d box: boxRect.width > 0 ? Qt.vector4d(boxRect.x + boxRect.width * 0.5 - width * 0.5, boxRect.y + boxRect.height * 0.5 - height * 0.5, boxRect.width * 0.5, boxRect.height * 0.5) : Qt.vector4d(0, 0, 0, 0)

    fragmentShader: GlassService.shaderUrl
}
