# Optional conda launcher. Default path is setup-venv.ps1 + launch.ps1.
# This uses Start-Process so the launched process does not exit when this PowerShell session closes.

$workDir = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $workDir "utils\find-lphk-python.ps1")

$condaPath = Find-CondaExe
if (-not $condaPath) {
    throw "conda.exe not found. Install Miniconda or add conda to PATH."
}

$outLog = Join-Path $workDir "LPHK.out.log"
$errLog = Join-Path $workDir "LPHK.err.log"
$condaRoot = Split-Path (Split-Path $condaPath)
$envName = @("lphk", "LPHK") | Where-Object { Test-Path -LiteralPath (Join-Path $condaRoot "envs\$_\python.exe") } | Select-Object -First 1
if (-not $envName) {
    $envName = "lphk"
}

$argList = @("run", "-n", $envName, "python", "LPHK.py")

Start-Process -FilePath $condaPath -ArgumentList $argList -WorkingDirectory $workDir -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog

# Exit the PowerShell script immediately; the launched process runs independently.
Exit 0