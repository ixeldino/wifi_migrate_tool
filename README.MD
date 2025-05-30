# Опис українською

[In english](#english-version)

## Утиліта для імпорту WiFi профілів

Цей PowerShell скрипт дозволяє вибрати наявні профілі WiFi на комп’ютері та створює спеціальний скрипт, який імпортує вибрані профілі на інший комп’ютер. 

### Особливості:
- Перегляд усіх наявних WiFi профілів.
- Вибір профілів для експорту.
- Автоматичне створення скрипта для імпорту вибраних профілів.
- Зручне відновлення мережевих налаштувань на новому ПК.

### Використання:
1. Запустіть скрипт.
2. Оберіть WiFi профілі зі списку.
3. Отримайте готовий скрипт для імпорту на іншому комп’ютері.
4. Запустіть імпортний скрипт на цільовому ПК.

### Запуск через CMD файл з обходом політики виконання PowerShell

Щоб спростити запуск скрипта і уникнути проблем з політикою виконання PowerShell, можна використовувати `.cmd` файл, який:

- Піднімає права адміністратора (UAC).
- Завантажує скрипт, якщо його немає локально.
- Запускає PowerShell із параметром `-ExecutionPolicy Bypass`.

#### Приклад файлу `wifi_export.cmd`:

```batch
@echo off
if "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
  "%SYSTEMROOT%\sysnative\cmd.exe" /c %0 & goto :eof
)
reg query "HKEY_USERS\S-1-5-19\Environment" /v TEMP 2>&1 | findstr /I /C:"REG_EXPAND_SZ" 2>&1 >nul || (
  if "%1"=="elevated" (call :NOADMIN & exit /b 1)
  echo CreateObject^("Shell.Application"^).ShellExecute WScript.Arguments^(0^),"elevated","","runas",1 >"%TEMP%\getadmin.vbs"
  wscript.exe //nologo "%TEMP%\getadmin.vbs" "%~dpnx0" elevated
  del /a /f /q "%TEMP%\getadmin.vbs"
  exit /b
)
cd %~dp0
IF NOT EXIST %~dp0\wifi_pro.ps1 (
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/refs/heads/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1
```

# English version
## WiFi Profile Import Utility
This PowerShell script allows you to select existing WiFi profiles on your computer and generates a special script that imports the selected profiles onto another computer.

## Features:
### Lists all available WiFi profiles.

- Allows selection of profiles to export.

- Automatically creates an import script for the selected profiles.

- Simplifies restoring network settings on a new PC.

### Usage:
1. Run the script.

1. Select WiFi profiles from the list.

1. Receive the generated import script.

1. Run the import script on the target machine.

### Running via CMD file to bypass PowerShell execution policy
To simplify running the script and avoid PowerShell execution policy issues, use a .cmd file that:

- Elevates to admin rights (UAC).

- Downloads the script if missing locally.

- Runs PowerShell with -ExecutionPolicy Bypass.

#### Example wifi_export.cmd file:
```batch
@echo off
if "%PROCESSOR_ARCHITECTURE%"=="x86" if "%PROCESSOR_ARCHITEW6432%"=="AMD64" (
  "%SYSTEMROOT%\sysnative\cmd.exe" /c %0 & goto :eof
)
reg query "HKEY_USERS\S-1-5-19\Environment" /v TEMP 2>&1 | findstr /I /C:"REG_EXPAND_SZ" 2>&1 >nul || (
  if "%1"=="elevated" (call :NOADMIN & exit /b 1)
  echo CreateObject^("Shell.Application"^).ShellExecute WScript.Arguments^(0^),"elevated","","runas",1 >"%TEMP%\getadmin.vbs"
  wscript.exe //nologo "%TEMP%\getadmin.vbs" "%~dpnx0" elevated
  del /a /f /q "%TEMP%\getadmin.vbs"
  exit /b
)
cd %~dp0
IF NOT EXIST %~dp0\wifi_pro.ps1 (
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/refs/heads/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1
```