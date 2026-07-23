# 実装画面スクショの取得手順（共通リファレンス）

`figma-verify-screen` / `fix-design-diff` から参照される共通手順。dev サーバーの確保から実装画面のスクリーンショット取得までを定める。スキル固有の差分（撮影サイズ・オプション）は各スキル側に記載がある。
両スキルとも、既定フロー（AI レビュー未依頼）では本ファイルを Read しない。ユーザーが AI レビューを明示依頼した場合の準備工程としてのみ Read される。

## 前提

- 対象プロトタイプに Playwright が導入済み（`prototypes/sample-app-v2` は導入済み）。
- 初回のみ Chromium のシステム依存が必要な場合がある:
  ```bash
  npx playwright install chromium-headless-shell
  sudo npx playwright install-deps chromium-headless-shell
  ```
  既に入っていれば不要（`~/.cache/ms-playwright/` を確認）。
- スクショスクリプト: `prototypes/<proto>/verify/screenshot.mjs`（route を渡すだけで撮れる。フォント外部読み込みのブロック等、ハマりどころは対策済み）。
- 出力先: `prototypes/<proto>/verify/shots/`（`.gitignore` 済み。コミットしない。ディレクトリがなければ作る）。

## 1. dev サーバーの確保

- 既に起動しているか確認する: `curl -s -o /dev/null -w "%{http_code}" http://localhost:<port>`（port は各プロトタイプの `vite.config.ts` が権威。sample-app-v2 は 5175）。
- **起動済みなら流用する**（自分で新規に起動しようとしない。ポート占有で失敗するだけでなく、他の作業を止めかねない）。
- 起動していなければ `cd prototypes/<proto> && pnpm run dev` を `run_in_background: true` で起動し、起動ログで ready を確認する。
- **自分が起動した場合のみ**、スクショ取得後に停止する（他プロセスが使っている dev サーバーは止めない）。

## 2. スクショの取得

```bash
cd prototypes/<proto>
node verify/screenshot.mjs <route> verify/shots/<name>-impl.png [オプション]
```

- `--full` でスクロール込みの全体を撮る。サイズ・オプションの使い分けは呼び出し元スキルの指定に従う。
- 出力 JSON の `ok:true` / `status:200` / `consoleErrors:[]` を確認する（エラーがあればスクショ比較より先にそちらを直す/差し戻す）。

## 3. screenshot.mjs が無い環境のフォールバック

スクショ工程をスキップし、最終報告で「dev サーバーの `http://localhost:<port><route>` を直接開いて確認してほしい」と案内する。スクショのために新たな仕組みを作り込まない。
