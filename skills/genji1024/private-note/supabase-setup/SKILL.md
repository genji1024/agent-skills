---
name: supabase-setup
description: genji1024/private-note リポジトリの Supabase データベース・Storage セットアップ手順（実行順序、初期ユーザ、RLS）。private-note の環境構築・DBセットアップ作業時に使う。
---

# Supabase Setup

## データベースセットアップ手順

Supabase ダッシュボードの SQL Editor で以下の順番で実行する。

### 実行順序

1. `supabase/schema.sql` — 基本テーブル（users, entries, read_status）+ RLS
2. `supabase/functions.sql` — 認証・既読関数（verify_user, mark_read）
3. `supabase/threads_schema.sql` — スレッドテーブル（threads, thread_comments）+ RLS
4. `supabase/threads_functions.sql` — スレッド関数（get_threads, get_thread_comments）
5. `supabase/account_migration.sql` — profile_image_url 列追加、update_password 関数、ユーザデータ移行
6. `supabase/storage_setup.sql` — Storage images バケット作成 + RLS ポリシー

### 初期ユーザ

- `account_migration.sql` によって `genji` と `chihiro` ユーザが作成される
- パスワードは各ユーザ名と同じ（初回ログイン後変更可能）
- パスワードは `update_password()` 関数で変更可能

### RLS ポリシー

- 全テーブルで Row Level Security を有効化
- 認証済みユーザのみ read/write 可能
- サーバー側 API では `supabaseAdmin`（service_role key）を使用して RLS をバイパス

## Storage セットアップ

- `images` バケット（public）を作成
- アップロード可能ファイル: JPEG, PNG, GIF, WebP
- 最大サイズ: 5MB
- 保存パス: `{userId}/{timestamp}-{random}.{ext}`

## 環境変数

```
NEXT_PUBLIC_SUPABASE_URL=<SupabaseプロジェクトURL>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon key>
SUPABASE_SERVICE_ROLE_KEY=<service role key>
```

## 注意点

- `psql` がインストールされていない場合は Dashboard の SQL Editor を使用
- Supabase Auth Redirects の設定は不要（NextAuth Credentials Provider を使用のため）
- テーブル削除は `migration_simplify.sql` のコメントアウトを参照
