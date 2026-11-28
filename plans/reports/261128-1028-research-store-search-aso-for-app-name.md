# Store search (ASO) research for the app name

Researched 2026-11-28, Vietnamese App Store and Google Play (vi-VN). Data and scripts are in `plans/reports/261128-1028-aso/`.

## Answer

**Use a brand plus Vietnamese keywords in the name field: "CallBye: Chặn cuộc gọi rác".** A brand alone will not be found, and the brand itself hardly matters for search as long as it is short.

- The name under the icon stays **CallBye**. The 30-character store name is a separate field, and both stores let it differ per language.
- No iOS/Android split name is needed. The same brand works on both stores with the same "Brand: keywords" pattern.
- The owner's example does not show English names ranking for a Vietnamese query. Truecaller and CleanCall both have Vietnamese listings; the owner's phone is set to English, so the store displays their English text.

What cannot be measured from outside: the exact position a new app will get, how many people type each query, and how fast ratings will move it. Those need a live listing and App Store Connect or Search Ads data.

## Contents

1. Queries people type
2. What ranks today
3. The owner's example: why English-looking apps rank
4. How a new app would surface
5. Proposed metadata
6. Name candidates compared
7. Is CallBye too close to CleanCall?
8. Limits, next steps, open questions

## 1. Queries people type

The App Store autocomplete for the Vietnamese storefront is the only direct evidence of real queries. Typing "chặn" suggests, in this order:

> chặn cuộc gọi rác, chặn quảng cáo, chặn cuộc gọi lạ, chặn cuộc gọi ngoài danh bạ, chặn cuộc gọi lừa đảo, chặn cuộc gọi, chặn quảng cáo youtube, chặn quảng cáo safari, chặn số rác, chặn tin nhắn rác

Other suggestions that matter:

- **With "app" or "ứng dụng" in front:** "app chặn cuộc gọi rác", "ứng dụng chặn cuộc gọi rác", "app chặn số lạ", "app chặn số lừa đảo", and the misspelling "ap chặn cuộc gọi". The owner's example query is one of these.
- **"Số" family:** chặn số rác, chặn số lạ, chặn số điện thoại lạ, chặn số lừa đảo.
- **Typing without diacritics** ("chan cuoc") suggests the accented phrases, and "chan cuoc goi" returns almost the same top 10 as "chặn cuộc gọi". Unaccented spellings do not need their own keywords.
- **English:** "call b" suggests call blocker, call blacklist, smart call blocker. "spam" suggests spam call. "block" suggests only games.

I searched 22 queries on both stores: 18 Vietnamese and 4 English. The full top-10 tables, with ratings, are in `261128-1028-aso/data/top10-per-query.md`.

Autocomplete shows that a query exists, not how often it is typed. Its order is the best available proxy for popularity.

## 2. What ranks today

### App Store (Vietnam)

Top three for the main queries, with rating counts:

| Query | 1 | 2 | 3 |
|---|---|---|---|
| chặn cuộc gọi | Chống làm phiền (310) | Chặn Đầu Số - Cuộc Gọi Rác (8) | Truecaller (9K) |
| chặn cuộc gọi rác | Truecaller (9K) | CleanCall (5.9K) | Chặn Đầu Số - Cuộc Gọi Rác (8) |
| chặn số rác | Truecaller (9K) | Chặn Đầu Số - Cuộc Gọi Rác (8) | CleanCall (5.9K) |
| chặn số lạ | Truecaller (9K) | Chống làm phiền (310) | CleanCall (5.9K) |
| chặn cuộc gọi lừa đảo | iCallme-Nhận diện gọi lừa đảo (3K) | Truecaller (9K) | Chặn & Tra Cứu Số Điện Thoại (1.6K) |
| chặn đầu số | Chặn Đầu Số - Cuộc Gọi Rác (8) | Chanso – Chặn số làm phiền (5) | Số Lạ (962) |
| chặn spam | True CallerID: Chặn spam cuộc (14) | Chặn & Tra Cứu Số Điện Thoại (1.6K) | CleanCall (5.9K) |

Across the 18 Vietnamese queries (180 top-10 slots):

- **Keywords in the visible text decide who shows up.** 80 slots have "chặn" in the title and another 63 have it in the subtitle. Only 37 have it in neither.
- **A new app can rank.** 87 of the 180 slots belong to apps with fewer than 50 ratings.
- **The clearest case is our direct competitor.** "Chặn Đầu Số - Cuộc Gọi Rác" (PrefixBlock in English, 8 ratings) is in the top 10 for 14 of 18 queries and in the top 3 for 8. Its Vietnamese name is nothing but keywords.
- **Ratings decide the very top.** Truecaller (9K ratings) is in the top 3 for 15 of 18 queries.
- **Brand-only names rank only with a large rating count.** "vCaller" (733) appears in 11 top-10s and never in a top 3. "Số Lạ" (962) does better, but its brand is itself a search term.
- **Most apps write a separate Vietnamese name.** Of 39 different apps in these results, 23 have a Vietnamese title that differs from their English one.

### Google Play (vi-VN)

