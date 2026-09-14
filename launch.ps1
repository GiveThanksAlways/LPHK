# Launch LPHK detached. Prefers repo .venv, then conda env lphk/LPHK, then python on PATH.

$workDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $workDir "utils\find-lphk-python.ps1")

$python = Find-LphkPython -Repo $workDir
if (-not $python) {
    throw "No Python found. Run setup-venv.ps1 (preferred) or install a conda env named lphk."
}

$outLog = Join-Path $workDir "LPHK.out.log"
$errLog = Join-Path $workDir "LPHK.err.log"

Start-Process -FilePath $python -ArgumentList "LPHK.py" -WorkingDirectory $workDir -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
Exit 0
