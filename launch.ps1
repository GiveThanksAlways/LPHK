$python = "python"
$workDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outLog = Join-Path $workDir "LPHK.out.log"
$errLog = Join-Path $workDir "LPHK.err.log"

Start-Process -FilePath $python -ArgumentList "LPHK.py" -WorkingDirectory $workDir -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog
Exit 0