---
description: 現在のブランチから main への PR を pr-creator エージェント（Haiku）に委譲して作成する
argument-hint: "[PRの目的の補足（省略可）] [--draft]"
---

現在のフィーチャーブランチの Pull Request 作成を **pr-creator サブエージェント**に委譲する。メインセッションで直接 gh 操作をせず、必ずエージェント経由にする。

手順:

1. pr-creator エージェント（Agent ツール、`subagent_type: pr-creator`）を起動し、以下を渡す:
   - `purpose`: この一連の作業の目的・背景の要約。**会話の文脈から自分で書く**。`$ARGUMENTS` に補足があれば反映する
   - `draft`: `$ARGUMENTS` に `--draft` が含まれていれば true
2. エージェントの JSON 結果を受け、PR の URL とタイトルをユーザーに報告する。中断された場合（未コミット変更あり・既存 PR あり・認証エラー等）は理由と次のアクション（`/commit` の実行、[docs/setup/github-pat.md](../../docs/setup/github-pat.md) の参照など）を伝える。
