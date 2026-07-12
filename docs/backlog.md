# バックログ

着手待ちの既知タスク。完了したら行ごと消す。

- **gh 安全ガードの実装**: CLAUDE.md は「`.claude/settings.json` の deny リストでブロック済み」としているが、実ファイルには `model` 指定しかない。deny リストを実装して記述と一致させる
- **CLAUDE.md が参照する未作成ファイルの整備**: ルート `package.json`（`lint:spell` スクリプト）/ `cspell.json` / `docs/workflows/figma-development.md` / `docs/setup/github-pat.md` が空リンク。各プロトタイプ着手時に作成する
