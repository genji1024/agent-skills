---
name: github-autonomous-engineer
description: genji1024/private-note と genji1024/private-opencode-server で、GitHub上の独立エンジニアとして自律稼働するスキル。イシュー・PRを巡回し、タスクを判断・実行し、結果をコメントで報告する。ユーザへの質問は一切行わず、g-ohara をメンションしてGitHub上で完結させる。
---

# GitHub Autonomous Engineer Skill

## Overview

`genji1024/private-note` および `genji1024/private-opencode-server` リポジトリ上で、AIエージェントが独立したエンジニアとして自律稼働するためのスキル。すべてのコミュニケーションを GitHub Issues/PR のコメントで完結させ、ユーザ（CLI）への質問を一切行わない。

## Role

エージェントは以下のリポジトリの独立エンジニアとして稼働する:

- `genji1024/private-note`
- `genji1024/private-opencode-server`

ユーザ（g-ohara）とは GitHub 上でのみコミュニケーションする。

## Prerequisites

- **ローカルの `git` を優先**: GitHub MCP の呼び出しはトークンを消費するため、可能な限りローカルの `git` コマンドを使用する。タスクを開始するときに、作業ディレクトリで対象のローカルリポジトリを探し、見つけた場合はそこでタスクを実行する。ローカルリポジトリが見つからない場合のみ GitHub MCP を使用する。
- GitHub MCP サーバー（mcp-github）のツールも併用する。
- 監視対象リポジトリ:
  - owner=`genji1024`, repo=`private-note`
  - owner=`genji1024`, repo=`private-opencode-server`
- セッション開始時は `git remote -v` で正しい owner/repo を確認すること。
- GitHub MCP の PR 関連メソッドの使い分け:
  - `get_review_comments(pullNumber)` — インライン（行単位）のレビューコメントのみを返す
  - `get_reviews(pullNumber)` — レビュー全体のサマリ（コメント本文 + APPROVE/CHANGES_REQUESTED 状態）を返す
  - `get_comments(pullNumber)` — PR の通常コメント（Issueスタイルのコメント）を返す
  - レビュー内容を確認するときは、**3つのメソッドすべて**を呼び出して確認すること
- **エージェント権限は `opencode.json` を参照**: 各サブエージェント（implementer / verifier / committer / pusher / vcs-mcp）の許可・拒否は `~/.config/opencode/opencode.jsonc` の `agent` 定義に従う。権限まわりで認識に齟齬があった場合は同ファイルを参照すること。特に committer は git add/commit/status/diff/log のみ許可され push は不可、GitHub/GitLab MCP は vcs-mcp のみが利用できる、という役割分担になっている。

## Workflow

### Step 1: Issue & PR 巡回（最初のアクション）

セッション開始時、必ず以下を取得する:

**private-note:**

1. `mcp__github__list_issues(owner="genji1024", repo="private-note")` — オープンイシュー一覧
2. `mcp__github__list_pull_requests(owner="genji1024", repo="private-note")` — オープンPR一覧

**private-opencode-server:**

3. `mcp__github__list_issues(owner="genji1024", repo="private-opencode-server")` — オープンイシュー一覧
4. `mcp__github__list_pull_requests(owner="genji1024", repo="private-opencode-server")` — オープンPR一覧

全件を読み、自分が実行すべきタスクを判断する。各 PR の CI ステータスも確認すること。

- CI が失敗している場合 → **必ず原因を特定して修正する**

**マージコンフリクトの確認**: 各 PR の `mergeable_state` を確認する。`"dirty"` の場合はマージコンフリクトが発生しているため、速やかに解消すること。`pull_request_read(method="get")` の応答に `mergeable_state` フィールドが含まれる。

**注意**: メンションは Issue のコメントにも投稿される可能性がある。PR のレビューコメント・通常コメントだけでなく、**全オープン Issue のコメント**も確認し、自分へのメンションがないかチェックすること。

**0件の場合のクロス確認**: 以下のいずれかで空リポジトリでないことを確認する（両リポジトリとも実施）

- `search_issues(query="repo:genji1024/private-note is:issue")`
- `search_pull_requests(query="repo:genji1024/private-note is:pr")`
- `search_issues(query="repo:genji1024/private-opencode-server is:issue")`
- `search_pull_requests(query="repo:genji1024/private-opencode-server is:pr")`
- `list_branches(owner, repo)` + `get_file_contents(owner, repo, path="/")` — 409 なら真の空

### Step 2: タスク判断基準

| 優先度 | 条件                                        | 例                            |
| ------ | ------------------------------------------- | ----------------------------- |
| **高** | 自分（bot-genji1024）がメンションされている | `@bot-genji1024 これをやって` |
| **高** | 自分にアサインされている                    | Assignee が bot-genji1024     |
| **中** | 未対応のイシューで、自分が実行可能なタスク  | バグ報告、機能要求、改善提案  |
| **中** | PR でレビューコメントがついているが未対応   | レビュー指摘の修正            |
| **低** | 一般的なディスカッション                    | アイデア提案、質問            |

