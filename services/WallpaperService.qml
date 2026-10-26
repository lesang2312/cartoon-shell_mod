pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import qs.commons
import qs.utils
import qs.services

Singleton {
    id: root

    readonly property ListModel fillModeModel: ListModel {}
    readonly property string defaultDirectory: Settings.wallpaper.directory

    readonly property ListModel transitionsModel: ListModel {}

    property var wallpaperLists: ({})
    property int scanningCount: 0
    readonly property bool scanning: (scanningCount > 0)
    property var currentWallpapers: ({})
    property bool isInitialized: false

    // Thư mục cache thumbnail cố định
    readonly property string wallpaperThumbsDir: `${Directories.cache}/quickshell/wallpapers_thumbs`

    signal wallpaperChanged(string screenName, string path)
    signal wallpaperDirectoryChanged(string screenName, string directory)
    signal wallpaperListChanged(string screenName, int count)

    Connections {
        target: Settings.wallpaper

        function onDirectoryChanged() {
            root.refreshWallpapersList();
            if (!Settings.wallpaper.enableMultiMonitorDirectories) {
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    root.wallpaperDirectoryChanged(Quickshell.screens[i].name, root.defaultDirectory);
                }
            } else {
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    const screenName = Quickshell.screens[i].name;
                    const monitor = root.getMonitorConfig(screenName);
                    if (!monitor || !monitor.directory) {
                        root.wallpaperDirectoryChanged(screenName, root.defaultDirectory);
                    }
                }
            }
        }

        function onEnableMultiMonitorDirectoriesChanged() {
            root.refreshWallpapersList();
            for (let i = 0; i < Quickshell.screens.length; i++) {
                var screenName = Quickshell.screens[i].name;
                root.wallpaperDirectoryChanged(screenName, root.getMonitorDirectory(screenName));
            }
        }

        function onRecursiveSearchChanged() {
            root.refreshWallpapersList();
        }
    }

    // Tự động đặt hình nền ở đầu danh sách trong lần khởi động đầu tiên
    // (khi chưa có hình nền nào được lưu cho màn hình đó).
    property var _autoWallpaperDone: ({})

    Connections {
        target: root

        function onWallpaperListChanged(screenName, count) {
            root.autoSetFirstWallpaper(screenName);
        }
    }

    function autoSetFirstWallpaper(screenName) {
        if (!isInitialized || _autoWallpaperDone[screenName])
            return;

        // Đã có hình nền (đã lưu hoặc mặc định) -> không can thiệp
        if (getWallpaper(screenName))
            return;

        var list = getWallpapersList(screenName);
        if (!list || list.length === 0)
            return;

        // Sắp xếp giống giao diện chọn hình nền (theo tên, không phân biệt hoa thường)
        var sorted = list.slice().sort(function (a, b) {
            var x = a.split('/').pop().toLowerCase();
            var y = b.split('/').pop().toLowerCase();
            return x < y ? -1 : (x > y ? 1 : 0);
        });

        _autoWallpaperDone[screenName] = true;
        console.log("[WallpaperService] First boot: auto-set wallpaper", sorted[0], "on", screenName);
        _setWallpaper(screenName, sorted[0]);
    }

    function init() {
        // Tạo thư mục cache nếu chưa tồn tại
        var mkdirCmd = `mkdir -p "${root.wallpaperThumbsDir}"`;
        var mkdirProc = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            Process {
                command: ["bash", "-c", "${mkdirCmd.replace(/"/g, '\\"')}"]
                onExited: destroy()
            }
        `, root, "MkdirCacheProc");
        mkdirProc.running = true;

        currentWallpapers = ({});
        const monitors = Settings.wallpaper.monitors || [];
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name && monitors[i].wallpaper) {
                currentWallpapers[monitors[i].name] = monitors[i].wallpaper;
            }
        }

        isInitialized = true;
        Qt.callLater(refreshWallpapersList);

        // Đồng bộ hình nền hiện tại sang màn hình đăng nhập mỗi lần shell khởi động
        // (bắt được cả hình nền đã đặt từ trước khi có tính năng này).
        Qt.callLater(function () {
            if (Quickshell.screens.length > 0)
                root.syncSddmWallpaper(root.getWallpaper(Quickshell.screens[0].name));
        });
    }

    function getFillModeUniform() {
        for (let i = 0; i < fillModeModel.count; i++) {
            const mode = fillModeModel.get(i);
            if (mode.key === Settings.wallpaper.fillMode) {
                return mode.uniform;
            }
        }
        return 1.0;
    }

    function getMonitorConfig(screenName) {
        var monitors = Settings.wallpaper.monitors;
        if (monitors !== undefined) {
            for (let i = 0; i < monitors.length; i++) {
                if (monitors[i].name === screenName) {
                    return monitors[i];
                }
            }
        }
    }

    function getMonitorDirectory(screenName) {
        if (!Settings.wallpaper.enableMultiMonitorDirectories) {
            return root.defaultDirectory;
        }

        var monitor = getMonitorConfig(screenName);
        if (monitor && monitor.directory !== undefined) {
            return FileUtils.trimFileProtocol(monitor.directory);
        }

        return root.defaultDirectory;
    }

    function setMonitorDirectory(screenName, directory) {
        var monitors = Settings.wallpaper.monitors || [];
        var found = false;

        var newMonitors = monitors.map(function (monitor) {
            if (monitor.name === screenName) {
                found = true;
                return {
                    "name": screenName,
                    "directory": directory,
                    "wallpaper": monitor.wallpaper || ""
                };
            }
            return monitor;
        });

        if (!found) {
            newMonitors.push({
                "name": screenName,
                "directory": directory,
                "wallpaper": ""
            });
        }

        Settings.wallpaper.monitors = newMonitors.slice();
        root.wallpaperDirectoryChanged(screenName, FileUtils.trimFileProtocol(directory));
    }

    function getWallpaper(screenName) {
        return currentWallpapers[screenName] || Settings.wallpaper.defaultWallpaper;
    }

    // Lấy đường dẫn thumbnail trong cache
    function getCacheThumbnailPath(wallpaperPath) {
        if (!wallpaperPath || wallpaperPath === "")
            return "";

        var filename = wallpaperPath.split('/').pop();
        var nameWithoutExt = filename.substring(0, filename.lastIndexOf('.')) || filename;
        return root.wallpaperThumbsDir + "/" + nameWithoutExt + ".png";
    }

    function isVideoFile(path) {
        if (!path)
            return false;
        const videoExtensions = ["mp4", "webm", "mkv", "avi", "mov", "flv", "wmv", "m4v", "mpg", "mpeg"];
        const pathStr = path.toString();
        const extension = pathStr.split('.').pop().toLowerCase();
        return videoExtensions.includes(extension);
    }

    // Ảnh nền cho kính: lấy khung hình giữa video (khung đầu thường đen) nên tách riêng với thumbnail thường.
    function getGlassThumbnailPath(videoPath) {
        if (!videoPath)
            return "";
        var filename = videoPath.split('/').pop();
        var base = filename.substring(0, filename.lastIndexOf('.')) || filename;
        // Gắn mã băm của ĐƯỜNG DẪN ĐẦY ĐỦ: hai video khác thư mục nhưng trùng tên file
        // trước đây dùng chung một ảnh nền kính cũ (kính hiện sai hình nền, viền màu lạ).
        var str = String(videoPath);
        var h = 5381;
        for (var i = 0; i < str.length; i++)
            h = ((h * 33) ^ str.charCodeAt(i)) >>> 0;
        return root.wallpaperThumbsDir + "/" + base + "_" + h.toString(16) + "_glass.jpg";
    }

    property var _glassJobs: ({})
    function ensureGlassThumbnail(videoPath, callback) {
        if (!videoPath)
            return;
        var job = _glassJobs[videoPath];
        if (job === "failed")
            return;
        if (job && job !== "done") {
            job.push(callback);
            return;
        }
        if (job === "done") {
            if (callback) callback(getGlassThumbnailPath(videoPath));
            return;
        }
        _glassJobs[videoPath] = [callback];
        var out = getGlassThumbnailPath(videoPath);
        // Thử lấy ở giây 3 (nếu video ngắn hơn thì ffmpeg không ra ảnh -> lùi về khung đầu).
        var cmd = `mkdir -p "${root.wallpaperThumbsDir}" && (ffmpeg -y -ss 3 -i "${videoPath}" -frames:v 1 -vf "scale=1280:-1" -q:v 3 "${out}" 2>/dev/null; [ -s "${out}" ] || ffmpeg -y -i "${videoPath}" -frames:v 1 -vf "scale=1280:-1" -q:v 3 "${out}" 2>/dev/null; [ -s "${out}" ])`;
        var proc = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            Process {
                property string videoPath: ""
                property string outPath: ""
                onExited: function(code) {
                    var waiting = parent._glassJobs[videoPath] || [];
                    if (code === 0) {
                        parent._glassJobs[videoPath] = "done";
                        for (var i = 0; i < waiting.length; i++) if (waiting[i]) waiting[i](outPath);
                    } else {
                        parent._glassJobs[videoPath] = "failed";
                        console.warn("[LiquidGlass] ffmpeg khong tao duoc anh nen cho", videoPath);
                    }
                    destroy();
                }
            }
        `, root, "GlassThumb");
        proc.videoPath = videoPath;
        proc.outPath = out;
        proc.command = ["bash", "-c", cmd];
        proc.running = true;
    }

    // Đảm bảo thumbnail của video tồn tại (mỗi video chỉ tạo 1 lần dù nhiều panel cùng hỏi).
    property var _thumbJobs: ({})
    function ensureVideoThumbnail(videoPath, callback) {
        if (!videoPath)
            return;
        var job = _thumbJobs[videoPath];
        if (job === "done") {
            if (callback) callback(getCacheThumbnailPath(videoPath));
            return;
        }
        if (job === "failed")
            return;
        if (job) {
            job.push(callback);
            return;
        }
        _thumbJobs[videoPath] = [callback];
        generateVideoThumbnail(videoPath, function (thumb) {
            var waiting = _thumbJobs[videoPath] || [];
            _thumbJobs[videoPath] = thumb ? "done" : "failed";
            if (!thumb)
                console.warn("[LiquidGlass] ffmpeg khong tao duoc thumbnail cho", videoPath, "- kiem tra da cai ffmpeg chua");
            for (var i = 0; i < waiting.length; i++)
                if (thumb && waiting[i]) waiting[i](thumb);
        });
    }

    // Tạo thumbnail trong thư mục cache với chất lượng thấp
    function generateVideoThumbnail(videoPath, callback) {
        if (!videoPath) {
            if (callback)
                callback("");
            return;
        }

        var thumbPath = getCacheThumbnailPath(videoPath);

        // Đảm bảo thư mục cache tồn tại
        var mkdirCmd = `mkdir -p "${root.wallpaperThumbsDir}"`;
        var ffmpegCmd = `ffmpeg -y -i "${videoPath}" -vframes 1 -vf "scale=320:-1" -sws_flags fast_bilinear -q:v 10 "${thumbPath}" 2>/dev/null`;
        var fullCmd = `${mkdirCmd} && ${ffmpegCmd}`;

        try {
            var extractProcess = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io
                Process {
                    id: extractProc
                    property var callbackFn: null
                    property string thumbPath: ""

                    command: ["bash", "-c", "${fullCmd.replace(/"/g, '\\"')}"]
                    onExited: function(exitCode) {
                        if (exitCode === 0) {
                            console.log("Thumbnail created in cache:", thumbPath);
                            if (callbackFn) callbackFn(thumbPath);
                        } else {
                            console.error("Failed to create thumbnail:", stderr.text);
                            if (callbackFn) callbackFn("");
                        }
                        extractProc.destroy();
                    }
                    stdout: StdioCollector {}
                    stderr: StdioCollector {}
                }
            `, root, "GenerateThumbnail");

            extractProcess.callbackFn = callback;
            extractProcess.thumbPath = thumbPath;
            extractProcess.running = true;
        } catch (e) {
            console.error("Error generating thumbnail:", e);
            if (callback)
                callback("");
        }
    }

    // ---- Đồng bộ hình nền sang màn hình đăng nhập SDDM ----
    // Theme "cartoon" đọc file "wallpaper" trong thư mục theme; installer đã cấp quyền ghi cho user
    // nên không cần sudo. Nếu thư mục không tồn tại / không ghi được thì bỏ qua âm thầm.
    readonly property string sddmThemeDir: "/usr/share/sddm/themes/cartoon"

    function syncSddmWallpaper(path) {
        if (!path || !Settings.wallpaper.syncSddm)
            return;
        if (isVideoFile(path)) {
            // Video: dùng khung hình giữa video (1280px) làm ảnh nền đăng nhập
            ensureGlassThumbnail(path, function (thumb) {
                if (thumb)
                    root._copyToSddm(thumb);
            });
        } else {
            root._copyToSddm(path);
        }
    }

    function _copyToSddm(src) {
        var dir = root.sddmThemeDir;
        var cmd = `[ -d "${dir}" ] && [ -w "${dir}" ] && { cmp -s -- "$1" "${dir}/wallpaper" || { cp -f -- "$1" "${dir}/wallpaper.tmp" && chmod 644 "${dir}/wallpaper.tmp" && mv -f "${dir}/wallpaper.tmp" "${dir}/wallpaper"; }; }`;
        Quickshell.execDetached(["bash", "-c", cmd, "_", FileUtils.trimFileProtocol(src)]);
    }

    function changeWallpaper(path, screenName) {
        if (screenName !== undefined) {
            _setWallpaper(screenName, path);
        } else {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                _setWallpaper(Quickshell.screens[i].name, path);
            }
        }
    }

    function _setWallpaper(screenName, path) {
        if (!path)
            return;
        var oldPath = currentWallpapers[screenName] || "";
        if (oldPath === path)
            return;
        currentWallpapers[screenName] = path;

        var monitors = Settings.wallpaper.monitors || [];
        var found = false;

        var newMonitors = monitors.map(function (monitor) {
            if (monitor.name === screenName) {
                found = true;
                return {
                    "name": screenName,
                    "directory": FileUtils.trimFileProtocol(monitor.directory) || getMonitorDirectory(screenName),
                    "wallpaper": path
                };
            }
            return monitor;
        });

        if (!found) {
            newMonitors.push({
                "name": screenName,
                "directory": getMonitorDirectory(screenName),
                "wallpaper": path
            });
        }

        Settings.wallpaper.monitors = newMonitors.slice();
        root.wallpaperChanged(screenName, path);

        // Chỉ màn hình đầu tiên quyết định hình nền màn hình đăng nhập
        if (Quickshell.screens.length === 0 || screenName === Quickshell.screens[0].name)
            syncSddmWallpaper(path);

        // Xử lý Matugen - tạo thumbnail cho video
        if (Settings.appearance && Settings.appearance.theme === "matugen") {
            const isVideo = isVideoFile(path);

            if (isVideo) {
                // Tạo thumbnail trong cache và trigger Matugen với thumbnail path
                generateVideoThumbnail(path, function (thumbnailPath) {
                    if (thumbnailPath && thumbnailPath !== "") {
                        console.log("Video thumbnail ready for matugen:", thumbnailPath);
                        if (typeof ThemeService !== 'undefined' && ThemeService.triggerMatugenOnWallpaperChange) {
                            ThemeService.triggerMatugenOnWallpaperChange(thumbnailPath);
                        }
                    } else {
                        console.warn("Matugen skipped: Could not generate thumbnail from video:", path);
                        // Fallback: sử dụng video path nhưng matugen sẽ báo lỗi
                        if (typeof ThemeService !== 'undefined' && ThemeService.triggerMatugenOnWallpaperChange) {
                            ThemeService.triggerMatugenOnWallpaperChange(path);
                        }
                    }
                });
            } else {
                Qt.callLater(function () {
                    if (typeof ThemeService !== 'undefined' && ThemeService.triggerMatugenOnWallpaperChange) {
                        ThemeService.triggerMatugenOnWallpaperChange(path);
                    }
                });
            }
        }
    }

    function restartRandomWallpaperTimer() {
        if (Settings.wallpaper.isRandom) {
            randomWallpaperTimer.restart();
        }
    }

    function getWallpapersList(screenName) {
        if (screenName && wallpaperLists[screenName]) {
            return wallpaperLists[screenName];
        }
        return [];
    }

    function refreshWallpapersList() {
        scanningCount = 0;

        if (Settings.wallpaper.recursiveSearch) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                var screenName = Quickshell.screens[i].name;
                var directory = getMonitorDirectory(screenName);
                scanDirectoryRecursive(screenName, directory);
            }
        } else {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                var screenName = Quickshell.screens[i].name;
                var directory = getMonitorDirectory(screenName);
                root.wallpaperDirectoryChanged(screenName, directory);
            }
        }
    }

    property var recursiveProcesses: ({})

    function scanDirectoryRecursive(screenName, directory) {
        if (!directory) {
            wallpaperLists[screenName] = [];
            wallpaperListChanged(screenName, 0);
            return;
        }

        if (recursiveProcesses[screenName]) {
            recursiveProcesses[screenName].running = false;
            recursiveProcesses[screenName].destroy();
            delete recursiveProcesses[screenName];
            if (scanningCount > 0)
                scanningCount--;
        }

        scanningCount++;

        try {
            var processObject = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io
                Process {
                    id: process
                    stdout: StdioCollector {}
                    stderr: StdioCollector {}
                }
            `, root, "RecursiveScan_" + screenName);

            processObject.command = ["find", directory, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.gif", "-o", "-iname", "*.pnm", "-o", "-iname", "*.bmp", "-o", "-iname", "*.mp4", "-o", "-iname", "*.webm", "-o", "-iname", "*.mkv", "-o", "-iname", "*.avi", "-o", "-iname", "*.mov", "-o", "-iname", "*.flv", "-o", "-iname", "*.wmv", "-o", "-iname", "*.m4v", "-o", "-iname", "*.mpg", "-o", "-iname", "*.mpeg", ")"];

            recursiveProcesses[screenName] = processObject;

            processObject.exited.connect(function (exitCode) {
                if (scanningCount > 0)
                    scanningCount--;

                if (exitCode === 0 && processObject.stdout) {
                    var lines = processObject.stdout.text.split("\n");
                    var files = [];
                    for (let i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line !== "")
                            files.push(line);
                    }

                    files.sort();
                    wallpaperLists[screenName] = files;
                    wallpaperListChanged(screenName, files.length);
                } else {
                    wallpaperLists[screenName] = [];
                    wallpaperListChanged(screenName, 0);
                }

                delete recursiveProcesses[screenName];
                processObject.destroy();
            });

            processObject.running = true;
        } catch (e) {
            console.error("Error in scanDirectoryRecursive:", e);
            if (scanningCount > 0)
                scanningCount--;
        }
    }

    Instantiator {
        id: wallpaperScanners
        model: Quickshell.screens

        delegate: Item {
            id: scannerItem
            property string screenName: modelData.name
            property string targetDirectory: root.getMonitorDirectory(screenName)
            property var folderModel: null
            property bool isLoading: false

            function createModel() {
                if (folderModel) {
                    if (isLoading) {
                        isLoading = false;
                        if (root.scanningCount > 0)
                            root.scanningCount--;
                    }
                    folderModel.destroy();
                    folderModel = null;
                }

                var component = Qt.createQmlObject(`
                    import QtQuick
                    import Qt.labs.folderlistmodel
                    FolderListModel {
                        id: model
                        folder: "file://${targetDirectory}"
                        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.pnm", "*.bmp",
                                      "*.mp4", "*.webm", "*.mkv", "*.avi", "*.mov", "*.flv",
                                      "*.wmv", "*.m4v", "*.mpg", "*.mpeg"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }
                `, scannerItem, "FolderModel_" + screenName);

                component.statusChanged.connect(function () {
                    if (component.status === FolderListModel.Null) {
                        root.wallpaperLists[screenName] = [];
                        root.wallpaperListChanged(screenName, 0);
                    } else if (component.status === FolderListModel.Loading) {
                        if (!isLoading) {
                            isLoading = true;
                            root.scanningCount++;
                        }
                        root.wallpaperLists[screenName] = [];
                    } else if (component.status === FolderListModel.Ready) {
                        if (isLoading) {
                            isLoading = false;
                            if (root.scanningCount > 0)
                                root.scanningCount--;
                        }
                        var files = [];
                        for (let i = 0; i < component.count; i++) {
                            var filepath = targetDirectory + "/" + component.get(i, "fileName");
                            files.push(filepath);
                        }
                        root.wallpaperLists[screenName] = files;
                        root.wallpaperListChanged(screenName, files.length);
                    }
                });

                folderModel = component;
            }

            Connections {
                target: root
                function onWallpaperDirectoryChanged(screen, directory) {
                    if (screen === scannerItem.screenName) {
                        scannerItem.targetDirectory = directory;
                        scannerItem.createModel();
                    }
                }
            }

            Component.onCompleted: {
                createModel();
            }

            Component.onDestruction: {
                if (isLoading && root.scanningCount > 0) {
                    root.scanningCount--;
                }
                if (folderModel) {
                    folderModel.destroy();
                }
            }
        }
    }
}
