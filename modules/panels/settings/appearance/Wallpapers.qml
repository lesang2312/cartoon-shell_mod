import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel
import qs.services
import qs.commons

Item {
    id: systemSettings
    property string homePath: Directories.home
    property string wallpapersPath: "file://" + Directories.home + "/Pictures/Wallpapers/"
    property string wallpaperPath: ""
    property string currentWallpaper: ""  // Lưu đường dẫn đã chuẩn hóa (không có file://)
    property int currentScreenIndex: 0
    property var currentScreen: Quickshell.screens[currentScreenIndex] || null

    // Đường dẫn thư mục lưu thumbnail tạm
    property string thumbnailDir: homePath ? homePath + "/.cache/quickshell/wallpapers_thumbs" : ""

    // Hàm helper để chuẩn hóa đường dẫn (bỏ file://)
    function normalizePath(path) {
        if (!path)
            return "";
        var strPath = path.toString();
        return strPath.replace(/^file:\/\//, "");
    }

    // Process để set wallpaper
    Process {
        id: wallpaperProcess

        stdout: StdioCollector {
            onTextChanged: {}
        }

        onRunningChanged: {
            if (!running) {
                currentWallpaper = normalizePath(wallpaperPath);
                showNotification(lang?.wallpapers?.success_set || "Đã đặt hình nền thành công!");
            }
        }
    }

    // Process để xóa file (bao gồm cả xóa thumbnail)
    Process {
        id: deleteProcess

        stdout: StdioCollector {
            onTextChanged: {}
        }

        onRunningChanged: {
            if (!running) {
                showNotification(lang?.wallpapers?.success_delete || "Đã xóa ảnh thành công!");
            }
        }
    }

    // Process để tạo thumbnail cho video sử dụng ffmpeg tối ưu
    Process {
        id: thumbnailProcess

        onRunningChanged: {
            if (!running) {
                // Refresh lại model hoặc grid sau khi tạo xong nếu cần
            }
        }
    }

    // Process chạy ngầm để dọn dẹp các thumbnail mồ côi
    Process {
        id: cleanupProcess
    }

    // FolderListModel để liệt kê ảnh & video
    FolderListModel {
        id: folderModel
        folder: wallpapersPath
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.bmp", "*.webp", "*.gif", "*.mp4", "*.webm", "*.mkv", "*.avi", "*.mov", "*.flv", "*.wmv", "*.m4v", "*.mpg", "*.mpeg"]
        showDirs: false
        showFiles: true
        showHidden: false
        sortField: FolderListModel.Name
        caseSensitive: false

        onStatusChanged: {
            if (status === FolderListModel.Ready) {
                cleanupOldThumbnails();
            }
        }
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: ScalerService.s(20)
        clip: true
        ScrollBar.vertical.policy: ScrollBar.AsNeeded

        ColumnLayout {
            width: parent.width
            spacing: ScalerService.s(15)

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(10)

                Text {
                    text: lang?.wallpapers?.title || "Quản lý hình ảnh"
                    color: theme.primary.foreground
                    font.pixelSize: ScalerService.s(24)
                    font.bold: true
                    font.family: "ComicShannsMono Nerd Font"
                }

                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: ScalerService.s(1)
                color: theme.primary.foreground
            }

            // Screen selector
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(5)

                Repeater {
                    model: Quickshell.screens

                    delegate: Rectangle {
                        Layout.preferredWidth: ScalerService.s(100)
                        Layout.preferredHeight: ScalerService.s(30)
                        radius: ScalerService.s(6)
                        color: systemSettings.currentScreenIndex === index ? theme.normal.blue : theme.button.background
                        border.color: theme.button.border
                        border.width: ScalerService.s(1)

                        Text {
                            anchors.centerIn: parent
                            text: modelData.name || `Screen ${index + 1}`
                            color: systemSettings.currentScreenIndex === index ? theme.primary.background : theme.primary.foreground
                            font.pixelSize: ScalerService.s(12)
                            font.family: "ComicShannsMono Nerd Font"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: systemSettings.currentScreenIndex = index
                        }
                    }
                }
            }

            // Statistics
            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(20)

                Rectangle {
                    Layout.preferredHeight: ScalerService.s(40)
                    Layout.fillWidth: true
                    radius: ScalerService.s(8)
                    color: theme.button.background
                    border.color: theme.button.border
                    border.width: ScalerService.s(2)

                    Row {
                        anchors.centerIn: parent
                        spacing: ScalerService.s(8)

                        Text {
                            text: lang?.wallpapers?.total_images || "Tổng số ảnh:"
                            font.family: "ComicShannsMono Nerd Font"
                            color: theme.primary.dim_foreground
                            font.pixelSize: ScalerService.s(15)
                        }

                        Text {
                            text: folderModel.count
                            color: theme.normal.blue
                            font.family: "ComicShannsMono Nerd Font"
                            font.pixelSize: ScalerService.s(18)
                            font.bold: true
                        }

                        Text {
                            text: "|"
                            color: theme.primary.dim_foreground
                            font.pixelSize: ScalerService.s(15)
                        }

                        Text {
                            text: homePath ? (lang?.wallpapers?.path || "Đường dẫn:") + " ~/Pictures/Wallpapers/" : (lang?.wallpapers?.loading || "Đang tải...")
                            font.family: "ComicShannsMono Nerd Font"
                            color: theme.primary.dim_foreground
                            font.pixelSize: ScalerService.s(15)
                            elide: Text.ElideMiddle
                        }
                    }
                }
            }

            // Wallpapers Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(10)

                Text {
                    text: lang?.wallpapers?.wallpapers_label || "Hình nền:"
                    color: theme.primary.foreground
                    font {
                        family: "ComicShannsMono Nerd Font"
                        pixelSize: ScalerService.s(16)
                    }
                }

                // Status indicator
                Text {
                    visible: folderModel.status === FolderListModel.Loading
                    text: lang?.wallpapers?.loading || "Đang tải..."
                    color: theme.primary.dim_foreground
                    font.pixelSize: ScalerService.s(14)
                    Layout.alignment: Qt.AlignCenter
                }

                // Wallpapers Grid
                Grid {
                    id: wallpapersGrid
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: ScalerService.s(10)
                    rowSpacing: ScalerService.s(10)

                    Repeater {
                        model: folderModel

                        delegate: Rectangle {
                            width: systemSettings.width / 4
                            height: systemSettings.width / 4
                            radius: ScalerService.s(12)
                            color: Qt.alpha(theme.button.background, 0.5)
                            border.color: theme.button.border
                            border.width: ScalerService.s(1)

                            Column {
                                anchors.fill: parent
                                anchors.margins: ScalerService.s(8)
                                spacing: ScalerService.s(8)

                                // Thumbnail
                                Rectangle {
                                    width: parent.width
                                    height: parent.height - ScalerService.s(70)
                                    radius: ScalerService.s(8)
                                    clip: true
                                    color: "transparent"

                                    Component.onCompleted: {
                                        if (isVideoFile(fileName)) {
                                            generateThumbnail(fileUrl);
                                        }
                                    }

                                    Image {
                                        id: thumbnailImage
                                        anchors.fill: parent
                                        source: isVideoFile(fileName) ? getThumbnailPath(fileUrl) : fileUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: true
                                        smooth: true
                                        mipmap: true

                                        onStatusChanged: {
                                            if (status === Image.Error && isVideoFile(fileName)) {
                                                generateThumbnail(fileUrl);
                                            }
                                        }
                                    }

                                    // Video indicator
                                    Rectangle {
                                        visible: isVideoFile(fileName)
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.margins: ScalerService.s(5)
                                        width: ScalerService.s(24)
                                        height: ScalerService.s(24)
                                        radius: ScalerService.s(12)
                                        color: theme.normal.magenta

                                        Text {
                                            text: "▶"
                                            color: theme.primary.background
                                            font.pixelSize: ScalerService.s(12)
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }
                                    }

                                    // Current Wallpaper Indicator
                                    Rectangle {
                                        visible: normalizePath(fileUrl) === systemSettings.currentWallpaper
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: ScalerService.s(5)
                                        width: ScalerService.s(24)
                                        height: ScalerService.s(24)
                                        radius: ScalerService.s(12)
                                        color: theme.normal.green

                                        Text {
                                            text: "✓"
                                            color: theme.primary.background
                                            font.pixelSize: ScalerService.s(12)
                                            font.bold: true
                                            anchors.centerIn: parent
                                        }
                                    }
                                }

                                // File Info & Actions
                                Column {
                                    width: parent.width
                                    spacing: ScalerService.s(6)

                                    Text {
                                        text: fileName
                                        color: theme.primary.foreground
                                        font.pixelSize: ScalerService.s(12)
                                        elide: Text.ElideMiddle
                                        width: parent.width
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: ScalerService.s(8)
                                        Text {
                                            text: Math.round(fileSize / 1024) + " KB"
                                            color: theme.primary.dim_foreground
                                            font.pixelSize: ScalerService.s(9)
                                        }
                                        Text {
                                            text: new Date(fileModified).toLocaleDateString(Qt.locale(), "dd/MM/yyyy")
                                            color: theme.primary.dim_foreground
                                            font.pixelSize: ScalerService.s(9)
                                        }
                                    }

                                    Row {
                                        width: parent.width
                                        spacing: ScalerService.s(6)

                                        // Set Wallpaper
                                        Rectangle {
                                            width: (parent.width - ScalerService.s(6)) / 2
                                            height: ScalerService.s(28)
                                            radius: ScalerService.s(6)
                                            color: normalizePath(fileUrl) === systemSettings.currentWallpaper ? theme.normal.green : theme.normal.blue

                                            Text {
                                                anchors.centerIn: parent
                                                text: normalizePath(fileUrl) === systemSettings.currentWallpaper ? (lang?.wallpapers?.already_set || "Đã đặt") : (lang?.wallpapers?.set_wallpaper || "Đặt nền")
                                                color: theme.primary.background
                                                font.pixelSize: ScalerService.s(10)
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    setWallpaper(fileUrl);
                                                }
                                            }
                                        }

                                        // Delete Button
                                        Rectangle {
                                            width: (parent.width - ScalerService.s(6)) / 2
                                            height: ScalerService.s(28)
                                            radius: ScalerService.s(6)
                                            color: theme.normal.red

                                            Text {
                                                anchors.centerIn: parent
                                                text: lang?.wallpapers?.delete || "Xóa"
                                                color: theme.primary.background
                                                font.pixelSize: ScalerService.s(10)
                                                font.bold: true
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: showDeleteDialog(fileName, fileUrl)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // No images message
                Text {
                    visible: folderModel.count === 0 && homePath && folderModel.status === FolderListModel.Ready
                    text: lang?.wallpapers?.no_images || "Không tìm thấy ảnh nào trong thư mục ~/Pictures/Wallpapers"
                    color: theme.primary.dim_foreground
                    font.pixelSize: ScalerService.s(14)
                    Layout.alignment: Qt.AlignCenter
                }

                // Loading message
                Text {
                    visible: !homePath
                    text: lang?.wallpapers?.loading_info || "Đang tải thông tin..."
                    color: theme.primary.dim_foreground
                    font.pixelSize: ScalerService.s(14)
                    Layout.alignment: Qt.AlignCenter
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // Delete dialog
    Rectangle {
        id: deleteDialog
        visible: false
        anchors.centerIn: parent
        width: ScalerService.s(300)
        height: ScalerService.s(160)
        radius: ScalerService.s(12)
        color: theme.primary.background
        border.color: theme.normal.red
        border.width: ScalerService.s(2)
        z: 1000

        property string fileNameToDelete: ""
        property string filePathToDelete: ""

        Column {
            anchors.fill: parent
            anchors.margins: ScalerService.s(20)
            spacing: ScalerService.s(15)

            Text {
                text: (lang?.wallpapers?.delete_confirm || "Xác nhận xóa") + "\n" + deleteDialog.fileNameToDelete
                color: theme.normal.red
                font.pixelSize: ScalerService.s(16)
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Row {
                spacing: ScalerService.s(15)
                anchors.horizontalCenter: parent.horizontalCenter

                // Cancel
                Rectangle {
                    width: ScalerService.s(100)
                    height: ScalerService.s(35)
                    radius: ScalerService.s(6)
                    color: theme.button.background
                    border.color: theme.button.border

                    Text {
                        anchors.centerIn: parent
                        text: lang?.wallpapers?.cancel || "Hủy"
                        color: theme.primary.foreground
                        font.pixelSize: ScalerService.s(14)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: deleteDialog.visible = false
                    }
                }

                // Confirm delete
                Rectangle {
                    width: ScalerService.s(100)
                    height: ScalerService.s(35)
                    radius: ScalerService.s(6)
                    color: theme.normal.red

                    Text {
                        anchors.centerIn: parent
                        text: lang?.wallpapers?.delete || "Xóa"
                        color: theme.primary.background
                        font.pixelSize: ScalerService.s(14)
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            deleteWallpaper(deleteDialog.filePathToDelete);
                            deleteDialog.visible = false;
                        }
                    }
                }
            }
        }
    }

    // Notification
    Rectangle {
        id: successNotification
        visible: false
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: ScalerService.s(20)
        width: ScalerService.s(250)
        height: ScalerService.s(50)
        radius: ScalerService.s(8)
        color: theme.normal.green
        z: 1001

        Row {
            anchors.centerIn: parent
            spacing: ScalerService.s(10)
            Text {
                text: "✓"
                color: theme.primary.background
                font.bold: true
                font.pixelSize: ScalerService.s(16)
            }
            Text {
                id: notificationText
                color: theme.primary.background
                text: ""
                font.bold: true
                font.pixelSize: ScalerService.s(16)
            }
        }

        Timer {
            id: notificationTimer
            interval: 3000
            onTriggered: successNotification.visible = false
        }
    }

    // ===== HÀM XỬ LÝ =====

    function setWallpaper(filePath) {
        Settings.wallpaper.shaders = Math.floor(Math.random() * 4);
        var cleanPath = normalizePath(filePath);

        if (Settings.wallpaper.setWallpaperOnAllMonitors) {
            for (var i = 0; i < Quickshell.screens.length; i++) {
                WallpaperService.changeWallpaper(cleanPath, Quickshell.screens[i].name);
            }
        } else {
            var screen = systemSettings.currentScreen;
            if (screen) {
                WallpaperService.changeWallpaper(cleanPath, screen.name);
            } else if (Quickshell.screens.length > 0) {
                WallpaperService.changeWallpaper(cleanPath, Quickshell.screens[0].name);
            }
        }

        showNotification(lang?.wallpapers?.success_set || "Đã đặt hình nền thành công!");
        systemSettings.currentWallpaper = cleanPath;
    }

    // Tạo thumbnail bằng lệnh ffmpeg nhẹ nhất
    function generateThumbnail(filePath) {
        if (!homePath || !thumbnailDir)
            return;

        var actualPath = normalizePath(filePath);
        var fileName = actualPath.split('/').pop();
        var thumbnailPath = thumbnailDir + "/" + fileName + ".jpg";

        // Lệnh ffmpeg tối ưu dung lượng và tốc độ
        var cmd = `mkdir -p "${thumbnailDir}" && test -f "${thumbnailPath}" || ffmpeg -y -i "${actualPath}" -vframes 1 -vf "scale=320:-1" -sws_flags fast_bilinear -q:v 10 "${thumbnailPath}" 2>/dev/null`;

        thumbnailProcess.command = ["sh", "-c", cmd];
        thumbnailProcess.running = true;
    }

    function isVideoFile(fileName) {
        if (!fileName)
            return false;
        var ext = fileName.toLowerCase().split('.').pop();
        return ["mp4", "webm", "mkv", "avi", "mov", "flv", "wmv", "m4v", "mpg", "mpeg"].indexOf(ext) !== -1;
    }

    function getThumbnailPath(filePath) {
        if (!homePath || !thumbnailDir)
            return "";
        var actualPath = normalizePath(filePath);
        var fileName = actualPath.split('/').pop();
        return "file://" + thumbnailDir + "/" + fileName + ".jpg";
    }

    // Xóa file gốc và xóa luôn thumbnail tương ứng nếu có
    function deleteWallpaper(filePath) {
        var actualPath = normalizePath(filePath);
        var fileName = actualPath.split('/').pop();
        var thumbnailPath = thumbnailDir + "/" + fileName + ".jpg";

        deleteProcess.command = ["sh", "-c", `rm -f "${actualPath}" "${thumbnailPath}"`];
        deleteProcess.running = true;
    }

    // Xóa các thumbnail cũ không còn tệp video gốc tương ứng
    function cleanupOldThumbnails() {
        if (!thumbnailDir || folderModel.count === 0)
            return;

        var validThumbnails = [];
        for (var i = 0; i < folderModel.count; i++) {
            var name = folderModel.get(i, "fileName");
            if (isVideoFile(name)) {
                validThumbnails.push(name + ".jpg");
            }
        }

        // Tạo chuỗi danh sách các file cần giữ lại để xử lý shell
        var keepList = validThumbnails.map(function (item) {
            return `-not -name "${item}"`;
        }).join(" ");

        var cleanupCmd = `if [ -d "${thumbnailDir}" ]; then find "${thumbnailDir}" -type f -name "*.jpg" ${keepList} -delete; fi`;

        cleanupProcess.command = ["sh", "-c", cleanupCmd];
        cleanupProcess.running = true;
    }

    function showDeleteDialog(fileName, filePath) {
        deleteDialog.fileNameToDelete = fileName;
        deleteDialog.filePathToDelete = filePath;
        deleteDialog.visible = true;
    }

    function showNotification(message) {
        notificationText.text = message;
        successNotification.visible = true;
        notificationTimer.start();
    }

    function isCurrentWallpaper(filePath) {
        if (!currentScreen)
            return false;
        var currentWallpaper = WallpaperService.getWallpaper(currentScreen.name);
        return normalizePath(filePath) === normalizePath(currentWallpaper);
    }

    Component.onCompleted: {
        var wallpaper = WallpaperService.getWallpaper(currentScreen.name);
        systemSettings.currentWallpaper = normalizePath(wallpaper);
    }
}
