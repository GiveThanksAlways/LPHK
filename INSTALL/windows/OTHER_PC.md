# Other PC setup (Windows)

Clone this repo, create a local venv, then optionally register logon autostart. No extra program is installed. Conda is optional and not required.

From the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\setup-venv.ps1
powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1 -Test
powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1
```

That registers a current-user Task Scheduler job named **LPHK Autostart**. It starts 15 seconds after logon only if a Novation Launchpad is plugged in, then exits. Nothing keeps running in the background when the pad is absent.

Need Python 3 from python.org with **Tcl/Tk** and `python.exe` on PATH. Autostart uses `.venv` if it exists, then a conda env named `lphk` / `LPHK` if you still have one, then `python` on PATH.

Useful commands:

```powershell
powershell -ExecutionPolicy Bypass -File .\launch.ps1
powershell -ExecutionPolicy Bypass -File .\install-autostart.ps1 -Uninstall
powershell -ExecutionPolicy Bypass -File .\RUN_with_conda.ps1
```

`-IncludeHotplug` on `install-autostart.ps1` also starts LPHK when a Novation USB device is plugged in after login. Logon-only is the default.

If autostart does not fire, check `LPHK.autostart.log` in the repo root and Task Scheduler for **LPHK Autostart**.
