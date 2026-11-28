---
title: P0 UI/UX brainstorm (fresh redo) — Chặn cuộc gọi iOS
type: brainstorm
date: 2026-11-28 01:58 (Asia/Saigon)
branch: johnnybui1911/p0-ui-ux-redo
status: awaiting owner approval — no code written
---

# P0 UI/UX brainstorm — Chặn cuộc gọi (iOS)

## Summary

I recommend **Direction A, "Lá chắn"**: one home screen with a single protection status, one primary button ("Chặn số"), and the blocked list underneath. It drops the tab bar, the "Quy tắc" vocabulary and the manual reload button, and it turns the Settings guide into a setup sheet that only appears when blocking is not active.

The strongest research finding is a positioning one. Of 42 one- and two-star Vietnamese reviews of Truecaller from 2026 in the App Store feed, 13 say that blocking by prefix ("đầu số", 024/028) does not work, usually after paying for Premium. Blocking by prefix is exactly what this app does, so the UI should lead with "chặn đầu số" and be honest about its limit (a prefix needs at least 6 digits).

Nothing here changes the code. Six questions at the end need the owner's answer before a plan is written.

## Contract

- **Outcome:** an approved UI/UX direction and a Vietnamese wording set for the P0 app, so that a user whose goal is "block this number" can do it without learning what a rule, an extension or E.164 is.
- **Constraints:**
  - iOS Call Directory only. The app cannot see incoming calls, so it has no real "calls blocked" count or history (`plans/prd.md`, "Hành vi khi có cuộc gọi"). Any tile showing blocked-call statistics would be fabricated and is ruled out.
  - Truthful data the UI can show: protection status (on / off / unknown / unreadable), how many numbers are covered, how many entries the user added, capacity against the 2,000,000 limit, and the result of the last save.
  - Prefixes need at least 6 digits. Blocking all of 024 or 028 is impossible on iOS.
  - Deployment target is iOS 16.0 (`project.yml`). Liquid Glass APIs are iOS 26 only, so glass needs a material fallback or a raised minimum version.
  - Keep every existing capability: add, edit, delete, turn on/off, note, export/import, storage warnings.
- **Non-goals:** spam database, caller ID, number lookup, community reports, accounts, subscriptions, ads, Android, SMS blocking, any change to `BlockerCore` blocking logic.
- **Acceptance criteria for this brainstorm:** three different directions with visual references, a wording table, competitor findings, one recommendation, open questions, and owner sign-off before any plan or code.

## What the app looks like today

Two tabs ("Quy tắc", "Hướng dẫn") plus an editor sheet. The first screen stacks a serif title, up to three notices, a status card, a count, the rule list, and a pinned "Tải lại danh sách chặn" button. The editor asks the user to pick a type, enter a number, and tune "Độ dài E.164" with a stepper. User-facing text contains "quy tắc", "extension", "CallKit", "E.164", "App Group", "chuẩn hóa" and "Personal Team". The Guide tab mixes the four-step user instructions with developer signing notes.

## Competitor findings

Sources: App Store VN lookup API, all store screenshots, and the VN and US review feeds (most recent and most helpful, about 100 reviews per app), fetched 2026-11-28.

One correction to the brief: the three links are labelled one app off. `id1047334922` is **Mr. Number** (Hiya), `id1124167631` is **Call Control**, and `id1180310843` is **Call Blocker** (DEEPDY). None of them is Truecaller, so I added Truecaller (`id448142450`) as a fourth.

