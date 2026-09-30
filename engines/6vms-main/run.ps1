param(
    [string]$Script = "main.luau",
    [string[]]$Args = @()
)

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$lune = Join-Path $root "lune.exe"
$lute = Join-Path $root "lute.exe"

if (Test-Path $lune) {
    if ($Args.Count -gt 0) {
        & $lune run $Script @Args
    } else {
        & $lune run $Script
    }
} elseif (Test-Path $lute) {
    & $lute $Script @Args
} else {
    Write-Error "Neither lune.exe nor lute.exe found"
    exit 1
}
