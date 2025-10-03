#Requires -Version 5.1
<#
.SYNOPSIS
    Stop the local mock HTTP server
.DESCRIPTION
    Stops the PowerShell background job running the mock server
#>

$ScriptRoot = $PSScriptRoot
$TmpDir = Join-Path $ScriptRoot "tmp"
$JobFile = Join-Path $TmpDir "server_job.txt"

Write-Host "Stopping mock server..." -ForegroundColor Yellow

# Stop job by name first
$stopped = $false
try {
    $job = Get-Job -Name "MockServer" -ErrorAction SilentlyContinue
    if ($job) {
        $job | Stop-Job -PassThru | Remove-Job -Force
        Write-Host "Mock server job stopped" -ForegroundColor Green
        $stopped = $true
    }
}
catch {
    Write-Host "Error stopping job: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Try to stop by job ID from file
if (-not $stopped -and (Test-Path $JobFile)) {
    try {
        $jobId = Get-Content $JobFile -ErrorAction SilentlyContinue
        if ($jobId) {
            $job = Get-Job -Id $jobId -ErrorAction SilentlyContinue
            if ($job) {
                $job | Stop-Job -PassThru | Remove-Job -Force
                Write-Host "Mock server job stopped by ID" -ForegroundColor Green
                $stopped = $true
            }
        }
    }
    catch {
        Write-Host "Error stopping job by ID: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

# Clean up job file
if (Test-Path $JobFile) {
    Remove-Item $JobFile -Force -ErrorAction SilentlyContinue
}

# Force stop any PowerShell processes listening on port 8080
try {
    $processes = Get-NetTCPConnection -LocalPort 8080 -ErrorAction SilentlyContinue | 
                 Select-Object -ExpandProperty OwningProcess -Unique
    
    foreach ($pid in $processes) {
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        if ($process -and $process.ProcessName -eq "powershell") {
            Write-Host "Stopping PowerShell process $pid listening on port 8080..." -ForegroundColor Yellow
            Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue
            $stopped = $true
        }
    }
}
catch {
    # Ignore errors in process cleanup
}

if ($stopped) {
    Write-Host "Mock server stopped successfully" -ForegroundColor Green
} else {
    Write-Host "No mock server found running" -ForegroundColor Gray
}

# Final port check
Start-Sleep -Seconds 1
try {
    $connection = Test-NetConnection -ComputerName localhost -Port 8080 -InformationLevel Quiet -WarningAction SilentlyContinue
    if ($connection) {
        Write-Warning "Something is still listening on port 8080. You may need to restart PowerShell."
    } else {
        Write-Host "Port 8080 is now free" -ForegroundColor Green
    }
}
catch {
    Write-Host "Port 8080 appears to be free" -ForegroundColor Green
}