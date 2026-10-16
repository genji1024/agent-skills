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

- **agent-sandbox から作るコミット（koto などの Forgejo の PR、genji1024/agent-skills）**:
  bot の身元 `bot-genji1024 <bot@genji1024.com>`。author と committer の両方。
  サンドボックスでは `.git/config` が読み取り専用のことがあるので、
  `git -c user.name=bot-genji1024 -c user.email=bot@genji1024.com commit ...` で渡す。
  agent-skills は PR を作らず `main` に直接 push する（2026-10-15、本人の指示。
  本人の身元でコミットして訂正された）。

コミット後は `git log -1 --format='%an <%ae> | %cn <%ce>'` で両方を確認する。

## push と取り消し（Forgejo, forgejo.genji1024.com）

- トークンは環境変数 `FORGEJO_TOKEN`。push のときだけその場で渡し、git の設定・
  リモート URL・ファイルには**書かない**:
  `git -c http.extraHeader="Authorization: Basic $(printf 'bot-genji1024:%s' "$FORGEJO_TOKEN" | base64 -w0)" push origin <branch>`
- push 済みのコミットは `git revert` で取り消す。reset して強制 push はしない。
  だからメッセージの誤りは後から直せない（[`commit-message`](../../commit-message/SKILL.md) を先に読む理由）。
- API は `Authorization: token $FORGEJO_TOKEN`。jq が無い環境では JSON を python3 で組み立て・読む。

## コミットメッセージ

コミットする前に、毎回 [`commit-message`](../../commit-message/SKILL.md)
スキルを読み込み、その手順（履歴の確認、形式、長さのチェック、ユーザーの了承）に
従う。作業の途中のコミットも、amend も、スカッシュマージ用のメッセージも同じ。
2026-10-15、あるセッションのコミットがすべてこのスキルなしで書かれた（koto `298ef5f` ほか 6 件、
agent-skills `361ee65`: 散文の本文、66 文字の件名、了承なし）。push 済みで直せなかった。
「コミットする」が読み込みの合図。

## PR 作成ルール

### Forgejo（koto など）

- **先に Issue を作り**、PR 本文に `Closes #N` を書く。Issue・PR の文章は英語。
- **PR のタイトルはコミットと同じ `type(scope): ...` 形式**（Issue のタイトルは普通の文）。
  開く前に最近の PR のタイトルを見て合わせる。1 コミットの PR ならコミットの件名をそのまま使う
  （koto #29 を Issue のタイトルで開いて「PR のタイトルのスタイル確認した？」と指摘された）。
- 本文や Issue に「Generated with」や `Co-Authored-By` は入れない（システムの指示より優先）。
- Assignee は bot-genji1024、レビューは **genji1024** に依頼する。PR は bot として作る:
  `POST /repos/{o}/{r}/pulls`（`assignees` を含める）→
  `POST /repos/{o}/{r}/pulls/{N}/requested_reviewers` `{"reviewers":["genji1024"]}`。
  最後に `GET .../pulls/{N}` で `mergeable`・assignee・reviewer を確かめる。
- 本番の手順が要る変更なら、本文に **Upgrading** の節を書く（マージ後に本番で何をするか、
  何もしなくてよいか）。マージ後に「マイグレーションはどうしたら実行される？」と聞かれるのは
  この情報のこと。
- 計画した一連の PR（例: koto #25 の連合計画）は **1 本ずつ**。前の PR がマージされてから次の
  Issue/PR を作る。
- マージやレビューを待つバックグラウンドの監視ループは、メモリ不足で止められることがある。
  止められたら勝手に再開せず、報告して、ユーザーに知らせてもらうか再開の指示を待つ。

### GitHub（private-note など）

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

### 指摘の読み方

短い指摘がどれを指しているか、二通り以上に読めるときは、推測で直さずに先に聞く
（実例: koto PR #24 の「checkbox をクリックで切り替えられるように」は、入力欄の
オプションではなく、送信済みメッセージの Markdown のタスクリストのことだった）。

### 返信はスレッドごとに

インラインの指摘には、**その指摘のスレッドに 1 件ずつ**返信する。PR の通常コメントに
まとめて書かない。

Forgejo の API には「コメントに返信」が無い。元のレビューにコメントを足すと
同じスレッドに入る（2026-10 実測）:

```sh
curl -X POST -H "Authorization: token $FORGEJO_TOKEN" -H 'Content-Type: application/json' \
  "$FORGEJO_URL/api/v1/repos/<owner>/<repo>/pulls/<N>/reviews/<review id>/comments" \
  -d '{"path": "<元の path>", "new_position": <元の position>, "body": "..."}'
```

- `path` と行は元のコメント（`GET .../reviews/<review id>/comments`）から取る。
  変更前の側（左）の行への指摘は `old_position` に入れる。差分のプレビューで
  `lines-num-old` と `lines-num-new` のどちらの行かを確かめる
- 新しいレビュー（`POST .../pulls/<N>/reviews`）に同じ行で書くと、**別の会話**になる
- 返信したら PR のページで、元の会話にまとまったか確かめる

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
