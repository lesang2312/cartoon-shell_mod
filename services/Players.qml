pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
  id: root

  // Ưu tiên ứng dụng đang phát nhạc; không mặc định lấy phần tử đầu tiên vì
  // danh sách MPRIS có thể chứa player đã dừng/đang rảnh đứng trước player thật.
  readonly property var mprisPlayer: {
    const available = Mpris.players.values || [];
    for (let i = 0; i < available.length; i++) {
      const candidate = available[i];
      if (candidate && candidate.isPlaying)
        return candidate;
    }
    for (let i = 0; i < available.length; i++) {
      const candidate = available[i];
      if (candidate && candidate.trackTitle)
        return candidate;
    }
    return available.length > 0 ? available[0] : null;
  }

  function getArtUrl(player: MprisPlayer): string {
    if (!player)
    return "";
    if (player.trackArtUrl)
    return player.trackArtUrl;

    const metadata = player.metadata || {};
    const url = metadata["xesam:url"] ?? "";
    if (url.startsWith("https://www.youtube.com/watch")) {
      // Fallback for youtube
      const id = url.match(/[?&]v=([\w-]{11})/)?.[1];
      return id ? `https://img.youtube.com/vi/${id}/hqdefault.jpg` : "";
    }
    return "";
  }
  function getProgress() {
    if (!root.mprisPlayer)
    return 0

    var pos = root.mprisPlayer.position ?? 0
    var len = root.mprisPlayer.length ?? 0

    if (len <= 0 || pos < 0)
    return 0

    var progress = pos / len

    return Math.max(0, Math.min(1, progress))
  }

  function formatTime(seconds) {
    if (isNaN(seconds) || seconds < 0)
    return "00:00"

    var totalSeconds = Math.floor(seconds)
    var minutes = Math.floor(totalSeconds / 60)
    var secs = totalSeconds % 60

    function pad(n) {
      return n < 10 ? "0" + n : n
    }

    return pad(minutes) + ":" + pad(secs)
  }

  function getIdentity(player): string {
    return player ? String(player.identity || player.desktopEntry || "Media player") : "No active player";
  }

  function getActive(prop: string): string {
    const active = root.mprisPlayer;
    return active ? String(active[prop] ?? "Invalid property") : "No active player";
  }

  function list(): string {
    const available = Mpris.players.values || [];
    return available.map(player => root.getIdentity(player)).join("\n");
  }

  function play(): void {
    const active = root.mprisPlayer;
    if (active?.canPlay)
      active.play();
  }

  function pause(): void {
    const active = root.mprisPlayer;
    if (active?.canPause)
      active.pause();
  }

  function playPause(): void {
    const active = root.mprisPlayer;
    if (active?.canTogglePlaying)
    active.togglePlaying();
  }

  function previous(): void {
    const active = root.mprisPlayer;
    if (active?.canGoPrevious)
    active.previous();
  }

  function next(): void {
    const active = root.mprisPlayer;
    if (!active) {
      console.warn("Cannot go next: no active player");
      return;
    }
    if (active.canGoNext === true) {
      active.next();
    } else {
      console.warn("Cannot go next: canGoNext is false");
    }
  }

  function stop(): void {
    const active = root.mprisPlayer;
    if (active && typeof active.stop === "function")
      active.stop();
  }

}
