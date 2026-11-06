#!/usr/bin/env bash
# Chép shader kính lỏng của quickshell (Serpantinum) sang n43.
# Dùng:  ./install_quickshell_shader.sh /đường/dẫn/quickshell-dir  [/đường/dẫn/n43]
# Mặc định: $SERPANTINUM_DIR và thư mục chứa script này.
SRC_ROOT="${1:-$SERPANTINUM_DIR}"
N43="${2:-$(cd "$(dirname "$0")" && pwd)}"
SRC="$SRC_ROOT/assets/shaders/effects/liquid_glass.frag.qsb"
if [ ! -f "$SRC" ]; then
  echo "Không thấy $SRC"; echo "Tìm thử:"; find "$HOME" -name liquid_glass.frag.qsb 2>/dev/null | head; exit 1
fi
mkdir -p "$N43/shaders/qsb"
cp -v "$SRC" "$N43/shaders/qsb/liquid_glass_quickshell.frag.qsb"
echo "Xong. Khởi động lại Quickshell."
