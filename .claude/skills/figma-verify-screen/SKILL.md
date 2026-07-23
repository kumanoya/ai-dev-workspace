---
name: figma-verify-screen
description: "figma-implement-screen で実装した画面の完了確認をするスキル。既定では AI レビューを行わず、実装完了とブラウザ確認用 URL の案内で終了する。ユーザーが「Figma と突き合わせて」「スクショで比較して」「視覚検証して」等、スクショベースの AI レビューを明示的に依頼した場合のみ、Playwright スクショと Figma デザインを figma-screen-reviewer で突き合わせ、人間チェック用レポートを出す（mode: report）。PASS まで修正を反復する mode: loop は、AI レビューを依頼した中でさらに明示指定した場合のみ。"
---

# figma-verify-screen — 画面の完了確認（既定は軽量、AI レビューはオプトイン）

`figma-implement-screen` で実装した画面に対して呼ばれるスキル。**既定では AI レビューを行わない**
（スクショ取得もレビュアー起動もしない）。実装完了とブラウザ確認用 URL を案内して終了する。
ユーザーが「Figma と突き合わせて」「スクショで比較して」「視覚検証して」等、
スクショベースの AI レビューを**明示的に**依頼した場合のみ、手順B（AI レビュー）を実行する。

```
呼び出し
  │
  ├─ AI レビューの明示依頼なし（既定）──→ 手順A（完了案内のみ）で終了
  │
  └─ AI レビューの明示依頼あり ────────→ 手順B（mode: report）
                                           │
                                           └─ loop の明示指定あり → loop-mode.md（mode: loop）
```

修正の判断と細部の検証は常に人間が担う（標準運用の根拠は `docs/ai-cost-optimization.md` §7）。

## 前提

