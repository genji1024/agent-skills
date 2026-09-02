---
name: forgejo-autonomous-engineer
description: autonomous-engineer（基底スキル）のForgejoインスタンス。self-hosted ForgejoインスタンスのIssue/PRを自律的に巡回し、タスクを判断・実行し、結果をコメントで報告する。自分のユーザ名・担当リポジトリ・レビュー依頼先はハードコードせず、forgejo-mcpで動的に解決する。ユーザへの質問は一切行わず、Forgejo上で完結させる。
---

# Forgejo Autonomous Engineer Skill

[autonomous-engineer](../autonomous-engineer/SKILL.md) の Forgejo インスタンス。共通のワークフロー・判断基準・Skill Update Rulesは基底スキルを参照。ここでは Forgejo 固有の Platform Binding とツールの使い分け・既知の制約のみを定義する。

対象MCPサーバーは `forgejo-mcp`（self-hosted Forgejo/Gitea互換API向け）。ツール名・プレフィックス（`forgejo_` 付きか否か）は実装により異なるため、**セッション開始時に実行時判定する**（下記「セッション開始時の MCP サーバー判定」参照）。本スキルで `get_my_user_info` のように記載するツール名はプレフィックスなしの基底名であり、判定したプレフィックスを付けて呼び出す。

## セッション開始時の MCP サーバー判定（Step 0-1 対応、最初のアクション）

対象MCPサーバーは `agentic-forges/forgejo-mcp` への移行が進行中です（genji1024/dotfiles#4 で実装・PR 作成済み）。これはプロジェクトの状況であって MCP の仕様ではないため、移行が完了するまで記録として残す。ただし稼働中の MCP サーバーの実装・ツール名・プレフィックス・環境変数は**外的要因で変更されうるため本スキルにハードコードしない**。セッション開始時の最初のアクションとして、必ず以下の手順で実行時に判定する。

1. **プレフィックスを判定する**: 自分のアカウント情報取得ツールをプレフィックス有無の両方で試す
   - `get_my_user_info`（プレフィックスなし）
   - `forgejo_get_my_user_info`（`forgejo_` プレフィックス付き）
   - 成功した方で稼働中の MCP のプレフィックスを確定し、以降のセッションではそのプレフィックスを統一して使う。
2. **両方失敗した場合**: 利用可能なツール一覧（MCP の `tools/list` 等）を取得し、実際に提供されているツール名を確認する。一覧を基準にプレフィックスと実ツール名を確定する。
3. **以降のツール呼び出しは確定したプレフィックスを使う**: 本スキルの Platform Binding・既知の制約に記載したツール名はプレフィックスなしの基底名として読み、確定したプレフィックスを付けて呼び出す。

### 認証・環境変数（実行時に実測した注意点）

- 認証は Forgejo の通常 PAT（40 文字 hex、ドットなし）を使用する。JWT は不要。認証に使う環境変数名・`FORGEJO_URL` の値は実装により異なるため、**本スキルにハードコードせず、dotfiles リポジトリ（`dotfiles/.dockerscripts/` 等）や `~/.config/opencode/opencode.jsonc` の設定を実行時に確認する**。
- **Authorization ヘッダに注意（実測）**: forgejo MCP の `/mcp` への Authorization ヘッダ値（`Bearer` / `token ` の後続）を Forgejo API トークンとして解釈する実装の場合、`opencode.jsonc` で `Authorization: Bearer ${STREAMABLE_HTTP_AUTH_TOKEN}` のような共有プレースホルダ値を forgejo MCP へ送信すると、Forgejo サーバーで `token is malformed: token contains an invalid number of segments` / `access token does not exist` / `authorized integration: parse JWT error` / `task with token ...: resource does not exist` が発生する（dotfiles#4 で実測）。認証はサーバー側のトークン用 env で完結させ、forgejo MCP に Authorization ヘッダを送らない。`STREAMABLE_HTTP_AUTH_TOKEN` は gitlab-mcp 等の別 MCP 用。
- Actions 系ツール（`list_workflow_runs` 等）は bot トークン（read:admin 無し）で CI 結果を取得できる実装がある（実測）。利用可否・ツール名は実行時に確認する。

