#Requires -Version 5.1
<#
.SYNOPSIS
    Reset environment between test runs
.DESCRIPTION
    Lighter cleanup that preserves configuration but removes test artifacts
#>

$ScriptRoot = $PSScriptRoot
$TmpDir = Join-Path $ScriptRoot "tmp"

Write-Host "Resetting test environment..." -ForegroundColor Yellow

# Clean npm cache
try {
    npm cache clean --force 2>$null
    Write-Host "npm cache cleaned" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to clean npm cache"
}

# Remove test artifacts but keep server and config
$cleanupPaths = @(
    "test-*",
    "node_modules", 
    "package-lock.json",
    "*.tgz"
)

foreach ($path in $cleanupPaths) {
    $fullPath = Join-Path $ScriptRoot $path
    if (Test-Path $fullPath) {
        try {
            Remove-Item $fullPath -Recurse -Force
            Write-Host "  Removed: $path" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Failed to remove $path"
        }
    }
}

# Clean tmp directory but recreate it
if (Test-Path $TmpDir) {
    Remove-Item $TmpDir -Recurse -Force
}
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

Write-Host "Reset completed - ready for next test run" -ForegroundColor Green
