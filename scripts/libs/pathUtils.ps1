# モジュール共通内部ヘルパー: Create-DirectoryPath
function local:createDirectoryWithCurrent {
    param(
        [string]$Path,
        [switch]$DryRun
    )

    $trimmed = $Path.Trim()

    if ([string]::IsNullOrWhiteSpace($trimmed)) {
        throw [System.ArgumentException]::new("Invalid path: empty or whitespace only.")
    }

    if ($trimmed -match '^([/\\\*\|\:\?\"\<\>]|\s)+$') {
        throw [System.ArgumentException]::new("Invalid path: only forbidden characters like [\\/:*] are not allowed.")
    }

    if ($trimmed.StartsWith('~/')) {
        $fullPath = Join-Path $env:USERPROFILE $trimmed.Substring(2)
    }
    elseif ([System.IO.Path]::IsPathRooted($trimmed)) {
        $fullPath = $trimmed
    }
    else {
        $fullPath = Join-Path (Get-Location) $trimmed
    }

    if (-not $DryRun) {
        New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
    }

    return $fullPath
}

# パイプ入力対応メイン関数: mkdirFromList
function mkdirFromList {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]]$PathList,

        [switch]$DryRun
    )
    begin {
        $script:createdPaths = @()
    }

    process {
        foreach ($path in $PathList) {
            $script:createdPaths += createDirectoryWithCurrent -Path $path -DryRun:$DryRun
        }
    }
    end {
        return $script:createdPaths
    }
}
