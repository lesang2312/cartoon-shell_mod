pragma Singleton
import QtQuick
import Qt.labs.settings
import Quickshell

Singleton {
    id: root

    // Position ratios are normalized so layouts survive resolution changes.
    property var positions: ({})
    // Per-widget visibility preferences are persisted independently from temporary shell panels.
    property var widgetVisibility: ({})
    // Per-widget compact/minimized state, persisted alongside visibility and layout.
    property var widgetMinimized: ({})
    // Per-widget visual size multiplier (0.55x–1.35x), persisted across restarts.
    property var widgetScales: ({})
    property bool editMode: false
    // True only during an active drag; glass geometry tracking sleeps at all other times.
    property bool draggingWidget: false
    property string draggingWidgetId: ""

    onEditModeChanged: {
        if (!editMode) {
            draggingWidget = false;
            draggingWidgetId = "";
        }
    }

    property Settings store: Settings {
        category: "cartoon_shell_widget_layout"
        property string positionsJson: "{}"
        property string visibilityJson: "{}"
        property string minimizedJson: "{}"
        property string scalesJson: "{}"
        // One-time migration: ensure newly added widgets are visible and not stuck at old/offscreen positions.
        property bool notesPhotoWidgetRepairApplied: false
    }

    Component.onCompleted: {
        try {
            const parsedPositions = JSON.parse(store.positionsJson || "{}");
            root.positions = parsedPositions && typeof parsedPositions === "object" ? parsedPositions : {};
        } catch (error) {
            root.positions = {};
        }
        try {
            const parsedVisibility = JSON.parse(store.visibilityJson || "{}");
            root.widgetVisibility = parsedVisibility && typeof parsedVisibility === "object" ? parsedVisibility : {};
        } catch (error) {
            root.widgetVisibility = {};
        }
        try {
            const parsedMinimized = JSON.parse(store.minimizedJson || "{}");
            root.widgetMinimized = parsedMinimized && typeof parsedMinimized === "object" ? parsedMinimized : {};
        } catch (error) {
            root.widgetMinimized = {};
        }
        try {
            const parsedScales = JSON.parse(store.scalesJson || "{}");
            root.widgetScales = parsedScales && typeof parsedScales === "object" ? parsedScales : {};
        } catch (error) {
            root.widgetScales = {};
        }

        // Older runs may have saved these new widgets as hidden or placed with a zero-sized Loader.
        // Restore a known-visible first-run state once; afterwards the user's show/hide choices persist.
        if (!store.notesPhotoWidgetRepairApplied) {
            const migratedVisibility = Object.assign({}, root.widgetVisibility || {});
            migratedVisibility["sticky-note"] = true;
            migratedVisibility["photo-frame"] = true;
            root.widgetVisibility = migratedVisibility;
            store.visibilityJson = JSON.stringify(migratedVisibility);

            const migratedPositions = Object.assign({}, root.positions || {});
            delete migratedPositions["sticky-note"];
            delete migratedPositions["photo-frame"];
            root.positions = migratedPositions;
            store.positionsJson = JSON.stringify(migratedPositions);

            // Also clear a previously persisted compact state so both new widgets
            // appear full-sized after applying the repaired package once.
            const migratedMinimized = Object.assign({}, root.widgetMinimized || {});
            migratedMinimized["sticky-note"] = false;
            migratedMinimized["photo-frame"] = false;
            root.widgetMinimized = migratedMinimized;
            store.minimizedJson = JSON.stringify(migratedMinimized);
            store.notesPhotoWidgetRepairApplied = true;
        }
    }

    function savedRatio(widgetId, axis, fallback) {
        const entry = root.positions ? root.positions[widgetId] : null;
        const value = entry ? Number(entry[axis]) : NaN;
        return isFinite(value) ? value : fallback;
    }

    function xFor(widgetId, defaultRatio, screenWidth, widgetWidth) {
        if (screenWidth <= 0)
            return 0;
        const ratio = root.savedRatio(widgetId, "x", defaultRatio);
        const maxX = Math.max(0, screenWidth - Math.max(0, widgetWidth));
        return Math.max(0, Math.min(maxX, ratio * screenWidth));
    }

    function yFor(widgetId, defaultRatio, screenHeight, widgetHeight) {
        if (screenHeight <= 0)
            return 0;
        const ratio = root.savedRatio(widgetId, "y", defaultRatio);
        const maxY = Math.max(0, screenHeight - Math.max(0, widgetHeight));
        return Math.max(0, Math.min(maxY, ratio * screenHeight));
    }

    function moveWidget(widgetId, pixelX, pixelY, screenWidth, screenHeight, widgetWidth, widgetHeight) {
        if (screenWidth <= 0 || screenHeight <= 0 || !widgetId)
            return;
        const maxX = Math.max(0, screenWidth - Math.max(0, widgetWidth));
        const maxY = Math.max(0, screenHeight - Math.max(0, widgetHeight));
        const safeX = Math.max(0, Math.min(maxX, pixelX));
        const safeY = Math.max(0, Math.min(maxY, pixelY));
        const next = Object.assign({}, root.positions || {});
        next[widgetId] = { x: safeX / screenWidth, y: safeY / screenHeight };
        root.positions = next;
    }

    function isWidgetVisible(widgetId) {
        const visibility = root.widgetVisibility || {};
        return visibility[widgetId] !== false;
    }

    function setWidgetVisible(widgetId, isVisible) {
        if (!widgetId)
            return;
        const next = Object.assign({}, root.widgetVisibility || {});
        next[widgetId] = Boolean(isVisible);
        root.widgetVisibility = next;
        store.visibilityJson = JSON.stringify(next);
    }

    function toggleWidgetVisible(widgetId) {
        setWidgetVisible(widgetId, !isWidgetVisible(widgetId));
    }

    function isWidgetMinimized(widgetId) {
        const minimized = root.widgetMinimized || {};
        return minimized[widgetId] === true;
    }

    function setWidgetMinimized(widgetId, isMinimized) {
        if (!widgetId)
            return;
        const next = Object.assign({}, root.widgetMinimized || {});
        next[widgetId] = Boolean(isMinimized);
        root.widgetMinimized = next;
        store.minimizedJson = JSON.stringify(next);
    }

    function toggleWidgetMinimized(widgetId) {
        setWidgetMinimized(widgetId, !isWidgetMinimized(widgetId));
    }

    // Real size adjustment: the widget content is scaled, not merely collapsed.
    function widgetScale(widgetId) {
        const value = Number((root.widgetScales || {})[widgetId]);
        if (!isFinite(value) || value <= 0)
            return 1.0;
        return Math.max(0.55, Math.min(1.35, value));
    }

    function setWidgetScale(widgetId, value) {
        if (!widgetId)
            return;
        const next = Object.assign({}, root.widgetScales || {});
        next[widgetId] = Math.max(0.55, Math.min(1.35, Number(value) || 1.0));
        root.widgetScales = next;
        store.scalesJson = JSON.stringify(next);
    }

    function adjustWidgetScale(widgetId, delta) {
        setWidgetScale(widgetId, widgetScale(widgetId) + Number(delta));
    }

    function setAllWidgetsVisible(isVisible, widgetIds) {
        const next = Object.assign({}, root.widgetVisibility || {});
        for (let i = 0; i < widgetIds.length; i++)
            next[widgetIds[i]] = Boolean(isVisible);
        root.widgetVisibility = next;
        store.visibilityJson = JSON.stringify(next);
    }

    function save() {
        store.positionsJson = JSON.stringify(root.positions || {});
        store.visibilityJson = JSON.stringify(root.widgetVisibility || {});
        store.minimizedJson = JSON.stringify(root.widgetMinimized || {});
        store.scalesJson = JSON.stringify(root.widgetScales || {});
    }

    function resetPositions() {
        root.positions = {};
        store.positionsJson = "{}";
    }
}
