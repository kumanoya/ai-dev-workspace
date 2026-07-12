---
name: figma-component-library
description: Figma の Component Library を Figma MCP 経由で読み取り、デザイントークン（@theme）・コンポーネント仕様（specs Markdown）・最小実装の雛形（atoms/molecules .tsx）として第二弾プロトタイプに定義する。「FigmaのコンポーネントライブラリをVに取り込む」「デザイントークンを抽出」「コンポーネント定義を作る」等で起動。scaffold-prototype の後、画面実装の前に行う。
---

# figma-component-library — Figma Component Library の取り込み

Figma の Component Library を読み取り、プロトタイプの**コンポーネント作成に必要な情報**を 3 つの成果物として定義するスキル。仕様駆動（`specs/` が Source of Truth）に従い、**仕様 → トークン → 雛形**の順で作る。

## 前提

- `scaffold-prototype` で対象プロトタイプ（既定 `prototypes/sample-app-v2`）の土台が作成済み。
- Figma MCP（`plugin:figma:figma`）が認証済み（`claude mcp list` で `✔ Connected`）。
- ユーザーから **Component Library の Figma URL（node-id 付き）** を受け取る。未提供なら依頼する。

## 使用する Figma MCP ツール（メインループが直接使うのは read 系の2つのみ）

- `get_metadata` — ライブラリ配下の構造把握。`COMPONENT` / `COMPONENT_SET` ノードの一覧（id・名前・バリアント）を取得。
- `get_variable_defs` — デザイン変数（色・タイポグラフィ・スペーシング・radius 等のトークン）を取得。

`get_design_context`（個別コンポーネントの構造・参照コード・アセットURL）と `get_screenshot`（バリアント差分の視覚確認）はメインループでは呼ばない。コンポーネント数だけこの2つを繰り返すとメインループのトークン消費が線形に膨らむため、**サブエージェント `figma-component-extractor` に委譲**する（下記手順3）。

## コスト方針：委譲とバッチ

メインループは「ライブラリ全体の把握」と「トークンの `@theme` への反映」だけを担当するオーケストレーターに徹し、コンポーネント単位の重い読み取り・ファイル生成は `figma-component-extractor`（`.claude/agents/figma-component-extractor.md`, model: sonnet）に任せる。これは `figma-verify-screen` が `figma-screen-reviewer` に視覚QAを委譲しているのと同じ考え方で、メインループが受け取るのはサブエージェントからの**コンパクトな要約 JSON のみ**（生の `get_design_context` レスポンスは受け取らない）。

## 手順

1. **ライブラリ構造の把握**（メインループ）: URL から fileKey と nodeId を抽出し `get_metadata` を実行。`COMPONENT` / `COMPONENT_SET` を列挙し、コンポーネント名・バリアント軸（例: `Button` の variant=primary/secondary、size=… 等）と node-id を一覧化する。出力が大きすぎて token 上限を超える場合は結果がファイルに退避されるので、`jq` / `python` で name・id だけ抽出する。

2. **デザイントークンの抽出と反映**（メインループ）: `get_variable_defs` でトークンを取得し、`src/index.css` の `@theme` ブロックに Tailwind v4 流儀で反映する。
   - 色: `--color-<name>: <hex>;`、タイポ: `--font-*`、スペーシング: `--spacing-*`、角丸: `--radius-*` など。
   - 第一弾の `@theme`（`--font-sans: "Noto Sans JP"` 等）を踏襲しつつ、Figma 由来トークンを追加。
   - ハードコード値ではなく**トークン参照**を基本とする（画面実装時に `bg-[--color-...]` / 既定の Tailwind ユーティリティで参照）。

3. **コンポーネント単位の抽出をサブエージェントに委譲**: 手順1で列挙した各コンポーネントについて、Agent ツールで `figma-component-extractor` を起動する。**最大3件を1メッセージ内で並列起動**し、バッチごとに完了を待って次のバッチへ進む。渡す情報:
   - `componentName`（例 `Button`）
   - `nodeId` / `fileKey`
   - `specPath`（例 `specs/sample-app-v2/components/Button.md`）
   - `tsxPath`（例 `src/components/atoms/Button.tsx`）
   - `existingTokens`（手順2で `@theme` に反映済みのトークン名一覧）
   - `variantAxes`（手順1の `get_metadata` で判明済みのバリアント軸と値。例 `variant=primary/secondary, size=s/m/l`。サブエージェント側での再導出を不要にする）

   サブエージェントは対象コンポーネント1件分の `get_design_context`（必要なら軽量な `get_screenshot`）を取得し、仕様 Markdown（Overview / Anatomy・Layout / Variants & States / Tokens / Props / Figma参照）と最小実装の tsx 雛形（`export const ComponentName: React.FC<ComponentNameProps>`、Tailwind は `base` + `variants` + クラス合成、トークンは `@theme` 経由）を直接ファイルに書き込んで返す。`@theme` 自体は編集させない（並列書き込み競合を避けるため）。

4. **トークンの追記**（メインループ）: 各サブエージェントの戻り値 `newTokensNeeded` を集約し、未定義トークンがあれば `@theme` に一括で追記する。

5. **整合チェック**（メインループ）:
   ```bash
   cd prototypes/sample-app-v2
   pnpm run lint
   pnpm run dev   # トークン反映・雛形の表示を確認
   ```

## 成果物

- `src/index.css` の `@theme` にデザイントークン（メインループが集約反映）。
- `specs/sample-app-v2/components/*.md` のコンポーネント仕様（`figma-component-extractor` が作成）。
- `src/components/atoms|molecules/**/*.tsx` の最小実装雛形（`figma-component-extractor` が作成）。

## 完了条件

全コンポーネントについて `figma-component-extractor` からの要約が揃い、`newTokensNeeded` が `@theme` に反映済みで、`pnpm run lint` がパス、`pnpm run dev` で雛形が表示できる。

## 次のステップ

**figma-screen-flow** で画面遷移図を読み、画面全体像を把握する。
