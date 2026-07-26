---
name: verify-design-diff
description: "実装画面のスクリーンショットと参照デザイン画像（PNG 等）を突き合わせ、相違点リストの解消状況を人間チェック用に報告する視覚検証スキル。ユーザーが「AI でも検証して」「見比べて」「verifier を回して」等と明示的に依頼したときだけ起動する。fix-design-diff の完了工程ではないため、修正後に自動で呼ばない。Figma MCP は使わない。指摘の提出までで止まり、修正はしない。"
---

# verify-design-diff — 参照画像との視覚検証（明示依頼時のみ）

`fix-design-diff` で修正した画面のスクリーンショットを撮り、参照デザイン画像と突き合わせて
相違点リストの解消状況を報告する。**呼ばれた時点で「ユーザーが視覚検証を依頼した」ことを意味する。**

このスキルは修正フローの一部ではない。`fix-design-diff` は実装完了とブラウザ確認用 URL の案内で終わり、
検証を呼ぶかどうかは人間が決める（方針と根拠は `docs/ai-cost-optimization.md` §7）。

**レビュー1回で終了する。** 指摘を提出したらそこで止め、修正・再スクショ・再レビューはしない。
**Figma MCP ツール（`mcp__figma-*` / `mcp__plugin_figma_*`）はどの段階でも呼ばない**（`fix-design-diff` と同じく、Figma 非連携が前提）。

## 入力

- **referenceImage**: 正しいデザインを示す画像ファイルの絶対パス（= `fix-design-diff` の `imagePath`）
- **diffList**: 元になった相違点リスト（各項目の解消を個別に判定する）
- **route**: 対象ルート（例 `/users/new`）
- **proto**（既定 `sample-app-v2`）
- **sourceFiles**（任意）: 修正で変更されたファイル群（数値プロパティの確認に使う）

## 手順

### 1. 実装スクショの取得

[`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) を Read し、その手順に従う（dev サーバーの確保 → 撮影 → 出力 JSON の `ok:true` / `status:200` / `consoleErrors:[]` の確認）。コンソールエラーがあれば、スクショ比較より先にその報告を優先する。

このスキルでの撮影は `--full` の1枚でよい:

```bash
cd prototypes/<proto>
node verify/screenshot.mjs <route> verify/shots/<name>-impl.png --full
```

### 2. レビュー（サブエージェント）

`design-diff-verifier`（model: haiku）を Agent ツールで起動し、次を渡す:

- `referenceImage`, `implShot`, `diffList`, `sourceFiles`, `round: 1`

### 3. 人間チェック用レポート

返ってくる JSON の `verdict` / `diffListStatus` / `findings` を、[`.claude/skills/shared/human-check-report.md`](../shared/human-check-report.md) の**様式A（検証レポート）**に従って整形して提示する。実装スクショと参照画像のパスを併記し、人間が見比べる材料にする。

未解決や新規の critical/major があってもユーザーに提示するまでで止める。**無断で修正ループに入らない。**

### 4. 後片付け

- 自分が起動した dev サーバーを停止する（起動済みを流用した場合は何もしない）。
- `verify/shots/` の画像は人間の目視確認が終わるまで残してよい（`.gitignore` 済み。コミットしない）。作業用の一時スクリプトは削除する。
