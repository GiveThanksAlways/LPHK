# One-time per PC: register a current-user scheduled task that starts LPHK at logon
# if a Novation Launchpad is connected. No admin, no extra software, no background watcher.
#
# Full other-PC steps: INSTALL\windows\OTHER_PC.md
# Default interpreter is repo .venv (setup-venv.ps1). Conda is optional fallback.
#
# After cloning this repo:
#   powershell -ExecutionPolicy Bypass -File .\setup-venv.ps1
#   powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1
#   powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1 -Test
#   powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1 -Uninstall
#   powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1 -IncludeHotplug

param(
    [switch]$Uninstall,
    [switch]$Test,
    [switch]$IncludeHotplug,
    [int]$LogonDelaySeconds = 15
)

$ErrorActionPreference = "Stop"
$taskName = "LPHK Autostart"
$repo = $PSScriptRoot
$launcher = Join-Path $repo "start-lphk-if-pad.ps1"

if (-not (Test-Path -LiteralPath $launcher)) {
    throw "Missing launcher: $launcher"
}

if ($Uninstall) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Write-Host "Removed scheduled task '$taskName'."
    exit 0
}

if ($Test) {
    & $launcher -Test
    exit $LASTEXITCODE
}

$who = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$powershell = Join-Path $env:SystemRoot "System32\WindowsPowerShell\v1.0\powershell.exe"
$action = New-ScheduledTaskAction -Execute $powershell -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$launcher`"" -WorkingDirectory $repo

$logon = New-ScheduledTaskTrigger -AtLogOn -User $who
$logon.Delay = "PT{0}S" -f $LogonDelaySeconds
$triggers = @($logon)

if ($IncludeHotplug) {
    try {
        $eventClass = Get-CimClass -Namespace "Root/Microsoft/Windows/TaskScheduler" -ClassName "MSFT_TaskEventTrigger"
        $usb = New-CimInstance -CimClass $eventClass -ClientOnly
        $usb.Enabled = $true
        $usb.Subscription = @"
<QueryList>
  <Query Id="0" Path="Microsoft-Windows-Kernel-PnP/Configuration">
    <Select Path="Microsoft-Windows-Kernel-PnP/Configuration">
      *[System[(EventID=400)]] and *[EventData[Data[contains(., 'VID_1235')]]]
    </Select>
  </Query>
</QueryList>
"@
        $triggers += $usb
        Write-Host "Hotplug trigger added (Kernel-PnP Event 400, Novation VID_1235)."
    }
    catch {
        Write-Warning "Could not add USB hotplug trigger; logon trigger will still be installed. $_"
    }
}

$principal = New-ScheduledTaskPrincipal -UserId $who -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit (New-TimeSpan -Minutes 2) `
    -Hidden

Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $triggers -Principal $principal -Settings $settings -Description "Start LPHK at logon when a Novation Launchpad is connected. Installed from $repo" | Out-Null

Write-Host "Registered scheduled task '$taskName' for $who."
Write-Host "Starts $LogonDelaySeconds seconds after logon, only if a Launchpad is present."
Write-Host "Re-run this script after cloning onto another PC. Use -Uninstall to remove."
Write-Host "Check detection now with: powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1 -Test"
