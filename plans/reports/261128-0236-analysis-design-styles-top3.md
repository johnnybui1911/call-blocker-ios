---
title: Design style analysis — 8 styles scored, top 3, revised directions
type: analysis
date: 2026-11-28 02:36 (Asia/Saigon)
branch: johnnybui1911/p0-ui-ux-redo
status: awaiting owner's pick — no mockups built for this round
---

# Phân tích 8 phong cách thiết kế cho Chặn cuộc gọi

## Tóm tắt (tiếng Việt)

Ba phong cách nên chọn, theo điểm:

1. **Tối giản (Minimalism), 33/35.** Nền sáng, một việc chính trên mỗi màn hình, chữ lớn. Đây là phong cách dễ đọc nhất cho người lớn tuổi và làm giống hệt nhau trên iOS lẫn Android.
2. **Nền tối tương phản cao (High-contrast dark), 31/35.** Đây là "ngôn ngữ" quen thuộc của app bảo mật (1Password, Opal). Nên làm thành giao diện tối của cùng một hệ thống, không thay giao diện sáng.
3. **Vi tương tác (Micro-interactions), 29/35.** Người dùng app đối thủ phàn nàn nhiều nhất là "không biết app có chặn không". Chuyển động và rung phản hồi trả lời câu hỏi đó ngay lúc bấm "Chặn".

Nên bỏ:

- **Giọng nói (20/35):** nghe sai một chữ số là chặn nhầm số, và phải xin thêm quyền micro trong một app đang hứa "không cần quyền gì".
- **Glassmorphism (20/35):** chữ trên nền mờ khó đọc, nhất là với người lớn tuổi.
- **Agentic / gợi ý tự động (21/35):** iOS không cho app biết ai vừa gọi, nên câu "Số lạ 028888… vừa gọi 3 lần" không làm thật được trên iPhone. Android thì làm được, nên hai nền tảng sẽ lệch nhau.
- **Bento (25/35):** app chỉ có hai con số thật (số đang chặn, dung lượng), không đủ để lấp một lưới ô.

**Liquid Glass của Apple (23/35)** không vào top 3 vì chỉ có trên iOS 26 và Android không có tương đương. Tuy vậy app build bằng Xcode 26 sẽ tự có Liquid Glass ở thanh công cụ, sheet và nút hệ thống trên máy iOS 26. Đề xuất: nhận phần "miễn phí" đó, không lấy nó làm bản sắc riêng.

Về ba hướng bố cục cũ: **A (Lá chắn) giữ lại**, **B (Bento) bỏ**, **C (Bàn phím) sửa thành "Ô nhập"** dùng bàn phím số của hệ thống. Thêm hướng mới **D (Danh sách)** giống màn hình Cài đặt của iOS, thay cho B.

Cần chủ sở hữu quyết: chọn 3 phong cách để dựng mockup, và 3 mockup đó dùng chung một bố cục (đề xuất: A) hay mỗi phong cách một bố cục.

## Scope and method

The brief names nine items, but "Liquid Glass + restrained 3D" and "Apple's Liquid Glass (iOS 26 native)" are the same material, so I scored eight styles: Minimalism, High-contrast dark, Micro-interactions, Bento grid, Apple Liquid Glass (with restrained 3D), Generative/Agentic UI, Glassmorphism, and Voice UI.

Each style is scored 1 to 5 on seven criteria, for a maximum of 35. The cross-platform criterion was added at the owner's request: the app is SwiftUI now and will be ported to Jetpack Compose.

Evidence comes from fresh Refero searches for each style in this round (eight searches, not the earlier set), the competitor research in `261128-0158-brainstorm-p0-ui-ux-redo.md`, the design-skill style database, and one web search on the iOS 26 glass APIs. I opened six Refero images (Meta AI, Wabi, ID by amo, Drops, Siri, MSCHF). The other references are cited from Refero's descriptions only.

## Scoring table

| Style | Trust and security feel | Simplicity | Accessibility and readability | SwiftUI feasibility | iOS + Android feasibility | Fit for older Vietnamese users | Evidence | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Minimalism | 4 | 5 | 5 | 5 | 5 | 5 | 4 | **33** |
| High-contrast dark | 5 | 4 | 4 | 5 | 5 | 3 | 5 | **31** |
| Micro-interactions | 4 | 4 | 4 | 5 | 4 | 4 | 4 | **29** |
| Bento grid | 3 | 3 | 4 | 4 | 5 | 3 | 3 | 25 |
| Apple Liquid Glass + restrained 3D | 4 | 4 | 3 | 4 | 2 | 3 | 3 | 23 |
| Generative / Agentic UI | 3 | 3 | 4 | 3 | 2 | 3 | 3 | 21 |
| Glassmorphism | 3 | 3 | 2 | 4 | 3 | 2 | 3 | 20 |
| Voice UI | 2 | 4 | 3 | 3 | 3 | 3 | 2 | 20 |

