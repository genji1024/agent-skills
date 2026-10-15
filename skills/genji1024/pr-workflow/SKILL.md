---
name: pr-workflow
description: genji1024 配下のリポジトリ（private-note, private-opencode-server, koto など）共通のコミットの身元・PR作成・レビュー対応・CI検証ワークフロー。コミットを作る時、Assignee/Reviewer設定、レビューコメント処理、プッシュ前検証を行う際に使う。
---

# PR Workflow

## コミットの身元

誰の指示で作るコミットかで author / committer を変える。

- **対話セッションで本人（genji1024）が指示したコミット**: 本人の身元
  `genji1024 <contact@genji1024.com>` にする。author と committer の両方。
  リポジトリに `git config user.name` / `user.email` を設定して以後も揃える。
  履歴を書き換えて揃えるよう頼まれた場合も両方を直す。
- **自律エンジニアとして作る PR のコミット**: bot の身元にする（詳細は
  [`forgejo-autonomous-engineer`](../forgejo-autonomous-engineer/SKILL.md) の既知の制約）。

コミット後は `git log -1 --format='%an <%ae> | %cn <%ce>'` で両方を確認する。

## コミットメッセージ

コミットする前に、毎回 [`commit-message`](../../commit-message/SKILL.md)
スキルを読み込み、その手順（履歴の確認、形式、長さのチェック、ユーザーの了承）に
従う。作業の途中のコミットも、amend も、スカッシュマージ用のメッセージも同じ。

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
   - 検証内容: [`commit-message`](../../commit-message/SKILL.md) の形式（見出し50文字以内、本文は箇条書きの階層、すべての行72文字以下、リポジトリの規約に準拠）。同スキルの awk のチェックを実行する
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