## Platform Binding
下記のツール名はプレフィックスなしの基底名。実際の呼び出し時は「セッション開始時の MCP サーバー判定」で確定したプレフィックス（`forgejo_` 付きか否か）を付ける。ツールの存在・引数は実行時に確認し、齟齬があれば基底スキルの [Skill Update Rules](../autonomous-engineer/SKILL.md) に従って更新する。

| 項目 | forgejo-mcp での実現方法 |
| --- | --- |
| 自分のアカウント情報取得 | `get_my_user_info` |
| Issue一覧・詳細 | `list_repo_issues`（`type=issues` で PR を除外）/ `get_issue_by_index`（owner/repo/index 必須） |
| Issueコメント一覧・投稿 | `list_issue_comments` / `create_issue_comment` |
| PR一覧・詳細・差分 | `list_repo_pull_requests`（空リポジトリでは 404 `The target couldn't be found`）/ `get_pull_request` / `get_pull_request_diff` |
| PRコミット・変更ファイル一覧 | `list_pr_commits` / `list_pull_request_files` |
| PRレビュー | `list_pull_reviews` / `create_pull_review`（`create_pull_review` の `state` に `APPROVED`/`REQUEST_CHANGES`/`COMMENT` を渡すことでレビューを投稿・承認できる） |
| 再レビュー依頼 | `create_review_requests`（`request_pr_review` は存在しない。この実ツールでオーナーへの再依頼が成功する。ただし PR 投稿者自身はレビューアに指定不可） |
| PR更新（本文/ブランチ更新等） | `update_pull_request`（assignee/ラベル更新に使用）/ `update_pr_branch` |
| ファイル編集手段（`edit`ツール不可時） | `get_file_contents` で取得 → ローカルに一時保存 → `update_file` で更新 |
| 担当リポジトリの列挙 | ローカル `git remote -v` を優先。フルスキャンが必要な場合は `list_user_repos`（自分が所有/コラボレータのリポジトリ）または `list_org_repos`（組織配下）で解決する |
| レビュー依頼先候補の列挙 | `list_collaborators` は存在しない。`requested_reviewers`・オーナー情報・会話コンテキストから解決する |

## 既知の制約（2026-08 実測で確認済み）

`forgejo-mcp` はコミュニティ製で、GitHub MCPほど機能が枯れていない。以下は実行時に実測して確認した挙動。ツール名はプレフィックスなしの基底名で記す（プレフィックスは「セッション開始時の MCP サーバー判定」に従う）。齟齬に気づいたら基底スキルの [Skill Update Rules](../autonomous-engineer/SKILL.md) に従ってこのセクションを更新する。

