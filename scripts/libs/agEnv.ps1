# src: libs/agEnv.ps1
# @(#) : AgEnv : Environment Variable Manager
#
# Copyright (c) 2025 atsushifx <atsushifx@gmail.com>
# Released under the MIT License
# https://opensource.org/licenses/MIT

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

# ─────────────────────────────────────
# Class: AgEnv (Internal Helper)
# ─────────────────────────────────────
<#
.SUMMARY
Internal static helper class for environment variable operations.
Provides protection against critical environment variable modification.
#>
class AgEnv {
    static [string[]]$ProtectedKeys = @(
        "Path",
        "PathExt",
        "PSModulePath",
        "TMP",
        "TEMP"
    )

    <#
    .SUMMARY
    Sets an environment variable internally without validation.
    #>
    static [void] _setEnv([string]$Name, [string]$Value, [AgEnvScope]$Scope = [AgEnvScope]::CURRENT) {
        [Environment]::SetEnvironmentVariable($Name, $Value, $Scope)
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
    static [void] _removeEnv([string]$Name, [AgEnvScope]$Scope = [AgEnvScope]::CURRENT) {
        [Environment]::SetEnvironmentVariable($Name, $null, $Scope)
    }

    <#
    .SUMMARY
    Determines if the given environment variable name is protected.
    #>
    static [Boolean] isProtected([string]$Name) {
        $upperKeys = [AgEnv]::ProtectedKeys | ForEach-Object { $_.ToUpperInvariant() }
        return ($upperKeys -contains ($Name.ToUpperInvariant()))
    }
}

# ─────────────────────────────────────
# Function: agSetEnv
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

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw [System.ArgumentException]::new("Environment variable name cannot be empty or whitespace.")
    }

    if ([AgEnv]::isProtected($Name)) {
        throw [System.InvalidOperationException]::new("Setting of protected variable '$Name' is not allowed.")
    }

    [AgEnv]::_setEnv($Name, $Value, $Scope)

    if (-not $NoSync -and $Scope -ne [AgEnvScope]::CURRENT) {
        [AgEnv]::_setEnv($Name, $Value, [AgEnvScope]::CURRENT)
    }
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

    return [AgEnv]::_getEnv($Name, $Scope)
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

    $Name = $Name.Trim()

    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw [System.ArgumentException]::new("Environment variable name cannot be empty or whitespace.")
    }

    if ([AgEnv]::isProtected($Name)) {
        throw [System.InvalidOperationException]::new("Removal of protected variable '$Name' is not allowed.")
    }

    [AgEnv]::_removeEnv($Name, $Scope)

    if (-not $NoSync -and $Scope -ne [AgEnvScope]::CURRENT) {
        [AgEnv]::_removeEnv($Name, [AgEnvScope]::CURRENT)
    }
}

# ─────────────────────────────────────
# Function: agSetEnvFromList
# ─────────────────────────────────────
<#
.SUMMARY
Sets multiple environment variables from a list.
.PARAMETER Items
A list of two-element arrays (VariableName, Value).
.PARAMETER Scope
The scope to apply (default: USER).
.PARAMETER NoSync
Switch to disable process environment synchronization.
#>
function agSetEnvFromList {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true
        )]
        [string[][]]$Items,

        [Parameter()]
        [AgEnvScope]$Scope = [AgEnvScope]::USER,

        [switch]$NoSync
    )

    process {
        foreach ($Item in $Items) {
            if ($Item.Count -ge 2) {
                $varName = $Item[0].Trim()
                $varValue = $Item[1].Trim()

                if ([string]::IsNullOrWhiteSpace($varName)) {
                    throw [System.ArgumentException]::new("Environment variable name cannot be empty or whitespace.")
                }

                agSetEnv -Name $varName -Value $varValue -Scope $Scope -NoSync:$NoSync
            }
            else {
                throw [System.ArgumentException]::new(
                    "Each item must have exactly 2 elements: VariableName and Value."
                )
            }
        }
    }
}
