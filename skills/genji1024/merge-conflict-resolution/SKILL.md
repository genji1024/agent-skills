---
name: merge-conflict-resolution
description: genji1024 配下のリポジトリで、並行開発中のPRが他のPRのマージによりコンフリクトした際の解決手順。git merge/rebase、再フォーマット、CI再検証、レビュー再依頼を行う際に使う。
---

# Merge Conflict Resolution

## 背景

複数 PR を並行して開発するプロジェクトでは、1つの PR がマージされた後に残りの PR でコンフリクトが発生する。

## 解決手順

1. マージされた PR を確認
2. 残り全 PR のコンフリクトをチェック
3. 該当ブランチで `git merge origin/main` を実行
4. 競合は以下の戦略で解決:
   - `--ours` で main を取り込む（両方に同じ変更がある場合）
   - `prettier --write` で再フォーマット（format 競合の場合）
5. 全 CI チェックを実行:
   - `npm run lint`
   - `npm run format:check`
   - `npm run typecheck`
   - `npm run build`
6. push
   - `git merge origin/main` でマージコミットを作成した場合: `git push`（force push 不要）
   - `git rebase origin/main` でリベースした場合: `git push --force-with-lease` が必要
7. PR にコメントで解決報告 + @g-ohara メンション
8. `update_pull_request` でレビュー再リクエスト

## 注意点

- format:check が高確率で失敗するので、必ず `prettier --write` を実行
- コンフリクト解決後も全 CI チェックが通ることを確認
- force push 後はリモートの PR が自動更新される