- **インラインコメントは `list_pull_review_comments` で取得できる（2026-08 実測）**: 以前は「専用ツールは存在しない」と記載していたが、`list_pull_review_comments` は実在する。ただし `list_pull_reviews` はレビュー単位に `comments_count` を返すのみで、インラインコメント本文は含まない。PR は Forgejo/Gitea 内部では issue として扱われるため、通常コメントは `list_issue_comments`、レビューは `list_pull_reviews`、インラインコメントは `list_pull_review_comments` を**組み合わせて**確認し、レビュー指摘を見逃さないこと。**レビュー指摘はインラインコメント（`list_pull_review_comments` / REST API `/reviews/{id}/comments`）だけでなく、レビュー本文（`list_pull_reviews` の `body` フィールド）にも書かれる場合がある**（実発生: レビュー id 45 の指摘はインラインコメントでなくレビュー本文にあった）。インラインコメントのみに注目すると指摘を見逃す。`list_pull_reviews` で取得した各レビューの `body` を必ず確認すること。
- **レビュー承認時はコメントだけでなく必ず Approve を投稿する（2026-08-25 レビュー指摘）**: レビュー依頼を受けた PR を確認し「問題なし」と通常コメント（`create_issue_comment`）するだけでは足りず、`create_pull_review` で `state="APPROVED"` のレビューを明示的に投稿する必要がある（forgejo-server#4 で「レビュアーは承認時に必ず Approve してください。Approval がないとマージできない場合がある」と指摘された）。Approval はプロジェクトのマージ可否条件（branch protection 等）に関わるため、レビュー承認時は必ず `create_pull_review(state="APPROVED")` を呼ぶ。通常コメントだけでは承認とみなされない。
- **CI 状態は `list_workflow_runs` で取得できる（2026-08 実測）**: 以前は「CI/チェック状態を取得するツールは存在しない」と記載していたが、`list_workflow_runs` は実在し、run 一覧と pass/fail を取得できる。ただしジョブ詳細・ログは 404（resource does not exist）になり、run の表示番号は `run_id` と異なる。CI 失敗の原因究明はローカルの lint/format/typecheck/build/test + Docker 検証による**ローカル再現で代替**し、その旨を PR コメントに明記すること（隠蔽しない）。MCP のジョブ詳細・ログ取得系ツールは 404 になるが、**Forgejo の REST API を直接（`curl` + トークン）呼ぶことで run ログを取得できる**（private-opencode-server#4 で実測し、CI 失敗の原因特定に使用した）。MCP 経由で 404 でも「CI 結果を確認できない」と断定せず、REST API 直叩きを試すこと。ランナー・Secrets 系 API は `read:admin` スコープ必須で bot トークンでは 403。
- **`mergeable_state` / `has_conflicts` は存在しない**: `get_pull_request` が返すのは `mergeable`(bool) のみ。コンフリクト確認はローカルで `git merge --no-commit --no-ff` 相当の確認で代替する。
- **`list_user_repos` は `username` 引数が必須**: 引数なしだとバリデーションエラーになる。
- **`list_org_repos` は org が実在しないと 404**: 個人ユーザ（組織でない）名を渡すと 404 (GetOrgByName) になる。組織かどうかは `list_my_orgs` で判定できる。
- **PR作成時の `reviewers` 引数は非コラボレータ（オーナー含む）を黙殺する**: オーナーをレビュアーにするには `create_pull_request` の reviewers では効かず、`create_review_requests`（`request_pr_review` は存在しない）を別途呼ぶと成功する。
- **`create_review_requests` は PR 投稿者（poster）をレビューアに指定できない（2026-08-23 実測）**: オーナーが PR の投稿者である場合、`create_review_requests` でオーナーを reviewer に指定すると `MCP error -32603: create review requests err: poster of pr can't be reviewer [user_id: 2, repo_id: 8]` で失敗する（決定論的なサーバー側バリデーション拒否）。PR 投稿者への再レビュー依頼は API では不可能。この場合は通常コメント（`create_issue_comment`）で「ご確認お願いします」と伝える（コメント投稿で依頼は伝達される）。Platform Binding「再レビュー依頼」の「オーナーへの再依頼が成功する」は、オーナーが PR 投稿者でない場合に限る。
- **ラベルはリポジトリに存在しない場合がある**: `enhancement` 等を付与する前に `create_repo_label` でラベルを新規作成してから `add_issue_labels` で PR に付与する。`add_issue_labels` はラベル**名前（文字列）ではなく数値ID** を渡す必要がある（ラベル名を渡すと `invalid label ID 'enhancement' … labels must be numeric IDs` エラーになる。2026-08-26 実測）。ラベルの数値ID は `list_repo_labels` で取得できる。
- **`list_repo_issues` は PR と Issue を同一ストリームで返す**: `type=issues` を指定しないとオープン一覧に PR が混在するため、Issue 巡回時は PR を除外するフィルタが必要。PR 番号と Issue 番号が衝突しうるので、コメント取得時にどちらを指すか注意。
- **`list_collaborators` は存在しない**: コラボレータ列挙ツールは提供されていない。レビュー依頼先の列挙は `requested_reviewers` やオーナー情報・会話コンテキストを併用する。
- **権限レベルは API で報告されない**: コラボレータ列挙ツールが無いため、permission フィールドによる権限判定はできない（`list_collaborators` のレスポンスに permission フィールドが無い、という旧記載はツール非存在により該当しない）。
- **`list_pull_reviews` に `REQUEST_REVIEW` 状態のレコードが混在する**: 再レビュー依頼イベントもレビューとして返る。レビュー判定時は `state` を必ず確認する（`REQUEST_REVIEW` は人間のレビューではない）。
- **force-push 後もレビューの `stale` フラグは自動更新されない**: head コミットが変わっても `stale:false` のまま残る。「stale:false」を「現 head 対象の有効な指摘」と安易に解釈しない。
- **ランナー・Secrets 系ツールは存在するが bot トークンでは 403**: `list_action_runners_jobs` / `get_runner_registration_token` は「unavailable tool」ではなく admin スコープ不足（`required scope: read:admin`）で 403。CI 状態は上記の通り `list_workflow_runs` で取得できるが、ジョブ詳細・ログ・ランナー・Secrets は bot では不可視（上記「CI 状態は `list_workflow_runs` で取得できる」の精緻化）。
- **pusher の push 手段は gitpush MCP のみ**: 通常は `gitpush_push(repo_path, remote="origin", branch, force)` で、事前設定済みの名前付きリモートへ同名ブランチをそのまま push するだけ。リモート追加・ブランチ作成・refspec・ローカル `git push` は不可。committer の bash 許可は `git add/commit/status/diff/log` のみで、`remote*`/`checkout*`/`branch*`/`reset*`/`rm*`/`rev-list`/`config`/`ls-files`/`grep` は DENIED（実測）。
- **gitpush MCP のツールバインディングがセッションに無い場合の HTTP フォールバック（2026-08 実測）**: 本環境では gitpush MCP のツールバインディングがセッションに無く `gitpush_push` が呼べない場合があり、ローカル coder の bash も `git push*`/`git remote*` を拒否する。この場合は gitpush MCP サーバー `http://gitpush-mcp:3007/mcp` を HTTP 直接呼び出しする。JSON-RPC のツール名は **`push`**（`gitpush_push` ではない）。params は `repo_path` / `remote` / `branch` / `force`。Forgejo PAT はサーバー内部で解決されるためクライアント側でのトークン指定は不要。push 後に Forgejo 側（`list_branches` / `list_repo_commits`）でブランチ・コミットを確認してから「push した」と報告すること。
- **Forgejo PAT の取得先を `dotfiles/.dockerscripts/.env` に固定しない（2026-08 実測）**: 過去に「PAT は `dotfiles/.dockerscripts/.env` の `FORGEJO_PERSONAL_ACCESS_TOKEN` から取得できる」と記載していたが、コンテナ環境によっては `.env` 自体が存在しない（`.env.example` のみ）場合がある。PAT の場所・変数名は実行時に確認し、`.env` の存在を前提としないこと。取得後は HTTP ヘッダ `Authorization: token <PAT>` で curl 等から Forgejo REST API を呼ぶ。
- **公開リポジトリは認証なし REST API で読み取りできる（2026-08 実測）**: 公開リポジトリであれば `Authorization` ヘッダ無しの `curl` でも、PR のインラインコメント・変更ファイル（files）一覧など読み取り系の Forgejo REST API を呼べる。MCP ツールがサーバー側エラーで失敗する場合（例: `list_pull_review_comments` の `GetReviewByID` エラー）のフォールバックとして、公開リポジトリなら認証なし REST API を試すこと。
- **committer への `git -c user.name=... -c user.email=... commit` 指定は DENIED**: `-c` プレフィックス付きコマンドは allowlist の `git commit` に一致しない（実測）。bot 身元で通常コミットするには、リポジトリのデフォルト identity が bot であることを事前に確認してから素の `git commit` を実行し、コミット後に `git log -1` で author/committer が bot 身元であることを必ず確認する。identity を明示指定する必要がある場合は coder（builder 配下）に委譲する。
- **このコンテナ環境では git のデフォルト identity が存在せず、committer 単独でのコミット作成は不可**: `.git/config` に `[user]` セクションが無くグローバル config も読み取り不可のため、committer の素の `git commit` は `Author identity unknown / unable to auto-detect email address` で失敗する（dotfiles#4 で実測）。committer の allowlist では `git config` / `-c` / `GIT_AUTHOR_*` env / `--author` が全て DENIED。したがって「デフォルト identity が bot である」ことを確認できない場合は、最初から coder（builder 配下）にコミット作成を委譲する。coder では `git -c user.name="bot-..." -c user.email="bot@..." commit` が許可されている（committer と異なり DENIED されない）ことを dotfiles#4 で実証。委譲後は `git log -1 --format='%h %an <%ae> | %cn <%ce>'` で author/committer 双方が bot 身元であることを必ず確認する。
- **committer 環境のデフォルト identity は未設定（bot ですらない）**: 実測では `.git/config` に `[user]` セクションが無く、global/system config も `GIT_AUTHOR_*` 等の env も無いため、素の `git commit` は `Author identity unknown` で abort する。「デフォルト identity が bot なら素の commit」を当てにせず、**コミットは最初から coder（builder 配下）に委譲**し、coder が `git -c user.name="<bot>" -c user.email="<bot>" commit`（または repo-local `git config` 後に素の commit）で実行するのが既定手順。コミット後は `git log -1` で author/committer が bot 身元であることを必ず検証する。committer（integrator 配下）に commit を委ねると identity 未設定で必ず詰まる（実発生）。
- **素の `git commit` が `Author identity unknown` で失敗した時の確実な対処（2026-08 実測）**: リポジトリのデフォルト identity（`.git/config` の `[user]`）が未設定で、committer の allowlist が `git config` を禁止している場合、素の `git commit` は `Author identity unknown` で失敗する。確実な修正方法は commit を coder（builder 配下）に委譲して `git -c user.name="bot-genji1024" -c user.email="bot@genji1024.com" commit` で実行すること。デフォルト identity が bot であると想定せず、`git log -1 --format="%an <%ae>"` で確認するか、コミット失敗時にこの対処へ切り替えること。
- **push 先リモートの検証が必須**: gitpush MCP のデフォルト remote は `origin`。ローカルリポジトリの origin が GitHub の場合、`remote="forgejo"` を明示しない限り push は GitHub に行き Forgejo には反映されない。Forgejo へ push する際は `remote="forgejo"` を明示し、push 後に `list_branches` / `list_repo_commits` で Forgejo 側のコミット・ブランチを確認してから「Forgejo に push した」と報告すること（過去に「Forgejo へ push」と報告しつつ実際は GitHub origin に push していた事案あり）。リモート追加は coder の `git remote add` で行う。
- **Forgejo MCP に複数ファイルを1コミットで作る手段は無い**: `create_file` は 1ファイル=1コミット（content は base64）。git data API（tree/commit/ref の低レベル作成）やバッチ `create_files` 相当は未提供。
- **PR クローズ専用ツールは存在しない**: `close_pull_request` 相当は無い。PR をクローズするには `update_pull_request(state="closed")` で代用する（実測）。クローズする前に理由コメントを投稿してからクローズすること。
- **「GitHub→Forgejo の1コミットsquash移行」は coder の git plumbing 経路で実行可能（実証済み）**: 空リポジトリへ `main=空init` + `migrate/from-github=squash` を作るには、**builder→coder に委譲**し、coder の広範な bash 許可（`git remote add` / `git fetch` / `git mktree` / `git hash-object -t commit -w --stdin` / `git update-ref` / `git checkout -B` / `git reset --hard` / `git rev-parse` / `git log`）で plumbing 方式（`git commit` 不使用）によりコミットオブジェクトを直接構築する。その後 integrator→pusher が gitpush MCP で `remote="forgejo"` へ push し、pr-manager が PR を作成する。committer の allowlist（`git add/commit/status/diff/log` のみ）だけを根拠に「実行不可」と判断しないこと（private-opencode-server#1 / agent-skills#1 で実証済み）。コミット数の計測は `git rev-list --count` が DENIED なので `git log --oneline origin/main | wc -l` の行数で代用する。
- **plumbing でのコミット構築手順（`git commit` 不使用）**: 空ツリーは `git mktree </dev/null`（既知の空ツリー SHA `4b825dc642cb6eb9a060e54bf8d69288fbee4904` でも可）。コミットオブジェクトは `printf 'tree <tree-sha>\nparent <parent-sha>\nauthor <name> <email> <timestamp> +0900\ncommitter <name> <email> <timestamp> +0900\n\n<message>\n' | git hash-object -t commit -w --stdin`（parent 行は空initでは省略）で作成し、`git update-ref refs/heads/<branch> <sha>` でブランチに指す。squash コミットの tree は `git rev-parse origin/main^{tree}` の値を使う。**`git checkout -B <branch>` は開始点を必ず明示**（例: `git checkout -B migrate/from-github <sha>`）。開始点を省略すると、既存ブランチを HEAD にリセットして squash コミットのポインタを上書きしてしまう（実発生したバグ）。
- **plumbing で構築するコミットの author/committer は自分（bot）の身元を使う**: `<name> <email>` には `get_my_user_info` で動的解決した自分のユーザ名・メール（例: `bot-genji1024 <bot@genji1024.com>`）を指定する。リポジトリオーナーの名前や `git config user.name` のデフォルト（人間の名前）を使わない（実発生: author が `genji1024` になり PR レビューで指摘された）。
- **plumbing で構築するコミットのメッセージも commit-message スキルに従う**: `git commit` を使わず `printf ... | git hash-object` で直接コミットオブジェクトを作る場合も [commit-message](../../commit-message/SKILL.md) の形式制約を適用する。body の行間は空けない（見出しと本文の間の1行のみ）、トップレベル（抽象）とサブバレット（具体）の階層構造にする（実発生: body の行間に空行が入り、階層的でないと PR レビューで指摘された）。
- **docker-mcp / bash の `docker` CLI のどちらが利用可能かは実行時要因で変わる（DinD 移行後は逆転しうる）**: 以前は「docker-mcp は利用可能（bash の `docker` CLI は無い）」としていたが、DinD 移行後は逆に docker-mcp がセッションに配線されておらず、bash の `docker` CLI（dind, Docker 27.5.1）が直接使える状態だった（実測）。どちらが利用可能かは実行時要因（DinD 移行等）で変わりうるため、**セッション開始時に docker-mcp のツール呼び出し試行と bash の `docker` コマンド存在確認（`command -v docker` / `docker version`）の両方を行い、利用可能な方を使うこと**。Docker 動作確認は必ず利用可能な方（docker-mcp または bash の `docker` CLI）で実施する。**「実行環境に Docker が無い」と報告する前に、docker-mcp と bash の `docker` CLI の両方の利用可否を必ず確認する**（実発生: docker-mcp が使えるのに「Docker が無いため未実施」と報告し、レビューで指摘された）。docker-mcp に compose ツールは無いため、compose 相当は build / start / network を個別に呼んで再現する（bash の `docker` CLI が使えるなら `docker compose` も利用可）。
- **docker-mcp のビルドコンテキストは `/workspace` 配下に限られる**: `docker_build_docker_image` はビルドコンテキストが `/workspace` 配下にあることを要求し、`/home/genji/repos/workspace/...` のようなパスは `resolves outside of /workspace; refusing to build` で拒否される（2026-08 実測）。docker-mcp が利用可能でもこのパス制約によりビルドが不可能な場合がある。「Docker が無いため未実施」と報告する前に、**docker-mcp の利用可否とこのパス制約の両方**を確認すること。なお `/workspace` と作業ディレクトリ `/home/genji/repos/workspace` は**別ファイルシステムで非同一**であり、必要なら tar での同期 + `docker_docker_cp` で回避すること。
- **builder のローカルコミットが pusher からアクセス不可の場合がある（2026-08 実測）**: builder がローカルでコミットしても、pusher が external_directory 制約でローカルリポジトリのパスにアクセス不可の場合がある。この場合 push は「Everything up-to-date」となりローカルコミットが反映されない（実発生: `/home/genji/repos/genji1024/containerized-agents` でコミットを作成したが反映されなかった）。代替として `update_file`（または `create_file`）でリモートに直接コミットする。ただし 1ファイル=1コミットになるため、複数ファイル変更時はファイル毎にコミットされる点に注意。ローカルコミットの SHA とリモートに直接作成したコミットの SHA は異なるため、完了報告コメントには実際に push された（リモートに存在する）SHA を記載すること。さらに、フォールバックでの内容適用は「オーケストレータが指定した目標テキストの逐語適用＋適用後の逐語検証」で行うこと。内容の再構築・言い換えは誤った記録を生む（2026-09-02 実測: 再構築により追加した教訓が分離・誤帰属され、修正コミットが追加で必要になった）。
- **Forgejo act ランナーは step 境界でバックグラウンドプロセスを後始末する（2026-08 実測）**: GitHub Actions 前提の「起動 step と検証 step を分離」するワークフローは Forgejo では動かない。起動 step で `&` 起動したプロセスが次 step 開始直後に消滅する（`Initial HTTP status: 000`）。起動〜検証は同一 step に統合すること。またランナーイメージ `node:20-bookworm` には **docker CLI が無い**ため `docker compose` 系 step は常に失敗する。Docker 検証は CI に載せず docker-mcp でローカル実施するのが確実（private-opencode-server#4 で実測）。
- **CI 失敗を「テスト・ジョブ削除」で回避してはならない（2026-08 レビュー指摘）**: Forgejo act ランナーの環境要因（例: ランナーイメージ `node:20-bookworm` に docker CLI が無い）で CI ジョブが失敗しても、失敗ジョブ・テストを**削除して CI を緑にするのは「テスト削除による回避」であり禁止**（private-opencode-server#4 でレビュー指摘）。手順: (1) 失敗の根本原因を調査し (2) テスト・ジョブの削除・変更が必要な場合は**実施前にレビュアー判断を仰ぎ** (3) 環境要因が原因なら環境を提供する側（例: genji1024/forgejo-server のランナー設定）にイシューを立てて根本解決する。既存の docker 系 CI ジョブを勝手に削除しないこと。
- **ブランチ作成前に必ずリモートを fetch して最新化する**: ローカルの `forgejo/main`（等）が古いままブランチを切ると、PR の親コミットが最新 main にならず `mergeable=false` になる（実発生: dotfiles#4 でオーナーに「親コミットが main 最新でない。必ずローカルブランチを全て最新の状態にしてから作業するように」と指摘され、リベース＋force push を強いられた）。ブランチ作成前に `git fetch forgejo main` 等で最新を取得し、`git rev-parse forgejo/main` が最新であることを確認してからブランチを切ること。
- **main への直接 push 前も必ず fetch → rebase で最新化する（2026-08 実測）**: Skill Update Rules によるスキル更新など main への直接コミット・push でも、ローカル main が古いままだと並行セッションのコミットでリモートが先行している場合に `! [rejected] main -> main (fetch first)` で push が拒否される（2026-08 実測）。対処は push 前に必ず `git fetch origin main` → `git rebase origin/main`（または merge）で最新化してから push すること。fetch/rebase は coder（builder 配下）に委譲する（pusher は push のみ、committer は identity 未設定・allowlist 制約で実施不可）。
- **`list_pull_review_comments` がサーバー側エラー（`GetReviewByID`）で失敗する環境がある（2026-08-22 実測）**: 実行時に観測したところ、`list_pull_review_comments` が全 PR で `-32603: GetReviewByID` のサーバー側エラーになり、インラインコメント本文を取得できない環境があった。**2026-09-02 実測: このエラーは review id を省略した呼び出しで発生する場合があり、`id` 引数にレビュー id を明示して再呼び出しすると成功する。まず review id 明示渡しで再試行すること**。再発時は「インラインコメントなし」と断定せず、通常コメント（`list_issue_comments`）とレビュー（`list_pull_reviews`）で指摘を見落とさないこと。公開リポジトリであれば認証なし REST API（`Authorization` ヘッダ無しの `curl`）でインラインコメント・files 一覧を取得できるため、MCP エラー時のフォールバックとして試すこと。
- **PR 詳細取得ツールの実在は実行時に確認する（2026-08 実測）**: 実行時に確認した環境では `get_pull_request` が存在せず、`get_pull_request_by_index`（owner/repo/index 指定）で取得できた。どちらのツールが存在するかは実装により異なるため、セッション開始時の判定で利用可能なツール一覧を確認してから使うこと。
- **リポジトリ・ユーザ・組織系ツールの実在は実行時に確認する（2026-08 実測）**: 実行時に確認した環境では `list_user_repos` / `list_org_repos` / `list_collaborators` / `get_user` / `list_orgs` が存在せず、代わりに `list_my_repos`（自分のリポジトリ一覧）・`list_my_orgs`（組織判定）が利用できた。`list_repo_labels` は実在する（2026-08-26 実測）。どのツールが存在するかは実装により異なるため、各ツールは実行時に存在確認してから使うこと。

