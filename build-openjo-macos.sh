#!/bin/zsh
# Build OpenJO (Jedi Outcast SP) for macOS from vendor/openjk.
# Out-of-tree: configure/build in build-macos/, install into install-macos/.
set -euo pipefail

cd "$(dirname "$0")"

ARCH=$(uname -m)

echo "== Toolchain =="
echo "arch:  $ARCH"
clang --version | head -1
cmake --version | head -1
echo "ninja: $(ninja --version)"
echo "sdl2:  $(brew list --versions sdl2)"
echo

echo "== Configure =="
cmake -G Ninja -S vendor/openjk -B build-macos \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$(brew --prefix)" \
  -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0 \
  -DCMAKE_INSTALL_PREFIX=./install-macos \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  -DBuildJK2SPEngine=ON -DBuildJK2SPGame=ON -DBuildJK2SPRdVanilla=ON \
  -DBuildSPEngine=OFF -DBuildSPGame=OFF -DBuildSPRdVanilla=OFF \
  -DBuildMPEngine=OFF -DBuildMPRdVanilla=OFF -DBuildMPDed=OFF \
  -DBuildMPGame=OFF -DBuildMPCGame=OFF -DBuildMPUI=OFF -DBuildMPRend2=OFF

echo
echo "== Build =="
cmake --build build-macos

echo
echo "== Install =="
cmake --install build-macos

BUNDLE="install-macos/JediOutcast/openjo_sp.${ARCH}.app"

echo
echo "== Vendor SDL3 (sdl2-compat runtime dependency) =="
# Homebrew's "sdl2" is sdl2-compat: a shim that dlopens libSDL3 at load time.
# fixup_bundle can't see that (it's not a load command), and the bundled copy
# loses the keg rpath, so its @loader_path/libSDL3.dylib candidate must exist.
cp "$(brew --prefix sdl3)/lib/libSDL3.0.dylib" "$BUNDLE/Contents/Frameworks/libSDL3.dylib"

echo
echo "== Codesign (ad-hoc, post-fixup_bundle) =="
# fixup_bundle() rewrites load commands after linking, invalidating the
# linker's ad-hoc signature — re-sign nested dylibs first, then the bundle.
find "$BUNDLE" -name '*.dylib' -exec codesign --force --sign - {} \;
codesign --force --sign - "$BUNDLE"

echo
echo "== Verify =="
BIN="$BUNDLE/Contents/MacOS/openjo_sp.${ARCH}"
lipo -archs "$BIN"
otool -L "$BIN" | grep -i sdl || true
codesign -vvv --deep --strict "$BUNDLE"
echo "OK: $BUNDLE"
