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
}

Describe "AgEnvManager - 基本操作" {

    AfterEach {
        agRemoveEnv -Name "TEST_VAR" -Scope ([AgEnvScope]::CURRENT)
        agRemoveEnv -Name "TEST_USER_VAR" -Scope ([AgEnvScope]::USER)
    }

    Context "Process スコープでの set/get/remove" {
        It "should set and get a variable" {
            agSetEnv -Name "TEST_VAR" -Value "TestValue" -Scope ([AgEnvScope]::CURRENT)
            $result = agGetEnv -Name "TEST_VAR"
            $result | Should -BeExactly "TestValue"
        }

        It "should remove a variable" {
            agRemoveEnv -Name "TEST_VAR" -Scope ([AgEnvScope]::CURRENT)
            $result = agGetEnv -Name "TEST_VAR"
            $result | Should -BeNullOrEmpty
        }
    }

    Context "User スコープでの set/get/remove" {
        It "should set and get a user scoped variable" {
            agSetEnv -Name "TEST_USER_VAR" -Value "UserValue" -Scope ([AgEnvScope]::USER)
            $result = agGetEnv -Name "TEST_USER_VAR" -Scope ([AgEnvScope]::USER)
            $result | Should -BeExactly "UserValue"
        }

        It "should remove a user scoped variable" {
            agRemoveEnv -Name "TEST_USER_VAR" -Scope ([AgEnvScope]::USER)
            $result = agGetEnv -Name "TEST_USER_VAR" -Scope ([AgEnvScope]::USER)
            $result | Should -BeNullOrEmpty
        }
    }
}

Describe "AgEnvManager - 保護変数の制限" {

    BeforeEach {
        $script:originalProtectedKeys = [_AgEnvManager]::_protectedKeys.Clone()
        [_AgEnvManager]::_protectedKeys = $script:originalProtectedKeys + "MOCK_ENV"
    }
    AfterEach {
        [_AgEnvManager]::_protectedKeys = $script:originalProtectedKeys
    }

    Context "ProtectedKeys に対する拒否動作" {
        It "set illegal variable should throw" {
            { agSetEnv -Name "MOCK_Env" -Value "SomeValue" -Scope ([AgEnvScope]::CURRENT) } | Should -Throw -ExceptionType ([System.InvalidOperationException])
        }
        It "remove illegal variable should throw" {
            { agRemoveEnv -Name "MOCK_Env" -Scope ([AgEnvScope]::CURRENT) } | Should -Throw -ExceptionType ([System.InvalidOperationException])
        }
    }
}

Describe "AgEnvManager - スコープ同期（Process/User）" {

    BeforeEach {
        agRemoveEnv -Name "TEST_SYNC_VAR" -Scope ([AgEnvScope]::USER)
        Remove-Item Env:TEST_SYNC_VAR -ErrorAction SilentlyContinue
    }

    AfterEach {
        agRemoveEnv -Name "TEST_SYNC_VAR" -Scope ([AgEnvScope]::USER)
        Remove-Item Env:TEST_SYNC_VAR -ErrorAction SilentlyContinue
    }

    Context "同期あり (NoSyncなし)" {
        It "User scope に設定すると Process にも反映される" {
            agSetEnv -Name "TEST_SYNC_VAR" -Value "SyncedValue" -Scope ([AgEnvScope]::USER)
            $env:TEST_SYNC_VAR | Should -BeExactly "SyncedValue"
        }
    }

    Context "同期なし (NoSync指定)" {
        It "User scope に設定しても Process に反映されない" {
            agSetEnv -Name "TEST_SYNC_VAR" -Value "SyncedValue" -Scope ([AgEnvScope]::USER) -NoSync
            $env:TEST_SYNC_VAR | Should -BeNullOrEmpty
        }
    }
}
