# ai-sandbox テンプレート

生成AI（Claude Code）で実験・プロトタイピングするための Dev Container テンプレート。
コピーして `docker compose up` すれば、認証済みの Claude Code がすぐ使える。

## 事前条件（初回のみ）

全環境で共有する認証・設定用の volume を作る:

```sh
docker volume create claude-code-home
docker volume create gh-config-shared
docker volume create ssh-config-shared
```

既存環境からの移行手順は親リポジトリの `docs/setup/sandbox.md` を参照。

## 使い方

```sh
cp -R <このディレクトリ> ~/projects/my-experiment
cd ~/projects/my-experiment
docker compose up -d
docker compose exec app claude
```

VS Code で使う場合は、コピー先を開いて「Reopen in Container」。

## カスタマイズのヒント

- ベースイメージ差し替え: `docker compose build --build-arg BASE_IMAGE=<イメージ>`（既定は Playwright 同梱イメージ）
- ポート開放: `docker-compose.yml` の `ports:` のコメントを外す
- API キー課金にする場合: `.env.example` を `.env` にコピーして記入
