# src: scripts/tests/agEnvCore.Tests.ps1
# @(#) : 環境変数マネージャーCoreのユニットテスト
#
# Copyright (c) 2025 atsushifx <atsushifx@gmail.com>
# Released under the MIT License
# https://opensource.org/licenses/MIT

<#
.SUMMARY
Tests the Raw and Get methods in agEnvCore.ps1
.DESCRIPTION
Uses BeforeEach/AfterEach to setup/teardown env vars,
then tests _SetRaw, _GetRaw, _RemoveRaw, Get and IsEnvExist.
#>
BeforeAll {
    $script = $SCRIPTROOT + '\libs\agEnvCore.ps1'
    . $script
}

Describe "agEnvCore - Raw操作" {

    Context "SetRaw メソッド" {

        Context "Process スコープに設定する場合" {
            BeforeEach {
                $testVar   = '<UT_SetRaw_Process>'
                $testValue = 'ProcessValue'
                # 事前にクリア
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
            }
            AfterEach {
                # クリーンアップ
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
            }

            It "環境変数が Process に設定される" {
                [_agEnvCore]::_SetRaw($testVar, $testValue, [agEnvScope]::Process)
                $raw = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process)
                $raw | Should -Be $testValue

                (Test-Path "Env:$testVar") | Should -BeTrue
            }
        }

        Context "User スコープに設定する場合（明示的）" {
            BeforeEach {
                $testVar   = '<UT_SetRaw_User>'
                $testValue = 'UserValue'
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::User)
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
            }
            AfterEach {
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::User)
            }

            It "User にのみ設定され、Process には反映されない" {
                [_agEnvCore]::_SetRaw($testVar, $testValue, [agEnvScope]::User)

                $userRaw = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::User)
                $userRaw | Should -Be $testValue

                $procRaw = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process)
                $procRaw | Should -BeNullOrEmpty
            }
        }
    }

    Context "IsEnvExist / _GetRaw / _RemoveRaw メソッド" {

        Context "存在チェックと削除" {
            BeforeEach {
                $testVar   = '<UT_Exist>'
                $testValue = 'ExistValue'
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
                [_agEnvCore]::_SetRaw($testVar, $testValue, [agEnvScope]::Process)
            }
            AfterEach {
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
            }

            It "IsEnvExist は true を返し、_GetRaw は値を返す" {
                [_agEnvCore]::IsEnvExist($testVar, [agEnvScope]::Process) | Should -BeTrue
                [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process) | Should -Be $testValue
            }

            It "RemoveRaw 後は存在しない扱いになる" {
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
                [_agEnvCore]::IsEnvExist($testVar, [agEnvScope]::Process) | Should -BeFalse
            }
        }
    }
}

Describe "agEnvCore - Get メソッド (Public API)" {

    Context "正常系" {
        BeforeEach {
            $testVar   = '<UT_Get_Public>'
            $testValue = 'PublicValue'
            # _SetRaw で Current (Process) スコープに設定
            [_agEnvCore]::_SetRaw($testVar, $testValue, [agEnvScope]::Current)
        }
        AfterEach {
            # _RemoveRaw でクリーンアップ
            [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Current)
        }

        It "Current alias を指定して取得できる" {
            $result = [_agEnvCore]::Get($testVar, [agEnvScope]::Current)
            $result | Should -Be $testValue
        }
    }
}

Describe "agEnvCore - Set メソッド (Public API)" {

    Context "Sync 動作" {
        BeforeEach {
            $testVar = '<UT_Set_Sync>'
            # User/Current をクリア
            [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::User)
            [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Current)
        }
        AfterEach {
            # クリーンアップ
            [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::User)
            [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Current)
        }

        It "Sync=true で User と Current に同時設定される" {
            $valueOn = 'SyncOnValue'
            [_agEnvCore]::Set($testVar, $valueOn, [agEnvScope]::User, $true)

            # public Get で User スコープ確認
            [_agEnvCore]::Get($testVar, [agEnvScope]::User) | Should -Be $valueOn

            # public Get で Current(alias)スコープ確認
            [_agEnvCore]::Get($testVar, [agEnvScope]::Current) | Should -Be $valueOn
        }

        It "Sync=false で User のみ設定され、Current には反映されない" {
            $valueOff = 'SyncOffValue'
            [_agEnvCore]::Set($testVar, $valueOff, [agEnvScope]::User, $false)

            # public Get で User スコープ確認
            [_agEnvCore]::Get($testVar, [agEnvScope]::User) | Should -Be $valueOff

            # 変数がない場合は IsEnvExist で false を確認
            [_agEnvCore]::IsEnvExist($testVar, [agEnvScope]::Current) | Should -BeFalse
        }
    }
}
