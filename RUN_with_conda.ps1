# Launch LPHK in a detached process using the conda environment 'lphk'
# This uses Start-Process so the launched process does not exit when this PowerShell session closes.

$condaPath = "C:\Users\spencer.willett\AppData\Local\miniconda3\Scripts\conda.exe"
$workDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$outLog = Join-Path $workDir "LPHK.out.log"
$errLog = Join-Path $workDir "LPHK.err.log"

# Arguments: run -n <env> python <script>
$argList = @('run','-n','lphk','python','LPHK.py')

Start-Process -FilePath $condaPath -ArgumentList $argList -WorkingDirectory $workDir -WindowStyle Hidden -RedirectStandardOutput $outLog -RedirectStandardError $errLog

# Exit the PowerShell script immediately; the launched process runs independently.
Exit 0