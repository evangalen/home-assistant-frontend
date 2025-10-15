#!/bin/bash

# Usage: ./regex-search.sh '<regex>' <folder>
#

# --- 1. VALIDATION AND SETUP ---
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 \"<regex>\" <folder>"
    exit 1
fi

REGEX_PATTERN="$1"
SEARCH_FOLDER="$2"

# Determine which grep command to use for cross-platform compatibility.
if command -v ggrep &> /dev/null; then
  GREP_CMD="ggrep"
else
  GREP_CMD="grep"
fi

"$GREP_CMD" -rPzo "$REGEX_PATTERN" "$SEARCH_FOLDER" --color=always | tr '\0' '\n'
