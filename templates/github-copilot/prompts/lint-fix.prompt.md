---
description: pnpm run lint を実行し、機械的な ESLint エラーを修正する
mode: agent
model: Claude Haiku 4.5
tools: ['codebase', 'editFiles', 'runCommands']
---

# lint-fix — ESLint の機械的な修正

ESLint の指摘を機械的に解消する。**新しいチャットセッションで（タスクの切れ目に）実行する**こと — 長い実装セッションの途中に挟まない。

## 手順

1. 対象を決める。チャットメッセージに対象プロトタイプの指定があればそれ、なければ `prototypes/sample-app` と `prototypes/sample-app-v2` の両方。
2. 各プロトタイプで `pnpm -C prototypes/<name> run lint` を実行する。
3. エラーを機械的に修正する（未使用 import の削除、`const` 化、明示的な型注釈の追加など）。**ロジックの変更・リファクタリングはしない**。
4. 判断が要る指摘（ルール無効化が妥当か、設計変更が必要か等）は修正せず、最後にまとめて報告する。
5. 再度 lint を実行してクリーンになったことを確認し、修正件数・残件を報告する。

## 制約

- `eslint-disable` コメントの追加・ESLint 設定の変更は勝手にしない（報告のみ）。
- コミットはしない（必要なら人間が `/commit` を使う）。
- lint の実行以外のコマンドは実行しない。