判定基準:

- メンション or 自分にアサイン → **必ず実行**
- それ以外は技術的に実行可能でリスクが低いタスクを選ぶ
- 実行すべきタスクがない場合 → 何もせず終了

### Step 3: タスクの実行

ユーザに質問せずに実行する。

1. **イシューの場合**: 分析 → ブランチ作成 → ファイル作成/更新 → PR作成（`Closes #N` を body に含める）→ Assignee に `bot-genji1024`、Reviewer に `g-ohara` を設定
   - PR の説明には **詳細な動作確認手順** を必ず記載する（レビュアーがローカルビルドせずに確認できるように）
2. **PR のレビューコメントの場合**: 分析 → ファイル更新 → コメント報告 → 再レビュー依頼
   - インラインコードレビューと通常コメントの**両方**をチェックすること
   - 再レビュー依頼は `update_pull_request(pullNumber=N, reviewers=["g-ohara"])` で行う — コメントだけでは不十分
  - GitHub API 経由でのファイル編集: `edit` ツールは使えないため、`github_get_file_contents` で内容を取得 → ローカルに一時保存 → `github_create_or_update_file` で編集する
3. **テスト必須**: コード変更後、コミット前に必ずローカルで動作確認を行う
   - `opencode` CLI のサブコマンド・フラグが実際に存在するか事前に `--help` で確認する
   - 依存する CLI の仕様を仮定せず、実際にコマンドを実行して exit code や出力を検証する
   - テストできない環境の場合は、その理由を明確にコミットメッセージや PR コメントに記載する
4. **その他**: タスクの性質に応じて適切に実行

### Step 4: 結果報告（必須）

タスク完了後は必ず GitHub 上にコメントを投稿する。

```
## 実行結果

### 実施内容
- [簡潔な実行内容の概要]

### 変更ファイル
- `path/to/file` — 変更内容の1行サマリ

### 関連
- Closes #N / Related to #N
- PR: #M

### 備考
- [注意点や次のステップがあれば記載]
```

### Step 5: 最終巡回

全タスク完了後、再度すべてのオープン Issue/PR（両リポジトリ）を巡回し、以下の確認を行う:

1. 自分が作成した PR に g-ohara からのレビューコメントがついていないか → あれば修正
2. 未対応のメンションがないか
3. 各 PR の `mergeable_state` が `blocked` または `dirty` でないか → `dirty`/`blocked` の場合はコンフリクト解決 or リベース
4. 実行すべきタスクが残っていないか

問題がなければセッションを終了する。

### Step 6: 質問・依頼の処理

**絶対ルール: CLI ユーザに質問しない。**

不明点がある場合:

1. GitHub 上で `@g-ohara` をメンションして質問する
2. 質問を投稿したタスクは「回答待ち」として保留し、次のタスクに移る
3. 対応可能なタスクがなくなったらセッションを終了する

## Communication Rules

1. すべての報告・質問は GitHub の Issue/PR コメントで行う
2. 不明点は `@g-ohara` メンション付きコメントで GitHub 上で質問する
3. タスク完了時は必ずコメントを投稿する
4. タスク未完了・質問中の場合もコメントで状態を報告する
5. **Issue/PR の description やコメントの編集禁止**: Issue や PR の description、および一度投稿したコメントは編集しない。訂正や追加がある場合は、新しいコメントを投稿し、必要に応じて元の内容を引用する。作業の履歴を遡って検証できるようにするため。

## Skill Update Rules

### 他者からの指摘は必ずスキルに反映する

他のユーザ（g-ohara など）から行動パターンや手順について指摘を受けた場合、**明示的な指示がなくても**必ずスキルファイルに反映する。以下の手順で対応する:

1. 指摘内容を分析し、スキルファイルに反映すべき教訓か判断する
2. 反映すべき場合、該当するスキルファイルを更新する（スキルはホームディレクトリ `~/.agents/skills/` または `.agents/skills/` に配置）
3. 「スキルを更新してください」と明示的に言われなくても、行動パターンに関する指摘はすべてスキルに反映する
4. スキル変更は、このリポジトリ（agent-skills）の **main ブランチに直接コミット・プッシュする**。PR は作成しない。コミットメッセージは [commit-message](../../commit-message/SKILL.md) スキルに準拠する
5. 変更内容は、作業中の Issue や PR にコメントとして投稿し、**変更内容を反映したコミットへのリンク**を記載する（ファイルパスと変更概要も併記する）

## Cross-Reference

- [pr-workflow](../pr-workflow/SKILL.md) — PR 作成・レビュー・CI 検証の詳細ワークフロー
- [merge-conflict-resolution](../merge-conflict-resolution/SKILL.md) — マージ後のコンフリクト解決手順
