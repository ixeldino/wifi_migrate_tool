param(
    [switch]$All,
    [string[]]$Filter,
    [switch]$NoGui
)
# Export Wi-Fi profiles and generate a self-contained CMD importer

$ErrorActionPreference = 'Stop'

# --- Templates ---

$cmdHeaderTemplate = @'
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

'@

$cmdProfileTemplate = @'
set "{VarName}={Base64}"
(echo !{VarName}!) > "%temp%\{SafeName}.b64"
certutil -f -decode "%temp%\{SafeName}.b64" "%temp%\{SafeName}.xml" >nul 2>&1
if errorlevel 1 (
  echo Failed to decode {SafeName}.xml
  timeout 60
  exit /b 1
)
netsh wlan add profile filename="%temp%\{SafeName}.xml" user=all >nul 2>&1
del "%temp%\{SafeName}.b64" >nul 2>&1
del "%temp%\{SafeName}.xml" >nul 2>&1

'@

$cmdFooterTemplate = @'
endlocal
pause
exit /b 0
:NOADMIN
echo Administrator rights required.
timeout 60
exit /b 1
'@

# --- Functions ---

function Write-ScriptNotify {
    param(
        [Parameter(Mandatory = $true)][string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White,
        [int]$Timeout,
        [switch]$Exit
    )
    # Robust EXE detection: check $env:PS2EXE, $PSCommandPath, and $MyInvocation.MyCommand.Path
    # Use [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName as the ultimate fallback
    $isExe = $false
    if ($env:PS2EXE -eq 'true') { $isExe = $true }
    elseif ($PSCommandPath -and $PSCommandPath -like '*.exe') { $isExe = $true }
    elseif ($MyInvocation.MyCommand.Path -and $MyInvocation.MyCommand.Path -like '*.exe') { $isExe = $true }
    else {
        try {
            $procPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
            if ($procPath -and $procPath.ToLower().EndsWith('.exe')) { $isExe = $true }
        }
        catch {}
    }

    Write-Host $Message -ForegroundColor $Color
    if (-not $isExe -and $Timeout -and $Timeout -gt 0) {
        $remaining = [int]$Timeout
        Write-Host "Press any key to close or wait $Timeout seconds..." -NoNewline
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
                Write-Host ("\rPress any key to close or wait {0} seconds..." -f $remaining) -NoNewline
            }
            Start-Sleep -Milliseconds 200
        }
        Write-Host ""
    }
    if ($Exit) {
        exit
    }
}

function Get-ProfileFolder {
    param($BaseFolder, $ComputerName)
    $folder = Join-Path $BaseFolder $ComputerName
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory | Out-Null
    }
    return $folder
}

function Get-WifiProfiles {
    netsh wlan show profiles | Where-Object { $_ -match "All User Profile" } |
    ForEach-Object { ($_ -split ":")[1].Trim() }
}

function Export-WifiProfile {
    param($ProfileName, $ProfileFolder)
    # Sanitize profile name for file system
    $safeNameBase = $ProfileName -replace '[\\/:*?"<>|]', '_'
    $safeName = $safeNameBase
    $counter = 1
    # Check for existing file and add index if needed
    while (Test-Path (Join-Path $ProfileFolder "$safeName.xml")) {
        $safeName = "$safeNameBase`_$counter"
        $counter++
    }
    $xmlPath = Join-Path $ProfileFolder "$safeName.xml"
    netsh wlan export profile name="$ProfileName" folder="$ProfileFolder" key=clear > $null

    $exportedXml = Get-ChildItem $ProfileFolder -Filter "$safeNameBase*.xml" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($exportedXml) {
        [xml]$xmlDoc = Get-Content $exportedXml.FullName
        $key = (netsh wlan show profile name="$ProfileName" key=clear | Select-String "Key Content\s+: (.*)").Matches.Groups[1].Value
        if ($key) {
            $keyNode = $xmlDoc.WLANProfile.MSM.security.sharedKey
            $keyNode.protected = "false"
            $keyNode.keyMaterial = $key
            $xmlDoc.Save($xmlPath)
            Remove-Item $exportedXml.FullName -Force
        }
    }
}