| | Truecaller | Mr. Number | Call Control | Call Blocker |
| --- | --- | --- | --- | --- |
| VN rating (count) | 4.4 (8,954) | 4.6 (27) | 4.8 (92) | 4.8 (65) |
| Last update | 2026-11-23 | 2023-07-10 | 2022-04-05 | 2026-10-21 |
| Vietnamese UI | Yes | No | No | No |
| Navigation | 4–5 tabs: Trang chủ, Bảo vệ, Trợ lý, Phần thưởng, eSIM | 4 icon-only tabs: keypad, recents, stats, settings | Home activity feed plus drill-downs | 5 tabs: Home, Search, Blocked, Contacts, Protection |
| Where the personal block list lives | Under Bảo vệ, behind Premium | Settings → Call Blocking → Blocked Numbers (3 levels deep) | "Block & Report number" field on home | Own tab, red "Block phone number" button pinned at the bottom |
| Hero pattern | Green shield, "Được bảo vệ 100%", one toggle | Keypad | Shield and community counter | Shield, "Full Protection", two toggles |
| Visual style | White cards on saturated blue, green shield | Flat navy and blue, pink "Unblock" pills | Blue, condensed caps | Teal gradient, tilted phones, red CTA |
| Business model | Subscription, ads, eSIM upsell | Subscription | Subscription | Subscription, ads, credits |

Screenshots worth opening:

- Truecaller "Bảo vệ thư rác" hero: <https://is1-ssl.mzstatic.com/image/thumb/PurpleSource211/v4/59/7c/0c/597c0c54-8cf8-2548-524f-b59ac2ffa401/Truecaller_App_Store_vi_vietnamese_9.png/600x1300bb.jpg>
- Mr. Number block list: <https://is1-ssl.mzstatic.com/image/thumb/PurpleSource124/v4/e1/74/c1/e174c104-27b2-060a-a05d-859d232ead58/32d92fbe-900e-4f1f-864e-8245b06f16d8_blocklist_5-5.png/600x1300bb.jpg>
- Call Blocker block list with pinned button: <https://is1-ssl.mzstatic.com/image/thumb/Purple126/v4/bc/d9/e8/bcd9e8f7-e57f-ba01-71d6-f1c683f2957f/3a406e3c-d9e8-47df-86c0-ab947c1bdf53_iPhone_-_4_opaque.png/600x1300bb.jpg>
- Call Control home: <https://is1-ssl.mzstatic.com/image/thumb/Purple123/v4/d8/d6/00/d8d600d1-7f22-9db8-b3ef-d864aa5c7dc8/mzl.spbxaiwn.jpg/600x1300bb.jpg>

### What reviewers complain about

**Truecaller, Vietnam store (69 reviews sampled, 54 at one or two stars).** Among the 42 low reviews from 2026:

- 13 name prefix blocking failing. Examples: "Dùng bản premium hoàn toàn không chặn được đầu số 024 028", "Chặn tiền tố số có chặn được đâu", "Mua pre mà ko chặn đc 11 số, cũng đầu số đấy chỉ chặn đc 10 số", and one three-star review saying Premium allows only five number series with no delete button.
- 24 mention having paid and feeling cheated.
- Across all years, 9 low reviews are about OTP, sign-up or locked accounts, and 3 say spam increased after installing.
- Other themes: full-screen ads with no close button, and caller names that stop appearing after a month or two.

**Mr. Number, Call Control and Call Blocker** have almost no Vietnamese reviews, so these themes come from the US feed (about 40% one-star in each sample for the first two):

- "It doesn't block anything" is the top complaint in all three. Several reviewers never finished the Settings step and nothing in the app told them so. One Call Control reviewer asks for "a video or something".
- No feedback that blocking is working: "There's no record kept of what numbers were blocked", "They don't give you the metrics".
- Prefix or area-code blocking is advertised and then missing or broken (Call Control: "Unable to block area code in iOS"; Mr. Number: a six-digit prefix that still rang).
- Contacts blocked by mistake, numbers disappearing from the block list, paywalls on features that were free, and privacy fears about contact upload.

### What to take and what to leave

