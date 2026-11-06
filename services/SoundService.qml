pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.commons

Singleton {
    function playSound(name, force) {
        if (!force && !Settings.behavior.soundEffects)
            return;
        if (clickProcess.running)
            return;   // tránh dồn nhiều tiến trình khi rê chuột nhanh
        const vol = Math.max(0, Math.min(1, Settings.behavior.soundVolume));
        clickProcess.command = ["pw-play", "--volume=" + vol.toFixed(2), Directories.assetsPath + "/sounds/" + name + ".wav"];
        clickProcess.running = true;
    }

    Process {
        id: clickProcess
        running: false
    }
}
