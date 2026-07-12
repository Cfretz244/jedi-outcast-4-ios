# OpenJO Notes

Running log of workarounds, patch rationales, and asset checksums.
Every OpenJK source change gets a one-line rationale here (see patch discipline in the project brief).

## Repo layout

- Superproject: this repo. Submodule `vendor/openjk` → `git@github.com:Cfretz244/OpenJK.git`, branch `openjo-macos`.
- `openjo-macos` branched from `upstream/master` at `1a6a6434` ("[JO] Fix spawn item error va eval (#1343)").
- Fork's `master` left untouched as a clean mirror of upstream.
- Remote `upstream` → `https://github.com/JACoders/OpenJK.git` (configured locally in the submodule; not recorded in git config files, so re-add after a fresh `git submodule update --init`).

## Environment (Phase 0 snapshot, 2026-07-12)

- Apple Silicon (arm64), macOS 26.5, Xcode at `/Applications/Xcode.app`
- Apple clang 17.0.0 (clang-1700.6.4.2)
- CMake 4.3.1, Ninja 1.13.2 (Homebrew, prefix `/opt/homebrew`)
- SDL2: **not yet installed** — needed in Phase 1 (`brew install sdl2`)

## Phase 1 — macOS build (2026-07-12)

- Built via `build-openjo-macos.sh` (configure/build/install/codesign/verify, out-of-tree in `build-macos/`, installs to `install-macos/JediOutcast/`). Zero OpenJK source changes needed.
- CMake 4.3.1 accepted the tree's `cmake_minimum_required(VERSION 3.1...3.31)` range with no policy override — the brief's claim verified.
- **Homebrew's `sdl2` formula now installs sdl2-compat 2.32.70** (SDL2 API reimplemented on SDL3; real SDL2 is EOL upstream). Builds and links as a drop-in; bundle carries `libSDL2-2.0.0.dylib` (Mach-O current version 3201.70.0). If runtime misbehaves in Phase 2, suspect sdl2-compat before the engine.
- `cmake --install` prints an `install_name_tool -delete_rpath /opt/homebrew/lib` **error — harmless**: the installed binary already has zero LC_RPATHs and SDL2 resolves to `@executable_path/../Frameworks/libSDL2-2.0.0.dylib`. The delete step's goal is already satisfied.
- Ad-hoc re-sign after install is required (fixup_bundle invalidates the linker signature): sign nested dylibs first, then the bundle. `codesign -vvv --deep --strict` passes; binary is arm64-only.
- Compile warnings only (7): savegame-related `trajectory_t` typedef-linkage warnings in `codeJK2/game` save/write templates, plus an unused variable in `icarus/TaskManager.cpp`. Consistent with the known 64-bit savegame weak spot — watch this area if saves misbehave.
- `compile_commands.json` copied into the submodule source dir by OpenJK's `copy-compile-commands` target is excluded via the submodule's local `info/exclude` (i.e. `.git/modules/vendor/openjk/info/exclude` in the superproject — re-add after a fresh submodule init, like the `upstream` remote).

## Phase 2 — game assets + first run (2026-07-12)

- Assets pulled from the user's own Steam account (appid 6030) via SteamCMD (Homebrew cask; payload from Valve's CDN, runs under Rosetta 2), forcing the Windows depot: the macOS depot is a dead 32-bit build. User authenticated interactively; download landed in `~/jk2-steam/GameData/base/`.
- Four pk3s copied to fs_homepath: `~/Library/Application Support/OpenJO/base/`. All zip-valid. `verify-assets.sh` re-checks presence/integrity/sha256.
- **sdl2-compat runtime failure, fixed**: the app aborted pre-`main()` (SIGABRT in `dllinit` under dyld) with a "failed to load library" dialog. Cause: Homebrew's sdl2-compat locates libSDL3 via its keg rpath (`@loader_path/../../../../opt/sdl3/lib`); the copy `fixup_bundle` placed in `Contents/Frameworks/` has no rpaths, and SDL3 is a `dlopen`, not a load command, so fixup never copies it. Fix: vendor `libSDL3.0.dylib` into `Contents/Frameworks/libSDL3.dylib` (matches sdl2-compat's `@loader_path/libSDL3.dylib` candidate) and re-sign — now part of `build-openjo-macos.sh`. Lesson for Phase 3: sdl2-compat's SDL3 dependency is invisible to bundle tooling.
- Verified startup log (`logfile 2`): FS_Startup lists all four pk3s (14978 files), "Running Jedi Outcast Mode", rd-vanilla loads, GL 2.1 Metal-backed (Apple M1 Max), SDL cocoa video + coreaudio audio, UI menus load, clean shutdown. SDL compiled/linked 2.32.70.

### Asset checksums (sha256, Steam 1.04 depot)

| file | sha256 |
|------|--------|
| assets0.pk3 | e8e466f219bb2faed536021bb0d10aa6b7f5cd687302aa43080da2debdae307c |
| assets1.pk3 | c3a9aeaf09c93e57847290e7e5cd6c1a071a560045fa8c5e8c6df3688df841c1 |
| assets2.pk3 | aa5bf361f7623f0210473021d73fa1e6c6997f7a5cceb6af19fce951edd43368 |
| assets5.pk3 | 7dc6bc7e599a32cc882fb2a9b741065f792ef39a129302fbd04d72ef77ee7a07 |

## OpenJK patches (fork branch `openjo-macos`)

_None yet._

## Asset checksums

_Pending Phase 2._