function Build-ProfileBlock {
    param($File)
    $safeName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
    $content = Get-Content $File.FullName -Raw
    $minified = ($content -split "`r?`n" | ForEach-Object { $_.Trim() }) -join ""
    $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($minified))
    $varName = "b64_$safeName"
    return $cmdProfileTemplate.Replace('{VarName}', $varName).Replace('{Base64}', $b64).Replace('{SafeName}', $safeName)
}

function Build-CmdScript {
    param($ProfileFiles)
    $cmd = $cmdHeaderTemplate
    foreach ($file in $ProfileFiles) {
        $cmd += Build-ProfileBlock -File $file
    }
    $cmd += $cmdFooterTemplate
    return $cmd
}

<#
.SYNOPSIS
    Shows a Windows Forms dialog for selecting Wi-Fi profiles, with flexible filtering and automation options.

.DESCRIPTION
    Show-WifiProfileSelector displays a CheckedListBox with available Wi-Fi profiles and allows the user to select multiple profiles.
    - If -Filter is a string, only profiles containing the substring are shown and pre-selected.
    - If -Filter is a string array, only profiles matching any string in the array are shown and pre-selected.
    - If -All is specified, all profiles are pre-selected (cannot be used with -Filter).
    - If -NoGui is specified, the dialog is not shown and the function returns the filtered or all profiles automatically.
    - If both -All and -NoGui are specified, all profiles are returned.
    - If -NoGui and -Filter are specified, only filtered profiles are returned.
    - -All and -Filter cannot be used together (throws error).

.PARAMETER Profiles
    Array of all available Wi-Fi profile names.

.PARAMETER Filter
    String or string array for filtering profile names.

.PARAMETER All
    Switch to select all profiles.

.PARAMETER NoGui
    Switch to skip GUI and return filtered or all profiles.

.EXAMPLE
    $selected = Show-WifiProfileSelector -Profiles $profiles -Filter "Home"
    $selected = Show-WifiProfileSelector -Profiles $profiles -Filter @("Home","Office") -NoGui
    $selected = Show-WifiProfileSelector -Profiles $profiles -All -NoGui
