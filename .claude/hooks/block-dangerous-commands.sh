#!/bin/bash
# PreToolUse hook: Block dangerous Bash commands
# Exit 0 = allow, Exit 2 = block

COMMAND=$(jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -iE '(rails db:(drop|reset)|rm -rf /|git push --force.*main|git reset --hard)' > /dev/null 2>&1; then
  echo "Blocked: Destructive command detected — $COMMAND" >&2
  exit 2
fi

exit 0
