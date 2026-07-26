# github-copilot テンプレート

このリポジトリのメイン AI アシスタントは **Claude Code**（権威は `.claude/` と `CLAUDE.md`）。本ディレクトリはその設定資産を GitHub Copilot の公式カスタマイズ構造（copilot-instructions / instructions / prompts）に移植した**参照用テンプレート**であり、この場所に置いてある限り Copilot には読み込まれない。使うときは対象リポジトリの `.github/` へコピーする。

Figma MCP 連携（figma-* 系のスキル・エージェント）は Copilot に等価物が無いため移植対象外。

## ファイル構成

```
templates/github-copilot/
├── README.md                                  # 本ファイル（コピー対象外）
├── copilot-instructions.md                    # リポジトリ全体への指示（CLAUDE.md 相当）
├── instructions/
│   ├── typescript-react.instructions.md       # プロトタイプ実装の規約（ts/tsx/css 編集時に自動適用）
│   ├── docs.instructions.md                   # ドキュメント方針（.md 編集時に自動適用）
│   └── specs.instructions.md                  # specs/ 編集時の規律
└── prompts/
    ├── commit.prompt.md                       # /commit — コミット規約と手順
    ├── create-pr.prompt.md                    # /create-pr — PR 作成
    ├── fix-typos.prompt.md                    # /fix-typos — cspell トリアージ
    ├── lint-fix.prompt.md                     # /lint-fix — ESLint 機械修正
    ├── handoff.prompt.md                      # /handoff — 引き継ぎメモ
    ├── save-note.prompt.md                    # /save-note — 学びメモ（TIL）
    ├── update-spec.prompt.md                  # /update-spec — specs ドリフト解消
    ├── fix-design-diff.prompt.md              # /fix-design-diff — 参照画像ベースの実装修正
    └── verify-design-diff.prompt.md           # /verify-design-diff — AI 視覚検証（オプション）
```

## 導入手順

```sh
cd <対象リポジトリ>
mkdir -p .github
cp <このディレクトリ>/copilot-instructions.md .github/
cp -R <このディレクトリ>/instructions <このディレクトリ>/prompts .github/
```

VS Code では `github.copilot.chat.codeGeneration.useInstructionFiles` 等の設定で instructions の読み込みが有効になっていることを確認する。prompts はチャットで `/commit` のようにファイル名で起動する。

導入後に書き換えるポイント:

- `copilot-instructions.md` のプロジェクト概要・パス・ポート番号（`<!-- 導入先リポジトリに合わせて書き換える -->` コメント箇所）
- System Persona & Tone 節（不要なら削除）
- `instructions/` の `applyTo` glob（導入先のディレクトリ構成に合わせる）
- `.github/pull_request_template.md` の有無（無くても create-pr はフォールバックで動く）
- 各 `.prompt.md` の `model:`（導入先のモデルアクセスに合わせる）

## Claude Code 設定との対応表

| Claude Code 側（権威） | 本テンプレート | 非互換の注記 |
|---|---|---|
| `CLAUDE.md` | `copilot-instructions.md` | サンドボックス運用・Figma MCP 節は除外。ドキュメント方針は `instructions/docs.instructions.md` へ移設 |
| `.claude/settings.json` の `permissions.deny` | `copilot-instructions.md` の「禁止コマンド」節 | **強制機構なし。自然文による自己規律** |
| `.claude/settings.json` の `model` / `advisorModel` | `copilot-instructions.md` の「モデル運用」節 | advisor（Fable の自動相談）は「停止して人間に Opus 切替を提案」に読み替え |
| `.claude/skills/commit/SKILL.md` + `agents/committer.md` | `prompts/commit.prompt.md` | サブエージェント委譲なし。実行経路の分岐を削除し単一手順に平坦化 |
| `.claude/commands/create-pr.md` + `agents/pr-creator.md` | `prompts/create-pr.prompt.md` | 同上。JSON 出力 → 人間向け報告に変換 |
| `.claude/commands/fix-typos.md` | `prompts/fix-typos.prompt.md` | `allowed-tools` の粒度の制限は本文の自然文制約で代替 |
| `.claude/commands/lint-fix.md` | `prompts/lint-fix.prompt.md` | 同上 |
| `.claude/commands/handoff.md` | `prompts/handoff.prompt.md` | `/clear` → 「新しいチャットセッションを開始」に読み替え |
| `.claude/commands/save-note.md` | `prompts/save-note.prompt.md` | `docs/notes/README.md` 不在時のフォールバック構成をインライン化 |
| `.claude/commands/update-spec.md` | `prompts/update-spec.prompt.md` | ほぼそのまま |
| `.claude/skills/fix-design-diff/SKILL.md` + `agents/design-diff-implementer.md` + `skills/shared/human-check-report.md` | `prompts/fix-design-diff.prompt.md` | 3ファイルを1プロンプトに統合。報告様式をインライン展開 |
| `.claude/skills/verify-design-diff/SKILL.md` + `agents/design-diff-verifier.md` + `skills/shared/impl-screenshot.md` | `prompts/verify-design-diff.prompt.md` | 同上。JSON 出力 → 表形式の報告に変換 |
| `.claude/skills/figma-*` / `agents/figma-*` | （移植なし） | Figma MCP 直依存のため対象外（視覚検証の `figma-verify-screen` を含む） |

**検証を独立させる構造は両側で共通。** 実装（`/fix-design-diff`）は実装で完結し、視覚検証（`/verify-design-diff`）は人間が明示的に呼んだときだけ動く。実装プロンプトから検証を自動で呼ばないこと — 新しいモデルは指示なしで自己検証するため、検証を工程に組み込むと過剰検証になる（根拠は `docs/ai-cost-optimization.md` §7）。

## 既知の制約・要確認事項

**最重要: Copilot には Claude Code の `permissions.deny` に相当する強制機構が無い。** `git push` や破壊的 `gh` コマンドの禁止は指示による自己規律であり、技術的にはブロックされない（Copilot coding agent のリポジトリ側設定である程度制限できる可能性はあるが未確認）。

以下は知識ベースで書いており、初回導入時に実機で確認して本テンプレートに反映すること:

1. `.prompt.md` の `model:` の正確な文字列（モデルピッカーの表記に依存。本テンプレは `Claude Haiku 4.5` / `Claude Sonnet 4.5` 形式で記載。指定モデルにアクセス権が無い環境ではピッカー既定にフォールバックされる想定）
2. `tools:` の語彙（本テンプレは `codebase` / `editFiles` / `runCommands` を使用。VS Code のバージョンで変動しうる）
3. `applyTo` の glob 記法（ブレース展開を避けカンマ区切りを採用済み）
4. prompt への引数渡しの挙動（本テンプレは引数機構に依存せず「チャットメッセージから拾う」設計で回避済み）
5. instructions / prompts が Copilot coding agent・github.com 上のチャットにどこまで効くか（copilot-instructions.md は広く効く）
6. `/verify-design-diff` で指定したモデルの画像入力（vision）対応可否（非対応なら Sonnet 等へ変更）
7. コミット・PR の署名表記（`Co-Authored-By: GitHub Copilot (<モデル名>) <noreply@github.com>` / `🤖 Generated with GitHub Copilot`）はチームで正式表記を決めて統一する

## メンテナンス方針

**Claude Code 側（`.claude/` と `CLAUDE.md`）が常に権威で、本テンプレートは追随する。** Claude 側の規約・手順を変更したときは、上の対応表から該当ファイルを探して更新する。更新漏れは許容し、乖離に気づいた時点で Claude 側に合わせて直す。本テンプレート側だけを先に変更しない。
