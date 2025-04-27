# Copyright (c) 2025 Furukawa Atsushi <atsushifx@gmail.com>
#
# This software is released under the MIT License.
# https://opensource.org/licenses/MIT
Set-Variable -Scope Script -Option ReadOnly -Name SCRIPTROOT -Value (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Variable -Name testRoot -Value (Join-Path $SCRIPTROOT "tests")
Write-output "testRoot: $testRoot"

Invoke-Pester -Path $testRoot -Verbose
