#!/usr/bin/env bash
#
# dogfood.sh — rebuild the macOS app from HEAD, then relaunch it.
#
# Why this exists: on 2026-07-15 a folder-placement fix (2317cd7) landed in the
# source, but the .app being dogfooded was built the night before (Jul 14). The
# running binary predated the fix, so the "already-fixed" bug still showed up in
# real use — "source fixed ≠ binary rebuilt". Always rebuild before you test the
# real app, and let this script guarantee the binary matches HEAD.
#
# Usage:
#   scripts/dogfood.sh [debug|release]     # default: release (matches real use)
#
set -euo pipefail

FLAVOR="${1:-release}"
cd "$(dirname "$0")/.."

case "$FLAVOR" in
  debug)   BUILD_ARGS=(--debug);   PRODUCT_DIR="Debug" ;;
  release) BUILD_ARGS=(--release); PRODUCT_DIR="Release" ;;
  *) echo "usage: $0 [debug|release]" >&2; exit 2 ;;
esac

HEAD_SHA="$(git rev-parse --short HEAD)"
echo "▶ Building $FLAVOR from $HEAD_SHA — flutter build macos ${BUILD_ARGS[*]}"
flutter build macos "${BUILD_ARGS[@]}"

APP="build/macos/Build/Products/$PRODUCT_DIR/KeyBox.app"
[ -d "$APP" ] || { echo "✗ build produced no $APP" >&2; exit 1; }

echo "▶ Closing any running KeyBox (so the vault DB lock releases)…"
pkill -x KeyBox 2>/dev/null || true
sleep 1

echo "▶ Launching fresh build: $APP"
open "$APP"
echo "✓ Now dogfooding $HEAD_SHA ($FLAVOR) — the binary matches HEAD."
