# devc

Per-repository development containers for the [Apple `container`](https://github.com/apple/container) CLI on macOS.

Each repository is built from its own `Dockerfile` and run as a container with the working
copy mounted inside and an SSH server on `127.0.0.1:2222`, reachable as `ssh vm` or through
VS Code Remote-SSH. Containers hold no git credentials.

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/minimall-io/devc/main/install.sh | bash
```

The scripts are copied to `~/.devc` and linked as `~/.local/bin/devc`. When that directory is
not on `PATH`, an export is appended to the shell profile under a `# devc` marker, which
applies to shells started afterwards or immediately after:

```bash
source ~/.zshrc
```

Re-running the installer updates an existing installation in place.

| Variable | Default | Effect |
| --- | --- | --- |
| `DEVC_HOME` | `~/.devc` | Install directory |
| `BIN_DIR` | `~/.local/bin` | Directory holding the `devc` symlink |
| `DEVC_REF` | `main` | Branch, tag or commit to install |

## Commands

```
devc init <repo>               copy the Dockerfile template into <repo>
devc rebuild <repo>            build the <repo> image
devc rebuild                   remove every image
devc reset <repo> [port ...]   run the <repo> container
devc reset                     remove every container
devc version                   print the installed version
devc                           usage
```

`<repo>` is a directory in the current working directory, so `devc` runs from the folder that
holds the repositories. The no-argument forms are destructive, and act on every image or
container on the machine rather than only those `devc` created.

```bash
devc init myrepo             # writes myrepo/Dockerfile, refuses to overwrite one
devc rebuild myrepo          # build the image
devc reset myrepo 3000 8080  # run it, forwarding extra ports
ssh vm
```

`reset` removes every running container first, then starts `myrepo-container` with the
repository mounted at `/root/myrepo` and ports published on `127.0.0.1` only. On the first run
it offers to generate an ed25519 key pair in `~/.ssh/devc` and adds a `Host vm` entry to
`~/.ssh/config`.

| Variable | Default | Effect |
| --- | --- | --- |
| `WORKSPACE_DIR` | current directory | Where `<repo>` is looked up |
| `GIT_USER_NAME` | `Agent` | `user.name` inside the container |
| `GIT_USER_EMAIL` | `agent@minimall.io` | `user.email` inside the container |

## Removal

```bash
~/.devc/uninstall.sh
```

Removes the symlink, the `~/.devc` directory, and the lines added to the shell profile.
Generated SSH keys, the `Include` line in `~/.ssh/config`, and any images or containers built
along the way are left in place.
