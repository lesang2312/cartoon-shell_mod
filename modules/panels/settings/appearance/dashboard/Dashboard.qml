import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.commons

Item {
  id: dashboardSettings

  property string homePath: {
    try {
      return Directories.home;
    } catch (e) {
      console.log("Directories.home không khả dụng, dùng $HOME thay thế:", e);
      return Quickshell.env ? (Quickshell.env("HOME") || "") : "";
    }
  }

  property var layoutModel: [
    {
      key: "dwindle_default",
      name: lang?.dashboard?.dwindle_default_name || "Hyprland Dwindle (Mặc định)",
      desc: lang?.dashboard?.dwindle_default_desc || "Xoắn ốc chia đôi liên tục — thuật toán chia cửa sổ gốc và mặc định của Hyprland.",
      glyph: "🌀",
      cardRadius: 18,
      previewRadius: 12,
      previewType: "dwindleDefault",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = false,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:1} ],
        [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:0.5} , {x:0.5,y:0.5,w:0.5,h:0.5} ]
      ]
    },
    {
      key: "master_left",
      name: lang?.dashboard?.master_left_name || "Hyprland Master – Trái",
      desc: lang?.dashboard?.master_left_desc || "Một cửa sổ chủ chiếm bên trái, các cửa sổ phụ xếp chồng dọc bên phải.",
      glyph: "▌",
      cardRadius: 9,
      previewRadius: 7,
      previewType: "masterLeft",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\tnew_status = \"slave\",\n\t\torientation = \"left\",\n\t\tmfact = 0.55,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:0.65,h:1} ],
        [ {x:0,y:0,w:0.65,h:1} , {x:0.65,y:0,w:0.35,h:0.5} , {x:0.65,y:0.5,w:0.35,h:0.5} ]
      ]
    },
    {
      key: "master_right",
      name: lang?.dashboard?.master_right_name || "Hyprland Master – Phải",
      desc: lang?.dashboard?.master_right_desc || "Đối xứng với Master – Trái: cửa sổ chủ chiếm bên phải, các cửa sổ phụ xếp chồng dọc bên trái.",
      glyph: "▐",
      cardRadius: 30,
      previewRadius: 22,
      previewType: "masterRight",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\tnew_status = \"slave\",\n\t\torientation = \"right\",\n\t\tmfact = 0.65,\n\t},\n})",
      frames: [
        [ {x:0.35,y:0,w:0.65,h:1} ],
        [ {x:0.35,y:0,w:0.65,h:1} , {x:0,y:0,w:0.35,h:0.5} , {x:0,y:0.5,w:0.35,h:0.5} ]
      ]
    },
    {
      key: "master_center",
      name: lang?.dashboard?.master_center_name || "Master – Trung Tâm (Niri Style)",
      desc: lang?.dashboard?.master_center_desc || "Cửa sổ chủ nằm giữa màn hình, các cửa sổ phụ dàn đều hai bên — gợi nhớ bố cục cột giữa của Niri.",
      glyph: "🧩",
      cardRadius: 14,
      previewRadius: 10,
      previewType: "masterCenter",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"center\",\n\t\tmfact = 0.5,\n\t\tnew_status = \"slave\",\n\t},\n})",
      frames: [
        [ {x:0.25,y:0,w:0.5,h:1} ],
        [ {x:0,y:0,w:0.22,h:1} , {x:0.25,y:0,w:0.5,h:1} , {x:0.78,y:0,w:0.22,h:1} ]
      ]
    },
    {
      key: "niri_columns",
      name: lang?.dashboard?.niri_columns_name || "Cột Cuộn Đều (Niri Style)",
      desc: lang?.dashboard?.niri_columns_desc || "Nhiều cột hẹp cao đầy màn hình, đứng cạnh nhau — dải cột cuộn ngang (bản mô phỏng).",
      glyph: "🗂",
      cardRadius: 36,
      previewRadius: 26,
      previewType: "niriColumns",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpermanent_direction_override = true,\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:0.48,h:1} , {x:0.52,y:0,w:0.48,h:1} ],
        [ {x:0,y:0,w:0.23,h:1} , {x:0.26,y:0,w:0.23,h:1} , {x:0.52,y:0,w:0.23,h:1} , {x:0.78,y:0,w:0.22,h:1} ]
      ]
    },
    {
      key: "dwindle_snap",
      name: lang?.dashboard?.dwindle_snap_name || "Dwindle Snap Đều (Win11 Style)",
      desc: lang?.dashboard?.dwindle_snap_desc || "Chia đều bốn góc màn hình khi lần lượt kéo cửa sổ tới các cạnh — gần với Snap Layouts của Win11.",
      glyph: "🪟",
      cardRadius: 8,
      previewRadius: 6,
      previewType: "dwindleSnap",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t\tforce_split = 2,\n\t},\n})",
      frames: [
        [ {x:0.02,y:0.02,w:0.96,h:0.96} ],
        [ {x:0,y:0,w:0.49,h:0.49} , {x:0.51,y:0,w:0.49,h:0.49} , {x:0,y:0.51,w:0.49,h:0.49} , {x:0.51,y:0.51,w:0.49,h:0.49} ]
      ]
    },
    {
      key: "dwindle_zorin",
      name: lang?.dashboard?.dwindle_zorin_name || "Dwindle Mượt Mà (Zorin OS)",
      desc: lang?.dashboard?.dwindle_zorin_desc || "Giữ tỷ lệ chia cân đối, mượt mà — trải nghiệm chia cửa sổ nhẹ nhàng, gọn gàng.",
      glyph: "❄",
      cardRadius: 24,
      previewRadius: 17,
      previewType: "dwindleZorin",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = true,\n\t\tdefault_split_ratio = 1.0,\n\t},\n})",
      frames: [
        [ {x:0.02,y:0.05,w:0.46,h:0.9} , {x:0.52,y:0.05,w:0.46,h:0.9} ],
        [ {x:0.02,y:0.05,w:0.3,h:0.9} , {x:0.35,y:0.05,w:0.3,h:0.9} , {x:0.68,y:0.05,w:0.3,h:0.9} ]
      ]
    },
    {
      key: "zorin_thirds",
      name: lang?.dashboard?.zorin_thirds_name || "Chia Ba Cân Đối (Zorin Style)",
      desc: lang?.dashboard?.zorin_thirds_desc || "Ba cột đều nhau, viền bo tròn, khoảng cách rộng rãi — phong cách chia thư thái.",
      glyph: "🧊",
      cardRadius: 32,
      previewRadius: 24,
      previewType: "zorinThirds",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = true,\n\t\tdefault_split_ratio = 0.9,\n\t\tforce_split = 0,\n\t},\n})",
      frames: [
        [ {x:0.03,y:0.05,w:0.94,h:0.9} ],
        [ {x:0.02,y:0.05,w:0.31,h:0.9} , {x:0.35,y:0.05,w:0.3,h:0.9} , {x:0.67,y:0.05,w:0.31,h:0.9} ]
      ]
    },
    {
      key: "master_top",
      name: lang?.dashboard?.master_top_name || "Master – Trên Cùng (GNOME Style)",
      desc: lang?.dashboard?.master_top_desc || "Cửa sổ chủ nằm phía trên, chia đôi đơn giản — gần giống Tiling Assist của GNOME.",
      glyph: "🪄",
      cardRadius: 12,
      previewRadius: 9,
      previewType: "masterTop",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"top\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.5,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:1,h:0.6} ],
        [ {x:0,y:0,w:1,h:0.55} , {x:0,y:0.57,w:0.49,h:0.43} , {x:0.51,y:0.57,w:0.49,h:0.43} ]
      ]
    },
    {
      key: "master_bottom",
      name: lang?.dashboard?.master_bottom_name || "Master – Dưới Cùng",
      desc: lang?.dashboard?.master_bottom_desc || "Đối xứng với Master – Trên: cửa sổ chủ nằm phía dưới, các cửa sổ phụ xếp phía trên.",
      glyph: "🪁",
      cardRadius: 26,
      previewRadius: 19,
      previewType: "masterBottom",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"bottom\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.6,\n\t},\n})",
      frames: [
        [ {x:0,y:0.4,w:1,h:0.6} ],
        [ {x:0,y:0.43,w:1,h:0.57} , {x:0,y:0,w:0.49,h:0.4} , {x:0.51,y:0,w:0.49,h:0.4} ]
      ]
    },
    {
      key: "dwindle_asymmetric",
      name: lang?.dashboard?.dwindle_asymmetric_name || "Dwindle Bất Đối Xứng (i3/Sway)",
      desc: lang?.dashboard?.dwindle_asymmetric_desc || "Hướng chia luân phiên linh hoạt theo thao tác của bạn — triết lý của i3/Sway.",
      glyph: "🌳",
      cardRadius: 16,
      previewRadius: 12,
      previewType: "dwindleAsymmetric",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t\tsplit_bias = 1,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:1} ],
        [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:0.5} , {x:0.5,y:0.5,w:0.25,h:0.5} , {x:0.75,y:0.5,w:0.25,h:0.5} ]
      ]
    },
    {
      key: "master_stage",
      name: lang?.dashboard?.master_stage_name || "Master – Phụ Thu Nhỏ (macOS Style)",
      desc: lang?.dashboard?.master_stage_desc || "Cửa sổ chính chiếm phần lớn bên phải, cửa sổ phụ thu nhỏ bên trái (Stage Manager).",
      glyph: "🎭",
      cardRadius: 40,
      previewRadius: 30,
      previewType: "masterStage",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"right\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.75,\n\t\tslave_count_for_center_master = 3,\n\t},\n})",
      frames: [
        [ {x:0.22,y:0.1,w:0.76,h:0.8} ],
        [ {x:0.22,y:0.1,w:0.76,h:0.8} , {x:0,y:0.05,w:0.14,h:0.24} , {x:0,y:0.32,w:0.14,h:0.24} , {x:0,y:0.59,w:0.14,h:0.24} ]
      ]
    },
    {
      key: "dwindle_pop",
      name: lang?.dashboard?.dwindle_pop_name || "Dwindle Tự Động (Pop!_OS)",
      desc: lang?.dashboard?.dwindle_pop_desc || "Chia đôi gọn gàng, khoảng cách rộng rãi, tự động — phong cách quen thuộc của Pop!_OS.",
      glyph: "🚀",
      cardRadius: 20,
      previewRadius: 15,
      previewType: "dwindlePop",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = false,\n\t\tdefault_split_ratio = 1.0,\n\t},\n})",
      frames: [
        [ {x:0.04,y:0.04,w:0.92,h:0.92} ],
        [ {x:0.04,y:0.04,w:0.44,h:0.92} , {x:0.52,y:0.04,w:0.44,h:0.44} , {x:0.52,y:0.52,w:0.44,h:0.44} ]
      ]
    },
    {
      key: "master_kde_quarter",
      name: lang?.dashboard?.master_kde_quarter_name || "Góc Phần Tư (KDE Plasma)",
      desc: lang?.dashboard?.master_kde_quarter_desc || "Bốn vùng không đều nhau, ưu tiên góc trên-trái — thao tác Quick Tile của KDE.",
      glyph: "🧱",
      cardRadius: 22,
      previewRadius: 16,
      previewType: "masterKdeQuarter",
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"top\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.55,\n\t\tslave_count_for_center_master = 2,\n\t},\n})",
      frames: [
        [ {x:0.03,y:0.03,w:0.94,h:0.94} ],
        [ {x:0,y:0,w:0.55,h:0.55} , {x:0.57,y:0,w:0.43,h:0.55} , {x:0,y:0.57,w:0.55,h:0.43} , {x:0.57,y:0.57,w:0.43,h:0.43} ]
      ]
    },
    {
      key: "spiral_fib",
      name: lang?.dashboard?.spiral_fib_name || "Xoắn Ốc Fibonacci",
      desc: lang?.dashboard?.spiral_fib_desc || "Các cửa sổ thu nhỏ dần theo tỷ lệ vàng, cuộn tròn như vỏ ốc Fibonacci — vừa lạ vừa có trật tự toán học.",
      glyph: "🌌",
      previewType: "spiralFib",
      cardRadius: 28,
      previewRadius: 8,
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = true,\n\t\tdefault_split_ratio = 1.618,\n\t},\n})",
      frames: [
        [ {x:0.1,y:0.1,w:0.8,h:0.8} ],
        [ {x:0,y:0,w:0.618,h:1} , {x:0.618,y:0,w:0.382,h:0.382} , {x:0.618,y:0.382,w:0.191,h:0.618} , {x:0.809,y:0.382,w:0.191,h:0.309} , {x:0.809,y:0.691,w:0.191,h:0.309} ]
      ]
    },
    {
      key: "honeycomb_shift",
      name: lang?.dashboard?.honeycomb_shift_name || "Tổ Ong Lệch Tầng",
      desc: lang?.dashboard?.honeycomb_shift_desc || "Các hàng cửa sổ so le nhau như tổ ong — phá vỡ lưới vuông vức thông thường.",
      glyph: "🐝",
      previewType: "honeycombShift",
      cardRadius: 20,
      previewRadius: 14,
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"top\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.34,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:1,h:0.5} , {x:0,y:0.5,w:1,h:0.5} ],
        [ {x:0,y:0,w:0.34,h:0.5} , {x:0.33,y:0.08,w:0.34,h:0.5} , {x:0.66,y:0,w:0.34,h:0.5} , {x:0.17,y:0.52,w:0.34,h:0.48} , {x:0.5,y:0.52,w:0.34,h:0.48} ]
      ]
    },
    {
      key: "diagonal_cascade",
      name: lang?.dashboard?.diagonal_cascade_name || "Bậc Thang Chéo",
      desc: lang?.dashboard?.diagonal_cascade_desc || "Cửa sổ xếp chồng chéo góc như bậc thang trượt xuống — táo bạo và khác biệt hoàn toàn với dạng chia lưới.",
      glyph: "🎢",
      previewType: "diagonalCascade",
      cardRadius: 10,
      previewRadius: 10,
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t\tsplit_bias = 2,\n\t},\n})",
      frames: [
        [ {x:0.05,y:0.05,w:0.5,h:0.5} , {x:0.45,y:0.45,w:0.5,h:0.5} ],
        [ {x:0,y:0,w:0.4,h:0.4} , {x:0.2,y:0.2,w:0.4,h:0.4} , {x:0.4,y:0.4,w:0.4,h:0.4} , {x:0.6,y:0.6,w:0.4,h:0.4} ]
      ]
    },
    {
      key: "bento_mosaic",
      name: lang?.dashboard?.bento_mosaic_name || "Bento Ngẫu Hứng",
      desc: lang?.dashboard?.bento_mosaic_desc || "Các ô kích thước khác nhau ghép lại như hộp bento — không đối xứng, đầy cá tính.",
      glyph: "🍱",
      previewType: "bentoMosaic",
      cardRadius: 34,
      previewRadius: 18,
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = false,\n\t\tforce_split = 1,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:0.6,h:1} , {x:0.6,y:0,w:0.4,h:1} ],
        [ {x:0,y:0,w:0.6,h:0.6} , {x:0,y:0.6,w:0.3,h:0.4} , {x:0.3,y:0.6,w:0.3,h:0.4} , {x:0.6,y:0,w:0.4,h:0.35} , {x:0.6,y:0.35,w:0.4,h:0.65} ]
      ]
    },
    {
      key: "orbit_focus",
      name: lang?.dashboard?.orbit_focus_name || "Quỹ Đạo Tiêu Điểm",
      desc: lang?.dashboard?.orbit_focus_desc || "Cửa sổ chính nổi bật ở trung tâm, các cửa sổ phụ bay quanh bốn góc như vệ tinh quay quỹ đạo.",
      glyph: "🪐",
      previewType: "orbitFocus",
      cardRadius: 44,
      previewRadius: 28,
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"center\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.5,\n\t},\n})",
      frames: [
        [ {x:0.2,y:0.1,w:0.6,h:0.8} ],
        [ {x:0.25,y:0.15,w:0.5,h:0.7} , {x:0,y:0,w:0.22,h:0.3} , {x:0,y:0.7,w:0.22,h:0.3} , {x:0.78,y:0,w:0.22,h:0.3} , {x:0.78,y:0.7,w:0.22,h:0.3} ]
      ]
    },
    {
      key: "ribbon_flow",
      name: lang?.dashboard?.ribbon_flow_name || "Dải Lụa Uốn Lượn",
      desc: lang?.dashboard?.ribbon_flow_desc || "Các cột cao thấp so le nhau như dải lụa bay — bố cục thử nghiệm nhiều biến thể độ rộng và chiều cao.",
      glyph: "🎀",
      previewType: "ribbonFlow",
      cardRadius: 15,
      previewRadius: 20,
      hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpermanent_direction_override = true,\n\t\tpreserve_split = false,\n\t},\n})",
      frames: [
        [ {x:0,y:0,w:0.33,h:1} , {x:0.33,y:0,w:0.34,h:1} , {x:0.67,y:0,w:0.33,h:1} ],
        [ {x:0,y:0.1,w:0.22,h:0.8} , {x:0.24,y:0,w:0.22,h:1} , {x:0.48,y:0.15,w:0.22,h:0.7} , {x:0.72,y:0,w:0.13,h:0.45} , {x:0.72,y:0.47,w:0.13,h:0.53} , {x:0.87,y:0.05,w:0.13,h:0.9} ]
      ]
    }
  ]

  property string currentLayout: {
    try {
      return Settings.dashboard.splitMethod || "dwindle_default";
    } catch (e) {
      return "dwindle_default";
    }
  }

  property bool applyInProgress: false

  Process {
    id: applyLayoutProcess
    stdout: StdioCollector {}
    stderr: StdioCollector {
      onTextChanged: {
        if (text && text.length > 0) {
          console.log("[Dashboard] hyprctl/apply script lỗi:", text);
        }
      }
    }
    // QUAN TRỌNG: Process của Quickshell KHÔNG hề có property "exitCode" —
    // nó chỉ phát ra SIGNAL "exited(exitCode, exitStatus)" khi tiến trình
    // kết thúc. Code cũ đọc "applyLayoutProcess.exitCode" (một property
    // không tồn tại) nên giá trị đọc được luôn là "undefined", và
    // "undefined === 0" luôn luôn là false. Kết quả: dù script chạy hoàn
    // toàn thành công (exit code thật sự = 0), UI vẫn LUÔN LUÔN hiện thông
    // báo "Áp dụng thất bại!". Sửa bằng cách lấy đúng exit code thật từ
    // tham số của signal "exited" thay vì từ một property ảo không tồn tại.
    onExited: (exitCode, exitStatus) => {
      dashboardSettings.applyInProgress = false;
      // Chỉ báo thành công khi script thật sự chạy xong không lỗi (exit code 0).
      if (exitCode === 0) {
        showNotification(lang?.dashboard?.success_apply || "Đã áp dụng bố cục thành công!");
      } else {
        showNotification(lang?.dashboard?.error_apply || "Áp dụng thất bại! Kiểm tra log để biết chi tiết (config Lua có thể bị lỗi cú pháp).");
      }
    }
  }

  function applyLayout(layoutData) {
    if (dashboardSettings.applyInProgress) return;
    dashboardSettings.applyInProgress = true;

    var confDir = homePath + "/.config/hypr/custom/layout";
    var confFile = confDir + "/split-method.lua";
    // Không cần tự chèn require() vào hyprland.lua ở đây nữa — bạn đã tự thêm
    // đúng dòng pcall(require, "custom.layout.split-method") trong hyprland.lua,
    // có bọc pcall để không sập cả config nếu file layout lỗi cú pháp. Tự chèn
    // thêm 1 require không bọc pcall ở đây sẽ vừa bị trùng, vừa có nguy cơ làm
    // sập toàn bộ config khi file layout lỗi (mất tác dụng bảo vệ của pcall).

    // Bo tròn cửa sổ THẬT lấy đúng con số đang vẽ trên card xem trước,
    // để "mô tả sao thì thực tế phải vậy" thay vì hai giá trị lệch nhau.
    var rounding = Math.round(layoutData.previewRadius);

    var decorationAndAnim =
        "\n\n-- Bo tròn cửa sổ thật, đồng bộ với previewRadius trên card\n"
      + "hl.config({\n"
      + "\tdecoration = {\n"
      + "\t\trounding = " + rounding + ",\n"
      + "\t\trounding_power = 2.5,\n" // các góc bo mềm, tự nhiên hơn kiểu tròn cứng thô
      + "\t\tactive_opacity = 1.0,\n"
      + "\t\tinactive_opacity = 0.94,\n"
      + "\t\tshadow = { enabled = true, range = 18, render_power = 3, color = \"rgba(00000055)\" },\n"
      + "\t},\n"
      + "})\n\n"
      + "-- Bộ hiệu ứng cho cửa sổ THẬT, đồng bộ cảm giác nảy như trên UI Dashboard.\n"
      + "-- Spring cho hiệu ứng nảy nhẹ khi mở / kéo-thả / snap vào layout:\n"
      + "hl.curve(\"dashboardBounce\", { type = \"spring\", mass = 1, stiffness = 170, dampening = 14 })\n"
      + "-- Bezier mượt cho các chuyển động không cần nảy (đóng, mờ dần, đổi workspace):\n"
      + "hl.curve(\"dashboardSmooth\", { type = \"bezier\", points = { {0.16, 1}, {0.3, 1} } })\n\n"
      + "hl.animation({ leaf = \"windowsIn\",   enabled = true, speed = 5, spring = \"dashboardBounce\", style = \"popin 80%\" })\n" // mở cửa sổ: phóng to kèm nảy nhẹ
      + "hl.animation({ leaf = \"windowsOut\",  enabled = true, speed = 4, bezier = \"dashboardSmooth\", style = \"popin 80%\" })\n" // đóng cửa sổ: thu nhỏ mượt, không nảy (tránh giật mắt)
      + "hl.animation({ leaf = \"windowsMove\", enabled = true, speed = 5, spring = \"dashboardBounce\" })\n" // kéo/snap cửa sổ: nảy nhẹ khi chạm layout mới
      + "hl.animation({ leaf = \"border\",      enabled = true, speed = 6, bezier = \"dashboardSmooth\" })\n" // viền đổi màu mượt khi focus
      + "hl.animation({ leaf = \"fade\",        enabled = true, speed = 5, bezier = \"dashboardSmooth\" })\n" // mờ/hiện mượt
      + "hl.animation({ leaf = \"workspaces\",  enabled = true, speed = 5, bezier = \"dashboardSmooth\", style = \"slide\" })\n"; // chuyển workspace trượt mượt

    var script =
        "mkdir -p '" + confDir + "' && cat > '" + confFile + "' <<'EOF'\n"
      + layoutData.hyprLua
      + decorationAndAnim
      + "EOF\n"
      // QUAN TRỌNG: bắt riêng exit code của "hyprctl reload" và dùng NÓ làm
      // exit code cuối cùng của cả script (exit "$reload_status" ở cuối).
      // Trước đây dùng "hyprctl reload && for ... done" nên exit code cuối
      // cùng lại phụ thuộc vào LỆNH CUỐI trong vòng for (focuswindow/
      // togglefloating) — chỉ là hiệu ứng xếp lại cửa sổ cho đẹp, không liên
      // quan gì đến việc config Lua có hợp lệ hay không. Hệ quả: chỉ cần một
      // cửa sổ toggle floating bị trục trặc (ví dụ cửa sổ đó đã đóng, hoặc
      // không hỗ trợ floating) là cả script báo "thất bại", khiến người dùng
      // thấy thông báo sai "config Lua có thể bị lỗi cú pháp" dù thật ra
      // hyprctl reload đã chạy thành công và config hoàn toàn hợp lệ.
      + "hyprctl reload; reload_status=$?; "
      // Hyprland KHÔNG tự re-tile các cửa sổ đang mở sẵn khi chỉ đổi thuật toán
      // layout / rounding / animation qua reload — chỉ cửa sổ mở SAU mới nhận
      // layout mới. Ép từng cửa sổ đang mở thoát khỏi tiling rồi gắn lại
      // (toggle floating 2 lần) để chúng được xếp lại + nhận rounding/animation
      // mới ngay, giống hệt những gì thấy ở card xem trước.
      // Chỉ chạy bước "làm đẹp" này khi reload thật sự thành công, và dù nó
      // có trục trặc gì đi nữa cũng KHÔNG được làm thay đổi reload_status.
      + "if [ \"$reload_status\" -eq 0 ]; then "
      + "for addr in $(hyprctl clients -j | grep -oE '\"address\":[[:space:]]*\"0x[0-9a-fA-F]+\"' | grep -oE '0x[0-9a-fA-F]+'); do "
      + "hyprctl dispatch focuswindow address:$addr >/dev/null 2>&1; "
      + "hyprctl dispatch togglefloating >/dev/null 2>&1; "
      + "hyprctl dispatch togglefloating >/dev/null 2>&1; "
      + "done; "
      + "fi; "
      + "exit \"$reload_status\"";

    applyLayoutProcess.command = ["bash", "-c", script];
    applyLayoutProcess.running = true;

    try {
      // QUAN TRỌNG: phải GÁN LẠI CẢ OBJECT "dashboard" (không được mutate
      // property con như Settings.dashboard.splitMethod = ...). Hệ thống
      // Settings chỉ phát tín hiệu lưu ra file khi chính property "dashboard"
      // được gán lại — mutate object con trong JS không hề trigger việc lưu,
      // nên trước đây lựa chọn chỉ đúng tạm thời trong RAM, chưa từng thật sự
      // ghi xuống đĩa. Đó là lý do mất lựa chọn, quay về mặc định sau khi
      // Quickshell/Dashboard bị restart (ví dụ khi mở nhiều cửa sổ gây reload shell).
      var currentDashboardSettings = Settings.dashboard ? Object.assign({}, Settings.dashboard) : {};
      currentDashboardSettings.splitMethod = layoutData.key;
      Settings.dashboard = currentDashboardSettings;
      // KHÔNG gán "dashboardSettings.currentLayout = layoutData.key" ở đây nữa.
      // "currentLayout" là một PROPERTY BINDING (đọc từ Settings.dashboard.splitMethod).
      // Gán trực tiếp bằng "=" như trước đây sẽ HUỶ VĨNH VIỄN binding đó — kể từ lúc
      // đó "currentLayout" không còn tự cập nhật theo Settings.dashboard nữa trong
      // suốt vòng đời của Dashboard, khiến UI (isCurrent) có thể lệch khỏi giá trị
      // thật sự đã lưu (đặc biệt nếu Settings đổi từ nơi khác, hoặc dashboard bị
      // giữ sống bởi Loader thay vì tạo mới). Chỉ cần Settings.dashboard được gán
      // lại ở dòng trên, binding sẽ tự re-evaluate và currentLayout tự cập nhật
      // đúng — không cần set tay.
    } catch (e) {
      console.log("Settings.dashboard.splitMethod chưa lưu được:", e);
      // Chỉ set tay làm phương án dự phòng khi việc lưu thật sự lỗi, để ít nhất
      // UI trong phiên hiện tại vẫn phản ánh đúng lựa chọn vừa bấm.
      dashboardSettings.currentLayout = layoutData.key;
    }
  }

  ScrollView {
    id: scrollView
    anchors.fill: parent
    anchors.margins: ScalerService.s(24) // Lề rộng rãi
    clip: true
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    ColumnLayout {
      width: parent.width
      spacing: ScalerService.s(20)

      // Header tinh tế hơn
      ColumnLayout {
        Layout.fillWidth: true
        spacing: ScalerService.s(6)
        
        Text {
          text: lang?.dashboard?.title || "Bố Cục Cửa Sổ"
          color: theme.primary.foreground
          font.pixelSize: ScalerService.s(26)
          font.bold: true
          font.family: "ComicShannsMono Nerd Font"
        }

        Text {
          Layout.fillWidth: true
          text: lang?.dashboard?.subtitle || "Di chuột vào thẻ để xem trước mô phỏng. Click để áp dụng vào Hyprland."
          color: theme.primary.dim_foreground
          font.pixelSize: ScalerService.s(14)
          font.family: "ComicShannsMono Nerd Font"
          opacity: 0.85
          wrapMode: Text.WordWrap
        }
        
        Text {
          Layout.fillWidth: true
          text: lang?.dashboard?.engine_note || "* Các bố cục dưới đây được tinh chỉnh từ Dwindle & Master để mô phỏng thẩm mỹ của các môi trường khác."
          color: theme.primary.dim_foreground
          font.pixelSize: ScalerService.s(12)
          font.family: "ComicShannsMono Nerd Font"
          font.italic: true
          opacity: 0.5
          wrapMode: Text.WordWrap
        }
      }

      Rectangle {
        Layout.fillWidth: true
        height: ScalerService.s(1)
        color: Qt.alpha(theme.primary.foreground, 0.08) // Dải phân cách mờ 
      }

      // Lưới Layout Card
      Grid {
        id: layoutGrid
        Layout.fillWidth: true
        columns: 3
        columnSpacing: ScalerService.s(18) // Khoảng cách giữa các cột
        rowSpacing: ScalerService.s(18)

        Repeater {
          model: dashboardSettings.layoutModel

          delegate: Rectangle {
            id: layoutCard
            width: (layoutGrid.width - (layoutGrid.columnSpacing * 2)) / 3
            height: ScalerService.s(260) 
            // Mỗi biến thể layout có độ bo góc riêng (cardRadius) — nếu layout không khai báo thì dùng 18 mặc định
            radius: ScalerService.s(layoutData.cardRadius !== undefined ? layoutData.cardRadius : 18)
            Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
            
            // Màu nền kính mờ (Glassmorphism)
            color: isCurrent ? Qt.alpha(theme.normal.blue, 0.08) : (hovered ? Qt.alpha(theme.button.background, 0.9) : Qt.alpha(theme.button.background, 0.5))
            
            border.color: isCurrent ? theme.normal.blue : (hovered ? Qt.alpha(theme.normal.blue, 0.4) : "transparent")
            border.width: isCurrent ? ScalerService.s(2) : ScalerService.s(1)
            
            scale: hovered ? 1.05 : 1.0 // Card nổi lên rõ ràng hơn khi hover để thấy độ nảy
            
            // --- HIỆU ỨNG NẢY 1 LẦN KHI DI CHUỘT VÀO CARD ---
            Behavior on scale { 
                NumberAnimation { 
                    duration: 420; 
                    easing.type: Easing.OutBack; 
                    easing.overshoot: 1.6
                } 
            }
            
            Behavior on color { ColorAnimation { duration: 250 } }
            Behavior on border.color { ColorAnimation { duration: 250 } }

            property var layoutData: modelData
            property bool isCurrent: dashboardSettings.currentLayout === modelData.key
            property bool hovered: false

            // Chuẩn hoá dữ liệu preview: gộp cả 2 trạng thái (thu gọn / mở rộng)
            // để Repeater bên dưới luôn dùng CÙNG một số lượng delegate.
            // Đây là gốc rễ của lỗi "layout không chạy": trước đây Repeater đổi
            // thẳng model giữa frames[0] và frames[1] khi hover, khiến QML hủy
            // toàn bộ delegate cũ và tạo delegate mới ở vị trí cuối cùng luôn —
            // không có animation chuyển tiếp nào chạy cả, mọi thứ chỉ "nhảy cóc".
            readonly property var compactFrames: layoutData.frames[0]
            readonly property var expandedFrames: layoutData.frames[1]
            readonly property int frameCount: Math.max(compactFrames.length, expandedFrames.length)

            // ==== HỌA TIẾT HÌNH HỌC NỀN CHÌM TẠO SỰ TINH TẾ ====
            Item {
              anchors.fill: parent
              clip: true 
              
              // Đã loại bỏ xoay (rotation) theo yêu cầu
              Rectangle {
                width: ScalerService.s(130)
                height: width
                radius: ScalerService.s(30)
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: ScalerService.s(-45)
                anchors.topMargin: ScalerService.s(-45)
                color: layoutCard.isCurrent ? Qt.alpha(theme.normal.blue, 0.08) : (layoutCard.hovered ? Qt.alpha(theme.normal.blue, 0.04) : "transparent")
                Behavior on color { ColorAnimation { duration: 300 } }
              }
              
              // Hình tròn mờ ở góc dưới
              Rectangle {
                width: ScalerService.s(70)
                height: width
                radius: width / 2
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: ScalerService.s(-10)
                anchors.bottomMargin: ScalerService.s(-10)
                color: layoutCard.isCurrent ? Qt.alpha(theme.normal.green, 0.05) : "transparent"
                Behavior on color { ColorAnimation { duration: 300 } }
              }
            }

            // ==== NỘI DUNG CHÍNH CỦA CARD ====
            Column {
              anchors.fill: parent
              anchors.margins: ScalerService.s(16)
              spacing: ScalerService.s(12)

              // 1. Khung Preview Workspace
              Rectangle {
                id: previewBox
                width: parent.width
                height: ScalerService.s(105)
                // Mỗi biến thể layout có độ bo khung preview riêng (previewRadius).
                // TRƯỚC ĐÂY: previewBox (khung "cửa sổ chính" chứa toàn bộ các ô mini bên
                // trong) hoàn toàn đứng im khi hover — chỉ layoutCard (khung ngoài cùng) và
                // từng miniWindow (ô con) có bo tròn/nảy phản hồi hover, còn khung nền desktop
                // giả lập ở giữa thì không. Giờ bo thêm 1 chút khi card được hover, đồng bộ
                // cảm giác "phồng lên" với 2 lớp còn lại.
                radius: ScalerService.s((layoutCard.layoutData.previewRadius !== undefined ? layoutCard.layoutData.previewRadius : 12) + (layoutCard.hovered ? 4 : 0))
                Behavior on radius { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                clip: true
                border.width: layoutCard.hovered ? 1.5 : 1
                border.color: layoutCard.hovered ? Qt.alpha(theme.normal.blue, 0.35) : Qt.alpha(theme.primary.foreground, 0.06)
                Behavior on border.width { NumberAnimation { duration: 250 } }
                Behavior on border.color { ColorAnimation { duration: 250 } }

                // --- HIỆU ỨNG NẢY CHO "CỬA SỔ CHÍNH": chính khung nền desktop giả lập này
                // giờ cũng phóng nhẹ (scale) kèm nảy khi rê chuột vào card, y hệt kiểu nảy
                // OutBack đang dùng cho layoutCard và miniWindow, chỉ khác biên độ nhỏ hơn
                // vì đây là khung lớn nhất, phóng to nhiều sẽ trông "vỡ" bố cục hơn là nảy.
                // transformOrigin ở giữa để không lệch các ô mini con nằm bên trong.
                scale: layoutCard.hovered ? 1.025 : 1.0
                transformOrigin: Item.Center
                Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }

                // Background giả lập Desktop tĩnh
                gradient: Gradient {
                  GradientStop { position: 0.0; color: Qt.alpha(theme.primary.background, 0.5) }
                  GradientStop { position: 1.0; color: Qt.alpha(theme.primary.background, 0.15) }
                }

                Repeater {
                  // Số delegate CỐ ĐỊNH — không đổi khi hover, chỉ toạ độ/kích thước của
                  // từng ô thay đổi mượt qua Behavior bên dưới. Đây là phần sửa lỗi chính:
                  // trước đây model đổi thẳng giữa frames[0]/frames[1] khiến Repeater huỷ
                  // sạch rồi tạo lại toàn bộ delegate -> preview "đứng hình", không animate.
                  model: layoutCard.frameCount

                  // ==========================================
                  // CỬA SỔ SIÊU NHỎ GIẢ LẬP
                  // - Khi CHƯA dùng (chưa hover card) -> nén lại thành hình tròn, không thao tác được.
                  // - Khi rê chuột vào card -> "mở rộng" ra thành bố cục cửa sổ thật, có thể tương tác.
                  // ==========================================
                  delegate: Rectangle {
                    id: miniWindow
                    property bool windowHovered: false // Trạng thái hover riêng của cửa sổ nhỏ

                    // Khung tương ứng cho trạng thái thu gọn / mở rộng của ô thứ [index].
                    // Nếu ô này chỉ xuất hiện ở trạng thái mở rộng (nhiều cửa sổ hơn), nó sẽ
                    // "sinh ra" từ vị trí ô cuối cùng của trạng thái thu gọn rồi nảy ra chỗ thật.
                    readonly property var lastCompact: layoutCard.compactFrames[layoutCard.compactFrames.length - 1]
                    readonly property bool existsInCompact: index < layoutCard.compactFrames.length
                    readonly property var compactRect: existsInCompact ? layoutCard.compactFrames[index] : lastCompact
                    readonly property var expandedRect: index < layoutCard.expandedFrames.length ? layoutCard.expandedFrames[index] : lastCompact
                    readonly property var targetRect: layoutCard.hovered ? expandedRect : compactRect
                    // Chỉ "hoạt động như thường" (nhận hover riêng) khi đã mở rộng ra
                    readonly property bool interactive: layoutCard.hovered
                    // Rời card đột ngột cũng phải nén lại, không kẹt ở trạng thái hover cũ
                    onInteractiveChanged: if (!interactive) windowHovered = false

                    clip: true
                    // MẶC ĐỊNH LUÔN LÀ HÌNH TRÒN/VIÊN THUỐC NÉN LẠI — không phụ thuộc việc
                    // card có đang hover hay không. CHỈ ô nào được rê chuột trực tiếp vào
                    // (windowHovered) mới "mở ra" thành khung cửa sổ bo góc nhẹ để dùng.
                    radius: windowHovered ? ScalerService.s(5) : Math.min(width, height) / 2
                    
                    color: layoutCard.isCurrent ? theme.normal.blue : theme.primary.foreground
                    
                    // Ô chỉ tồn tại ở trạng thái mở rộng thì mờ dần về 0 khi nén lại,
                    // thay vì đứng lù lù không đúng chỗ.
                    opacity: (!existsInCompact && !layoutCard.hovered) ? 0
                      : windowHovered ? 0.9
                      : (layoutCard.isCurrent ? (0.45 + 0.1 * index) : (0.15 + 0.05 * index))
                    border.width: windowHovered ? 2 : 1
                    border.color: windowHovered ? theme.normal.blue : (layoutCard.isCurrent ? Qt.alpha(theme.normal.blue, 0.7) : Qt.alpha(theme.primary.foreground, 0.25))

                    // Phóng to nhẹ khi rê chuột — nén nhỏ lại một chút khi ở dạng viên thuốc
                    // để lúc mở ra có cảm giác "nảy bung" rõ ràng hơn.
                    scale: windowHovered ? 1.1 : 0.9
                    z: windowHovered ? 10 : index 

                    x: targetRect.x * previewBox.width + ScalerService.s(3)
                    y: targetRect.y * previewBox.height + ScalerService.s(3)
                    width: targetRect.w * previewBox.width - ScalerService.s(6)
                    height: targetRect.h * previewBox.height - ScalerService.s(6)

                    // --- HIỆU ỨNG NẢY 1 LẦN KHI DI CHUỘT VÀO (OutBack = nảy quá đà đúng 1 nhịp rồi
                    // ổn định, khác với OutElastic dao động nhiều lần trông như bị "rung") ---
                    Behavior on radius { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Behavior on scale { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                    Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                    Behavior on y { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                    Behavior on width { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                    Behavior on height { NumberAnimation { duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.4 } }
                    Behavior on opacity { NumberAnimation { duration: 250 } } // Opacity giữ nguyên để không bị nháy

                    // Thanh Title Bar giả lập phía trên cửa sổ
                    Rectangle {
                      anchors.top: parent.top
                      anchors.left: parent.left
                      anchors.right: parent.right
                      height: ScalerService.s(8)
                      color: Qt.alpha(theme.primary.background, 0.3)
                      // Chỉ hiện title bar khi CHÍNH ô này đang được hover trực tiếp — vì
                      // lúc còn nén tròn (chưa dùng) thì cửa sổ chưa "hoạt động như thường".
                      opacity: miniWindow.windowHovered ? 1.0 : 0.0
                      Behavior on opacity { NumberAnimation { duration: 300 } }
                      
                      // 3 Chấm điều khiển chuẩn phong cách macOS
                      Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: ScalerService.s(4)
                        spacing: ScalerService.s(2.5)
                        visible: miniWindow.width > ScalerService.s(22) // Ẩn nếu ô chia quá hẹp
                        // Cả 3 chấm cũng nảy nhẹ theo đúng ô cửa sổ đang được hover trực tiếp
                        scale: windowHovered ? 1.25 : 1.0
                        transformOrigin: Item.Center
                        Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }

                        Rectangle { width: ScalerService.s(2.5); height: width; radius: width/2; color: Qt.alpha("#ff5f56", layoutCard.isCurrent || windowHovered ? 0.9 : 0.4) }
                        Rectangle { width: ScalerService.s(2.5); height: width; radius: width/2; color: Qt.alpha("#ffbd2e", layoutCard.isCurrent || windowHovered ? 0.9 : 0.4) }
                        Rectangle { width: ScalerService.s(2.5); height: width; radius: width/2; color: Qt.alpha("#27c93f", layoutCard.isCurrent || windowHovered ? 0.9 : 0.4) }
                      }
                    }

                    // Vùng tương tác chuột dành riêng cho cửa sổ con.
                    // Chỉ bật (enabled) khi cửa sổ đang ở dạng "mở rộng" — lúc còn nén tròn
                    // (chưa dùng) thì không nhận hover/klick riêng, đúng yêu cầu "không hoạt
                    // động như thường" khi ở trạng thái nén.
                    MouseArea {
                      anchors.fill: parent
                      enabled: miniWindow.interactive
                      hoverEnabled: true
                      propagateComposedEvents: true // Để click xuyên qua xuống Card chính (không chặn nút áp dụng)
                      
                      onEntered: miniWindow.windowHovered = true
                      onExited: miniWindow.windowHovered = false
                      onClicked: (mouse) => { mouse.accepted = false } // Bỏ qua click, chuyển tiếp xuống thẻ
                    }
                  }
                }

                // Icon Glyph tinh tế ở góc phải dưới — nảy nhẹ theo khi hover cả card,
                // để mọi "ô" nhỏ trên card đều có cảm giác phản hồi khi di chuột vào,
                // không chỉ riêng khung card hay các ô cửa sổ mini bên trong preview.
                Text {
                  anchors.bottom: parent.bottom
                  anchors.right: parent.right
                  anchors.margins: ScalerService.s(8)
                  text: layoutCard.layoutData.glyph
                  color: theme.primary.foreground
                  font.pixelSize: ScalerService.s(18)
                  opacity: layoutCard.hovered ? 0.9 : 0.5
                  scale: layoutCard.hovered ? 1.18 : 1.0
                  transformOrigin: Item.Center
                  Behavior on opacity { NumberAnimation { duration: 250 } }
                  Behavior on scale { NumberAnimation { duration: 380; easing.type: Easing.OutBack; easing.overshoot: 1.8 } }
                }
              }

              // 2. Tiêu đề và Nội dung
              Text {
                width: parent.width
                text: layoutCard.layoutData.name
                color: layoutCard.isCurrent ? theme.normal.blue : theme.primary.foreground
                font.pixelSize: ScalerService.s(14)
                font.bold: true
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 250 } }
              }

              Text {
                width: parent.width
                height: ScalerService.s(45)
                text: layoutCard.layoutData.desc
                color: theme.primary.dim_foreground
                font.pixelSize: ScalerService.s(12)
                opacity: 0.75
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                lineHeight: 1.25
              }
              
              Item { width: 1; height: 1; Layout.fillHeight: true } // Filler đẩy nút xuống đáy

              // 3. Nút áp dụng (Pill Design)
              Rectangle {
                width: parent.width
                height: ScalerService.s(34)
                radius: height / 2 // Bo tròn 2 đầu dạng viên thuốc
                color: layoutCard.isCurrent ? theme.normal.green : (cardMouseArea.pressed ? Qt.darker(theme.normal.blue, 1.2) : theme.normal.blue)
                opacity: (dashboardSettings.applyInProgress && !layoutCard.isCurrent) ? 0.4 : (layoutCard.hovered || layoutCard.isCurrent ? 1.0 : 0.8)
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Row {
                  anchors.centerIn: parent
                  spacing: ScalerService.s(6)
                  
                  Text {
                    visible: layoutCard.isCurrent
                    text: "✓"
                    color: theme.primary.background
                    font.pixelSize: ScalerService.s(13)
                    font.bold: true
                  }
                  
                  Text {
                    text: layoutCard.isCurrent
                      ? (lang?.dashboard?.already_applied || "Đang Dùng")
                      : (dashboardSettings.applyInProgress
                          ? (lang?.dashboard?.applying || "Đang Xử Lý...")
                          : (lang?.dashboard?.apply || "Áp Dụng"))
                    color: theme.primary.background
                    font.pixelSize: ScalerService.s(12)
                    font.bold: true
                  }
                }
              }
            }

            // Mouse Area cho toàn bộ Card
            MouseArea {
              id: cardMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: layoutCard.isCurrent ? Qt.ArrowCursor : Qt.PointingHandCursor

              onEntered: layoutCard.hovered = true
              onExited: layoutCard.hovered = false

              onClicked: {
                if (!layoutCard.isCurrent) {
                  dashboardSettings.applyLayout(layoutCard.layoutData);
                }
              }
            }
          }
        }
      }

      Item { Layout.fillHeight: true }
    }
  }

  // ==== THÔNG BÁO POPUP (FADE IN/OUT) ====
  Rectangle {
    id: successNotification
    opacity: 0
    visible: opacity > 0
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottomMargin: ScalerService.s(30)
    width: ScalerService.s(320)
    height: ScalerService.s(48)
    radius: height / 2
    color: theme.normal.green
    z: 1001

    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
    Behavior on anchors.bottomMargin { NumberAnimation { duration: 400; easing.type: Easing.OutBack } }

    Row {
      anchors.centerIn: parent
      spacing: ScalerService.s(12)
      
      Rectangle {
        width: ScalerService.s(26)
        height: ScalerService.s(26)
        radius: width / 2
        color: Qt.alpha(theme.primary.background, 0.25)
        
        Text {
          anchors.centerIn: parent
          text: "✓"
          color: theme.primary.background
          font.bold: true
          font.pixelSize: ScalerService.s(14)
        }
      }
      
      Text {
        id: notificationText
        color: theme.primary.background
        text: ""
        font.bold: true
        font.pixelSize: ScalerService.s(14)
      }
    }

    Timer {
      id: notificationTimer
      interval: 3500
      onTriggered: {
        successNotification.opacity = 0;
        successNotification.anchors.bottomMargin = ScalerService.s(10); // Hiệu ứng tụt xuống dần
      }
    }
  }

  function showNotification(message) {
    notificationText.text = message;
    successNotification.anchors.bottomMargin = ScalerService.s(45); // Hiệu ứng nảy lên
    successNotification.opacity = 1;
    notificationTimer.restart();
  }
}
