#!/bin/bash
# PreCompact hook: Save working state before context compaction
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/plans"
STATE_FILE="$CLAUDE_PROJECT_DIR/.claude/plans/.pre-compact-state.md"
{
  echo "# Pre-Compact State ($(date '+%Y-%m-%d %H:%M'))"
  echo "## Git State"
  echo "- Branch: $(git branch --show-current 2>/dev/null)"
  echo "- Modified files: $(git diff --name-only 2>/dev/null | head -10)"
  echo "- Staged files: $(git diff --cached --name-only 2>/dev/null | head -10)"
} > "$STATE_FILE"
exit 0
