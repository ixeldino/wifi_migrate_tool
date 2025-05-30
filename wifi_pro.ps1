# === Export and Package Wi-Fi Profiles into Autonomously Executable CMD ===
$ErrorActionPreference = 'Stop'

# Отримати ім’я комп’ютера
$computerName = $env:COMPUTERNAME

# Поточна папка запуску
$baseFolder = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Створити підпапку для профілів
$profileFolder = Join-Path $baseFolder $computerName
if (-not (Test-Path $profileFolder)) {
    New-Item -Path $profileFolder -ItemType Directory | Out-Null
}

# Отримати список профілів Wi-Fi
$profiles = netsh wlan show profiles | Where-Object { $_ -match "All User Profile" } |
    ForEach-Object { ($_ -split ":")[1].Trim() }

if (-not $profiles) {
    Write-Host "❌ Немає доступних Wi-Fi профілів."
    exit
}

# Вибір профілів через GUI
$selectedProfiles = $profiles | Out-GridView -Title "Оберіть Wi-Fi профілі для експорту" -OutputMode Multiple
if (-not $selectedProfiles) {
    Write-Host "❗️ Вибір скасовано."
    exit
}

# Обробка кожного профілю
foreach ($profile in $selectedProfiles) {
    $safeName = $profile -replace '[\\/:*?"<>|]', '_'
    $xmlPath = Join-Path $profileFolder "$safeName.xml"

    # Стандартний експорт
    netsh wlan export profile name="$profile" folder="$profileFolder" key=clear > $null

    # Виправити файл на unprotected keyMaterial
    $exportedXml = Get-ChildItem $profileFolder -Filter "$safeName*.xml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($exportedXml) {
        [xml]$xmlDoc = Get-Content $exportedXml.FullName
        $key = (netsh wlan show profile name="$profile" key=clear | Select-String "Key Content\s+:\s+(.*)").Matches.Groups[1].Value
        if ($key) {
            $keyNode = $xmlDoc.WLANProfile.MSM.security.sharedKey
            $keyNode.protected = "false"
            $keyNode.keyMaterial = $key
            $xmlDoc.Save($xmlPath)
            Remove-Item $exportedXml.FullName -Force
        }
    }
}

# Створити CMD файл
$cmdPath = Join-Path $profileFolder "wifi_imports_$computerName.cmd"
$cmd = @"
@echo off
if "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="AMD64" ("%SYSTEMROOT%\sysnative\cmd.exe" /c %0 & goto :eof)
reg query "HKEY_USERS\S-1-5-19\Environment" /v TEMP 2>&1 | findstr /I /C:"REG_EXPAND_SZ" 2>&1 >nul || (
	if "%1"=="elevated" (call :NOADMIN & exit /b 1)
	echo CreateObject^("Shell.Application"^).ShellExecute WScript.Arguments^(0^),"elevated","","runas",1 >"%TEMP%\getadmin.vbs"
	wscript.exe //nologo "%TEMP%\getadmin.vbs" "%~dpnx0"
	del /a /f /q "%TEMP%\getadmin.vbs"
	exit /b
)
setlocal EnableDelayedExpansion


"@

$i = 1
$profileFiles = Get-ChildItem -Path $profileFolder -Filter *.xml
foreach ($file in $profileFiles) {
    $content = Get-Content $file.FullName -Raw
    $minified = ($content -split "`r?`n" | ForEach-Object { $_.Trim() }) -join ""
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($minified))
    $varName = "b64_$i"
    $tempName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)

    $cmd += "set ""${varName}=$b64""`r`n"
    $cmd += "> ""%temp%\$tempName.b64"" echo(!${varName}!`r`n"
    $cmd += "certutil -f -decode ""%temp%\$tempName.b64"" ""%temp%\$tempName.xml"" >nul 2>&1`r`n"
    $cmd += "if !errorlevel! neq 0 (`r`n  color 4F`r`n  echo [ERROR] $tempName.xml`r`n  goto :end`r`n)`r`n"
    $i++
}

foreach ($file in $profileFiles) {
    $tempName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $cmd += "netsh wlan add profile filename=""%temp%\$tempName.xml"" user=all `r`n"
    $cmd += "if !errorlevel! neq 0 (`r`n  color 4F`r`n  echo [ERROR] Import $tempName.xml failed`r`n  goto :end`r`n)`r`n"
}

$cmd += "color 2F`r`necho [OK] All profiles are imported succesfully.`r`n:end`r`n"
foreach ($file in $profileFiles) {
    $tempName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
    $cmd += "del ""%temp%\$tempName.b64"" >nul 2>&1`r`n"
    $cmd += "del ""%temp%\$tempName.xml"" >nul 2>&1`r`n"
}
$cmd += "`r`nendlocal`r`npause`r`n"

Set-Content -Path $cmdPath -Value $cmd -Encoding UTF8

Write-Host "`n✅ Готово! Профілі та wifi_embedded.cmd збережено в:"
Write-Host "`n$profileFolder"