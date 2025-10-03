#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 6: Worm Propagation Simulation
.DESCRIPTION
    Simulates npm publish dry-run across multiple packages using fake NPM token
#>

Write-Host "Scenario 6: Worm Propagation Simulation" -ForegroundColor Yellow

# Load fake NPM token
$npmToken = if ($env:FAKE_NPM_TOKEN) { $env:FAKE_NPM_TOKEN } else { "npm_test_token_12345" }
Write-Host "Using NPM token: $npmToken" -ForegroundColor Gray

# Package names to simulate publishing
$packageNames = @(
    "test-worm-package-1",
    "test-worm-package-2", 
    "test-worm-package-3",
    "test-worm-package-4",
    "test-worm-package-5"
)

Write-Host "Simulating worm propagation across $($packageNames.Count) packages..." -ForegroundColor Red

foreach ($packageName in $packageNames) {
    Write-Host "Processing package: $packageName" -ForegroundColor Cyan
    
    # Create package directory
    $packageDir = "worm-$packageName"
    if (Test-Path $packageDir) {
        Remove-Item $packageDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
    
    Push-Location $packageDir
    
    try {
        # Create malicious package.json
        $packageJson = @{
            name = $packageName
            version = "1.0.0"
            description = "Simulated worm package - DO NOT PUBLISH"
            main = "index.js"
            scripts = @{
                postinstall = "node worm.js"
            }
        } | ConvertTo-Json -Depth 10
        
        $packageJson | Out-File -FilePath "package.json" -Encoding UTF8
        
        # Create main index file
        $indexContent = @'
module.exports = function() {
  return "worm package - simulation only";
};
'@
        $indexContent | Out-File -FilePath "index.js" -Encoding UTF8
        
        # Create worm script
        $wormContent = @'
// Simulated worm propagation script
console.log("Worm payload executed - SIMULATION ONLY");

// Simulate token theft
const fakeToken = process.env.NPM_TOKEN || "npm_test_token_12345";
console.log("Captured NPM token:", fakeToken);

// Simulate package enumeration
const packages = ["victim-pkg-1", "victim-pkg-2", "victim-pkg-3"];
console.log("Target packages:", packages);
'@
        $wormContent | Out-File -FilePath "worm.js" -Encoding UTF8
        
        # Simulate npm publish dry-run with fake token
        Write-Host "  Simulating npm publish dry-run..." -ForegroundColor Yellow
        
        try {
            # Set fake NPM token temporarily
            $env:NPM_TOKEN = $npmToken
            
            # Run npm publish --dry-run (safe - doesn't actually publish)
            $publishOutput = npm publish --dry-run 2>&1
            Write-Host "  Dry-run completed for $packageName" -ForegroundColor Green
            Write-Host "  Output: $publishOutput" -ForegroundColor Gray
        }
        catch {
            Write-Host "  Dry-run failed for $packageName (expected)" -ForegroundColor Yellow
        }
        finally {
            # Clean up environment
            $env:NPM_TOKEN = $null
        }
        
        # Simulate additional worm behaviors
        Write-Host "  Simulating worm behaviors..." -ForegroundColor Red
        
        # Fake network scanning
        Write-Host "    - Network enumeration simulation" -ForegroundColor Gray
        
        # Fake file system scanning
        Write-Host "    - File system scanning simulation" -ForegroundColor Gray
        
        # Fake credential harvesting
        Write-Host "    - Credential harvesting simulation" -ForegroundColor Gray
        
    }
    finally {
        Pop-Location
    }
    
    Start-Sleep -Seconds 1
}

# Clean up worm packages
Write-Host "Cleaning up worm packages..." -ForegroundColor Yellow
foreach ($packageName in $packageNames) {
    $packageDir = "worm-$packageName"
    if (Test-Path $packageDir) {
        Remove-Item $packageDir -Recurse -Force
        Write-Host "  Removed: $packageDir" -ForegroundColor Gray
    }
}

Write-Host "Scenario 6 complete" -ForegroundColor Green
Write-Host "Note: All npm publish operations were dry-runs only - no packages were actually published" -ForegroundColor Cyan
