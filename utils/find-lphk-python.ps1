# Shared interpreter lookup. Prefer a repo venv; conda is optional fallback.
# Dot-source this file, then call: Find-LphkPython -Repo $PSScriptRoot

function Find-CondaExe {
    $fromPath = Get-Command conda.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    $candidates = @(
        $fromPath,
        "$env:USERPROFILE\AppData\Local\miniconda3\Scripts\conda.exe",
        "$env:LOCALAPPDATA\miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\Miniconda3\Scripts\conda.exe",
        "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
        "$env:USERPROFILE\Anaconda3\Scripts\conda.exe",
        "$env:LOCALAPPDATA\anaconda3\Scripts\conda.exe",
        "$env:ProgramData\miniconda3\Scripts\conda.exe",
        "$env:ProgramData\anaconda3\Scripts\conda.exe"
    )

    foreach ($path in $candidates) {
        if ($path -and (Test-Path -LiteralPath $path)) {
            return $path
        }
    }

    return $null
}

function Find-LphkPython {
    param([Parameter(Mandatory = $true)][string]$Repo)

    foreach ($venvDir in @(".venv", "venv")) {
        $python = Join-Path $Repo "$venvDir\Scripts\python.exe"
        if (Test-Path -LiteralPath $python) {
            return $python
        }
    }

    $conda = Find-CondaExe
    if ($conda) {
        $root = Split-Path (Split-Path $conda)
        foreach ($envName in @("lphk", "LPHK")) {
            $python = Join-Path $root "envs\$envName\python.exe"
            if (Test-Path -LiteralPath $python) {
                return $python
            }
        }
    }

    $fromPath = Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
    if ($fromPath) {
        return $fromPath
    }

    return $null
}
