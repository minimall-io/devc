#!/bin/bash
set -e

SRC_DIR=$(cd -P "$(dirname "$0")" 2>/dev/null && pwd) || SRC_DIR=""
DEVC_HOME="${DEVC_HOME:-$HOME/.devc}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"
REPO="${DEVC_REPO:-minimall-io/devc}"
REF="${DEVC_REF:-main}"

# Piped from curl there are no files beside the script, and $0 resolves to
# the working directory, so fetch a copy of the repository instead of
# reading whatever happens to be sitting there.
if [ ! -f "$SRC_DIR/devc" ]; then
  SRC_DIR=$(mktemp -d)
  trap 'rm -rf "$SRC_DIR"' EXIT

  curl -fsSL "https://codeload.github.com/$REPO/tar.gz/$REF" \
    | tar xz -C "$SRC_DIR" --strip-components=1

  echo "Fetched $REPO@$REF"
fi

mkdir -p "$DEVC_HOME" "$BIN_DIR"

for FILE in devc init.sh rebuild.sh reset.sh uninstall.sh Dockerfile; do
  cp "$SRC_DIR/$FILE" "$DEVC_HOME/$FILE"
  echo "Installed $DEVC_HOME/$FILE"
done

chmod +x "$DEVC_HOME/devc" "$DEVC_HOME/uninstall.sh"

# A checkout can name the exact commit; a fetched tarball only knows its ref.
git -C "$SRC_DIR" describe --always --dirty > "$DEVC_HOME/.version" 2>/dev/null \
  || echo "$REF" > "$DEVC_HOME/.version"

ln -sf "$DEVC_HOME/devc" "$BIN_DIR/devc"
echo "Linked $BIN_DIR/devc -> $DEVC_HOME/devc"

case ":$PATH:" in
  *":$BIN_DIR:"*) exit 0 ;;
esac

# $BIN_DIR is not on PATH: add it to the shell profile, marked so that
# uninstall.sh can take it back out again.
case "$(basename "${SHELL:-}")" in
  zsh)  PROFILE="$HOME/.zshrc" ;;
  bash) if [ -f "$HOME/.bash_profile" ]; then
          PROFILE="$HOME/.bash_profile"      # login shells, the macOS default
        else
          PROFILE="$HOME/.bashrc"            # interactive shells elsewhere
        fi ;;
  *)    PROFILE="" ;;
esac

if [ -z "$PROFILE" ]; then
  echo
  echo "$BIN_DIR is not on PATH, and the shell '${SHELL:-unknown}' is not one"
  echo "this installer knows how to configure. Add this to the shell profile:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
  exit 0
fi

if [ "$BIN_DIR" = "$HOME/.local/bin" ]; then
  PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'
else
  PATH_LINE="export PATH=\"$BIN_DIR:\$PATH\""
fi

if ! grep -q "^# devc$" "$PROFILE" 2>/dev/null; then
  # Keep the marker and the export adjacent, so uninstall.sh removes both.
  if [ -s "$PROFILE" ] && [ -n "$(tail -c 1 "$PROFILE")" ]; then
    echo >> "$PROFILE"
  fi
  printf '%s\n%s\n' "# devc" "$PATH_LINE" >> "$PROFILE"
  echo "Added $BIN_DIR to PATH in $PROFILE"
fi

echo
echo "Run this once to pick it up in the current shell:"
echo "  source $PROFILE"
