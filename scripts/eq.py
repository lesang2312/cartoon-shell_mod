#!/usr/bin/env python3
"""Equalizer 10 băng tần cho cartoon-shell, dùng PipeWire filter-chain (builtin bq_peaking).

  eq.py apply <enabled 0|1> g1 g2 ... g10     (g = dB, -12..12)

Yêu cầu: pipewire, pw-cli, pw-dump, pactl (pipewire-pulse).
Khi bật: chạy một tiến trình `pipewire -c <conf>` tạo sink ảo "Cartoon Equalizer"
(node.name = cartoon_eq_input) và đặt nó làm sink mặc định; lưu sink cũ để khôi phục khi tắt.
"""
import json, os, subprocess, sys, time, signal

FREQS = [31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
NODE = "cartoon_eq_input"
CACHE = os.path.expanduser("~/.cache/cartoon-shell")
CONF = os.path.join(CACHE, "cartoon-eq.conf")
PID = os.path.join(CACHE, "cartoon-eq.pid")
PREV = os.path.join(CACHE, "cartoon-eq.prev-sink")
LOG = os.path.join(CACHE, "cartoon-eq.log")


def run(*a):
    return subprocess.run(a, capture_output=True, text=True)


def write_conf(gains):
    nodes, links = [], []
    for i, (f, g) in enumerate(zip(FREQS, gains), 1):
        nodes.append('{ type = builtin name = eq_band_%d label = bq_peaking '
                     'control = { "Freq" = %d "Q" = 1.1 "Gain" = %.1f } }' % (i, f, g))
        if i > 1:
            links.append('{ output = "eq_band_%d:Out" input = "eq_band_%d:In" }' % (i - 1, i))
    conf = """context.properties = { }
context.spa-libs = {
  audio.convert.* = audioconvert/libspa-audioconvert
  support.*       = support/libspa-support
}
context.modules = [
  { name = libpipewire-module-rt
    args = { nice.level = -11 }
    flags = [ ifexists nofail ] }
  { name = libpipewire-module-protocol-native }
  { name = libpipewire-module-client-node }
  { name = libpipewire-module-adapter }
  { name = libpipewire-module-filter-chain
    args = {
      node.description = "Cartoon Equalizer"
      media.name = "Cartoon Equalizer"
      filter.graph = {
        nodes = [ %s ]
        links = [ %s ]
        inputs = [ "eq_band_1:In" ]
        outputs = [ "eq_band_10:Out" ]
      }
      audio.channels = 2
      audio.position = [ FL FR ]
      capture.props = { node.name = "%s" media.class = Audio/Sink }
      playback.props = { node.name = "cartoon_eq_output" node.passive = true }
    }
  }
]
""" % ("\n          ".join(nodes), "\n          ".join(links), NODE)
    os.makedirs(CACHE, exist_ok=True)
    open(CONF, "w").write(conf)


def daemon_pid():
    try:
        pid = int(open(PID).read().strip())
        os.kill(pid, 0)
        return pid
    except Exception:
        return None


def node_id():
    out = run("pw-dump").stdout
    try:
        for o in json.loads(out):
            if o.get("type") == "PipeWire:Interface:Node":
                if (o.get("info", {}).get("props", {}) or {}).get("node.name") == NODE:
                    return o["id"]
    except Exception:
        pass
    return None


def wait_node(timeout=4.0):
    end = time.time() + timeout
    while time.time() < end:
        nid = node_id()
        if nid is not None:
            return nid
        time.sleep(0.2)
    return None


def set_gains(nid, gains):
    params = " ".join('"eq_band_%d:Gain" %.1f' % (i, g) for i, g in enumerate(gains, 1))
    return run("pw-cli", "s", str(nid), "Props", "{ params = [ %s ] }" % params)


def start(gains):
    write_conf(gains)
    if daemon_pid() is None:
        cur = run("pactl", "get-default-sink").stdout.strip()
        if cur and cur != NODE:
            open(PREV, "w").write(cur)
        os.makedirs(CACHE, exist_ok=True)
        try:
            lf = open(LOG, "w")
            p = subprocess.Popen(["pipewire", "-c", CONF], stdout=lf,
                                 stderr=lf, start_new_session=True)
        except FileNotFoundError:
            print("error: không tìm thấy lệnh `pipewire`")
            return 1
        open(PID, "w").write(str(p.pid))
    nid = wait_node(6.0)
    if nid is None:
        tail = ""
        try:
            tail = " | ".join([l.strip() for l in open(LOG).read().splitlines() if l.strip()][-3:])
        except Exception:
            pass
        print("error: không tạo được sink Cartoon Equalizer. " + (tail or "xem " + LOG))
        return 1
    set_gains(nid, gains)
    run("pactl", "set-default-sink", NODE)
    return 0


def stop():
    pid = daemon_pid()
    if pid:
        try:
            os.kill(pid, signal.SIGTERM)
        except Exception:
            pass
        try:
            os.remove(PID)
        except Exception:
            pass
    try:
        prev = open(PREV).read().strip()
        if prev:
            run("pactl", "set-default-sink", prev)
    except Exception:
        pass
    return 0


def main():
    if len(sys.argv) < 3 or sys.argv[1] != "apply":
        print(__doc__)
        return 2
    enabled = sys.argv[2] == "1"
    gains = [max(-12.0, min(12.0, float(x))) for x in sys.argv[3:13]]
    gains += [0.0] * (10 - len(gains))
    return start(gains) if enabled else stop()


if __name__ == "__main__":
    sys.exit(main())
