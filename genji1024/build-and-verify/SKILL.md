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

## リポジトリ固有の E2E 手順

Next.js のビルド・lint・typecheck は genji1024 配下のリポジトリで共通だが、実際の
E2E 動作確認（DBセットアップ・画面遷移）はアプリごとに異なる。各リポジトリの
project-conventions スキルを参照すること（例: private-note は
[`genji1024/private-note/project-conventions`](../private-note/project-conventions/SKILL.md)）。
