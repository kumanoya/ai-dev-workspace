---
name: fix-design-diff
description: 「この画像/PNGが正しいデザイン」「実装との相違点をリスト化したので直して」のように、参照デザイン画像（Figma からの書き出しやスクショ）と相違点リストをもとに、Figma MCP を使わずに実装を修正する。実装は design-diff-implementer（Sonnet サブエージェント）に委譲し、メインループは指示と統合のみ行う。既定の検証はスクショを撮って人間に渡すまで（AI 視覚検証はユーザーの明示依頼時のみ design-diff-verifier を使う）。Figma に直接アクセスできる/してよい場合は figma-implement-screen / figma-verify-screen を使う。
---

# fix-design-diff — 参照画像＋相違点リストによる実装修正（Figma 非連携）

実装済み画面と「正しいデザイン」を示す**画像ファイル**（Figma からの書き出し PNG、デザイナー共有のスクショ等）を突き合わせ、ユーザーが挙げた相違点リストを解消するスキル。**Figma MCP には一切アクセスしない**（コスト節約や Figma 未連携環境での利用を想定）。

## 運用方針（最優先）

このスキルは「安く・そこそこ直る」ことを最優先に設計されている:

- **diffList がスコープの全て。** 修正箇所の特定は人間の役割であり、AI は渡されたリストの項目だけを直す。
- **画像は参考資料。** リスト項目を実装するときの見本として参照するのみで、画像と実装の網羅的な差分探索・照合はしない（それはコストが掛かる割に人間の目視で足りる）。
- **完璧を目指さない。** リストの項目がある程度解消されれば成功。判断できない項目は推測で直さずスキップし、最終報告に含める。
- **最終チェックは人間。** 既定フローはスクショを撮って人間に渡すところまで。AI による視覚検証はユーザーが明示的に頼んだ場合のみ。

## いつ使うか

- ユーザーが画像ファイルのパスを渡し、「これが正しいデザイン」「実装との差分を直して」と依頼したとき。
- 相違点が既にリスト化されている（文言違い・色違い・要素の有無・レイアウト違い等）。
- 明示的に「Figma MCP は使わないで」「Figma 連携は不要」と指示されたとき。

Figma に直接アクセスしてよい状況（node-id 付き URL があり、都度取得してよい）では、代わりに `figma-implement-screen` / `figma-verify-screen` を使う。

## コスト方針とモデル配分

メインループ（このスキルを実行しているエージェント自身）は入力の整理・スクショ取得・結果の統合に徹し、重い読み取りと実装はサブエージェントに委譲する。メインループが自前で Edit/Write して実装しない（単発の小修正に見えても、必ずサブエージェント経由にする）。

| 役割 | モデル | 備考 |
| ---- | ------ | ---- |
| メインループ | Sonnet で十分 | オーケストレーションのみ。Fable / Opus は不要 |
| `design-diff-implementer` | sonnet（agent 定義で固定） | 画像参照＋コード修正 |
| `design-diff-verifier` | sonnet（agent 定義で固定） | オプション。明示依頼時のみ起動 |

## 前提

- 実装画面のスクショ取得（Playwright の前提・dev サーバーの確保・出力先規約・`verify/screenshot.mjs` が無い環境のフォールバック）は、共通リファレンス [`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) に従う（手順3で Read する）。

## 入力

ユーザー / 呼び出し元から受け取る:

- **imagePath**: 正しいデザインを示す画像ファイルの絶対パス
- **diffList**: 相違点リスト（ユーザーが箇条書きで提示。無ければ先に確認する）
- **route**: 検証対象のルート（例 `/users/new`）
- **proto**（既定 `sample-app-v2`）
- **targetHint**（任意）: 画面名・推定コンポーネントパス

diffList の色・数値系の項目は、可能なら具体値を含めてもらう（例「送信ボタンの背景を `#e3edfe` に」「カード間の gap を 16px に」）。具体値があれば実装エージェントのピクセルサンプリング工程が丸ごと省け、精度も上がる。無くても動くが、値の確定に手間が掛かる。

## 手順

### 1. 対象の特定（メインループ・軽量）

`route` や `diffList` の内容から対象画面が明らかでなければ、Grep/Glob で `src/components/organisms/` 配下の候補を軽く絞り込む（詳細な読み込みは行わない。それは実装エージェントの仕事）。

### 2. 実装（サブエージェントに委譲）

`design-diff-implementer` を Agent ツールで起動する。渡す情報:

- `imagePath`, `diffList`, `targetHint`, `proto`

エージェントは画像の目視確認・（diffList に具体値が無い色指摘に限り python3 + Pillow によるピクセルサンプリングでの色確定）・対象ファイルの特定・実装・`pnpm run lint && pnpm run build` までを行い、`changedFiles` / `diffChecklist` / `openQuestions` / `noticedButSkipped` を返す。

`openQuestions` があってもここでユーザーに確認して止まらない。未対応項目として最終報告（手順4）に含める。

### 3. 実装画面のスクショ取得（メインループ）

[`.claude/skills/shared/impl-screenshot.md`](../shared/impl-screenshot.md) を Read し、その手順に従う（dev サーバーの確保 → 撮影 → `ok:true` / `consoleErrors:[]` の確認。コンソールエラーがあれば実装エージェントに差し戻す）。このスキルでの撮影は `--full` の1枚でよい:

```bash
node verify/screenshot.mjs <route> verify/shots/<name>-impl.png --full
```

### 4. 人間チェック用の報告（メインループ・既定はここで終了）

**既定フローの終点。** 実装エージェントの結果を、[`.claude/skills/shared/human-check-report.md`](../shared/human-check-report.md) の**様式B（相違点対応報告）**と共通原則に従って整形し、人間が目視確認できる形で報告する。実装スクショのパス（手順3で取得した場合）と参照画像（`imagePath`）のパスを併記する。

AI による画像照合はここでは行わない。

### 5. AI 視覚検証（オプション・明示依頼時のみ）

ユーザーが「AI でも検証して」「verifier を回して」等と明示的に依頼した場合のみ、`design-diff-verifier` を Agent ツールで起動する。渡す情報:

- `referenceImage`（= `imagePath`）, `implShot`, `diffList`, `sourceFiles`（= 実装エージェントの `changedFiles`）, `round`

返ってくる JSON の `verdict` / `diffListStatus` / `findings` を手順4の報告に統合する。未解決や新規の critical/major があってもユーザーに提示するまでで止める（無断で自動修正ループしない）。

### 6. 後片付け（メインループ）

- 自分が起動した dev サーバーを停止する（起動済みを流用した場合は何もしない）。
- `verify/shots/` の一時画像は人間の目視確認が終わるまで残してよい（`.gitignore` 済み）。作業用の一時スクリプトは削除する。

## 注意

- **どの段階でも Figma MCP ツール（`mcp__figma-*` / `mcp__plugin_figma_*`）を呼ばない。** このスキルの存在意義そのもの。
- 色の相違は目視だけで確定しない（近似色は区別できないことがある）。diffList の具体値 → コード上の hex/トークン → ピクセルサンプリングの優先順で裏を取る。
- コミット・PR 作成は本スキルの範囲外。ユーザーから明示の指示があった時点で別途行う（`main` への直接コミットは禁止、フィーチャーブランチ → PR 経由。詳細はリポジトリルート `CLAUDE.md` のコミット規約に従う）。
