pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ============ CẤU HÌNH ============
    // Pattern glob để tìm socket của kitty trong /tmp
    // Ví dụ mỗi kitty được mở bằng:
    //   kitty -o allow_remote_control=yes --listen-on unix:/tmp/kitty_id_$RANDOM
    property string socketGlob: "/tmp/kitty_id*"

    // Opacity nhỏ nhất/lớn nhất cho phép kéo tới (kitty không cho set 0 tuyệt đối ở vài bản)
    property real minOpacity: 0.10
    property real maxOpacity: 1.0

    // Đường dẫn tới kitty.conf, dùng để lưu opacity thật (không chỉ đổi live qua remote control)
    property string configPath: Quickshell.env("HOME") + "/.config/kitty/kitty.conf"

    // ============ TRẠNG THÁI ============
    // Danh sách instance: [{ socket: "/tmp/kitty_id_123", label: "nvim ~/proj", opacity: 0.85 }]
    property var instances: []

    // Các socket đang được chọn để điều khiển riêng. Rỗng = áp dụng cho TẤT CẢ.
    property var selectedSockets: []

    // Giá trị hiển thị trên nút giọt nước / slider (0-100), đại diện cho mức trong suốt hiện tại
    property real displayOpacity: 90

    readonly property bool hasInstances: instances.length > 0

    // ============ THEME ============
    // Thư mục chứa theme do người dùng tự thêm
    property string userThemeDir: Quickshell.env("HOME") + "/.config/kitty/themes"
    // Thư mục cache theme có sẵn (được kitty tải về khi chạy `kitty +kitten themes` lần đầu)
    property string builtinThemeCacheDir: Quickshell.env("HOME") + "/.cache/kitty-themes/themes"

    // Danh sách theme: [{ name, path, background, foreground, isUser }]
    property var themes: []

    // Tên theme đang được ÁP DỤNG chính thức (đã bấm chọn). Rỗng nếu đang dùng màu tùy chỉnh / chưa chọn.
    property string currentThemeName: ""

    // Backup màu gốc của từng socket trước khi bắt đầu preview (để phục hồi khi rê chuột ra ngoài)
    property var previewBackup: ({})
    property bool isPreviewing: false

    // ============ MÀU CHỮ TÙY CHỈNH ============
    // Chỉ override màu chữ, độc lập với theme (theme đổi cả bảng màu, cái này chỉ đổi màu chữ nhanh)
    property color customForeground: "#cdd6f4"

    // ============ FONT ============
    // Thư mục font người dùng tự thêm vào (dò ra bằng grep trong cấu hình fontconfig, xem hàm scanFonts)
    property string userFontDir: ""
    // Danh sách font: [{ name }]
    property var fonts: []
    // Font đang được ÁP DỤNG chính thức (đã bấm chọn / đã có sẵn trong kitty.conf khi mở popup)
    property string currentFontName: ""
    property bool isPreviewingFont: false

    // ============ QUÉT DANH SÁCH KITTY ĐANG CHẠY ============
    function refreshInstances() {
        scanProcess.running = false;
        scanProcess.running = true;
    }

    Process {
        id: scanProcess
        running: false
        command: ["bash", "-c", `
            for f in ${root.socketGlob}; do
              [ -S "$f" ] || continue
              title=$(kitty @ --to "unix:$f" ls 2>/dev/null | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d[0]['tabs'][0]['windows'][0]['title'][:24])
except Exception:
    print('')
" 2>/dev/null)
              [ -z "$title" ] && title="kitty"
              echo "$f|$title"
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split("\n") : [];
                const found = lines.map(line => {
                    const idx = line.indexOf("|");
                    const socket = idx >= 0 ? line.slice(0, idx) : line;
                    const label = idx >= 0 ? line.slice(idx + 1) : socket;
                    const prev = root.instances.find(i => i.socket === socket);
                    return {
                        socket: socket,
                        label: label || socket.split("/").pop(),
                        opacity: prev ? prev.opacity : root.displayOpacity / 100
                    };
                });

                // Bỏ các socket đã chọn nhưng không còn tồn tại
                root.selectedSockets = root.selectedSockets.filter(s => found.some(f => f.socket === s));
                root.instances = found;
            }
        }
    }

    // Danh sách socket đang được nhắm tới: các socket đã chọn, hoặc TẤT CẢ nếu chưa chọn cái nào
    function targetSockets() {
        return root.selectedSockets.length > 0
            ? root.selectedSockets
            : root.instances.map(i => i.socket);
    }

    // ============ ĐIỀU CHỈNH OPACITY ============
    // percent: 0-100
    function setOpacity(percent) {
        const value = Math.max(root.minOpacity, Math.min(root.maxOpacity, percent / 100));
        root.displayOpacity = value * 100;

        // Lưu lại vào kitty.conf để lần mở kitty tiếp theo vẫn giữ đúng độ trong suốt này.
        // Đặt TRƯỚC early-return bên dưới, để dù chưa có cửa sổ kitty nào đang chạy
        // (targets rỗng) giá trị vẫn được lưu cho lần mở kitty sau.
        // Dùng debounce vì setOpacity() có thể bị gọi liên tục khi lăn chuột / kéo slider.
        persistOpacityTimer.restart();

        const targets = root.targetSockets();

        if (targets.length === 0) return;

        // cập nhật opacity đã lưu cho từng instance được áp dụng
        root.instances = root.instances.map(i => {
            if (targets.includes(i.socket)) {
                return { socket: i.socket, label: i.label, opacity: value };
            }
            return i;
        });

        const cmd = targets.map(s => `kitty @ --to "unix:${s}" set-background-opacity ${value.toFixed(2)} >/dev/null 2>&1`).join(" ; ");
        applyProcess.command = ["bash", "-c", cmd];
        applyProcess.running = true;
    }

    Process {
        id: applyProcess
        running: false
    }

    // Đợi 400ms sau lần đổi cuối cùng rồi mới ghi file, tránh spam sed khi đang kéo/lăn liên tục
    Timer {
        id: persistOpacityTimer
        interval: 400
        repeat: false
        onTriggered: root.persistOpacity()
    }

    Process {
        id: persistOpacityProcess
        running: false
    }

    // Ghi giá trị background_opacity hiện tại xuống kitty.conf (lưu thật, sống sót qua lần mở kitty sau)
    function persistOpacity() {
        const value = (root.displayOpacity / 100).toFixed(2);
        const writeConf = `
            conf="${root.configPath}"
            touch "$conf"
            if grep -qE '^background_opacity[[:space:]]' "$conf"; then
                sed -i "s/^background_opacity.*/background_opacity ${value}/" "$conf"
            else
                echo "background_opacity ${value}" >> "$conf"
            fi
        `;
        persistOpacityProcess.command = ["bash", "-c", writeConf];
        persistOpacityProcess.running = true;
    }

    // ============ CHỌN / BỎ CHỌN INSTANCE ============
    function toggleSelected(socket) {
        const list = root.selectedSockets.slice();
        const idx = list.indexOf(socket);
        if (idx >= 0) {
            list.splice(idx, 1);
        } else {
            list.push(socket);
        }
        root.selectedSockets = list;

        // đồng bộ slider theo instance vừa chọn (nếu có)
        if (list.length > 0) {
            const inst = root.instances.find(i => i.socket === list[list.length - 1]);
            if (inst) root.displayOpacity = inst.opacity * 100;
        }
    }

    function selectAll() {
        root.selectedSockets = [];
    }

    // ============ QUÉT DANH SÁCH THEME ============
    function scanThemes() {
        themeScanProcess.running = false;
        themeScanProcess.running = true;
    }

    Process {
        id: themeScanProcess
        running: false
        // Quét cả theme người dùng tự thêm lẫn theme có sẵn (cache của kitten themes).
        // Ưu tiên bản trong thư mục người dùng nếu trùng tên.
        command: ["bash", "-c", `
            for entry in "${root.userThemeDir}|user" "${root.builtinThemeCacheDir}|builtin"; do
              dir="\${entry%%|*}"
              kind="\${entry##*|}"
              [ -d "$dir" ] || continue
              for f in "$dir"/*.conf; do
                [ -f "$f" ] || continue
                name=$(basename "$f" .conf)
                bg=$(grep -m1 -E '^background[[:space:]]' "$f" | awk '{print $2}')
                fg=$(grep -m1 -E '^foreground[[:space:]]' "$f" | awk '{print $2}')
                [ -z "$bg" ] && bg="#000000"
                [ -z "$fg" ] && fg="#ffffff"
                echo "$f|$name|$bg|$fg|$kind"
              done
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split("\n") : [];
                const byName = {};
                lines.forEach(line => {
                    const parts = line.split("|");
                    if (parts.length < 5) return;
                    const [path, name, bg, fg, kind] = parts;
                    const isUser = kind === "user";
                    // Nếu trùng tên, ưu tiên bản của người dùng
                    if (byName[name] && byName[name].isUser && !isUser) return;
                    byName[name] = { name, path, background: bg, foreground: fg, isUser };
                });
                const list = Object.values(byName).sort((a, b) => a.name.localeCompare(b.name));
                root.themes = list;
            }
        }
    }

    // ============ PREVIEW / ÁP DỤNG THEME ============
    Process {
        id: themeProcess
        running: false
    }

    // Rê chuột vào theme -> xem trước trên các kitty đang mở, chưa lưu
    function previewTheme(themePath) {
        const targets = root.targetSockets();
        if (targets.length === 0) return;

        root.isPreviewing = true;
        const backup = Object.assign({}, root.previewBackup);
        const cmds = [];

        targets.forEach(s => {
            if (!(s in backup)) {
                const safeName = s.replace(/[^a-zA-Z0-9]/g, "_");
                const backupPath = `/tmp/kitty_color_backup_${safeName}.conf`;
                cmds.push(`kitty @ --to "unix:${s}" get-colors > "${backupPath}" 2>/dev/null`);
                backup[s] = backupPath;
            }
            cmds.push(`kitty @ --to "unix:${s}" set-colors --all "${themePath}" >/dev/null 2>&1`);
        });

        root.previewBackup = backup;
        themeProcess.command = ["bash", "-c", cmds.join(" ; ")];
        themeProcess.running = true;
    }

    // Rê chuột ra khỏi theme mà CHƯA bấm chọn -> khôi phục màu như trước khi preview
    function cancelPreview() {
        if (!root.isPreviewing) return;

        const cmds = [];
        for (const socket in root.previewBackup) {
            const backupPath = root.previewBackup[socket];
            cmds.push(`kitty @ --to "unix:${socket}" set-colors --all "${backupPath}" >/dev/null 2>&1`);
        }

        if (cmds.length > 0) {
            themeProcess.command = ["bash", "-c", cmds.join(" ; ")];
            themeProcess.running = true;
        }

        root.previewBackup = ({});
        root.isPreviewing = false;
    }

    // Bấm chọn theme -> áp dụng thật sự (lưu vào cấu hình kitty), hiện dấu tích
    function applyTheme(themePath, themeName) {
        const targets = root.targetSockets();
        if (targets.length === 0) return;

        const cmds = targets.map(s => `kitty @ --to "unix:${s}" set-colors --configured --all "${themePath}" >/dev/null 2>&1`);
        themeProcess.command = ["bash", "-c", cmds.join(" ; ")];
        themeProcess.running = true;

        root.currentThemeName = themeName;
        root.previewBackup = ({});
        root.isPreviewing = false;
    }

    // ============ MÀU CHỮ TÙY CHỈNH ============
    // Chỉ đổi màu chữ, độc lập với theme, áp dụng ngay và lưu vào cấu hình kitty
    function applyCustomForegroundColor(fgHex) {
        const targets = root.targetSockets();
        if (targets.length === 0) return;

        root.customForeground = fgHex;

        const cmds = targets.map(s => `kitty @ --to "unix:${s}" set-colors --configured foreground=${fgHex} >/dev/null 2>&1`);
        themeProcess.command = ["bash", "-c", cmds.join(" ; ")];
        themeProcess.running = true;
    }

    // ============ QUÉT DANH SÁCH FONT ============
    function scanFonts() {
        fontScanProcess.running = false;
        fontScanProcess.running = true;
    }

    Process {
        id: fontScanProcess
        running: false
        // 1) Dùng grep để tìm trong cấu hình fontconfig xem thư mục font người dùng nằm ở đâu
        //    (fallback về chuẩn XDG ~/.local/share/fonts nếu không grep ra được).
        // 2) Dùng grep để đọc font đang được cấu hình trong kitty.conf (nếu có).
        // 3) Liệt kê toàn bộ font monospace có trên hệ thống bằng fc-list (đã cài font mới cũng tự lên sau khi fc-cache).
        command: ["bash", "-c", `
            userFontDir=$(grep -ohE '<dir>[^<]*</dir>' "$HOME/.config/fontconfig/fonts.conf" /etc/fonts/fonts.conf 2>/dev/null \
                | sed -E 's#</?dir>##g' | sed "s#~#$HOME#" | grep -m1 "^$HOME")
            [ -z "$userFontDir" ] && userFontDir="$HOME/.local/share/fonts"
            echo "USERFONTDIR|$userFontDir"

            currentFont=$(grep -m1 -E '^font_family[[:space:]]' "$HOME/.config/kitty/kitty.conf" 2>/dev/null | sed -E 's/^font_family[[:space:]]+//')
            [ -n "$currentFont" ] && echo "CURRENTFONT|$currentFont"

            currentOpacity=$(grep -m1 -E '^background_opacity[[:space:]]' "$HOME/.config/kitty/kitty.conf" 2>/dev/null | awk '{print $2}')
            [ -n "$currentOpacity" ] && echo "CURRENTOPACITY|$currentOpacity"

            fc-list :spacing=mono family 2>/dev/null | tr ',' '\\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | sort -u | while read -r name; do
              [ -n "$name" ] && echo "FONT|$name"
            done
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().length ? text.trim().split("\n") : [];
                const fontNames = [];
                let dir = "";
                let current = "";

                lines.forEach(line => {
                    const idx = line.indexOf("|");
                    if (idx < 0) return;
                    const key = line.slice(0, idx);
                    const value = line.slice(idx + 1);
                    if (key === "USERFONTDIR") dir = value;
                    else if (key === "CURRENTFONT") current = value;
                    else if (key === "CURRENTOPACITY") {
                        const parsed = parseFloat(value);
                        if (!isNaN(parsed)) root.displayOpacity = Math.max(root.minOpacity, Math.min(root.maxOpacity, parsed)) * 100;
                    }
                    else if (key === "FONT" && value) fontNames.push(value);
                });

                root.userFontDir = dir;
                if (current) root.currentFontName = current;
                root.fonts = fontNames.map(n => ({ name: n }));
            }
        }
    }

    Process {
        id: fontProcess
        running: false
    }

    // Rê chuột vào 1 font -> xem trước live trên các kitty đang mở (chưa lưu, dùng override tạm của kitty)
    function previewFont(fontName) {
        const targets = root.targetSockets();
        if (targets.length === 0) return;

        root.isPreviewingFont = true;
        const cmds = targets.map(s => `kitty @ --to "unix:${s}" load-config -o "font_family=${fontName}" >/dev/null 2>&1`);
        fontProcess.command = ["bash", "-c", cmds.join(" ; ")];
        fontProcess.running = true;
    }

    // Rê chuột ra khỏi font mà CHƯA bấm chọn -> nạp lại cấu hình gốc (bỏ override tạm)
    // QUAN TRỌNG: kitty's "load-config" mặc định VẪN GIỮ các override -o đã gửi trước đó
    // (xem docs: "any config overrides previously specified ... are respected"), nên nếu
    // không thêm --ignore-overrides thì override font_family của previewFont() sẽ không
    // bao giờ bị hủy -> preview coi như bị "set" luôn dù chưa bấm chọn. Đây là chỗ đã fix.
    function cancelFontPreview() {
        if (!root.isPreviewingFont) return;

        const targets = root.targetSockets();
        const cmds = targets.map(s => `kitty @ --to "unix:${s}" load-config --ignore-overrides >/dev/null 2>&1`);
        if (cmds.length > 0) {
            fontProcess.command = ["bash", "-c", cmds.join(" ; ")];
            fontProcess.running = true;
        }
        root.isPreviewingFont = false;
    }

    // Bấm chọn font -> ghi font_family vào kitty.conf (lưu thật) rồi nạp lại, hiện dấu tích
    function applyFont(fontName) {
        const targets = root.targetSockets();
        if (targets.length === 0) return;

        const escaped = fontName.replace(/"/g, '\\"');
        const writeConf = `
            conf="$HOME/.config/kitty/kitty.conf"
            touch "$conf"
            if grep -qE '^font_family[[:space:]]' "$conf"; then
                sed -i "s/^font_family.*/font_family ${escaped}/" "$conf"
            else
                echo "font_family ${escaped}" >> "$conf"
            fi
        `;
        const reloadCmds = targets.map(s => `kitty @ --to "unix:${s}" load-config --ignore-overrides >/dev/null 2>&1`);
        fontProcess.command = ["bash", "-c", writeConf + "\n" + reloadCmds.join(" ; ")];
        fontProcess.running = true;

        root.currentFontName = fontName;
        root.isPreviewingFont = false;
    }

    Component.onCompleted: {
        refreshInstances();
        scanThemes();
        scanFonts();
    }
}
