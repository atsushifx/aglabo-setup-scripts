# src: libs/agEnv.ps1
# @(#) : AgEnv : Environment Variable Manager
#
# Copyright (c) 2025 atsushifx <atsushifx@gmail.com>
# Released under the MIT License
# https://opensource.org/licenses/MIT

Set-StrictMode -version latest

# ─────────────────────────────────────
# Enum: AgEnvScope
# ─────────────────────────────────────
<#
.SUMMARY
Defines the scope of environment variable targets.
#>
enum AgEnvScope {
    CURRENT = [System.EnvironmentVariableTarget]::Process
    USER = [System.EnvironmentVariableTarget]::User
    SYSTEM = [System.EnvironmentVariableTarget]::Machine
}

<#
.SUMMARY
Internal static helper class for environment variable operations.
Provides protection against critical environment variable modification.
#>
class _AgEnvManager {
    static [string[]]$_protectedKeys = @(
        "Path",
        "PathExt",
        "PSModulePath",
        "TMP",
        "TEMP"
    )

    <#
    .SUMMARY
    Sets an environment variable internally
    #>
    static [void] _setEnvScoped([string]$Name, [string]$Value, [AgEnvScope]$Scope = [AgEnvScope]::CURRENT) {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
    }

    <#
    .SUMMARY
    Sets an environment variable internally.
    #>
    static [void] _setEnv(
        [string]$Name,
        [string]$Value,
        [AgEnvScope]$Scope,
        [bool]$NoSync = $false
    ) {
        $Name = $Name.Trim()
        $Value = $Value.Trim()

        if ([string]::IsNullOrWhiteSpace($Name)) {
            throw [System.ArgumentException]::new("Environment variable name cannot be empty or whitespace.")
        }

        if ([_AgEnvManager]::_isProtected($Name)) {
            throw [System.InvalidOperationException]::new("Modification of protected variable '$Name' is not allowed.")
        }
        [_AgEnvManager]::_setEnvScoped($Name, $Value, $Scope)
        if (-not $NoSync -and $Scope -ne [AgEnvScope]::CURRENT) {
            [_AgEnvManager]::_setEnvScoped($Name, $Value, [AgEnvScope]::CURRENT)
        }
    }


    <#
    .SUMMARY
    Gets the value of an environment variable internally.
    #>
    static [string] _getEnv([string]$Name, [AgEnvScope]$Scope = [AgEnvScope]::CURRENT) {
        return [Environment]::GetEnvironmentVariable($Name, $Scope)
    }

    <#
    .SUMMARY
    Removes an environment variable internally.
    #>
    static [void] _removeEnv([string]$Name, [AgEnvScope]$Scope = [AgEnvScope]::CURRENT, [bool]$NoSync = $false) {
        $Name = $Name.Trim()

        if ([string]::IsNullOrWhiteSpace($Name)) {
            throw [System.ArgumentException]::new("Environment variable name cannot be empty or whitespace.")
        }

        if ([_AgEnvManager]::_isProtected($Name)) {
            throw [System.InvalidOperationException]::new("Modification of protected variable '$Name' is not allowed.")
        }
        [_AgEnvManager]::_setEnvScoped($Name, $null, $Scope)
        if (-not $NoSync -and $Scope -ne [AgEnvScope]::CURRENT) {
            [_AgEnvManager]::_setEnvScoped($Name, $null, [AgEnvScope]::CURRENT)
        }
    }

    <#
    .SUMMARY
    Determines if the given environment variable name is protected.
    #>
    static [Boolean] _isProtected([string]$Name) {
        $upperKeys = [_AgEnvManager]::_protectedKeys | ForEach-Object { $_.ToUpperInvariant() }
        return ($upperKeys -contains ($Name.ToUpperInvariant()))
    }
}

# ─────────────────────────────────────
# 外部公開用関数
# ─────────────────────────────────────
<#
.SUMMARY
Sets an environment variable with optional process synchronization.
.PARAMETER Name
The name of the environment variable (trimmed automatically).
.PARAMETER Value
The value to assign (trimmed automatically).
.PARAMETER Scope
The scope where the variable is set (default: USER).
.PARAMETER NoSync
Switch to disable process environment synchronization.
#>
function agSetEnv {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter()]
        [AgEnvScope]$Scope = [AgEnvScope]::USER,

        [switch]$NoSync
    )

    $Name = $Name.Trim()
    $Value = $Value.Trim()
    [_AgEnvManager]::_setEnv($Name, $Value, $Scope, $NoSync)
}

# ─────────────────────────────────────
# Function: agGetEnv
# ─────────────────────────────────────
<#
.SUMMARY
Retrieves the value of an environment variable.
.PARAMETER Name
The name of the environment variable (trimmed automatically).
.PARAMETER Scope
The scope from which to retrieve (default: CURRENT).
.RETURNS
The value of the environment variable or $null if not found.
#>
function agGetEnv {
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [AgEnvScope]$Scope = [AgEnvScope]::CURRENT
    )

    $Name = $Name.Trim()

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw [System.ArgumentException]::new("Environment variable name cannot be empty or whitespace.")
    }

    return [_AgEnvManager]::_getEnv($Name, $Scope)
}

# ─────────────────────────────────────
# Function: agRemoveEnv
# ─────────────────────────────────────
<#
.SUMMARY
Removes an environment variable with optional process synchronization.
.PARAMETER Name
The name of the environment variable to remove (trimmed automatically).
.PARAMETER Scope
The scope where the variable is removed (default: USER).
.PARAMETER NoSync
Switch to disable process environment synchronization.
#>
function agRemoveEnv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter()]
        [AgEnvScope]$Scope = [AgEnvScope]::USER,

        [switch]$NoSync
    )
    [_AgEnvManager]::_removeEnv($Name, $Scope, $NoSync)

}
