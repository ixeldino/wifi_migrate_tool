# Опис українською

[In english](#english-version)

## Утиліта для експорту та імпорту WiFi профілів

Цей PowerShell скрипт дозволяє зручно експортувати вибрані профілі WiFi з поточного комп’ютера та створює спеціальний скрипт для їх імпорту на іншому ПК.

---

## Як працює скрипт

### Запуск скрипта

#### 1. Через PowerShell (ручний запуск)

Відкрийте PowerShell у папці зі скриптом та виконайте:

```powershell
.\wifi_pro.ps1
```

Можна одразу передати параметри, наприклад:

```powershell
.\wifi_pro.ps1 -All -NoGui
.\wifi_pro.ps1 -Filter Home -NoGui
.\wifi_pro.ps1 -Filter Home,Office -NoGui
```

#### 2. Через командний файл (.cmd)

Для зручності можна використовувати підготовлені .cmd-файли, які:
- Піднімають права адміністратора (UAC)
- Завантажують скрипт, якщо його немає локально
- Запускають PowerShell із потрібними параметрами

##### Приклад файлу `wifi_export.cmd` (GUI, ручний вибір):

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
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1
```

##### Приклад файлу `wifi_export_all.cmd` (експорт усіх профілів):

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
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -All -NoGui
```

##### Приклад файлу `wifi_export_home.cmd` (експорт профілів з фільтром "Home"):

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
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home -NoGui
```

##### Передача декількох значень фільтра (масив):

```batch
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home,Office -NoGui
```

#### 3. Через PowerShell із завантаженням через інтернет (IRM)

```powershell
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex
```

Можна додати параметри:

```powershell
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex -All -NoGui
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex -Filter Home,Office -NoGui
```

---

## Елементи керування та інтерфейс

- **GUI-режим:**  
  Відкривається вікно з:
  - Списком усіх знайдених WiFi профілів
  - Полем фільтрації для швидкого пошуку
  - Кнопками: Select All, Clear, OK, Cancel, очищення фільтра
  - Можливість вибрати декілька профілів

- **NoGui-режим:**  
  Вибір профілів відбувається автоматично згідно з параметрами, вікно не відкривається.

---

## Які файли створюються і де

- **Папка з іменем комп’ютера**  
  У тій же папці, де знаходиться скрипт, буде створено папку з іменем вашого комп’ютера (наприклад, `DESKTOP-12345`).

- **XML-файли профілів**  
  У цій папці будуть збережені експортовані профілі у форматі `.xml`.

- **Імпортний скрипт**  
  У цій же папці буде створено файл `wifi_import_<ім'я_комп'ютера>.cmd`.  
  УВАГА: Всі профілі вбудовані у цей скрипт у вигляді base64-рядків, тому для імпорту не потрібні окремі XML-файли.

---

## Як імпортувати профілі на іншому комп’ютері

### 1. Імпорт усіх профілів одразу

- Скопіюйте папку з імпортним скриптом на інший комп’ютер.
- Запустіть файл `wifi_import_<ім'я_комп'ютера>.cmd` від імені адміністратора.
- Всі профілі будуть автоматично додані у систему.

### 2. Імпорт окремого профілю вручну

- У папці з експортом знайдіть потрібний `.xml` файл профілю.
- Виконайте команду у PowerShell або CMD (від імені адміністратора):

```powershell
netsh wlan add profile filename="шлях_до_файлу.xml" user=all
```

---

## Структура та приклади

### Приклад командного файлу для експорту всіх профілів

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
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -All -NoGui
```

### Приклад командного файлу для експорту профілів з фільтром

```batch
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home,Office -NoGui
```

---

## Важливо

- Профілі не перезаписуються: якщо імена збігаються, до імені додається індекс.
- Всі експортовані профілі вбудовані у імпортний скрипт, тому для імпорту не потрібні окремі XML-файли.
- Для імпорту потрібні права адміністратора.

---

## Готовий EXE-файл

У [релізах GitHub](https://github.com/ixeldino/wifi_migrate_tool/releases) можна завантажити вже скомпільований виконуваний файл (`wifi_pro.exe`).

- **EXE-версія** не потребує встановленого PowerShell чи додаткових модулів.
- Працює аналогічно скрипту: підтримує всі параметри, GUI/NoGui, автоматично відкриває папку з профілями після експорту.
- Просто завантажте `wifi_pro.exe`, запустіть від імені адміністратора та користуйтеся!

---

# English version

## WiFi Profile Export & Import Utility

This PowerShell script allows you to easily export selected WiFi profiles from your computer and generates a special script for importing them on another PC.

---

## How to run the script

### 1. From PowerShell (manual launch)

Open PowerShell in the folder with the script and run:

```powershell
.\wifi_pro.ps1
```

You can pass parameters, for example:

```powershell
.\wifi_pro.ps1 -All -NoGui
.\wifi_pro.ps1 -Filter Home -NoGui
.\wifi_pro.ps1 -Filter Home,Office -NoGui
```

### 2. Using a command file (.cmd)

For convenience, use prepared .cmd files that:
- Elevate to admin (UAC)
- Download the script if missing
- Run PowerShell with the required parameters

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
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1
```

#### Example `wifi_export_all.cmd` (export all profiles):

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
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -All -NoGui
```

#### Example `wifi_export_home.cmd` (export profiles with filter "Home"):

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
  powershell -command "Invoke-RestMethod -Uri 'https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1' -OutFile '%~dp0\wifi_pro.ps1'"
)
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home -NoGui
```

#### Passing multiple filter values (array):

```batch
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home,Office -NoGui
```

### 3. From PowerShell via IRM (download and run in one line)

```powershell
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex
```

With parameters:

```powershell
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex -All -NoGui
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex -Filter Home,Office -NoGui
```

---

## Controls and interface

- **GUI mode:**  
  Window with:
  - List of all found WiFi profiles
  - Filter box for quick search
  - Buttons: Select All, Clear, OK, Cancel, clear filter
  - Multi-select support

- **NoGui mode:**  
  Profiles are selected automatically according to parameters, no window is shown.

---

## What files are created and where

- **Computer-named folder**  
  In the same folder as the script, a folder with your computer name will be created (e.g., `DESKTOP-12345`).

- **Profile XML files**  
  Exported profiles are saved as `.xml` files in this folder.

- **Import script**  
  In the same folder, a file `wifi_import_<computername>.cmd` will be created.  
  **All profiles are embedded in this script as base64 strings, so you do not need separate XML files for import.**

---

## How to import profiles on another computer

### 1. Import all profiles at once

- Copy the folder with the import script to another computer.
- Run `wifi_import_<computername>.cmd` as administrator.
- All profiles will be added automatically.

### 2. Import a single profile manually

- In the export folder, find the desired `.xml` profile file.
- Run in PowerShell or CMD (as administrator):

```powershell
netsh wlan add profile filename="path_to_file.xml" user=all
```

---

## Notes

- Profiles are not overwritten: if names match, an index is added.
- All exported profiles are embedded in the import script, so you do not need separate XML files for import.
- Admin rights are required for import.

---

## Готовий EXE-файл

У [релізах GitHub](https://github.com/ixeldino/wifi_migrate_tool/releases) можна завантажити вже скомпільований виконуваний файл (`wifi_pro.exe`).

- **EXE-версія** не потребує встановленого PowerShell чи додаткових модулів.
- Працює аналогічно скрипту: підтримує всі параметри, GUI/NoGui, автоматично відкриває папку з профілями після експорту.
- Просто завантажте `wifi_pro.exe`, запустіть від імені адміністратора та користуйтеся!

---

**Усі приклади та параметри перевірені та відповідають останній версії скрипта.**