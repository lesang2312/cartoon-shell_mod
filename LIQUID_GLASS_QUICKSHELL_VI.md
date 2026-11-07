# Liquid Glass n43 giống quickshell

Ghi đè 4 file vào thư mục cấu hình n43 rồi khởi động lại Quickshell:
- services/GlassService.qml
- components/LiquidGlass.qml
- components/GlassBackdrop.qml
- components/GlassFill.qml

Thông số khớp quickshell: ior 1.5, dispersion 0.11, frost 2.7, rim 0.45, saturation 1.25,
bezel = clamp(min(w,h)*0.36, 5, 26), thickness = bezel*1.15, tint 0.12.
Bỏ hai lớp highlight/viền phụ của n43; thêm uniform `unpremul`, `fillet` như quickshell.
Chỉnh nhanh: các giá trị nằm ở đầu GlassService.qml.