#>
function Show-WifiProfileSelector {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Profiles,
        [Parameter()]
        [Alias('f')]
        [Object]$Filter,
        [switch]$All,
        [switch]$NoGui
    )

    if ($All -and $Filter) {
        throw "Parameters -All and -Filter cannot be used together."
    }

    $filteredProfiles = $Profiles
    $preSelected = @()
    if ($Filter) {
        if ($Filter -is [string]) {
            $filteredProfiles = $Profiles | Where-Object { $_ -like "*$Filter*" }
            $preSelected = $filteredProfiles
        }
        elseif ($Filter -is [System.Collections.IEnumerable]) {
            $filteredProfiles = $Profiles | Where-Object { $Filter -contains $_ }
            $preSelected = $filteredProfiles
        }
    }
    elseif ($All) {
        $preSelected = $Profiles
    }

    if ($NoGui) {
        if ($All) {
            return $Profiles
        }
        elseif ($Filter) {
            return $filteredProfiles
        }
        else {
            return @()
        }
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object Windows.Forms.Form
    $form.Text = "Select Wi-Fi profiles to export"
    $form.Size = New-Object Drawing.Size(440, 520)
    $form.StartPosition = "CenterScreen"
    $form.BackColor = [System.Drawing.Color]::White
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.ShowInTaskbar = $true

    # Set window icon (replace path with your own .ico file if needed)
    $iconPath = "$PSScriptRoot\wifi.ico"
    if (Test-Path $iconPath) {
        $form.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon($iconPath)
    }

    $label = New-Object Windows.Forms.Label
    $label.Text = "Select one or more Wi-Fi profiles:"
    $label.Font = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
    $label.AutoSize = $true
    $label.Location = New-Object Drawing.Point(10, 10)
    $form.Controls.Add($label)

    # Filter TextBox
    $filterBox = New-Object Windows.Forms.TextBox
    $filterBox.Font = New-Object Drawing.Font("Segoe UI", 10)
    $filterBox.Size = New-Object Drawing.Size(260, 28)
    $filterBox.Location = New-Object Drawing.Point(10, 38)
    $form.Controls.Add($filterBox)

    # Clear filter button
    $clearFilterButton = New-Object Windows.Forms.Button
    $clearFilterButton.Text = "✕"
    $clearFilterButton.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $clearFilterButton.Size = New-Object Drawing.Size(32, 28)
    $clearFilterButton.Location = New-Object Drawing.Point(275, 38)
    $form.Controls.Add($clearFilterButton)

    # CheckedListBox
    $listBox = New-Object Windows.Forms.CheckedListBox
    $listBox.Font = New-Object Drawing.Font("Segoe UI", 10)
    $listBox.Location = New-Object Drawing.Point(10, 75)
    $listBox.Size = New-Object Drawing.Size(400, 340)
    $listBox.BackColor = [System.Drawing.Color]::WhiteSmoke
    $form.Controls.Add($listBox)

    # Helper: update listbox items based on filter
    function Update-ListBox {
        param($filterText)
        $listBox.Items.Clear()
        if ([string]::IsNullOrWhiteSpace($filterText)) {
            $visibleProfiles = $filteredProfiles
        }
        else {
            $visibleProfiles = $filteredProfiles | Where-Object { $_ -like "*$filterText*" }
        }
        foreach ($item in $visibleProfiles) {
            $listBox.Items.Add($item) | Out-Null
        }
        # Restore checked state for pre-selected
        for ($i = 0; $i -lt $listBox.Items.Count; $i++) {
            if ($preSelected -contains $listBox.Items[$i]) {
                $listBox.SetItemChecked($i, $true)
            }
        }
    }

    # Initial fill
    Update-ListBox -filterText $filterBox.Text

    # Filter on text change
    $filterBox.Add_TextChanged({
            Update-ListBox -filterText $filterBox.Text
            # Reset select all toggle state
            $selectAllButton.Tag = $false
            $selectAllButton.Text = "Select All"
        })

    # Clear filter button logic
    $clearFilterButton.Add_Click({
            $filterBox.Text = ""
            $filterBox.Focus()
        })

    # Select All/Unselect All button
    $selectAllButton = New-Object Windows.Forms.Button
    $selectAllButton.Text = "Select All"
    $selectAllButton.Size = New-Object Drawing.Size(100, 30)
    $selectAllButton.Location = New-Object Drawing.Point(10, 430)
    $selectAllButton.Tag = $false # false = not all selected

    $selectAllButton.Add_Click({
            $allSelected = $selectAllButton.Tag
            for ($i = 0; $i -lt $listBox.Items.Count; $i++) {
                $listBox.SetItemChecked($i, -not $allSelected)
            }
            $selectAllButton.Tag = -not $allSelected
            if ($selectAllButton.Tag) {
                $selectAllButton.Text = "Unselect All"
            }
            else {
                $selectAllButton.Text = "Select All"
            }
        })
    $form.Controls.Add($selectAllButton)

    # Clear selection button
    $clearButton = New-Object Windows.Forms.Button
    $clearButton.Text = "Clear"
    $clearButton.Size = New-Object Drawing.Size(100, 30)
    $clearButton.Location = New-Object Drawing.Point(120, 430)
    $clearButton.Add_Click({
            for ($i = 0; $i -lt $listBox.Items.Count; $i++) {
                $listBox.SetItemChecked($i, $false)
            }
            $selectAllButton.Tag = $false
            $selectAllButton.Text = "Select All"
        })
    $form.Controls.Add($clearButton)

    $okButton = New-Object Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.Size = New-Object Drawing.Size(100, 30)
    $okButton.Location = New-Object Drawing.Point(230, 430)
    $okButton.Add_Click({ $form.Tag = 'OK'; $form.Close() })
    $form.Controls.Add($okButton)

    $cancelButton = New-Object Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.Size = New-Object Drawing.Size(100, 30)
    $cancelButton.Location = New-Object Drawing.Point(340, 430)
    $cancelButton.Add_Click({ $form.Tag = 'Cancel'; $form.Close() })
    $form.Controls.Add($cancelButton)

    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.Topmost = $true

    $form.ShowDialog() | Out-Null
    if ($form.Tag -eq 'Cancel') {
        return @()
    }
    $selectedProfiles = @()
    foreach ($item in $listBox.CheckedItems) { $selectedProfiles += $item }
    return $selectedProfiles
}

