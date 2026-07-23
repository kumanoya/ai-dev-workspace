---
name: figma-implement-screen
description: Figma に定義された個別画面を、Component Library 仕様・画面遷移図(flow.md)・Figma のアノテーション（注釈）を踏まえてプロトタイプの画面として実装する。「この画面を実装して」「Figmaの〇〇画面を作る」「アノテーションを考慮して画面化」等で起動。scaffold-prototype / figma-component-library / figma-screen-flow の後に、画面ごとに繰り返し実行する。
---

# figma-implement-screen — Figma 画面の実装（アノテーション考慮）

Figma の個別画面を、既存の Component Library と画面遷移図を土台に、**アノテーション（Dev Mode の注釈）を必ず考慮して**実装するスキル。画面ごとに繰り返し呼ぶ。

## 前提

- `figma-component-library`（コンポーネント仕様・トークン・雛形）と `figma-screen-flow`（`specs/sample-app-v2/screens/flow.md`）が整備済み。
- ユーザーから **対象画面の Figma URL（node-id 付き）** を受け取る。未提供なら、flow.md の Screen Inventory から対象を選んで確認する。
- Component Library の specs（`specs/sample-app-v2/components/*.md`）に node-id が記録済みのコンポーネントは、`get_metadata` を再実行せずそこを参照する（同一ノードへの重複取得を避ける）。

## コスト方針：画面単位でサブエージェントに委譲

画面ごとの重い読み取り（`get_design_context`/`get_metadata`）・アノテーション収集・実装・ルーティング接続は、サブエージェント `figma-screen-implementer`（`.claude/agents/figma-screen-implementer.md`, model: sonnet）に画面単位で委譲する。メインループは対象画面を決めて起動するだけにし、Figma MCP ツールを直接呼ばない。

**視覚照合（`get_screenshot` によるピクセル比較）はこのスキルでは行わない。** 実装後は `figma-verify-screen` を呼ぶ（同じ画面に対して `get_screenshot` を二重に取得しないための一本化）。既定では AI による視覚照合は行われず、実装完了とブラウザ確認用 URL の案内で終了する（`figma-verify-screen` 側の既定フロー）。AI レビュー（`mode: report`）と自動修正ループ（`mode: loop`）は、ユーザーが明示的に依頼した場合のみのオプション工程。方針の詳細は `docs/ai-cost-optimization.md` §7。

## 手順

1. **対象の特定**（メインループ）: URL から fileKey / nodeId を抽出。flow.md でこの画面の役割・ルート・遷移元/先を確認する。

2. **サブエージェントの起動**（メインループ）: Agent ツールで `figma-screen-implementer` を起動する。渡す情報:
   - `route`
   - `fileKey` / `nodeId`
   - `flowExcerpt`（flow.md のうち当該画面の記述）
   - `componentSpecs`（関連する Component Library 仕様ファイルのパス一覧）
   - `proto`（既定 `sample-app-v2`）

   サブエージェントは metadata-first の読み取り（`get_metadata` で構造把握 → `get_design_context` は画面固有コンテンツ領域のノードに絞って1回）、Dev Mode アノテーションの収集・反映（「120分でセッション切れ→再認証画面へ」「必須項目は赤枠」等、実装上の挙動・制約・文言・バリデーション）、`src/components/organisms/` への実装、`src/App.tsx` のルーティング接続、`pnpm run lint` の実行までを行い、変更ファイル一覧・アノテーション対応状況・残課題を返す。

3. **レビューと次のステップ**（メインループ）: 戻り値の `changedFiles`/`annotationChecklist`/`openQuestions` を確認する。`openQuestions` があればユーザーに確認する。問題なければ **`figma-verify-screen` を起動する**。既定では AI 視覚照合は行われず、実装完了とブラウザ確認用 URL の案内を受けて終了する（この時点で完了とみなしてよい）。ユーザーが AI レビューを明示依頼している場合のみ、`figma-verify-screen` 側でそのフローに進む。

## 成果物

- `src/components/organisms/<画面>.tsx`（＋必要に応じ molecules/atoms、data/types 追加）。
- `src/App.tsx` のルート接続。
- 必要に応じ `specs/sample-app-v2/components/` の追記。

## 完了条件

`figma-screen-implementer` からの要約で `lintPassed: true`、`annotationChecklist` の全項目が `applied: true`、かつ後続の `figma-verify-screen` の呼び出しが完了していること — 既定はブラウザ確認用 URL の案内まで、AI レビュー明示依頼時（`mode: report`）はそのレポート提出まで、`mode: loop` 明示時は PASS まで（以降の修正判断は人間に引き継ぐ）。

## 繰り返し

flow.md の Screen Inventory の各画面に対して本スキルを繰り返し、プロトタイプ全体を完成させる。
