# GitHub 認証（gh / PAT）のセットアップ

コンテナ内の `gh` コマンドが認証エラーで止まったときの対処と、Personal Access Token（PAT）が必要になる場面の扱い。

権威は `docker-compose.yml` の volume 定義（認証情報の置き場）と `.claude/settings.json` の deny リスト（AI に許していない操作）。本書は運用上の切り分けだけを扱う。

## 前提: 認証は2系統ある

このリポジトリでは GitHub への認証経路が2つあり、**エラーの原因はまずどちらかを見分けるところから始める**。

| 経路 | 使うもの | 保存先 | 使われる操作 |
|---|---|---|---|
| GitHub API | `gh` のトークン | volume `gh-config-shared`（`~/.config/gh`） | `gh pr create` / `gh issue` / `gh api` 等 |
| Git 操作 | SSH 鍵 | volume `ssh-config-shared`（`~/.ssh`） | `git clone` / `git fetch` / `git push` |

`gh pr create` は失敗するのに `git fetch` は通る（あるいはその逆）なら、この2系統のうち片方だけが壊れている。`gh auth status` の出力で `Git operations protocol: ssh` と表示されるとおり、Git 側は `gh` のトークンを使わない。

**volume は全環境で共有**されている（本リポジトリ・`templates/ai-sandbox/` のコピー先・`claude-sandbox` の使い捨てコンテナ）。したがって**ログインと鍵登録は全体を通じて1回だけ**で、新しいサンドボックスを作っても再ログインは不要。逆に、ここで認証をやり直すと全環境に影響する。

## 初回ログイン（未認証のとき）

```sh
gh auth status          # まず現状を確認する
gh auth login           # 未認証ならログイン
```

コンテナにはブラウザが無いので、`gh auth login` はワンタイムコードを表示する device flow になる。表示されたコードを**ホスト側のブラウザ**で入力する。

`Git operations protocol` は `SSH` を選ぶ（Git 側は SSH 鍵の系統に寄せ、トークンの寿命に依存させない）。SSH 鍵をまだ作っていない場合は、コンテナ専用に新規発行する（ホストの個人鍵はコンテナに持ち込まない。詳細は [sandbox.md](sandbox.md)）。

## スコープ不足のエラー

`gh` が `HTTP 403` や `missing required scopes` を返す場合は、ログインし直さずスコープだけ足す:

```sh
gh auth refresh -s <scope>      # 例: gh auth refresh -s workflow
```

`gh auth login` で得られる既定のトークンには `repo` / `read:org` / `gist` / `admin:public_key` が入る。`/create-pr` を含む通常の PR 運用はこれで足りる。追加が要るのは主に次のケース:

- `.github/workflows/**` を含む変更を push・作成する → `workflow`
- GitHub Projects を操作する → `project`（`read:project`）
- Packages を読み書きする → `read:packages` / `write:packages`

`gh auth refresh` の結果も共有 volume に書かれるので、**一度足せば全環境に効く**。

## PAT を使う場合

device flow が使えない、あるいは組織のポリシーで OAuth アプリが許可されていない場合は PAT を使う。

**PAT の発行と設定は人間が手動で行う。AI にトークンの値を渡さない・設定させない**（`gh secret set` 等は `.claude/settings.json` の deny でブロック済み）。

```sh
gh auth login --with-token < <トークンを書いたファイル>
```

### 落とし穴: `GH_TOKEN` は保存済み認証を上書きする

環境変数 `GH_TOKEN` / `GITHUB_TOKEN` が設定されていると、`gh` は共有 volume の認証より**そちらを優先する**。共有 volume 方式の前提が崩れて「ログインしたはずなのに権限が足りない」状態になるので、原則として設定しない。設定してしまった場合は `gh auth status` の出力に環境変数由来である旨が出るので、そこで気づける。

やむを得ず使うときも、`.env`（git 管理外）に置いてそのシェルに閉じ込め、`docker-compose.yml` の `environment` へ常設しない。

## AI が認証エラーに遭遇したときの扱い

- `pr-creator` エージェントは認証エラーを検知したらリトライせず中断し、本書を参照するよう案内して終了する（権威は [.claude/agents/pr-creator.md](../../.claude/agents/pr-creator.md)）
- **`git push` は AI に対して deny 済み**。認証を直したところで AI が push できるようにはならない。push は人間が行う
