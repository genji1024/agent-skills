---
name: sql-idempotency
description: genji1024/private-note リポジトリの SQL 冪等性パターン（同じDBへの再実行を安全にするマイグレーション対策）。private-note の Supabase SQL を書く際に使う。
---

# SQL Idempotency Rules

## 背景

g-ohara は複数PR検証で同じDBにSQLを再実行する。すべての SQL は冪等に実行できるよう設計すること。

## パターン一覧

| パターン                                        | 修正                                                                  |
| ----------------------------------------------- | --------------------------------------------------------------------- |
| `CREATE INDEX idx ON t (...)`                   | → `CREATE INDEX IF NOT EXISTS idx ON t (...)`                         |
| `CREATE POLICY "p" ON t ...`                    | → `DROP POLICY IF EXISTS "p" ON t; CREATE POLICY "p" ON t ...`        |
| 戻り型変更 `CREATE OR REPLACE FUNCTION`         | → `DROP FUNCTION IF EXISTS f(...); CREATE OR REPLACE FUNCTION f(...)` |
| `CREATE TABLE` より後にそれを参照するDOブロック | → CREATE TABLE を先に配置                                             |

## 実装例

### インデックス

```sql
CREATE INDEX IF NOT EXISTS idx_entries_user_id ON entries(user_id);
```

### RLS ポリシー

```sql
DROP POLICY IF EXISTS "Users can read all entries" ON entries;
CREATE POLICY "Users can read all entries" ON entries
  FOR SELECT USING (auth.role() = 'authenticated');
```

### 戻り型変更のある関数

```sql
DROP FUNCTION IF EXISTS verify_user(text, text);
CREATE OR REPLACE FUNCTION verify_user(p_username text, p_password text)
RETURNS TABLE(id uuid, username text, display_name text) AS $$
  ...
$$ LANGUAGE plpgsql;
```

## 注意点

- `DROP FUNCTION IF EXISTS` には引数リストが必要（オーバーロード対策）
- `CREATE OR REPLACE FUNCTION` は戻り型変更に対応していない — 先に DROP が必要
