# Yêu cầu sản phẩm — Chặn cuộc gọi (iOS)

Tài liệu này mô tả sản phẩm tính đến 27/11/2026, 12:16 UTC+7. Hành vi đã có trong source thì lấy theo code. Chỗ ghi chú của PM lệch với code được ghi rõ bên dưới.

Thiết kế và lý do kỹ thuật: [td.md](td.md).

## Vấn đề

Johnny (chủ app, lập trình mobile hơn 7 năm) bị cuộc gọi spam, lừa đảo và quảng cáo mỗi ngày. Cần một app chặn số lạ **theo quy tắc do chính người dùng nhập**.

Không có số điện thoại cứng trong app. `028888` chỉ là đầu số để thử trên máy thật, không được gắn sẵn.

## Mục tiêu và giai đoạn

1. Dùng cá nhân trước, trên iPhone của Johnny.
2. Nếu chặn ổn, phát hành lên App Store, rồi Google Play.
3. iOS làm trước, trong repo này. Tên hiển thị là “AntiCall”. Target app là `ChanCuocGoi`.
4. Android làm sau, repo riêng `call-blocker-android`. Swift và Kotlin không dùng chung code, nên không nhét hai nền tảng vào một repo.

## Phạm vi MVP

Quyết định của Johnny lúc 27/11 10:11 UTC+7: làm MVP trong 3 giờ, hạn **13:15** cùng ngày, cắt scope còn mốc M2–M5, UI tối thiểu, không polish.

MVP iOS chỉ chặn im lặng cuộc gọi đến. Người dùng tự thêm quy tắc, bật extension trong Cài đặt, rồi kiểm tra bằng một cuộc gọi thật.

## Yêu cầu chức năng (iOS)

### Quy tắc do người dùng nhập

- Thêm, sửa, xóa, bật và tắt từng quy tắc. Quy tắc tắt không vào danh sách chặn.
- Hai loại, đúng enum `RuleKind` trong `BlockerCore`:
  - `prefix` — Đầu số. Mở rộng mọi số còn lại cho đủ độ dài E.164 của quy tắc đó.
  - `fullNumber` — Số đầy đủ. Đúng một số sau khi chuẩn hóa.
- Mỗi quy tắc có ghi chú tùy chọn.
- Không có loại hậu tố trên iOS.
- Lưu (thêm, sửa, xóa, bật, tắt) ghi `rules.json` ra đĩa rồi gọi `CXCallDirectoryManager.reloadExtension`. Nút **Tải lại danh sách chặn** làm lại bước nạp.
- Dữ liệu nằm trong file, không chỉ trong bộ nhớ. Tắt app hoặc hệ thống giết app thì quy tắc vẫn còn.
- Xuất và nhập JSON để giữ quy tắc khi phải xóa app (đổi team ký). File xuất tạm là `quy-tac-chan-cuoc-goi.json`. Nhập vào danh sách đang có thì app hỏi trước khi thay toàn bộ.

### Chuẩn hóa số Việt Nam

Mã quốc gia mặc định `84`. Bốn dạng đều được nhận: `0…`, `84…`, `+84…`, `0084…`. Khoảng trắng, `-`, `.` và ngoặc được bỏ qua. Chữ cái, số nước khác và chuỗi rỗng bị từ chối.

Ba cách gõ `028888`, `+8428888` và `8428888` ra cùng một đầu số `8428888`.

### Độ dài tối thiểu của đầu số

Đầu số phải có ít nhất **6 chữ số, tính cả số 0 đầu** (ví dụ `028888` cho số bàn, `090123` cho di động). Đầu số 5 chữ số trở xuống bị từ chối, không có mức cảnh báo. Đầu số dài hơn vẫn được. Với 6 chữ số, đầu số sinh 10.000 (di động) đến 100.000 (số bàn) số, an toàn cho extension. Với 5 chữ số có thể tới 1.000.000.

Quy tắc này áp dụng cho nhập tay, nhập JSON và quy tắc đã lưu. Quy tắc đầu số ngắn từ file JSON hoặc `rules.json` không làm app lỗi: app vẫn hiển thị, đánh dấu “không hợp lệ” và không đưa vào danh sách chặn. Số đầy đủ không bị giới hạn này.

### Cảnh báo khi danh sách quá lớn

