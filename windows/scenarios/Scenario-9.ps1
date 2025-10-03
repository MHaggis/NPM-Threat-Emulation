#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 9: Bundle Worm Chain Simulation
.DESCRIPTION
    Creates a weaponized tarball with bundle.js and spawns additional scripts for persistence
#>

Write-Host "Scenario 9: Bundle Worm Chain Simulation" -ForegroundColor Yellow

# Check if Node.js is available
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "Node.js is required for Scenario 9." -ForegroundColor Red
    Write-Host "Scenario 9 skipped" -ForegroundColor Yellow
    return
}

$RootDir = $PSScriptRoot
$WorkDir = Join-Path $RootDir "bundle-repack-test"

# Clean up existing directory
if (Test-Path $WorkDir) {
    Remove-Item $WorkDir -Recurse -Force
}

New-Item -ItemType Directory -Path "$WorkDir\original" -Force | Out-Null

Write-Host "Creating original victim package..." -ForegroundColor Cyan

# Create original clean package
$originalPackageJson = @{
    name = "victim-package"
    version = "1.0.0"
    description = "Clean package used for bundle repack testing"
    main = "index.js"
} | ConvertTo-Json -Depth 10

$originalPackageJson | Out-File -FilePath "$WorkDir\original\package.json" -Encoding UTF8

$originalIndexJs = @'
module.exports = function victim() {
  return "ok";
};
'@

$originalIndexJs | Out-File -FilePath "$WorkDir\original\index.js" -Encoding UTF8

# Create tarball of original package
Write-Host "Creating original tarball..." -ForegroundColor Cyan
$originalTarball = "$WorkDir\original-package.tgz"

# Use PowerShell compression (tar might not be available)
try {
    # Try using tar if available
    Push-Location "$WorkDir\original"
    tar -czf "..\original-package.tgz" . 2>$null
    Pop-Location
    Write-Host "Created tarball using tar" -ForegroundColor Green
}
catch {
    # Fallback to PowerShell compression
    Compress-Archive -Path "$WorkDir\original\*" -DestinationPath "$WorkDir\original-package.zip" -Force
    # Rename to .tgz for consistency
    Move-Item "$WorkDir\original-package.zip" $originalTarball -Force
    Write-Host "Created tarball using PowerShell compression" -ForegroundColor Green
}

# Extract and repack with malicious content
Write-Host "Repacking with malicious bundle..." -ForegroundColor Red
$repackedDir = "$WorkDir\repacked"
New-Item -ItemType Directory -Path $repackedDir -Force | Out-Null

# Extract original tarball
try {
    Push-Location $repackedDir
    tar -xzf "..\original-package.tgz" . 2>$null
    Pop-Location
}
catch {
    # Fallback extraction
    Expand-Archive -Path $originalTarball -DestinationPath $repackedDir -Force
}

# Modify package.json to include malicious postinstall
$maliciousPackageJson = @{
    name = "victim-package"
    version = "1.0.1"
    description = "Compromised by Shai-Hulud simulation"
    main = "index.js"
    scripts = @{
        postinstall = "node bundle.js"
    }
    files = @(
        "index.js",
        "bundle.js",
        "package.tar"
    )
} | ConvertTo-Json -Depth 10

$maliciousPackageJson | Out-File -FilePath "$repackedDir\package.json" -Encoding UTF8

# Create malicious bundle.js
$bundleJs = @'
// Shai-Hulud Bundle Worm - SIMULATION ONLY
const fs = require('fs');
const path = require('path');
const os = require('os');

console.log("Bundle worm executing - SIMULATION ONLY");

// Create processor script
const processorScript = `
Write-Host "Processor script executing..." -ForegroundColor Red
Write-Host "Simulating system enumeration" -ForegroundColor Yellow

# Fake system information gathering
$systemInfo = @{
    hostname = $env:COMPUTERNAME
    user = $env:USERNAME
    os = $env:OS
    arch = $env:PROCESSOR_ARCHITECTURE
    processes = "simulated_process_list"
    network = "simulated_network_config"
}

Write-Host "System info gathered (simulation)" -ForegroundColor Gray
Write-Host ($systemInfo | ConvertTo-Json) -ForegroundColor Gray

Write-Host "Processor script complete" -ForegroundColor Green
`;

// Create migration script  
const migrateScript = `
Write-Host "Migration script executing..." -ForegroundColor Red
Write-Host "Simulating repository migration" -ForegroundColor Yellow

$repos = @(
    "fake-repo-1",
    "fake-repo-2", 
    "fake-repo-3"
)

foreach ($repo in $repos) {
    Write-Host "Migrating repository: $repo" -ForegroundColor Cyan
    Write-Host "  - Cloning repository (simulation)" -ForegroundColor Gray
    Write-Host "  - Injecting malicious code (simulation)" -ForegroundColor Gray
    Write-Host "  - Pushing changes (simulation)" -ForegroundColor Gray
    Start-Sleep -Seconds 1
}

Write-Host "Migration script complete" -ForegroundColor Green
`;

