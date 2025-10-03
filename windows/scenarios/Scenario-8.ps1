#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 8: GitHub Repository Weaponization
.DESCRIPTION
    Creates a weaponized git repository with embedded fake credentials and environment data
#>

Write-Host "Scenario 8: GitHub Repository Weaponization" -ForegroundColor Yellow

# Load environment variables if not already set
if (-not $env:FAKE_GITHUB_TOKEN) {
    $env:FAKE_GITHUB_TOKEN = "ghp_test_token_abcdef"
    $env:FAKE_NPM_TOKEN = "npm_test_token_12345"
    $env:FAKE_AWS_KEY = "AKIA_TEST_KEY_12345"
}

$WorkDir = "shai-hulud-migration-test"

# Clean up existing directory
if (Test-Path $WorkDir) {
    Remove-Item $WorkDir -Recurse -Force
}

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
Set-Location $WorkDir

# Initialize git repository
try {
    git init 2>$null | Out-Null
    Write-Host "Initialized git repository: $WorkDir" -ForegroundColor Cyan
}
catch {
    Write-Host "Git init failed (git may not be installed)" -ForegroundColor Yellow
}

# Create weaponized data file with stolen credentials
Write-Host "Creating weaponized data file with fake stolen credentials..." -ForegroundColor Red

$dataFile = @{
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    stolen_secrets = @{
        github_token = $env:FAKE_GITHUB_TOKEN
        npm_token = $env:FAKE_NPM_TOKEN
        aws_credentials = @{
            access_key = $env:FAKE_AWS_KEY
            secret_key = "fake_secret_123"
        }
    }
    environment_vars = @{
        PATH = $env:PATH
        USER = $env:USERNAME
        COMPUTERNAME = $env:COMPUTERNAME
        PROCESSOR_ARCHITECTURE = $env:PROCESSOR_ARCHITECTURE
        OS = $env:OS
    }
    system_info = @{
        platform = [System.Environment]::OSVersion.Platform.ToString()
        version = [System.Environment]::OSVersion.Version.ToString()
        machine_name = [System.Environment]::MachineName
        user_domain = [System.Environment]::UserDomainName
        is_64bit = [System.Environment]::Is64BitOperatingSystem
        processor_count = [System.Environment]::ProcessorCount
        working_directory = (Get-Location).Path
    }
    network_info = @{
        hostname = [System.Net.Dns]::GetHostName()
        ip_addresses = @()
    }
} | ConvertTo-Json -Depth 10

# Add IP addresses
try {
    $networkInfo = Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 3
    $ipList = @()
    foreach ($ip in $networkInfo) {
        $ipList += $ip.IPAddress
    }
    $dataObject = $dataFile | ConvertFrom-Json
    $dataObject.network_info.ip_addresses = $ipList
    $dataFile = $dataObject | ConvertTo-Json -Depth 10
}
catch {
    Write-Host "Failed to gather network info" -ForegroundColor Yellow
}

$dataFile | Out-File -FilePath "data.json" -Encoding UTF8

Write-Host "Created data.json with simulated stolen credentials and system info" -ForegroundColor Red

# Add additional files to make repository look legitimate
$readmeContent = @'
# Migration Test Repository

This repository contains test data for migration purposes.

**WARNING: This is a simulation - contains fake credentials only**

## Files
- data.json: System configuration and credentials backup
- migrate.ps1: Migration script (simulation)
'@

$readmeContent | Out-File -FilePath "README.md" -Encoding UTF8

# Create fake migration script
$migrateScript = @'
# Migration Script - SIMULATION ONLY
Write-Host "Starting migration process..." -ForegroundColor Yellow

# Load configuration
$config = Get-Content "data.json" | ConvertFrom-Json

Write-Host "Loaded credentials for:" -ForegroundColor Cyan
Write-Host "  GitHub: $($config.stolen_secrets.github_token)" -ForegroundColor Gray
Write-Host "  NPM: $($config.stolen_secrets.npm_token)" -ForegroundColor Gray  
Write-Host "  AWS: $($config.stolen_secrets.aws_credentials.access_key)" -ForegroundColor Gray

Write-Host "Migration simulation complete" -ForegroundColor Green
'@

$migrateScript | Out-File -FilePath "migrate.ps1" -Encoding UTF8

# Commit files to git
try {
    git add . 2>$null
    git commit -m "Shai-Hulud Migration - Test Data" 2>$null | Out-Null
    Write-Host "Files committed to git repository" -ForegroundColor Green
    
    # Show git log
    Write-Host "Git commit history:" -ForegroundColor Cyan
    git log --oneline 2>$null
}
catch {
    Write-Host "Git commit failed (git may not be configured)" -ForegroundColor Yellow
}

Set-Location ..

Write-Host ""
Write-Host "Created weaponized repository: $WorkDir" -ForegroundColor Red
Write-Host "Repository contains:" -ForegroundColor Yellow
Write-Host "  - Fake stolen credentials (GitHub, NPM, AWS)" -ForegroundColor Gray
Write-Host "  - System environment information" -ForegroundColor Gray
Write-Host "  - Network configuration details" -ForegroundColor Gray
Write-Host "  - Migration scripts for persistence" -ForegroundColor Gray

Write-Host "Scenario 8 complete" -ForegroundColor Green
