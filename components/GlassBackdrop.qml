import QtQuick
import Quickshell
import qs.services
import "glassNesting.js" as Nesting

// Nền kính của một cửa sổ/panel.
//  * Dựng lại hình nền (wallpaper) đúng vị trí phía sau panel trên màn hình.
//  * Vẽ chính panel bằng LiquidGlass.
//  * Cung cấp `texture` (đã có kính) cho các GlassFill lồng bên trong để chúng khúc xạ tiếp.
// Khi GlassService.enabled = false hoặc chưa có hình nền, `active` = false và item này ẩn hoàn toàn,
// panel quay về nền màu đặc ban đầu.
Item {
    id: root

    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius

    property real tint: GlassService.panelTint
    property real frostAmount: GlassService.panelFrost
    property real rim: GlassService.rimStrength
    property color tintColor: GlassService.base
    property real bezelSize: Math.max(5, Math.min(GlassService.bezelMax, Math.min(width, height) * GlassService.bezelRatio))

    // Sample extra wallpaper outside the panel. The visible shader still draws only the panel;
    // the margin exists so rays can pull real pixels across the edge instead of clamping.
    readonly property real refractionPad: Math.max(12, Math.min(44, bezelSize * 1.25))
    // Shader quickshell kẹp uv theo tỉ lệ của chính panel (không dùng viền đệm), nên bỏ pad khi dùng nó.
    readonly property real sourcePad: (GlassService.customShader && !GlassService.quickshellShader) ? refractionPad : 0
    readonly property real sourceWidth: Math.max(1, width + sourcePad * 2)
    readonly property real sourceHeight: Math.max(1, height + sourcePad * 2)

    readonly property bool isGlassBackdrop: true
    readonly property Item texture: glassTexture
    property int consumers: 0
    property int frame: 0
    property int wallpaperRetryCount: 0
    property int glassErrRetries: 0
    property string ownerWidgetId: ""
    property int nestLevel: 0
    readonly property real nest: Math.min(1, nestLevel * 0.5)
    // Mức `nest` đưa cho shader: giảm bớt để panel lồng nhau vẫn khúc xạ rõ.
    readonly property real shaderNest: nest * GlassService.nestDamping

    property bool standalone: false
    property bool surfaceEnabled: true

    Component.onCompleted: {
        inheritedOwner = findInheritedOwner();
        ownerWidgetId = findOwnerWidgetId();
        nestLevel = (standalone || inheritedOwner !== null) ? 0 : Nesting.nestLevel(root, null, true);
        updateWallpaper();
    }

    // ---- Màn hình / cửa sổ chứa ----------------------------------------------------------
    property var screenOverride: null
    property Item inheritedOwner: null
    readonly property var inheritedScreen: inheritedOwner ? inheritedOwner.glassScreen : null

    function findInheritedOwner() {
        let e = root.parent;
        let d = 0;
        while (e && d < 64) {
            if (e.glassScreen !== undefined)
                return e;
            e = e.parent;
            d++;
        }
        return null;
    }

    function findOwnerWidgetId() {
        let e = root.parent;
        let d = 0;
        while (e && d < 96) {
            if (e.widgetId !== undefined && String(e.widgetId) !== "")
                return String(e.widgetId);
            e = e.parent;
            d++;
        }
        return "";
    }

    onParentChanged: {
        inheritedOwner = findInheritedOwner();
        ownerWidgetId = findOwnerWidgetId();
        refreshGeometry();
    }
    readonly property var effectiveScreenOverride: screenOverride ? screenOverride : inheritedScreen

    readonly property var hostWindow: QsWindow.window
    readonly property var hostScreen: effectiveScreenOverride ? effectiveScreenOverride : (hostWindow ? hostWindow.screen : null)
    readonly property string screenName: hostScreen && hostScreen.name ? hostScreen.name : ""
    readonly property bool parentVisible: parent ? parent.visible : true

    // Chỉ dựng kính khi scene graph chạy trên GPU (OpenGL/Vulkan/...). Với renderer phần mềm
    // (CPU) shader không chạy được và sẽ ngốn CPU, nên quay về nền đặc.
    readonly property bool gpuOk: GlassService.gpuUsable && GraphicsInfo.api !== GraphicsInfo.Software && GraphicsInfo.api !== GraphicsInfo.Null
    readonly property bool wanted: surfaceEnabled && parentVisible && GlassService.enabled && gpuOk && width > 0 && height > 0 && hostScreen !== null && (hostWindow ? hostWindow.visible : true)
    readonly property bool active: wanted && wall.status === Image.Ready

    // ---- Hình nền ------------------------------------------------------------------------
    property string wallSource: ""
    property string videoPath: ""

    function toUrl(path) {
        if (!path)
            return "";
        const p = String(path);
        return p.indexOf("://") >= 0 ? p : "file://" + p;
    }

    function updateWallpaper() {
        if (!screenName)
            return;
        let path = "";
        try {
            path = WallpaperService.getWallpaper(screenName) || "";
        } catch (e) {
            path = "";
        }
        // Với video: dùng ảnh thumbnail trong cache làm nền kính.
        if (path && ThemeService.isVideoFile(path)) {
            videoPath = path;
            // Chỉ nạp ảnh khi file thumbnail chắc chắn tồn tại. Nạp file chưa có làm Qt nhớ lỗi trong cache
            // và các panel tạo sớm (thanh bar) bị kẹt ở trạng thái không có kính.
            const vp = path;
            WallpaperService.ensureGlassThumbnail(vp, function (thumb) {
                if (root.videoPath !== vp)
                    return;
                const u = root.toUrl(thumb);
                if (u !== root.wallSource) {
                    root.wallSource = u;
                    root.wallpaperRetryCount = 0;
                }
            });
            return;
        } else {
            videoPath = "";
        }
        const url = toUrl(path);
        if (url !== wallSource) {
            wallSource = url;
            if (url !== "")
                wallpaperRetryCount = 0;
        }
    }

    onScreenNameChanged: {
        wallpaperRetryCount = 0;
        updateWallpaper();
        refreshGeometry();
    }
    onHostScreenChanged: {
        updateWallpaper();
        refreshGeometry();
    }
    onScreenWidthChanged: refreshGeometry()
    onScreenHeightChanged: refreshGeometry()

    // Retry briefly while the wallpaper service initializes. Later changes are handled
    // by WallpaperService signals, so a missing path cannot leave a permanent retry timer.
    Timer {
        interval: 700
        repeat: true
        running: root.wanted && root.wallSource === "" && root.wallpaperRetryCount < 12
        onTriggered: {
            root.wallpaperRetryCount++;
            root.updateWallpaper();
        }
    }
    Connections {
        target: WallpaperService
        function onIsInitializedChanged() { root.updateWallpaper(); }
    }

    Connections {
        target: WallpaperService
        function onWallpaperChanged(name, path) {
            if (name === root.screenName)
                root.updateWallpaper();
        }
    }

    readonly property real screenWidth: hostScreen ? hostScreen.width : 1
    readonly property real screenHeight: hostScreen ? hostScreen.height : 1
    readonly property size textureSize: Qt.size(
        Math.max(1, Math.round(screenWidth * GlassService.textureScale)),
        Math.max(1, Math.round(screenHeight * GlassService.textureScale))
    )

    // ---- Hình học: vị trí màn hình so với item này ---------------------------------------
    property real imageX: 0
    property real imageY: 0
    property real imageScale: 1
    property real imageRotation: 0
    property rect validRect: Qt.rect(0, 0, 1, 1)
    property var geoSig: [NaN, 0, 0, 0, 0, 0, 0, 0, -1]

    function refreshGeometry() {
        const w = root.hostWindow;
        const scr = root.hostScreen;
        if (!scr)
            return;
        let wx = 0;
        let wy = 0;
        if (w && w.anchors && !root.effectiveScreenOverride) {
            const a = w.anchors;
            const m = w.margins;
            if (a.left)
                wx = m.left;
            else if (a.right)
                wx = scr.width - w.width - m.right;
            else
                wx = (scr.width - w.width) / 2;
            if (a.top)
                wy = m.top;
            else if (a.bottom)
                wy = scr.height - w.height - m.bottom;
            else
                wy = (scr.height - w.height) / 2;
        }
        const p0 = root.mapFromItem(null, -wx, -wy);
        const px = root.mapFromItem(null, 1 - wx, -wy);
        const gs = root.geoSig;
        if (p0.x === gs[0] && p0.y === gs[1] && px.x === gs[2] && px.y === gs[3]
                && scr.width === gs[4] && scr.height === gs[5] && root.width === gs[6]
                && root.height === gs[7] && root.sourcePad === gs[8])
            return;
        gs[0] = p0.x;
        gs[1] = p0.y;
        gs[2] = px.x;
        gs[3] = px.y;
        gs[4] = scr.width;
        gs[5] = scr.height;
        gs[6] = root.width;
        gs[7] = root.height;
        gs[8] = root.sourcePad;
        const dx = px.x - p0.x;
        const dy = px.y - p0.y;
        const len = Math.sqrt(dx * dx + dy * dy);
        if (!isFinite(len) || len <= 0)
            return;
        root.imageX = p0.x;
        root.imageY = p0.y;
        root.imageScale = len;
        root.imageRotation = Math.atan2(dy, dx) * 180 / Math.PI;
        const p1 = root.mapFromItem(null, scr.width - wx, scr.height - wy);
        // validRect now describes the complete padded wallpaper texture, not just the card.
        // The padded area maps back to the same screen-space pixels around the card.
        const pad = root.sourcePad;
        const iw = root.sourceWidth;
        const ih = root.sourceHeight;
        const x0 = Math.max(0, Math.min(1, (Math.min(p0.x, p1.x) + pad) / iw));
        const y0 = Math.max(0, Math.min(1, (Math.min(p0.y, p1.y) + pad) / ih));
        const x1 = Math.max(x0, Math.min(1, (Math.max(p0.x, p1.x) + pad) / iw));
        const y1 = Math.max(y0, Math.min(1, (Math.max(p0.y, p1.y) + pad) / ih));
        if (x0 !== root.validRect.x || y0 !== root.validRect.y || x1 - x0 !== root.validRect.width || y1 - y0 !== root.validRect.height)
            root.validRect = Qt.rect(x0, y0, x1 - x0, y1 - y0);
    }

    // Do not run a per-frame geometry scan for every static glass card.
    // Nested GlassFill surfaces still need frame tracking, and layout edit mode
    // needs it while widgets are being dragged. All other movement is handled
    // by the geometry/window change signals below.
    // No continuous frame loop for static glass. Geometry changes are handled by
    // x/y/size/window signals; only an active drag needs per-frame sampling.
    FrameAnimation {
        // Only the backdrop inside the widget being dragged runs per-frame tracking.
        running: root.wanted && WidgetLayoutService.draggingWidget
                 && root.ownerWidgetId !== ""
                 && root.ownerWidgetId === WidgetLayoutService.draggingWidgetId
        onTriggered: {
            root.refreshGeometry();
            if (root.consumers > 0)
                root.frame++;
        }
    }

    onWantedChanged: {
        if (wanted) {
            updateWallpaper();
            refreshGeometry();
        }
    }

    Connections {
        target: root.hostWindow
        ignoreUnknownSignals: true
        function onXChanged() { root.refreshGeometry(); }
        function onYChanged() { root.refreshGeometry(); }
        function onWidthChanged() { root.refreshGeometry(); }
        function onHeightChanged() { root.refreshGeometry(); }
    }

    // ---- Cập nhật texture khi có thay đổi --------------------------------------------------
    function refreshTexture() {
        if (root.active && root.consumers > 0)
            glassTexture.scheduleUpdate();
    }

    onImageXChanged: refreshTexture()
    onImageYChanged: refreshTexture()
    onImageScaleChanged: refreshTexture()
    onImageRotationChanged: refreshTexture()
    onXChanged: { refreshGeometry(); refreshTexture(); }
    onYChanged: { refreshGeometry(); refreshTexture(); }
    onWidthChanged: { refreshGeometry(); refreshTexture(); }
    onHeightChanged: { refreshGeometry(); refreshTexture(); }
    onConsumersChanged: refreshTexture()
    onActiveChanged: refreshTexture()
    onTintChanged: refreshTexture()
    onFrostAmountChanged: refreshTexture()
    onTintColorChanged: refreshTexture()
    onValidRectChanged: refreshTexture()

    visible: active
    clip: false

    // Lớp hình nền (nguồn cho shader)
    Item {
        id: content
        x: -root.sourcePad
        y: -root.sourcePad
        width: root.sourceWidth
        height: root.sourceHeight
        visible: false
        layer.enabled: root.active
        layer.mipmap: true
        layer.smooth: true

        Image {
            id: wall
            x: root.imageX + root.sourcePad
            y: root.imageY + root.sourcePad
            width: root.screenWidth
            height: root.screenHeight
            scale: root.imageScale
            rotation: root.imageRotation
            transformOrigin: Item.TopLeft
            source: root.wanted ? root.wallSource : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            smooth: true
            sourceSize: root.textureSize
            onStatusChanged: {
                root.refreshTexture();
                // Thumbnail của video chưa có -> tạo bằng ffmpeg rồi nạp lại.
                if (status === Image.Error && root.videoPath !== "" && root.glassErrRetries++ < 3) {
                    const vp = root.videoPath;
                    WallpaperService.ensureGlassThumbnail(vp, function (thumb) {
                        if (root.videoPath === vp) {
                            root.wallSource = "";
                            root.updateWallpaper();
                        }
                    });
                }
            }
        }
    }

    // Chính panel được vẽ bằng kính
    Item {
        id: rendered
        anchors.fill: parent

        GlassFallback {
            anchors.fill: parent
            visible: root.active && !GlassService.customShader
            // sourcePad is zero in fallback mode, so its source remains panel-sized.
            src: root.active ? content : null
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            bezel: root.bezelSize
            nest: root.nest
        }

        LiquidGlass {
            id: glassEffect
            anchors.fill: parent
            visible: root.active && GlassService.customShader
            src: root.active ? content : null
            // Map this panel to the centre of the padded texture. Offsets can now sample
            // genuine wallpaper outside all four edges, which creates visible lens refraction.
            sourceRect: Qt.rect(
                root.sourcePad / root.sourceWidth,
                root.sourcePad / root.sourceHeight,
                root.width / root.sourceWidth,
                root.height / root.sourceHeight
            )
            topLeftRadius: root.topLeftRadius
            topRightRadius: root.topRightRadius
            bottomLeftRadius: root.bottomLeftRadius
            bottomRightRadius: root.bottomRightRadius
            tintColor: root.tintColor
            tintAmount: root.tint * (1 - 0.5 * root.nest)
            frost: root.frostAmount * (1 - 0.5 * root.nest)
            rim: root.rim * (1 - 0.35 * root.nest)
            nest: root.shaderNest
            bezel: root.bezelSize
            thickness: root.bezelSize * GlassService.thicknessScale
            ior: GlassService.ior
            dispersion: GlassService.dispersion
            saturation: GlassService.saturation
            validRect: root.validRect
            unpremul: 1
            // Giữ hiệu ứng ở phần ruột kể cả với backdrop lồng sâu; chỉ dùng mức
            // trong suốt toàn cục thay vì tự ép mọi panel lồng thành kính trong rỗng.
            clear: GlassService.transparency
            cursorPos: Qt.point(root.cursorX, root.cursorY)
            hover: root.hoverAmount
        }
    }

    // Texture (đã có kính) cho GlassFill lồng bên trong
    ShaderEffectSource {
        id: glassTexture
        anchors.fill: parent
        // Kính trong suốt thì `rendered` có alpha = 0 ở ruột (premultiplied -> đen). GlassFill lồng bên trong
        // lấy mẫu texture này nên viền của nó ra màu đen. Khi đó đưa cho chúng lớp hình nền đặc (`content`).
        sourceItem: root.active ? ((GlassService.quickshellShader && GlassService.transparency > 0.5) ? content : rendered) : null
        live: false
        mipmap: true
        visible: false
        smooth: true
        format: ShaderEffectSource.RGBA8
    }

    // ---- Con trỏ ---------------------------------------------------------------------------
    HoverHandler {
        id: pointer
        enabled: root.active
    }

    property real hoverAmount: pointer.hovered ? 1.0 : 0.0
    Behavior on hoverAmount {
        NumberAnimation {
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    property real cursorX: width / 2
    property real cursorY: height / 2
    onCursorXChanged: { frame++; refreshTexture(); }
    onCursorYChanged: { frame++; refreshTexture(); }
    onHoverAmountChanged: { frame++; refreshTexture(); }
    Behavior on cursorX {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }
    Behavior on cursorY {
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    Connections {
        target: pointer
        function onPointChanged() {
            if (pointer.hovered) {
                root.cursorX = pointer.point.position.x;
                root.cursorY = pointer.point.position.y;
            }
        }
    }
}