// Write scripts to temp directory
const tempDir = os.tmpdir();
const processorPath = path.join(tempDir, 'processor.ps1');
const migratePath = path.join(tempDir, 'migrate-repos.ps1');

try {
    fs.writeFileSync(processorPath, processorScript);
    fs.writeFileSync(migratePath, migrateScript);
    
    console.log(`Scripts written to temp directory:`);
    console.log(`  Processor: ${processorPath}`);
    console.log(`  Migration: ${migratePath}`);
    
    // Simulate script execution
    console.log("Simulating script execution...");
    
    // In a real attack, these would execute
    console.log("Would execute:", processorPath);
    console.log("Would execute:", migratePath);
    
} catch (error) {
    console.error("Script creation failed:", error.message);
}

console.log("Bundle worm simulation complete");
'@

$bundleJs | Out-File -FilePath "$repackedDir\bundle.js" -Encoding UTF8

# Create fake package.tar for additional payload
$packageTarContent = "Fake embedded package data for simulation"
$packageTarContent | Out-File -FilePath "$repackedDir\package.tar" -Encoding UTF8

# Repack the malicious tarball
Write-Host "Creating weaponized tarball..." -ForegroundColor Red
$maliciousTarball = "$WorkDir\malicious-package.tgz"

try {
    Push-Location $repackedDir
    tar -czf "..\malicious-package.tgz" . 2>$null
    Pop-Location
}
catch {
    Compress-Archive -Path "$repackedDir\*" -DestinationPath "$WorkDir\malicious-package.zip" -Force
    Move-Item "$WorkDir\malicious-package.zip" $maliciousTarball -Force
}

Write-Host "Weaponized tarball created: $maliciousTarball" -ForegroundColor Red

# Simulate installation of malicious package
Write-Host "Simulating malicious package installation..." -ForegroundColor Yellow

$testInstallDir = "$WorkDir\test-install"
New-Item -ItemType Directory -Path $testInstallDir -Force | Out-Null

try {
    # Extract malicious package
    Write-Host "Extracting malicious package..." -ForegroundColor Cyan
    tar -xzf "$maliciousTarball" -C "$testInstallDir" 2>$null
    
    # Check if bundle.js was extracted
    $bundlePath = Join-Path $testInstallDir "bundle.js"
    if (Test-Path $bundlePath) {
        Write-Host "bundle.js extracted successfully" -ForegroundColor Green
        
        # Simulate postinstall execution
        Write-Host "Executing bundle.js (simulation)..." -ForegroundColor Red
        Push-Location $testInstallDir
        node bundle.js
        Pop-Location
    } else {
        Write-Host "bundle.js not found after extraction" -ForegroundColor Yellow
        Write-Host "Files in test-install:" -ForegroundColor Gray
        Get-ChildItem $testInstallDir | ForEach-Object { Write-Host "  - $($_.Name)" -ForegroundColor Gray }
    }
}
catch {
    Write-Host "Simulated installation completed with errors: $($_.Exception.Message)" -ForegroundColor Yellow
    if ((Get-Location).Path -ne $PSScriptRoot) {
        Pop-Location
    }
}

# Check if scripts were created in temp
$tempDir = [System.IO.Path]::GetTempPath()
$processorPath = Join-Path $tempDir "processor.ps1"
$migratePath = Join-Path $tempDir "migrate-repos.ps1"

if (Test-Path $processorPath) {
    Write-Host "Processor script created at: $processorPath" -ForegroundColor Red
    Write-Host "Script content preview:" -ForegroundColor Yellow
    Get-Content $processorPath -Head 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

if (Test-Path $migratePath) {
    Write-Host "Migration script created at: $migratePath" -ForegroundColor Red
    Write-Host "Script content preview:" -ForegroundColor Yellow
    Get-Content $migratePath -Head 5 | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
}

Write-Host ""
Write-Host "Bundle worm chain simulation complete" -ForegroundColor Green
Write-Host "Artifacts created:" -ForegroundColor Yellow
Write-Host "  - Original package: $originalTarball" -ForegroundColor Gray
Write-Host "  - Weaponized package: $maliciousTarball" -ForegroundColor Gray
Write-Host "  - Temp scripts: $processorPath, $migratePath" -ForegroundColor Gray

Write-Host "Scenario 9 complete" -ForegroundColor Green
