FROM mcr.microsoft.com/devcontainers/base:2-trixie

# 追加ツールと日本語ロケールのインストール
RUN apt-get update && apt-get install -y \
    locales \
    unzip \
    && echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen ja_JP.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# 日本語環境変数の設定
ENV LANG=ja_JP.UTF-8
ENV LC_ALL=ja_JP.UTF-8

# `vscode`ユーザー用にbunをインストール
USER vscode
COPY --chown=vscode:vscode .bun-version /tmp/.bun-version
RUN BUN_VERSION=$(cat /tmp/.bun-version) && \
    curl -fsSL https://bun.sh/install | bash -s "bun-v${BUN_VERSION}" && \
    rm /tmp/.bun-version

# claude codeのインストール
RUN curl -fsSL https://claude.ai/install.sh | bash

# uvのインストール（Serena用のPythonパッケージマネージャー）
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/home/vscode/.local/bin:$PATH"

# uvを使ってPython 3.12をインストール（Serena互換性のため）
RUN uv python install 3.12

WORKDIR /workspace/main
