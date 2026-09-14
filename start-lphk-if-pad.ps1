# Starts LPHK only if a Novation Launchpad is already connected.
# Called by the "LPHK Autostart" scheduled task. Exits immediately; does not loop.
#
#   powershell -ExecutionPolicy Bypass -File .\start-lphk-if-pad.ps1 -Test

param(
    [switch]$Test,
    [switch]$SkipPadCheck
)

$ErrorActionPreference = "Continue"
$repo = $PSScriptRoot
$logFile = Join-Path $repo "LPHK.autostart.log"
$outLog = Join-Path $repo "LPHK.out.log"
$errLog = Join-Path $repo "LPHK.err.log"

# Focusrite/Novation VID 1235. PIDs cover Launchpad models LPHK already supports.
$launchpadPidPattern = "USB\\VID_1235&PID_(000E|0020|0036|0051|0069|0103|0113|0123)"

function Write-AutostartLog {
    param([string]$Message)
    $line = "{0} {1}" -f (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"), $Message
    Add-Content -Path $logFile -Value $line -ErrorAction SilentlyContinue
    if ($Test) {
        Write-Host $line
    }
}

function Test-LphkRunning {
    Get-CimInstance -ClassName Win32_Process -Filter "Name='python.exe' OR Name='pythonw.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'LPHK\.py' }
}

function Test-LaunchpadPresent {
    $devices = Get-CimInstance -ClassName Win32_PnPEntity -Filter "PNPDeviceID LIKE '%VID_1235%' OR Name LIKE '%Launchpad%'" -ErrorAction SilentlyContinue
    if (-not $devices) {
        return $false
    }

    $connected = $devices | Where-Object {
        $_.ConfigManagerErrorCode -eq 0 -and (
            $_.PNPDeviceID -match $launchpadPidPattern -or
            $_.Name -match 'Launchpad'
        )
    }

    return [bool]$connected
}

. (Join-Path $repo "utils\find-lphk-python.ps1")

$alreadyRunning = [bool](Test-LphkRunning)
$padPresent = Test-LaunchpadPresent
$python = Find-LphkPython -Repo $repo

if ($Test) {
    Write-AutostartLog "test already-running=$alreadyRunning pad=$padPresent python=$python"
    if (-not $python) { exit 1 }
    exit 0
}

if ($alreadyRunning) {
    Write-AutostartLog "skip already-running"
    exit 0
}

if (-not $SkipPadCheck) {
    if (-not $padPresent) {
        Start-Sleep -Seconds 5
        $padPresent = Test-LaunchpadPresent
    }
    if (-not $padPresent) {
        Write-AutostartLog "skip no-launchpad"
        exit 0
    }
}

if (-not $python) {
    Write-AutostartLog "error no-python"
    exit 1
}

Write-AutostartLog "start python=$python"
Start-Process -FilePath $python -ArgumentList "LPHK.py" -WorkingDirectory $repo -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
exit 0
