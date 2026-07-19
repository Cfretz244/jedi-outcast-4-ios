# OpenJO Roadmap

Jedi Knight II: Jedi Outcast single-player — macOS reference build, then iOS port.
Engine: [OpenJK](https://github.com/JACoders/OpenJK) (fork: [Cfretz244/OpenJK](https://github.com/Cfretz244/OpenJK), submodule at `vendor/openjk`).

Phases are gated: each ends in a hard stop for review before the next begins.

## Current state (2026-07-18)

**The iOS port largely works.** JK2 SP boots fullscreen on device (iPhone Air), renders
widescreen-correct, takes controller input, and is playable through the campaign — including the
chapter 3→4 transition that broke twice. It's the first-ever JK2 on iOS.

What we keep hitting is one recurring failure mode, not a scattering of unrelated bugs: **the
static-link refactor changed the lifetime of the game/renderer modules, and a class of file-scope
global objects that used to be reset by `dlclose`/`dlopen` now survive across level transitions and
save-loads.** Each new area of the game we reach tends to trip one more of these — see the
[Static-link stale-globals hazard](#static-link-stale-globals-hazard-the-dominant-recurring-issue)
section below, which is now the primary thing to reach for when a level misbehaves impossibly.

## Phase status

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Repo, fork, submodule setup | ✅ Complete — signed off |
| 1 | macOS build (JK2 SP engine + game + renderer) | ✅ Complete — signed off |
| 2 | Game assets (Steam, appid 6030 via SteamCMD) | ✅ Complete — campaign playable, Gate 2 passed |
| 3 | iOS port | 🟢 Largely working — playable on device; hardening ongoing (see hazard section) |

## Phase 3 sub-stages

| Stage | Description | Status |
|-------|-------------|--------|
| 3.0 | Study the Beloko Games (emileb) Android port; write up findings | ✅ Complete — see docs/research/ |
| 3.1 | Static-link refactor (kill runtime dlopen), verified on macOS | ✅ Complete — `openjo-static` branch. **Source of the recurring stale-globals hazard** (see below) |
| 3.2 | Renderer strategy comparison — user decided: GLES1 patch, native ES 1.1 first, ANGLE later | ✅ Decided |
| 3.3 | Implement chosen renderer path (cherry-pick emileb USE_GLES1) | ✅ Complete — `openjo-ios` branch |
| 3.4 | iOS CMake target, SDL2 iOS backend, sandbox paths | ✅ Complete — boots on iOS Simulator (first-ever JK2 on iOS) |
| 3.5 | Boot to menu on device | ✅ Complete — runs fullscreen on iPhone Air via Xcode deploy (2026-07-12) |
| 3.6 | Touch + controller input | Controller ✅ (SDL_GameController, tuned on device); touch overlay not started (controller is sufficient) |
| 3.7 | Polish: widescreen, save/load, dev console, background resume | Mostly done — aspect-corrected 2D/FOV/HUD corners/prongs; dev console + cheats on device (L3+R3 chord + on-screen keyboard, `27665ce1`). Remaining: background/resume, prong snap jank, AltStore packaging |

## Static-link stale-globals hazard (the dominant recurring issue)

This is where nearly all the sporadic breakage comes from, so it gets its own section.

**Root cause.** In the dynamic build, the game and renderer are dylibs loaded with `dlopen` and torn
down with `dlclose` on every level change / `vid_restart`. A lot of JK2 module code silently relies
on that: file-scope globals, static class members, and cached containers were written assuming the
whole module gets wiped and reconstructed between levels. The static-link refactor (Phase 3.1,
needed because iOS can't `dlopen` arbitrary code) folds those modules into the main executable, so
those globals now **persist for the life of the process**. Anything that was implicitly reset by
`dlclose` is now a stale-state bug waiting for the right level to expose it.

**Symptom signature.** A level behaves *impossibly* — player can look but not move even with noclip;
a cinematic wedges; a crash (`EXC_BAD_ACCESS`) deep in a subsystem after a save-load or level
transition; an error that only fires on the 2nd/3rd load. First-play-of-a-fresh-boot usually works;
the bug needs a prior teardown to have left dirt behind.

**Fixed so far** (all reset in the module's teardown path — `NAV_Shutdown` / `ShutdownGame`; each is
a no-op for dynamic builds):

| Commit | Stale global | Broke |
|--------|--------------|-------|
| `de048a2a` | `CNavigator::m_nodes` / `m_edgeLookupMap` (nav) | Double save-load → crash in `CheckBlockedEdges` |
| `de048a2a` | `numStoredWaypoints` / `tempWaypointList` (nav) | `Too many waypoints!` ERR_DROP on ~3rd load |
| `51b9b1bf` | ROFF cache (`g_roff.cpp`) — filenames/data on freed level hunk | Chapter-4 intro cinematic wedged / `G_Roff` crash |
| `877c25fa` | `player_locked` + `cinematicSkipScript` (ICARUS) | Arrive in chapter 4 unable to move (noclip can't help — usercmd is zeroed) |

**Diagnosis playbook** when a level misbehaves impossibly:

1. Suspect a stale global *first*, before renderer/asset theories.
2. `grep` for file-scope / `static` state in the involved subsystem; check whether teardown resets it.
3. Reproduce headless-ish on the macOS static build with a scripted cfg (`maptransition`, `wait`,
   `viewpos`/movement probe, `runscript`) — see NOTES.md "Headless-ish scripted repro".
4. Fix = reset the global in the module teardown path, guarded so dynamic builds are unaffected.

**Known caveats.**
- **`vid_restart` (renderer statics) is still untested** — the renderer went static too, and its
  file-scope state has not been audited for the same hazard.
- **Saves written by a broken build can be permanently poisoned** — e.g. `G_SaveCachedRoffs`
  serialized dangling ROFF filenames, so a bad chapter-4 auto-save hangs even on fixed builds; only a
  fresh transition writes a clean one.
- **Cheats reset on level transition** (`helpusobi 1` must be re-entered) — an on-device "noclip
  didn't work" report can mean noclip silently never engaged, not that movement is truly blocked.

## Key decisions

- **2026-07-12** — Superproject is this repo (`~/git/jedi-outcast-4-ios`), not `~/src/openjo` as originally drafted.
- **2026-07-12** — Asset source: Steam (SteamCMD, forced Windows platform).
- **2026-07-12** — Submodule uses ssh URL (`git@github.com:Cfretz244/OpenJK.git`) per user preference.
- Distribution: sideload only (AltStore/SideStore, personal cert). App Store is out — settled, do not relitigate.
- **2026-07-12** — Renderer path: cherry-pick emileb's `USE_GLES1` rd-vanilla patch; boot natively on OpenGLES.framework ES 1.1 first, keep ANGLE-on-Metal as the later durability upgrade (same patch either way).
- **2026-07-12** — Module linking: static-link game + renderer into the engine (ld -r prelink + localize + direct GetGameAPI/GetRefAPI calls), built on macOS first; bundle-embedded signed dylibs kept as fallback.

## Outstanding work (as of 2026-07-18)

Ordered roughly by value.

1. **Static-link stale-globals hardening** — the recurring hazard, now written up in its own
   [section above](#static-link-stale-globals-hazard-the-dominant-recurring-issue). Four instances
   fixed (nav ×2, ROFF cache, `player_locked`); the campaign is playable through them. Still open:
   audit `vid_restart` / renderer statics, and keep expecting one more per newly-reached area of the
   game. Not "done" so much as an ongoing discipline — this item stays open for the life of the port.
   On-device: chapter 4 verified via `devmap artus_detention`; a full *played* chapter 3→4 transition
   on device not yet user-confirmed end-to-end.
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
