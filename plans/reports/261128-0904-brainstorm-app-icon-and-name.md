# App icon and app name — options for the owner

Date: 2026-11-28. Scope: research and mockups only; no app code was changed.
All files are in `plans/reports/261128-0904-icon-name/`.

## Recommendation

Name the app **ByeScam** and use icon **B** (green shield, phone handset, red "blocked" badge).
The owner needs to choose one name and one icon; the two choices are independent.

- **ByeScam** is the only fully English candidate with no app of that name on the App Store (VN or US) and no brand found on the web. Pick **AloStop** instead if older, non-English-speaking users matter more than an English name.
- **Icon B** is the only concept that shows all three ideas (protection, phone call, blocked) and still reads at Settings size.

## Brainstorm contract

- **Outcome:** the owner can choose a new English name and a new icon from researched, visual options.
- **Constraints:** approved palette and shield motif from `mockups-v3/src/tokens.json`; work only in `plans/reports/`.
- **Non-goals:** the AppIcon asset set, display name and localization changes, which follow the owner's choice.
- **Acceptance criteria:** competitor research, 5–8 name candidates with checks and a top 3, 3–4 icons at 1024×1024, home-screen previews in dark, light and tinted, and a recommendation.
- **Better approaches:** none — the recommended direction is the requested one (shield + phone in the approved green).

## 1. Competitor research

Source: App Store search API, Vietnam storefront, 2026-11-28. Raw icons are in `research/icons/`, the contact sheet is `research/competitor-icons.png`.

| App | Seller | VN ratings | Icon |
|---|---|---|---|
| Truecaller: Premium Caller ID | True Software Scandinavia | 8,954 | White handset on blue |
| CleanCall: Caller ID & Block | Vuong Nguyen Quoc (VN) | 5,874 | White shield line-mark with a star, on red |
| iCallme - Caller ID Lookup | Technology Application Center for Personal Data Protection (VN) | 3,009 | White handset on cyan-blue |
| Call Protect Spam Call Blocker | Kain Suite | 1,599 | White shield, blue handset, green check bubble |
| Số Lạ | Tuan Anh Vu (VN) | 962 | Green shield with handset on dark grey |
| vCaller | Inmoteck (VN) | 733 | White handset on purple |
| Chống làm phiền | Viettel | 310 | Yellow shield split by a green bar, on green |
| nTrust: Phòng chống lừa đảo | National Cybersecurity Association (VN) | 250 | Blue shield with a star, on white |
| Call Control: #1 Call Blocker | Call Control LLC | 92 | Blue shield with white handset |
| Hiya: Spam Blocker | Hiya | 84 | Purple handset in a ring, on white |
| Call Blocker | Deepdy | 65 | Teal shield with a slashed phone |
| Mr. Number Lookup & Call Block | Hiya | 27 | "mn" letters on blue |
| PrefixBlock: Spam Call Filter | Phung Doanh (VN) | 8 | Detailed illustration of a phone, "BLOCKED", shield |
| Chanso – Block Nuisance Calls | Dat Nguyen Quang (VN) | 5 | White shield outline with check, on blue |

What this shows:

- **Blue dominates.** Nine of the sixteen icons collected are blue. A neon-green shield on near-black is not used by anyone, so the approved palette is itself the differentiator.
- **Shield plus handset is the category code.** Users already read it as "call protection", which is exactly the understanding the current icon lacks.
- **Almost no one shows "blocked".** Only three of the sixteen (Deepdy, App Toro, PrefixBlock) use a slash or "no" sign, so a blocked mark sets us apart from caller-ID apps.
- **Names follow one pattern:** a short coined brand, then a descriptive keyword tail ("CleanCall: Caller ID & Block"). Vietnamese-made apps mostly use English brands (CleanCall, iCallme, vCaller, PrefixBlock).
- **Two direct competitors do prefix blocking:** PrefixBlock and Chanso, both with under 10 ratings.

The current icon is a red "no entry" sign on black. It shows neither a phone nor protection, and red is the app's own "protection is off" colour.

## 2. Name candidates

Checks run on 2026-11-28: exact-name search on the App Store (VN and US storefronts), DNS lookup for `.com`, `.app` and `.vn`, and one web search per name. Raw output is in `research/name-appstore-search.txt` and `research/name-domain-dns.txt`.

| # | Name | Meaning | Vietnamese pronunciation | App Store (exact name) | Domains | Web / brand conflicts |
|---|---|---|---|---|---|---|
| 1 | **ByeScam** | "Goodbye, scam" | "bai-xcam", 2 syllables. "Bye" is universal; "scam" is common slang among younger users, less known to older ones | None in VN or US | `.app` and `.vn` have no DNS; `.com` is parked for sale | None found. Nearby: "Bye Bye, Con Artist" (call blocker), "SpamBye" (SMS filter) |
| 2 | **AloStop** | "Alo" (how Vietnamese answer the phone) + "stop" | "a-lô-xtóp", every age group knows both words | None in VN or US | `.com`, `.app`, `.vn` all have no DNS | None found. Nearby: "Allostop Africa" (carpooling), "Alostopup". "Alo…" is a crowded Vietnamese prefix (AloTrip, Alo Ship) |
| 3 | **ScamOff** | "Scam: off" | "xcam-óp", 2 syllables | None in VN; none exact in US | `.vn` has no DNS; `.com` and `.app` taken | None found |
| 4 | NoScam | "No scam" | "nô-xcam", very easy | None exact | All three taken | **Conflict:** "NoScam", an AI scam-protection app for Android, is listed on Product Hunt |
| 5 | StopCall | "Stop the call" | "xtóp-côn", easy | None exact | `.app` and `.vn` have no DNS; `.com` taken | Descriptive, so weak to protect. Nearby: "StopScam Call & Spam Blocker". Can be read as "stops all calls" |
| 6 | ByeSpam | "Goodbye, spam" | Easy; "spam" is the best-known word | **Taken:** "ByeSpam - Spam SMS Filtrele" | `.com` and `.app` taken | Rejected |
| 7 | CallShield | "Shield for calls" | Hard: "sh" and the "-ld" ending | **Taken:** four apps named Call Shield / CallShield | `.com` and `.app` taken | Rejected |
| 8 | Nope | "No" | "nốp", easy | Crowded: five or more unrelated "Nope" apps | Not checked | Rejected; says nothing about calls |

