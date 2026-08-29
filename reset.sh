#!/bin/bash
set -e

container rm -af 2>/dev/null || true

if [ -z "$1" ]; then
  exit 0
fi

REPO_NAME=$1
shift

PORTS=""
for PORT in "$@"; do
    PORTS="$PORTS -p 127.0.0.1:${PORT}"
done

WORKSPACE_DIR="${WORKSPACE_DIR:-$PWD}"
GIT_USER_NAME="${GIT_USER_NAME:-Agent}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-agent@minimall.io}"

# SSH key generation
read -rp "Generate new SSH key pair for container? [Y/n]: " GENERATE_KEYS
GENERATE_KEYS="${GENERATE_KEYS:-Y}"

read -rp "Key folder [~/.ssh/devc]: " KEY_DIR
KEY_DIR="${KEY_DIR:-$HOME/.ssh/devc}"
KEY_DIR="${KEY_DIR/#\~/$HOME}"

if [[ "$GENERATE_KEYS" =~ ^[Yy]$ ]]; then
  mkdir -p "$KEY_DIR"
  chmod 700 "$KEY_DIR"

  rm -f "$KEY_DIR/vm" "$KEY_DIR/vm.pub"
  ssh-keygen -t ed25519 -f "$KEY_DIR/vm" -N "" -C "devc" -q

  cat > "$KEY_DIR/config" <<EOF
Host vm
    HostName 127.0.0.1
    Port 2222
    User root
    IdentityFile $KEY_DIR/vm
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
  chmod 600 "$KEY_DIR/config"

fi

INCLUDE_LINE="Include $KEY_DIR/config"
if ! grep -qF "$INCLUDE_LINE" ~/.ssh/config 2>/dev/null; then
  tmp=$(mktemp)
  { echo "$INCLUDE_LINE"; echo ""; cat ~/.ssh/config 2>/dev/null || true; } > "$tmp"
  cp "$tmp" ~/.ssh/config
  rm "$tmp"
  chmod 600 ~/.ssh/config
fi

if [ ! -f "$KEY_DIR/vm.pub" ]; then
  echo "Error: SSH public key not found at $KEY_DIR/vm.pub"
  exit 1
fi

container run -d \
  --name ${REPO_NAME}-container \
  --cpus 4 \
  --memory 12g \
  -v "${WORKSPACE_DIR}/${REPO_NAME}:/root/${REPO_NAME}" \
  -e GIT_AUTHOR_NAME="${GIT_USER_NAME}" \
  -e GIT_AUTHOR_EMAIL="${GIT_USER_EMAIL}" \
  -e GIT_COMMITTER_NAME="${GIT_USER_NAME}" \
  -e GIT_COMMITTER_EMAIL="${GIT_USER_EMAIL}" \
  -p 127.0.0.1:2222:22 \
  $PORTS \
  $REPO_NAME

container exec ${REPO_NAME}-container bash -c "until pgrep sshd > /dev/null; do sleep 0.5; done"

container exec ${REPO_NAME}-container bash -c \
  'printf "%s\\n" "$1" > /root/.ssh/authorized_keys && \
   chmod 600 /root/.ssh/authorized_keys' \
  authorized_keys "$(cat "$KEY_DIR/vm.pub")"

container exec ${REPO_NAME}-container bash -c \
  "git config --global user.name '${GIT_USER_NAME}' && \
   git config --global user.email '${GIT_USER_EMAIL}'"
