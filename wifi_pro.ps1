# Export Wi-Fi profiles and generate a self-contained CMD importer
$ErrorActionPreference = 'Stop'

$computerName = $env:COMPUTERNAME
$baseFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition
$profileFolder = Join-Path $baseFolder $computerName

if (-not (Test-Path $profileFolder)) {
    New-Item -Path $profileFolder -ItemType Directory | Out-Null
}

$profiles = netsh wlan show profiles | Where-Object { $_ -match "All User Profile" } |
    ForEach-Object { ($_ -split ":")[1].Trim() }

if (-not $profiles) {
    Write-Host "No Wi-Fi profiles found."
    Start-Sleep -Seconds 60
    exit
}

$selectedProfiles = $profiles | Out-GridView -Title "Select Wi-Fi profiles to export" -OutputMode Multiple
if (-not $selectedProfiles) {
    Write-Host "Selection cancelled."
    Start-Sleep -Seconds 60
    exit
}

foreach ($profile in $selectedProfiles) {
    $safeName = $profile -replace '[\\/:*?"<>|]', '_'
    $xmlPath = Join-Path $profileFolder "$safeName.xml"
    netsh wlan export profile name="$profile" folder="$profileFolder" key=clear > $null

    $exportedXml = Get-ChildItem $profileFolder -Filter "$safeName*.xml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($exportedXml) {
        [xml]$xmlDoc = Get-Content $exportedXml.FullName
        $key = (netsh wlan show profile name="$profile" key=clear | Select-String "Key Content\s+: (.*)").Matches.Groups[1].Value
        if ($key) {
            $keyNode = $xmlDoc.WLANProfile.MSM.security.sharedKey
            $keyNode.protected = "false"
            $keyNode.keyMaterial = $key
            $xmlDoc.Save($xmlPath)
            Remove-Item $exportedXml.FullName -Force
        }
    }
}

# Generate .cmd script
$cmdPath = Join-Path $profileFolder "wifi_import_$computerName.cmd"
$cmd = @"
@echo off
if "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="AMD64" ("%SYSTEMROOT%\sysnative\cmd.exe" /c %0 & goto :eof)
reg query "HKEY_USERS\S-1-5-19\Environment" /v TEMP >nul 2>&1 || (
  if "%1"=="elevated" (goto :NOADMIN)
  echo CreateObject^("Shell.Application"^).ShellExecute WScript.Arguments^(0^), "elevated", "", "runas", 1 > "%TEMP%\getadmin.vbs"
  wscript.exe //nologo "%TEMP%\getadmin.vbs" "%~dpnx0" elevated
  del "%TEMP%\getadmin.vbs"
  exit /b
)
setlocal EnableDelayedExpansion

"@

$i = 1
$profileFiles = Get-ChildItem -Path $profileFolder -Filter *.xml
foreach ($file in $profileFiles) {
    $safeName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $content = Get-Content $file.FullName -Raw
    $minified = ($content -split "`r?`n" | ForEach-Object { $_.Trim() }) -join ""
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($minified))
    $varName = "b64_$safeName"

    $cmd += "set ""$varName=$b64""`r`n"
    $cmd += "(echo !$varName!) > ""%temp%\$safeName.b64""`r`n"
    $cmd += "certutil -f -decode ""%temp%\$safeName.b64"" ""%temp%\$safeName.xml"" >nul 2>&1`r`n"
    $cmd += "if errorlevel 1 (`r`n"
    $cmd += "  echo Failed to decode $safeName.xml`r`n"
    $cmd += "  timeout 60`r`n"
    $cmd += "  exit /b 1`r`n)`r`n"
    $cmd += "netsh wlan add profile filename=""%temp%\$safeName.xml"" user=all >nul 2>&1`r`n"
    $cmd += "del ""%temp%\$safeName.b64"" >nul 2>&1`r`n"
    $cmd += "del ""%temp%\$safeName.xml"" >nul 2>&1`r`n`r`n"
    $i++
}

$cmd += "endlocal`r`npause`r`nexit /b 0`r`n"
$cmd += ":NOADMIN`r`necho Administrator rights required.`r`ntimeout 60`r`nexit /b 1`r`n"

Set-Content -Path $cmdPath -Value $cmd -Encoding ASCII

Write-Host "Done. Run the generated file to import profiles:"
Write-Host "`r`n$cmdPath`r`n"
Start-Sleep -Seconds 60
