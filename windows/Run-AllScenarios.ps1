#Requires -Version 5.1
<#
.SYNOPSIS
    Run all NPM Threat Emulation scenarios
.DESCRIPTION
    Executes all 9 scenarios sequentially with configurable delays between each
.PARAMETER DelaySeconds
    Seconds to wait between scenarios (default: 60)
.PARAMETER StartFrom
    Scenario number to start from (1-9, default: 1)
.PARAMETER EndAt
    Scenario number to end at (1-9, default: 9)
#>

param(
    [int]$DelaySeconds = 60,
    [ValidateRange(1,9)]
    [int]$StartFrom = 1,
    [ValidateRange(1,9)]
    [int]$EndAt = 9
)

$ScriptRoot = $PSScriptRoot
$ScenariosDir = Join-Path $ScriptRoot "scenarios"

# Ensure environment is set up
if (-not $env:MOCK_WEBHOOK) {
    Write-Host "Environment not initialized. Running setup..." -ForegroundColor Yellow
    & (Join-Path $ScriptRoot "Setup-TestEnvironment.ps1")
}

Write-Host "Starting NPM Supply Chain Attack Emulation Tests" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Webhook: $env:MOCK_WEBHOOK" -ForegroundColor Gray
Write-Host "Delay between scenarios: $DelaySeconds seconds" -ForegroundColor Gray
Write-Host "Running scenarios $StartFrom to $EndAt" -ForegroundColor Gray
Write-Host ""

$successCount = 0
$failureCount = 0
$startTime = Get-Date

for ($scenario = $StartFrom; $scenario -le $EndAt; $scenario++) {
    $scenarioScript = Join-Path $ScenariosDir "Scenario-$scenario.ps1"
    
    if (-not (Test-Path $scenarioScript)) {
        Write-Warning "Scenario $scenario script not found: $scenarioScript"
        $failureCount++
        continue
    }
    
    Write-Host "Running Scenario $scenario..." -ForegroundColor Yellow
    Write-Host "Script: $scenarioScript" -ForegroundColor Gray
    
    $scenarioStart = Get-Date
    
    try {
        & $scenarioScript
        $scenarioEnd = Get-Date
        $duration = ($scenarioEnd - $scenarioStart).TotalSeconds
        
        Write-Host "Scenario $scenario completed successfully (${duration}s)" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Error "Scenario $scenario failed: $($_.Exception.Message)"
        $failureCount++
    }
    
    # Wait before next scenario (except for the last one)
    if ($scenario -lt $EndAt) {
        Write-Host "Waiting $DelaySeconds seconds before next scenario..." -ForegroundColor Cyan
        Start-Sleep -Seconds $DelaySeconds
        Write-Host ""
    }
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalMinutes

Write-Host ""
Write-Host "All emulation tests completed!" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "Total duration: $([math]::Round($totalDuration, 1)) minutes" -ForegroundColor Gray
Write-Host "Successful scenarios: $successCount" -ForegroundColor Green
Write-Host "Failed scenarios: $failureCount" -ForegroundColor $(if ($failureCount -gt 0) { "Red" } else { "Gray" })
Write-Host ""

if ($env:MOCK_WEBHOOK -match "localhost") {
    $payloadDir = Join-Path $ScriptRoot "tmp"
    $payloadFiles = Get-ChildItem -Path $payloadDir -Filter "payload_*.json" -ErrorAction SilentlyContinue
    if ($payloadFiles) {
        Write-Host "Payload files captured:" -ForegroundColor Yellow
        $payloadFiles | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor Gray }
    }
}

Write-Host "Check your monitoring solution for generated events and alerts" -ForegroundColor Yellow
