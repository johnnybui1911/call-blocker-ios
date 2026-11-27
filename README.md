# Chặn cuộc gọi

App iOS cá nhân để chặn im lặng cuộc gọi đến theo **đầu số** hoặc **số đầy đủ**. Bạn thêm quy tắc trong app. App chuẩn hóa số Việt Nam sang E.164, mở rộng đầu số thành từng số, ghi một file nhị phân đã sắp tăng dần vào App Group, rồi Call Directory Extension nạp file đó vào CallKit.

Phiên bản này chỉ có iOS. Không có thống kê, không có lịch sử cuộc gọi bị chặn.

## Cấu trúc

```
Config/Signing.xcconfig          ← sửa Team, prefix bundle, bật/tắt App Group
Config/App.xcconfig              ← đừng sửa
Config/Extension.xcconfig        ← đừng sửa
project.yml                      ← XcodeGen
ChanCuocGoi.xcodeproj            ← project đã generate, mở được ngay
BlockerCore/                     ← logic dùng chung, test được trên Linux
ios/App/                         ← SwiftUI
ios/Extension/                   ← Call Directory Extension
ios/Entitlements/                ← entitlement có hoặc không có App Group
ios/Shared/SharedConfig.swift    ← đọc ID từ Info.plist
```

`BlockerCore` chỉ dùng Foundation. App và extension cùng link package này.

## Cần có

- Mac, Xcode 16 trở lên (project dùng objectVersion 77)
- iPhone thật, iOS 16 trở lên, cắm máy để Run
- Apple ID. Personal Team (miễn phí) cài được app để soạn quy tắc. Chặn cuộc gọi thật cần App Group, xem mục bên dưới
- Máy thứ hai để gọi thử, nếu có

Call Directory **không chạy trên Simulator**. Simulator chỉ để xem giao diện.

## Cấu hình một chỗ

Mở `Config/Signing.xcconfig` **trước** lần build đầu:

| Biến | Ý nghĩa |
| --- | --- |
| `TEAM_ID` | 10 ký tự. Personal Team cũng có mã này. Để trống thì chọn Team trong Xcode |
| `BUNDLE_PREFIX` | Ví dụ `dev.johnny.chancuocgoi`. Đổi trước khi Run, vì Apple đăng ký bundle id này cho tài khoản của bạn |
| `ENABLE_APP_GROUPS` | `NO` hoặc `YES` (chữ hoa) |

Ba ID còn lại tự suy ra, không sửa tay:

- App: `$(BUNDLE_PREFIX)`
- Extension: `$(BUNDLE_PREFIX).CallDirectory`
- App Group: `group.$(BUNDLE_PREFIX)`

Ví dụ prefix `dev.johnny.chancuocgoi` thì App Group là `group.dev.johnny.chancuocgoi`.

Xcode đọc xcconfig lúc build. Sửa file này rồi build lại. Chỉ chạy lại `xcodegen generate` khi bạn đổi `project.yml`.

Nếu bạn đã chọn Team trong Signing & Capabilities, Xcode có thể ghi đè `DEVELOPMENT_TEAM` trong project. Khi đó việc sửa `TEAM_ID` không có tác dụng. Vào Build Settings của **cả hai** target (app và extension), tìm Development Team, xóa giá trị cứng để nó lấy lại từ xcconfig.

## Build bằng Personal Team

1. Xcode → Settings → Accounts → thêm Apple ID.
2. Chọn team dạng `Tên của bạn (Personal Team)`. Team ID là chuỗi 10 ký tự ở cột phải, không phải chữ “Personal Team”.
3. Điền vào `Config/Signing.xcconfig`:

   ```
   TEAM_ID = ABCD123456
   BUNDLE_PREFIX = dev.johnny.chancuocgoi
   ENABLE_APP_GROUPS = NO
   ```

   `ENABLE_APP_GROUPS = NO` là mặc định. Entitlement App Group không được gắn vào bản ký, nên Personal Team ký được.
4. Cài XcodeGen nếu bạn cần generate lại project (project trong repo đã generate sẵn):

   ```bash
   brew install xcodegen
   xcodegen generate
   open ChanCuocGoi.xcodeproj
   ```

