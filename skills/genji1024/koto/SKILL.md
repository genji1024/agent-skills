---
name: koto
description: Pitfalls and conventions for the genji1024/koto repository — a closed-community Matrix client (React, matrix-js-sdk) plus its Synapse/PostgreSQL/Sygnal compose stack. Load before changing koto's Matrix data layer, its UI, the homeserver config or scripts, or running its tests and E2E.
---

# koto

The repository documents itself; read these first instead of rediscovering:

- `docs/architecture.md` — how koto maps onto Matrix (space, child rooms by
  kind, `com.genji1024.koto.*` event types, power levels)
- `docs/deployment.md`, `docs/troubleshooting.md` — the stack and its failures
- `docs/development.md` — tests, E2E, repository layout

This skill lists what those do not say, or what cost time to find out.

## Data model changes

- Never rename the `com.genji1024.koto` namespace: live communities hold data
  under it.
- New rooms or new member-writable event types reach existing communities
  only through `ensureRootJoinable` in `client/src/matrix/koto.ts`, which runs
  when the **admin** opens koto. Until then members get 403s; route those
  through `describeError` so they see the "管理者が koto を開くと更新されます"
  message, and say in the change that the admin must open koto first.

## matrix-js-sdk behaviour koto depends on

- `startClient` uses `PendingEventOrdering.Detached` (relation and redaction
  code needs it). Pending events are then **not** in the live timeline: show
  local echoes from `room.getPendingEvents()`.
- An edit is applied to the original event asynchronously, after the
  Timeline event for the `m.replace`: listen for `MatrixEventEvent.Replaced`
  on each shown event.
- `createRoom`/`joinRoom` resolve before the room's state has synced; wait for
  the koto state event (`waitForRoom`). State that arrives right after a join
  fires no Timeline event: listen to `RoomStateEvent.Update` client-wide and
  to `kotoEvents` "children".
- Keep the SDK's `threadSupport` **off**. Diary photos are thread replies;
  turning it on moves them out of the room timeline and breaks deleting them
  and read receipts. The chat groups thread replies itself.
- Compute per-item data (reactions, read state) in the parent and key rows by
  event id only. Keying by anything that changes on each event remounts rows
  and closes open menus and editors.
- On alias lookup, only `M_NOT_FOUND` means "no community". Any other failure
  (offline) must not offer to create a second one.
- `crypto.subtle` does not exist over plain HTTP; hashing uses `@noble/hashes`.

## Media

- Synapse serves media only with a token: fetch it and use blob URLs
  (`client/src/media.ts`).
- Upload blobs with a real MIME type. A typeless `Blob` is stored as
  `application/octet-stream` and never thumbnailed.

## Homeserver and scripts

- `data/synapse/homeserver.yaml` is a bind mount: after `./scripts/init.sh`,
  `docker compose restart synapse`, or Synapse keeps the old config.
- For bulk writes (the migration), retry `M_LIMIT_EXCEEDED` after
  `retry_after_ms` rather than aborting. The admin API refuses login-as-user
  for the caller itself: reuse the admin's own session for its account.
- Traefik v3 `PathPrefix` takes one argument; combine with `||`.

## Tests

- `client/e2e/run.sh` runs in a throwaway copy of the repo under separate
  compose project names. Keep it that way: resetting the stack in the
  checkout would wipe the real `.env` and `data/`.
- koto opens on the ルーム (Rooms) tab. Tab labels can be renamed in settings,
  so `e2e.mjs` looks them up through `settingsTab` rather than literals.
- Without Docker (a sandbox), use `client/e2e/run-local.sh [integration|e2e]`
  (see docs/development.md). What it took to get there:
  - The checkout's `client/node_modules` may come from an Alpine container
    (musl native bindings) and fail on a glibc host. The script works in a
    copy with its own `npm ci`; do the same for ad-hoc tsc/lint/tests.
  - Playwright 1.58.0's `playwright install chromium` hangs while unpacking
    under Node 26; the script pins 1.64.0. Chromium also needs its shared
    libraries on the host.
  - The service-worker steps need the preview server to answer like
    `client/nginx.conf`: no-store on `/config.json`, `/index.html`,
    `/sw.js`, and `preview.cors: false`. vite preview's CORS adds
    `Vary: Origin`, cached assets never match, and the offline start fails.
    Keep the no-store list in `vite.config.ts` in sync with nginx.conf.
  - The integration tests expect server name `matrix.example.com` for a
    server on 127.0.0.1.
  - On a small host, run one server set at a time; both scripts stop their
    servers and delete their data on exit.
- Push cannot be tested headless (Chromium always denies notification
  permission) or in incognito contexts (no Push API): `client/e2e/push.mjs`
  runs headed with a persistent profile under `xvfb-run`.
- Pure logic (thread grouping, recurrence) has unit tests that run without a
  server; put new pure logic where it can be tested the same way.

## Writing

- The UI is Japanese; README, docs and commits are English. In docs, quote a
  UI label in Japanese with an English gloss: **メンバー** (Members).
- Don't write "家族" (family) in UI or docs: the audience is any closed group.
- Before every commit, load [`commit-message`](../../commit-message/SKILL.md)
  and follow it (format, length checks, the user's approval). This skill's
  scope list does not replace it.
- Commit scopes — client: `app`, `setup`, `chat`, `diary`, `notes`, `todo`,
  `calendar`, `members`, `profile`, `settings`, `pwa`, `push`, `media`,
  `migrate`, `ui`, `e2e`, `integration`; server: `compose`, `synapse`, `init`,
  `check`; whole repo: `repo`, `readme`, `license`. See
  [`commit-message`](../../commit-message/SKILL.md).
