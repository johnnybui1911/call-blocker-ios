# Thiết kế kỹ thuật — Chặn cuộc gọi (iOS)

Tính đến 27/11/2026, 12:16 UTC+7. Khi ghi chú của PM hoặc dev lệch với source, mục này lấy theo code và ghi chú ở cuối.

Yêu cầu sản phẩm: [prd.md](prd.md).

Source đang ở GitHub `johnnybui1911/call-blocker-ios`, nhánh `main`, commit `f1d89a4` (import cùng tree từ Origin `170cf02`, không giữ history). Code iOS chưa từng được compile bằng Xcode.

## Kiến trúc

```
SwiftUI app (ChanCuocGoi)
    RuleStore  --rules.json-->  App Group container  (hoặc Application Support)
    RuleStore  --blocklist.bin-> App Group container
    RuleStore  --reloadExtension--> CXCallDirectoryManager
                                         |
Call Directory Extension (CallDirectoryHandler)
    đọc blocklist.bin, addBlockingEntry theo thứ tự tăng dần

BlockerCore (Swift package, Foundation)
    dùng chung cho app và extension, test bằng swift test
```

`BlockerCore` không import CallKit hay SwiftUI. App và extension chỉ là lớp iOS quanh package đó.

### Project

- `project.yml` là nguồn của XcodeGen. `ChanCuocGoi.xcodeproj` đã generate và commit (`objectVersion` 77, cần Xcode 16 trở lên). Chỉ chạy `xcodegen generate` khi sửa `project.yml`.
- Deployment target iOS 16.0. `TARGETED_DEVICE_FAMILY = 1` (chỉ iPhone). Swift 5. Ngôn ngữ project `vi`. UI là SwiftUI.
- Scheme `ChanCuocGoi` build cả app và extension.

| Target | Loại | Source | Việc |
| --- | --- | --- | --- |
| `ChanCuocGoi` | application | `ios/App`, `ios/Shared` | SwiftUI. Màn hình và lưu quy tắc |
| `CallDirectoryExtension` | app-extension | `ios/Extension`, `ios/Shared` | Call Directory. `NSExtensionPointIdentifier` = `com.apple.callkit.call-directory`. Class `CallDirectoryHandler` |

App nhúng extension (`embed: true`). Cả hai link product `BlockerCore`.

Không thêm entitlement `com.apple.developer.callkit.call-directory`. Provisioning profile không có key đó. Call Directory chỉ cần `NSExtensionPointIdentifier` trong `ios/Extension/Info.plist`.

Màn hình app:

- `RulesView` — danh sách, bật tắt, xóa, xuất, nhập, nút tải lại.
- `RuleEditorView` — thêm và sửa. Gọi `RuleFactory.preview` để ước tính trước khi lưu.
- `GuideView` — hướng dẫn và trạng thái extension.
- `RuleStore` — đọc ghi file, gọi `reloadExtension`.
- `ExtensionStatus` — `getEnabledStatusForExtension` và `openSettings`.
- `ActivityView` — chỉ là share sheet (`UIActivityViewController`) để **xuất** file. Nhập dùng `fileImporter`, không đi qua `ActivityView`. Ghi chú dev gộp “export/import” vào `ActivityView` là lệch chỗ này.

`ios/Shared/SharedConfig.swift` đọc ba key từ Info.plist của process hiện tại: `AppGroupIdentifier`, `ExtensionBundleIdentifier` (chỉ app có key này), `AppGroupsBuildEnabled`.

### BlockerCore

Package `BlockerCore/Package.swift`, `swift-tools-version` 5.9, platform tối thiểu iOS 16 và macOS 12. Chỉ Foundation, nên `swift test` chạy được trên Linux.

API public khớp source:

| Kiểu | Vai trò |
| --- | --- |
| `RuleKind` | `prefix`, `fullNumber` |
| `BlockRule` | `id`, `kind`, `rawInput`, `pattern` (chữ số E.164, không dấu `+`), `targetLength`, `enabled`, `note` |
| `PhoneNormalizer.normalize` | `String` → `Result<String, NormalizeError>` |
| `RuleFactory.preview` / `make` | Kiểm tra và tạo quy tắc. `DraftPreview.canSave` khi không lỗi và đã chuẩn hóa được |
| `NumberRange.merge` | Gộp dải chồng hoặc kề nhau, bỏ trùng |
| `BlocklistBuild.evaluate` | Ước tính từng quy tắc, cộng quy tắc đang bật, gộp, ra `mergedCount` và `ranges` |
| `BlocklistFile` | Ghi và đọc `blocklist.bin` |
| `RuleArchive` | `rules.json`, encode pretty-printed, key sắp xếp |
| `Limits` | Ngưỡng và độ dài mặc định |