App Store length: the name limit is 30 characters, and the home-screen label truncates at roughly 12. All top three fit both.

| Name | Home-screen label | Full App Store name (characters) |
|---|---|---|
| ByeScam | ByeScam (7) | "ByeScam - Chặn số lừa đảo" (25) or "ByeScam: Chặn cuộc gọi lừa đảo" (30, at the limit) |
| AloStop | AloStop (7) | "AloStop: Chặn cuộc gọi lừa đảo" (30, at the limit) |
| ScamOff | ScamOff (7) | "ScamOff: Chặn cuộc gọi lừa đảo" (30, at the limit) |

Suggested subtitle for any of them: "Chặn đầu số rác & lừa đảo" (25 characters).

### Top 3

1. **ByeScam.** English, conversational, and it finishes a sentence people already say ("bye!"). It is the cleanest on availability among English names. It depends most on the audience knowing the word "scam"; it fails first with older users, which the Vietnamese keyword tail in the App Store name partly covers.
2. **AloStop.** The easiest to understand and say for any Vietnamese speaker, and every domain looks free. It is half Vietnamese, so it fails first if the owner wants a strictly English brand or plans to launch outside Vietnam.
3. **ScamOff.** Short and reads like a switch, which matches the app's on/off shield. It is less warm than ByeScam and has the same dependence on "scam".

Limits of the checks: no trademark registry (Vietnam NOIP, WIPO, USPTO) was searched, "no DNS" means a domain is probably unregistered but a registrar must confirm it, and only App Store Connect can confirm that a name is free to reserve.

## 3. Icon concepts

Every concept uses the in-app shield shape and the approved colours. Each has three 1024×1024 PNGs in `icons/`: `dark` (the brand version), `light`, and `tinted` (simulated with a blue tint to prove it reads without green or red).

| | Concept | File prefix | What it says | Weakness |
|---|---|---|---|---|
| A | Shield + handset | `icon-a-shield-call` | "Call protection." Cleanest, holds down to 20pt | Same idea as Call Control and Số Lạ; only the colour is ours. Does not say "blocked" |
| B | Shield + handset + red ✕ badge | `icon-b-shield-blocked` | "Calls get blocked." Uses both approved colours | The badge turns into a dot at 20pt (notification size) |
| C | Outlined shield, handset struck through | `icon-c-shield-slash` | "No calls get past." One colour, so it tints well | The slash cuts the handset in two; hardest to read below 40pt |
| D | Shield + handset with pulse rings | `icon-d-shield-pulse` | Freezes the in-app shield animation | Rings fade out below 40pt and the shield is the smallest of the four |

Previews, in `previews/`:

- `home-screen-dark.png`, `home-screen-light.png`, `home-screen-tinted.png`: the four concepts on a home screen under the candidate names, next to eight real competitors and the current icon.
- `small-sizes.png`: each concept at 120, 60, 40, 29 and 20pt, plus light and tinted.

Two things the previews showed:

- The badge in B was first placed top-right, where the iOS notification badge would cover it, so it now sits bottom-right.
- On a dark wallpaper the near-black background makes the icon's edge disappear. The shield still carries the icon, but this is worth judging on a real phone.

`src/build-icons.py` regenerates everything (`python3 src/build-icons.py`, needs `rsvg-convert`).

## 4. Recommended next step

After the owner picks, implementation is: the AppIcon asset set with dark and tinted variants, `CFBundleDisplayName`, and the App Store name and subtitle in Vietnamese and English. The handset in the mockups is the Material Design "call" glyph (Apache 2.0), which can ship as is or be redrawn.

## Unresolved questions

1. Which name: ByeScam, AloStop or ScamOff?
2. Which icon: A, B, C or D?
3. Should the default icon (the one the App Store listing shows) be the dark neon version, with the light version used only in light appearance, or the other way round?
4. Should the Xcode target and bundle ID keep `ChanCuocGoi`, changing only the display name?

## Sources

- App Store Search API, Vietnam and US storefronts (`itunes.apple.com/search`)
- [Bye Bye, Con Artist on the App Store](https://apps.apple.com/lu/app/id6787752706)
- [SpamBye: Spam SMS Blocker](https://apps.apple.com/app/id6760017925)
- [NoScam on Product Hunt](https://www.producthunt.com/products/noscam)
- [Allostop Africa](https://appgoblin.info/apps/com.allostop_africa.app)
- [Alostopup](https://apps.apple.com/lb/app/alostopup/id6590626146)
- [StopScam Call & Spam Blocker](https://apps.apple.com/app/id6741771102)
