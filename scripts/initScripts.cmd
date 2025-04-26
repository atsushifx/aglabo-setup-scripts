@echo off
rem src: ./scripts/initScripts.cmd
rem @(#) : setup environment for execute ps1 script
rem
rem Copyright (c) 2025 atsushifx <atsushifx@gmail.com>
rem
rem This software is released under the MIT License.
rem https://opensource.org/licenses/MIT

setlocal

REM バッチ自身が置かれているディレクトリに移動
cd /d %~dp0

REM pwsh (PowerShell 7+) の存在チェック
where pwsh >nul 2>nul
if %errorlevel%==0 (
    set "SH=pwsh"
) else (
    echo [警告] PowerShell Core (pwsh) が見つかりませんでした。
    echo [案内] Windows標準の powershell.exe を使用します。
    echo [推奨] より安全な実行環境のため、PowerShell 7+ のインストールをおすすめします。
    echo [推奨] winget install --id Microsoft.Powershell --source winget --interactive
    set "SH=powershell"
)

REM 実行ポリシー設定（CurrentUserスコープで安全に）
%SH% -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force"

REM ダウンロードファイルのブロック解除
%SH% -Command "Get-ChildItem -Path . -Filter *.ps1 -Recurse | Unblock-File"

echo セットアップ準備完了しました！
pause
exit /b