19 hàm `test*` trong `BlockerCore/Tests/BlockerCoreTests`: chuẩn hóa, mở rộng `028888` thành 100.000 số, thứ tự tăng, gộp trùng, ngưỡng 1 triệu và 2 triệu, đọc lại file nhị phân, vòng `rules.json`. Dương Quá báo `swift test` trên Linux pass. Máy viết tài liệu này không có Swift toolchain nên không chạy lại.

## Luồng dữ liệu

1. Người dùng gõ số. `PhoneNormalizer` đưa về chữ số E.164, mã `84`.
2. Đầu số: `ExpansionMath.prefixSpan` tính `[first, last]` và `10^(targetLength - pattern.count)` số. Số đầy đủ: một số, count = 1.
3. `RuleStore.commit` gọi `BlocklistBuild.evaluate`. Nếu `mergedCount > Limits.hardCap` thì dừng, không ghi file.
4. `RuleArchive.save` ghi `rules.json` (atomic). Nếu đang có App Group, `BlocklistFile.write` ghi `blocklist.bin`.
5. `CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier:)` với `EXTENSION_BUNDLE_ID`.
6. `CallDirectoryHandler.beginRequest`: nếu iOS xin incremental thì `removeAllBlockingEntries()`, rồi đọc toàn bộ file và `addBlockingEntry(withNextSequentialPhoneNumber:)` theo lô 2.000 số, trong `autoreleasepool`.

Quy tắc tắt không vào `ranges`. Mọi quy tắc tắt nghĩa là danh sách rỗng, không số nào bị chặn.

Không có App Group thì bước 4 chỉ ghi `rules.json` cục bộ, không ghi `blocklist.bin`. Extension thấy `AppGroupsBuildEnabled` khác YES thì trả danh sách trống (vẫn xóa số cũ nếu iOS xin incremental). `reloadExtension` vẫn được gọi. Lỗi reload trong trường hợp này hiện cảnh báo, không chặn được cuộc gọi.

## File

### `rules.json`

Tên hằng `RuleArchive.fileName`. Mảng `BlockRule`.

- Có App Group: trong container `group.<BUNDLE_PREFIX>`.
- Không có App Group: Application Support của app, thư mục `ChanCuocGoi`. Extension không đọc được chỗ này.
- Lần đầu container App Group mở được, nếu group chưa có `rules.json` mà máy còn bản cục bộ, app copy sang. Không ghi đè file đã có trong group.

### `blocklist.bin`

Tên hằng `BlocklistFile.fileName`. Không dùng JSON và không dùng UserDefaults: file nhị phân để extension đọc tuần tự, ít cấp phát.

```
0   "CBLK"          4 byte
4   version         UInt16 = 1
6   reserved        UInt16 = 0
8   count           UInt64
16  số             Int64 little-endian × count, tăng nghiêm ngặt, không trùng
```

Dải được gộp trước khi ghi. Giá trị phải vừa `Int64` (kiểu `CXCallDirectoryPhoneNumber`). Ghi qua file `.tmp` rồi thay thế. Đọc từ chối magic sai, version lạ, file cụt, số âm, hoặc số không tăng nghiêm ngặt.

Cả `rules.json` và `blocklist.bin` được đặt `FileProtectionType.none` để extension còn đọc sau khi máy khởi động lại, trước lần mở khóa đầu. Máy tắt vẫn được mã hóa bởi phần cứng. Vì là file trên đĩa, dữ liệu còn sau khi app bị giết.

## Chuẩn hóa và ví dụ `028888`

`Limits.countryCode = "84"`. Đây là đầu vào chuẩn hóa, không phải một dòng trong danh sách chặn.

| Người dùng gõ | Kết quả |
| --- | --- |
| `0…` | bỏ `0`, thêm `84` |
| `84…` | giữ nguyên |
| `+84…` | bỏ `+` |
| `0084…` | bỏ `00` |

Bản cập nhật 12:16 của dev chỉ liệt kê `0…`, `+84…`, `0084…`. Code còn nhận `84…` không dấu cộng (`PhoneNormalizer`).