- **An exact title match wins even without ratings.** "Chặn cuộc gọi rác & lừa đảo" (`vn.chanprefix.blocker`, a prefix blocker with 500+ installs and 6 ratings) is first for "chặn cuộc gọi rác" and "chặn cuộc gọi lừa đảo", second for "chặn số rác" and "chặn đầu số", above or next to Truecaller.
- **The same holds for the other leaders.** "Chặn số gọi không xác định" is in the top 3 for 16 of 18 Vietnamese queries, and "Chặn cuộc gọi - Điện thoại" for 10.
- **The short description counts.** For "chặn cuộc gọi", all ten results have the three words in the title or short description; five have them in the title.
- Play shows install and rating counts for only a few of these apps on the web, so popularity is less visible here than on the App Store.

## 3. The owner's example: why English-looking apps rank

I reproduced the search "app chặn cuộc gọi rác" on the Vietnamese App Store. The top two are the same as in the owner's screenshot: Truecaller, then CleanCall. Third is "Chặn Đầu Số - Cuộc Gọi Rác" with 8 ratings.

The same two apps, seen with the store set to Vietnamese and to English:

| App | Shown in English (owner's phone) | Shown in Vietnamese |
|---|---|---|
| Truecaller | "Truecaller: Premium Caller ID" / "Scam shield: Block spam calls" | "Truecaller:Xác định cuộc gọi" / "Gọi rác: nhận diện & chặn." |
| CleanCall | "CleanCall: Caller ID & Block" / "Identify & block spam calls" | "CleanCall: Cảnh báo cuộc gọi" / "Nhận diện & chặn cuộc gọi rác" |

What is evidence and what is a guess:

| Explanation | Status |
|---|---|
| Both apps have a Vietnamese listing whose title and subtitle contain the query words. CleanCall's subtitle contains "chặn cuộc gọi rác" word for word. | **Evidence.** Read from the store pages. |
| The store searches the Vietnamese listing even when the phone displays English. | **Evidence, indirect.** The English text has no Vietnamese words, yet the apps rank for a Vietnamese query. |
| High rating counts (9K and 5.9K) put these two above the 8-rating app with a better keyword match. | **Strong inference.** Consistent across all 18 queries, but Apple does not publish weights. |
| Their hidden 100-character keyword fields contain Vietnamese terms. | **Guess.** The field is not visible to anyone outside. |
| Text inside screenshots is indexed (CleanCall's say "Ứng dụng chặn cuộc gọi & tin nhắn rác"). | **Guess.** ASO blogs have reported this since 2025; I did not verify it, and the ranking is fully explained without it. |

Whether the word "app" in the query is matched or ignored is unknown. The results for "app chặn cuộc gọi rác" and "chặn cuộc gọi rác" have the same top three.

## 4. How a new app would surface

| Path | What to expect | Confidence |
|---|---|---|
| Searching the brand "CallBye" | First result. No other app has this name on either store. | High |
| Vietnamese queries whose words are all in our title and subtitle (chặn cuộc gọi rác, chặn đầu số, chặn cuộc gọi lừa đảo) | In the results within days of release. Top 10 is realistic: apps with 8 and 5 ratings hold top-3 places for "chặn đầu số" today. | Medium |
| Head terms (chặn cuộc gọi, chặn số lạ) | In the results, below Truecaller, CleanCall and Viettel until ratings build up. | Medium |
| Words only in the 100-character keyword field | Matched, but weaker than title and subtitle according to ASO practice. | Low; cannot be observed |
| Google Play | Title first, then short description, then the long description, where the main phrases should each appear a few times in natural sentences. Play has no hidden keyword field. | Medium |

The name "CallBye" by itself contributes one searchable word, "call", which matters only for English queries. Any of the candidate brands behaves the same way. The Vietnamese words after the colon do the work.

## 5. Proposed metadata

Character counts are verified. Limits: App Store name 30, subtitle 30, keywords 100; Google Play title 30, short description 80.

### App Store

| Field | Vietnamese listing | English listing |
|---|---|---|
| Name | CallBye: Chặn cuộc gọi rác (26) | CallBye: Spam Call Blocker (26) |
| Subtitle | Đầu số spam, telesale, lừa đảo (30) | Block scam calls by prefix (26) |
| Keywords | `số,lạ,quảng,cáo,làm,phiền,điện,thoại,đòi,nợ,lọc,quấy,rối,ứng,dụng,app,tiếp,thị,cảnh,báo,bảo,vệ` (94) | `unknown,caller,number,robocall,telemarketer,filter,blacklist,phone,junk,stop,nuisance,fraud,range` (97) |

- **No word is repeated across name, subtitle and keywords.** Apple combines words from all three, so a repeat wastes space. Title plus subtitle already cover "chặn cuộc gọi rác", "chặn đầu số", "chặn cuộc gọi lừa đảo", "chặn spam" and "chặn số rác".
- **The keyword field uses single words, not phrases,** for the same reason: "số" and "lạ" combine with "chặn" from the name to match "chặn số lạ".
- **Fill both English listings (US and UK) with the English column.** I could not confirm which English variant the Vietnamese storefront indexes, and filling both costs nothing.
- **Left out on purpose:** "tin nhắn" (the app does not filter SMS) and "ngoài danh bạ" (the app cannot block everyone outside contacts), although both are popular suggestions.

### Google Play (for the Android version)

| Field | Vietnamese | English |
|---|---|---|
| Title | CallBye: Chặn cuộc gọi rác (26) | CallBye: Spam Call Blocker (26) |
| Short description | Chặn cuộc gọi rác, lừa đảo, telesale theo đầu số. Không cần tài khoản. (70) | Block spam and scam calls by number prefix. No account needed. (62) |
| Long description | Use these phrases in natural sentences, each two to four times: chặn cuộc gọi rác, chặn số rác, chặn đầu số, chặn cuộc gọi lừa đảo, chặn số lạ, cuộc gọi quảng cáo | spam call blocker, block scam calls, block number prefix |

Do not title the Play listing "Chặn cuộc gọi rác & lừa đảo": that is the exact title of the existing Android prefix blocker `vn.chanprefix.blocker`. It is also the subtitle I suggested in the round-2 name report, so that suggestion is withdrawn.

## 6. Name candidates compared

| Name field | Length | Search effect |
|---|---|---|
| CallBye: Chặn cuộc gọi rác | 26 | Recommended. Unique brand, full main phrase |
| StopCall: Chặn cuộc gọi rác | 27 | Same search effect. Brand mirrors CallStop on Google Play (see round-2 report) |
| CallKick: Chặn cuộc gọi rác | 27 | Same search effect |
| ScamCallStop: Chặn cuộc gọi rác | 31 | **Does not fit.** The longest version that fits is "ScamCallStop: Chặn số rác" (25), which loses "cuộc gọi" |
| Chặn cuộc gọi rác (no brand) | 17 | Ranks, but six apps already carry near-identical names ("Chặn Cuộc Gọi", "Chặn Cuộc Gọi Rác", "Chặn cuộc gọi rác, số lạ"). Nobody can ask for it by name |
| CallBye (brand only) | 7 | Found only by people who already know the name |

A long English brand such as ScamCallStop spends 12 of 30 characters on words Vietnamese users do not type. A brand of eight characters or fewer leaves room for the whole phrase "Chặn cuộc gọi rác".

## 7. Is CallBye too close to CleanCall?

No. They share only the word "call", which is also in TrustCall, AiCall, iCallme, vCaller and Callapp in the same results.

- They do not sound alike: "clin-côn" against "côn-bai". The word order is reversed and the first syllables differ.
- CleanCall's icon is a white shield mark on red; ours is green on near-black.
- The pattern "Brand: keywords" is the category norm, not CleanCall's property. Truecaller, CaptureShield and True CallerID use it too.

The cost is the opposite of confusion: "call" brands are common here, so the name will not stand out by itself. I did not search a trademark registry.

## 8. Limits, next steps, open questions

### Limits

- Results come from the stores' public web pages, without an account. Rankings in the phone apps can differ slightly and change daily. This is one snapshot.
- No search-volume numbers. Apple Search Ads shows a popularity score per keyword once there is an account.
- Play ratings and installs were readable for only some apps.
- The claim that Apple indexes screenshot text comes from ASO blogs and was not tested.

### Next steps

1. Confirm the name field "CallBye: Chặn cuộc gọi rác" and the Vietnamese subtitle.
2. After release, record the app's position for the 18 Vietnamese queries weekly; `src/collect-store-search.py` can be rerun as is.
3. Change one field at a time (subtitle first) so the effect is readable.
4. Put Vietnamese text in the first screenshot ("Chặn cuộc gọi rác theo đầu số"). It helps people decide to install whether or not the store indexes it.

### Open questions

1. Is "số lạ" acceptable in the keyword field? The app blocks by prefix, not every unknown number. It is one of the most suggested terms, and stores require keywords to describe what the app does.
2. Will the Android version also work without an account? The proposed Play short description says so.
3. Does the owner accept that the name field differs by language (Vietnamese keywords in Vietnam, English keywords elsewhere) while the icon label is always "CallBye"?

## Sources

- App Store search pages and autocomplete, Vietnamese storefront, read 2026-11-28 (`apps.apple.com/vn/iphone/search`)
- Google Play search and listing pages, `hl=vi&gl=VN`, read 2026-11-28
- [Google Play: best practice for your store listing](https://support.google.com/googleplay/android-developer/answer/13393723?hl=en)
- [Android Developers Blog: updated guidance to improve your app quality and discovery](https://android-developers.googleblog.com/2021/04/updated-guidance-to-improve-your-app.html?m=0)
- [AppTweak: App Store localization, primary and secondary languages](https://www.apptweak.com/en/aso-blog/how-to-benefit-from-cross-localization-on-the-app-store)
- [Sensor Tower: iOS keyword localization guide](https://sensortower.com/blog/ios-keyword-localization-guide)
- [AppTweak: Google Play ASO checklist](https://www.apptweak.com/en/aso-resources/google-play-store-aso-checklist)