| Decision | Competitors' way | Our way | Recommendation |
| --- | --- | --- | --- |
| First screen | A status hero that claims "100% protected" | A status hero that states only what is true | Take the hero pattern, drop the percentage. Say "Đang chặn 100.000 số". |
| Adding a number | 2–3 levels deep, or behind a paywall | One button on the home screen | Take Call Blocker's always-visible "Block phone number" button. |
| Prefix blocking | Hidden under "spoofing" or Premium, often broken | The core feature | Lead with it in copy and in the App Store listing later. |
| Setup in Settings | A help page the user must find | A blocking state on the home screen until it is done | Make "not turned on" impossible to miss, with a deep link. |
| Proof that it works | Fake or missing | Not available from iOS | Offer a guided self-test ("gọi thử từ số khác") instead of a counter. |
| Navigation | 4–5 tabs | No tabs | Leave tabs out. The app has one list. |
| Accounts, contacts, ads | Required | None | Say so in the UI: "Không cần tài khoản. Không đọc danh bạ." |
| Lookup, community, eSIM | Core to their model | Out of scope | Leave out. |

## Refero references

Refero has no call-blocker app, so these come from security, banking and blocker products (iOS screens).

| Reference | Why it matters |
| --- | --- |
| [1Password Watchtower, dark](https://refero.design/screens/b7ba5698-6344-4272-b9be-d46598f3b4fd) | One large status reading on true black, a plain-language line under it, cards below. |
| [Google Security Checkup](https://refero.design/screens/edb61a1f-e5b8-4b00-87f9-0e7704a309f2) | Shield, one sentence ("Your account is now protected"), then a checklist of ticked rows. |
| [Opal home](https://refero.design/screens/9689fec6-82f1-48bc-9682-94552b922ec2) | A single glowing 3D object as the hero and one full-width "Block Now" pill. This is what "restrained 3D" looks like in a shipped blocker. |
| [Checker boards](https://refero.design/screens/0a3f233e-9341-457e-9c3c-d1d8b58f88d9) | A 2×2 bento on black where each tile has one number and one tint. |
| [Clearful tiles](https://refero.design/screens/5227f304-f991-410b-8b04-8806ba2f4f25) | An asymmetric bento: one large primary-action tile beside smaller ones. |
| [1Password Watchtower cards](https://refero.design/screens/c8b60fa2-da8b-4fbd-8f95-e05df4727cbc) | Stacked metric cards, each with a count and a "Show items" link (metadata only, image not inspected). |
| [Rewind extension setup](https://refero.design/screens/bb087baa-b73f-493e-9568-567086ba3c11) | Four numbered steps with cropped Settings screenshots and one "Go to Settings" button. |
| [Glow extension setup](https://refero.design/screens/1cfe1d63-da16-4db1-aa8a-471b98958fb4) | One step per page and a confirming button, "I've Enabled It". |
| [Airbuds phone entry](https://refero.design/screens/8d1e72b1-31fb-475b-b537-35c908774cf2) | One large number field, the system number pad, nothing else. |
| [Linktree links](https://refero.design/screens/028904a8-4c61-4ba6-80ed-578053c0af77) | A full-width "Add" pill above a list of cards with a switch each, and an inline warning inside the affected card. |
| [Wise scam warning](https://refero.design/screens/63bab791-4b4d-426c-bda5-a9ed51f58b8e) | A calm full-screen warning with one icon and short sentences (metadata only). |

![1Password Watchtower](https://images.refero.design/screenshots/68/mobile/3aaa5c70-37ca-454c-836c-ed941cde4b2d_thumb.jpg)
![Opal home](https://images.refero.design/screenshots/76/mobile/58bd7d28-662b-42aa-a633-62ea4a1c8635_thumb.jpg)
![Checker boards](https://images.refero.design/screenshots/210/mobile/17669302-f5dd-40cd-964d-32c9134203e9_thumb.jpg)
![Rewind setup](https://images.refero.design/screenshots/137/mobile/8e7f2aee-615e-4757-8b47-8b05b132d7e4_thumb.jpg)
![Airbuds phone entry](https://images.refero.design/screenshots/150/mobile/952c4091-ea0f-463a-bc3d-0221190b8403_thumb.jpg)
![Linktree links](https://images.refero.design/screenshots/24/mobile/a60a40e3-949e-4156-a7e4-daee6dac4205_thumb.jpg)

## Shared by all three directions

These follow from the research and the brief, so they do not vary between directions.

- **No tab bar.** One home screen, one "Chặn số" sheet, one setup sheet. Export, import and technical details sit in a single "…" menu.
- **One input for adding.** The user types or pastes a number. The app decides whether it is one number or a prefix from its length and shows the result live: "Chặn 1 số: 028 3823 4567" or "Chặn 100.000 số bắt đầu bằng 028 888". Landline versus mobile length is inferred from the leading digits, and the manual length control moves under "Nâng cao".
- **No reload button.** Saving already reloads the list. A "Thử lại" button appears only when a reload fails.
- **Setup is a state.** While blocking is off, the home screen says so and the main button opens the setup sheet. After setup the sheet is reachable from the "…" menu.
- **Dark mode is the design target**, true-black background, one accent colour, and three state colours (green on, amber needs attention, red off). Light mode is derived from it.
- **Micro-interactions:** the status object changes state with a short morph, the count rolls to its new value after a save, a new row slides in at the top with a success haptic, and switches and swipe actions use system behaviour. All of them respect Reduce Motion.
- **Glass and 3D stay on one element each:** glass on the floating button bar or sheet chrome, depth on the status object. Body text never sits on glass.

## Direction A — "Lá chắn" (status first)

The home screen answers one question: is my phone protected? A shield with slight depth sits at the top, the sentence under it carries the state, a full-width "Chặn số" pill follows, and the list starts immediately below.

```text
┌──────────────────────────────┐
│ Chặn cuộc gọi            ⋯  │
│                              │
│            ◈ shield          │
│        Đang bảo vệ           │
│   Đang chặn 100.001 số       │
│                              │
│ ┌──────────────────────────┐ │
│ │        ＋ Chặn số        │ │
│ └──────────────────────────┘ │
│                              │
│ Số đang chặn (3)             │
│ 028 888…        100.000 số ◉│
│ Spam vay tiền                │
│ 090 123 4567        1 số   ◉│
│ 024 7300…        10.000 số ○│
└──────────────────────────────┘
```

- **Screens:** home, "Chặn số" sheet, setup sheet. Three in total.
- **References:** Truecaller "Bảo vệ thư rác", Google Security Checkup, 1Password Watchtower, Opal home, Linktree list.
- **Trends applied:** high-contrast dark, one restrained 3D object, glass on the button, state-morph micro-interaction. No bento.
- **Depends most on:** users opening the app mainly to check or to add one number, so a status and one button are enough.
- **Fails first when:** the list grows past a screen or two, because the hero pushes it down. A collapsing hero on scroll and a search field above 20 entries cover that.

## Direction B — "Bảng điều khiển" (bento)

The home screen is a bento grid. A large status tile sits beside a "Chặn số" tile, with smaller tiles for the number count, capacity used, the entry list preview and setup.

```text
┌──────────────────────────────┐
│ Chặn cuộc gọi            ⋯  │
│ ┌──────────────┐ ┌─────────┐ │
│ │ ◈            │ │    ＋   │ │
│ │ Đang bảo vệ  │ │ Chặn số │ │
│ └──────────────┘ └─────────┘ │
│ ┌─────────┐ ┌──────────────┐ │
│ │ 100.001 │ │ Dung lượng   │ │
│ │ số chặn │ │ ▓░░░░░  5%   │ │
│ └─────────┘ └──────────────┘ │
│ ┌──────────────────────────┐ │
│ │ Số đang chặn (3)      ›  │ │
│ │ 028 888… · 090 123 4567  │ │
│ └──────────────────────────┘ │
│ ┌──────────────────────────┐ │
│ │ Gọi thử để kiểm tra   ›  │ │
│ └──────────────────────────┘ │
└──────────────────────────────┘
```

- **Screens:** home grid, full list, "Chặn số" sheet, setup sheet. Four in total.
- **References:** Checker boards, Clearful tiles, 1Password Watchtower cards.
- **Trends applied:** bento grid, glass tiles, tilt on the status tile, count-up numbers. This is the most "2026" of the three.
- **Depends most on:** having enough truthful metrics to fill a grid.
- **Fails first when:** the tiles are counted. The app has two real numbers (numbers covered, capacity). The rest of the grid is navigation dressed as data, and the list moves one tap further away, which works against "few pages, few buttons". It also invites adding a fake "calls blocked" tile later.

## Direction C — "Bàn phím" (input first)

The app opens straight into a number field, like the Phone keypad. Typing shows the live result and one "Chặn" button. The status is a small pill at the top and the list is a sheet pulled up from the bottom.

```text
┌──────────────────────────────┐
│ ● Đang bảo vệ            ⋯  │
│                              │
│   Nhập số hoặc đầu số        │
│                              │
│        028 888_              │
│  Chặn 100.000 số bắt đầu     │
│  bằng 028 888                │
│                              │
│ ┌──────────────────────────┐ │
│ │          Chặn            │ │
│ └──────────────────────────┘ │
│   1    2    3                │
│   4    5    6                │
│   7    8    9                │
│  Dán   0    ⌫                │
│ ━━━ Số đang chặn (3) ━━━━━━━ │
└──────────────────────────────┘
```

- **Screens:** input home with a list drawer, setup sheet. Two in total, the fewest.
- **References:** Mr. Number keypad, Truecaller search field, Airbuds phone entry.
- **Trends applied:** minimal steps (block in one screen), glass keypad keys, key-press haptics.
- **Depends most on:** adding numbers being the main reason to open the app.
- **Fails first when:** blocking is not turned on. A small status pill is easy to miss, and "it doesn't block anything" is the top competitor complaint. A user who has nothing to add also lands on an empty keypad every time, and most numbers will be pasted from Recents, so the custom keypad is rarely used.

## Trade-offs

| | A — Lá chắn | B — Bảng điều khiển | C — Bàn phím |
| --- | --- | --- | --- |
| Screens | 3 | 4 | 2 |
| Taps to block a number from launch | 2 plus typing | 2 plus typing | 1 plus typing |
| "Not turned on" visibility | Whole hero | One tile | Small pill |
| Fits real data | Yes | Thin: two metrics | Yes |
| Trend coverage | Dark, glass, 3D, micro-interactions | All five | Dark, glass, minimal steps |
| Build cost on current SwiftUI code | Low: restyle list screen, merge Guide | Medium: new grid plus separate list screen | Medium: custom keypad and drawer |
| Worst plausible case | Long list sits below the hero | Looks decorative, tempts fake stats | User never notices blocking is off |
| Cost to abandon later | Low: hero is one view | Medium | Medium |

## Recommendation

**Direction A.** It puts the one thing competitors fail at, telling the user whether blocking is on, in the largest element on screen, and it matches the truthful data the app has. It is also the smallest change to the current code.

Two pieces of the other directions belong inside it because they are the right answer regardless of layout:

- The single-field input with a live result from Direction C becomes the "Chặn số" sheet.
- The two real metrics from Direction B (numbers covered, capacity used) become one two-tile row under the hero, shown only when capacity passes 50%. That is the honest amount of bento for this app.

**Better approaches: one found.** The brief asks for bento as a 2026 trend. Inspection shows the app has two truthful metrics, so a full bento home (Direction B) would be mostly decoration. Using bento for one two-tile row costs nothing to switch to and keeps the trend where it carries information.

## Wording table

Vocabulary rules: the thing is a "số" or "đầu số", the collection is "Số đang chặn", and the action is "Chặn số". "Quy tắc", "extension", "CallKit", "E.164", "App Group" and "chuẩn hóa" never appear in user-facing text. Sentences are short and say what happens to the phone.

### Home

| Where | Now | Proposed |
| --- | --- | --- |
| Tab 1 / nav title | Quy tắc | (no tab) Chặn cuộc gọi |
| Tab 2 | Hướng dẫn | (removed, becomes setup sheet) |
| Subtitle | Chặn im lặng theo đầu số hoặc số đầy đủ. Máy không đổ chuông với số khớp quy tắc đang bật. | Số bạn chặn sẽ không làm máy đổ chuông. |
| Status, on | Đã bật | Đang bảo vệ |
| Status, on, detail | iOS đang dùng extension này cho cuộc gọi đến. | Đang chặn {n} số. |
| Status, off | Chưa bật | Chưa bật chặn |
| Status, off, detail | Vào Cài đặt > Điện thoại > Chặn cuộc gọi & Nhận dạng và bật công tắc của app. | Còn một bước trong Cài đặt để bắt đầu chặn. |
| Status, off, button | Mở phần Chặn cuộc gọi | Bật ngay |
| Status, unknown | Chưa rõ / Không đọc được | Chưa kiểm tra được |
| Status, unknown, detail | Chưa xác định được. Hãy mở Cài đặt và kiểm tra công tắc. | Mở Cài đặt để xem chặn cuộc gọi đã bật chưa. |
| Status, on but list empty | (none) | Đã bật. Thêm số đầu tiên để bắt đầu chặn. |
| Count label | Đang chặn / {n} số | Đang chặn {n} số |
| Merged note | Gộp từ {n} | (removed) |
| Section header | Quy tắc | Số đang chặn |
| Empty title | Chưa có quy tắc | Chưa chặn số nào |
| Empty body | Thêm một đầu số hoặc một số đầy đủ. Khi mọi quy tắc đều tắt, danh sách chặn để trống và không số nào bị chặn. | Nhập một số, hoặc vài số đầu để chặn cả dải số. |
| Add button | + (icon), "Thêm quy tắc" | Chặn số |
| Row tag, prefix | Đầu số | Đầu số |
| Row tag, full number | Số đầy đủ | Một số |
| Row detail, prefix | 8428888 · 100.000 số · đủ 12 chữ số | 100.000 số bắt đầu bằng 028 888 |
| Row detail, full number | 84901234567 · 1 số | (number only, formatted 090 123 4567) |
| Row switch label | Bật / Tắt quy tắc {số} | Đang chặn / Tạm ngưng chặn {số} |
| Row invalid | Quy tắc không hợp lệ và không được đưa vào danh sách. | Đầu số này quá ngắn nên chưa được chặn. Chạm để sửa. |
| Row large | Nhiều số — dễ vượt giới hạn bộ nhớ của extension. | Dải số này rất lớn. Thêm chữ số để chặn chắc hơn. |
| Swipe actions | Sửa / Xóa | Sửa / Bỏ chặn |
| Delete confirm | Xóa quy tắc này? / Xóa / Hủy | Bỏ chặn {số}? / Bỏ chặn / Giữ lại |
| Reload button | Tải lại danh sách chặn / Đang tải lại… | (removed; on failure only) Thử lại / Đang cập nhật… |
| Reload caption | {n} số sẽ được nạp vào CallKit. | (removed) |
| Menu, export | Xuất quy tắc… | Sao lưu danh sách |
| Menu, import | Nhập quy tắc… | Khôi phục danh sách |
| Menu, new | (none) | Cách bật chặn cuộc gọi |
| Import confirm | Thay toàn bộ quy tắc hiện có? / File JSON sẽ thay danh sách đang có trên máy này. / Thay thế | Thay danh sách hiện tại? / Các số đang chặn sẽ được thay bằng danh sách trong tệp. / Thay thế |

### "Chặn số" sheet

| Where | Now | Proposed |
| --- | --- | --- |
| Title, new | Thêm quy tắc | Chặn số |
| Title, edit | Sửa quy tắc | Sửa số chặn |
| Type picker | Loại: Đầu số / Số đầy đủ | (removed; detected from what is typed. Override under Nâng cao: Một số / Cả dải số) |
| Type help, prefix | Mọi số có đầu này, sau khi chuẩn hóa, sẽ bị chặn. | Chặn mọi số bắt đầu bằng {đầu số}. |
| Type help, full | Chỉ đúng một số, sau khi chuẩn hóa sang E.164. | Chỉ chặn đúng số này. |
| Field label | Số | Số điện thoại hoặc đầu số |
| Placeholder | 0…, 84… hoặc +84… | Ví dụ 028 888 hoặc 090 123 4567 |
| Live line | Chuẩn hóa: 8428888 | Sẽ chặn 100.000 số, từ 028 8880 0000 đến 028 8889 9999 |
| Length control | Độ dài E.164: 12 | (Nâng cao) Loại số: Số bàn (11 số) / Di động (10 số) |
| Length help | Mặc định 12 là số bàn Việt Nam: mã vùng kèm số 0… | Tự nhận theo đầu số. Chỉ đổi khi số bạn muốn chặn có độ dài khác. |
| Note | Ghi chú / Không bắt buộc | Ghi chú / Ví dụ: spam vay tiền |
| Enable switch | Bật quy tắc này | Chặn ngay |
| Estimate section | Ước tính / Số lượng / Từ … / Đến … | (merged into the live line) |
| Buttons | Lưu / Hủy | Chặn (new) or Lưu (edit) / Hủy |
| Paste helper | (none) | Dán số |

### Errors and notices

| Now | Proposed |
| --- | --- |
| Hãy nhập đầu số hoặc số điện thoại. | Nhập số bạn muốn chặn. |
| Chỉ dùng chữ số, dấu +, khoảng trắng, dấu gạch, dấu chấm hoặc ngoặc. | Số điện thoại chỉ gồm chữ số. |
| Chỉ nhận số Việt Nam dạng 0…, 84…, +84… hoặc 0084…. | Hiện chỉ chặn được số Việt Nam (bắt đầu bằng 0 hoặc +84). |
| Đầu số phải có ít nhất 6 chữ số, tính cả số 0 đầu. Ví dụ 028888 hoặc 090123. | Nhập ít nhất 6 số đầu, ví dụ 028 888. iPhone không cho chặn dải số rộng hơn. |
| Đầu số đã dài bằng hoặc hơn độ dài đích. Hãy chọn Số đầy đủ, hoặc tăng độ dài E.164. | (no longer reachable once type is auto-detected) |
| Số đầy đủ quá ngắn sau khi chuẩn hóa… | Số này còn thiếu chữ số. |
| Số đầy đủ dài {n} chữ số. E.164 tối đa 15. | Số này dài quá. Kiểm tra lại giúp nhé. |
| Đầu số này tạo ra {n} số, vượt giới hạn 2.000.000… | Dải số này quá lớn. Nhập thêm chữ số để thu hẹp. |
| Tổng số sau khi gộp là {n}, vượt giới hạn… Hãy tắt bớt quy tắc hoặc nhập đầu số dài hơn. | Danh sách đã đầy ({n}/2.000.000 số). Bỏ bớt một dải số rồi thử lại. |
| Danh sách đang bật có từ 1.000.000 số trở lên. iOS có thể tắt extension… | Danh sách đang rất lớn. Nếu thấy chặn không ổn định, hãy bỏ bớt dải số. |
| Đã lưu quy tắc. / Đã nạp danh sách vào CallKit. | Đã chặn {số}. |
| Đã xóa quy tắc. | Đã bỏ chặn {số}. |
| Đã bật quy tắc. / Đã tắt quy tắc. | Đang chặn {số}. / Đã tạm ngưng chặn {số}. |
| Đã nhập {n} quy tắc. | Đã khôi phục {n} số chặn. |
| File không phải danh sách quy tắc của app này. | Tệp này không phải bản sao lưu của Chặn cuộc gọi. |
| Extension chưa được bật. Vào Cài đặt > Điện thoại > Chặn cuộc gọi & Nhận dạng. | Chưa bật chặn cuộc gọi trong Cài đặt. Chạm "Bật ngay". |
| Extension đang tải. Đợi vài giây rồi thử lại. | Đang cập nhật danh sách. Đợi vài giây nhé. |
| Việc tải danh sách bị gián đoạn. Hãy thử lại. | Cập nhật chưa xong. Chạm "Thử lại". |
| iOS từ chối vì quá nhiều số… | iPhone không nhận vì danh sách quá lớn. Bỏ bớt dải số rồi thử lại. |
| Danh sách không tăng dần / có số trùng. Đây là lỗi của app… | Có lỗi từ phía ứng dụng. Số của bạn vẫn được lưu. Chạm "Thử lại". |
| Chưa chặn được cuộc gọi (App Group / Personal Team text) | Bản cài thử này chưa chặn được cuộc gọi. Số bạn nhập vẫn được lưu. (details under "Thông tin kỹ thuật") |

### Setup sheet (was the Hướng dẫn tab)

| Where | Now | Proposed |
| --- | --- | --- |
| Title | Bật chặn cuộc gọi | Bật chặn cuộc gọi |
| Intro | Call Directory chỉ có tác dụng trên iPhone thật, sau khi bạn bật extension trong Cài đặt. Simulator không chặn cuộc gọi. | iPhone cần bạn cho phép một lần. Mất khoảng 10 giây. |
| Step 1 | Mở ứng dụng Cài đặt. | Chạm "Mở Cài đặt" bên dưới. |
| Step 2 | Chọn Điện thoại. | Chọn Điện thoại. |
| Step 3 | Chọn Chặn cuộc gọi & Nhận dạng. | Chọn Chặn cuộc gọi & Nhận dạng. |
| Step 4 | Bật công tắc cạnh "Chặn cuộc gọi". | Bật công tắc "Chặn cuộc gọi", rồi quay lại đây. |
| Primary button | Mở phần Chặn cuộc gọi | Mở Cài đặt |
| Secondary button | Mở Cài đặt của app | (removed; automatic fallback) |
| Success | (none) | Đã bật. Máy sẽ không đổ chuông với số bạn chặn. |
| Self-test | (none) | Muốn kiểm tra? Chặn số của một máy khác rồi gọi thử. |
| Footer | Chặn im lặng là hành vi của Call Directory: máy không đổ chuông. App không xem lịch sử cuộc gọi và không lưu số đã chặn. | Không cần tài khoản. Không đọc danh bạ hay lịch sử cuộc gọi. Mọi thứ nằm trên máy bạn. |
| Developer section | Personal Team và App Group / App Group dự kiến / Bundle ID extension | Thông tin kỹ thuật (collapsed, reached from the "…" menu) |

## Unresolved questions

1. **Auto-detecting the type.** Is it acceptable to remove the "Đầu số / Số đầy đủ" picker and decide from the length typed (complete length means one number, shorter means a prefix), with a manual override under "Nâng cao"? This changes the editor's behaviour, not only its labels.
2. **Per-number on/off switch.** Keep the switch on every row as today, or move "Tạm ngưng chặn" into the swipe actions so each row has no control on it? The second is cleaner; the first keeps the feature one tap away.
3. **Minimum iOS version.** Stay on iOS 16 with material blur as the glass effect, or raise the minimum to iOS 26 for real Liquid Glass? Staying on 16 means two code paths for glass.
4. **Accent colour and tone.** The current theme is warm paper with a red seal. Competitors are all blue or teal. Options are a green-on-black "protected" palette, or keeping red as a brand accent with green reserved for the on state. Which should the mock-ups use?
5. **Settings path wording.** Truecaller's Vietnamese listing writes the path as "Cài đặt > Ứng dụng > Điện thoại > Chặn cuộc gọi & Nhận diện", while the app says "Cài đặt > Điện thoại > Chặn cuộc gọi & Nhận dạng". The exact labels differ by iOS version and need checking on the owner's iPhone before the steps are finalised.
6. **Next deliverable.** After a direction is approved, should the next step be static mock-ups of the three screens for review, or go straight to an implementation plan?