Ký tự được bỏ: khoảng trắng, `-`, `.`, ngoặc, kể cả NBSP. `+` chỉ hợp lệ ở đầu, một lần.

Mỗi quy tắc đầu số có `targetLength` riêng:

| Hằng | Giá trị | Ý nghĩa |
| --- | --- | --- |
| `defaultTargetLength` | 12 | Số bàn Việt Nam: mã vùng kèm 0, rồi 8 chữ số thuê bao, bỏ 0, thêm `84` |
| `minimumTargetLength` … `maximumTargetLength` | 8 … 15 | Stepper trong màn hình sửa |
| `minimumFullNumberLength` … `maximumFullNumberLength` | 10 … 15 | Số đầy đủ sau chuẩn hóa |

Số di động Việt Nam thường dài 11 chữ số E.164 (`090…` → `8490…`). Chặn đầu số di động thì hạ độ dài đích xuống 11. App nói điều này ở footer của stepper.

Số bàn TP.HCM là `028` + 8 chữ số thuê bao. Đầu số `028888` chiếm 3 chữ số thuê bao, còn 5. Sau chuẩn hóa pattern là `8428888` (7 chữ số). Với đích 12: `10^5 = 100.000` số, từ `842888800000` đến `842888899999`.

## Ký

Chỉ sửa `Config/Signing.xcconfig`. `Config/App.xcconfig` và `Config/Extension.xcconfig` chỉ `#include` file đó và chọn entitlement. Đừng sửa hai file kia.

Giá trị đang commit:

```
TEAM_ID =
BUNDLE_PREFIX = dev.changeme.chancuocgoi
ENABLE_APP_GROUPS = NO
```

`BUNDLE_PREFIX` là placeholder, phải đổi trước khi Run. Apple gắn bundle id này với team.

Ba ID suy ra, không gõ tay:

| Biến | Công thức |
| --- | --- |
| `APP_BUNDLE_ID` | `$(BUNDLE_PREFIX)` |
| `EXTENSION_BUNDLE_ID` | `$(BUNDLE_PREFIX).CallDirectory` |
| `APP_GROUP_ID` | `group.$(BUNDLE_PREFIX)` |
| `DEVELOPMENT_TEAM` | `$(TEAM_ID)` |

`ENABLE_APP_GROUPS` chỉ nhận `YES` hoặc `NO`. App và extension chọn file entitlement bằng `CODE_SIGN_ENTITLEMENTS = $(APP_ENTITLEMENTS_$(ENABLE_APP_GROUPS))` và bản tương ứng của extension:

- `YES` → `ios/Entitlements/App.AppGroup.entitlements` và `Extension.AppGroup.entitlements` (`com.apple.security.application-groups` = `$(APP_GROUP_ID)`).
- `NO` → `App.NoGroup.entitlements` và `Extension.NoGroup.entitlements` (plist rỗng).

Ba ID và cờ `ENABLE_APP_GROUPS` được ghi vào Info.plist lúc build (`AppGroupIdentifier`, `ExtensionBundleIdentifier`, `AppGroupsBuildEnabled`) để `SharedConfig` không hardcode.

Xcode có thể ghi đè `DEVELOPMENT_TEAM` trong Build Settings sau khi chọn Team ở Signing & Capabilities. Khi đó sửa `TEAM_ID` không có tác dụng. Xóa giá trị cứng ở **cả hai** target để project lấy lại `$(TEAM_ID)`.

## Quyết định

Mốc giờ là UTC+7, ngày 27/11/2026.

| Khi | Quyết định | Lý do |
| --- | --- | --- |
| ~10:00 | Johnny đăng ký Apple Developer Program (99 USD/năm). Trước khi team active thì dùng Personal Team | App Group trên tài khoản miễn phí thường không ký được. `TEAM_ID` và bundle id gom vào một xcconfig để đổi sau |
| 10:11 | MVP trong 3 giờ, hạn 13:15. Scope còn M2–M5. UI tối thiểu, không polish | Đủ để thử chặn thật, không làm phần Apple không cho app làm |
| 10:11 | Chỉ `prefix` và `fullNumber`. Không hậu tố, không thống kê, không số cứng | Call Directory cần danh sách số cụ thể, tăng dần. Hậu tố quá lớn. App không nhận sự kiện cuộc gọi nên không có lịch sử để hiện |
| 10:11 | Repo iOS và Android tách nhau | Swift và Kotlin không chia sẻ implementation. Android là `call-blocker-android`, chưa bắt đầu |
| 10:12 | Code M2–M5 trên Origin `170cf02` | Logic và UI đã nằm trong source. Chưa phải bản đã build |
| 11:57 | Chuyển cùng tree lên GitHub `main` `f1d89a4`, bỏ history Origin | Agent trên Mac không clone được Origin. Origin chỉ là repo tạm |

