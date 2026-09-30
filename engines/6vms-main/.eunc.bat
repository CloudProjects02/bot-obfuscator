@echo off
REM .eunc.bat - UNC Test Environment Logger
REM Runs e-UNC test through 6Vms environment logger (main.luau + lune.exe)

set SCRIPT_DIR=%~dp0
cd /d "%SCRIPT_DIR%"

set SCRIPT_PATH=unc_test.lua
set OUTPUT_PATH=unc_out.lua

if not exist lune.exe (
    echo Error: lune.exe not found in %SCRIPT_DIR%
    exit /b 1
)

if not exist main.luau (
    echo Error: main.luau not found in %SCRIPT_DIR%
    exit /b 1
)

if not exist %SCRIPT_PATH% (
    echo Downloading latest UNC test...
    powershell -Command "Invoke-WebRequest -Uri 'https://e-unc.vercel.app/script.lua' -OutFile '%SCRIPT_PATH%'"
    if errorlevel 1 (
        echo Failed to download UNC test
        exit /b 1
    )
)

echo Running UNC test through 6Vms environment logger...
echo Script: %SCRIPT_PATH%
echo Output: %OUTPUT_PATH%

REM Settings optimized for UNC test spoofing:
REM roblox=true - Enable Roblox-compatible behavior
REM spyexeconly=true - Only spy executor functions (reduces noise)
REM explore_funcs=false - Don't explore all functions (speeds up)
REM inf_loops=false - Disable infinite loop protection
REM constants=false - Don't process constants
REM hookOp=true - Enable hookOp for obfuscation handling
REM isPremium=true - Enable premium features
REM minifier=true - Minify output

REM Use relative path for ipt argument
lune.exe run main.luau ipt=%SCRIPT_PATH% roblox=true spyexeconly=true explore_funcs=false inf_loops=false constants=false hookOp=true isPremium=true minifier=true out=%OUTPUT_PATH%

if exist %OUTPUT_PATH% (
    echo.
    echo Finished! Output written to %OUTPUT_PATH%
    echo.
    echo --- Output preview ---
    head -20 %OUTPUT_PATH% 2>nul || powershell -Command "Get-Content '%OUTPUT_PATH%' -TotalCount 20"
    echo --- End preview ---
) else (
    echo Warning: No output file generated
)