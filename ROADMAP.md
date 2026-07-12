# OpenJO Roadmap

Jedi Knight II: Jedi Outcast single-player — macOS reference build, then iOS port.
Engine: [OpenJK](https://github.com/JACoders/OpenJK) (fork: [Cfretz244/OpenJK](https://github.com/Cfretz244/OpenJK), submodule at `vendor/openjk`).

Phases are gated: each ends in a hard stop for review before the next begins.

## Phase status

| Phase | Description | Status |
|-------|-------------|--------|
| 0 | Repo, fork, submodule setup | ✅ Complete — signed off |
| 1 | macOS build (JK2 SP engine + game + renderer) | ✅ Complete — awaiting gate sign-off |
| 2 | Game assets (Steam, appid 6030 via SteamCMD) | Not started |
| 3 | iOS port | Not started |

## Phase 3 sub-stages (planned)

| Stage | Description | Status |
|-------|-------------|--------|
| 3.0 | Study the Beloko Games (emileb) Android port; write up findings | Not started |
| 3.1 | Static-link refactor (kill runtime dlopen), verified on macOS | Not started |
| 3.2 | Renderer strategy comparison (GL4ES/ANGLE vs GLES port vs Metal) — user decides | Not started |
| 3.3 | Implement chosen renderer path | Not started |
| 3.4 | iOS CMake/Xcode target, SDL2 iOS backend, sandbox paths | Not started |
| 3.5 | Boot to menu on device | Not started |
| 3.6 | Touch + controller input | Not started |
| 3.7 | Polish: virtual buttons, save/load, background resume | Not started |

## Key decisions

- **2026-07-12** — Superproject is this repo (`~/git/jedi-outcast-4-ios`), not `~/src/openjo` as originally drafted.
- **2026-07-12** — Asset source: Steam (SteamCMD, forced Windows platform).
- **2026-07-12** — Submodule uses ssh URL (`git@github.com:Cfretz244/OpenJK.git`) per user preference.
- Distribution: sideload only (AltStore/SideStore, personal cert). App Store is out — settled, do not relitigate.
