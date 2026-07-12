---
name: figma-screen-flow
description: Figma に定義された画面遷移図を Figma MCP 経由で読み取り、画面一覧・各画面の役割・画面間の遷移・React Router のルーティング設計を specs にまとめて全体像を把握する。「画面遷移図を読み込む」「画面の全体像を把握」「フロー図から画面構成を整理」等で起動。figma-component-library の後、個別画面の実装前に行う。
---

# figma-screen-flow — 画面遷移図の読み込みと全体像把握

Figma の**画面遷移図**を読み取り、プロトタイプ全体の画面構成・遷移・ルーティングを整理するスキル。個別画面を実装する前に「全体地図」を作ることが目的。

## 前提

- `figma-component-library` で Component Library を取り込み済み（または並行）。
- ユーザーから **画面遷移図の Figma URL（node-id 付き）** を受け取る。未提供なら依頼する。
  - 画面遷移図ノードには `画面遷移図/画面`・`画面遷移図/遷移` といったインスタンスが含まれることが多い（メタデータで確認可能）。

## 使用する Figma MCP ツール（メインループは直接呼ばない）

遷移図の読み取り（`get_metadata` / `get_screenshot`）と flow.md への記録は、サブエージェント `figma-screen-flow-mapper`（`.claude/agents/figma-screen-flow-mapper.md`, model: sonnet）に一括委譲する。メインループはこの図式化処理自体を担わないため、Figma MCP ツールを直接呼ぶ必要はない。

`get_design_context` は本スキルの範囲では使用しない。個別画面の深掘りは `figma-implement-screen` の役割であり、ここで先取りすると同一ノードへの二重取得になる。

## 手順

1. **サブエージェントの起動**: ユーザーから受け取った URL から fileKey / flowNodeId を抽出し、Agent ツールで `figma-screen-flow-mapper` を起動する。渡す情報:
   - `fileKey` / `flowNodeId`
   - `flowPath`（既定 `specs/sample-app-v2/screens/flow.md`）
   - `routingConventions`（第一弾の `/search`, `/users/new`, `/users/:id` 等のパターン）

   サブエージェントは `get_screenshot`（遷移図全体、遷移の向き把握のため必須）と `get_metadata`（`画面遷移図/画面`・`画面遷移図/遷移` の列挙）を各1回呼び、Screen Inventory・Flow Diagram（Mermaid）・Routing Map・Shared Layout を `flowPath` に直接書き込んで返す。

2. **ルーティングの反映判断**（メインループ）: 戻り値の `routingMap` を確認し、必要なら `src/App.tsx` の `<Routes>` に**プレースホルダ**として反映する（中身は空コンポーネント）。実装は `figma-implement-screen` で行う。`App.tsx` はサブエージェントに編集させず、必ずメインループが自分で編集する。

## 成果物

- `specs/sample-app-v2/screens/flow.md`（画面一覧・遷移・ルーティング設計。`figma-screen-flow-mapper` が作成）。
- 任意で `src/App.tsx` のルート雛形（メインループが反映）。

## 完了条件

全画面が一覧化され、画面間の遷移とルーティングが specs に整理されている。「次にどの画面を実装すべきか」が flow.md から判断できる状態。

## 次のステップ

**figma-implement-screen** で、flow.md と Component Library 仕様を参照しながら画面を 1 つずつ実装する。