# --- Main logic ---

# --- Detect if running as EXE or PS1 ---
# Use [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName as the ultimate fallback
$isExe = $false
if ($env:PS2EXE -eq 'true') { $isExe = $true }
elseif ($PSCommandPath -and $PSCommandPath -like '*.exe') { $isExe = $true }
elseif ($MyInvocation.MyCommand.Path -and $MyInvocation.MyCommand.Path -like '*.exe') { $isExe = $true }
else {
    try {
        $procPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        if ($procPath -and $procPath.ToLower().EndsWith('.exe')) { $isExe = $true }
    }
    catch {}
}

# --- HEADER ---
if (-not $isExe) {

    Write-Host 'WiFi Profile Exporter & Importer' -ForegroundColor Yellow
    Write-Host 'https://github.com/ixeldino/wifi_migrate_tool' -ForegroundColor Yellow

    Write-Host 'Glory to UKRAINE!' -ForegroundColor Blue

}

# --- Robust base folder detection for .ps1 and .exe ---
if ($MyInvocation.MyCommand.Path) {
    $baseFolder = Split-Path -Parent $MyInvocation.MyCommand.Path
}
elseif ($PSScriptRoot) {
    $baseFolder = $PSScriptRoot
}
else {
    $baseFolder = [System.AppDomain]::CurrentDomain.BaseDirectory
}

$computerName = $env:COMPUTERNAME

$profiles = Get-WifiProfiles

if (-not $profiles) {
    Write-ScriptNotify -Message "No Wi-Fi profiles found." -Color Red -Timeout 60 -Exit
}

# Use script parameters for selector
$selectorParams = @{
    Profiles = $profiles
}
if ($All) { $selectorParams.All = $true }
if ($NoGui) { $selectorParams.NoGui = $true }
if ($Filter) { $selectorParams.Filter = $Filter }

$selectedProfiles = Show-WifiProfileSelector @selectorParams

if (-not $selectedProfiles) {
    Write-ScriptNotify -Message "Selection cancelled." -Color Yellow -Timeout 60 -Exit
}

# Створюємо папку лише якщо є профілі для експорту
$profileFolder = $null
if ($selectedProfiles.Count -gt 0) {
    $profileFolder = Get-ProfileFolder -BaseFolder $baseFolder -ComputerName $computerName

    foreach ($profile in $selectedProfiles) {
        Export-WifiProfile -ProfileName $profile -ProfileFolder $profileFolder
    }

    $profileFiles = Get-ChildItem -Path $profileFolder -Filter *.xml
    if ($profileFiles.Count -eq 0) {
        Write-ScriptNotify -Message "No profiles were exported." -Color Yellow -Timeout 60 -Exit
    }

    $cmdScript = Build-CmdScript -ProfileFiles $profileFiles

    $cmdPath = Join-Path $profileFolder "wifi_import_$computerName.cmd"
    Set-Content -Path $cmdPath -Value $cmdScript -Encoding ASCII

    if ($isExe) {
        Write-Host "Done. Run the generated file to import profiles:`r`n$cmdPath`r`n" -ForegroundColor Green
        Start-Process explorer.exe $profileFolder
    }
    else {
        Write-ScriptNotify -Message "Done. Run the generated file to import profiles:`r`n$cmdPath`r`n" -Color Green -Timeout 60
    }
}
else {
    Write-ScriptNotify -Message "No profiles selected for export." -Color Yellow -Timeout 60 -Exit
}