## Prerequisites

- **ローカルの `git` を優先**: forgejo-mcpの呼び出しは対象インスタンスへのAPIコールになるため、可能な限りローカルの `git` コマンドを使用する。セッション開始時は `git remote -v` で対象のForgejoホスト・owner/repoを確認すること。
- **エージェント権限は `opencode.jsonc` を参照**: 各サブエージェント（coder / verifier / committer / pusher / pr-manager）の許可・拒否は `~/.config/opencode/opencode.jsonc` 配下の `agents/*.md` の `permission` に従う。committer は git add/commit/status/diff/log のみ許可されpush不可、GitHub/GitLab/Forgejo MCPはissue-reader（Planner配下、コンテキスト収集を担当）とpr-manager（Integrator配下、Issue/PR操作を担当）のみが利用できる、という役割分担になっている。

## Cross-Reference

- [autonomous-engineer](../autonomous-engineer/SKILL.md) — 共通のワークフロー・判断基準・Skill Update Rules（本体）
- [pr-workflow](../pr-workflow/SKILL.md) — PR作成・レビュー対応・CI検証の詳細ワークフロー（GitHub MCPのメソッド名を前提にした記述が含まれるため、手順の趣旨のみ流用し、具体的なツール呼び出しは上記Platform Bindingに読み替えること）
- [merge-conflict-resolution](../merge-conflict-resolution/SKILL.md) — マージ後のコンフリクト解決手順（同上、`update_pull_request` 等の呼び出し部分は読み替える）
- [build-and-verify](../build-and-verify/SKILL.md) — lint/typecheck/build/Docker動作確認の手順（プラットフォーム非依存）
