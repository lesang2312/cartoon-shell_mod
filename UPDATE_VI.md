# Thông báo & nút cập nhật

- **Nút**: Cài đặt → Hệ thống → thẻ "Cập nhật Cartoon Shell" (Kiểm tra / Cập nhật ngay / Tải lại shell, công tắc tự kiểm tra).
- **Thông báo**: sau khi shell chạy 20 giây rồi mỗi 2 giờ, nếu GitHub (`lesang2312/cartoon-shell_mod`, nhánh mặc định) có commit mới thì hiện popup 1 lần cho mỗi commit; đồng thời có chấm đỏ ở nút **Cài đặt** (menu trái) và mục **Hệ thống**.
- **Cách hoạt động**: `scripts/update.sh` so mã commit.
  - Thư mục shell là git clone → `git merge --ff-only` (không đè thay đổi cục bộ).
  - Không phải git → tải tarball đúng commit, **sao lưu** vào `~/.cache/cartoon-shell/backups/` (giữ 3 bản), rồi chép đè; mã commit lưu ở `.installed_commit`.
  - Repo kèm sẵn `VERSION` (số phiên bản hiển thị) và `.installed_commit` (mốc commit đã cài).
  - Với bản Git, phiên bản hiển thị được đọc từ `VERSION` trong `HEAD`; với bản không có Git, đọc file `VERSION` tại thư mục cài đặt.
  - Khi không biết SHA đang cài, updater không tự ghi nhận commit mới nhất làm mốc nữa; nó sẽ đề xuất cài lại snapshot đã xác minh.
  - Version trên GitHub được đọc theo đúng SHA đang kiểm tra, không đọc theo tên nhánh đang có thể thay đổi.
  - Nếu bản Git có thay đổi cục bộ, updater giữ nguyên và báo lỗi rõ ràng thay vì ghi đè.
- Thử tay: `bash scripts/update.sh check` / `bash scripts/update.sh apply`.

## Đóng băng tác vụ không dùng (giảm CPU/GPU)
- Kiểm tra update: 20 giây sau khi khởi động, rồi mỗi **2 giờ** (không có gì khác chạy nền cho update).
- Shader chuyển cảnh hình nền chỉ tồn tại trong lúc đổi hình nền; đứng yên thì không vẽ.
- Quét Wi-Fi (`nmcli`) chỉ chạy khi đang mở bảng Wi-Fi / Quick settings / Cài đặt; nền chỉ đọc trạng thái mỗi 60 giây.
- Thăm dò mạng ở thanh: 5s/8s -> 20s/30s. Đăng ký lại bind clipboard: 15s -> 120s.
- Đĩa xoay album chỉ quay khi đang phát nhạc và đang hiện.

## Dịch tự động toàn bộ giao diện
- `AutoTranslateService.t("...")` dịch chữ sang ngôn ngữ đang chọn (tự nhận ngôn ngữ nguồn nên vi/en lẫn lộn đều về một ngôn ngữ). Chưa có bản dịch thì hiện chữ gốc, vài giây sau tự đổi.
- `CustomText`, `ButtonText`, `HeaderSettings` tự dịch `name`; các chuỗi `text/title/desc/label...` đã được bọc sẵn (`tools/i18n/wrap.py`, chạy lại được, không đụng icon/đối số hàm/so sánh).
- Bản dịch lưu ở `~/.cache/cartoon-shell/i18n/auto_<lang>.json` (không bị mất khi update). Nguồn dịch: Google Translate web, cần mạng lần đầu; lỗi mạng thì thử lại sau 10 phút.
- Cài đặt → Chung → Ngôn ngữ & khu vực: công tắc bật/tắt, nút **Dịch toàn bộ ngay**, nút xóa cache.
- Thêm chữ mới: cứ viết bình thường (`CustomText { name: "..." }`); chạy `python3 tools/i18n/wrap.py` để bọc các prop khác và `python3 tools/i18n/extract.py` để cập nhật danh mục.

## Cách kiểm tra và cập nhật phiên bản
- Nguồn sự thật là **commit SHA của nhánh mặc định GitHub**. Script tự đọc tên nhánh mặc định (hiện tại là `cartoon-beta`) và SHA của chính nhánh đó; không hard-code `main`/`master`.
- `VERSION` chỉ dùng để hiển thị số phiên bản. Không dùng phép so sánh số version để quyết định có bản cập nhật hay không, vì commit mới có thể được push mà số version chưa đổi.
- Khi bấm cập nhật, script lấy đúng nhánh vừa kiểm tra và xác minh SHA tải về vẫn trùng với SHA đã hiển thị. Nếu repo đổi giữa hai thao tác, cập nhật bị dừng và yêu cầu kiểm tra lại thay vì tải nhầm commit.
- Bản cài Git dùng `git merge --ff-only`, không ghi đè thay đổi cục bộ. Bản không có Git tải tarball theo SHA chính xác, sao lưu trước, rồi ghi SHA đã cài vào `.installed_commit`.
- Nếu không xác định được commit hiện tại của bản cài, updater sẽ đề xuất cài lại snapshot mới nhất thay vì âm thầm báo đã mới nhất.
- Kiểm tra tay: `bash scripts/update.sh check`; cập nhật tay: `bash scripts/update.sh apply`.

## Sửa Dashboard & dịch (bổ sung)
- Card nhạc trong Dashboard cao theo nội dung thật, nền đặc + viền giống các card khác (trước đây bị ép 250px nên thanh tua và nút điều khiển bị các ô bên dưới che).
- Số đứng đầu/cuối chuỗi được tách ra ("14 minutes" chỉ dịch chữ "minutes"); mô tả thời tiết từ API cũng được dịch.
- Lần đầu mỗi ngôn ngữ, shell tự dịch cả danh mục chuỗi ở nền sau ~4 giây. Log dịch in ra terminal với tiền tố `[AutoTranslate]` (kèm `stderr`/`detail` nếu lỗi) để dễ chẩn đoán. Script có thêm endpoint dự phòng.

## Dịch nhanh & nhất quán hơn
- `scripts/translate.py` dịch theo lô 20 chuỗi/request (POST, tự lùi khi bị giới hạn, endpoint dự phòng), lưu cache sau mỗi lô → dịch cả danh mục trong vài giây thay vì từng chuỗi một. Lệch số dòng thì tự rơi về dịch lẻ.
- Khóa cache bỏ khoảng trắng đầu/cuối (" hours" = "hours"); từ chữ thường như "hours", "minutes" cũng được dịch. `CustomText`/`ButtonText` dùng font icon (Symbols) thì không bao giờ dịch.
- Card nhạc Dashboard dùng bản compact, cao 220px cùng hàng App Grid, hiện đủ thanh tua và nút.
