---
description: プロトタイプ実装（React / TypeScript / Tailwind）の規約
applyTo: "prototypes/**/*.ts,prototypes/**/*.tsx,prototypes/**/*.css"
---

# プロトタイプ実装の規約

- コンポーネントは `src/components/{atoms,molecules,organisms}` の Atomic Design 配置に従う。新規コンポーネントは既存の粒度・命名パターンに合わせる
- `specs/` が Source of Truth。画面・コンポーネントの仕様は対応する specs ファイルを参照してから実装する
- 色は各プロトタイプの `src/index.css` の `@theme` ブロックにあるデザイントークン（`--color-*`）を優先して使う（例: `bg-blue-2`）。一致するトークンが無い場合のみ直値 `bg-[#xxxxxx]` を使い、デザイン上の変数名をコメントで併記する（既存パターンに倣う）
- コードコメントは「なぜ（Why）」だけ書く。何をしているかはコードと命名が語る。タスク文脈・Issue 番号・実装経緯は書かない（それは PR 説明・コミットメッセージへ）
- 変更後は対象プロトタイプで `pnpm run lint && pnpm run build` を実行し、両方パスすることを確認する
- dev サーバーのポート番号は各プロトタイプの `vite.config.ts`（`strictPort: true`）が権威。ドキュメントの例示値より優先する
