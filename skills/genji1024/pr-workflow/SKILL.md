---
name: pr-workflow
description: genji1024 配下のリポジトリ（private-note, private-opencode-server など）共通のPR作成・レビュー対応・CI検証ワークフロー。Assignee/Reviewer設定、レビューコメント処理、プッシュ前検証を行う際に使う。
---

# PR Workflow

## PR 作成ルール

1. Assignee: bot-genji1024 を設定
2. Reviewer: g-ohara を設定
3. ラベル: 機能追加は `enhancement`、ドキュメントは `documentation`
4. コンフリクトがないことを確認
5. Body に `Closes #N` を記載してイシューを自動クローズ
6. PR コメントに @g-ohara をメンションしてレビュー依頼

## レビュー依頼時のコメントフォーマット

レビュー依頼コメントには必ず以下を含める:

- lint 結果（`npm run lint`）
- format:check 結果（`npm run format:check`）
- typecheck 結果（`npm run typecheck`）
- build 結果（`npm run build`）
- Docker 動作確認結果（対象プロジェクトに Dockerfile がある場合）

## レビューコメントの処理

### コメント取得（重要）

`issue_read(method="get_comments")` は通常の議論コメントのみ返す。
インラインコードレビューコメントは `pull_request_read(method="get_review_comments")` で取得する。

**両方を毎回チェックすること** — 片方だけではレビュー指摘を見逃す。

### 修正後のフロー

1. 指摘事項を分析し修正
2. 該当ブランチでファイルを更新
3. `update_pull_request(pullNumber=N, reviewers=["g-ohara"])` で再レビュー依頼
   - コメントだけではレビュー依頼にならない — `update_pull_request` での再リクエストが必須

## ローカル検証（プッシュ前に必ず実行）

コード変更後、プッシュ前に以下の5ステップを**すべて**ローカルで実行すること:

```bash
npm run lint --max-warnings 0
npm run format:check
npm run typecheck
npm run build
```

ビルドが通るだけでは不十分。lint・フォーマット・型チェックのすべてが通って初めて「動作確認完了」と見なす。

5. コミットメッセージ検証: プッシュ前に、対象コミットのメッセージを `git log -1 --format=%B`（または該当コミットのメッセージ）で確認する
   - 検証内容: すべての行が72文字以下、見出し（1行目）は約50文字以内、リポジトリの規約（Conventional Commits / Gitmoji）に準拠していること
   - 違反があれば `git commit --amend` でメッセージを修正してからプッシュする
   - コード変更を伴わないコミット（メッセージ修正のみのコミット）にも適用する

対象プロジェクトに Dockerfile がある場合（private-note / private-opencode-server ともにある）は、
**Docker 動作確認も必須**: Docker MCP サーバー（mcp-docker）で イメージビルド → コンテナ起動 → HTTP 応答確認
までを実施し、結果をレビュー依頼コメントに含めること。

## CI チェック

巡回時は必ず `pull_request_read(method="get_check_runs")` で全PRのCI状態を確認する。
CI失敗はレビュー指摘と同じ重み — 見逃さないこと。

## アーキテクチャ変更後の注意点

アーキテクチャ変更（コンポーネントの統合・置き換え）後は、
変更が**実際に使われているコンポーネント**に適用されているか確認すること。
死コード（古いコンポーネント）にのみ変更を加えても画面上で動作しない。
