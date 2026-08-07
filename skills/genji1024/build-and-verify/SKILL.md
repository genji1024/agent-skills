---
name: build-and-verify
description: Next.js の型チェック・lint・format・build を実行する手順。genji1024 配下のリポジトリ（private-note, private-opencode-server など）で共通のCI検証を行う際に使う。
---

# Build and Verify

## ビルド手順

```bash
rm -rf .next          # .next キャッシュクリア
npx tsc --noEmit      # 型チェック
npm run build         # Next.js ビルド
```

### 注意点

- `.next` キャッシュが古いとビルドエラーになることがあるため、必ずクリアする
- `tsc --noEmit` は `node_modules` の型エラーを除外して確認: `npx tsc --noEmit 2>&1 | grep -v node_modules`
- tsconfig の `@/*` パスは `./src/*` に設定（src/ ディレクトリ使用時）

## Lint・Format

```bash
npm run lint          # ESLint（--max-warnings 0 付き）
npm run format:check  # Prettier フォーマットチェック
npm run format        # Prettier フォーマット適用
npm run typecheck     # tsc --noEmit
```

## CI チェック

コード変更後、プッシュ前に以下の4ステップを**すべて**ローカルで実行:

1. `npm run lint --max-warnings 0`
2. `npm run format:check`
3. `npm run typecheck`
4. `npm run build`

CI のステータスも必ず確認する — `pull_request_read(method="get_check_runs")` を使用。

## Docker 動作確認

対象プロジェクトに Dockerfile / docker-compose.yml がある場合（private-note, private-opencode-server ともにある）は、
コード変更後、**Docker での動作確認も必須**:

1. イメージビルド（`docker build` / `docker compose build`）
2. コンテナ起動（`docker compose up -d`）
3. HTTP 応答確認（`curl` 等で 200 応答を確認）

Docker MCP サーバー（mcp-docker）のツールを使用する。結果は PR コメントに報告する。

## Docker 動作確認（docker-mcp 利用）

### 利用可能な docker-mcp ツール
- `docker_build_docker_image` — `dockerfile_dir` / `image_name` / `build_args` を指定可能
- `docker_create_network` / `docker_remove_network` — コンテナ間通信用ネットワーク
- `docker_start_container` — `image_name` / `name` / `command` / `network` / `ports` を指定して常駐起動
- `docker_docker_cp` — `container_name` / `container_path` / `workspace_path` / `direction` でファイル・ディレクトリを双方向コピー
- `docker_container_logs` — 常駐コンテナのログ取得（`tail` 指定可）
- `docker_exec_in_container` — 常駐コンテナ内でコマンド実行（`timeout_seconds` 指定可）
- `docker_inspect_object` — コンテナ・イメージ・ネットワーク等の inspect
- `docker_list_images` / `docker_list_containers`
- `docker_run_test_container` — 使い捨て実行（`image_name` / `command` / `network` 指定）
- `docker_stop_container` — 常駐コンテナの停止・破棄

### 利用できない機能（要望経過）
- イメージ削除（`docker image rm` 相当）は存在しない。検証で作ったイメージはネストデーモン内に残存する（ホストディスクには影響しない）

### デプロイ環境に近い動作確認の推奨パターン
Web アプリ + リバースプロキシ構成（例: Nginx + Next.js, Nginx + Node API）の検証では、**単一コンテナ起動ではなく2コンテナ連携**を実施する:

1. ビルド: `docker_build_docker_image` でアプリイメージをビルド。環境変数（`NEXT_PUBLIC_BASE_PATH` 等）は `build_args` 経由で注入
2. ネットワーク作成: `docker_create_network`
3. app コンテナ常駐起動: `docker_start_container` で `network` を指定し、`command` でランタイム環境変数を付与
   - `command="sh -c 'export NEXTAUTH_SECRET=... NEXTAUTH_URL=... && exec node server.js'"` のようにラッパーで渡す（Dockerfile を編集しない）
4. nginx コンテナ常駐起動: `docker_start_container` で `image_name="nginx:alpine"`、`network` を指定、`ports={"8088":"80"}` でホスト公開
5. 設定注入: `default.conf` をローカルに作成し `docker_docker_cp` で `/etc/nginx/conf.d/default.conf` に注入 → `docker_exec_in_container` で `nginx -t && nginx -s reload`
6. HTTP 応答確認: ホスト側から `curl -i -H "Host: example.com" http://localhost:8088/<path>` を実行し、ステータス・`Location`・`Content-Type`・本文タイトル等を検証
7. クリーンアップ: `docker_stop_container`（両コンテナ） → `docker_remove_network` → 一時ビルドコンテキスト削除

### nginx proxy_pass の注意点
- `proxy_pass http://<app>:3000;`（末尾スラッシュ **なし**）が基本。末尾スラッシュを入れると URI rewrite により Next.js basePath と不一致を起こし 404 になる
- `location = /note { return 301 /note/; }` のようなリダイレクトは Next.js 側で 307→308 を返すため無限ループになりやすい。Next.js basePath に任せる（DEPLOY.md 参照）

### 500 エラーが出る場合の切り分け
- `[next-auth][error][NO_SECRET]` → `NEXTAUTH_SECRET` 未設定。ランタイム環境変数がコンテナに渡っていない
- basePath 周りは 404 で出る。basePath 未焼き込み（build-args 未指定）が原因か `docker_exec_in_container` で `grep -o '"basePath":"[^"]*"' /app/server.js` を実行して実測確認

## リポジトリ固有の E2E 手順

Next.js のビルド・lint・typecheck は genji1024 配下のリポジトリで共通だが、実際の
E2E 動作確認（DBセットアップ・画面遷移）はアプリごとに異なる。各リポジトリの
project-conventions スキルを参照すること（例: private-note は
[`genji1024/private-note/project-conventions`](../private-note/project-conventions/SKILL.md)）。
