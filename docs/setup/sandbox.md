# サンドボックス環境の運用

生成AI（Claude Code）で実験するための使い捨て環境の作り方と運用ルール。仕組みは2つ:

1. **`claude-sandbox` スクリプト**（ホスト macOS で実行）: コマンド一発で使い捨てコンテナを起動・破棄
2. **`templates/ai-sandbox/` テンプレート**: 腰を据えたプロジェクトを新規に始めるときにコピーする Dev Container 一式

権威は `scripts/claude-sandbox` と `templates/ai-sandbox/` の実ファイル。本書は初回セットアップと運用ポリシーのみを扱う。

## 初回セットアップ（ホストで1回だけ）

### 1. 共有 volume の作成

Claude Code の認証・設定、gh の認証、SSH 鍵は、固定名の共有 volume に置き、本リポジトリ・テンプレコピー先・サンドボックスの全環境で共用する（ログイン・鍵登録は全体で1回で済む）。SSH 鍵はコンテナ専用に新規発行する（ホストの個人鍵はコンテナに持ち込まない）。

```sh
docker volume create claude-code-home
docker volume create gh-config-shared
docker volume create ssh-config-shared
```

### 2. 旧 volume からの移行（本リポジトリを既に使っていた場合）

旧 volume 名は compose プロジェクト名（ホストのディレクトリ名）に依存するので、まず実名を確認してからコピーする:

```sh
docker volume ls | grep -e claude-home -e gh-config   # 旧 volume の実名を確認
docker run --rm -v <旧claude-home実名>:/from -v claude-code-home:/to alpine sh -c "cp -a /from/. /to/"
docker run --rm -v <旧gh-config実名>:/from -v gh-config-shared:/to alpine sh -c "cp -a /from/. /to/"
```

移行後、本リポジトリのコンテナを再作成する: `docker compose build && docker compose up -d --force-recreate`

注意: `CLAUDE_CONFIG_DIR` 切り替え直後の初回のみ、claude 起動時に onboarding の質問が再表示されることがある（認証は保持される）。

### 3. claude-sandbox の導入

PATH の通った場所に symlink を張るだけ:

```sh
ln -s <このリポジトリ>/scripts/claude-sandbox /usr/local/bin/claude-sandbox
```

## 使い捨てサンドボックス（claude-sandbox）

```sh
claude-sandbox try-hono-rpc    # 作成して claude 起動（既存なら再接続）
claude-sandbox ls              # 一覧
claude-sandbox shell <name>    # bash で入る
claude-sandbox rm <name>       # コンテナ破棄（コードは ~/sandboxes/<name> に残る）
claude-sandbox build           # テンプレ更新後のイメージ再ビルド
```

ワークスペースはホストの `~/sandboxes/<name>`（`CLAUDE_SANDBOX_DIR` で変更可）。コンテナを破棄してもコードは残るので、迷ったら消してよい。

## テンプレートから新プロジェクトを始める

```sh
cp -R <このリポジトリ>/templates/ai-sandbox ~/projects/<新プロジェクト名>
cd ~/projects/<新プロジェクト名>
docker compose up -d && docker compose exec app claude
```

詳細・カスタマイズは `templates/ai-sandbox/README.md` を参照。

## 運用ポリシー

- **命名**: 小文字ケバブケースで目的が分かる名前（例: `try-hono-rpc`、`spike-rag-eval`）
- **寿命**: サンドボックスは原則1〜2週間。`claude-sandbox ls` で定期的に棚卸しする
- **破棄基準**: 目的の検証が終わったら即 `rm`。コードは `~/sandboxes/` に残るので、コンテナは気軽に消す
- **昇格手順**（サンドボックス → 本プロジェクト）:
  1. `~/sandboxes/<name>` で `git init` して GitHub にリポジトリを作る
  2. `templates/ai-sandbox/` をコピーして専用の Dev Container 環境にする
  3. サンドボックスコンテナは `claude-sandbox rm <name>` で破棄

## 変更時の検証チェックリスト（ホストで実施）

`Dockerfile` / `docker-compose.yml` / `templates/ai-sandbox/` / `scripts/claude-sandbox` を変更したら:

1. 本リポジトリ: `docker compose build && docker compose up -d --force-recreate` → `scripts/dev-container.sh` で claude が**再ログインなしで**起動し、`pnpm --version` が Dockerfile の `PNPM_VERSION` と一致すること
2. テンプレ: `cp -R templates/ai-sandbox /tmp/sbx-test && cd /tmp/sbx-test && docker compose up -d && docker compose exec app claude` → 認証済みで即起動すること
3. claude-sandbox: `claude-sandbox demo` → `ls` → `shell demo` → `rm demo` が一巡し、`~/sandboxes/demo` が残ること
4. VS Code の「Reopen in Container」が従来どおり動くこと
