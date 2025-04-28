# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
# --- 変数設定
Set-Variable -Scope Script -Option ReadOnly -Name SCRIPTROOT -Value (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Variable -Name testRoot -Value (Join-Path $SCRIPTROOT "tests")

Write-Output "testRoot: $testRoot"

# --- テストファイル一覧取得（#で始まるファイルは除外）
$allTestFiles = Get-ChildItem -Path $testRoot -Recurse -File
| Where-Object { $_.Name -like '*.Tests.ps1' }
| Select-Object *, @{ Name = 'TrimmedName'; Expression = { $_.Name.TrimStart() } }
$testFiles = $allTestFiles | Where-Object { -not ($_.TrimmedName -like '#*') }

if ($testFiles.Count -eq 0) {
    Write-Error "No test files found after filtering."
    exit 1
}

#  --- テスト実行
Invoke-Pester -Path $testFiles.FullName -Verbose
