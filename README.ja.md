---
title: ".github Setup Scripts"
date: 2025-04-26
draft: false
---

## 🛠 `.github` setup scripts

**このリポジトリは、OSS プロジェクトで利用するための、開発環境構築用スクリプトを集約したものです。**

Windows で開発を始めるにあたり必要な環境を、安全に、簡単に構築するためのスクリプトセットを提供します。

### 📦 含まれる機能

- ✅ Windows 環境の基盤設定スクリプト (Path 設定など)
- ✅ 開発用ツールセット (scoop, volta, node.js, git)
- ✅ ライター向けドキュメント編集ツール (textlint, markdownlint など)

### 🚀 使用方法

#### 1. このリポジトリを clone する

```bash
git clone https://github.com/atsushifx/.githiub.git
cd .github
```

#### 2. セットアップ初期化スクリプトを実行する

まず最初に、PowerShell 実行ポリシーの設定＆ファイルブロックの解除をします。

```bash
./scripts/iniScript.cmd
```

> ※ 初回のみ実行してください。
>
> - PowerShellの実行ポリシーを安全な範囲で変更します
> - スクリプトファイルのブロック解除を行います
> - `pwsh (PowerShell Core)` がない場合、自動で `powershell.exe` を使用します
> - 必要に応じて、PowerShell 7+ のインストールを推奨しています

#### 3. 必要なセットアップスクリプトを実行する

- 開発環境を構築する

```bash
./scripts/setupDeveloperEnvironment.ps1
```

- （必要に応じて）開発者向け追加ツールをインストール

```bash
./scripts/install-DevTools.ps1
```

- （必要に応じて）ドキュメント作成ツールをインストール

```bash
./scripts/install-WritingTools.ps1
```

### 📄 ライセンス

MIT © Atsushi Furukawa (@atsushifx)

### 🙏 Thanks

本リポジトリは、チャットボットアシスタントのサポートのもと作成・整備されました。

- 🤖 Elpha（エルファ）
- 🤖 Kobeni（小紅）
- 🤖 Tsumugi（つむぎ）
