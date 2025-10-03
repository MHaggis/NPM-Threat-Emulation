#Requires -Version 5.1
<#
.SYNOPSIS
    PowerShell HTTP Mock Server for NPM Threat Emulation
.DESCRIPTION
    Simple HTTP server that accepts GET/POST requests and logs payloads for testing
.PARAMETER Port
    Port to listen on (default: 8080)
.PARAMETER LogDirectory
    Directory to save payload logs (default: tmp)
#>

param(
    [int]$Port = 8080,
    [string]$LogDirectory = "tmp"
)

# Ensure log directory exists
$LogDir = Join-Path $PSScriptRoot $LogDirectory
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "Mock server listening on port $Port" -ForegroundColor Green
    Write-Host "Payloads will be saved to: $LogDir" -ForegroundColor Yellow
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Cyan
    
    while ($listener.IsListening) {
        # Get request context
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Get current timestamp
        $timestamp = Get-Date -Format "yyyyMMddTHHmmssZ"
        
        # Log request info
        $logInfo = @{
            timestamp = $timestamp
            method = $request.HttpMethod
            url = $request.Url.ToString()
            userAgent = $request.UserAgent
            contentLength = $request.ContentLength64
        }
        
        Write-Host "[$timestamp] $($request.HttpMethod) $($request.Url.PathAndQuery)" -ForegroundColor White
        
        # Read request body if present
        $requestBody = ""
        if ($request.HasEntityBody) {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $requestBody = $reader.ReadToEnd()
            $reader.Close()
            
            # Save payload to file
            $payloadFile = Join-Path $LogDir "payload_$timestamp.json"
            $payloadData = @{
                request = $logInfo
                body = $requestBody
                headers = @{}
            }
            
            # Add headers
            foreach ($headerName in $request.Headers.AllKeys) {
                $payloadData.headers[$headerName] = $request.Headers[$headerName]
            }
            
            $payloadData | ConvertTo-Json -Depth 10 | Out-File -FilePath $payloadFile -Encoding UTF8
            Write-Host "  Payload saved: $payloadFile" -ForegroundColor Gray
        }
        
        # Create response
        $responseData = @{
            ok = $true
            method = $request.HttpMethod
            path = $request.Url.PathAndQuery
            timestamp = $timestamp
            bytes = $requestBody.Length
        } | ConvertTo-Json
        
        $responseBytes = [System.Text.Encoding]::UTF8.GetBytes($responseData)
        
        # Set response headers
        $response.ContentType = "application/json"
        $response.ContentLength64 = $responseBytes.Length
        $response.StatusCode = 200
        
        # Write response
        $response.OutputStream.Write($responseBytes, 0, $responseBytes.Length)
        $response.Close()
    }
}
catch {
    Write-Error "Server error: $($_.Exception.Message)"
}
finally {
    if ($listener.IsListening) {
        $listener.Stop()
    }
    $listener.Close()
    Write-Host "Server stopped" -ForegroundColor Red
}
