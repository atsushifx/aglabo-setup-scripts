# src: scripts/tests/agEnv.Tests.ps1
# @(#) : agEnv.Tests.ps1 : 環境変数関連関数の機能テスト
#
# Copyright (c) 2023 atsushifx <atsushifx@gmail.com>
# Released under the MIT License
# https://opensource.org/licenses/MIT

<#
.SUMMARY
Tests the functions in agEnv.ps1

.DESCRIPTION
Tests the functions in agEnv.ps1
    setEnv: Set an environment variable with optional process synchronization.
    getEnv: Retrieves the value of an environment variable.
    removeEnv: Removes an environment variable.
#>
BeforeAll {
    $script = $SCRIPTROOT + '\libs\agEnvManager.ps1'
    . $script
    # Environment Variable Names
    $script:TEST_ENV_EXIST = "Path"
    $script:TEST_ENV = "<TEST_ENV>"
    $script:TEST_USER_ENV = "<TEST_USER_ENV>"
}

Describe "AgEnvManager - xxRaw関数" {
    context "Test env::getRaw" {
        It "should get valid data from Environment Variable" {
            $true | Should -Be $true
        }
    }
}
