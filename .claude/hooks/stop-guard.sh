#!/bin/bash
# Stop hook: Warn about uncommitted changes on session exit
# Guard against infinite loops
if [ "$stop_hook_active" = "1" ]; then exit 0; fi
export stop_hook_active=1

CHANGES=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
STAGED=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

if [ "$CHANGES" -gt 0 ] || [ "$STAGED" -gt 0 ]; then
  echo "[Session Exit] Warning: $CHANGES unstaged + $STAGED staged changes remain uncommitted."
fi
exit 0
