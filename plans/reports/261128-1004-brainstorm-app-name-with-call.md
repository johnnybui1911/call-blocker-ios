# App name, round 2 — names containing "Call"

Date: 2026-11-28. This replaces the name section of `261128-0904-brainstorm-app-icon-and-name.md`. The icon concepts are unchanged.

## Recommendation

Name the app **CallBye**, with the subtitle **"Chặn cuộc gọi rác & lừa đảo"**.

CallBye is the only short "Call" name that came back clean on every check: no app of that name on the Vietnamese or US App Store, no DNS on `.com`, `.app` or `.vn`, and no brand found on the web.

One trade-off needs the owner's decision. **StopCall** says "blocks calls" more literally than CallBye, and it is free on the iOS App Store. However, an Android app called **CallStop** already does the same thing we do: it blocks spam calls by number range. If an Android version is planned, StopCall would sit next to its mirror image on Google Play.

## What the owner asked for

- The name must contain "Call" and make it obvious the app blocks calls.
- English, easy for Vietnamese speakers to read, say and remember, short enough to fit under the icon.

"Call" is safe for a Vietnamese audience: people already say "video call" and "call điện". It is pronounced "côn".

## Candidates

Checks run on 2026-11-28: exact-name search on the App Store (VN and US), DNS lookup for `.com`, `.app`, `.vn`, and a web search. "Free?" means no DNS record, which a registrar must still confirm. Raw output is in `261128-0904-icon-name/research/name-round2-appstore-search.txt` and `name-round2-domain-dns.txt`.

| # | Name | Reads as | Vietnamese pronunciation | App Store VN / US (exact name) | `.com` / `.app` / `.vn` | Conflicts found |
|---|---|---|---|---|---|---|
| 1 | **CallBye** | "Bye, calls" | "côn-bai"; both words known at any age | None / none | Free? / free? / free? | None |
| 2 | **StopCall** | "Stop the call" | "xtóp-côn"; very easy | None / none | Taken / free? / free? | Mirror of **CallStop** on Google Play (range-based spam call blocker). Nearby on iOS: "Stop Calling", "StopScam Call & Spam Blocker" |
| 3 | **CallKick** | "Kick the call out" | "côn-kích"; "kick" is familiar from games and group chats | None / none | Parked / free? / free? | None |
| 4 | ByeCall | "Bye, call" | "bai-côn"; easy | None / none | Taken / free? / free? | None. Same idea as CallBye with a worse `.com` |
| 5 | CallZero | "Zero calls" | "côn-zê-rô"; three syllables | None / none | Lookup timed out / free? / free? | None. Could be read as "no calls at all" |
| 6 | CallNope | "Call? Nope." | "côn-nốp"; "nope" is not widely known | None / none | Free? / free? / free? | None |
| 7 | CallMute | "Mute the call" | "côn-miu"; "mute" is less known | None / none | Free? / free? / free? | None. Muting is not blocking |
| 8 | CallOff | "Calls: off" | "côn-óp"; easy | None / none | Parked / free? / free? | Search for it returns Call of Duty. "Call off" also means "cancel" |
| 9 | CallStop | "Stop calls" | "côn-xtóp"; very easy | None / none | Parked / free? / free? | **Taken on Android:** "CallStop: Spam Call Blocker" (`com.callstop.app`, updated Oct 2026), also on Product Hunt. "Call Stopper" is on iOS |
| 10 | BlockCall | "Block the call" | "bờ-lóc-côn"; "block" is everyday slang | None / none | Parked / taken / free? | **Mirror of "Callblock"**, a call blocker already on the iOS App Store, and one letter from the generic "Call Blocker" |
| 11 | NoCall | "No calls" | "nô-côn"; very easy | **Taken:** "NoCall: Spam Call Blocker" and a second NoCall blocker | Parked / taken / free? | Rejected |
| 12 | CallWall | "A wall against calls" | "côn-uôn"; awkward | **Taken:** "CallWall: Spam Call Blocker" | Free? / taken / free? | Rejected |

Also checked and rejected:

- **CallGuard:** taken by "CallGuard – Spam Blocker", "Call Guard" and Xfinity Call Guard.
- **CallShield:** taken by four apps, as found in round 1.
- **CallSafe / SafeCall:** taken by "CallSafe Recorder", "Safe Call" and "SafeCall".
- **CallGate:** taken by "CallGate Lite".
- **CallBan:** free, but "ban" reads as "bạn" in Vietnamese, so it looks like "call a friend".
- **CallCut:** one letter from CapCut.
- **CallLock:** free, but suggests locking, not blocking.

## Top 3

1. **CallBye.** Friendly and easy to repeat ("bai bai"), and the only candidate with nothing in its way. It depends on the subtitle to say "block"; it fails first if the owner wants the name alone to say it.
2. **StopCall.** The most literal of the names still free on iOS, and "stop" is understood by everyone. It depends on staying iOS-only or accepting the CallStop neighbour on Android; it fails first at an Android launch or a trademark filing, because it is descriptive.
3. **CallKick.** Active and a little playful, with no conflicts found. "Kick" is clear to younger users but less so to older ones.

## App Store name and subtitle

All three names are 7–8 characters, so none truncates under the icon. The App Store name and subtitle limits are 30 characters each.

| Field | Vietnamese | English |
|---|---|---|
| Name | "CallBye: Chặn cuộc gọi rác" (26) | "CallBye: Spam Call Blocker" (26) |
| Subtitle | "Chặn cuộc gọi rác & lừa đảo" (27) | "Block spam & scam calls" (23) |
| Subtitle, alternative that names the prefix feature | "Chặn đầu số rác & lừa đảo" (25) | "Block spam calls by prefix" (26) |

The same patterns fit StopCall and CallKick (27 characters each for the Vietnamese name).

## Icon

No name here implies an icon change. Icon B (shield, handset, red "blocked" badge) still fits, and it supplies the "blocked" meaning that CallBye leaves to the subtitle.

The three home-screen previews in `261128-0904-icon-name/previews/` (`home-screen-dark.png`, `home-screen-light.png`, `home-screen-tinted.png`) now show CallBye, StopCall, CallKick and ByeCall under the four icon concepts. The round-1 names no longer appear in them.

## Limits of the checks

No trademark registry (Vietnam NOIP, WIPO, USPTO) was searched. Google Play was checked only through web search, not name by name. Only App Store Connect can confirm a name is free to reserve.

## Unresolved questions

1. Is an Android version planned? If so, StopCall is risky; if not, it is a real alternative to CallBye.
2. CallBye, StopCall or CallKick?
3. Should the subtitle mention the prefix feature ("Chặn đầu số rác & lừa đảo") or stay general ("Chặn cuộc gọi rác & lừa đảo")?

## Sources

- App Store Search API, Vietnam and US storefronts (`itunes.apple.com/search`)
- [CallStop: Spam Call Blocker on Google Play](https://play.google.com/store/apps/details?id=com.callstop.app)
- [CallStop on Product Hunt](https://www.producthunt.com/products/callstop-block-100-of-spam-calls)
- [Callblock on the App Store](https://apps.apple.com/us/app/id1148495423)
- [Call Stopper on the App Store](https://apps.apple.com/na/app/call-stopper/id1507622486)
- [StopScam Call & Spam Blocker](https://apps.apple.com/app/id6741771102)
- [Bye Bye Button](https://apps.apple.com/us/app/id6744056095)
