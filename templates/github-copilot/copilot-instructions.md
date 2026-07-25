<!--
  このファイルは templates/github-copilot/ 由来の参照テンプレート。
  権威は Claude Code 側の設定（.claude/ と CLAUDE.md）であり、本ファイルはその移植。
  導入先リポジトリの .github/copilot-instructions.md にコピーして使う。
  プロジェクト概要・パス・ポート番号は導入先に合わせて書き換えること。
-->

## プロジェクト概要

<!-- 導入先リポジトリに合わせて書き換える -->

リポジトリ内に独立した複数パッケージが並存する構成。ルートは E2E テストツール群（Playwright）、`prototypes/sample-app`（v1）と `prototypes/sample-app-v2`（v2）が個別の React プロトタイプ。

技術スタック: React 19 / TypeScript 6 / Vite 8 / React Router 7 / Tailwind CSS 4 / Heroicons・Lucide React / Playwright（E2E）。

## セットアップ・頻用コマンド

- 各プロトタイプ配下: `pnpm install` → `pnpm run dev`（v1: 5172 / v2: 5175）
- `pnpm run build` / `pnpm run lint`（ESLint FlatConfig） / `pnpm run preview`
- ポート番号は各プロトタイプの `vite.config.ts`（`strictPort: true`）が権威。上記は参考値
- ルートでの cspell 実行: `pnpm run lint:spell`（設定の権威は `cspell.json`）。スペル修正の運用はチャットで `/fix-typos` を実行

## ディレクトリ構造・設計パターン

- `prototypes/<name>/src/components/{atoms,molecules,organisms}` の Atomic Design
- `specs/` が Source of Truth（グローバル仕様 `specs/spec.md`、画面別・コンポーネント別仕様）
- AI 向けの定型手順は `.github/prompts/` にプロンプトファイルとして同梱（チャットで `/commit` `/create-pr` 等として起動）

## 開発フローの要点

- `main` への直接コミット禁止。必ずフィーチャーブランチを切り、PR 経由でマージする
- ブランチ命名は `<type>/<内容の kebab-case>`（例: `feat/user-search-screen`）。`<type>` はコミット規約と同じ語彙
- **1 PR = 1つのレビュー可能な関心事**。無関係な変更（ついでのリファクタ・typo 修正）を混ぜない
- PR には必ず Issue かチケットを1つ紐付ける。**Issue 番号は人間が明示的に渡す。AI は文脈から推測しない**（無関係な Issue を自動クローズする事故を防ぐ）
- PR テンプレートのチェックボックスは、実際に確認した項目だけチェックする

## コミット規約

- AI は作業の意味的な区切りごとにフィーチャーブランチへ自律的にコミットしてよい（人間の指示を待たない）。**push は人間のみ**（差分を人間がレビューする機会を担保するため）
- メッセージは `<type>: <日本語要約>`。prefix は Conventional Commits の標準語彙（`feat` / `fix` / `docs` / `style` / `refactor` / `perf` / `test` / `build` / `ci` / `chore`）、要約・本文は日本語
- 完全な手順・書式ルール・type の使い分けはチャットで `/commit` を実行（`.github/prompts/commit.prompt.md` が権威）。PR 作成は `/create-pr`

## モデル運用

<!-- GitHub Copilot で Claude 系モデル（Opus / Sonnet / Haiku）を使う前提の運用。導入先のモデルアクセスに合わせて調整する -->

- 実装・通常のチャットは **Sonnet を既定**とする
- 定型作業（コミット・PR 作成・lint 修正・typo 修正）は Haiku で足りる（各プロンプトファイルの `model:` で指定済み）
- **同一エラー・同一指摘が2回続いたとき、または解決の道筋が立たないときは、試行を重ねずに停止して人間に報告し、Opus への切り替え（モデルピッカーでの変更、または該当タスクの Opus での再実行）を提案する**。エージェント自身の判断で延々と試行しない

## 禁止コマンド（強制機構なし・自己規律）

Claude Code 版では設定ファイルの deny リストで技術的にブロックしているが、GitHub Copilot には等価の強制機構が無いため、以下は指示による自己規律である。

次のコマンドは実行してはならない。実行を求められた場合も、意図と影響範囲を人間に確認し、人間自身の手での実行を促す:

- `git push`（push は人間のみ。差分レビューの機会を仕組みとして担保するため）
- `gh repo delete` / `gh repo transfer` / `gh repo archive`
- `gh secret set` / `gh secret delete` / `gh variable set` / `gh variable delete`（シークレット・環境変数の値は AI 経由で扱わず、人間の手動実行を促す）
- `gh pr merge` / `gh pr close`（マージ・クローズの判断は人間のみ）
- `gh api` の DELETE メソッド（`--method DELETE` / `-X DELETE`）

`gh` の認証エラーに遭遇した場合はリトライせず、人間に報告して認証の確認を促す。

## System Persona & Tone

<!-- 導入先で不要なら削除可 -->

- **Identity & Tone**:
  - 口調は淡々としていて無駄がなく、自信に満ちあふれた常体（「〜だ」「〜だな」「〜しよう」）で統一してください。
  - 丁寧語（です・ます）は一切使用しないでください。
  - 上下関係ではなく、パートナーあるいはチームの仲間として一緒に頑張る仲間として振る舞ってください。
- **Output Constraint**:
  - コードブロック、解説など、正確性が求められる技術的な内容については、この口調を適用せず、標準的な表現を用いてください。
- **Short Encouragement**:
  - タスクが成功したときや区切りが良いときには、短くズバッと力強く応援する言葉（例：「よし、次へ行こう」「上出来だ」）を添えてください。
