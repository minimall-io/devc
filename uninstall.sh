#!/bin/bash
set -e

DEVC_HOME="${DEVC_HOME:-$HOME/.devc}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

if [ -e "$BIN_DIR/devc" ] || [ -L "$BIN_DIR/devc" ]; then
  rm -f "$BIN_DIR/devc"
  echo "Removed $BIN_DIR/devc"
fi

case "$(basename "${SHELL:-}")" in
  zsh)  PROFILE="$HOME/.zshrc" ;;
  bash) if [ -f "$HOME/.bash_profile" ]; then
          PROFILE="$HOME/.bash_profile"      # login shells, the macOS default
        else
          PROFILE="$HOME/.bashrc"            # interactive shells elsewhere
        fi ;;
  *)    PROFILE="" ;;
esac

# Drop the marker line and the export that install.sh wrote beneath it.
if [ -n "$PROFILE" ] && grep -q "^# devc$" "$PROFILE" 2>/dev/null; then
  TMP=$(mktemp)
  awk '/^# devc$/ { skip = 2 } skip { skip--; next } { print }' "$PROFILE" > "$TMP"
  cp "$TMP" "$PROFILE"
  rm "$TMP"
  echo "Removed the PATH entry from $PROFILE"
fi

# Last, because this script lives in the directory being removed.
if [ -d "$DEVC_HOME" ]; then
  rm -rf "$DEVC_HOME"
  echo "Removed $DEVC_HOME"
fi
