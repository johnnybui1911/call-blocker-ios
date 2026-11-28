# Name round 3 (CallProtector, AntiCall, CallWall) and the bundle-id rename plan

Date: 2026-11-28. No code was changed. Raw check output is in `261128-1053-names/name-round3-checks.txt`.

## Answer

- **AntiCall: acceptable.** No app has this exact name on the App Store (VN, US) or in Google Play search (vi-VN, en-US).
- **CallProtector: acceptable but weak.** It is free as an exact name, but it is one syllable away from two established "Call Protect" apps, and it is too long for the name pattern.
- **CallWall: not acceptable.** It is taken on both stores by spam call blockers.
- **Correction to round 2: CallBye is taken on Google Play.** An Android app named "CallBye" exists in the same category. I missed it because round 2 checked Google Play only through web search. CallBye is still free on the iOS App Store.

**Recommendation:** if an Android version is planned, use **AntiCall**. If the app stays iOS-only, **CallBye** remains the friendlier name and is still usable. Ranking: AntiCall, CallBye, CallProtector, CallWall.

## 1. Checks

Run 2026-11-28: exact and spaced names on the App Store (VN and US), Google Play search (vi-VN and en-US, first eight results), DNS for `.com`/`.app`/`.vn`, and web search including Product Hunt. "No DNS" means probably unregistered; a registrar must confirm.

| | CallBye | AntiCall | CallProtector | CallWall |
|---|---|---|---|---|
| App Store, exact name | None | None | None | **Taken** |
| App Store, near names | None | "AntiSpam: Call Blocker" (two apps, 0 ratings in VN) | "Call Protect Spam Call Blocker" (1,598 VN ratings), "Call Protect: Robocall Blocker" (31.8K US ratings) | — |
| Google Play, exact name | **Taken** | None | None | **Taken** |
| Google Play, near names | — | None | "Call Protect", "Call Protection", "Call Guard: Call Blocker" | — |
| `.com` / `.app` / `.vn` | No DNS / no DNS / no DNS | Parked for sale / no DNS / no DNS | Parked for sale / taken / no DNS | No DNS / taken / no DNS |
| Web and Product Hunt | Nothing found | Nothing found | AT&T Call Protect (US carrier service) | App Store listing only |
| Length | 7 | 8 | 13 | 8 |

### What exactly conflicts

- **CallWall, App Store:** "CallWall: Spam Call Blocker" by Phillip David Conley (app id 6761127543), available in Vietnam, 11 ratings in the US. It is a community-powered spam call and text blocker.
- **CallWall, Google Play:** "CallWall" by Projy AI (`ai.projy.callwall`), 5K+ installs, updated October 2026: "Block spam calls and identify suspicious numbers".
- **CallBye, Google Play:** "CallBye" by Deponto Digital (`com.henrymob.callbye`), 100+ installs, updated 1 November 2026: "Control unknown calls and choose who can call you".
- **CallProtector, near names only:** the two "Call Protect" apps above are on the Vietnamese App Store today, and one has 1,598 Vietnamese ratings. A user told "CallProtector" will find them first.

## 2. Reading, saying and fitting

| | Vietnamese pronunciation | "Name: Chặn cuộc gọi rác" (limit 30) | Home-screen label |
|---|---|---|---|
| CallBye | "côn-bai", 2 syllables | 26, fits | Fits |
| AntiCall | "an-ti-côn", 3 syllables; "anti" is already used in Vietnamese ("anti-fan") | 27, fits | Fits |
| CallProtector | "côn-prô-téc-tơ", 4 syllables with "pr" and "ct" clusters; hardest to say and spell | **32, does not fit.** "CallProtector: Chặn số rác" (26) fits but drops "cuộc gọi" | Probably fits, see below |
| CallWall | "côn-uôn"; awkward, the two halves sound alike | 27, fits | Fits |

**Does CallProtector get cut off under the icon?** Probably not at default settings. Rendered in the system font it is 184 px wide at 3x, narrower than "Authenticator" (190 px), which iPhones show in full. I measured this on a Mac, not on a phone, so it is unverified with Bold Text or a larger text size, where it would become "CallProtect…".

The store-search research showed that the Vietnamese words after the colon do the ranking work. CallProtector is the only candidate that cannot carry the full phrase "Chặn cuộc gọi rác".

## 3. Head to head with CallBye

| Against CallBye | Wins on | Loses on |
|---|---|---|
| AntiCall | Free on Google Play; "anti" says "against calls" without needing the subtitle | Colder tone; reads as "against all calls"; descriptive, so harder to protect; `.com` is parked |
| CallProtector | Free on Google Play; "protector" matches the shield icon | Too long for the name field; hardest to pronounce; crowded by "Call Protect" apps with real rating counts |
| CallWall | Nothing | Taken on both stores |

## 4. Ranking

1. **AntiCall.** The only candidate with no same-name app on either store, short enough for the full keyword phrase, and it meets the owner's test of saying "blocks calls" in the name. It depends on users reading "anti" as "against junk calls"; the Vietnamese keywords next to it cover that.
2. **CallBye.** Friendlier and all three domains look free, but an Android app with the same name and purpose already exists. Fine if the product stays on iOS.
3. **CallProtector.** Usable only with a shorter keyword tail, and it will always sit beside the "Call Protect" apps.
4. **CallWall.** Taken.

Limits: no trademark registry was searched. Google Play was checked through its search page (first eight results per query), so a same-name app ranked lower could still exist.

## 5. What changes when the bundle id is renamed

