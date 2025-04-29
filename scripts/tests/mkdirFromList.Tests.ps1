# src: scripts/tests/mkdirFromList.Tests.ps1
# @(#) : mkdirFromList.Tests : ディレクトリ作成テスト
#
# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
# This software is released under the MIT License.
#
# https://opensource.org/licenses/MIT

<#
.SYNOPSIS
mkdirFromList.Tests : ディレクトリ作成テスト

.DESCRIPTION
パイプ形式で読み込んだディレクトリが作成できるかのテスト
テスト自体はMockを使用して、実際のディレクトリ作成を行わない
#>

# --- import
# すぐ後に関数が定義されているか確認
BeforeAll {
    . "$SCRIPTROOT/libs/pathUtils.ps1"
}
# --- テストメイン
Describe "pathUtils: mkdirFromList (Dry-Run mode)" {
    # Mock Dir
    $script:mockCurrent = "C:\<Mock>\Current"
    $script:mockHome = "C:\<Mock>\Home"
    $script:originalHome = $env:USERPROFILE

    BeforeEach {
        # 環境変数とGet-Locationのモック
        $env:USERPROFILE = $mockHome

        $script:createdPaths = @()

        Mock -CommandName Get-Location -MockWith { return $mockCurrent }
        Mock -CommandName Test-Path -MockWith { return $false }
        Mock -CommandName New-Item -MockWith {
            $path = $args[3]
            $script:createdPaths += $path
            [PSCustomObject]@{ Path = $path }
        }
    }

    AfterEach {
        $env:USERPROFILE = $originalHome
    }

    Context "when creating directory from home path (Dry-Run)" {
        It "should resolve and return the correct home path without creating directory" {
            $result = "~/projects/myApp" | mkdirFromList -DryRun

            # New-Itemは呼ばれていないことを確認
            Assert-MockCalled -CommandName New-Item -Times 0 -Exactly -Scope It

            # 出力されたパスを確認
            $expected = "C:\<Mock>\Home\projects\myApp"
            $result | Should -BeExactly $expected
        }
    }

    Context "when creating directory from home path" {
        It "should resolve and return the correct home path with creating directory" {
            $result = "~/projects/myApp" | mkdirFromList


            # New-Itemは呼ばれていないことを確認
            Assert-MockCalled -CommandName New-Item -Times 1 -Exactly -Scope It

            # 出力されたパスを確認
            $expected = "C:\<Mock>\Home\projects\myApp"
            $result | Should -BeExactly $expected
        }
    }

    Context "when creating directory from relative path (Normal mode)" {
        It "should create directory under mocked current location" {
            $result = "relativeDir" | mkdirFromList

            # New-Itemが呼ばれたことを確認
            Assert-MockCalled -CommandName New-Item -Times 1 -Exactly -Scope It

            # 出力されたパスを確認
            $expected = "C:\<Mock>\Current\relativeDir"
            $result | Should -BeExactly $expected
        }
    }

    Context "when creating directory from absolute path (Normal mode)" {
        It "should create directory as is without changing base" {
            $result = "C:\<Mock>\Absolute\dir" | mkdirFromList

            # New-Itemが呼ばれたことを確認
            Assert-MockCalled -CommandName New-Item -Times 1 -Exactly -Scope It

            # 出力されたパスを確認
            $expected = "C:\<Mock>\Absolute\dir"
            $result | Should -BeExactly $expected
        }
    }

    ## Edge Case : null or space
    Context "when path is empty string" {
        It "should write error and skip creation" {
            { "" | mkdirFromList } | Should -Throw
        }
    }

    Context "when path is whitespace only" {
        It "should write error and skip creation" {
            { "   " | mkdirFromList } | Should -Throw
        }
    }

    Context "when path has leading and trailing spaces" {
        It "should trim spaces and create directory correctly" {
            $result = "  trimmedDir  " | mkdirFromList

            # New-Itemが呼ばれたことを確認
            Assert-MockCalled -CommandName New-Item -Times 1 -Exactly -Scope It

            # 出力されたパスを確認
            $expected = "C:\<Mock>\Current\trimmedDir"
            $result | Should -BeExactly $expected
        }
    }

    ## Edge Case : i18n (CJK: Japanese, Korean, Chinese)
    Context "when creating directory with Japanese characters" {
        It "should create directory with Japanese name correctly" {
            $result = "資料" | mkdirFromList
            Assert-MockCalled -CommandName New-Item -Times 1 -Exactly -Scope It

            $expected = "C:\<Mock>\Current\資料"
            $result | Should -BeExactly $expected
        }
    }

    Context "when creating directory with Japanese name and full-width space" {
        It "should create directory with full-width space in name" {
            $result = "新規　フォルダ" | mkdirFromList
            Assert-MockCalled -CommandName New-Item -Times 1 -Exactly -Scope It

            $expected = "C:\<Mock>\Current\新規　フォルダ"
            $result | Should -BeExactly $expected
        }
    }

    Context "when creating directory with Korean or Chinese characters" {
        It "should create directory with multi-byte name correctly" {
            $result = "데이터" | mkdirFromList
            Assert-MockCalled -CommandName New-Item -Times 1 -Exactly -Scope It

            $expected = "C:\<Mock>\Current\데이터"
            $result | Should -BeExactly $expected
        }
    }

    ## Edge Case : illegal characters
    Context "when path is composed only of forbidden characters" {
        It "should throw error for only backslash" {
            { "\" | mkdirFromList } | Should -Throw
        }
        It "should throw error for only slash" {
            { "/" | mkdirFromList } | Should -Throw
        }
        It "should throw error for only asterisk" {
            { "*" | mkdirFromList } | Should -Throw
        }
        It "should throw error for only question mark" {
            { "?" | mkdirFromList } | Should -Throw
        }
        It "should throw error for only less than" {
            { "<" | mkdirFromList } | Should -Throw
        }
        It "should throw error for only greater than" {
            { ">" | mkdirFromList } | Should -Throw
        }
        It "should throw error for only pipe" {
            { "|" | mkdirFromList } | Should -Throw
        }
    }

    ## multiple directories list
    Context "when creating multiple directories" {
        It "should create all directories from list" {
            $dirs = @("dir1", "dir2", "dir3")
            $results = $dirs | mkdirFromList

            # New-ItemのMockで記録されたパスリストと比較
            $expectedPaths = @(
                "C:\<Mock>\Current\dir1",
                "C:\<Mock>\Current\dir2",
                "C:\<Mock>\Current\dir3"
            )

            $script:createdPaths | Should -BeExactly $expectedPaths
            $results | Should -BeExactly $expectedPaths
        }
    }
}
