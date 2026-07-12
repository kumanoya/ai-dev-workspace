# ai-dev-workspace

プロジェクト概要・技術スタック・ディレクトリ構成は [CLAUDE.md](CLAUDE.md) を参照。

## Dev Container で開発を始める

推奨環境は VS Code + Dev Containers 拡張機能（`ms-vscode-remote.remote-containers`）。コンテナランタイムは [OrbStack](https://orbstack.dev/) を使用。

### 初回セットアップ

1. OrbStack をインストール・起動
2. 認証情報（Claude Code / gh / SSH 鍵）を全環境で共有するための固定名 volume を作成（設計の詳細は [docs/setup/sandbox.md](docs/setup/sandbox.md)）

   ```sh
   docker volume create claude-code-home
   docker volume create gh-config-shared
   docker volume create ssh-config-shared
   ```

3. VS Code に Dev Containers 拡張機能を入れる

### 起動手順（2回目以降はここから）

1. OrbStack を起動

   ```sh
   open -a OrbStack
   ```

2. VS Code でリポジトリを開く
3. コマンドパレット（`Cmd+Shift+P`）→ `Dev Containers: Reopen in Container`

`.devcontainer/devcontainer.json` が `docker-compose.yml` の `app` サービスを参照する設定になっている。コンテナが既に起動済みならそれにアタッチ、なければビルドして起動する。アタッチ後は VS Code の統合ターミナル・拡張機能（ESLint・スペルチェッカー等）がすべてコンテナ内の環境で動く。

### CLI だけで使いたい場合

VS Code を使わず、コンテナ内で `claude` を動かすだけなら:

```sh
scripts/dev-container.sh
```

**実ターミナル（Terminal.app・iTerm2・VS Code 統合ターミナル等）から実行すること。** Claude Code の `!` ローカルコマンド経由で実行すると疑似端末（TTY）が最後まで繋がらず、コンテナ内の `claude` が非対話モードに落ちてエラーになる。

この方法は VS Code 自体はホスト側で動く、いわばハイブリッド構成になる。ファイルは bind mount（`docker-compose.yml` の `.:/workspace:cached`）で共有されるので実体として問題はないが、エディタの拡張機能はホストの Node/pnpm を使うため、コンテナ内の Lint 結果とズレることがある。エディタも含めて環境を揃えたい場合は上記の「Reopen in Container」を使うこと。
