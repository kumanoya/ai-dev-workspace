---
name: figma-verify-screen
description: "実装済み画面と Figma デザインをスクリーンショットで突き合わせ、差異を人間チェック用レポートにまとめる視覚検証スキル。ユーザーが「Figma と突き合わせて」「スクショで比較して」「視覚検証して」等と明示的に依頼したときだけ起動する。実装スキルの完了工程ではないため、実装後に自動で呼ばない。指摘の提出までで止まり、修正はしない。"
---

# figma-verify-screen — 画面の視覚検証（明示依頼時のみ）

実装済み画面と Figma デザインを突き合わせ、差異を人間チェック用レポートにまとめる。
**呼ばれた時点で「ユーザーが視覚検証を依頼した」ことを意味する。**

このスキルは実装フローの一部ではない。`figma-implement-screen` は実装完了とブラウザ確認用 URL の案内で終わり、
検証を呼ぶかどうかは人間が決める（方針と根拠は `docs/ai-cost-optimization.md` §7）。

**レビュー1回で終了する。** 指摘を提出したらそこで止め、修正・再スクショ・再レビューはしない。
何を直すかの判断は人間が行い、実値つきの一括修正指示として別途受け取る。

## 前提

- 実装画面のスクショ取得（Playwright の前提・dev サーバーの確保・出力先規約）は、共通リファレンス
  [`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) に従う。
- レビュアー: `.claude/agents/figma-screen-reviewer.md`（model: haiku）。

## 入力

ユーザー / 呼び出し元から受け取る:

- **route**: 対象ルート（例 `/users`）
- **proto**: プロトタイプ名（既定 `sample-app-v2`）
- **Figma nodeId**: 実画面ノード（**遷移図のラベルではなく実デザイン**。例 `123:4567`）
- **fileKey**: 対象 Figma ファイルのキー（Figma URL の `figma.com/design/<fileKey>/...` 部分）
- **specPath**（任意）: 画面仕様 Markdown

> 実画面 nodeId が不明な場合は、`get_metadata` で「プロト連携用」キャンバス（`865:42978`）配下から
> 画面名のフレームを特定する（`specs/.../screens/flow.md` の node は遷移図ラベルなので実画面とは別）。

## 手順

### 1. 準備

[`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) を Read し、その手順1に従って dev サーバーを確保する（sample-app-v2 の port は **5175**）。`verify/shots/` がなければ作成する。

### 2. Figma 正解スクショの取得（1回）

- 同一 nodeId の `verify/shots/<name>-figma.png` が既に残っていれば**再利用してよい**（Figma 側のデザイン更新がユーザーから明示された場合を除く。取得済み画像の再取得は画像トークンの二重払い）。
- 無ければ `mcp__plugin_figma_figma__get_screenshot`（fileKey, nodeId, maxDimension=1600）で URL を取得し、
  `curl -s -o verify/shots/<name>-figma.png "<url>"` で保存する（URL は短命なので即取得）。

### 3. 実装スクショの取得

共通リファレンスの手順2に従い、このスキルでは2枚撮る:

```bash
cd prototypes/<proto>
node verify/screenshot.mjs <route> verify/shots/<name>-impl.png            # 1450x984 固定（Figma比較用）
node verify/screenshot.mjs <route> verify/shots/<name>-impl-full.png --full # スクロール込み全体
```

- 出力 JSON の `ok:true` / `status:200` / `consoleErrors:[]` を確認（エラーがあれば先に直す）。

### 4. レビュー（サブエージェント）

`figma-screen-reviewer`（model: haiku）を Agent ツールで起動し、次を渡す:

- `figmaShot`, `implShot`, `implFullShot`, `specPath`, `sourceFiles`（対象画面の .tsx/data/types）, `round: 1`

### 5. 人間チェック用レポート

[`.claude/skills/shared/human-check-report.md`](../shared/human-check-report.md) の**様式A（検証レポート）**と共通原則（実値併記・minor/nit 含め全件・一括修正指示の案内）に従い、verdict に関わらず findings を全件出力して終了する。人間が Figma と突き合わせて取捨選択し、**実値つきの一括修正指示**を出すための材料にする。

## コスト・暴走防止の原則

- **レビュアー起動は1回で固定**（画像2枚 + haiku 1回）。verdict が FAIL でも修正・再レビューに進まない。
- レビュアーは安価な視覚QAに徹し（`haiku`）、**数値プロパティ（余白/フォント/色）は画像目測でなく
  コード/トークンで確認**させる（誤判定の往復を減らす）。
- スクショ・Figma 取得・レビューは必要時のみ。同じ画像/ファイルを何度も読み直さない。

## 注意

- スクショは `deviceScaleFactor:2` で精細化済み。比較は同一 1450 幅で行い、apples-to-apples を保つ。
- `verify/shots/` の画像はコミットしない（検証用の一時生成物）。
- レビュアーは**指摘専用**。修正はこのスキルの範囲外。
- Figma MCP は read 系のみ（プロジェクト規約）。
