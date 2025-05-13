# src: scripts/tests/agEnvCore.Tests.ps1
# @(#) : 環境変数マネージャーCoreのユニットテスト
#
# Copyright (c) 2025 atsushifx <atsushifx@gmail.com>
# Released under the MIT License
# https://opensource.org/licenses/MIT

<#
.SUMMARY
Tests the functions in agEnv.ps1

.DESCRIPTION
Tests the functions in agEnv.ps1
#>
BeforeAll {
    $script = $SCRIPTROOT + '\libs\agEnvCore.ps1'
    . $script
}


Describe "agEnvCore - Raw操作" {
    Context "GetRaw メソッド" {
        Context "環境変数が存在する場合" {
            It "指定した環境変数の値を返す" {
                $testVar = '<TEST_VAR>'
                $testValue = 'Value123'

                # Process スコープで環境変数を設定
                [System.Environment]::SetEnvironmentVariable(
                    $testVar, $testValue,
                    [System.EnvironmentVariableTarget]::Process
                )

                # GetRaw 呼び出し
                $result = [_agEnvCore]::_GetRaw($testVar, [agEnvScope]::Process)
                $result | Should -Be $testValue
                [_agEnvCore]::isEnvExist($testVar, [agEnvScope]::Process) | Should -Be $true

                # 後片付け: Env: プロバイダーを明示
                Remove-Item "Env:$testVar" -ErrorAction SilentlyContinue
            }
        }

        Context "環境変数が存在しない場合" {
            It "null または空文字列 を返す" {
                $testVarNotExist = '<TEST_NOT_EXIST_VAR>'

                # 存在しなければ SilentlyContinue で安全に削除
                Remove-Item "Env:$testVarNotExist" -ErrorAction SilentlyContinue

                $result = [_agEnvCore]::_GetRaw($testVarNotExist, [agEnvScope]::Process)
                $result | Should -BeNullOrEmpty
                [_agEnvCore]::isEnvExist($testVarNotExist, [agEnvScope]::Process) | Should -Be False
            }
        }
    }

    Context "RemoveRaw メソッド" {
        Context "環境変数が存在する場合" {
            It "指定した環境変数が削除される" {
                $testVar = '<UT_RemoveRaw>'

                # Process スコープにテスト用変数を設定
                [System.Environment]::SetEnvironmentVariable(
                    $testVar, 'ToBeRemoved',
                    [System.EnvironmentVariableTarget]::Process
                )

                # RemoveRaw 呼び出し
                [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process)
                $envVar = [_agEnvCore]::_GetRaw( $testVar, [agEnvScope]::Process)

                # 削除されていることを検証
                $envvar | Should -BeNullOrEmpty
            }
        }

        Context "環境変数が存在しない場合" {
            It "例外を投げずに処理される" {
                $testVar = '<UT_RemoveRaw_Not_Exist>'

                # 事前に削除（なければ SilentlyContinue）
                Remove-Item "Env:$testVar" -ErrorAction SilentlyContinue

                # RemoveRaw 呼び出しが例外を投げないことを確認
                { [_agEnvCore]::_RemoveRaw($testVar, [agEnvScope]::Process) } | Should -Not -Throw
            }
        }
    }

}
