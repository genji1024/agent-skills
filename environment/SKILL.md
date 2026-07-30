---
name: environment
description: Facts about the host/container runtime environment that opencode executes in. Load this skill before running shell commands that depend on OS, package manager, filesystem layout, or service availability.
---

# SKILL: Execution Environment

## Overview

This skill records the fixed facts about *where* opencode is running. Use it whenever a shell command depends on the operating system, package manager, init system, or filesystem layout. Check the relevant section before running a command — do not assume a generic Linux environment.

## Architecture

The dotfiles repository (`g-ohara/dotfiles`) follows a "one tool, one container" philosophy — see `.dockerscripts/README.md`. opencode itself runs inside its own Docker container rather than directly on the host.

- **Host**: Arch Linux (kernel `7.0.12-arch1-1`, rootless Docker, user `genji`).
- **opencode container**: built from `.dockerscripts/dockerfiles/opencode/Dockerfile`, base image `node:26.3.0-trixie-slim` → the running OS inside is **Debian GNU/Linux 13 (trixie)**.
- **Image tag**: `opencode:1.18.5`, built with `OPENCODE_VERSION=1.18.5`. opencode-ai and `difit` are installed via `npm install -g`. GitLab access is provided by the separate `gitlab-mcp` service (see below), not by a CLI installed in this image.

## How the container is launched

Wrapper: `.dockerscripts/opencode` (a `sh` script). It:

1. Runs `scripts/healthcheck.sh` against `https://opencode.ai/install`.
2. Creates the four runtime directories on the host: `~/.cache/opencode`, `~/.config/opencode`, `~/.local/share/opencode`, `~/.local/state/opencode`.
3. Invokes `docker compose -f ~/.dockerscripts/compose.yaml run --service-ports --rm opencode opencode "$@"`.

## Bind mounts (compose service `opencode`, `.dockerscripts/compose.yaml:144`)

- `${PWD}` → `${PWD}` (same path on both sides; the dotfiles repo appears at its real host path).
- `${HOME}/.agents` → `/root/.agents` (skills/agents lockfile).
- `${HOME}/.cache/opencode`, `${HOME}/.config/opencode`, `${HOME}/.local/share/opencode`, `${HOME}/.local/state/opencode` → corresponding `/root/...` paths.
- Inherits `common` (bind `${PWD}`, `working_dir: ${PWD}`, `tty: true`, COLORTERM).
- `depends_on: gitlab-mcp, github-mcp` — both MCP server containers start automatically:
  - GitLab: `http://gitlab-mcp:3002/mcp` (`@zereight/mcp-gitlab`, native Streamable HTTP, shared-secret auth via `STREAMABLE_HTTP_AUTH_TOKEN`)
  - GitHub: `http://github-mcp:3003/mcp` (official `github-mcp-server` wrapped in `mcp-proxy` since it only speaks stdio natively; no bearer auth — network isolation only)
  OpenCode's `mcp.gitlab`/`mcp.github` config (in `~/.config/opencode/opencode.jsonc`) points at these URLs.
- Port `4966:4966` is published (opencode server).

## Agent split (`~/.config/opencode/opencode.jsonc`)

OpenCode runs two agents to keep the expensive model's token usage down:
- **`orchestrator`** (primary, `opencode-go/glm-5.2`): `read`/`edit`/`bash`/`grep`/`glob`/`webfetch`/`gitlab_*`/`github_*` are all denied. It can only load skills and invoke the `task` tool to delegate to `worker`.
- **`worker`** (subagent, `opencode-go/deepseek-v4-flash`): full tool access, does the actual reading/running/MCP calls.

If you're reasoning about "why can't I read this file / run this command", check which agent is active first — `orchestrator` denying itself these tools is expected behavior, not a bug.

## Rules for shell commands

1. **Do NOT use Arch/pacman here.** The container is Debian. `pacman`, `yay`, `reflector`, `systemctl --user` (host units) are not available. If a package must be installed, use `apt-get` — and prefer not to install anything (the host intentionally keeps the environment clean).
2. **No Docker inside.** The Docker daemon socket is *not* mounted into the opencode container. `docker`, `docker compose`, spawning sibling containers — none of these work from here. (The Neovim container is the one that talks to the host daemon via `${XDG_RUNTIME_DIR}/docker.sock`; opencode does not.)
3. **No systemd.** `systemctl`, `journalctl`, `systemd-analyze` are not functional.
4. **`hostname` returns the container ID** (e.g. `723a1bb6263f`), not the host name. `uname -r` shows the host kernel (Arch), but `/etc/os-release` reports Debian 13. Read both before reasoning about the platform.
5. **Paths are 1:1 with the host.** Because `${PWD}` is bind-mounted as itself, the working directory path (e.g. `/home/genji/repos/dotfiles`) is identical inside and outside. Do not rewrite absolute paths when constructing commands.
6. **`~` maps to `/root`** inside the container (we run as `user: root`). `${HOME}` env may be inherited — when a path must resolve to the mounted config, prefer the `/root/...` target paths or `${HOME}` rather than guessing.
7. **Pre-installed tools**: `node` (v26.x), `npm`, `git`, `curl`, `opencode`, `difit`. Use these directly instead of looking for host binaries. `glab` is **not** available inside the opencode container — GitLab access goes through the `gitlab-mcp` MCP server container (HTTP at `http://gitlab-mcp:3002/mcp`), or via the `gitlab_*` MCP tools exposed through opencode.
8. **GUI/X11 not assumed.** Other services in the compose file (e.g. `firefox`) mount `/tmp/.X11-unix` and `DISPLAY`; the opencode service does **not**. Do not attempt to launch GUI apps from this container.

## When to Load This Skill

- Before running any shell command whose correctness depends on the OS, package manager, init system, or available binaries.
- Before suggesting a "system" command (`apt`, `pacman`, `systemctl`, `docker`, `snap`, …) — verify it against the rules above.
- When a user reports a path that looks different inside vs. outside the container.

## Cross-Reference

- [`general`](../general/SKILL.md) — skill-loading policy and baseline rules.
- [`mr-review`](../cpp-coursework/mr-review/SKILL.md) — workflow for resolving GitLab MR review
  comments using `gitlab_*` MCP tools, on the cpp-coursework project.

Note: this file is mirrored at `~/.agents/skills/environment/SKILL.md` in the
`g-ohara/dotfiles` repo (symlinked into the opencode container). If the two
drift, this repo is the source of truth going forward.
