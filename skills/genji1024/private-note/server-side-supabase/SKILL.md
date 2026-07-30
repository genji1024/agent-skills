---
name: server-side-supabase
description: genji1024/private-note リポジトリのサーバー側 Supabase 使用パターン（supabaseAdmin による RLS バイパス）。private-note の API ルート実装時に使う。
---

# Server-Side Supabase Usage

## supabaseAdmin の使用

サーバー側 API ルートでは `supabaseAdmin`（service_role key）を使用すること。

### 理由

- `supabase`（anon key）は RLS によって書き込みがブロックされる
- サーバー側では認証済みユーザの操作を保証できるため、RLS をバイパスする
- `supabaseAdmin` は service_role key を使用し、RLS をバイパス可能

### 使用箇所

- 全 API ルート（`/api/entries`, `/api/threads`, `/api/upload`, `/api/read`, `/api/profile`）
- サーバーコンポーネントでのデータ取得（`page.tsx`）

### 実装

```typescript
import { supabaseAdmin } from "@/lib/supabase";

const { data, error } = await supabaseAdmin
  .from("entries")
  .insert({ ... });
```

### 注意点

- `supabaseAdmin` はサーバー側でのみ使用（クライアント側では絶対に使用しない）
- `service_role` key は環境変数 `SUPABASE_SERVICE_ROLE_KEY` から取得
- クライアント側では `supabase`（anon key）を使用
