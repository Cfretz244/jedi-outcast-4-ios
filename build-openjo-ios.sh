#!/bin/zsh
# Build OpenJO (Jedi Outcast SP) for iOS from vendor/openjk.
#
# Usage: build-openjo-ios.sh [sim|device]   (default: sim)
#   sim    — iOS Simulator (arm64), no code signing required
#   device — iOS device (arm64); binary is left ad-hoc signed, real signing
#            happens at sideload time (AltStore/SideStore)
#
# SDL2 (real SDL2, pinned release, not sdl2-compat) is fetched and built
# statically for the target the first time through.
set -euo pipefail

cd "$(dirname "$0")"

TARGET="${1:-sim}"
SDL2_TAG=release-2.32.10
IOS_MIN=13.0

case "$TARGET" in
  sim)
    SYSROOT=iphonesimulator
    SUFFIX=ios-sim
    ;;
  device)
    SYSROOT=iphoneos
    SUFFIX=ios
    ;;
  *)
    echo "usage: $0 [sim|device]" >&2; exit 2
    ;;
esac

DEPS_SRC=build-ios-deps
DEPS_PREFIX="$PWD/install-$SUFFIX-deps"
BUILD_DIR="build-$SUFFIX"

echo "== SDL2 ($SDL2_TAG, static, $SYSROOT) =="
if [[ ! -d "$DEPS_SRC/SDL" ]]; then
  mkdir -p "$DEPS_SRC"
  git clone --depth 1 --branch "$SDL2_TAG" https://github.com/libsdl-org/SDL.git "$DEPS_SRC/SDL"
fi
if [[ ! -f "$DEPS_PREFIX/lib/libSDL2.a" ]]; then
  cmake -G Ninja -S "$DEPS_SRC/SDL" -B "$DEPS_SRC/SDL-$SUFFIX" \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$SYSROOT" \
    -DCMAKE_OSX_ARCHITECTURES=arm64 \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$DEPS_PREFIX" \
    -DSDL_SHARED=OFF -DSDL_STATIC=ON -DSDL_TEST=OFF
  cmake --build "$DEPS_SRC/SDL-$SUFFIX"
  cmake --install "$DEPS_SRC/SDL-$SUFFIX"
fi

echo
echo "== Configure OpenJO ($SYSROOT) =="
cmake -G Ninja -S vendor/openjk -B "$BUILD_DIR" \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_SYSTEM_PROCESSOR=arm64 \
  -DCMAKE_OSX_SYSROOT="$SYSROOT" \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_MIN" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="$DEPS_PREFIX" \
  -DCMAKE_FIND_ROOT_PATH="$DEPS_PREFIX" \
  -DBuildJK2SPEngine=ON -DBuildJK2SPGame=ON -DBuildJK2SPRdVanilla=ON \
  -DBuildJK2SPStatic=ON \
  -DBuildSPEngine=OFF -DBuildSPGame=OFF -DBuildSPRdVanilla=OFF \
  -DBuildMPEngine=OFF -DBuildMPRdVanilla=OFF -DBuildMPDed=OFF \
  -DBuildMPGame=OFF -DBuildMPCGame=OFF -DBuildMPUI=OFF -DBuildMPRend2=OFF

echo
echo "== Build =="
cmake --build "$BUILD_DIR"

APP="$BUILD_DIR/openjo_sp.arm64.app"
echo
echo "== Sign (ad-hoc) =="
codesign --force --sign - "$APP"
echo "OK: $APP"
