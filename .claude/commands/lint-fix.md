---
description: pnpm run lint を実行し、機械的な ESLint エラーを修正する（Haiku）
argument-hint: "[対象プロトタイプ（省略時は両方）]"
allowed-tools: Bash(pnpm run lint:*), Bash(pnpm -C:*), Read, Edit, Grep, Glob
model: haiku
---

ESLint の指摘を機械的に解消する。**独立タスクとして（タスクの切れ目・新規セッションで）実行する**こと — コマンドレベルのモデル切替は実行中セッションの履歴を Haiku で読み直すため、長い実装セッションの途中に挟まない。

## 手順

1. 対象を決める。`$ARGUMENTS` があればそのプロトタイプ、なければ `prototypes/sample-app` と `prototypes/sample-app-v2` の両方。
2. 各プロトタイプで `pnpm -C prototypes/<name> run lint` を実行する。
3. エラーを機械的に修正する（未使用 import の削除、`const` 化、明示的な型注釈の追加など）。**ロジックの変更・リファクタリングはしない**。
4. 判断が要る指摘（ルール無効化が妥当か、設計変更が必要か等）は修正せず、最後にまとめて報告する。
5. 再度 lint を実行してクリーンになったことを確認し、修正件数・残件を報告する。

## 制約

- `eslint-disable` コメントの追加・ESLint 設定の変更は勝手にしない（報告のみ）。
- コミットはしない（必要ならユーザーが `/commit` を使う）。