5. Scheme `ChanCuocGoi`. Destination: iPhone của bạn, không phải Simulator.
6. Signing & Capabilities của target `ChanCuocGoi` và `CallDirectoryExtension`: Automatically manage signing, cùng một Team.
7. Run. Lần đầu iPhone hỏi tin cậy nhà phát triển: Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị → tin cậy Apple ID của bạn.
8. Profile miễn phí hết hạn sau **7 ngày**. Hết hạn thì app không mở được cho đến khi bạn cắm máy và Run lại từ Xcode.

### App Group và Call Directory trên tài khoản miễn phí

Trang capability của Apple ([Supported capabilities (iOS)](https://developer.apple.com/help/account/reference/supported-capabilities-ios/)) hiện đánh dấu **App Groups** cho cả cột tài khoản miễn phí (“Apple Developer”), không chỉ chương trình trả phí. Trong Xcode, Personal Team vẫn thường từ chối entitlement này với lỗi kiểu:

`Personal development teams do not support the App Groups capability.`

Khi gặp lỗi đó, đặt lại `ENABLE_APP_GROUPS = NO` và build lại. Đừng thêm tay entitlement `com.apple.developer.callkit.call-directory`. Provisioning profile không có entitlement đó; Call Directory chỉ cần `NSExtensionPointIdentifier` = `com.apple.callkit.call-directory` trong Info.plist của extension.

Keychain Sharing cũng không phải lối thoát: capability đó không có trên tài khoản miễn phí, và không phải chỗ để chứa hàng trăm nghìn số.

Call Directory là extension riêng. Nó không đọc được sandbox của app. Không có App Group thì không có kênh nào để đưa danh sách số sang extension.

Giới hạn thực tế với Personal Team:

- App cài được, thêm/sửa/xóa/bật tắt quy tắc được, thấy ước tính số lượng.
- Extension có thể được nhúng vào app. Công tắc trong Cài đặt → Điện thoại → Chặn cuộc gọi & Nhận dạng **có thể không hiện** với profile miễn phí. Nếu không hiện, đó là giới hạn tài khoản, không phải lỗi danh sách số.
- Dù công tắc có hiện, extension cũng chỉ nạp **danh sách trống** khi không có App Group. Cuộc gọi không bị chặn.
- Profile hết hạn sau 7 ngày.

Muốn thử xem máy bạn có ký được App Group hay không: đặt `ENABLE_APP_GROUPS = YES`, build. Thành công thì app và extension dùng chung container, chặn được nếu iOS hiện công tắc. Thất bại thì trả về `NO`.

### Fallback khi không có App Group

| | Có App Group | Không có App Group |
| --- | --- | --- |
| Quy tắc lưu ở | container App Group (`rules.json`) | Application Support của app |
| Danh sách CallKit | `blocklist.bin`, extension đọc và gọi `addBlockingEntry` | extension hoàn tất với **không số nào** |
| Cuộc gọi | chặn im lặng nếu extension đã bật | không chặn |
| UI | trạng thái bình thường | banner “Chưa chặn được cuộc gọi” |

Lần đầu container App Group mở được, nếu trong App Group chưa có `rules.json` mà máy còn bản lưu cục bộ, app copy file đó sang. Không ghi đè quy tắc đã có trong App Group.

Đổi team thường buộc xóa app (iOS không cài đè khác chữ ký). Xóa app là mất dữ liệu cục bộ. Trước khi xóa: tab Quy tắc → menu `…` → **Xuất quy tắc**. Cài bản mới → **Nhập quy tắc**.

## Chuyển sang Team trả phí

Khi Apple Developer Program đã active (thường một đến hai ngày sau khi đăng ký):

1. Xcode → Settings → Accounts → tải lại account. Team trả phí xuất hiện, khác Personal Team.
2. Sửa `Config/Signing.xcconfig`:

   ```
   TEAM_ID = <mã 10 ký tự của team trả phí>
   ENABLE_APP_GROUPS = YES
   ```

   Giữ nguyên `BUNDLE_PREFIX` nếu bundle id đó đăng ký được cho team mới. Nếu portal báo bundle id đã thuộc team khác, đổi prefix.
3. Nếu Build Settings còn Development Team cứng của Personal Team, xóa để lấy `$(TEAM_ID)`.
4. Trên iPhone, xuất quy tắc, xóa app cũ, Run lại.
5. Nhập quy tắc. App ghi `blocklist.bin` vào App Group và gọi `reloadExtension`.
6. Bật extension trong Cài đặt (mục dưới).
7. Xcode automatic signing sẽ tạo App Group `group.<BUNDLE_PREFIX>` nếu team trả phí cho phép. Nếu không, vào [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → App Groups, tạo đúng ID đó, rồi bật App Groups cho **cả** App ID của app và của extension.

## Bật extension

Trên iPhone:

1. Mở Cài đặt.
2. Chọn Điện thoại.
3. Chọn Chặn cuộc gọi & Nhận dạng.
4. Bật công tắc của “Chặn cuộc gọi”.

Trong app, tab Hướng dẫn hiện trạng thái từ `CXCallDirectoryManager.getEnabledStatusForExtension`: Đã bật, Chưa bật, hoặc Chưa rõ. Nút **Mở phần Chặn cuộc gọi** gọi `openSettings` của CallKit. Nếu hệ thống không mở được đúng trang, nút **Mở Cài đặt của app** dùng `UIApplication.openSettingsURLString`; từ đó bạn tự vào Điện thoại → Chặn cuộc gọi & Nhận dạng.

Sau mỗi lần lưu quy tắc, app gọi `reloadExtension`. Nút **Tải lại danh sách chặn** làm lại việc đó. Lỗi CallKit hiện trên màn hình (extension chưa bật, đang tải, quá nhiều số, không tìm thấy extension).

## Cách thử với 028888

`028888` không có sẵn trong app. Bạn tự thêm khi thử.

1. Cài lên iPhone thật, App Group đang hoạt động, extension đã bật.
2. Thêm quy tắc loại **Đầu số**, nhập `028888`, độ dài E.164 để **12** (mặc định).
3. Ước tính phải là **100.000** số, từ `842888800000` đến `842888899999`. Ba cách gõ sau ra cùng một đầu số: `028888`, `+8428888`, `8428888`.
4. Bật quy tắc, lưu, bấm Tải lại danh sách chặn. Trạng thái extension là Đã bật.
5. Từ máy khác, gọi một số dạng `028 888x xxxx`, ví dụ `02888801234`. Máy cài app không đổ chuông.
6. Cách chắc hơn nếu bạn không có đầu số 028888 thật: thêm quy tắc **Số đầy đủ** là số của điện thoại thứ hai, gọi từ máy đó, xác nhận bị chặn, rồi xóa quy tắc.

Số bàn TP.HCM là `028` + 8 chữ số thuê bao. `028888` đã chiếm 3 chữ số thuê bao, còn 5 chữ số, nên 10^5 = 100.000 số. E.164 dài 12 chữ số: bỏ số 0 đầu, thêm mã `84`.

Số di động Việt Nam thường dài **11** chữ số E.164 (`090…` → `8490…`). Khi chặn đầu số di động, hạ độ dài đích xuống 11. Đầu số quá ngắn sẽ vượt ngưỡng và app từ chối lưu.

## Quy tắc và chuẩn hóa

Hai loại:

- **Đầu số**: mở rộng mọi số còn lại cho đủ độ dài E.164 của quy tắc đó.
- **Số đầy đủ**: đúng một số.

Mỗi quy tắc bật, tắt, sửa, xóa riêng. Quy tắc tắt không vào danh sách chặn. Không có loại hậu tố.

Chuẩn hóa, mã quốc gia mặc định Việt Nam `84`:

| Bạn gõ | Kết quả |
| --- | --- |
| `0…` | bỏ `0`, thêm `84` |
| `84…` | giữ nguyên |
| `+84…` | bỏ dấu `+` |
| `0084…` | bỏ `00` |

Ký tự được phép thêm: khoảng trắng, `-`, `.`, ngoặc. Chữ cái, số nước khác, chuỗi rỗng: từ chối.

Các dải được gộp, bỏ trùng, sắp theo giá trị số tăng dần (CallKit bắt buộc). Số 11 chữ số đứng trước số 12 chữ số vì giá trị nhỏ hơn.

File `blocklist.bin` (không phải JSON trong UserDefaults):

```
0   "CBLK"
4   UInt16 version = 1
6   UInt16 dành riêng
8   UInt64 số lượng
16  Int64 little-endian, tăng nghiêm ngặt, không trùng
```

Extension đọc tuần tự và gọi `addBlockingEntry(withNextSequentialPhoneNumber:)`. Mỗi lần tải là full reload. Nếu iOS xin incremental, extension xóa hết rồi thêm lại toàn bộ.

## Giới hạn iOS

Chưa đo trên máy thật trong môi trường viết code này (không có Xcode, không có iPhone, Call Directory không chạy trên Simulator). Ngưỡng trong app là chỗ đứng an toàn, phải kiểm tra lại khi bạn cài:

| Ngưỡng | Việc app làm |
| --- | --- |
| từ 1.000.000 số | cảnh báo, vẫn cho lưu |
| trên 2.000.000 số | không cho bật / không ghi `blocklist.bin` |
| đúng 2.000.000 | vẫn cho |

Một đầu số ngắn hơn độ dài đích `n` chữ số thì sinh đúng `10^n` số. `10^6` = 1.000.000 (cảnh báo). `10^7` = 10.000.000 (từ chối).

Nếu sau khi cài, tải lại báo `maximumEntriesExceeded`, extension biến mất, hoặc iOS giết extension, hãy thu hẹp đầu số. Call Directory có hạn bộ nhớ và thời gian mà Apple không công bố con số. 100.000 số của ví dụ `028888` / độ dài 12 là cỡ hợp lý để thử trước.

Những gì CallKit không làm:

- Không chặn SMS, FaceTime, hay cuộc gọi đã nối.
- Không phân biệt “từ chối” và “im”. Chỉ có chặn im lặng: máy không đổ chuông.
- Không đưa lịch sử cuộc gọi vào app.
- Số nhà mạng đưa cho iOS phải khớp dạng E.164 đã nạp. Nếu cuộc gọi không khớp, thử một quy tắc số đầy đủ với máy thứ hai trước khi kết luận đầu số sai.

File danh sách đặt mức bảo vệ `none` để extension còn đọc được sau khi máy khởi động lại, trước lần mở khóa đầu. Máy tắt vẫn được mã hóa bởi phần cứng.

## Test logic

Trên Mac hoặc Linux, trong `BlockerCore`:

```bash
swift test
```

Test gồm chuẩn hóa, mở rộng `028888` ra 100.000 số (`842888800000` … `842888899999`), sắp tăng dần, gộp trùng, ước tính, ngưỡng 1 triệu / 2 triệu, và đọc lại file nhị phân.

## Lỗi thường gặp

| Triệu chứng | Việc làm |
| --- | --- |
| Personal Team không hỗ trợ App Groups | `ENABLE_APP_GROUPS = NO`, build lại. Chặn thật để sau khi có team trả phí |
| Failed to register bundle identifier | Đổi `BUNDLE_PREFIX` thành tên chưa ai đăng ký |
| Extension chưa được bật | Cài đặt → Điện thoại → Chặn cuộc gọi & Nhận dạng |
| Không tìm thấy extension | Kiểm tra đã Run lên iPhone thật, và bundle extension là `<prefix>.CallDirectory` |
| iOS từ chối vì quá nhiều số | Đầu số dài hơn, hoặc hạ độ dài E.164 cho đúng loại số |
| App Group bật nhưng container trống | Capability App Groups của cả hai target, đúng `group.<prefix>`, cài lại |
| Đổi team xong mất quy tắc | Nhập lại file đã xuất |

## Việc chưa làm được ở đây

- Chưa chạy Xcode, chưa cài lên iPhone, chưa đo bộ nhớ hay thời gian của extension.
- Chưa biết máy của bạn với Personal Team có ký được App Group hay không. Mặc định tắt để bản đầu cài được.
- Công tắc Chặn cuộc gọi có xuất hiện với profile miễn phí hay không tùy iOS và tài khoản. Nếu không xuất hiện, cần team trả phí.
