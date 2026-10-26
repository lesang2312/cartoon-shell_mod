import QtQuick

// Icon SVG nét mảnh, đổi màu bằng cách nhúng màu vào data-URI (không cần Qt5Compat)
Image {
    id: icon
    property string path: ""            // phần bên trong <svg>, viewBox 24x24
    property color tint: "#FFFFFF"
    property real strokeWidth: 1.8

    readonly property string _c: String(tint).replace("#", "%23")
    source: path === "" ? "" : "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='"
            + _c + "' stroke-width='" + strokeWidth + "' stroke-linecap='round' stroke-linejoin='round'>" + path + "</svg>"
    sourceSize.width: width * 2
    sourceSize.height: height * 2
    smooth: true
}
