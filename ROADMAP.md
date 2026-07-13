# OpenJO Roadmap

Jedi Knight II: Jedi Outcast single-player — macOS reference build, then iOS port.
Engine: [OpenJK](https://github.com/JACoders/OpenJK) (fork: [Cfretz244/OpenJK](https://github.com/Cfretz244/OpenJK), submodule at `vendor/openjk`).

Phases are gated: each ends in a hard stop for review before the next begins.

## Phase status

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Repo, fork, submodule setup | ✅ Complete — signed off |
| 1 | macOS build (JK2 SP engine + game + renderer) | ✅ Complete — signed off |
| 2 | Game assets (Steam, appid 6030 via SteamCMD) | ✅ Complete — campaign playable, Gate 2 passed |
| 3 | iOS port | Not started |

## Phase 3 sub-stages (planned)

| Stage | Description | Status |
|-------|-------------|--------|
| 3.0 | Study the Beloko Games (emileb) Android port; write up findings | ✅ Complete — see docs/research/ |
| 3.1 | Static-link refactor (kill runtime dlopen), verified on macOS | ✅ Complete — `openjo-static` branch; double save-load crash fixed (`de048a2a`, nav stale globals) |
| 3.2 | Renderer strategy comparison — user decided: GLES1 patch, native ES 1.1 first, ANGLE later | ✅ Decided |
| 3.3 | Implement chosen renderer path (cherry-pick emileb USE_GLES1) | ✅ Complete — `openjo-ios` branch |
| 3.4 | iOS CMake target, SDL2 iOS backend, sandbox paths | ✅ Complete — boots on iOS Simulator (first-ever JK2 on iOS) |
| 3.5 | Boot to menu on device | ✅ Complete — runs fullscreen on iPhone Air via Xcode deploy (2026-07-12) |
| 3.6 | Touch + controller input | Controller ✅ (SDL_GameController, tuned on device); touch overlay not started |
| 3.7 | Polish: virtual buttons, save/load, background resume | Partial — widescreen presentation done (aspect-corrected 2D, FOV, HUD corners, prongs) |

## Key decisions

- **2026-07-12** — Superproject is this repo (`~/git/jedi-outcast-4-ios`), not `~/src/openjo` as originally drafted.
- **2026-07-12** — Asset source: Steam (SteamCMD, forced Windows platform).
- **2026-07-12** — Submodule uses ssh URL (`git@github.com:Cfretz244/OpenJK.git`) per user preference.
- Distribution: sideload only (AltStore/SideStore, personal cert). App Store is out — settled, do not relitigate.
- **2026-07-12** — Renderer path: cherry-pick emileb's `USE_GLES1` rd-vanilla patch; boot natively on OpenGLES.framework ES 1.1 first, keep ANGLE-on-Metal as the later durability upgrade (same patch either way).
- **2026-07-12** — Module linking: static-link game + renderer into the engine (ld -r prelink + localize + direct GetGameAPI/GetRefAPI calls), built on macOS first; bundle-embedded signed dylibs kept as fallback.

## Outstanding work (as of 2026-07-12, end of first session)

Everything below is unstarted or unverified; ordered roughly by value.

1. ~~**Double save-load crash**~~ **Fixed** (`de048a2a`, 2026-07-12) — was (a): static-link stale
   globals in the JK2 nav system (dangling `CNavigator::m_nodes` + ever-growing
   `numStoredWaypoints`). Both reset on teardown now; 6 consecutive loads verified on macOS static.
   Still open from the same hazard class: `vid_restart` (renderer statics) untested, saves on iOS
   untested, and other game-module globals may assume dlclose resets them. Not yet deployed/verified
   on device.
2. **AltStore/SideStore packaging** — escape the 7-day Xcode signing window. Zip
   `build-ios-xcode/Release/openjo_sp.arm64.app` into `Payload/` → `.ipa`; AltStore re-signs.
   Verify app-data (pk3s) survives AltStore's install-over. Free-account 7-day refresh still applies.
3. **Controller loose ends** — user has not confirmed: X button (+use) works, Start/Select reach the
   game on the OhSnap MCON I (ESC/datapad access). Quicksave/quickload (F9/F12) unreachable from
   the pad — consider mapping stick-clicks or a chord. Look tuning final: speed 30, pitch 0.75x,
   squared curve ("feels good" per user).
4. **Background/resume behavior** — untested: iOS backgrounding (GL context loss, audio session
   interruption, phone call). Likely needs SDL event handling for `SDL_APP_WILLENTERBACKGROUND`.
5. **Touch overlay controls** (optional, controller works) — design blueprint is the Android port's
   `mobile/game_interface.cpp` + MobileTouchControls (see docs/research/3.0-android-port-study.md).
   Current touch = SDL mouse synthesis: drag-look works, tap fires immediately.
6. **Prong snap jank** (cosmetic, accepted) — idle weapon-select prongs teleport between the corner
   gauges and the 4:3 carousel ends on open/close; proper fix is animating between anchors.
7. **Slow opening cinematics on macOS** (parked) — RoQ playback slow on the macOS reference build;
   suspects: GL-on-Metal texture upload, sdl2-compat. Re-check someday; iOS unaffected reports so far.
8. **Upstreaming** — `BuildJK2SPStatic` and the aspect-correction work are written to be
   upstreamable to JACoders/OpenJK; consider PRs once stable. (GPL source publication is already
   satisfied: fork is public at Cfretz244/OpenJK.)
9. **Icon assets** — `ios-icon/` is git-ignored (derived from the game's box art); `icon-1024.png`
   is the master. If lost, regenerate: crop the box-art emblem square and resize to
   AppIcon60x60@2x/@3x (120/180px) + AppIcon76x76@2x (152px).
