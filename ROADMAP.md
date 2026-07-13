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
| 3.1 | Static-link refactor (kill runtime dlopen), verified on macOS | ✅ Complete — `openjo-static` branch; known issue: double save-load crash (unclassified, deferred) |
| 3.2 | Renderer strategy comparison — user decided: GLES1 patch, native ES 1.1 first, ANGLE later | ✅ Decided |
| 3.3 | Implement chosen renderer path (cherry-pick emileb USE_GLES1) | ✅ Complete — `openjo-ios` branch |
| 3.4 | iOS CMake target, SDL2 iOS backend, sandbox paths | ✅ Complete — boots on iOS Simulator (first-ever JK2 on iOS) |
| 3.5 | Boot to menu on device | ✅ Complete — runs fullscreen on iPhone Air via Xcode deploy (2026-07-12) |
| 3.6 | Touch + controller input | Controller ✅ (SDL_GameController, tuned on device); touch overlay not started |
| 3.7 | Polish: virtual buttons, save/load, background resume | Not started |

## Key decisions

- **2026-07-12** — Superproject is this repo (`~/git/jedi-outcast-4-ios`), not `~/src/openjo` as originally drafted.
- **2026-07-12** — Asset source: Steam (SteamCMD, forced Windows platform).
- **2026-07-12** — Submodule uses ssh URL (`git@github.com:Cfretz244/OpenJK.git`) per user preference.
- Distribution: sideload only (AltStore/SideStore, personal cert). App Store is out — settled, do not relitigate.
- **2026-07-12** — Renderer path: cherry-pick emileb's `USE_GLES1` rd-vanilla patch; boot natively on OpenGLES.framework ES 1.1 first, keep ANGLE-on-Metal as the later durability upgrade (same patch either way).
- **2026-07-12** — Module linking: static-link game + renderer into the engine (ld -r prelink + localize + direct GetGameAPI/GetRefAPI calls), built on macOS first; bundle-embedded signed dylibs kept as fallback.
