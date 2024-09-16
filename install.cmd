@echo off
:: getting startup folder of current user (https://stackoverflow.com/a/68019702)
setlocal EnableExtensions DisableDelayedExpansion
set "StartupDir="
for /F "skip=1 tokens=1,2*" %%I in ('%SystemRoot%\System32\reg.exe QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Startup 2^>nul') do if /I "%%I" == "Startup" if not "%%~K" == "" if "%%J" == "REG_SZ" (set "StartupDir=%%~K") else if "%%J" == "REG_EXPAND_SZ" call set "StartupDir=%%~K"
if not defined StartupDir for /F "skip=1 tokens=1,2*" %%I in ('%SystemRoot%\System32\reg.exe QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Startup 2^>nul') do if /I "%%I" == "Startup" if not "%%~K" == "" if "%%J" == "REG_SZ" (set "StartupDir=%%~K") else if "%%J" == "REG_EXPAND_SZ" call set "StartupDir=%%~K"
if not defined StartupDir set "StartupDir=\"
if "%StartupDir:~-1%" == "\" set "StartupDir=%StartupDir:~0,-1%"
if not defined StartupDir set "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
::echo %StartupDir%

set CurrentDir=%CD%

:: create shortcut with Powershell command
set ShortcutName=autoclick-shortcut.lnk
set Target='%CurrentDir%\autoclick.exe'
set Shortcut='%StartupDir%\%ShortcutName%'
set PS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile
%PS% -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(%Shortcut%); $S.TargetPath = %Target%; $S.Save()"

:prompt
set /P OPEN=Open startup folder? Y/[N]
if /I "%OPEN%" neq "Y" goto end
start shell:startup
:end

endlocal
