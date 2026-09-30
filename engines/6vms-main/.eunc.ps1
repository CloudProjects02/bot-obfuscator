<#
.SYNOPSIS
    .eunc - UNC Test Environment Logger
    Runs e-UNC test through 6Vms environment logger (main.luau + lune.exe)
    Attempts to spoof executor checks to achieve 100% score

.DESCRIPTION
    This script runs the UNC test script through the 6Vms decompiler/environment logger
    with settings optimized for executor spoofing. It uses main.luau and lune.exe only.

.EXAMPLE
    .\.eunc.ps1
    .\.eunc.ps1 -ScriptPath "path\to\script.lua"
    .\.eunc.ps1 -OutputPath "unc_result.lua"
#>

param(
    [string]$ScriptPath = "unc_test.lua",
    [string]$OutputPath = "unc_out.lua",
    [switch]$DownloadLatest,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

# Check for lune.exe
$LuneExe = Join-Path $ScriptDir "lune.exe"
if (-not (Test-Path $LuneExe)) {
    Write-Error "lune.exe not found at $LuneExe"
    exit 1
}

# Check for main.luau
$MainLuau = Join-Path $ScriptDir "main.luau"
if (-not (Test-Path $MainLuau)) {
    Write-Error "main.luau not found at $MainLuau"
    exit 1
}

# Download latest UNC test if requested
if ($DownloadLatest) {
    Write-Host "Downloading latest UNC test from e-unc.vercel.app..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri "https://e-unc.vercel.app/script.lua" -OutFile $ScriptPath -ErrorAction Stop
        Write-Host "Downloaded to $ScriptPath" -ForegroundColor Green
    } catch {
        Write-Error "Failed to download UNC test: $_"
        exit 1
    }
}

# Check for script
$FullScriptPath = Join-Path $ScriptDir $ScriptPath
if (-not (Test-Path $FullScriptPath)) {
    Write-Error "Script not found at $FullScriptPath. Use -DownloadLatest to fetch it."
    exit 1
}

Write-Host "Running UNC test through 6Vms environment logger..." -ForegroundColor Cyan
Write-Host "Script: $ScriptPath" -ForegroundColor Gray
Write-Host "Output: $OutputPath" -ForegroundColor Gray

# Settings optimized for UNC test spoofing:
# - roblox=true: Enable Roblox-compatible behavior
# - spyexeconly=true: Only spy executor functions (reduces noise)
# - explore_funcs=false: Don't explore all functions (speeds up)
# - inf_loops=false: Disable infinite loop protection (UNC test has many loops)
# - constants=false: Don't process constants
# - hookOp=true: Enable hookOp for obfuscation handling
# - isPremium=true: Enable premium features
# - minifier=true: Minify output
$Settings = @(
    "roblox=true",
    "spyexeconly=true",
    "explore_funcs=false",
    "inf_loops=false",
    "constants=false",
    "hookOp=true",
    "isPremium=true",
    "minifier=true",
    "out=$OutputPath"
)

# Use relative path for ipt argument
$RelScriptPath = $ScriptPath
$Args = @("run", $MainLuau, "ipt=$RelScriptPath") + $Settings

if ($Verbose) {
    Write-Host "Command: $LuneExe $Args" -ForegroundColor Gray
}

$StartTime = Get-Date
try {
    & $LuneExe @Args
} catch {
    Write-Error "Execution failed: $_"
    exit 1
}
$EndTime = Get-Date

$Duration = ($EndTime - $StartTime).TotalSeconds
Write-Host "Finished in $($Duration.ToString('F2')) seconds" -ForegroundColor Green

# Check output
$FullOutputPath = Join-Path $ScriptDir $OutputPath
if (Test-Path $FullOutputPath) {
    $OutputSize = (Get-Item $FullOutputPath).Length
    Write-Host "Output written to $OutputPath ($OutputSize bytes)" -ForegroundColor Green
    
    # Show first few lines of output
    $Content = Get-Content $FullOutputPath -TotalCount 20
    Write-Host "--- Output preview ---" -ForegroundColor Cyan
    $Content | ForEach-Object { Write-Host $_ }
    Write-Host "--- End preview ---" -ForegroundColor Cyan
} else {
    Write-Warning "No output file generated at $OutputPath"
}

# Check for score in output (UNC tests typically print score)
if (Test-Path $FullOutputPath) {
    $FullContent = Get-Content $FullOutputPath -Raw
    if ($FullContent -match '(\d+)%\s*(?:passed|score|UNC)') {
        $Score = $matches[1]
        Write-Host "UNC Score: $Score%" -ForegroundColor Magenta
    } elseif ($FullContent -match 'score.*?(\d+)') {
        $Score = $matches[1]
        Write-Host "Detected score: $Score" -ForegroundColor Magenta
    }
}