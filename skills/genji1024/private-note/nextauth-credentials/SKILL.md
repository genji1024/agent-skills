---
name: nextauth-credentials
description: genji1024/private-note リポジトリの NextAuth Credentials Provider 実装パターン。ユーザ名+パスワード認証（genji/chihiro の2ユーザ固定）を扱う際に使う。
---

# NextAuth Credentials Provider

## 実装パターン

private-note では NextAuth.js の Credentials Provider を使用して、ユーザ名+パスワード認証を行う。

### 構成ファイル

- `src/lib/auth.ts` — NextAuth 設定（Credentials Provider, コールバック）
- `src/app/api/auth/[...nextauth]/route.ts` — NextAuth ルートハンドラー
- `src/app/login/page.tsx` — サーバーコンポーネント、ユーザ一覧を取得して LoginForm に渡す
- `src/components/LoginForm.tsx` — クライアントコンポーネント、ユーザ名プルダウン

### 認証フロー

1. ログインページでユーザ名を選択（プルダウン表示のみユーザ名）
2. パスワード入力
3. `signIn("credentials", { username, password })` で認証
4. Credentials Provider の `authorize` で `verify_user` RPC を呼ぶ
5. 認証成功 → JWT トークンに `id`, `username`, `display_name` をセット
6. セッションのコールバックで `session.user` にカスタムフィールドを渡す

### 注意点

- Supabase Auth Redirects の設定は不要（Credentials Provider のため）
- `session.user` のカスタムフィールドには `(session.user as any).id` でアクセス
- `src/lib/session.ts` に type-safe helpers を用意済み
- ログアウトは `signOut()` を使用（`LogoutButton.tsx` または `UserMenu.tsx`）

### ログインページ

- サーバーコンポーネントで Supabase からユーザ一覧を取得
- クライアントコンポーネント（LoginForm）に props で渡す
- プルダウンは表示名ではなくユーザ名のみ表示（g-ohara の指摘により修正）
