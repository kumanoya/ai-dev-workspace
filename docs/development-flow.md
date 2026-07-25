# 開発フロー — Issue からマージまで

このリポジトリでの変更の進め方の権威。規約の実体（コミットメッセージの型一覧、PR 本文の項目、deny リストの中身）は各権威ファイルが正であり、本書は**流れと、そう決めた理由**に徹する。

```
Issue / チケット
      ↓
フィーチャーブランチを切る（main から）
      ↓
実装 → 意味的な区切りごとにコミット（AI が自律的に行ってよい）
      ↓
/create-pr で PR 作成（人間が push を承認）
      ↓
レビュー（差分単位）
      ↓
マージ（人間のみ）
```

## Issue / チケットの紐付け

**PR には必ず Issue かチケットを1つ紐付ける。** 「何のための変更か」がコード差分の外に残らないと、数ヶ月後のレビューアも書いた本人も判断材料を失うため。

- **GitHub Issue が基本**。PR 本文に `Closes #12` と書けばマージ時に自動クローズされる
- **外部チケット**（Jira / Backlog 等）を使う案件では URL を貼る。GitHub 側の自動クローズ連携は効かないので、チケットのクローズは手動で行う
- 記入欄は [.github/pull_request_template.md](../.github/pull_request_template.md) の先頭セクション

AI に PR を作らせるときは `/create-pr #12` のように番号を明示的に渡す。**渡さなかった場合、AI は Issue 番号を推測しない**（無関係な Issue を巻き添えでクローズする事故を防ぐため、`.claude/agents/pr-creator.md` に禁止として明記してある）。

## ブランチ

`main` への直接コミットは禁止。必ずフィーチャーブランチを切って PR 経由でマージする。

命名は `<type>/<内容の kebab-case>`。`<type>` はコミット規約と同じ語彙（`feat` / `fix` / `docs` 等、一覧は [commit スキル](../.claude/skills/commit/SKILL.md)）を使い、規約をブランチ・コミット・PR タイトルで揃える。

例: `feat/user-search-screen`、`fix/login-redirect`、`docs/pr-template`

## コミット

規約と手順の権威は [.claude/skills/commit/SKILL.md](../.claude/skills/commit/SKILL.md)。運用上の要点:

- **AI は作業の意味的な区切りごとに自律コミットしてよい**（人間の指示を待たない）。人間はコミット差分単位でレビューできる粒度になっていることを期待する
- **push できるのは人間だけ**。AI の `git push` は `.claude/settings.json` の deny で技術的にブロック済み。これは「差分を人間が見る機会」を仕組みで担保するためのガード

## PR

作成は `/create-pr`（pr-creator サブエージェントに委譲）。本文フォーマットの権威は [.github/pull_request_template.md](../.github/pull_request_template.md) で、AI 経由でも GitHub Web UI 経由でも同じテンプレが使われる。

- **タイトルはコミットと同じ `<type>: <日本語要約>`**。破壊的変更は `<type>!:`
- **粒度は「1 PR = 1つのレビュー可能な関心事」**。目安としてレビューが一息で終わる規模。無関係な変更（ついでのリファクタ、typo 修正）を混ぜない。混ざりそうなら PR を分ける
- **チェックボックスは実際に確認した項目だけチェックする。** AI にも人間にも同じルールを課す。埋めることが目的化したチェックはレビューアの判断を狂わせ、チェックリスト自体を無意味にする

## レビューとマージ

- レビュー観点は PR テンプレの「セルフチェック」が起点。追加の観点が定常的に必要になったらテンプレ側に足す（レビューアの記憶に依存させない）
- `gh pr merge` / `gh pr close` は `.claude/settings.json` の deny でブロック済み。**マージ判断は人間が行う**
- 破壊的な `gh` コマンドの deny 一覧の権威は `.claude/settings.json`
