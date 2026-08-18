---
name: github-autonomous-engineer
description: autonomous-engineer（基底スキル）のGitHubインスタンス。GitHub上のIssue/PRを自律的に巡回し、タスクを判断・実行し、結果をコメントで報告する。自分のユーザ名・担当リポジトリ・レビュー依頼先はハードコードせず、GitHub MCPで動的に解決する。ユーザへの質問は一切行わず、GitHub上で完結させる。
---

# GitHub Autonomous Engineer Skill

[autonomous-engineer](../autonomous-engineer/SKILL.md) の GitHub インスタンス。共通のワークフロー・判断基準・Skill Update Rulesは基底スキルを参照。ここでは GitHub 固有の Platform Binding とツールの使い分けのみを定義する。

## Platform Binding

| 項目 | GitHub MCP での実現方法 |
| --- | --- |
| 自分のアカウント情報取得 | `get_me` |
| Issue一覧・詳細 | `list_issues` / `issue_read` |
| PR一覧・詳細・差分 | `list_pull_requests` / `pull_request_read` |
| インラインレビューコメント | `get_review_comments(pullNumber)` |
| レビューサマリ（本文+承認状態） | `get_reviews(pullNumber)` |
| PR通常コメント | `get_comments(pullNumber)` |
| 再レビュー依頼 | `update_pull_request(pullNumber=N, reviewers=["<Step0-3で解決した人間>"])` — コメントだけでは不十分 |
| CI/チェック状態 | `pull_request_read(method="get_check_runs")` |
| マージ可否・コンフリクト状態 | `pull_request_read(method="get")` の応答の `mergeable_state`（`"dirty"` はコンフリクト発生） |
| ファイル編集手段（`edit`ツール不可時） | `github_get_file_contents` で取得 → ローカルに一時保存 → `github_create_or_update_file` で更新 |
| 担当リポジトリの列挙 | ローカル `git remote -v` を優先。フルスキャンが必要な場合は自分がコラボレータ/メンバーのリポジトリを検索・一覧系ツールで解決する |

## 既知の制約

- レビュー内容を確認するときは `get_review_comments` / `get_reviews` / `get_comments` の**3つのメソッドすべて**を呼び出すこと（片方だけでは指摘を見逃す）。

## Prerequisites

- **ローカルの `git` を優先**: GitHub MCPの呼び出しはトークンを消費するため、可能な限りローカルの `git` コマンドを使用する。タスクを開始するときに、作業ディレクトリで対象のローカルリポジトリを探し、見つかった場合はそこでタスクを実行する。ローカルリポジトリが見つからない場合のみGitHub MCPを使用する。セッション開始時は `git remote -v` で対象owner/repoを確認すること。
- **0件の場合のクロス確認**: 一覧APIが0件を返した場合、以下のいずれかで空リポジトリでないことを確認する（対象owner/repoごとに実施）
  - `search_issues(query="repo:<owner>/<repo> is:issue")`
  - `search_pull_requests(query="repo:<owner>/<repo> is:pr")`
  - `list_branches(owner, repo)` + `get_file_contents(owner, repo, path="/")` — 409なら真の空
- **エージェント権限は `opencode.jsonc` を参照**: 各サブエージェント（coder / verifier / committer / pusher / pr-manager）の許可・拒否は `~/.config/opencode/opencode.jsonc` 配下の `agents/*.md` の `permission` に従う。権限まわりで認識に齟齬があった場合は同ファイルを参照すること。committer は git add/commit/status/diff/log のみ許可されpush不可、GitHub/GitLab/Forgejo MCPはissue-reader（Planner配下、コンテキスト収集を担当）とpr-manager（Integrator配下、Issue/PR操作を担当）のみが利用できる、という役割分担になっている。

## Cross-Reference

- [autonomous-engineer](../autonomous-engineer/SKILL.md) — 共通のワークフロー・判断基準・Skill Update Rules（本体）
- [pr-workflow](../pr-workflow/SKILL.md) — PR作成・レビュー対応・CI検証の詳細ワークフロー
- [merge-conflict-resolution](../merge-conflict-resolution/SKILL.md) — マージ後のコンフリクト解決手順
- [build-and-verify](../build-and-verify/SKILL.md) — lint/typecheck/build/Docker動作確認の手順
