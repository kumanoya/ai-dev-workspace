# オンボーディングガイド — このリポジトリで AI 駆動開発を始める人へ

本リポジトリに参加するチームメンバーが最初に読む全体マップ。各トピックの詳細・実値は権威ドキュメント（各節のリンク先）が正であり、本書は「何がどこにあり、なぜそうしているか」の要約に徹する。

対象読者: React / TypeScript / Git には慣れているが、本リポジトリの AI 駆動開発の流儀は知らないエンジニア。

---

## 1. このリポジトリは何か

Claude Code × Figma MCP による **AI 駆動のプロトタイプ開発ワークスペース**。単なるコード置き場ではなく、「AI にどう仕事を任せ、人間はどこで介入するか」の運用ルール・自動化フロー・コスト方針までをリポジトリに同梱して、チーム全員が同じ構成で開発することを狙っている。

- 複数の独立パッケージが並存する構成。ルートは E2E テストツール群、`prototypes/` 配下に個別の React プロトタイプが入る（構成の詳細は [CLAUDE.md](../CLAUDE.md) 参照）
- **`specs/` が Source of Truth**。Figma から読み取った仕様・デザイントークン・画面構成は specs に永続化し、実装は specs を参照する。「同じ情報を Figma から二度取らない」がコストと品質の両面の基本原則
- Figma デザインの読み取り → コンポーネント定義 → 画面実装 → 検証、の一連のフローが専用スキル・サブエージェントとして `.claude/` に定義済み

## 2. 環境構築

- 開発環境は Dev Container。セットアップ手順は [README.md](../README.md) 参照
- Claude Code / gh / SSH の認証は共有 volume 方式で、**ログイン・鍵登録は全環境を通じて1回だけ**
- 実験・試し書きは本リポジトリを汚さず、使い捨てコンテナ（`claude-sandbox`）か `templates/ai-sandbox/` のコピーで行う。手順と運用ポリシーは [docs/setup/sandbox.md](setup/sandbox.md) 参照

## 3. Claude Code の利用で意識すること

### 設定はリポジトリ同梱 — 個別セットアップ不要

`.claude/` 配下（skills / agents / settings.json）はリポジトリにコミットされており、クローンして Claude Code を起動すればチーム全員が同じスキル・同じエージェント・同じ安全ガードで動く。個人の上書きは `.claude/settings.local.json` で行い、共有設定は勝手に変えない（変えるなら PR で）。

### コミット・PR の規約

権威は [CLAUDE.md](../CLAUDE.md)「コミット規約」と [.claude/skills/commit/SKILL.md](../.claude/skills/commit/SKILL.md)。要点:

- **コミットメッセージは日本語**。`main` 直接コミット禁止、フィーチャーブランチ → PR
- **push できるのは人間だけ**。AI の `git push` は設定で技術的にブロック済み
- AI は作業の意味的な区切りごとに自律コミットしてよい。人間はコミット差分単位でレビューする
- PR 作成は `/create-pr`、明示的なコミット依頼は `/commit`

### 安全ガード

- 破壊的な `gh` コマンド（repo delete、pr merge、secret 操作等）は `.claude/settings.json` の deny リストでブロック済み（権威は同ファイル）
- **Figma MCP は read 系ツールのみ**。Figma への書き込みはユーザーの明示的な依頼がある場合に限る
- 自律ループには必ず停止条件を入れる文化（§4 参照）

### 主要スラッシュコマンド早見表

| コマンド / スキル | 用途 |
|---|---|
| `/commit` | 現在の変更を日本語規約でコミット |
| `/create-pr` | 現在のブランチから main への PR 作成 |
| `/fix-typos` | cspell の指摘をトリアージして修正 |
| `/lint-fix` | ESLint の機械的なエラー修正 |
| `/handoff` | セッションの作業状態を引き継ぎメモ化（`/clear` 前に） |
| `/update-spec` | 実装と specs のドリフトを検知して spec 側を追随 |
| `/figma-component-library` → `/figma-screen-flow` → `/figma-implement-screen` → `/figma-verify-screen` | Figma 連携の4段フロー（この順に使う） |

## 4. AI 駆動開発の指針

### 役割分担の思想

- **薄いメインループ + 単位仕事のサブエージェント委譲**。メインセッションはオーケストレーション（指示・統合・判断）に徹し、コンポーネント1件・画面1枚といったまとまった単位をサブエージェントに渡す
- **権限の分離を崩さない**。レビュアー系エージェントは Read-only（指摘のみ・修正しない）、実装エージェントは検証しない。相互に役割を侵食させないことが暴走防止になる
- 定型作業（コミット・PR 作成・lint 修正）は安価なモデルのサブエージェントに委譲し、メインセッションの文脈を太らせない

