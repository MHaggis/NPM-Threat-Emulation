#Requires -Version 5.1
<#
.SYNOPSIS
    Clean up NPM Threat Emulation test environment
.DESCRIPTION
    Removes all artifacts, stops server, clears npm cache, and cleans temp directories
#>

$ScriptRoot = $PSScriptRoot
$TmpDir = Join-Path $ScriptRoot "tmp"

Write-Host "NPM Threat Emulation - Environment Cleanup" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan

# Stop mock server with timeout
Write-Host "Stopping mock server..." -ForegroundColor Yellow
try {
    $stopScript = Join-Path $ScriptRoot "Stop-Server.ps1"
    if (Test-Path $stopScript) {
        # Run stop script with timeout
        $job = Start-Job -ScriptBlock {
            param($StopScript)
            & $StopScript
        } -ArgumentList $stopScript
        
        # Wait max 10 seconds for stop script to complete
        $completed = Wait-Job $job -Timeout 10
        if ($completed) {
            Receive-Job $job
            Remove-Job $job
        } else {
            Write-Host "Stop script timed out, forcing cleanup..." -ForegroundColor Yellow
            Stop-Job $job
            Remove-Job $job -Force
            
            # Force stop any mock server jobs
            Get-Job -Name "MockServer" -ErrorAction SilentlyContinue | Stop-Job -PassThru | Remove-Job -Force
        }
    }
}
catch {
    Write-Host "Error stopping server: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Clean npm cache
Write-Host "Cleaning npm cache..." -ForegroundColor Yellow
try {
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        npm cache clean --force 2>$null
        Write-Host "npm cache cleaned" -ForegroundColor Green
    } else {
        Write-Host "npm not found, skipping cache clean" -ForegroundColor Gray
    }
}
catch {
    Write-Warning "Failed to clean npm cache: $($_.Exception.Message)"
}

# Remove temp directories and artifacts
Write-Host "Removing temporary files and directories..." -ForegroundColor Yellow

$cleanupPaths = @(
    $TmpDir,
    "test-*",
    "node_modules",
    "package-lock.json",
    "*.tgz",
    ".env"
)

foreach ($path in $cleanupPaths) {
    $fullPath = if ([System.IO.Path]::IsPathRooted($path)) { $path } else { Join-Path $ScriptRoot $path }
    
    if (Test-Path $fullPath) {
        try {
            Remove-Item $fullPath -Recurse -Force -ErrorAction Stop
            Write-Host "  Removed: $path" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Failed to remove $path : $($_.Exception.Message)"
        }
    }
}

# Clean up any test repositories
try {
    $testRepos = Get-ChildItem -Path $ScriptRoot -Directory -ErrorAction SilentlyContinue | 
                 Where-Object { $_.Name -match "^test-" }
    
    foreach ($repo in $testRepos) {
        try {
            Remove-Item $repo.FullName -Recurse -Force
            Write-Host "  Removed test repo: $($repo.Name)" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Failed to remove test repo $($repo.Name): $($_.Exception.Message)"
        }
    }
}
catch {
    # Ignore errors in test repo cleanup
}

# Clear environment variables
$env:FAKE_NPM_TOKEN = $null
$env:FAKE_GITHUB_TOKEN = $null
$env:FAKE_AWS_KEY = $null
$env:MOCK_WEBHOOK = $null

Write-Host ""
Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "Environment variables cleared" -ForegroundColor Gray
Write-Host "All temporary files and artifacts removed" -ForegroundColor Gray

# Final check for any remaining jobs
$remainingJobs = Get-Job -Name "MockServer" -ErrorAction SilentlyContinue
if ($remainingJobs) {
    Write-Host "Cleaning up remaining background jobs..." -ForegroundColor Yellow
    $remainingJobs | Stop-Job -PassThru | Remove-Job -Force
}