pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    // The application already ships a themed image/file browser. Keep one instance
    // at shell level because it is a PanelWindow, not a child visual Item.
    property var picker: null
    property bool openPending: false
    signal imageChosen(url fileUrl)

    function registerPicker(pickerObject) {
        if (!pickerObject)
            return;
        root.picker = pickerObject;
        root.picker.fileOpened.connect(function(fileUrl) {
            root.imageChosen(fileUrl);
        });
        if (root.openPending) {
            root.openPending = false;
            root.picker.show();
        }
    }

    function openImagePicker() {
        if (root.picker) {
            root.picker.show();
        } else {
            // A click during startup is queued until the shell's file browser is ready.
            root.openPending = true;
        }
    }
}
