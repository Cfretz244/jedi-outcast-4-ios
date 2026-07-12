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

- **Gate 2 passed (2026-07-12)**: user confirmed a new game reaches player control; sound/video/input all fine. One observation: the **opening cinematics played surprisingly slowly** while in-game rendering was smooth. Not investigated (RoQ playback is CPU-decoded and uploads full-screen textures each frame — plausible suspects are the glDrawPixels/texture-upload path through Apple's GL-on-Metal, or sdl2-compat; could also be pre-existing OpenJK behavior). Known quirk to re-check when the renderer changes in Phase 3 — don't chase unless it worsens.

### Asset checksums (sha256, Steam 1.04 depot)

| file | sha256 |
|------|--------|
| assets0.pk3 | e8e466f219bb2faed536021bb0d10aa6b7f5cd687302aa43080da2debdae307c |
| assets1.pk3 | c3a9aeaf09c93e57847290e7e5cd6c1a071a560045fa8c5e8c6df3688df841c1 |
| assets2.pk3 | aa5bf361f7623f0210473021d73fa1e6c6997f7a5cceb6af19fce951edd43368 |
| assets5.pk3 | 7dc6bc7e599a32cc882fb2a9b741065f792ef39a129302fbd04d72ef77ee7a07 |

## Phase 3.0 — Android-port study (2026-07-12)

Full write-up: `docs/research/3.0-android-port-study.md`. Headlines:

- The live Android port is **`emileb/OpenJK` branch `master_mobile`** (engine of the Psi Touch app, pushed 2026-07-05), a fork of our exact upstream, merge-base 2 commits behind master. Total mobile delta: +4,283/−117 lines, cleanly ifdef'd.
- **Renderer**: in-tree **GLES 1.1** port of rd-vanilla behind `USE_GLES1` (~1,000 lines for SP). No translation layer. Keeps stencil shadows and cinematics; drops dynamic glow (default-off anyway) and hardware gamma (blend-pass emulation). GPLv2 — cherry-pickable into our fork with attribution.
- **Linking**: Android still dlopens everything from the APK lib dir — no one has solved iOS static linking; but module seams are 3 exported symbols + function tables, `-fvisibility=hidden` already on. iOS *does* allow dlopen of bundle-embedded, same-signed dylibs (fallback path).
- **iOS precedents**: OpenGLES.framework still functional through iOS 26 incl. ES 1.1 contexts via SDL2's iOS backend; ANGLE-on-Metal has a GLES1 frontend; gl4es→ANGLE→Metal shipped by PojavLauncher; PortMaster ships stock `openjo_sp` through gl4es on ARM handhelds. No JK2/JKA iOS port has ever existed.

## Phase 3.1 — static-link refactor (2026-07-12)

- Branch `openjo-static` (off `openjo-macos`), commit `20991733`: new `BuildJK2SPStatic` CMake option links game + renderer into the engine executable. Mechanism: modules built as static archives, each prelinked via `ld -r` into one relocatable object with all symbols except entry points (`GetGameAPI`/`dllEntry`/`cgame_vmMain`, `GetRefAPI`) made private extern — internal references bind at prelink, so the divergent per-module `q_shared` copies can't cross-contaminate. Engine calls entry points directly behind `USE_STATIC_MODULES` (+131/−2 over 8 files; dynamic builds untouched).
- Collision found: engine's built-in UI exports `vmMain`; cgame's `vmMain` renamed `cgame_vmMain` in static builds only.
- Both modules verified hermetic beforehand (`nm -u`: only libc/libc++/GL/zlib undefineds — no engine symbols), which is why the seam is this small.
- `ld -r` needs `-platform_version macos <target> <target>` with modern ld.
- Verified: single binary (3.5 MB), no module dylibs in bundle, signs cleanly, startup log identical to dynamic reference except the removed dlopen line; campaign playable (user-confirmed).
- Build via `./build-openjo-macos.sh static` → `build-macos-static/`, `install-macos-static/`.

## Phase 3.3 + 3.4 — GLES1 renderer and iOS target (2026-07-12)

- Branch `openjo-ios` (off `openjo-static`):
  - `137e48a8` — cherry-pick of emileb's `USE_GLES1` rd-vanilla port (GPLv2, from `emileb/OpenJK` `master_mobile`, merge-base `8cce3ea2`), scoped to `code/rd-vanilla`, +1,304 lines; iOS adaptations: OpenGLES/ES1 headers in qgl.h, `USE_GLES1` + OpenGLES.framework when `IOS` in CMake.
  - `66a54dc6` — iOS platform support: Documents homepath, `SDL_main` rename, static SDL2 link, iOS Info.plist (UIFileSharingEnabled, landscape), Architecture detection for cross builds, `glStencilOpSeparate` stub + forced two-pass stencil shadows on Apple GLES1.
- `build-openjo-ios.sh [sim|device]` — fetches/builds **real SDL2** (`release-2.32.10`, static) for the target, then builds the fully static app. Simulator needs no signing.
- **Milestone: first-ever JK2 on iOS** — boots on the iPhone 17 Pro simulator: all four pk3s found in sandbox Documents, `OpenGL ES-CM 1.1 APPLE` context via SDL `uikit`, main-menu scene renders, clean exit. (Simulator uses Apple Software Renderer; a real device uses the GPU driver.)
- Cross-build gotchas hit: `CMAKE_SYSTEM_PROCESSOR` empty under `-DCMAKE_SYSTEM_NAME=iOS` (fixed in-tree via `CMAKE_OSX_ARCHITECTURES`); `CMAKE_FIND_ROOT_PATH` needed for the SDL2 prefix; `ld -r` needs `-platform_version ios-simulator`.

## Known issues

- **iOS: on-screen keyboard appears at boot** (simulator, 2026-07-12): SDL's uikit backend starts text input eagerly; fix alongside touch input (3.6).
- **iOS: renders at 800×600 windowed default** instead of native fullscreen resolution; set mode/fullscreen for iOS at startup (3.5/3.7 polish).
- **Double save-load crash** (2026-07-12, static build): load a save, then ESC → load the same save again → crash. **Unclassified** — not yet reproduced on the dynamic reference build, so it's unknown whether this is (a) a static-link regression (game module globals are no longer reset by dlclose/dlopen on each load — the classic hazard of this refactor) or (b) the pre-existing OpenJK 64-bit savegame weak spot. First diagnostic step when picked up: repro the exact sequence on `install-macos/` (dynamic). Deferred per user to keep Phase 3 moving; revisit after something lands on iOS. Note the same staleness question applies to `vid_restart` (renderer globals) — untested.

## OpenJK patches (fork branch `openjo-macos` → `openjo-static`)

- `20991733` — `BuildJK2SPStatic` static-link option (see Phase 3.1 above). Written to be upstreamable.

## Asset checksums

_Pending Phase 2._
