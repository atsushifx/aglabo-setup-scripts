BeforeAll {
    $script = $SCRIPTROOT + '\libs\agEnv.ps1'
    . $script
}

Describe "AgEnv script functions test (agSetEnv/agGetEnv/agRemoveEnv)" {

    AfterEach {
        agRemoveEnv -Name "TEST_VAR" -Scope ([AgEnvScope]::CURRENT)
        agRemoveEnv -Name "TEST_USER_VAR" -Scope ([AgEnvScope]::USER)
    }

    Context "Environment variable operations (Process scope)" {
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

    Context "Environment variable operations (User scope)" {
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

Describe "AgEnv protect Environment Variable tests" {
    BeforeEach {
        $script:originalProtectedKeys = [AgEnv]::ProtectedKeys
        [AgEnv]::ProtectedKeys = $script:originalProtectedKeys + @("<MOCK_ENV>")
    }
    AfterEach {
        [AgEnv]::ProtectedKeys = $script:originalProtectedKeys
    }

    Context "check isProtected return" {
        It "set illegal variable should throw" {
            { agSetEnv -Name "<MOCK_Env>" -Value "SomeValue" -Scope ([AgEnvScope]::CURRENT) } | Should -Throw -ExceptionType ([System.InvalidOperationException])
        }
        It "remove illegal variable should throw" {
            { agRemoveEnv -Name "<MOCK_Env>" -Scope ([AgEnvScope]::CURRENT) } | Should -Throw -ExceptionType ([System.InvalidOperationException])
        }
    }
}

Describe "AgEnv process sync tests" {
    BeforeEach {
        agRemoveEnv -Name "TEST_SYNC_VAR" -Scope ([AgEnvScope]::USER)
        Remove-Item Env:TEST_SYNC_VAR -ErrorAction SilentlyContinue
    }

    AfterEach {
        agRemoveEnv -Name "TEST_SYNC_VAR" -Scope ([AgEnvScope]::USER)
        Remove-Item Env:TEST_SYNC_VAR -ErrorAction SilentlyContinue
    }

    It "should set USER scoped variable and reflect into process env by default" {
        agSetEnv -Name "TEST_SYNC_VAR" -Value "SyncedValue" -Scope ([AgEnvScope]::USER)
        $env:TEST_SYNC_VAR | Should -BeExactly "SyncedValue"
    }
}
