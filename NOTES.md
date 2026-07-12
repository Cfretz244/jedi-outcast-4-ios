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

## OpenJK patches (fork branch `openjo-macos`)

_None yet._

## Asset checksums

_Pending Phase 2._
