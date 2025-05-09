# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT

Set-StrictMode -Version Latest

# --- 変数設定
Set-Variable -Scope Script -Option ReadOnly -Name SCRIPTROOT -Value (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Variable -Name testRoot -Value (Join-Path $SCRIPTROOT "tests")

Write-Output "testRoot: $testRoot"

<#
.SYNOPSIS
Retrieves a list of test file paths.

.DESCRIPTION
This function returns an array of strings representing the paths to test files.
It is designed to locate and provide the necessary test files for further processing.

.RETURNS
[string[]]
An array of strings, where each string is the path to a test file.

.EXAMPLE
# Call the function to get test file paths
$testFiles = getTestFiles
# Outputs an array of test file paths
#>
function getTestFiles {
    [OutputType([string[]])]
    param([string]$testRoot)

    $allTestFiles = Get-ChildItem -Path $testRoot -Recurse -File
    | Where-Object { $_.Name -like '*.Tests.ps1' }
    | Select-Object *, @{ Name = 'TrimmedName'; Expression = { $_.Name.TrimStart() } }
    $testFiles = $allTestFiles | Where-Object { -not ($_.TrimmedName -like '#*') }
    if ($null -eq $testFiles) {
        return $null

    }
    return $testFiles.FullName
}

# --- テストファイル一覧取得（#で始まるファイルは除外）
$testFiles = getTestFiles -testRoot $testRoot
if ($null -eq $testFiles) {
    Write-Error "No test files found."
    exit 1
}

Invoke-Pester -Path $testFiles -Verbose
