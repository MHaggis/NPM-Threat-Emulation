param([switch]$Force)

$ScriptRoot = $PSScriptRoot
$TmpDir = Join-Path $ScriptRoot "tmp"

if (-not (Test-Path $TmpDir)) {
    New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null
}

Write-Host "NPM Threat Emulation - Windows Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check requirements
Write-Host "Checking requirements..." -ForegroundColor Cyan
$missing = @()
$required = @("node", "npm", "git")

foreach ($cmd in $required) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        $missing += $cmd
    }
    else {
        Write-Host "  OK $cmd found" -ForegroundColor Green
    }
}

if ($missing.Count -gt 0) {
    Write-Host "  Missing: $($missing -join ', ')" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please install missing requirements:" -ForegroundColor Yellow
    
    if ($missing -contains "node" -or $missing -contains "npm") {
        Write-Host "  Node.js: https://nodejs.org/" -ForegroundColor White
        Write-Host "  Or run: choco install nodejs -y" -ForegroundColor Gray
        Write-Host "  Or run: winget install OpenJS.NodeJS" -ForegroundColor Gray
    }
    if ($missing -contains "git") {
        Write-Host "  Git: https://git-scm.com/" -ForegroundColor White
        Write-Host "  Or run: choco install git -y" -ForegroundColor Gray
        Write-Host "  Or run: winget install Git.Git" -ForegroundColor Gray
    }
    Write-Host ""
    Write-Host "After installing, restart PowerShell and run this script again." -ForegroundColor Yellow
    exit 1
}

Write-Host "  All requirements satisfied!" -ForegroundColor Green
Write-Host ""

# Load .env file if exists
$EnvFile = Join-Path $ScriptRoot ".env"
if (Test-Path $EnvFile) {
    Write-Host "Loading .env file..." -ForegroundColor Yellow
    Get-Content $EnvFile | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            Set-Item -Path "env:$($matches[1])" -Value $matches[2]
        }
    }
}

# Set fake credentials
$env:FAKE_NPM_TOKEN = "npm_test_token_12345"
$env:FAKE_GITHUB_TOKEN = "ghp_test_token_abcdef"
$env:FAKE_AWS_KEY = "AKIA_TEST_KEY_12345"

Write-Host "Fake credentials exported:" -ForegroundColor Green
Write-Host "  FAKE_NPM_TOKEN: $env:FAKE_NPM_TOKEN" -ForegroundColor Gray
Write-Host "  FAKE_GITHUB_TOKEN: $env:FAKE_GITHUB_TOKEN" -ForegroundColor Gray
Write-Host "  FAKE_AWS_KEY: $env:FAKE_AWS_KEY" -ForegroundColor Gray
Write-Host ""

# Setup webhook
if ($env:MOCK_WEBHOOK -and $env:MOCK_WEBHOOK -notmatch '^https?://(localhost|127\.0\.0\.1)') {
    Write-Host "Using external webhook: $env:MOCK_WEBHOOK" -ForegroundColor Green
}
else {
    $env:MOCK_WEBHOOK = "http://localhost:8080/webhook-receiver"
    
    # Check if server already running
    try {
        $null = Invoke-RestMethod -Uri $env:MOCK_WEBHOOK -Method POST -Body @{ping=1} -TimeoutSec 2 -ErrorAction Stop
        Write-Host "Mock server already running on port 8080" -ForegroundColor Green
    }
    catch {
        Write-Host "Starting mock server..." -ForegroundColor Yellow
        
        # Stop old jobs
        Get-Job -Name "MockServer" -ErrorAction SilentlyContinue | Stop-Job -PassThru | Remove-Job -Force
        
        # Start server
        $serverScript = Join-Path $ScriptRoot "MockServer.ps1"
        $job = Start-Job -Name "MockServer" -ScriptBlock {
            param($Script, $LogDir)
            & $Script -LogDirectory $LogDir
        } -ArgumentList $serverScript, "tmp"
        
        # Wait for server
        $timeout = 10
        $elapsed = 0
        $ready = $false
        
        while ($elapsed -lt $timeout -and -not $ready) {
            Start-Sleep -Seconds 1
            $elapsed++
            try {
                $null = Invoke-RestMethod -Uri $env:MOCK_WEBHOOK -Method POST -Body @{ping=1} -TimeoutSec 2 -ErrorAction Stop
                $ready = $true
                Write-Host "Mock server started on port 8080" -ForegroundColor Green
            }
            catch {
                # Still waiting
            }
        }
        
        if (-not $ready) {
            Write-Warning "Mock server may not have started. Check: Get-Job -Name MockServer"
        }
        
        # Save job ID
        $jobFile = Join-Path $TmpDir "server_job.txt"
        $job.Id | Out-File -FilePath $jobFile -Encoding UTF8
    }
}

Write-Host ""
Write-Host "Environment ready!" -ForegroundColor Green
Write-Host "MOCK_WEBHOOK: $env:MOCK_WEBHOOK" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test the webhook:" -ForegroundColor Yellow
Write-Host '  Invoke-RestMethod -Uri $env:MOCK_WEBHOOK -Method POST -Body @{test=1}' -ForegroundColor Gray
Write-Host ""
Write-Host "Run scenarios:" -ForegroundColor Yellow
Write-Host "  .\scenarios\Scenario-1.ps1" -ForegroundColor Gray
Write-Host "  .\Run-AllScenarios.ps1" -ForegroundColor Gray
