# One-time per PC: create .venv and install Windows runtime deps.
# Conda is not required. After this, run install-autostart.ps1 if you want logon start.
#
#   powershell -ExecutionPolicy Bypass -File .\setup-venv.ps1

$ErrorActionPreference = "Stop"
$repo = $PSScriptRoot
$venvPython = Join-Path $repo ".venv\Scripts\python.exe"

function Find-SystemPython {
    $pyLauncher = Get-Command py.exe -ErrorAction SilentlyContinue
    if ($pyLauncher) {
        return $pyLauncher.Source
    }

    $python = Get-Command python.exe -ErrorAction SilentlyContinue
    if ($python) {
        return $python.Source
    }

    return $null
}

$systemPython = Find-SystemPython
if (-not $systemPython) {
    throw "No system Python found. Install Python 3 from python.org (include Tcl/Tk and add python.exe to PATH), then re-run this script."
}

if (-not (Test-Path -LiteralPath $venvPython)) {
    Write-Host "Creating .venv with $systemPython"
    if ((Split-Path $systemPython -Leaf) -eq "py.exe") {
        & $systemPython -3 -m venv (Join-Path $repo ".venv")
    }
    else {
        & $systemPython -m venv (Join-Path $repo ".venv")
    }
}

if (-not (Test-Path -LiteralPath $venvPython)) {
    throw "venv was not created at $venvPython"
}

Write-Host "Installing LPHK dependencies into .venv"
& $venvPython -m pip install --upgrade pip
& $venvPython -m pip install `
    "Pillow>=10.0.0" `
    "pygame>=2.6.0" `
    "pynput==1.7.7" `
    "tkcolorpicker==2.1.3" `
    "py-getch==1.0.1" `
    "PyAutoGUI==0.9.54" `
    "git+https://github.com/FMMT666/launchpad.py.git@master"

Write-Host "venv ready: $venvPython"
Write-Host "Launch with launch.ps1, or register logon start with install-autostart.ps1"
