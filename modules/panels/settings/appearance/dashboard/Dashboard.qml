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
            return Quickshell.env ? (Quickshell.env("HOME") || "") : "";
        }
    }

    // ĐÃ RÚT GỌN TÊN CÁC LAYOUT
    property var layoutModel: [
        {
            key: "dwindle_default",
            name: lang?.dashboard?.dwindle_default_name || "Dwindle",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = false,\n\t},\n})",
            frames: [
                [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:1} ],
                [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:0.5} , {x:0.5,y:0.5,w:0.5,h:0.5} ]
            ]
        },
        {
            key: "master_left",
            name: lang?.dashboard?.master_left_name || "Master Left",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\tnew_status = \"slave\",\n\t\torientation = \"left\",\n\t\tmfact = 0.55,\n\t},\n})",
            frames: [
                [ {x:0,y:0,w:0.65,h:1} ],
                [ {x:0,y:0,w:0.65,h:1} , {x:0.65,y:0,w:0.35,h:0.5} , {x:0.65,y:0.5,w:0.35,h:0.5} ]
            ]
        },
        {
            key: "master_right",
            name: lang?.dashboard?.master_right_name || "Master Right",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\tnew_status = \"slave\",\n\t\torientation = \"right\",\n\t\tmfact = 0.65,\n\t},\n})",
            frames: [
                [ {x:0.35,y:0,w:0.65,h:1} ],
                [ {x:0.35,y:0,w:0.65,h:1} , {x:0,y:0,w:0.35,h:0.5} , {x:0,y:0.5,w:0.35,h:0.5} ]
            ]
        },
        {
            key: "master_center",
            name: lang?.dashboard?.master_center_name || "Center (Niri)",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"center\",\n\t\tmfact = 0.5,\n\t\tnew_status = \"slave\",\n\t},\n})",
            frames: [
                [ {x:0.25,y:0,w:0.5,h:1} ],
                [ {x:0,y:0,w:0.22,h:1} , {x:0.25,y:0,w:0.5,h:1} , {x:0.78,y:0,w:0.22,h:1} ]
            ]
        },
        {
            key: "niri_columns",
            name: lang?.dashboard?.niri_columns_name || "Columns",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpermanent_direction_override = true,\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t},\n})",
            frames: [
                [ {x:0,y:0,w:0.48,h:1} , {x:0.52,y:0,w:0.48,h:1} ],
                [ {x:0,y:0,w:0.23,h:1} , {x:0.26,y:0,w:0.23,h:1} , {x:0.52,y:0,w:0.23,h:1} , {x:0.78,y:0,w:0.22,h:1} ]
            ]
        },
        {
            key: "dwindle_snap",
            name: lang?.dashboard?.dwindle_snap_name || "Snap",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t\tforce_split = 2,\n\t},\n})",
            frames: [
                [ {x:0.02,y:0.02,w:0.96,h:0.96} ],
                [ {x:0,y:0,w:0.49,h:0.49} , {x:0.51,y:0,w:0.49,h:0.49} , {x:0,y:0.51,w:0.49,h:0.49} , {x:0.51,y:0.51,w:0.49,h:0.49} ]
            ]
        },
        {
            key: "dwindle_zorin",
            name: lang?.dashboard?.dwindle_zorin_name || "Smooth",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = true,\n\t\tdefault_split_ratio = 1.0,\n\t},\n})",
            frames: [
                [ {x:0.02,y:0.05,w:0.46,h:0.9} , {x:0.52,y:0.05,w:0.46,h:0.9} ],
                [ {x:0.02,y:0.05,w:0.3,h:0.9} , {x:0.35,y:0.05,w:0.3,h:0.9} , {x:0.68,y:0.05,w:0.3,h:0.9} ]
            ]
        },
        {
            key: "zorin_thirds",
            name: lang?.dashboard?.zorin_thirds_name || "Thirds",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = true,\n\t\tdefault_split_ratio = 0.9,\n\t\tforce_split = 0,\n\t},\n})",
            frames: [
                [ {x:0.03,y:0.05,w:0.94,h:0.9} ],
                [ {x:0.02,y:0.05,w:0.31,h:0.9} , {x:0.35,y:0.05,w:0.3,h:0.9} , {x:0.67,y:0.05,w:0.31,h:0.9} ]
            ]
        },
        {
            key: "master_top",
            name: lang?.dashboard?.master_top_name || "Master Top",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"top\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.5,\n\t},\n})",
            frames: [
                [ {x:0,y:0,w:1,h:0.6} ],
                [ {x:0,y:0,w:1,h:0.55} , {x:0,y:0.57,w:0.49,h:0.43} , {x:0.51,y:0.57,w:0.49,h:0.43} ]
            ]
        },
        {
            key: "master_bottom",
            name: lang?.dashboard?.master_bottom_name || "Master Bottom",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"bottom\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.6,\n\t},\n})",
            frames: [
                [ {x:0,y:0.4,w:1,h:0.6} ],
                [ {x:0,y:0.43,w:1,h:0.57} , {x:0,y:0,w:0.49,h:0.4} , {x:0.51,y:0,w:0.49,h:0.4} ]
            ]
        },
        {
            key: "dwindle_asymmetric",
            name: lang?.dashboard?.dwindle_asymmetric_name || "Asym Dwindle",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t\tsplit_bias = 1,\n\t},\n})",
            frames: [
                [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:1} ],
                [ {x:0,y:0,w:0.5,h:1} , {x:0.5,y:0,w:0.5,h:0.5} , {x:0.5,y:0.5,w:0.25,h:0.5} , {x:0.75,y:0.5,w:0.25,h:0.5} ]
            ]
        },
        {
            key: "master_stage",
            name: lang?.dashboard?.master_stage_name || "Stage",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"right\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.75,\n\t\tslave_count_for_center_master = 3,\n\t},\n})",
            frames: [
                [ {x:0.22,y:0.1,w:0.76,h:0.8} ],
                [ {x:0.22,y:0.1,w:0.76,h:0.8} , {x:0,y:0.05,w:0.14,h:0.24} , {x:0,y:0.32,w:0.14,h:0.24} , {x:0,y:0.59,w:0.14,h:0.24} ]
            ]
        },
        {
            key: "dwindle_pop",
            name: lang?.dashboard?.dwindle_pop_name || "Auto PopOS",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = false,\n\t\tdefault_split_ratio = 1.0,\n\t},\n})",
            frames: [
                [ {x:0.04,y:0.04,w:0.92,h:0.92} ],
                [ {x:0.04,y:0.04,w:0.44,h:0.92} , {x:0.52,y:0.04,w:0.44,h:0.44} , {x:0.52,y:0.52,w:0.44,h:0.44} ]
            ]
        },
        {
            key: "master_kde_quarter",
            name: lang?.dashboard?.master_kde_quarter_name || "Quadrant",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"top\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.55,\n\t\tslave_count_for_center_master = 2,\n\t},\n})",
            frames: [
                [ {x:0.03,y:0.03,w:0.94,h:0.94} ],
                [ {x:0,y:0,w:0.55,h:0.55} , {x:0.57,y:0,w:0.43,h:0.55} , {x:0,y:0.57,w:0.55,h:0.43} , {x:0.57,y:0.57,w:0.43,h:0.43} ]
            ]
        },
        {
            key: "spiral_fib",
            name: lang?.dashboard?.spiral_fib_name || "Fibonacci",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = true,\n\t\tdefault_split_ratio = 1.618,\n\t},\n})",
            frames: [
                [ {x:0.1,y:0.1,w:0.8,h:0.8} ],
                [ {x:0,y:0,w:0.618,h:1} , {x:0.618,y:0,w:0.382,h:0.382} , {x:0.618,y:0.382,w:0.191,h:0.618} , {x:0.809,y:0.382,w:0.191,h:0.309} , {x:0.809,y:0.691,w:0.191,h:0.309} ]
            ]
        },
        {
            key: "honeycomb_shift",
            name: lang?.dashboard?.honeycomb_shift_name || "Honeycomb",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"top\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.34,\n\t},\n})",
            floatPositioned: true,
            frames: [
                [ {x:0,y:0,w:1,h:0.5} , {x:0,y:0.5,w:1,h:0.5} ],
                [ {x:0,y:0,w:0.34,h:0.5} , {x:0.33,y:0.08,w:0.34,h:0.5} , {x:0.66,y:0,w:0.34,h:0.5} , {x:0.17,y:0.52,w:0.34,h:0.48} , {x:0.5,y:0.52,w:0.34,h:0.48} ]
            ]
        },
        {
            key: "diagonal_cascade",
            name: lang?.dashboard?.diagonal_cascade_name || "Cascade",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = false,\n\t\tsmart_split = false,\n\t\tsplit_bias = 2,\n\t},\n})",
            floatPositioned: true,
            frames: [
                [ {x:0.05,y:0.05,w:0.5,h:0.5} , {x:0.45,y:0.45,w:0.5,h:0.5} ],
                [ {x:0,y:0,w:0.4,h:0.4} , {x:0.2,y:0.2,w:0.4,h:0.4} , {x:0.4,y:0.4,w:0.4,h:0.4} , {x:0.6,y:0.6,w:0.4,h:0.4} ]
            ]
        },
        {
            key: "bento_mosaic",
            name: lang?.dashboard?.bento_mosaic_name || "Bento",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpreserve_split = true,\n\t\tsmart_split = false,\n\t\tforce_split = 1,\n\t},\n})",
            floatPositioned: true,
            frames: [
                [ {x:0,y:0,w:0.6,h:1} , {x:0.6,y:0,w:0.4,h:1} ],
                [ {x:0,y:0,w:0.6,h:0.6} , {x:0,y:0.6,w:0.3,h:0.4} , {x:0.3,y:0.6,w:0.3,h:0.4} , {x:0.6,y:0,w:0.4,h:0.35} , {x:0.6,y:0.35,w:0.4,h:0.65} ]
            ]
        },
        {
            key: "orbit_focus",
            name: lang?.dashboard?.orbit_focus_name || "Orbit",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"master\",\n\t},\n\tmaster = {\n\t\torientation = \"center\",\n\t\tnew_status = \"slave\",\n\t\tmfact = 0.5,\n\t},\n})",
            floatPositioned: true,
            frames: [
                [ {x:0.2,y:0.1,w:0.6,h:0.8} ],
                [ {x:0.25,y:0.15,w:0.5,h:0.7} , {x:0,y:0,w:0.22,h:0.3} , {x:0,y:0.7,w:0.22,h:0.3} , {x:0.78,y:0,w:0.22,h:0.3} , {x:0.78,y:0.7,w:0.22,h:0.3} ]
            ]
        },
        {
            key: "ribbon_flow",
            name: lang?.dashboard?.ribbon_flow_name || "Ribbon",
            hyprLua: "hl.config({\n\tgeneral = {\n\t\tlayout = \"dwindle\",\n\t},\n\tdwindle = {\n\t\tpermanent_direction_override = true,\n\t\tpreserve_split = false,\n\t},\n})",
            floatPositioned: true,
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
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            dashboardSettings.applyInProgress = false;
            if (exitCode === 0) {
                showNotification(lang?.dashboard?.success_apply || "Applied successfully!");
            } else {
                showNotification(lang?.dashboard?.error_apply || "Failed to apply!");
            }
        }
    }

    function applyLayout(layoutData) {
        if (dashboardSettings.applyInProgress) return;
        dashboardSettings.applyInProgress = true;

        var confDir = homePath + "/.config/hypr/custom/layout";
        var confFile = confDir + "/split-method.lua";

        var decorationAndAnim =
            "\n\nhl.config({\n\tdecoration = {\n\t\trounding = 12,\n\t\trounding_power = 2.5,\n\t\tactive_opacity = 1.0,\n\t\tinactive_opacity = 0.94,\n\t\tshadow = { enabled = true, range = 18, render_power = 3, color = \"rgba(00000055)\" },\n\t},\n})\n\n"
          + "hl.curve(\"dashboardBounce\", { type = \"spring\", mass = 1, stiffness = 170, dampening = 14 })\n"
          + "hl.curve(\"dashboardSmooth\", { type = \"bezier\", points = { {0.16, 1}, {0.3, 1} } })\n\n"
          + "hl.animation({ leaf = \"windowsIn\",   enabled = true, speed = 5, spring = \"dashboardBounce\", style = \"popin 80%\" })\n"
          + "hl.animation({ leaf = \"windowsOut\",  enabled = true, speed = 4, bezier = \"dashboardSmooth\", style = \"popin 80%\" })\n"
          + "hl.animation({ leaf = \"windowsMove\", enabled = true, speed = 5, spring = \"dashboardBounce\" })\n"
          + "hl.animation({ leaf = \"border\",      enabled = true, speed = 6, bezier = \"dashboardSmooth\" })\n"
          + "hl.animation({ leaf = \"fade\",        enabled = true, speed = 5, bezier = \"dashboardSmooth\" })\n"
          + "hl.animation({ leaf = \"workspaces\",  enabled = true, speed = 5, bezier = \"dashboardSmooth\", style = \"slide\" })\n";

        var retileBody =
            "for addr in $(hyprctl clients -j | grep -oE '\"address\":[[:space:]]*\"0x[0-9a-fA-F]+\"' | grep -oE '0x[0-9a-fA-F]+'); do "
          + "hyprctl dispatch focuswindow address:$addr >/dev/null 2>&1; "
          + "hyprctl dispatch togglefloating >/dev/null 2>&1; "
          + "hyprctl dispatch togglefloating >/dev/null 2>&1; "
          + "done; ";

        // Các layout dạng tự do (honeycomb/cascade/bento/orbit/ribbon) chồng lấn hoặc lệch góc
        // không thể tạo được chỉ bằng dwindle/master (chia nhị phân) -> kết hợp thêm bước
        // đặt floating + di chuyển/resize chính xác theo toạ độ preview (frames[0]), trong khi
        // general.layout vẫn giữ nguyên làm bố cục cứng cho các cửa sổ mở sau đó.
        if (layoutData.floatPositioned) {
            var frame = layoutData.frames[0];
            var placeBody =
                "mon_json=$(hyprctl monitors -j); "
              + "read -r mon_w mon_h <<< \"$(awk '"
              + "/\"width\":[[:space:]]*[0-9]+/ { match($0,/[0-9]+/); w=substr($0,RSTART,RLENGTH) } "
              + "/\"height\":[[:space:]]*[0-9]+/ { match($0,/[0-9]+/); h=substr($0,RSTART,RLENGTH) } "
              + "/\"focused\":[[:space:]]*true/ { print w, h; exit }"
              + "' <<< \"$mon_json\")\"; "
              + "if [ -z \"$mon_w\" ]; then "
              + "mon_w=$(echo \"$mon_json\" | grep -oE '\"width\":[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+'); "
              + "mon_h=$(echo \"$mon_json\" | grep -oE '\"height\":[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+'); "
              + "fi; "
              + "active_ws=$(hyprctl activeworkspace -j | grep -oE '\"id\":[[:space:]]*[0-9]+' | head -1 | grep -oE '[0-9]+'); "
              + "addrs=$(hyprctl clients -j | awk -v ws=\"$active_ws\" '"
              + "/\"address\":/ { match($0,/0x[0-9a-fA-F]+/); addr=substr($0,RSTART,RLENGTH) } "
              + "/\"workspace\":/ { inws=1 } "
              + "inws && /\"id\":/ { match($0,/[0-9]+/); wsid=substr($0,RSTART,RLENGTH); inws=0; if (wsid==ws) print addr }"
              + "'); "
              + "if [ -z \"$addrs\" ]; then "
              + "addrs=$(hyprctl clients -j | grep -oE '\"address\":[[:space:]]*\"0x[0-9a-fA-F]+\"' | grep -oE '0x[0-9a-fA-F]+'); "
              + "fi; ";

            for (var i = 0; i < frame.length; i++) {
                var f = frame[i];
                placeBody +=
                    "addr=$(echo \"$addrs\" | sed -n '" + (i + 1) + "p'); "
                  + "if [ -n \"$addr\" ] && [ -n \"$mon_w\" ]; then "
                  + "px=$(awk -v w=\"$mon_w\" 'BEGIN{printf \"%d\", w*" + f.x + "}'); "
                  + "py=$(awk -v h=\"$mon_h\" 'BEGIN{printf \"%d\", h*" + f.y + "}'); "
                  + "pw=$(awk -v w=\"$mon_w\" 'BEGIN{printf \"%d\", w*" + f.w + "}'); "
                  + "ph=$(awk -v h=\"$mon_h\" 'BEGIN{printf \"%d\", h*" + f.h + "}'); "
                  + "hyprctl dispatch focuswindow address:$addr >/dev/null 2>&1; "
                  + "hyprctl dispatch setfloating >/dev/null 2>&1; "
                  + "hyprctl dispatch movewindowpixel exact $px $py >/dev/null 2>&1; "
                  + "hyprctl dispatch resizewindowpixel exact $pw $ph >/dev/null 2>&1; "
                  + "fi; ";
            }

            retileBody = placeBody;
        }

        var script =
            "mkdir -p '" + confDir + "' && cat > '" + confFile + "' <<'EOF'\n"
          + layoutData.hyprLua + decorationAndAnim + "EOF\n"
          + "hyprctl reload; reload_status=$?; "
          + "if [ \"$reload_status\" -eq 0 ]; then "
          + retileBody
          + "fi; "
          + "exit \"$reload_status\"";

        applyLayoutProcess.command = ["bash", "-c", script];
        applyLayoutProcess.running = true;

        try { Settings.dashboard.splitMethod = layoutData.key; } catch (e) {}
        dashboardSettings.currentLayout = layoutData.key;
    }

    ListView {
        id: scrollView
        anchors.fill: parent
        clip: true
        anchors.margins: ScalerService.s(20)
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds
        focus: true
        model: 1

        delegate: ColumnLayout {
            id: mainLayout
            width: scrollView.width
            spacing: ScalerService.s(15)

            RowLayout {
                Layout.fillWidth: true
                spacing: ScalerService.s(10)
                Text {
                    text: lang?.dashboard?.title || "Hyprland Layouts"
                    color: theme.primary.foreground
                    font.pixelSize: ScalerService.s(24)
                    font.bold: true
                    font.family: "ComicShannsMono Nerd Font"
                }
                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                height: ScalerService.s(1)
                color: theme.primary.foreground
            }

            Text {
                Layout.fillWidth: true
                text: lang?.dashboard?.subtitle || "Hover to preview layout. Click to apply."
                color: theme.primary.dim_foreground
                font.pixelSize: ScalerService.s(13)
                font.family: "ComicShannsMono Nerd Font"
                wrapMode: Text.WordWrap
            }

            GridLayout {
                id: layoutGrid
                Layout.fillWidth: true
                columns: 3
                columnSpacing: ScalerService.s(10)
                rowSpacing: ScalerService.s(10)

                Repeater {
                    model: dashboardSettings.layoutModel

                    delegate: Rectangle {
                        id: layoutCard
                        Layout.fillWidth: true
                        Layout.minimumWidth: ScalerService.s(120)
                        Layout.preferredHeight: ScalerService.s(170)
                        radius: ScalerService.s(16) 
                        color: Qt.alpha(theme.button.background, 0.5)
                        border.color: cardMouseArea.containsMouse ? theme.normal.blue : theme.button.border
                        border.width: ScalerService.s(layoutCard.isCurrent ? 2 : 1)

                        property var layoutData: modelData
                        property bool isCurrent: dashboardSettings.currentLayout === modelData.key
                        property real animatedScale: 0.0 

                        scale: animatedScale * (cardMouseArea.containsMouse ? 1.04 : 1.0)
                        Behavior on scale {
                            NumberAnimation { 
                                duration: 350; 
                                easing.type: Easing.OutBack; 
                                easing.overshoot: 2.0 
                            }
                        }

                        Component.onCompleted: entranceTimer.start()
                        Timer {
                            id: entranceTimer
                            interval: index * 40
                            onTriggered: layoutCard.animatedScale = 1.0
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: ScalerService.s(12)
                            spacing: ScalerService.s(8)

                            Rectangle {
                                id: previewBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScalerService.s(85)
                                radius: ScalerService.s(10)
                                clip: true
                                color: Qt.alpha(theme.primary.background, 0.6)

                                property bool showExpanded: false

                                Timer {
                                    id: loopTimer
                                    interval: 2000
                                    repeat: true
                                    running: true
                                    onTriggered: previewBox.showExpanded = !previewBox.showExpanded
                                }

                                Repeater {
                                    model: Math.max(layoutCard.layoutData.frames[0].length, layoutCard.layoutData.frames[1].length)
                                    delegate: Rectangle {
                                        property var compactRect: index < layoutCard.layoutData.frames[0].length ? layoutCard.layoutData.frames[0][index] : layoutCard.layoutData.frames[0][layoutCard.layoutData.frames[0].length - 1]
                                        property var expandedRect: index < layoutCard.layoutData.frames[1].length ? layoutCard.layoutData.frames[1][index] : layoutCard.layoutData.frames[0][layoutCard.layoutData.frames[0].length - 1]

                                        property var targetRect: previewBox.showExpanded ? expandedRect : compactRect

                                        x: targetRect.x * previewBox.width + ScalerService.s(3)
                                        y: targetRect.y * previewBox.height + ScalerService.s(3)
                                        width: targetRect.w * previewBox.width - ScalerService.s(6)
                                        height: targetRect.h * previewBox.height - ScalerService.s(6)

                                        radius: ScalerService.s(6)
                                        color: layoutCard.isCurrent ? theme.normal.blue : theme.primary.foreground
                                        opacity: (index >= layoutCard.layoutData.frames[0].length && !previewBox.showExpanded) ? 0 : (layoutCard.isCurrent ? 0.75 : 0.35)

                                        Behavior on x { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                                        Behavior on y { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                                        Behavior on height { NumberAnimation { duration: 500; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }
                                        Behavior on opacity { NumberAnimation { duration: 300 } }
                                    }
                                }

                                Rectangle {
                                    visible: layoutCard.isCurrent
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: ScalerService.s(6)
                                    width: ScalerService.s(22)
                                    height: ScalerService.s(22)
                                    radius: ScalerService.s(11)
                                    color: theme.normal.green
                                    z: 5
                                    Text {
                                        text: "✓"
                                        color: theme.primary.background
                                        font.pixelSize: ScalerService.s(12)
                                        font.bold: true
                                        anchors.centerIn: parent
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: layoutCard.layoutData.name
                                color: theme.primary.foreground
                                font.pixelSize: ScalerService.s(14)
                                font.bold: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter 
                            }

                            Rectangle {
                                id: applyBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: ScalerService.s(32)
                                radius: height / 2 
                                color: layoutCard.isCurrent ? theme.normal.green : theme.normal.blue
                                opacity: (dashboardSettings.applyInProgress && !layoutCard.isCurrent) ? 0.5 : 1.0

                                Text {
                                    anchors.centerIn: parent
                                    text: layoutCard.isCurrent ? "✓ Applied" : (dashboardSettings.applyInProgress ? "Applying..." : "Apply")
                                    color: theme.primary.background
                                    font.pixelSize: ScalerService.s(12)
                                    font.bold: true
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouseArea
                            anchors.fill: parent
                            hoverEnabled: true

                            onEntered: {
                                loopTimer.stop();
                                previewBox.showExpanded = true;
                            }

                            onExited: {
                                previewBox.showExpanded = false;
                                loopTimer.start();
                            }

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

    Rectangle {
        id: successNotification
        visible: false
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: ScalerService.s(30)
        width: ScalerService.s(280)
        height: ScalerService.s(45)
        radius: height / 2 
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
                font.pixelSize: ScalerService.s(14)
            }
        }

        Timer {
            id: notificationTimer
            interval: 3500
            onTriggered: successNotification.visible = false
        }
    }

    function showNotification(message) {
        notificationText.text = message;
        successNotification.visible = true;
        notificationTimer.start();
    }
}