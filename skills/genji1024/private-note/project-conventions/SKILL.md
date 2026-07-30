---
name: project-conventions
description: private-note（旧称 chihiro-note）リポジトリの技術スタック・設計方針・E2E確認手順。private-note固有の実装作業時に使う。PR規約・スキル管理は genji1024/pr-workflow と writing-skills を参照。
---

# Project Conventions

## 技術スタック

- Next.js 14 (App Router) + TypeScript
- Supabase (PostgreSQL) — DB + Storage
- NextAuth.js (Credentials Provider) — 認証
- ESLint + Prettier — Lint・Format

## 設計方針

- 2ユーザ（genji + chihiro）専用の交換日記Webサービス
- ユーザ名+パスワード認証
- 日記CRUD（1日複数投稿可）+ 画像添付
- スレッド機能（ユーザが追加・削除可能、日記はデフォルト削除不可）
- 既読機能（相手が読んだか分かる）
- ミニマルデザイン、モバイルレスポンシブ、日本語のみ

## tsconfig

- `@/*` パスは `./src/*` に設定（src/ ディレクトリ使用時）
- `target: es5` は既存設定（変更注意）

PR規約・スキル管理は private-note 固有ではないため、
[`genji1024/pr-workflow`](../../pr-workflow/SKILL.md) と
[`writing-skills`](../../../writing-skills/SKILL.md) を参照。

## 動作確認（E2E）

1. Supabase SQL を全て実行（`supabase-setup` スキル参照）
2. `.env.local` を設定
3. `npm run dev` で開発サーバー起動（ビルド・lint・typecheckは
   [`genji1024/build-and-verify`](../../build-and-verify/SKILL.md) を参照）
4. http://localhost:3000 にアクセス
5. ログイン → 日記投稿 → スレッド投稿 → 画像アップロード → 既読 → ログアウト

### E2E テスト（curl使用時）

- `curl --http1.1` を使用（HTTP/2 でエラーになるため）
- CSRF トークン取得 → credentials ログイン → セッションクッキー使用

## ユーザ情報

- genji / genji（パスワード = ユーザ名）
- chihiro / chihiro（パスワード = ユーザ名）
- パスワードは初回ログイン後変更可能（`update_password()` 関数）

## Supabase プロジェクト

- URL: `https://gnoqaaapfdfrmmnwrwzg.supabase.co`
- Storage バケット: `images`（public）