### モデルの使い分け（4段構成）

判断基準・使い分けの権威は [docs/ai-cost-optimization.md](ai-cost-optimization.md) §3。概要:

| モデル | 役割 |
|---|---|
| Haiku | 定型作業（コミット・PR・lint・typo） |
| Sonnet | **既定**。メインループとほぼ全サブエージェント |
| Opus | advisor でも改善しない複雑タスクへの明示エスカレーション |
| Fable | 既定の経路は **advisor（自動相談役）**。メインごと切り替える `/model fable` は長時間自律ラン等の例外のみ |

advisor は、メインの Sonnet が判断ポイントで自動的に Fable へ相談する仕組み。**同一エラー・同一指摘が2回続いたら試行を重ねる前に advisor へ相談し、それでも解消しなければ人間に報告して停止する**、が全エージェント共通のルール（[CLAUDE.md](../CLAUDE.md) に定義）。

### 検証の標準は「人間チェック」

`figma-verify-screen` の標準は `mode: report`: AI は1回だけ指摘レポートを出し、Figma との精密な突き合わせと修正指示は人間が担う。PASS まで AI に修正を反復させる `mode: loop` は、ユーザーが明示的に指定した場合のみの例外。スクショ検証ループは最もコストの重い工程であり、かつ微妙な色差・数 px の余白差は人間の方が確実に見えるため、この分担はコストと品質の両面で合理的（根拠と運用の詳細は [docs/ai-cost-optimization.md](ai-cost-optimization.md) §7）。

### 停止条件の文化

自律ループには複数の独立した停止条件（最大 round 数・同一エラー2回・差分なし検知）を必ず入れる。無限ループ1回の暴走は数日分の通常利用に相当しうる。上限に達したらエージェント自身に延長を判断させず、必ず人間に返す。

## 5. コスト面の方針

権威は [docs/ai-cost-optimization.md](ai-cost-optimization.md)（単価・チェックリスト・検証手順まで揃っている）。日常の意識としてはこの3点:

1. **モデルは単価でなく「1タスクあたり総トークン × 成功率」で選ぶ**。安いモデルで試行錯誤の往復が増えれば総額は簡単に逆転する
2. **最大の削減はモデル選定ではなく、往復回数の削減とキャッシュヒット率**。仕様（specs/）の精度を上げて手戻りを減らすことが、どのモデル変更よりも効く
3. **コンテキストを薄く保つ**。タスクの切れ目で `/clear`、指示は最初の1プロンプトに完了条件までまとめる、修正指摘は1件ずつ往復せず実値つきで一括、生ログは会話に貼らずファイルパスで渡す

タスク開始前・終了後の具体的なチェックリストは [docs/ai-cost-optimization.md](ai-cost-optimization.md) 付録を参照。

## 6. ドキュメントマップ

読む順番の目安つき。各文書の「権威」（そこが正、他は要約）を意識すること。

| 順 | ドキュメント | 内容 / 権威範囲 |
|---|---|---|
| 1 | 本書 | 全体マップ（詳細は各リンク先が正） |
| 2 | [README.md](../README.md) | Dev Container セットアップ手順 |
| 3 | [CLAUDE.md](../CLAUDE.md) | Claude Code への指示そのもの。コミット規約・ドキュメント方針・advisor 発動ルールの権威 |
| 4 | [docs/ai-cost-optimization.md](ai-cost-optimization.md) | コスト運用ルールの権威（モデル選定・キャッシュ・停止条件・検証運用） |
| 随時 | [docs/setup/sandbox.md](setup/sandbox.md) | サンドボックス環境の作り方・運用ポリシー |
| 随時 | [docs/report/リードエンジニア向けAI戦略レポート.md](report/リードエンジニア向けAI戦略レポート.md) | 現行方針に至った分析・意思決定の経緯 |
| 随時 | [docs/report/エグゼクティブAIレポート.md](report/エグゼクティブAIレポート.md) | 経営層向けのコスト構造・ROI 論 |
| 随時 | [docs/backlog.md](backlog.md) | 着手待ちの既知タスク |
| 随時 | `.claude/skills/` / `.claude/agents/` の各定義 | 個別スキル・エージェントの手順の権威 |

なお、CLAUDE.md が参照するファイルの一部（`docs/workflows/figma-development.md`、`docs/setup/github-pat.md`、ルートの `cspell.json` 等）は未作成で、[docs/backlog.md](backlog.md) で管理されている。リンク切れに遭遇したら backlog を確認すること。
