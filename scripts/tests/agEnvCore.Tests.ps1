# src: scripts/tests/agEnvCore.Tests.ps1
# @(#) : 環境変数マネージャーCoreのユニットテスト
#
# Copyright (c) 2025 atsushifx <atsushifx@gmail.com>
# Released under the MIT License
# https://opensource.org/licenses/MIT

<#
.SUMMARY
Tests the Raw methods in agEnvCore.ps1
.DESCRIPTION
Tests the _GetRaw, _SetRaw, _RemoveRaw and IsEnvExist methods in agEnvCore.ps1
#>
BeforeAll {
    $script = $SCRIPTROOT + '\libs\agEnvCore.ps1'
    . $script
}

Describe "agEnvCore - Raw操作" {

    Context "SetRaw メソッド" {
        Context "Process スコープに設定する場合" {
            It "環境変数が Process に設定される" {
                $testVar = '<UT_SetRaw_Process>'
                $testValue = 'ProcessValue'

                # 初期化
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)

                # 設定
                [_agEnvCore]::_SetRaw($testVar, $testValue, [agEnvScope]::Process)

                # 取得
                $raw = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process)
                $raw | Should -Be $testValue

                (Test-Path "Env:$testVar") | Should -BeTrue

                # 後片付け
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
            }
        }

        Context "User スコープに設定する場合" {
            It "User にのみ設定され、Process には反映されない" {
                $testVar = '<UT_SetRaw_User>'
                $testValue = 'UserValue'

                # 初期化
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::User)
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)

                # デフォルトScope(User)で設定
                [_agEnvCore]::_SetRaw($testVar, $testValue, [agEnvScope]::User)

                # User取得
                $userRaw = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::User)
                $userRaw | Should -Be $testValue

                # Process未反映
                $procRaw = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Current)
                $procRaw | Should -BeNullOrEmpty

                # 後片付け
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::User)
            }
        }
    }

    Context "GetRaw / IsEnvExist メソッド" {
        Context "環境変数が存在する場合" {
            It "GetRaw が値を返し、IsEnvExist が true を返す" {
                $testVar = '<TEST_VAR>'
                $testValue = 'Value123'

                [System.Environment]::SetEnvironmentVariable($testVar, $testValue, [System.EnvironmentVariableTarget]::Process)

                $result = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process)
                $exists = [_agEnvCore]::IsEnvExist($testVar, [agEnvScope]::Process)

                $result | Should -Be $testValue
                $exists | Should -BeTrue

                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
            }
        }

        Context "環境変数が存在しない場合" {
            It "GetRaw が null/empty を返し、IsEnvExist が false を返す" {
                $testVar = '<TEST_NOT_EXIST_VAR>'
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)

                $result = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process)
                $exists = [_agEnvCore]::IsEnvExist($testVar, [agEnvScope]::Process)

                $result | Should -BeNullOrEmpty
                $exists | Should -BeFalse
            }
        }
    }

    Context "RemoveRaw メソッド" {
        Context "環境変数が存在する場合" {
            It "削除後は GetRaw が null/empty を返す" {
                $testVar = '<UT_RemoveRaw>'

                [System.Environment]::SetEnvironmentVariable($testVar, 'ToBeRemoved', [System.EnvironmentVariableTarget]::Process)
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)

                $envVar = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process)
                $envVar | Should -BeNullOrEmpty
            }
        }

        Context "環境変数が存在しない場合" {
            It "例外を投げずに処理される" {
                $testVar = '<UT_RemoveRaw_Not_Exist>'
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)

                { [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process) } | Should -Not -Throw
            }
        }
    }
}
