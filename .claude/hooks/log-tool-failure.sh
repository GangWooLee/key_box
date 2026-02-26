#!/bin/bash
# PostToolUseFailure hook: Log tool failures for debugging
LOG_DIR="$CLAUDE_PROJECT_DIR/log"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/claude-tool-failures.log"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ERROR=$(echo "$INPUT" | jq -r '.error // "no error message"' | head -5)

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Tool: $TOOL_NAME | Error: $ERROR" >> "$LOG_FILE"
exit 0
