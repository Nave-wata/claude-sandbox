# Claude Sandbox - Ubuntu 24.04 実装

このディレクトリには、Claude Code を実行するためのコンテナ化された環境を提供する Claude Sandbox の Ubuntu 24.04 実装が含まれています。

## インストール

### 前提条件

- **Docker**: インストールされ、実行中である必要があります
- **権限**: ユーザーが Docker にアクセスできる必要があります（`docker` グループに属しているか sudo を使用）
- **Claude Code ライセンス**: 有効な Claude Code 認証/ライセンス

### Claude Sandbox のインストール

1. **このディレクトリに移動:**
   ```bash
   cd ubuntu/24.04
   ```

2. **セットアップウィザードを実行:**
   ```bash
   # デフォルトのユーザーローカルインストール（sudo権限不要）
   ./wizard.sh
   
   # オプション: システム全体へのインストール（sudo権限が必要）
   sudo ./wizard.sh
   ```

3. **インストールの確認:**
   ```bash
   claude-sandbox --help    # Claude Code のヘルプを表示（claude-sandbox のヘルプではありません）
   ```

## 使用方法

`claude-sandbox` コマンドは通常の `claude` コマンドとまったく同じように動作しますが、コンテナ化された環境で実行されます：

```bash
# インタラクティブな Claude Code CLI を開始（最も一般的な使用方法）
claude-sandbox

# 前回のセッションを再開
claude-sandbox --resume

# 特定のモデルで開始
claude-sandbox --model sonnet

# すべての Claude Code オプションがまったく同じように動作
claude-sandbox --help      # Claude Code のヘルプを表示
claude-sandbox --version   # Claude Code のバージョンを表示
```

**重要**: `claude-sandbox` は独自のヘルプやオプションを持ちません。すべてはコンテナ化された Claude Code インスタンスに渡されます。

## オプションのエイリアス

便利なエイリアスを作成できます：

```bash
# ~/.bashrc に追加
alias claude='claude-sandbox'    # デフォルトの claude コマンドとして使用
alias cs='claude-sandbox'        # 短縮エイリアス
```

## 実装詳細

### コンテナ環境

この実装は以下を使用します：
- **ベースイメージ**: `node:24.4-slim`
- **作業ディレクトリ**: `/workspace`（現在のディレクトリからマウント）
- **ユーザー**: `node`（UID 1000）
- **パッケージマネージャー**: npm（Claude Code インストール用）

### ディレクトリ構造

```
ubuntu/24.04/
├── README.md                   # このドキュメント
├── wizard.sh                   # セットアップおよび管理ウィザード
├── claude-sandbox              # メインラッパースクリプト
└── sandbox/                    # コンテナ設定
    └── Dockerfile              # コンテナ定義
```

### 動作方法

1. **インタラクティブ CLI**: 引数なしで `claude-sandbox` を実行すると、コンテナ内で完全なインタラクティブ Claude Code CLI が開始されます
2. **ディレクトリマウント**: 現在の作業ディレクトリは自動的にコンテナ内の `/workspace` にマウントされます
3. **設定の永続化**: Claude の設定（`~/.claude/`、`~/.claude.json`）は認証と設定を保持するためにマウントされます
4. **コンテナ管理**: Docker イメージは初回使用時に構築され、その後の実行で再利用されます

## 高度な設定

### コンテナのカスタマイズ

Docker コンテナは Node.js 24.4 と Claude Code で事前設定されています。必要に応じて追加のツールをインストールしたり環境を設定したりするために、`sandbox/Dockerfile` を変更してコンテナ環境をカスタマイズできます。

## トラブルシューティング

### Docker 権限の問題

権限エラーが発生した場合：

```bash
# ユーザーを docker グループに追加
sudo usermod -aG docker $USER
# ログアウトしてログインし直すか、以下を実行：
newgrp docker
```

### コンテナビルドの問題

コンテナを強制的に再構築：

```bash
# 既存のイメージを削除
docker rmi claude-sandbox
# claude-sandbox を再実行して再構築
claude-sandbox --help
```

### PATH の問題（ユーザーインストール）

ユーザーインストール後に `claude-sandbox` コマンドが見つからない場合：

```bash
# シェルプロファイル（~/.bashrc）に追加
export PATH="$HOME/.local/bin:$PATH"
# シェルを再読み込み
source ~/.bashrc
```

## アンインストール

Claude Sandbox を削除するには：

```bash
./wizard.sh --uninstall
```

これにより以下が削除されます：
- インストールされた `claude-sandbox` コマンド
- プロジェクト参照とシンボリックリンク  
- claude-sandbox イメージを使用するすべての Docker コンテナ
- claude-sandbox Docker イメージ自体
- Claude 設定ファイルは保持されます

## 技術的な詳細

### コンテナ仕様

- **イメージ名**: `claude-sandbox`
- **コンテナ名**: `claude-sandbox-{UID}-{timestamp}-{PID}-{random}`（インスタンスごとに一意）
- **ネットワーキング**: ホストネットワーク（ホストから継承）
- **ストレージ**: 一時的なコンテナ（実行後に削除）
- **競合検出**: 稀な名前の競合に対する自動検出とユーザーフレンドリーなエラーメッセージ

### ボリュームマウント

- 現在の作業ディレクトリ → `/workspace`
- `~/.claude` → `/home/node/.claude`
- `~/.claude.json` → `/home/node/.claude.json`

### セキュリティに関する考慮事項

- コンテナは非rootユーザー（`node`、UID 1000）として実行
- 特権アクセスは不要
- コンテナは一時的で実行後に削除される
- 現在のディレクトリと Claude 設定のみがマウントされる

### エラーハンドリングと信頼性

- **堅牢なコンテナ名生成**: 各コンポーネント（ユーザーID、タイムスタンプ、プロセスID、ランダムサフィックス）は包括的なエラーチェックで検証されます
- **優雅な失敗検出**: 稀な競合が発生した際に明確なエラーメッセージでユーザーをガイドします
- **パフォーマンス最適化**: コンテナ存在チェックに効率的なDocker API呼び出しを使用します
- **フェイルファスト設計**: 初期化中のサイレント失敗を防ぐため、即座にエラーレポートを提供します