Những lựa chọn trong code, kèm lý do:

- **Chuẩn hóa về E.164, mã 84.** Nhà mạng đưa số cho iOS phải khớp dạng đã nạp. `028…` và `+84…` phải thành cùng một dãy chữ số, nếu không cuộc gọi không khớp dù quy tắc “đúng”.
- **Mỗi đầu số có độ dài đích.** Số bàn 12 chữ số và số di động 11 chữ số không dùng chung một công thức.
- **Gộp dải, bỏ trùng, sắp tăng.** CallKit từ chối `entriesOutOfOrder` và `duplicateEntries`. `NumberRange.merge` gộp cả dải kề nhau.
- **`blocklist.bin` thay cho JSON trong UserDefaults.** Header cố định, rồi toàn `Int64` little-endian. Extension đọc tuần tự, không decode cả cây JSON. UserDefaults không phải chỗ chứa hàng trăm nghìn số, và extension không đọc UserDefaults của app.
- **Luôn full reload.** Mỗi lần lưu là một danh sách mới. Nếu `context.isIncremental` thì xóa hết rồi thêm lại. Không có diff từng số.
- **Chỉ `addBlockingEntry`.** Không thêm nhãn nhận dạng. CallKit không có chế độ “từ chối” riêng với “im”, và không tự nghe hay tự cúp.
- **Bảo vệ file `none`.** Extension phải đọc được trước lần mở khóa đầu sau reboot.
- **Copy `rules.json` một chiều khi có App Group.** Đổi từ bản Personal Team sang bản có group không làm mất quy tắc, và không đè quy tắc đã nằm trong group.
- **Xuất / nhập.** Đổi team thì iOS không cài đè khác chữ ký. Phải xóa app, tức mất dữ liệu cục bộ. Xuất trước, nhập sau.

## Ngưỡng

Apple không công bố trần số lượng của Call Directory. Extension còn bị giới hạn bộ nhớ và thời gian, cũng không có số chính thức. Mỗi chữ số đầu số ngắn đi làm số lượng nhân 10.

Trong app (`Limits`):

- `softCap = 1_000_000`. `mergedCount >= softCap` thì cảnh báo (`reachesSoftCap`), vẫn lưu.
- `hardCap = 2_000_000`. `mergedCount > hardCap` thì từ chối lưu (đường sửa trong app) hoặc không ghi `blocklist.bin` (đường nhập file). Đúng 2.000.000 vẫn được.
- `BlocklistFile.write` ném `exceedsHardCap` nếu tổng dải vượt `hardCap`.

PM ghi “cảnh báo khi > 1 triệu, chặn lưu khi > 2 triệu”. Lệch ở biên: code cảnh báo từ **đúng** 1.000.000, và **đúng** 2.000.000 vẫn lưu được.

Một đầu số ngắn hơn đích đúng `n` chữ số sinh `10^n` số. `10^6` chạm cảnh báo. `10^7` bị từ chối ngay ở `prefixSpan` vì `width > hardCap`.

Chưa đo trên máy. Nếu sau này reload trả `maximumEntriesExceeded`, extension biến mất, hoặc iOS giết extension, thu hẹp đầu số rồi mới tính chuyện nới `softCap`.

## Mốc

Cùng bảng với [prd.md](prd.md). Tóm tắt cho phần kỹ thuật, 27/11 UTC+7:

| Mốc | Trạng thái lúc 12:16 |
| --- | --- |
| M1 Scope và plan | Xong |
| M2 CRUD quy tắc, đầu số / số đầy đủ, bật tắt, validate, cảnh báo | Code xong, chưa compile |
| M3 Mở rộng E.164, sắp tăng, `blocklist.bin`, `addBlockingEntry` | Code xong. 19 test `BlockerCore` được báo pass trên Linux |
| M4 `reloadExtension` khi lưu, nút Tải lại, map lỗi CallKit trong `Vietnamese.reloadMessage` | Code xong |
| M5 `GuideView`, `ExtensionStatus` (`Đã bật` / `Chưa bật` / `Chưa rõ` / `Không đọc được`), `openSettings`, fallback `openSettingsURLString` | Code xong |
| M6 Build và thử trên iPhone thật | Chưa. Johnny dự kiến build khoảng 12:45, MacBook M1 Pro, macOS 15.7.9, Xcode 26.3 |

