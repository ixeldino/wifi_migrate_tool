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

## GetToolExe.cmd — автоматичне оновлення exe-файлу з GitHub Releases

**GetToolExe.cmd** — сучасний гібридний CMD+PowerShell скрипт для автоматичного завантаження та оновлення `wifi_pro.exe` з GitHub Releases.

- Працює як звичайний .cmd-файл, але вся логіка — у PowerShell (без створення тимчасових .ps1).
- Завантажує останній реліз exe-файлу з GitHub, перевіряє SHA256, показує кольорові повідомлення.
- Таймаут замість pause: вікно не закривається одразу, а чекає натискання клавіші або таймауту.
- Коректно працює у будь-якому середовищі (cmd, PowerShell, Windows Terminal).
- Всі повідомлення — англійською, зручний UX.

**Запуск:**

```cmd
GetToolExe.cmd
```

або подвійний клік у Провіднику.

> Скрипт не потребує прав адміністратора, але для запису у поточну папку потрібні відповідні права.

---

**Усі приклади та параметри перевірені та відповідають останній версії скрипта.**