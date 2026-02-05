@echo off
setlocal EnableExtensions

echo === Compile ===
echo.

:: Set paths
set "ScriptDir=%~dp0"
set "Compiler=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
set "BaseFile=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

:: Check if compiler exists
if not exist "%Compiler%" (
    echo [ERROR] Compiler not found: %Compiler%
    echo Please install AutoHotkey v2 with the compiler component.
    goto :end
)

:: Ask what to compile
echo Select script to compile:
echo   1. autoclick.ahk
echo   2. rivalability.ahk
echo.
choice /c 12 /n /m "Enter choice (1/2): "

if errorlevel 2 (
    set "SourceFile=%ScriptDir%rivalability.ahk"
    set "OutputFile=%ScriptDir%rivalability.exe"
) else (
    set "SourceFile=%ScriptDir%autoclick.ahk"
    set "OutputFile=%ScriptDir%autoclick.exe"
)

:: Check if source file exists
if not exist "%SourceFile%" (
    echo [ERROR] Source file not found: %SourceFile%
    goto :end
)

set "IconFile=%ScriptDir%img\app-icon.ico"

echo.
echo Compiling...
echo   Source: %SourceFile%
echo   Output: %OutputFile%
echo.

:: Compile the script
"%Compiler%" /in "%SourceFile%" /out "%OutputFile%" /base "%BaseFile%" /icon "%IconFile%"

if exist "%OutputFile%" (
    echo [OK] Compilation successful.
    echo.
    for %%A in ("%OutputFile%") do echo   Size: %%~zA bytes
) else (
    echo [ERROR] Compilation failed.
)

:end
echo.
pause
endlocal
