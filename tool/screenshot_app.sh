#!/usr/bin/env bash
#
# screenshot_app.sh — capture the running KeyBox macOS window to a PNG.
#
# Usage:
#   tool/screenshot_app.sh <output.png>
#
# Part of the V9 design vision-verification infra: golden tests cover static
# screen looks; this captures the *real* app window (native chrome, window
# manager, live data) for design-review passes.
#
# Requires the app to already be running, e.g.:
#   open build/macos/Build/Products/Debug/KeyBox.app
#
# Locates the window via Quartz `CGWindowListCopyWindowInfo` → the window's
# kCGWindowNumber, then captures it with `screencapture -l`. Two bindings to
# that same Quartz API are tried, in order:
#   1. python3 + pyobjc (Quartz)     — if pyobjc-framework-Quartz is installed
#   2. swift + CoreGraphics          — always present on a Flutter-macOS dev box
#
# Needs Screen Recording permission for the invoking terminal; without it the
# capture is a blank/empty file and this script reports that rather than
# emitting a misleading image.
set -euo pipefail

if [[ $# -lt 1 || -z "${1:-}" ]]; then
  echo "usage: $(basename "$0") <output.png>" >&2
  exit 2
fi
OUT="$1"

# ── Resolve the KeyBox on-screen window number ────────────────────────────
# The Flutter macOS app's owner name is the executable ("key_box") or the
# bundle display name ("KeyBox"); match either, case-insensitively. Prints the
# window number on success; empty output means "not found".

_winid_via_python() {
  command -v python3 >/dev/null 2>&1 || return 1
  python3 - <<'PY' 2>/dev/null || return 1
import sys
try:
    from Quartz import (
        CGWindowListCopyWindowInfo,
        kCGWindowListOptionOnScreenOnly,
        kCGNullWindowID,
    )
except Exception:
    sys.exit(2)  # pyobjc/Quartz not available for this python3
targets = {"key_box", "keybox"}
wins = CGWindowListCopyWindowInfo(
    kCGWindowListOptionOnScreenOnly, kCGNullWindowID
) or []
best = None
for w in wins:
    if (w.get("kCGWindowOwnerName") or "").lower() not in targets:
        continue
    b = w.get("kCGWindowBounds") or {}
    area = float(b.get("Width", 0)) * float(b.get("Height", 0))
    key = (int(w.get("kCGWindowLayer", 0)), -area, int(w.get("kCGWindowNumber")))
    if best is None or key < best:
        best = key
if best is None:
    sys.exit(1)
print(best[2])
PY
}

_winid_via_swift() {
  command -v swift >/dev/null 2>&1 || return 1
  local src rc
  src="$(mktemp -t kb_winid).swift"
  cat > "$src" <<'SWIFT'
import CoreGraphics
import Foundation
let targets: Set<String> = ["key_box", "keybox"]
guard let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID)
        as? [[String: Any]] else { exit(2) }
var best: (Int, Double, Int)? = nil
for w in list {
  let owner = (w[kCGWindowOwnerName as String] as? String) ?? ""
  guard targets.contains(owner.lowercased()) else { continue }
  let num = (w[kCGWindowNumber as String] as? Int) ?? -1
  let layer = (w[kCGWindowLayer as String] as? Int) ?? 0
  var area = 0.0
  if let b = w[kCGWindowBounds as String] as? [String: Any] {
    area = ((b["Width"] as? Double) ?? 0) * ((b["Height"] as? Double) ?? 0)
  }
  let cand = (layer, -area, num)
  if best == nil || cand < best! { best = cand }
}
if let b = best { print(b.2) } else { exit(1) }
SWIFT
  swift "$src" 2>/dev/null
  rc=$?
  rm -f "$src"
  return $rc
}

WID="$(_winid_via_python || true)"
if [[ -z "$WID" ]]; then
  WID="$(_winid_via_swift || true)"
fi

if [[ -z "$WID" ]]; then
  if ! command -v python3 >/dev/null 2>&1 && ! command -v swift >/dev/null 2>&1; then
    echo "error: neither python3 (with pyobjc/Quartz) nor swift is available to" >&2
    echo "       locate the window. Install one, e.g. Xcode Command Line Tools." >&2
    exit 3
  fi
  echo "error: KeyBox is not running — no on-screen window owned by key_box/KeyBox." >&2
  echo "       Launch it first:  open build/macos/Build/Products/Debug/KeyBox.app" >&2
  exit 1
fi

# ── Capture ───────────────────────────────────────────────────────────────
# `|| true` so a capture failure doesn't trip `set -e` before the friendly
# permission hint below (screencapture prints "could not create image from
# window" and yields no file when Screen Recording permission is missing).
/usr/sbin/screencapture -x -l"$WID" "$OUT" || true

if [[ ! -s "$OUT" ]]; then
  echo "error: found KeyBox window $WID but screencapture produced no image." >&2
  echo "       This is almost always a missing Screen Recording permission." >&2
  echo "       Grant it to your terminal under System Settings > Privacy &" >&2
  echo "       Security > Screen Recording, then retry." >&2
  exit 4
fi

echo "captured KeyBox window $WID -> $OUT ($(/usr/bin/stat -f%z "$OUT") bytes)"