- 実装画面のスクショ取得（Playwright の前提・dev サーバーの確保・出力先規約）は、共通リファレンス
  [`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) に従う（**手順Bの準備でのみ** Read する。手順Aでは Read しない）。
- レビュアー: `.claude/agents/figma-screen-reviewer.md`（model: haiku）。
- `figma-implement-screen` は視覚照合（get_screenshot によるピクセル比較）を行わない設計になっている。実装後の完了確認は本スキルを経由するが、既定では画面確認はブラウザで人間が行う運用とし、AI による視覚照合（スクショ取得・レビュアー起動）はユーザーが明示的に依頼した場合のみのオプション工程とする。

## 入力

ユーザー / 呼び出し元から受け取る:

- **route**: 対象ルート（例 `/users`）
- **proto**: プロトタイプ名（既定 `sample-app-v2`）
- **mode**（任意）: 未指定（**既定**）/ `report` / `loop`
  - 未指定（既定）: **AI レビューを一切行わない**。手順A（完了案内）のみで終了する。
  - `report`: ユーザーが「Figma と突き合わせて」「スクショで比較して」等、AI レビューを明示的に求めた場合に指定。手順B（レビュー1回・修正なし）を実行する。
  - `loop`: `report` に加え、PASS まで修正を反復してほしいとユーザーが明示指定した場合のみ。手順の詳細・停止条件は [loop-mode.md](loop-mode.md)（例外条件は `docs/ai-cost-optimization.md` §7.3）。

手順B（AI レビュー）のときのみ追加で必要:

- **Figma nodeId**: 実画面ノード（**遷移図のラベルではなく実デザイン**。例 `123:4567`）
- **fileKey**: 対象 Figma ファイルのキー（Figma URL の `figma.com/design/<fileKey>/...` 部分）
- **specPath**（任意）: 画面仕様 Markdown

> 実画面 nodeId が不明な場合は、`get_metadata` で「プロト連携用」キャンバス（`865:42978`）配下から
> 画面名のフレームを特定する（`specs/.../screens/flow.md` の node は遷移図ラベルなので実画面とは別）。

## 手順A: 既定（AI レビューを依頼されていない場合）

1. 実装側（`figma-implement-screen` 等）からの完了報告（`changedFiles` 等）を受け取る。
2. dev サーバーの起動有無だけ確認する（`curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>`。port は対象プロトタイプの `vite.config.ts` が権威。sample-app-v2 は 5175）。**スクショは撮らない**。未起動でも、起動はユーザーの確認手順に委ねてよい（スクショ目的での起動はしない）。
3. [`.claude/skills/shared/human-check-report.md`](../shared/human-check-report.md) の**様式C（完了案内）**に従い、変更ファイル一覧とブラウザ確認用 URL（`http://localhost:<port><route>`）を案内して終了する。
   Figma 正解スクショの取得・実装スクショの取得・`figma-screen-reviewer` の起動は一切行わない。

## 手順B: AI レビュー（mode: report — ユーザー明示依頼時のみ）

### B-0. 準備

[`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) を Read し、その手順1に従って dev サーバーを確保する（sample-app-v2 の port は **5175**）。`verify/shots/` がなければ作成する。

### B-1. Figma 正解スクショの取得（1回）

- 同一 nodeId の `verify/shots/<name>-figma.png` が既に残っていれば**再利用してよい**（Figma 側のデザイン更新がユーザーから明示された場合を除く。取得済み画像の再取得は画像トークンの二重払い）。
- 無ければ `mcp__plugin_figma_figma__get_screenshot`（fileKey, nodeId, maxDimension=1600）で URL を取得し、
  `curl -s -o verify/shots/<name>-figma.png "<url>"` で保存する（URL は短命なので即取得）。

### B-2. 実装スクショの取得

共通リファレンスの手順2に従い、このスキルでは2枚撮る:

```bash
cd prototypes/<proto>
node verify/screenshot.mjs <route> verify/shots/<name>-impl.png            # 1450x984 固定（Figma比較用）
node verify/screenshot.mjs <route> verify/shots/<name>-impl-full.png --full # スクロール込み全体
```

- 出力 JSON の `ok:true` / `status:200` / `consoleErrors:[]` を確認（エラーがあれば先に直す）。

### B-3. レビュー（サブエージェント）

- `figma-screen-reviewer`（model: haiku）を Agent ツールで起動し、次を渡す:
  - `figmaShot`, `implShot`, `implFullShot`, `specPath`, `sourceFiles`（対象画面の .tsx/data/types）, `round`。
- 返ってくる JSON の `verdict` を確認。

### B-4. 判定

**`mode: report` はここで終了**: verdict に関わらず findings を人間チェック用レポート（B-5）に整形して報告する。**修正・再スクショ・再レビューは行わない**。修正するかどうか・何を直すかの判断は人間が行い、実値つきの一括修正指示として別途受け取る。

`mode: loop` が明示指定されている場合のみ、[loop-mode.md](loop-mode.md) を Read し、その判定・反復・停止条件に従う。

### B-5. 人間チェック用レポート（mode: report のとき）

[`.claude/skills/shared/human-check-report.md`](../shared/human-check-report.md) の**様式A（検証レポート）**と共通原則（実値併記・minor/nit 含め全件・一括修正指示の案内）に従い、findings を全件出力して終了する。人間が Figma と突き合わせて取捨選択し、**実値つきの一括修正指示**を出すための材料にする。

## コスト・暴走防止の原則

- **最大の削減は「AI レビューを既定で実行しないこと」自体**（手順A）。手順Bに進んだ場合の最安構成が `mode: report`（画像2枚 + レビュアー起動 × 1回で固定）である、という位置づけは維持（`docs/ai-cost-optimization.md` §7）。
- レビュアーは安価な視覚QAに徹し（`haiku`）、**数値プロパティ（余白/フォント/色）は画像目測でなく
  コード/トークンで確認**させる（誤判定の往復を減らす）。
- スクショ・Figma取得・レビューは必要時のみ。同じ画像/ファイルを何度も読み直さない。

## 注意

- 本スキルが呼ばれた＝視覚検証が必要、ではない。既定は完了確認のみで足りる（プロトタイプフェーズの運用方針。`docs/ai-cost-optimization.md` §7）。
- スクショは `deviceScaleFactor:2` で精細化済み。比較は同一 1450 幅で行い、apples-to-apples を保つ。
- `verify/shots/` の画像はコミットしない（検証用の一時生成物）。
- レビュアーは**指摘専用**。修正はメイン/実装エージェント側で行い、必ず再スクショで効果を確認してから次へ。
- Figma MCP は read 系のみ（プロジェクト規約）。
