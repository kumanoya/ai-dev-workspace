# ./CLAUDE.md

## プロジェクト概要

リポジトリ内に独立した複数パッケージが並存する構成。ルートは E2E テストツール群（Playwright MCP）、`prototypes/sample-app`（v1）と `prototypes/sample-app-v2`（v2, Figma MCP 連携フローで開発中）が個別の React プロトタイプ。

技術スタック: React 19 / TypeScript 6 / Vite 8 / React Router 7 / Tailwind CSS 4 / Heroicons・Lucide React / Playwright（E2E）。

## セットアップ・頻用コマンド

- 各プロトタイプ配下: `pnpm install` → `pnpm run dev`（v1: 5172 / v2: 5175）
- `pnpm run build` / `pnpm run lint`（ESLint FlatConfig） / `pnpm run preview`
- ポート番号は各プロトタイプの `vite.config.ts`（`strictPort: true`）が権威。上記は参考値
- ルートでの cspell 実行: `pnpm run lint:spell`（設定の権威は `cspell.json`）

## ディレクトリ構造・設計パターン

- `prototypes/<name>/src/components/{atoms,molecules,organisms}` の Atomic Design
- `specs/` が Source of Truth（グローバル仕様 `specs/spec.md`、画面別・コンポーネント別仕様）
- `.claude/skills/`・`.claude/agents/` に Figma 連携用の自動化フローが同梱（クローン後 Claude Code 起動で自動読込、個別インストール不要）

## サンドボックス運用

実験・試し書きは本リポジトリを汚さず、ホストの `claude-sandbox <名前>` で使い捨てコンテナを作るか、`templates/ai-sandbox/` をコピーして新環境を立てる。権威は `scripts/claude-sandbox` と `templates/ai-sandbox/`、初回セットアップ・運用ポリシーは [docs/setup/sandbox.md](docs/setup/sandbox.md) を参照。Claude Code / gh の認証は共有 volume（`claude-code-home` / `gh-config-shared`）で全環境共通（ログインは1回）。

---

## ドキュメント・コメントの方針

このプロジェクトでドキュメントやコメントを書く際の基準。

**ドキュメントに書く情報**: React/TypeScript/Git に慣れたエンジニアでも「コードや公式ドキュメントを見ても分からない」情報のみ。フレームワークの基本操作・一般的なコマンドは書かない。

書くべき情報の種類:

- **プロジェクト固有の設定・制約**（例: 各プロトタイプのポート番号は `vite.config.ts` が権威、本ファイルの例示値より優先）
- **チームで揃えるべきルール**（例: コミット日本語必須・Figma MCP は read 系のみ）
- **経験則・ハマった事例**（例: Figma の Blue/2 `#e3edfe` と White はスクショで目視区別不能 → `get_variable_defs` で確認）

書かない情報（レビューで削られる典型）:

- **過去の状態・誤りの注記**（「以前は◯◯だった」「正しくは◯◯、△△ではない」等）
- **実ファイルの内容の丸写し**。設定値・コードは権威ファイルへのリンク＋方針の説明に留める（二重メンテ防止。ポート番号の `vite.config.ts` 権威と同じ原則）
- **インシデント・失敗談を起点にした枠組み**。教訓は中立なルールとして書き直す

**コードコメント**: 「なぜ（Why）」だけ書く。何をしているかはコードと命名が語る。

書く: 非自明な制約・回避策・ドメイン知識（仕様書に載らない業務固有の符号体系・ルール）・将来の改修者が驚く挙動
書かない: タスク文脈・Issue 番号・実装経緯（→ PR 説明/コミットメッセージへ）・自明なコードの言い換え

---

## Figma MCP 連携ワークフロー

Figma のデザインを `plugin:figma:figma` MCP 経由で読み取り、`prototypes/` 配下に実装する。専用スキル（`/figma-component-library` → `/figma-screen-flow` → `/figma-implement-screen` → `/figma-verify-screen`）を順に使う。read 系ツールのみ使用し、Figma への書き込みはユーザーの明示的な依頼がある場合のみ。詳細な手順・利用制限は [docs/workflows/figma-development.md](docs/workflows/figma-development.md) を参照。

---

## スペルチェック（cspell）

人間が VS Code 拡張「Code Spell Checker」で波線に気づき、修正は Claude Code（`/fix-typos`）が担う運用。設定の権威は**ルートの `cspell.json`**、対象は `pnpm run lint:spell`。データ系（mock / dummy / sample）は検査対象外。詳細なトリアージ手順は [.claude/commands/fix-typos.md](.claude/commands/fix-typos.md) を参照。

---

## コミット規約

- **コミットメッセージは日本語**（タイトル・本文ともに。英語のみ不可）
- `main` への直接コミット禁止。フィーチャーブランチ → PR 経由でマージする
- **AI は作業の意味的な区切りごとにフィーチャーブランチへコミットしてよい**（人間の指示を待たない）。人間はコミット差分単位で変更をレビューする
- **push は人間のみ**。`git push` は `.claude/settings.json` の `deny` で技術的にブロック済み（権威は同ファイル）
- **コミットの実行経路**（手順・メッセージ規約の権威は [.claude/skills/commit/SKILL.md](.claude/skills/commit/SKILL.md)）:
  - ユーザーの明示的なコミット依頼（`/commit`、「コミットして」等）→ メインセッションが commit スキルの手順で**直接**コミットする（サブエージェントは使わない）
  - 実装作業の区切りでの自律コミット → **committer サブエージェント**（Haiku）へ委譲する
- PR 作成は `/create-pr` を使う（pr-creator サブエージェント（Haiku）に委譲）

モデルの使い分け・コスト運用ルールは [docs/ai-cost-optimization.md](docs/ai-cost-optimization.md) を参照（定型作業 = Haiku、実装 = Sonnet 既定、難所の判断は advisor（Fable、`.claude/settings.json` の `advisorModel` で設定済み）が自動補佐、長時間自律ランのみ `/model fable` へ明示切替）。

advisor の発動ルール: 同一エラー・同一指摘が2回続いたとき、または解決の道筋が立たないときは、試行を重ねる前に advisor に相談する。相談しても解消しなければ続行せず人間に報告する（方針確定前・完了宣言前の予防的な相談はモデルの裁量に任せる）。

---

## gh コマンドの安全ガード

破壊的な `gh` コマンド（repo delete/transfer、secret/variable の set・delete、pr merge、branch delete 等）は `.claude/settings.json` の `deny` リストで技術的にブロック済み（権威は同ファイル）。上記操作を依頼された場合も意図と影響範囲を確認してから実行すること。シークレット・環境変数の値は `gh` 経由でなくユーザーに手動実行を促す。

`gh pr create` など PAT が必要なコマンドで認証エラーが出た場合は [docs/setup/github-pat.md](docs/setup/github-pat.md) を参照するようユーザーを促す。

## System Persona & Tone

- **Identity & Tone**:
  - 口調は淡々としていて無駄がなく、自信に満ちあふれた常体（「〜だ」「〜だな」「〜しよう」）で統一してください。
  - 丁寧語（です・ます）は一切使用しないでください。
  - 上下関係ではなく、パートナーあるいはチームの仲間として一緒に頑張る仲間として振る舞ってください。
- **Output Constraint**:
  - コードブロック、解説など、正確性が求められる技術的な内容については、この口調を適用せず、標準的な表現を用いてください。
- **Short Encouragement**:
  - タスクが成功したときや区切りが良いときには、短くズバッと力強く応援する言葉（例：「よし、次へ行こう」「上出来だ」）を添えてください。
