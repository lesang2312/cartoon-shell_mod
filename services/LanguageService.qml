pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
  id: root

  // ===============================
  // Paths
  // ===============================
  readonly property string languagesDir: Quickshell.shellDir + "/assets/i18n"
  readonly property string fallbackLang: "en"

  // ===============================
  // State
  // ===============================
  property string currentLanguage: Settings.general.lang || fallbackLang
  property var translations: ({})
  property bool loading: false

  signal languageChanged(string lang)

  // ===============================
  // Init
  // ===============================
  function init() {
    loadLanguage(currentLanguage);
  }

  // ===============================
  // Load language
  // ===============================
  function loadLanguage(lang) {
    if (!lang || lang === "")
    lang = fallbackLang;

    root.loading = true;
    root.currentLanguage = lang;

    const path = languagesDir + "/" + lang + ".json";
    languageReader.path = "";
    languageReader.path = path;
  }

  // ===============================
  // Change language (public API)
  // ===============================
  function changeLanguage(newLang) {
    if (newLang === currentLanguage)
    return translations;

    Settings.general.lang = newLang;
    loadLanguage(newLang);
    return translations;
  }

  // ===============================
  // Shared fallback catalog for UI sections that were not present in older
  // locale files. A translated locale value always takes priority.
  // ===============================
  readonly property var fallbackTranslations: ({
    network: {
      title: "Network", connection_status: "Connection status", airplane_active: "Airplane mode is on",
      disconnected: "No network connection", internet_connected: "Connected to the Internet", captive_portal: "Sign-in required for this network",
      limited_connection: "Limited connection (no Internet)", connected: "Connected", no_connection: "No connection",
      download: "Download", upload: "Upload", latency: "Latency", error: "Error", quick_connection: "Quick connection",
      wifi_on_desc: "On — scanning for nearby networks", wifi_off_desc: "Off", airplane_mode: "Airplane mode",
      airplane_desc: "Turn off Wi-Fi and Bluetooth", wifi_networks: "Nearby Wi-Fi networks", scanning: "Scanning networks…",
      no_wifi: "No Wi-Fi networks found", dns_title: "DNS servers", dns_for_connection: "Applied to connection",
      current_dns: "Current DNS", unknown: "Unknown", dns_auto: "Automatic", dns_google: "Google",
      dns_cloudflare: "Cloudflare", dns_adguard: "AdGuard", custom_dns: "Custom DNS", custom_dns_hint: "Enter one or two IPv4 DNS addresses.",
      dns_primary_placeholder: "Primary · 1.1.1.1", dns_secondary_placeholder: "Secondary · 1.0.0.1", apply_custom_dns: "Apply custom DNS",
      dns_need_connection: "Connect to a network before changing DNS.", dns_invalid: "Enter valid IPv4 addresses for DNS.",
      dns_failed: "DNS update failed — check permissions or NetworkManager.", dns_applied: "✓ DNS settings updated",
      dns_reconnect_failed: "DNS saved, but reconnecting failed.", connection_details: "Connection details", interface: "Interface",
      ipv4_address: "IPv4 address", gateway: "Gateway", mac_address: "MAC address", network_tools: "Network tools",
      ping_test: "Check latency", refresh: "Refresh", restart_network: "Restart network", connection_editor: "Connection editor",
      network_restarted: "✓ Network restarted", network_restart_failed: "Network restart failed", wifi_toggle_failed: "Could not change Wi-Fi state",
      editor_unavailable: "Network editor and nmtui are not installed"
    },
    performance: {
      title: "Performance", current_profile: "Current power profile", power_saver: "Power saver", power_saver_desc: "Lower power use",
      balanced: "Balanced", balanced_desc: "Everyday use", performance: "High performance", performance_desc: "Maximum responsiveness",
      profiles_unavailable: "power-profiles-daemon is not installed. Install it to change power profiles.",
      saver_mode: "One-touch power saver", saver_mode_desc: "Power saver profile + disable animations, blur, shadows and Liquid Glass.",
      visual_effects: "Visual effects", effects_title: "Animations, blur and shadows", effects_desc: "Turn off to reduce GPU load.",
      liquid_glass: "Liquid Glass", glass_desc: "The glass shader can use more GPU. Turn it off to reduce rendering load.",
      enabled: "Enabled", disabled: "Disabled"
    },
    icons: {
      title: "Icon Settings", style: "Icon style", cute: "Cute", cute_desc: "Soft illustrated icons and playful details",
      anime: "Anime", anime_desc: "Character icons for a more personal look", minimal: "Minimal", minimal_desc: "Clean system symbols",
      workspace_icons: "Workspace icons", choose_workspace_icon: "Choose a character for your workspaces",
      selected: "Selected", system_stats: "System stats", image_style: "Illustrated", symbol_style: "Symbols"
    },
    update: {
      title: "Cartoon Shell update", current: "Installed version", latest: "Latest version", unknown: "unknown",
      check: "Check for updates", checking: "Checking…", update_now: "Update now", updating: "Updating…",
      reload: "Reload shell", up_to_date: "You are on the latest version", available: "A new update is available",
      baseline: "Current version recorded as the baseline. You will be notified when a newer one appears.",
      done: "Update finished! Press \"Reload shell\" to apply it.", auto_check: "Check for updates automatically",
      auto_check_desc: "Checks at startup and every 2 hours, and shows a notification when an update is available.",
      notify_title: "Cartoon Shell has a new update", notify_body: "Open Settings → System to update.",
      backup: "Backup", err_network: "Could not reach GitHub.", err_git_conflict: "Local changes conflict with the update. Run git pull/stash yourself.",
      err_download: "Downloading the update failed.", err_backup: "Could not create a backup, aborted to stay safe.",
      err_generic: "Update failed.", err_stale_remote: "The repository changed after the check. Check for updates again.",
      err_local_changes: "This Git folder has local changes. Save, commit, or stash them before updating.", step_fetch: "Fetching…", step_merge: "Merging changes…", step_backup: "Backing up…",
      step_download: "Downloading…", step_extract: "Extracting…", step_install: "Installing…"
    },
    autotr: {
      title: "Auto-translate interface", desc: "Translates all text into the selected language, even strings missing from the bundled translations. Results are cached on this device.",
      translating: "Translating…", cached: "Translated strings", translate_all: "Translate everything now", clear: "Clear translation cache",
      err_network: "Could not reach the translation service. Will retry automatically.", err_python: "python3 is required for auto-translate.", err_generic: "Translation failed."
    },
    shortcuts: {
      title: "Hyprland Shortcuts", help: "Select a shortcut to edit it. Press a key combination; Esc cancels.",
      conflict_title: "Shortcut conflict", conflict_message: "The key combination is already assigned to:",
      overwrite_question: "Do you want to replace the existing shortcut?", cancel: "Cancel", overwrite: "Overwrite",
      add_new: "Add new shortcut", configure_new: "Configure new shortcut", action_name: "Action name (e.g. Open Firefox):",
      action_placeholder: "Action name…", command: "Command / app executable:", command_placeholder: "e.g. firefox",
      assign_key: "Assign shortcut (optional):", capture_hint: "Click to assign; Esc to skip",
      key_conflict: "This key is already assigned to: ", run_terminal: "Run in Kitty terminal — for CLI commands such as htop",
      save: "Save", required_fields: "Enter both an action name and a command."
    }
  })

  // Bản tiếng Việt cho các mục chưa có trong file locale (chỉ dùng khi ngôn ngữ = vi)
  readonly property var fallbackTranslationsVi: ({
    update: {
      title: "Cập nhật Cartoon Shell", current: "Phiên bản đang dùng", latest: "Phiên bản mới nhất", unknown: "chưa rõ",
      check: "Kiểm tra cập nhật", checking: "Đang kiểm tra…", update_now: "Cập nhật ngay", updating: "Đang cập nhật…",
      reload: "Tải lại shell", up_to_date: "Bạn đang dùng bản mới nhất", available: "Có bản cập nhật mới",
      baseline: "Đã ghi nhận phiên bản hiện tại làm mốc. Lần sau có bản mới sẽ báo ngay.",
      done: "Cập nhật xong! Bấm \"Tải lại shell\" để áp dụng.", auto_check: "Tự kiểm tra cập nhật",
      auto_check_desc: "Kiểm tra khi khởi động và mỗi 2 giờ, có bản mới sẽ hiện thông báo.",
      notify_title: "Cartoon Shell có bản cập nhật mới", notify_body: "Vào Cài đặt → Hệ thống để cập nhật.",
      backup: "Bản sao lưu", err_network: "Không kết nối được tới GitHub.", err_git_conflict: "Bạn có thay đổi cục bộ xung đột với bản mới. Hãy tự git pull/stash.",
      err_download: "Tải bản cập nhật thất bại.", err_backup: "Không tạo được bản sao lưu, đã hủy để an toàn.",
      err_generic: "Cập nhật thất bại.", err_stale_remote: "Repo vừa thay đổi sau lần kiểm tra. Hãy kiểm tra cập nhật lại.",
      err_local_changes: "Thư mục có thay đổi cục bộ. Hãy sao lưu/commit hoặc stash các thay đổi rồi cập nhật lại.",
      step_fetch: "Đang lấy dữ liệu…", step_merge: "Đang gộp thay đổi…", step_backup: "Đang sao lưu…",
      step_download: "Đang tải về…", step_extract: "Đang giải nén…", step_install: "Đang cài đặt…"
    },
    autotr: {
      title: "Tự động dịch giao diện", desc: "Dịch mọi chữ sang ngôn ngữ đang chọn, kể cả chữ chưa có trong bản dịch. Kết quả được lưu lại trên máy.",
      translating: "Đang dịch…", cached: "Số chuỗi đã dịch", translate_all: "Dịch toàn bộ ngay", clear: "Xóa bộ nhớ dịch",
      err_network: "Không kết nối được dịch vụ dịch. Sẽ tự thử lại sau.", err_python: "Cần cài python3 để dịch tự động.", err_generic: "Dịch thất bại."
    }
  })

  // ===============================
  // Translation helper
  // ===============================
  function t(section, key) {
    const local = translations?.[section]?.[key];
    if (local !== undefined && local !== null && local !== "") return local;
    if (currentLanguage === "vi") {
      const vi = fallbackTranslationsVi?.[section]?.[key];
      if (vi !== undefined) return vi;
    }
    const fallback = fallbackTranslations?.[section]?.[key];
    // Chưa có bản dịch cho ngôn ngữ này: dịch tự động từ chuỗi gốc tiếng Anh
    return fallback !== undefined ? AutoTranslateService.t(fallback) : key;
  }

  // ===============================
  // Fallback language
  // ===============================
  function getFallbackLanguage() {
    return {
      "settings": {
        "title": "Settings",
        "general": "General",
        "appearance": "Appearance",
        "network": "Network",
        "audio": "Audio",
        "performance": "Performance",
        "shortcuts": "Shortcuts",
        "system": "System"
      },
      "network": fallbackTranslations.network,
      "performance": fallbackTranslations.performance,
      "icons": fallbackTranslations.icons,
      "shortcuts": fallbackTranslations.shortcuts
    };
  }

  // ===============================
  // File loader
  // ===============================
  FileView {
    id: languageReader
    watchChanges: true

    onLoaded: {
      try {
        const jsonText = text();
        if (!jsonText || jsonText === "") {
          throw "Empty language file";
        }

        root.translations = JSON.parse(jsonText);
      } catch (e) {
        console.error("Language parse error:", e);
        root.translations = getFallbackLanguage();
      }

      root.loading = false;
      languageChanged(root.currentLanguage);
    }

    onLoadFailed: error => {
      root.translations = getFallbackLanguage();
      root.loading = false;
      languageChanged(root.currentLanguage);
    }
  }

  // ===============================
  // React to Settings change
  // ===============================
  Connections {
    target: Settings.general

    function onLangChanged() {
      Qt.callLater(function () {
          loadLanguage(Settings.general.lang);
      });
    }
  }
}
