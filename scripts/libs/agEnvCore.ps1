# src: ./scripts/libs/agEnvCore.ps1
# @(#) : agEnvCore : Environment Variable Manager
#
# Copyright (c) 2025 atsushifx <atsushifx@gmail.com>
# Released under the MIT License
# https://opensource.org/licenses/MIT

Set-StrictMode -version latest

<#
.SUMMARY
Defines the scope of environment variable targets.
#>
enum agEnvScope {
    Machine = [EnvironmentVariableTarget]::Machine
    User = [EnvironmentVariableTarget]::User
    Process = [EnvironmentVariableTarget]::Process
    # Alias
    System = [EnvironmentVariableTarget]::Machine
    Current = [EnvironmentVariableTarget]::Process
}

# $On $ Off 設定
if (Test-Path variable:On) {
    Set-Variable -Name On -Scope Global -Option ReadOnly -Value $true
}
if (Test-Path variable:Off) {
    Set-Variable -Name Off -Scope Global -Option ReadOnly -Value $false
}

<#
.SUMMARY
Internal static helper class for environment variable operations.
Provides protection against critical environment variable modification.
#>
class _agEnvCore {
    # ----------------
    # public method
    # ----------------

    <#
    .SYNOPSIS
    Sets an environment variable in the specified scope and optionally syncs to Current.
    .DESCRIPTION
    Uses `_SetRaw` to set in the given User or Machine scope.
    If `$Sync` is `$true` and scope is not Current, also sets in Current (Process).
    .PARAMETER Name
    The name of the environment variable.
    .PARAMETER Value
    The value to assign.
    .PARAMETER Scope
    The scope ([agEnvScope] enum) in which to set the variable.
    Defaults to [agEnvScope]::User.
    .PARAMETER Sync
    If `$true` (default), also sets in Current (Process) when scope is not Current.
    #>
    static [void] Set(
        [string] $Name,
        [string] $Value,
        [agEnvScope] $Scope = [agEnvScope]::User,
        [bool] $Sync = $On
    ) {
        [ _agEnvCore ]::_SetRaw($Name, $Value, $Scope)
        if ($Sync -and ($Scope -ne [agEnvScope]::Current)) {
            [ _agEnvCore ]::_SetRaw($Name, $Value, [agEnvScope]::Current)
        }
    }
    <#
    .SYNOPSIS
    Retrieves an environment variable value (defaults to Current scope).
    .DESCRIPTION
    Wraps `_GetRaw`. If no scope is provided, uses `Current` (Process).
    .PARAMETER Name
    Name of the environment variable.
    .PARAMETER Scope
    Scope ([agEnvScope] enum) to retrieve from. Defaults to [agEnvScope]::Current.
    .OUTPUTS
    Returns the variable's value as a string, or $null/empty if not set.
    #>
    static [string] Get(
        [string] $Name,
        [agEnvScope] $Scope = [agEnvScope]::Current
    ) {
        return [ _agEnvCore ]::_GetRaw($Name, $Scope)
    }

    <#
    .SYNOPSIS
    Checks whether an environment variable exists and has a non-empty value
    (defaults to Current scope).
    .DESCRIPTION
    Uses .NET API to get the raw value in the specified scope without validation,
    then returns $true if that value is neither $null nor an empty string.
    .PARAMETER Name
    The name of the environment variable to check.
    .PARAMETER Scope
    The scope ([agEnvScope] enum) in which to check the variable.
    Defaults to [agEnvScope]::Current (Process).
    .OUTPUTS
    Returns a boolean: $true if the variable exists with a non-empty value;
    otherwise $false.
    #>
    static [bool] isEnvExist([string]$name, $scope = [agEnvScope]::Current) {
        return [bool]([_agEnvCore]::_GetRaw($name, $scope))
    }

    # ----------------
    # private method
    # ----------------
    <#
    .SYNOPSIS
    Retrieves the raw value of an environment variable (defaults to Current scope).
    .DESCRIPTION
    Uses .NET API to get the value in the specified scope without validation.
    If no scope is provided, the Current (Process) scope is used.
    .PARAMETER Name
    The name of the environment variable to retrieve.
    .PARAMETER Scope
    The scope ([agEnvScope] enum) in which to look up the variable.
    Defaults to [agEnvScope]::Current (Process).
    .OUTPUTS
    Returns the variable's value as a string, or $null if not set.
    #>
    static [void] _SetRaw([string] $Name, [string] $Value, [agEnvScope] $Scope = [agEnvScope]::Current) {
        [System.Environment]::SetEnvironmentVariable(
            $Name,
            $Value,
            [System.EnvironmentVariableTarget]$Scope
        )
    }

    <#
    .SYNOPSIS
    Retrieves the raw value of an environment variable (defaults to Current scope).
    .DESCRIPTION
    Uses .NET API to get the value in the specified scope without validation.
    If no scope is provided, the Current (Process) scope is used.
    .PARAMETER Name
    The name of the environment variable to retrieve.
    .PARAMETER Scope
    The scope ([agEnvScope] enum) in which to look up the variable.
    Defaults to [agEnvScope]::Current (Process).
    .OUTPUTS
    Returns the variable's value as a string, or $null if not set.
    #>
    static [string] _GetRaw([string] $Name, [agEnvScope] $Scope = [agEnvScope]::Current) {
        return [System.Environment]::GetEnvironmentVariable(
            $Name,
            [System.EnvironmentVariableTarget]$Scope
        )
    }

    <#
    .SYNOPSIS
    Removes the raw value of an environment variable (defaults to Current scope).
    .DESCRIPTION
    Uses .NET API to set the variable to null in the specified scope without validation.
    .PARAMETER Name
    The name of the environment variable to remove.
    .PARAMETER Scope
    The scope ([agEnvScope] enum) in which to remove the variable.
    Defaults to [agEnvScope]::Current (Process).
    .OUTPUTS
    Returns nothing.
    #>
    static [void] _RemoveRaw(
        [string] $Name,
        [agEnvScope] $Scope = [agEnvScope]::Current
    ) {
        [System.Environment]::SetEnvironmentVariable(
            $Name,
            $null,
            [System.EnvironmentVariableTarget]$Scope
        )
    }



 }