Code M2–M5 nằm ở Origin `170cf02` lúc 10:12, rồi ở GitHub `f1d89a4`.

## Rủi ro

- Call Directory không chạy trên Simulator. Chỉ thử chặn được trên iPhone thật.
- Personal Team thường từ chối App Groups với lỗi `Personal development teams do not support the App Groups capability`. Trang capability của Apple hiện vẫn đánh dấu App Groups cho tài khoản miễn phí, nhưng Xcode thường không ký. Mặc định `ENABLE_APP_GROUPS = NO`: app cài và sửa quy tắc được, extension nạp danh sách trống, banner **Chưa chặn được cuộc gọi**. Công tắc trong Cài đặt có thể không hiện. Profile miễn phí hết hạn sau 7 ngày.
- Muốn thử ký App Group trên máy hiện tại: đặt `ENABLE_APP_GROUPS = YES` rồi build. Lỗi thì trả về `NO`.
- Chặn thật cần Apple Developer Program. Johnny đang đăng ký. Team trả phí thường active sau 1–2 ngày. Khi active: đổi `TEAM_ID`, đặt `ENABLE_APP_GROUPS = YES`, xuất quy tắc, xóa app cũ, cài lại, nhập quy tắc, bật công tắc.
- Lần build Xcode đầu có thể mất khoảng 15–30 phút sửa lỗi ký, bundle id, hoặc team bị ghi cứng. Chưa có kết quả build nên đây là ước lượng, không phải lỗi đã thấy.
- Không có trần Apple để bám. 100.000 số của `028888` là cỡ để thử trước. 1 triệu và 2 triệu chưa đo bộ nhớ hay thời gian nạp.
- Dạng số nhà mạng phải trùng E.164 đã nạp. Nếu cuộc gọi `028…` không khớp, thử một quy tắc số đầy đủ với máy thứ hai trước khi kết luận đầu số sai.
- Không chặn SMS, FaceTime, cuộc gọi đã nối.
- Đổi team bắt buộc xóa app. Quên xuất quy tắc là mất `rules.json` cục bộ.

## Việc còn mở

- Kết quả build Xcode đầu (dự kiến khoảng 12:45) và lỗi compile hoặc ký phải sửa.
- Personal Team của máy Johnny có ký được App Group hay không.
- Đo bộ nhớ và thời gian nạp với 100.000 số, rồi mới xét lại ngưỡng 1.000.000 / 2.000.000.
- `TEAM_ID` của team trả phí, sau khi Developer Program active. Khi đó bật App Groups.
- Đổi `BUNDLE_PREFIX` từ `dev.changeme.chancuocgoi` sang id thật chưa ai đăng ký.
- Thử chặn trên iPhone: số đầy đủ của máy thứ hai trước, rồi đầu số `028888`.
- Android (`CallScreeningService`, đầu số / hậu tố / số đầy đủ, đếm và lịch sử) chưa bắt đầu.

## Lệch so với ghi chú — lấy theo code

- Cảnh báo từ `mergedCount >= 1_000_000`. Từ chối khi `mergedCount > 2_000_000`. Đúng 2.000.000 vẫn ghi `blocklist.bin`.
- Chuẩn hóa nhận đủ `0…`, `84…`, `+84…`, `0084…`.
- `ActivityView` chỉ phục vụ xuất. Nhập là `fileImporter`.
- `ExtensionStatus` có `failed`, UI hiện **Không đọc được**, ngoài ba nhãn Đã bật / Chưa bật / Chưa rõ.
- Banner **Chưa chặn được cuộc gọi** là `StorageNotice` khi lưu cục bộ. Sau một lần lưu không có App Group, banner sự kiện là “Đã lưu trên máy. Chưa chặn được cuộc gọi vì chưa có App Group.”
- M1 theo dev là scope và plan. Target SwiftUI, extension và file entitlement App Group đã có trong repo, nhưng cờ build đang `NO` và chưa có lần compile.
