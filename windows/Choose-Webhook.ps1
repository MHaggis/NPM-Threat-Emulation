#Requires -Version 5.1
<#
.SYNOPSIS
    Interactive webhook configuration for NPM Threat Emulation
.DESCRIPTION
    Allows users to choose between local mock server or external webhook URL
#>

$ScriptRoot = $PSScriptRoot
$EnvFile = Join-Path $ScriptRoot ".env"

Write-Host "NPM Threat Emulation - Webhook Configuration" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Choose webhook option:" -ForegroundColor Yellow
Write-Host "1. Local mock server (default)" -ForegroundColor White
Write-Host "2. External webhook (e.g., webhook.site)" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Enter your choice (1 or 2)"

switch ($choice) {
    "2" {
        Write-Host ""
        Write-Host "Enter your external webhook URL:" -ForegroundColor Yellow
        Write-Host "Example: https://webhook.site/12345678-1234-1234-1234-123456789012" -ForegroundColor Gray
        $webhookUrl = Read-Host "URL"
        
        if ([string]::IsNullOrWhiteSpace($webhookUrl)) {
            Write-Error "No URL provided. Aborting."
            exit 1
        }
        
        # Validate URL format
        try {
            $uri = [System.Uri]$webhookUrl
            if ($uri.Scheme -notin @("http", "https")) {
                throw "Invalid scheme"
            }
        }
        catch {
            Write-Error "Please provide a valid http(s) URL"
            exit 1
        }
        
        # Save to environment file
        try {
            "MOCK_WEBHOOK=$webhookUrl" | Out-File -FilePath $EnvFile -Encoding UTF8
            Write-Host ""
            Write-Host "Webhook configured successfully!" -ForegroundColor Green
            Write-Host "MOCK_WEBHOOK set to: $webhookUrl" -ForegroundColor Cyan
            Write-Host "Saved to: $EnvFile" -ForegroundColor Gray
        }
        catch {
            Write-Warning "Could not write to $EnvFile"
            Write-Host "As a fallback, set the environment variable manually:" -ForegroundColor Yellow
            Write-Host "`$env:MOCK_WEBHOOK = '$webhookUrl'" -ForegroundColor Gray
        }
    }
    
    default {
        # Option 1 or any other input - use local server
        if (Test-Path $EnvFile) {
            Remove-Item $EnvFile -Force
            Write-Host "Removed existing .env file" -ForegroundColor Yellow
        }
        Write-Host "Configured to use local mock server (default)" -ForegroundColor Green
        Write-Host "The server will start automatically when you run Setup-TestEnvironment.ps1" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Run: .\Setup-TestEnvironment.ps1" -ForegroundColor White
Write-Host "2. Test: Invoke-RestMethod -Uri `$env:MOCK_WEBHOOK -Method POST -Body @{test=1}" -ForegroundColor White
Write-Host "3. Run scenarios: .\scenarios\Scenario-1.ps1" -ForegroundColor White