Đầu số ngắn hơn độ dài đích `n` chữ số thì sinh đúng `10^n` số (với độ dài tối thiểu 6, một đầu số đơn lẻ không còn chạm ngưỡng cảnh báo, nhưng nhiều quy tắc cộng lại vẫn có thể). Danh sách quá lớn làm extension dễ bị iOS tắt vì hết bộ nhớ hoặc hết thời gian.

Ngưỡng trong code (`Limits`), không phải câu “> 1 triệu / > 2 triệu” của PM:

| Số lượng sau khi gộp | Việc app làm |
| --- | --- |
| từ 1.000.000 (`>= softCap`) | cảnh báo, vẫn cho lưu |
| đúng 2.000.000 | vẫn cho lưu và ghi `blocklist.bin` |
| trên 2.000.000 (`> hardCap`) | không lưu quy tắc mới, không ghi `blocklist.bin` |

Khi nhập file mà tổng vượt 2.000.000, app vẫn ghi `rules.json` nhưng không ghi danh sách chặn, và báo lỗi.

Ngưỡng này là chỗ đứng an toàn, chưa đo trên iPhone.

### Màn hình Hướng dẫn

Tab **Hướng dẫn** chỉ cách bật extension:

1. Mở Cài đặt.
2. Chọn Điện thoại.
3. Chọn Chặn cuộc gọi & Nhận dạng.
4. Bật công tắc cạnh “Chặn cuộc gọi”.

App hiện trạng thái từ `CXCallDirectoryManager.getEnabledStatusForExtension`:

- Đã bật
- Chưa bật
- Chưa rõ
- Không đọc được (khi API trả lỗi; ghi chú PM chỉ nêu ba trạng thái đầu)

Nút **Mở phần Chặn cuộc gọi** gọi `openSettings`. Nếu hệ thống không mở đúng trang, app mở Cài đặt của app bằng `UIApplication.openSettingsURLString`. Nút **Mở Cài đặt của app** luôn đi đường đó. Call Directory không chạy trên Simulator.

### Hành vi khi có cuộc gọi

iOS chỉ có **chặn im lặng**: máy không đổ chuông. CallKit không phân biệt “từ chối” và “im”, không tự nghe máy, không tự cúp.

Không chặn SMS, FaceTime, hay cuộc gọi đã nối.

App không đếm và không lưu lịch sử cuộc gọi bị chặn. Apple không đưa sự kiện đó cho app. Cuộc gọi bị chặn im lặng vẫn có thể hiện trong Điện thoại > Gần đây; app không xóa được mục đó.

### Khi chưa có App Group

`ENABLE_APP_GROUPS` mặc định là `NO` để Personal Team ký được. Khi đó:

- App vẫn cài được và vẫn thêm, sửa, xóa, bật, tắt quy tắc. File nằm ở Application Support của app.
- Màn hình Quy tắc hiện banner **Chưa chặn được cuộc gọi**.
- Extension không đọc được sandbox của app, nên nạp danh sách trống. Cuộc gọi không bị chặn.
- Công tắc trong Cài đặt > Điện thoại > Chặn cuộc gọi & Nhận dạng có thể không hiện với profile miễn phí.

Profile miễn phí hết hạn sau 7 ngày. Hết hạn thì app không mở được cho đến khi cắm máy và Run lại từ Xcode.

Chặn thật cần App Group, thường là sau khi Apple Developer Program active và `ENABLE_APP_GROUPS = YES`.

## Ngoài phạm vi iOS MVP

| Hạng mục | Lý do |
| --- | --- |
| Quy tắc hậu tố | Call Directory chỉ nhận từng số cụ thể, đã sắp tăng dần. Hậu tố nở thành hàng triệu số. |
| Tự nghe máy, tự cúp | Call Directory không có API này. |
| Thống kê và lịch sử cuộc gọi bị chặn | Apple không đưa sự kiện chặn cho app. Số vẫn có thể nằm trong Điện thoại > Gần đây. |
| Chặn SMS, FaceTime | Ngoài Call Directory. |
| Android | Repo khác, làm sau. |
| Polish giao diện | Cắt lúc 10:11 để kịp hạn 13:15. |

## Android (chưa bắt đầu)

Repo dự kiến: `call-blocker-android`.

- `CallScreeningService` nhìn thấy cuộc gọi đến, nên làm được những việc iOS không làm: disallow/reject, silence, skip notification, tự cúp, đếm số lần chặn và giữ lịch sử.
- Khớp đầu số, hậu tố và số đầy đủ trên số đã chuẩn hóa. Cùng một ý với iOS: `028888…` và `+8428888…` phải ra cùng một dạng.