The project derives all three identifiers from one setting, `BUNDLE_PREFIX` in `Config/Signing.xcconfig`. The repository default is `dev.changeme.chancuocgoi`; the owner's phone build uses `me.jblabs.chancuocgoi`.

### Identifiers

| Identifier | Now | After, with `BUNDLE_PREFIX = me.jblabs.<newname>` | Where it is set |
|---|---|---|---|
| App bundle id | `me.jblabs.chancuocgoi` | `me.jblabs.<newname>` | `Config/Signing.xcconfig` |
| Extension bundle id | `me.jblabs.chancuocgoi.CallDirectory` | `me.jblabs.<newname>.CallDirectory` | Derived |
| App Group | `group.me.jblabs.chancuocgoi` | `group.me.jblabs.<newname>` | Derived; used only when `ENABLE_APP_GROUPS = YES` |
| Display name | "Chặn cuộc gọi" | The chosen brand | `CFBundleDisplayName` in `ios/App/Info.plist` and `ios/Extension/Info.plist` |

The extension's display name is the label the user switches on under Settings > Phone > Call Blocking & Identification. The in-app guide tells users to find "Chặn cuộc gọi" there, so the guide text must change with it.

### Internal names (optional, no user effect)

- `project.yml`: project name, target name, `PRODUCT_NAME`, scheme; then regenerate `ChanCuocGoi.xcodeproj`.
- `ios/App/ChanCuocGoiApp.swift`: file and struct name.
- `ios/Shared/SharedConfig.swift`: the local folder name `ChanCuocGoi` inside Application Support. Leave this one alone; renaming it would hide existing local rules for no benefit.
- `README.md`, `plans/prd.md`, `plans/td.md`: examples and instructions.

### Consequences on the phone

- **iOS treats it as a different app.** The new build installs next to the old one with an empty sandbox. The blocked list does not carry over.
- **The list can be moved by hand.** The app already has "Xuất quy tắc" (export) and a JSON import, so the path is export from the old app, import into the new one.
- **Call blocking must be switched on again.** The new extension is a new entry in Settings, off by default. While both apps are installed, both entries appear.
- **A new App Group is a new shared container.** Nothing is read from the old group.

### Consequences of the free Apple ID

- **App ID quota.** Apple's membership page says a free account can hold 10 App IDs, each expiring after 7 days. The rename registers two new ones (app and extension). Each further change of `BUNDLE_PREFIX` uses two more, so a few experiments in one week can hit "App ID limit reached".
- **App IDs cannot be deleted on a free account.** The old pair keeps counting until it expires.
- **Seven-day profiles.** Unchanged by the rename: the app still needs a rebuild and reinstall every seven days.
- **App Groups.** Still normally refused for a Personal Team, as the README already explains. The rename does not change this, so real blocking still waits for the paid programme.
- **Moving to the paid team later forces a delete and reinstall anyway,** because iOS will not install over an app signed by a different team.

## 6. Safe rename plan (for later)

Do the rename once, at the same time as the move to the paid developer team. That turns two disruptive reinstalls into one and avoids spending the free account's App ID quota.

1. **Fix the name first.** A bundle id cannot be changed after the app record exists in App Store Connect. If the brand might still change, use a neutral id such as `me.jblabs.callblocker`.
2. **Export the list.** On the phone, open the current app and use "Xuất quy tắc"; save the JSON to Files.
3. **Change one line.** Set `BUNDLE_PREFIX` in `Config/Signing.xcconfig`; set `TEAM_ID` to the paid team and `ENABLE_APP_GROUPS = YES` in the same edit.
4. **Change the display name** in both `Info.plist` files, and the guide text that quotes it.
5. **Rename internal names** (`project.yml`, app struct, docs) in a separate commit, then run `xcodegen generate`. Keep the `ChanCuocGoi` data folder name.
6. **Build and install** the new app next to the old one. Import the JSON. Switch on the new entry in Settings > Phone > Call Blocking & Identification.
7. **Verify** that a number matching a blocked prefix is rejected, then delete the old app.
8. **Roll back** by restoring the old `BUNDLE_PREFIX` if step 6 fails; the old app and its data are untouched until step 7.

If the rename has to happen before the paid team is active, do steps 2 to 8 on the free account once, and do not change `BUNDLE_PREFIX` again that week.

## Unresolved questions

1. Is an Android version planned? It decides between AntiCall and CallBye.
2. Should the bundle id carry the brand (`me.jblabs.anticall`) or stay neutral (`me.jblabs.callblocker`)?
3. Should the rename wait for the paid developer team, as recommended?

## Sources

- App Store Search API, Vietnam and US storefronts; Google Play search and listing pages, read 2026-11-28
- [CallWall on the App Store](https://apps.apple.com/us/app/id6761127543)
- [Call Protect: Robocall Blocker](https://apps.apple.com/us/app/id1357820531)
- [Call Protect Spam Call Blocker](https://apps.apple.com/app/id1440014663)
- [AntiSpam: Call Blocker](https://apps.apple.com/us/app/antispam-call-blocker/id1593671742?uo=4)
- [AT&T Call Protect terms](https://www.att.com/legal/terms.callProtectEULA)
- [Apple: Choosing a Membership](https://developer.apple.com/support/compare-memberships)
- [Apple Developer Forums: App ID limit reached](https://developer.apple.com/forums/thread/795781)
- [Apple Developer Forums: Xcode app limit](https://developer.apple.com/forums/thread/745359)
- [mybyways: limitations on the free Apple developer account](https://mybyways.com/blog/new-limitations-imposed-on-free-apple-developer-account)
