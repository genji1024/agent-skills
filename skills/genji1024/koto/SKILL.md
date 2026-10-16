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

- Space power levels live in `spaceEvents` (event type → required level);
  `ensureRootJoinable` resets any that differ, so raising a level (as for
  `m.space.child` → 100) works the same as opening one.
- Membership is by the admin's invitation (#27): the space is invite-only,
  koto joins only with the space's own invitation, and tests let members in
  with `joinCommunity` / `inviteMember` (`src/matrix/testing.ts`).
- `m.federate: false` is set at creation and never changes (#29). Existing
  communities can only get it by being rebuilt.
- Rooms in the space (#31): only the admin writes `m.space.child`; members
  register rooms with `com.genji1024.koto.room` (state key = room id, empty
  = deleted). `listRooms` shows only rooms passing `belongsTo` (kind,
  parent, restricted to the space, `m.federate` as closed as the space);
  `joinNewChildren` leaves registered rooms that fail it and, for the admin,
  mirrors the registry into `m.space.child`. Loops over rooms that may need
  fixing (join rules) use `linkedRooms`, not `listRooms`.
- Production data dates from 2026-09-24 (migrated from Supabase), after
  rooms became restricted (2026-09-20): every live room has the restricted
  join rule.

## Federation plan (Issue #25)

Server federates, community stays closed. One PR at a time, each after the
previous merge, each with its own sub-issue: 1 invitation-only (#26/#27,
merged), 2 `m.federate: false` (#28/#29, merged), 3 room registry
(#30/#31), 4 rebuild script for existing communities (freeze, recreate with
`m.federate: false`, re-post as authors, tombstone), 5 server federation
(listener, `.well-known/matrix/server`, Traefik, narrow `ip_range_whitelist`
to Sygnal, profile limits; only after 1–4 and the rebuild), 6 docs. Read
#25 for the decisions before starting the next one. Separate idea, not yet
an issue: removing a member deactivates the account, which conflicts with
accounts used outside koto.

## Upgrading production

When asked how a merged change reaches production ("マイグレーションは？"),
answer for that change. Ways it can happen:

- **Automatic, when the admin opens koto**: `ensureRootJoinable` (join
  rules, power levels, alias). Only the space's level-100 admin triggers it.
- **Manual scripts** run from `client/` with `KOTO_BASE_URL`,
  `KOTO_ADMIN_USER`, `KOTO_ADMIN_PASSWORD`: `scripts/upgrade-posts.ts`
  (`--dry-run` first) and `scripts/migrate.ts` (Supabase import).
- Deploy itself is `git pull && ./scripts/deploy.sh` (main also deploys the
  demo through `.forgejo/workflows/deploy-demo.yml`).

Put an **Upgrading** section in each PR body saying which applies.

## Operations

- Demo reset (user `koto-demo`, rootless Docker, repo `~/koto`):
  `sudo machinectl shell koto-demo@`, `docker compose --profile push down`,
  remove `data/postgres` and `data/synapse` through a container
  (`docker run --rm -v "$PWD/data:/data" alpine rm -rf ...`), then
  `./scripts/deploy.sh` and first-time setup with `SETUP_PASSWORD`. Keep
  `.env` and `data/sygnal/`.
- A lost password: register a temporary server admin
  (`scripts/create-user.sh -a`), `POST /_synapse/admin/v1/reset_password/<user>`,
  then deactivate the temporary admin.
- Sygnal shows `unhealthy` in production: its image's HEALTHCHECK runs
  `curl`, which the image lacks (`curl: not found`). Push works; check with
  `docker compose exec synapse curl -s -o /dev/null -w '%{http_code}\n' http://sygnal:5000/health`
  (200). Pending fix the user deferred (2026-10-16): a compose `healthcheck`
  using python `urllib`. Offer it as its own Issue/PR.

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
  `migrate`, `rooms`, `preview`, `ui`, `e2e`, `integration`; server: `compose`, `synapse`, `init`,
  `check`; whole repo: `repo`, `readme`, `license`. See
  [`commit-message`](../../commit-message/SKILL.md).