## Tiêu chí chấp nhận

### Đã nêu cho MVP

Trên iPhone thật, một quy tắc đầu số `028888` hoặc số đầy đủ của điện thoại thứ hai làm cuộc gọi im lặng, không đổ chuông.

### Đề xuất của PM — chưa được Johnny duyệt

Các mục sau là đề xuất, **chưa approved**:

1. Build và cài được lên iPhone thật.
2. Tạo, sửa, xóa, bật và tắt quy tắc đầu số và số đầy đủ. Đóng app rồi mở lại, dữ liệu vẫn còn.
3. Bật extension theo màn hình Hướng dẫn. App hiện đúng trạng thái Đã bật / Chưa bật / Chưa rõ.
4. Gọi từ số thứ hai, số đó khớp một quy tắc đang bật, thì máy cài app không đổ chuông.
5. Tắt hoặc xóa quy tắc đó, rồi tải lại danh sách, thì cuộc gọi đổ chuông lại.
6. Đầu số thử `028888` (100.000 số, từ `842888800000` đến `842888899999`, độ dài E.164 là 12) nạp được.

Mục 3 trong đề xuất chưa kể trạng thái **Không đọc được**. Code có trạng thái đó khi `getEnabledStatusForExtension` lỗi.

## Mốc

Giờ UTC+7, ngày 27/11/2026. “Code xong” nghĩa là source đã có trong repo. Chưa ai compile bằng Xcode, chưa cài lên iPhone.

PM gọi M1 là “dựng SwiftUI app + extension + App Group đã xong”. Dương Quá (12:16) gọi M1 là chốt scope và plan, còn phần app, extension và App Group nằm ở M2–M5. Bảng dưới lấy cách của dev vì đúng trạng thái source: target và entitlement đã có trong repo, `ENABLE_APP_GROUPS` vẫn là `NO`, và chưa có kết quả build.

| Mốc | Nội dung | Trạng thái |
| --- | --- | --- |
| M1 | Chốt scope và plan | Xong |
| M2 | Màn hình quy tắc: thêm, sửa, xóa, bật tắt, đầu số hoặc số đầy đủ, kiểm tra dữ liệu, cảnh báo danh sách lớn | Code xong |
| M3 | Mở rộng đầu số ra E.164, sắp tăng dần, ghi `blocklist.bin`, extension gọi `addBlockingEntry` | Code xong. 22 unit test của `BlockerCore` (`swift test` trên Linux) được báo là pass |
| M4 | `reloadExtension` sau mỗi lần lưu, nút Tải lại, hiện lỗi CallKit | Code xong |
| M5 | Màn hình Hướng dẫn và trạng thái extension (`getEnabledStatusForExtension`, nút `openSettings`, dự phòng `openSettingsURLString`) | Code xong |
| M6 | Build và thử trên iPhone thật | Chưa. Johnny dự kiến build khoảng 12:45 trên MacBook M1 Pro. Code iOS chưa từng được compile |

M2–M5 xong trong source lúc 10:12 (Origin commit `170cf02`). Xác nhận lại lúc 12:16: vẫn chưa compile, M6 chưa làm.

Hạn MVP: **13:15** cùng ngày.

## Bối cảnh ký và máy build

- Khoảng 10:00, Johnny đăng ký Apple Developer Program (99 USD/năm). Team trả phí thường active sau một đến hai ngày.
- Trong lúc chờ: Personal Team (Apple ID miễn phí). `TEAM_ID` và bundle id nằm một chỗ trong `Config/Signing.xcconfig` để đổi sau, không sửa rải trong project.
- Máy build: MacBook M1 Pro của Johnny, macOS 15.7.9, Xcode 26.3. Có iPhone thật và một số điện thoại thứ hai để gọi thử.
- Repo đang ở GitHub (`johnnybui1911/call-blocker-ios`, `main` `f1d89a4`). Repo Origin chỉ là chỗ tạm, history không được giữ khi chuyển sang.

## Lệch so với ghi chú PM

- Cảnh báo bắt đầu từ **đúng** 1.000.000 số (`>=`), không phải chỉ khi vượt 1.000.000. Đúng 2.000.000 vẫn lưu được. Chỉ **trên** 2.000.000 thì từ chối.
- Trạng thái extension có thêm **Không đọc được**, ngoài Đã bật / Chưa bật / Chưa rõ.
- M1 trong source là scope và plan. Phần SwiftUI, extension và App Group đã được viết nhưng chưa được build, và App Group đang tắt.
