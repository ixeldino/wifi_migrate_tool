# Опис українською

[In english](#english-version)

## Утиліта для експорту та імпорту WiFi профілів

Цей PowerShell скрипт дозволяє зручно експортувати вибрані профілі WiFi з поточного комп’ютера та створює спеціальний скрипт для їх імпорту на іншому ПК.

### Особливості:
- Перегляд усіх наявних WiFi профілів.
- Вибір профілів для експорту через зручне графічне вікно з фільтром.
- Автоматичне створення імпортного скрипта для вибраних профілів.
- Підтримка запуску з параметрами для автоматизації (без GUI).
- Уникнення перезапису файлів при наявності профілів з однаковими іменами.

---

### Параметри скрипта

- **-All**  
  Експортувати всі доступні WiFi профілі. Не можна використовувати разом із параметром `-Filter`.

- **-Filter**  
  Експортувати лише профілі, імена яких містять заданий рядок або входять до списку. Можна передати як рядок (`-Filter Home`) або масив рядків (`-Filter Home,Office`). Не можна використовувати разом із `-All`.

- **-NoGui**  
  Не показувати графічний інтерфейс вибору, а одразу експортувати профілі згідно з параметрами `-All` або `-Filter`. Якщо не вказано жодного з них, повертає порожній список.

#### Логіка роботи параметрів:
- Якщо вказано `-All -NoGui`, експортуються всі профілі без GUI.
- Якщо вказано `-Filter "text" -NoGui`, експортуються лише профілі, що містять "text" у назві, без GUI.
- Якщо вказано лише `-Filter`, відкриється GUI з попередньо відфільтрованим списком.
- Якщо не вказано жодного параметра, відкриється GUI з усіма профілями.
- Якщо вказано обидва `-All` і `-Filter`, буде помилка.

---

### Приклад запуску через CMD файл з обходом політики виконання PowerShell

Щоб спростити запуск скрипта і уникнути проблем з політикою виконання PowerShell, можна використовувати `.cmd` файл, який:

- Піднімає права адміністратора (UAC).
- Завантажує скрипт, якщо його немає локально.
- Запускає PowerShell із параметром `-ExecutionPolicy Bypass` та потрібними параметрами.

#### Приклад файлу `wifi_export.cmd` (GUI, ручний вибір):

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

#### Приклад файлу `wifi_export_all.cmd` (автоматичний експорт усіх профілів):

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
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -All -NoGui
```

#### Приклад файлу `wifi_export_home.cmd` (автоматичний експорт профілів з фільтром "Home"):

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
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home -NoGui
```

#### Передача декількох значень фільтра (масив):

Щоб експортувати лише профілі з іменами, які містять "Home" або "Office", використовуйте такий синтаксис у командному файлі:

```batch
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home,Office -NoGui
```

---

# English version

## WiFi Profile Export & Import Utility

This PowerShell script allows you to easily export selected WiFi profiles from your computer and generates a special script for importing them on another PC.

### Features:
- View all available WiFi profiles.
- Select profiles to export via a convenient GUI with filtering.
- Automatically generate an import script for the selected profiles.
- Supports parameterized launch for automation (no GUI).
- Prevents file overwriting if profiles have the same name.

---

### Script Parameters

- **-All**  
  Export all available WiFi profiles. Cannot be used together with `-Filter`.

- **-Filter**  
  Export only profiles whose names contain the specified string or are in the provided list. Can be a string (`-Filter Home`) or an array (`-Filter Home,Office`). Cannot be used together with `-All`.

- **-NoGui**  
  Do not show the GUI, export profiles immediately according to `-All` or `-Filter`. If neither is specified, returns an empty list.

#### Parameter logic:
- If `-All -NoGui` is specified, all profiles are exported without GUI.
- If `-Filter "text" -NoGui` is specified, only profiles containing "text" are exported, no GUI.
- If only `-Filter` is specified, GUI opens with the filtered list pre-selected.
- If no parameters are specified, GUI opens with all profiles.
- If both `-All` and `-Filter` are specified, an error is thrown.

---

### Example CMD file to bypass PowerShell execution policy

To simplify running the script and avoid PowerShell execution policy issues, use a `.cmd` file that:

- Elevates to admin rights (UAC).
- Downloads the script if missing locally.
- Runs PowerShell with `-ExecutionPolicy Bypass` and the required parameters.

#### Example `wifi_export.cmd` (GUI, manual selection):

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

#### Example `wifi_export_all.cmd` (automatic export of all profiles):

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
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -All -NoGui
```

#### Example `wifi_export_home.cmd` (automatic export of profiles with filter "Home"):

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
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home -NoGui
```

#### Passing multiple filter values (array):

To export only profiles named "Home" or "Office", use this syntax in the CMD file:

```batch
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home,Office -NoGui
```

---

**Усі приклади та параметри перевірені та відповідають останній версії скрипта.**