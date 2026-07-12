# syntax=docker/dockerfile:1

# Playwright 公式イメージ（Node.js・Chromium 等の OS 依存ライブラリを同梱）。
# prototypes/sample-app-v2 導入時、package.json の playwright バージョンとタグを一致させること。
FROM mcr.microsoft.com/playwright:v1.55.0-noble

# ベースイメージには既に ubuntu(1000)・pwuser(1001) が存在するため、
# 衝突を避けて 1002 をデフォルトにしている（docker-compose.yml と揃えること）。
ARG USERNAME=dev
ARG USER_UID=1002
ARG USER_GID=1002

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git ripgrep jq ca-certificates curl gnupg sudo \
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# 再現性のため固定。将来 prototypes/ 側の package.json に packageManager を書けば
# corepack がそちらを自動優先するので競合しない。
ARG PNPM_VERSION=11.9.0
RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate

RUN npm install -g @anthropic-ai/claude-code

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

WORKDIR /workspace

# ~/.claude.json（onboarding 状態・MCP 設定）も volume 内に置かせて、
# 認証と設定を claude-code-home volume 1個で完結させる。
ENV CLAUDE_CONFIG_DIR=/home/${USERNAME}/.claude

# named volume は初回マウント時にイメージ側の既存ディレクトリの所有権を引き継いでコピーする。
# ここで先に dev 所有のディレクトリを作っておくことで、volume マウント後も dev が書き込める。
RUN mkdir -p /home/${USERNAME}/.claude /home/${USERNAME}/.config/gh \
    && chown -R ${USERNAME}:${USERNAME} /home/${USERNAME} /workspace

USER ${USERNAME}

CMD ["sleep", "infinity"]
