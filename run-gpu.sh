#!/usr/bin/env bash
# Chạy Quickshell bằng GPU (nếu có). Đặt cạnh thư mục cấu hình n43, dùng thay lệnh `quickshell`.
# Bỏ mọi biến ép render phần mềm, bật render loop riêng (threaded) để đẩy việc vẽ ra khỏi luồng UI.
unset QT_QUICK_BACKEND LIBGL_ALWAYS_SOFTWARE QSG_RHI_PREFER_SOFTWARE_RENDERER GALLIUM_DRIVER LP_NUM_THREADS

if ls /dev/dri/renderD* >/dev/null 2>&1; then
  export QSG_RENDER_LOOP=threaded
  # Máy có 2 GPU (iGPU + dGPU): bỏ dấu # dòng dưới để dùng GPU rời
  # export DRI_PRIME=1
else
  echo "Không thấy GPU (/dev/dri/renderD*): kính lỏng sẽ tự tắt để khỏi tốn CPU." >&2
fi
exec quickshell "$@"
