@echo off
REM --- Hybrid CMD+PowerShell launcher ---

REM --- CMD section: relaunch as PowerShell and exit CMD ---
powershell -NoProfile -ExecutionPolicy Bypass -Command "& { (Get-Content -Raw '%~f0') -split ':__PS1__' | Select-Object -Last 1 | Invoke-Expression }" %*
exit /b

:__PS1__
# ================== PowerShell Script ==================
param()

function Write-Color($Text, $Color = 'White', $Bg = $null) {
    if ($Bg) {
        Write-Host $Text -ForegroundColor $Color -BackgroundColor $Bg
    } else {
        Write-Host $Text -ForegroundColor $Color
    }
}

function Wait-TimeoutOrKey([int]$Timeout = 15, [string]$Message = 'Press any key or wait {0} seconds...',[string]$Color = 'Gray') {
    $remaining = $Timeout
    $msg = $Message -f $Timeout
    $sw = [Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $Timeout) {
        if ([Console]::KeyAvailable) {
            [void][Console]::ReadKey($true)
            break
        }
        $elapsed = [int]$sw.Elapsed.TotalSeconds
        $newRemaining = $Timeout - $elapsed
        if ($newRemaining -ne $remaining) {
            $remaining = $newRemaining
            $msg = $Message -f $remaining
            Write-Host ("`r$msg") -ForegroundColor $Color -NoNewline
        }
        Start-Sleep -Milliseconds 200
    }
    Write-Host ""
}

# Header
Write-Color "" White
Write-Color "Script author: Ixeldino" Black Yellow
Write-Color "https://github.com/ixeldino/wifi_migrate_tool" White Blue
Write-Color "" White

$exeName = "wifi_pro.exe"
$repo = "ixeldino/wifi_migrate_tool"
$tmpJson = "$env:TEMP\gh_release.json"

# Fix for $PSScriptRoot: fallback to current dir if not set (when dot-sourced)
if (-not $PSScriptRoot) { $PSScriptRoot = (Get-Location).Path }

# 1. Get latest release info
Write-Color "Getting latest release info..." Gray
Invoke-RestMethod -Uri "https://api.github.com/repos/$repo/releases/latest" | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $tmpJson
Write-Color "Release JSON downloaded: $tmpJson" Gray

# 1.1 Extract EXE URL from JSON
$release = Get-Content -Raw $tmpJson | ConvertFrom-Json
$exeUrl = $release.assets | Where-Object { $_.name -eq $exeName } | Select-Object -ExpandProperty browser_download_url -First 1
Write-Color "EXE_URL: $exeUrl" Gray
if (-not $exeUrl) {
    Write-Color "EXE file not found in release!" Red
    Remove-Item $tmpJson -ErrorAction SilentlyContinue
    Wait-TimeoutOrKey 15 'Press any key or wait {0} seconds...' Red
    exit 1
}

# 2. Check if local file exists
$exePath = Join-Path $PSScriptRoot $exeName
if (-not (Test-Path $exePath)) {
    Write-Color "Local EXE not found. Downloading..." Yellow
    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -Verbose
    Write-Color "Download complete." Green
    Remove-Item $tmpJson -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\remote.sha256" -ErrorAction SilentlyContinue
    # After download, update $exePath (in case it was missing before)
    $exePath = Join-Path $PSScriptRoot $exeName
    # Continue to hash check
}

# 2.2.1 Check if SHA256 exists in release
$shaUrl = $release.assets | Where-Object { $_.name -like '*.sha256' } | Select-Object -ExpandProperty browser_download_url -First 1
Write-Color "SHA_URL: $shaUrl" Gray
if (-not $shaUrl) {
    Write-Color "No SHA256 in release. Downloading EXE anyway..." Yellow
    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -Verbose
    Write-Color "Download complete." Green
    Remove-Item $tmpJson -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\remote.sha256" -ErrorAction SilentlyContinue
    Wait-TimeoutOrKey 15 'Press any key or wait {0} seconds...' Yellow
    exit 0
}

# 2.2.2 Download SHA256 and get remote hash
Invoke-RestMethod -Uri $shaUrl | Out-File -Encoding ascii "$env:TEMP\remote.sha256"
Write-Color "SHA256 file downloaded: $env:TEMP\remote.sha256" Gray
$remoteHash = Get-Content "$env:TEMP\remote.sha256" | Select-Object -First 1 -Skip 0
$remoteHash = $remoteHash.Split(' ')[0]
Write-Color "REMOTE_HASH: $remoteHash" Gray

# 2.2.3 Calculate local hash
if ($exePath -and (Test-Path $exePath)) {
    $localHash = (Get-FileHash -Algorithm SHA256 $exePath).Hash
} else {
    $localHash = ""
}
Write-Color "LOCAL_HASH: $localHash" Gray

# 2.2.4 Compare hashes
if ($remoteHash -eq $localHash) {
    Write-Color "Hashes match. No download needed." Green
    Remove-Item $tmpJson -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\remote.sha256" -ErrorAction SilentlyContinue
    Wait-TimeoutOrKey 10 'Done! Press any key or wait {0} seconds...' Green
    exit 0
} else {
    Write-Color "Hashes differ. Downloading new EXE..." Yellow
    Invoke-WebRequest -Uri $exeUrl -OutFile $exePath -Verbose
    Write-Color "Download complete." Green
    Remove-Item $tmpJson -ErrorAction SilentlyContinue
    Remove-Item "$env:TEMP\remote.sha256" -ErrorAction SilentlyContinue
    Wait-TimeoutOrKey 10 'Done! Press any key or wait {0} seconds...' Green
    exit 0
}

Write-Color "Done!" Cyan
Wait-TimeoutOrKey -Timeout 60 'Done! Press any key or wait {0} seconds...' Cyan
exit 0
