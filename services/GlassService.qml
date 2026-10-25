pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons
import qs.services

// Trạng thái toàn cục của hiệu ứng Liquid Glass.
// Công tắc được lưu trong Settings.appearance.liquidGlass (settings.json của shell).
Singleton {
    id: root

    // ---- Công tắc chính (nút trong Settings -> Theme) -------------------------------------
    readonly property bool enabled: Settings.appearance.liquidGlass
    readonly property bool liquidGlass: enabled

    function setEnabled(value) {
        Settings.appearance.liquidGlass = value;
    }

    function toggle() {
        setEnabled(!enabled);
    }

    // ---- Thông số dùng chung ---------------------------------------------------------------
    // Màu nền kính theo theme hiện tại (luôn opaque; shader tự điều khiển độ đậm).
    readonly property color base: {
        const t = ThemeService.theme;
        const c = Qt.color((t && t.primary && t.primary.background) ? t.primary.background : "#13140d");
        return Qt.rgba(c.r, c.g, c.b, 1);
    }
    // ---- Thông số kính: khớp quickshell (WallpaperBlur + LiquidGlass) -------------------------
    // tintAmount = max(tint, 0.12) trong quickshell.
    // Độ trong suốt kiểu giọt nước, 0..1: 0 = ruột kính mờ/đầy đủ hiệu ứng,
    // 1 = ruột gần như trong suốt và chủ yếu chỉ thấy khúc xạ ở viền.
    // Mặc định 0.35 để phần ruột cũng có blur/tint nhưng vẫn nhìn được wallpaper.
    property real transparency: 0.35
    property real panelTint: 0.12 - 0.08 * transparency
    // Bật shader kính lỏng (QSB trong shaders/qsb). Tắt để dùng GlassFallback nếu GPU không tương thích.
    property bool customShader: true
    // Chỉ dùng cho fallback.
    property real blackBacking: 2
    property real refractionDepth: 3
    // Khúc xạ
    property real ior: root.quickshellShader ? 1.5 : 1.5
    // ---- Núm chỉnh độ khúc xạ (tăng = mép kính bẻ ảnh nền mạnh hơn) -----------------------
    // quickshell gốc: bezelRatio 0.36, bezelMax 26, thicknessScale 1.15, dispersion 0.11, rim 0.45.
    // n43 có nhiều panel lồng nhau và hình nền ít chi tiết nên cần mạnh hơn để thấy rõ như quickshell.
    property real bezelRatio: root.quickshellShader ? 0.36 : 0.5
    property real bezelMax: root.quickshellShader ? 26 : 34
    property real thicknessScale: root.quickshellShader ? 1.15 : 2.2
    property real dispersion: root.quickshellShader ? 0.11 : 0.14
    property real rimStrength: root.quickshellShader ? 0.45 : 0.6
    // Panel lồng trong panel: shader giảm khúc xạ theo `nest`. Hệ số này làm giảm mức giảm đó
    // (1 = như quickshell, 0 = lồng nhau vẫn khúc xạ đầy đủ).
    property real nestDamping: root.quickshellShader ? 1 : 0.3
    property real saturation: root.quickshellShader ? 1.25 : 1.25
    // frost = max(0.5, blurStrength(1.0) * 2.5) * 1.08
    property real panelFrost: 2.7 - 1.5 * transparency

    // Giải mã/lấy mẫu hình nền ở 1/2 độ phân giải mỗi chiều như quickshell (screen / 2, ~25% pixel).
    // Kính khúc xạ + frost nên không cần full-res; GPU phóng lên bằng lọc song tuyến.
    property real textureScale: 0.5

    // Không có render node GPU (/dev/dri/renderD*) -> Mesa sẽ vẽ shader bằng CPU (llvmpipe),
    // gây 100% CPU, nên tự tắt kính trong trường hợp đó.
    property bool gpuPresent: true
    Process {
        running: true
        command: ["sh", "-c", "ls /dev/dri/renderD* >/dev/null 2>&1 && echo gpu || echo none"]
        stdout: StdioCollector {
            onStreamFinished: root.gpuPresent = this.text.trim() === "gpu"
        }
    }

    // Đặt true để ép tắt kính (nền đặc) ngay cả khi có GPU, ví dụ khi muốn tiết kiệm pin.
    property bool forceCpuOff: false
    readonly property bool gpuUsable: gpuPresent && !forceCpuOff

    // ---- Shader gốc của quickshell (Serpantinum) -----------------------------------------------
    // Khúc xạ của quickshell do shader liquid_glass.frag.qsb của nó tạo ra, không phải do thông số.
    // Chép file đó vào n43 (xem GPU_RENDER_VI.md) thì n43 tự dùng nó và bộ thông số đúng của quickshell.
    readonly property string quickshellQsb: Quickshell.shellDir + "/shaders/qsb/liquid_glass_quickshell.frag.qsb"
    property bool quickshellShader: true
    FileView {
        path: root.quickshellQsb
        onLoaded: root.quickshellShader = true
        onLoadFailed: root.quickshellShader = false
    }

    readonly property url shaderUrl: "file://" + (quickshellShader ? quickshellQsb : Quickshell.shellDir + "/shaders/qsb/liquid_glass.frag.qsb")
}
