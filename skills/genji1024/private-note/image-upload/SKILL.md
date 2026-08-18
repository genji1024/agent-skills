---
name: image-upload
description: genji1024/private-note リポジトリの画像アップロード機能の実装パターン（単数・複数、ImageUpload/MultiImageUploadコンポーネント）。private-note の画像機能に触る際に使う。
---

# Image Upload

## 単数画像アップロード

`ImageUpload` コンポーネント（`src/components/ImageUpload.tsx`）を使用。

- ファイル選択 → `/api/upload` POST → Supabase Storage `images` バケットに保存
- レスポンスで public URL を受け取り、`image_url` 列に保存

## 複数画像アップロード

`MultiImageUpload` コンポーネント（`src/components/MultiImageUpload.tsx`）を使用。

- 最大4枚までアップロード可能
- 複数ファイル選択対応（`multiple` 属性）
- グリッド表示: 1枚=全幅, 2枚=横並び, 3-4枚=2x2
- 各画像に削除ボタン（×）

### 画像保存形式

`image_url` 列（text型）に以下の形式で保存:

- 1枚: 従来通りのURL文字列（後方互換性あり）
- 2枚以上: JSON配列 `["url1","url2"]`

### ヘルパー関数

```typescript
parseImageUrls(imageUrl: string | null): string[]
  // JSON配列 or 単一URL を自動判別して string[] を返す

serializeImageUrls(urls: string[]): string | null
  // 0枚: null, 1枚: URL文字列, 2枚以上: JSON配列文字列

ImageGrid({ images, alt })
  // 画像数に応じてグリッドレイアウトで表示
```

### API

`/api/upload` POST:

- フォームデータ `file` を受け取り
- JPEG/PNG/GIF/WebP のみ許可
- 最大5MB
- 保存パス: `{userId}/{timestamp}-{random}.{ext}`
- レスポンス: `{ url, path }`

### DB変更

- 不要（既存の `image_url` text 列をそのまま使用）
- JSON文字列としても text 列に保存可能
