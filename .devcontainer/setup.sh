#!/bin/bash
set -e

echo "🚀 Starting Dev Container setup..."


echo "👤 Current user:"
whoami


echo "🔐 Setting up Git safe directory..."
git config --global --add safe.directory /workspace/main


# GitHub認証のセットアップ
if [ -n "$GH_TOKEN" ]; then
  echo "🔐 Setting up GitHub authentication..."
  gh auth setup-git
  echo "✅ GitHub authentication configured"
else
  echo "⚠️  GH_TOKEN not set. Git push/pull may require manual authentication."
fi


echo "📦 Installing dependencies..."
bun ci


# echo "📦 Migrating database..."
# bun run db:migrate:deploy


# 個人用セットアップスクリプトの初期化と実行
if [ ! -f ".devcontainer/setup.personal.sh" ]; then
  cat << 'EOF' > .devcontainer/setup.personal.sh
#!/bin/bash
set -e

# ここに個人用のセットアップステップを記述

# ルートディレクトリに`core`を生成しないようにするための設定
# echo 'ulimit -c 0' >> ~/.zshrc
EOF
  chmod +x .devcontainer/setup.personal.sh
fi
echo "🔧 Running personal setup..."
bash .devcontainer/setup.personal.sh


echo "✨ Dev Container setup completed successfully!"
