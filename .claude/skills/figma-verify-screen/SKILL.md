---
name: figma-verify-screen
description: "figma-implement-screen で実装した画面の実レンダリング結果（Playwright スクショ）を Figma デザインのスクショと突き合わせ、人間チェック用の検証レポートを出す（標準は mode: report）。「実装画面を検証して」「Figma と突き合わせて」「画面の差分レポートを出して」等で起動。PASS まで修正を反復する mode: loop はユーザーが明示的に指定した場合のみ。"
---

# figma-verify-screen — 実装画面を Figma と突き合わせて検証レポートを出す（標準）

実装済み画面の**実レンダリング結果**を Playwright でスクショし、Figma デザインのスクショと
`figma-screen-reviewer` サブエージェントで突き合わせ、**指摘を人間チェック用レポートに整形して報告する**スキル。
修正の判断と細部の検証は人間が担う（`docs/ai-cost-optimization.md` §7 の標準運用）。
PASS まで修正を反復する自動修正ループ（`mode: loop`）は**例外**で、ユーザーが明示的に指定した場合のみ使う
（手順・停止条件は [loop-mode.md](loop-mode.md)。標準運用では読み込み不要）。
`figma-implement-screen` で画面を作った後、見た目の忠実度を担保するために使う。

## 前提

- 実装画面のスクショ取得（Playwright の前提・dev サーバーの確保・出力先規約）は、共通リファレンス
  [`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) に従う（手順0で Read する）。
- レビュアー: `.claude/agents/figma-screen-reviewer.md`。
- `figma-implement-screen` は視覚照合（get_screenshot によるピクセル比較）を行わない設計になっている。実装後の視覚検証は必ず本スキルで行い、省略しない。

## 入力

ユーザー / 呼び出し元から受け取る:

- **route**: 検証するルート（例 `/users`）
- **Figma nodeId**: 実画面ノード（**遷移図のラベルではなく実デザイン**。例 `123:4567`）
- **fileKey**: 対象 Figma ファイルのキー（Figma URL の `figma.com/design/<fileKey>/...` 部分）
- **proto**: プロトタイプ名（既定 `sample-app-v2`）
- **specPath**（任意）: 画面仕様 Markdown
- **mode**（任意）: `report`（**既定**）/ `loop`（**例外**）。
  - `report`（既定）: **round 1 のレビューのみ実行し、修正は一切しない**。指摘を人間チェック用レポート（手順 5）に整形して終了する。細部の検証と修正指示は人間が担う（標準運用の根拠は `docs/ai-cost-optimization.md` §7）。
  - `loop`（例外）: PASS まで修正を反復する。**ユーザーが明示的に `mode: loop` を指定した場合のみ**使う（例外条件は `docs/ai-cost-optimization.md` §7.3）。反復手順・`maxRounds`（既定 3）・停止条件は [loop-mode.md](loop-mode.md) を Read して従う。

> 実画面 nodeId が不明な場合は、`get_metadata` で「プロト連携用」キャンバス（`865:42978`）配下から
> 画面名のフレームを特定する（`specs/.../screens/flow.md` の node は遷移図ラベルなので実画面とは別）。

## 手順（メインエージェントが駆動する。標準は 0→1→2→3→4→5 の1周で終了）

### 0. 準備

[`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) を Read し、その手順1に従って dev サーバーを確保する（sample-app-v2 の port は **5175**）。`verify/shots/` がなければ作成する。

### 1. Figma 正解スクショの取得（1回）

- 同一 nodeId の `verify/shots/<name>-figma.png` が既に残っていれば**再利用してよい**（Figma 側のデザイン更新がユーザーから明示された場合を除く。取得済み画像の再取得は画像トークンの二重払い）。
- 無ければ `mcp__plugin_figma_figma__get_screenshot`（fileKey, nodeId, maxDimension=1600）で URL を取得し、
  `curl -s -o verify/shots/<name>-figma.png "<url>"` で保存する（URL は短命なので即取得）。

### 2. 実装スクショの取得

共通リファレンスの手順2に従い、このスキルでは2枚撮る:

```bash
cd prototypes/<proto>
node verify/screenshot.mjs <route> verify/shots/<name>-impl.png            # 1450x984 固定（Figma比較用）
node verify/screenshot.mjs <route> verify/shots/<name>-impl-full.png --full # スクロール込み全体
```

- 出力 JSON の `ok:true` / `status:200` / `consoleErrors:[]` を確認（エラーがあれば先に直す）。

### 3. レビュー（サブエージェント）

- `figma-screen-reviewer` を Agent ツールで起動し、次を渡す:
  - `figmaShot`, `implShot`, `implFullShot`, `specPath`, `sourceFiles`（対象画面の .tsx/data/types）, `round`。
- 返ってくる JSON の `verdict` を確認。

### 4. 判定

**標準（`mode: report`・既定）はここで終了**: verdict に関わらず findings を人間チェック用レポート（手順 5）に整形して報告する。**修正・再スクショ・再レビューは行わない**。修正するかどうか・何を直すかの判断は人間が行い、実値つきの一括修正指示として別途受け取る。

`mode: loop` が明示指定されている場合のみ、[loop-mode.md](loop-mode.md) を Read し、その判定・反復・停止条件に従う。

### コスト・暴走防止の原則

- **`mode: report`（標準）が最安の構造**: verify の中で最もコストが重いのは round ごとのスクショ（画像トークン）+ レビュアー起動 + 修正の反復であり、report はこれを 1 回で打ち切る。人間チェック + 実値つき一括修正指示との分担が品質面でも合理的（`docs/ai-cost-optimization.md` §7）。
- レビュアーは安価な視覚QAに徹し（既定 `sonnet`）、**数値プロパティ（余白/フォント/色）は画像目測でなく
  コード/トークンで確認**させる（誤判定の往復を減らす）。最終確認だけ opus に上げてもよい。
- スクショ・Figma取得・レビューは必要時のみ。同じ画像/ファイルを何度も読み直さない。

### 5. 人間チェック用レポート（標準・mode: report のとき）

[`.claude/skills/shared/human-check-report.md`](../shared/human-check-report.md) の**様式A（検証レポート）**と共通原則（実値併記・minor/nit 含め全件・一括修正指示の案内）に従い、findings を全件出力して終了する。人間が Figma と突き合わせて取捨選択し、**実値つきの一括修正指示**を出すための材料にする。

## 注意

- スクショは `deviceScaleFactor:2` で精細化済み。比較は同一 1450 幅で行い、apples-to-apples を保つ。
- `verify/shots/` の画像はコミットしない（検証用の一時生成物）。
- レビュアーは**指摘専用**。修正はメイン/実装エージェント側で行い、必ず再スクショで効果を確認してから次へ。
- Figma MCP は read 系のみ（プロジェクト規約）。
