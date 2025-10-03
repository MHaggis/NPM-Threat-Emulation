#Requires -Version 5.1
<#
.SYNOPSIS
    One-click installer for NPM Threat Emulation on Windows
.DESCRIPTION
    Downloads, sets up, and runs the NPM Threat Emulation toolkit
#>

param(
    [string]$WebhookUrl = "",
    [switch]$RunDemo
)

Write-Host "NPM Threat Emulation - One-Click Installer" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Set execution policy if needed (no try/catch for maximum compatibility)
$currentPolicy = Get-ExecutionPolicy -Scope CurrentUser
if ($currentPolicy -eq "Restricted") {
    Write-Host "Setting execution policy..." -ForegroundColor Yellow
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force -ErrorAction SilentlyContinue
}

# Check if git is available
$gitExists = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitExists) {
    Write-Host "Git not found. Attempting to install..." -ForegroundColor Yellow

    # Try winget first
    $wingetExists = Get-Command winget -ErrorAction SilentlyContinue
    if ($wingetExists) {
        Write-Host "Using winget to install Git..." -ForegroundColor Yellow
        Start-Process -FilePath "winget" -ArgumentList "install","Git.Git","-e","--accept-source-agreements","--accept-package-agreements" -Wait -NoNewWindow
    }

    # Re-check git
    $gitExists = Get-Command git -ErrorAction SilentlyContinue

    # Try Chocolatey if still not installed
    if (-not $gitExists) {
        $chocoExists = Get-Command choco -ErrorAction SilentlyContinue
        if ($chocoExists) {
            Write-Host "Using Chocolatey to install Git..." -ForegroundColor Yellow
            Start-Process -FilePath "choco" -ArgumentList "install","git","-y" -Wait -NoNewWindow
        }
    }

    # Final check
    $gitExists = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitExists) {
        Write-Host "Please install Git manually from: https://git-scm.com/" -ForegroundColor Red
        exit 1
    }
}

# Clone repository if not already present
$repoDir = "NPM-Threat-Emulation"
if (-not (Test-Path $repoDir)) {
    Write-Host "Cloning repository..." -ForegroundColor Cyan
    git clone https://github.com/MHaggis/NPM-Threat-Emulation.git
    Write-Host "Repository cloned" -ForegroundColor Green
}

# Navigate to windows directory
$windowsDir = Join-Path $repoDir "windows"
if (-not (Test-Path $windowsDir)) {
    Write-Error "Windows directory not found in repository"
    exit 1
}

Set-Location $windowsDir

# Configure webhook if provided
if ($WebhookUrl) {
    Write-Host "Configuring webhook: $WebhookUrl" -ForegroundColor Cyan
    $env:MOCK_WEBHOOK = $WebhookUrl
    "MOCK_WEBHOOK=$WebhookUrl" | Out-File -FilePath ".env" -Encoding UTF8
}

# Run setup
Write-Host "Running setup..." -ForegroundColor Cyan
& ".\Setup-TestEnvironment.ps1"

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Installation complete." -ForegroundColor Green
    Write-Host ""

    if ($RunDemo) {
        Write-Host "Running demo scenario..." -ForegroundColor Yellow
        & ".\scenarios\Scenario-1.ps1"
    }

    Write-Host "Ready to run scenarios!" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Try these commands:" -ForegroundColor Yellow
    Write-Host "  .\scenarios\Scenario-1.ps1    # Single scenario" -ForegroundColor White
    Write-Host "  .\Run-AllScenarios.ps1        # All scenarios" -ForegroundColor White
    Write-Host ""
    Write-Host "Happy hunting!" -ForegroundColor Green
} else {
    Write-Host "Setup failed. Check the output above for details." -ForegroundColor Red
    exit 1
}
