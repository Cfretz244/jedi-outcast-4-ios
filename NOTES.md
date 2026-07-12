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

## OpenJK patches (fork branch `openjo-macos`)

_None yet._

## Asset checksums

_Pending Phase 2._
