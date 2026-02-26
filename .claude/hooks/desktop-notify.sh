#!/bin/bash
# Notification hook: Desktop alert on macOS
MESSAGE=$(jq -r '.message // "Task completed"')
if command -v osascript &> /dev/null; then
  osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\"" 2>/dev/null
fi
exit 0