The scores are my judgement from the evidence below, not measurements. No user testing with older Vietnamese users has been done; that column rests on general readability principles and on the fact that the Vietnamese-language competitor (Truecaller) ships a light, large-type interface.

## Style by style

### 1. Minimalism — 33, top 3

- **Fit:** one status, one action, one list is already what the app is. Competitor reviews complain about ads and clutter, and a quiet screen is the opposite signal.
- **Risk:** taken too far it looks unfinished or cheap, which costs trust. It needs one crafted element (the shield) and careful type.
- **iOS and Android:** system fonts, plain surfaces and lists map one-to-one to SwiftUI and Compose. Nothing must differ except platform controls (switch, sheet).
- **Refero:** [Notion list](https://refero.design/screens/84643e38-0e5e-4bac-bac8-923edb8beeb7), [CARROT mission list](https://refero.design/screens/c1dd08ac-f85e-4c6a-b647-c13992c24ca1), [Haptic home](https://refero.design/screens/6aebad64-942e-4473-9fbc-709308209cb1), and from the first round [Google Security Checkup](https://refero.design/screens/edb61a1f-e5b8-4b00-87f9-0e7704a309f2).

### 2. High-contrast dark — 31, top 3

- **Fit:** the strongest security convention in the references. A single precise accent on black reads as serious and protective.
- **Risk:** many older users keep their phone in light mode with large text, and pure white on pure black tires some eyes. It should be the dark appearance of the same system, following the phone's setting, and state must never be carried by colour alone (icon plus words).
- **iOS and Android:** colour tokens, Dynamic Type on iOS and font scale on Android. Fully shared.
- **Refero:** [MSCHF](https://refero.design/screens/48f3dda6-8444-4ac8-89a5-e99ee69b642b) (black, white mono type, one yellow button), [(Not Boring) Habits](https://refero.design/screens/ba1c208f-2f2c-4ce9-a3ff-894dc203f0a4), [LookUp quiz](https://refero.design/screens/b99906a5-c633-460e-9088-cf6624a9eb22), and from the first round [1Password Watchtower](https://refero.design/screens/b7ba5698-6344-4272-b9be-d46598f3b4fd).

### 3. Micro-interactions — 29, top 3

- **Fit:** the top competitor complaint is "it doesn't block anything", and iOS gives the app no blocked-call count to show. A clear confirmation at the moment of blocking (shield stamp, haptic, the number sliding into the list) is the only honest proof the app can give.
- **Risk:** it is a layer, not a full visual identity, and it must honour Reduce Motion. Playful motion can undercut seriousness if overdone.
- **iOS and Android:** SwiftUI springs and haptics, Compose animation and haptic feedback. Share duration and easing tokens. Spring feel and haptic strength will differ slightly per platform.
- **Refero:** [Drops success check](https://refero.design/screens/efcb4da4-966c-4e0c-9193-b338d1c9d39e), [Foodvisor confetti check](https://refero.design/screens/ccbc9ce5-359f-46ba-96d6-7d054609d543), [Structured check](https://refero.design/screens/63d0450b-5828-42ee-a4f8-df8b61fd4f78), [Opal "Well Done"](https://refero.design/screens/4994424a-c8f8-4a23-96d8-38cb7e16ce82).

### 4. Bento grid — 25, drop as a home layout

- **Why not:** the app has two truthful metrics. The first mockup round showed the rest of the grid becomes navigation tiles, and several equal tiles split attention for a user who came to do one thing.
- **What survives:** a two-tile row (numbers covered, capacity) when capacity matters.
- **iOS and Android:** easy on both (`Grid`, lazy grids).
- **Refero:** [Wabi home](https://refero.design/screens/79aac046-3afd-49df-8fa1-b816375b4ccc), [Waterllama widgets](https://refero.design/screens/e9cd0b39-8dcb-422f-9e42-6a775a68d40c), [IFTTT widget](https://refero.design/screens/14e728cb-1daf-42ea-8093-78a73c49bf71). All are content-rich products; none is a single-purpose utility.

### 5. Apple Liquid Glass + restrained 3D — 23, adopt for free, do not build identity on it

- **Fit:** makes the app look current and native on iOS 26, which itself signals quality.
- **Why not top 3:** iOS 26 only, while the project targets iOS 16, so every custom glass surface needs a second code path. Android has no equivalent, so it is **iOS-first**. Text over glass also needs contrast care.
- **Shared fallback:** an opaque tonal surface with a hairline border, used on iOS 16 to 18 and on Android.
- **Refero:** [ID by amo](https://refero.design/screens/c3ec975c-1c3e-4acd-b68e-5c103e0e5e8c) (floating 3D object over sky, sheet below), [Telegram Face ID panel](https://refero.design/screens/ed552212-f2fe-48a4-a6ee-54cab7d97466), [ABY Journal 3D cloud](https://refero.design/screens/f0afc0e1-bb8f-4df8-b213-25808c4137cf). Refero has few iOS 26 screens yet.

### 6. Generative / Agentic UI — 21, drop

- **Why not:** the owner's example ("Số lạ 028888… vừa gọi 3 lần, chặn cả đầu số?") needs call data. iOS does not give it to apps, so on iPhone the only real suggestions come from the clipboard and the user's own list. A card claiming to know who called would also contradict the promise "không đọc lịch sử cuộc gọi".
- **iOS and Android:** Android's call screening service does see incoming calls, so the feature is real there and impossible on iOS. A shared design language cannot hide that gap.
- **What survives:** one contextual card for setup ("Còn một bước") and, later, call-based suggestions as an Android-only feature.
- **Refero:** [Meta AI home](https://refero.design/screens/ab0fd4cb-ab79-4745-b25e-4424970cd11f), [Microsoft Copilot](https://refero.design/screens/168b20b7-0c55-4c91-9d61-fd6b9754f907), [Structured AI](https://refero.design/screens/483a71c6-765a-4c53-a6cb-ce2bf1a72d2c).

### 7. Glassmorphism — 20, drop

- **Why not:** frosted content cards over colourful gradients lower text contrast, the opposite of what older users need, and the look reads as decorative rather than protective. None of the four competitors uses it.
- **iOS and Android:** SwiftUI materials work from iOS 15. Android backdrop blur needs API 31 or a library, with a flat fallback below that.
- **Refero:** [Arc Search tabs](https://refero.design/screens/317f8c64-742c-4896-bc3f-c1a33c20032c), [Meta modal in Instagram](https://refero.design/screens/09d1e425-b3d1-4ff3-a138-cf22d2e3c798), [Trip Way search overlay](https://refero.design/screens/6688eae1-f285-4b35-bc03-6092de6dd90c).

### 8. Voice UI — 20, drop

- **Why not:** blocking the wrong number is the costliest error in this app, and spoken digits are easy to mishear. Voice also needs microphone and speech-recognition permissions, in an app whose pitch is that it needs none.
- **iOS and Android:** both have speech APIs, so it is buildable, but recognition quality for Vietnamese digits and regional accents would need testing on both, and I have not verified on-device Vietnamese support.
- **What survives:** the dictation key on the system keyboard already gives voice input in the number field at no cost.
- **Refero:** [Siri](https://refero.design/screens/8dd54025-ec5d-427f-9889-37374ef952ca), [ChatGPT voice](https://refero.design/screens/37e79e78-e8c3-4c75-95f4-b481c7935ae0), [ElevenLabs orb](https://refero.design/screens/d4abfeba-c2f5-4885-8395-b6a9f40097ef), [Pi listening](https://refero.design/screens/ced14504-c151-4872-92f8-f768ec602c31). All are assistants; none is a utility.

## Liquid Glass versus Glassmorphism

| | Glassmorphism | Apple Liquid Glass (iOS 26) |
| --- | --- | --- |
| What it is | A visual trend from around 2020: static frosted cards with background blur, a translucent fill and a thin light border | Apple's system material: it bends and tints what is behind it, shows moving highlights, and morphs between shapes |
| Where it goes | Anywhere the designer puts it, usually content cards over a gradient | The control layer floating above content: toolbars, tab bars, sheets, buttons |
| SwiftUI | `.background(.ultraThinMaterial)` and similar, iOS 15 and later | Standard bars, sheets and controls adopt it automatically when built with the iOS 26 SDK. Custom surfaces use `.glassEffect(_:in:)`, `GlassEffectContainer` and `.buttonStyle(.glass)` |
| On this project (target iOS 16) | Works everywhere | Needs `if #available(iOS 26, *)` with a fallback such as `.ultraThinMaterial` or a bordered button |
| Android (Compose) | Backdrop blur from API 31 or via a library; flat translucent surface below that | No equivalent. Use the shared tonal-surface fallback |
| Accessibility | Contrast is the designer's problem | I could not confirm from the search how glass behaves with Reduce Transparency, so this needs a device test |

Because the project already builds with Xcode 26.3, system chrome will show Liquid Glass on iOS 26 devices without extra work. The decision is only whether to add custom glass surfaces on top, and I recommend not doing so.

## Top 3 and how they combine

Minimalism, High-contrast dark and Micro-interactions are the top three on score, and they are also the three that port to Android with one set of tokens, one layout and one motion spec.

They are not rivals. In the shipped app they stack: Minimalism is the structure, High-contrast dark is its dark appearance, and Micro-interactions is the feedback layer. For the mockup round each can still be pushed into its own identity so the owner can compare:

| Mockup | Identity |
| --- | --- |
| Tối giản | Light paper background, ink text, one accent, large type, almost no decoration |
| Tương phản cao | True black, white text, one precise non-green accent, heavier type, icon-plus-word states |
| Vi tương tác | Bright and friendly, rounded shapes, motion shown for real: tap to block, swipe a row, shield pulse |

## Earlier directions against the top 3

| Direction | Minimalism | High-contrast dark | Micro-interactions | Verdict |
| --- | --- | --- | --- | --- |
| A — Lá chắn (status first) | Fits. Flatten the shield and let the hero collapse on scroll | Fits as built | Fits best: the shield is the stage for feedback | **Keep**, with light mode as an equal and larger type |
| B — Bảng điều khiển (bento) | Conflicts: many tiles, little data | Works visually, same data problem | Tiles add motion targets without meaning | **Drop.** Keep only the two-tile stat row inside A |
| C — Bàn phím (input first) | Fits the single-purpose idea, but a custom keypad duplicates the system one | Fits | Key presses give good feedback | **Revise** into C′ below |

Revised direction list:

- **A — Lá chắn.** Status hero, one "Chặn số" button, list below. Three screens. Still the recommendation.
- **C′ — Ô nhập (replaces C).** The home screen is a status line, one large number field using the system number pad, and the list. Blocking happens without opening a sheet. Two screens. Its weak spot is unchanged: "chưa bật chặn" is less prominent than in A.
- **D — Danh sách (new, replaces B).** Built like the iOS Settings app: large title, a status row at the top, the list, and an add button. It is the most native on both platforms and the cheapest to build, but the least distinctive and the weakest at signalling protection.

Bento is the only style whose removal takes a direction with it. No new direction is needed for the top three styles themselves; they all sit on A.

## Recommendation for the mockup round

Build the three chosen styles on the same layout (A), so the owner compares visual identity alone. The first mockup round failed for the opposite reason, and mixing both variables again would repeat it. Layout (A, C′ or D) can then be settled in the winning style with quick wireframes.

## Status of the stopped work

The six-trend mockup job was stopped as instructed. `plans/reports/mockups-v2/src/` holds the shared structure and logic plus three unfinished theme files (assistant, bento, liquid glass). Nothing there was built, rendered or click-tested, and there is no `index.html`. The shared files can be reused for the next round; the theme files for dropped styles can be deleted.

## Sources

- Apple: [glassEffect(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:).md), [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer.md), [Glass](https://developer.apple.com/documentation/swiftui/glass.md)
- Community references on availability gating and fallbacks: [LiquidGlassReference](https://github.com/conorluddy/LiquidGlassReference), [Understanding GlassEffectContainer in iOS 26](https://dev.to/arshtechpro/understanding-glasseffectcontainer-in-ios-26-2n8p), [Liquid Glass in Swift: official best practices](https://dev.to/diskcleankit/liquid-glass-in-swift-official-best-practices-for-ios-26-macos-tahoe-1coo)
- Refero screens linked in each section above

## Unresolved questions

1. Which three styles should be mocked up: the scored top three, or does the owner want Liquid Glass in place of one of them despite it being iOS-only?
2. Should the three mockups share layout A, or should each style get its own layout?
3. Light or dark as the default appearance? I recommend following the phone's setting, with both designed.
4. What is the minimum Android version for the later port? It decides whether any blur is available there at all.
5. Should the unfinished `mockups-v2/src/` files be kept for reuse or removed?
6. Not verified: Liquid Glass behaviour with Reduce Transparency, and on-device Vietnamese speech recognition on either platform.
