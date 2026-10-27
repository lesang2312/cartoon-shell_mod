import QtQuick
import qs.services

// Hiển thị 1 ảnh/icon cho App Grid.
// `source` có thể là:
//   - đường dẫn tuyệt đối  (/home/x/.config/quickshell/cartoon-shell/icons/cat.png)
//   - URL                  (file://..., https://...)
//   - tên icon trong theme (kitty, firefox, ...)
// Nếu không tải được -> hiện chữ cái đầu của `fallbackText`.
Item {
    id: root

    property string source: ""
    property string fallbackText: "?"
    property color fallbackColor: "#cdd6f4"

    readonly property string resolved: {
        const s = root.source || "";
        if (s === "")
            return "";
        if (s.indexOf("://") >= 0)
            return s;
        if (s.charAt(0) === "/")
            return "file://" + s;
        return "image://icon/" + s;
    }

    Image {
        id: img
        anchors.fill: parent
        source: root.resolved
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
        sourceSize.width: 128
        sourceSize.height: 128
        visible: status === Image.Ready
    }

    Text {
        anchors.centerIn: parent
        visible: img.status !== Image.Ready
        text: (root.fallbackText || "?").charAt(0).toUpperCase()
        color: root.fallbackColor
        font.pixelSize: Math.max(10, root.height * 0.55)
        font.bold: true
        font.family: "ComicShannsMono Nerd Font"
    }
}
