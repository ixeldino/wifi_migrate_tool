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
- **EXE-файл збирається автоматично при кожній зміні основного скрипта (`wifi_pro.ps1`) та завжди відповідає його актуальній версії.**

---

## GetToolExe.cmd — автоматичне оновлення exe-файлу з GitHub Releases

**GetToolExe.cmd** — це утиліта для автоматичного завантаження та оновлення `wifi_pro.exe` з GitHub Releases.

- При запуску файл перевіряє наявність нової версії `wifi_pro.exe` у релізах GitHub і завантажує її, якщо доступне оновлення.
- Не потребує прав адміністратора (але потрібні права на запис у поточну папку).
- Підходить для швидкого отримання або оновлення exe-файлу без ручного пошуку на GitHub.

**Запуск:**

```cmd
GetToolExe.cmd
```

або подвійний клік у Провіднику.

> Скрипт не потребує прав адміністратора, але для запису у поточну папку потрібні відповідні права.

---

## Підтримайте Україну!

Ваша допомога важлива для захисту та відновлення України. Підтримайте перевірені фонди:

- **United24 (офіційна платформа)** — головна державна платформа для збору коштів на підтримку України. Кошти спрямовуються на оборону, гуманітарну допомогу, медицину, відновлення країни.  
  Сайт: https://u24.gov.ua  
  Банківські реквізити: https://u24.gov.ua/donate

- **Благодійний фонд "Повернись живим"** — один із найбільших і найпрозоріших фондів допомоги армії. Фонд забезпечує ЗСУ сучасною технікою, навчанням, підтримкою військових та їхніх родин.  
  Сайт: https://savelife.in.ua/donate/  
  Банківські реквізити: https://savelife.in.ua/donate/#donate-army-card

- **Фонд Сергія Притули** — громадський фонд, який займається закупівлею техніки, дронів, транспорту, медичного обладнання для ЗСУ, а також гуманітарною допомогою.  
  Сайт: https://prytulafoundation.org/  
  Банківські реквізити: https://prytulafoundation.org/help/donate

- **Благодійний фонд "Спільнота Стерненка"** — волонтерський фонд, що збирає кошти на потреби ЗСУ, закупівлю дронів, амуніції, допомогу пораненим та гуманітарні ініціативи.  
  Сайт: https://www.sternenkofund.org 
  🏦 Постійна банка: https://send.monobank.ua/jar/2JbpBYkhMv  
  💳 Монобаза: https://base.monobank.ua/rusoriz  
  💸 PayPal: sternenkopaypal@gmail.com  
  🏦 Конверт Приват: https://www.privat24.ua/send/gbwmp  
  💸 Більше реквізитів (у тому числі для юросіб): https://www.sternenkofund.org/donate

---

# English version

## Utility for Exporting and Importing WiFi Profiles

This PowerShell script allows you to conveniently export selected WiFi profiles from your current computer and generates a special script for importing them on another PC.

---

## How the Script Works

### Script Launch

#### 1. Via PowerShell (manual launch)

Open PowerShell in the folder with the script and run:

```powershell
.\wifi_pro.ps1
```

You can immediately pass parameters, for example:

```powershell
.\wifi_pro.ps1 -All -NoGui
.\wifi_pro.ps1 -Filter Home -NoGui
.\wifi_pro.ps1 -Filter Home,Office -NoGui
```

#### 2. Via command file (.cmd)

For convenience, you can use prepared .cmd files that:
- Elevate to administrator rights (UAC)
- Download the script if it is not present locally
- Launch PowerShell with the required parameters

##### Example file `wifi_export.cmd` (GUI, manual selection):

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

##### Example file `wifi_export_all.cmd` (export all profiles):

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

##### Example file `wifi_export_home.cmd` (export profiles with filter "Home"):

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

##### Passing multiple filter values (array):

```batch
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home,Office -NoGui
```

#### 3. Via PowerShell with online download (IRM)

```powershell
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex
```

You can add parameters:

```powershell
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex -All -NoGui
irm https://raw.githubusercontent.com/ixeldino/wifi_migrate_tool/main/wifi_pro.ps1 | iex -Filter Home,Office -NoGui
```

---

## Controls and Interface

- **GUI mode:**
  - A window opens with:
    - A list of all found WiFi profiles
    - A filter field for quick search
    - Buttons: Select All, Clear, OK, Cancel, clear filter
    - Ability to select multiple profiles

- **NoGui mode:**
  - Profile selection is performed automatically according to parameters, no window is shown.

---

## What Files Are Created and Where

- **Folder with computer name**
  In the same folder as the script, a folder with your computer's name (e.g., `DESKTOP-12345`) will be created.

- **Profile XML files**
  Exported profiles will be saved in this folder as `.xml` files.

- **Import script**
  In the same folder, a file `wifi_import_<computer_name>.cmd` will be created.
  NOTE: All profiles are embedded in this script as base64 strings, so no separate XML files are needed for import.

---

## How to Import Profiles on Another Computer

### 1. Import all profiles at once

- Copy the folder with the import script to another computer.
- Run the file `wifi_import_<computer_name>.cmd` as administrator.
- All profiles will be automatically added to the system.

### 2. Import a single profile manually

- In the export folder, find the required `.xml` profile file.
- Run the command in PowerShell or CMD (as administrator):

```powershell
netsh wlan add profile filename="path_to_file.xml" user=all
```

---

## Structure and Examples

### Example command file for exporting all profiles

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

### Example command file for exporting profiles with filter

```batch
powershell -executionpolicy bypass -nologo -file %~dp0\wifi_pro.ps1 -Filter Home,Office -NoGui
```

---

## Important

- Profiles are not overwritten: if names match, an index is added to the name.
- All exported profiles are embedded in the import script, so no separate XML files are needed for import.
- Administrator rights are required for import.

---

## Ready-to-use EXE file

You can download the compiled executable (`wifi_pro.exe`) from [GitHub Releases](https://github.com/ixeldino/wifi_migrate_tool/releases).

- **EXE version** does not require installed PowerShell or additional modules.
- Works the same as the script: supports all parameters, GUI/NoGui, automatically opens the folder with profiles after export.
- Just download `wifi_pro.exe`, run as administrator, and use!
- **The EXE file is built automatically on every change to the main script (`wifi_pro.ps1`) and always matches its current version.**

---

## GetToolExe.cmd — automatic exe update from GitHub Releases

**GetToolExe.cmd** is a utility for automatically downloading and updating `wifi_pro.exe` from GitHub Releases.

- On launch, the file checks for a new version of `wifi_pro.exe` in GitHub releases and downloads it if an update is available.
- Does not require administrator rights (but you need write permissions to the current folder).
- Suitable for quickly obtaining or updating the exe file without manually searching on GitHub.

**Run:**

```cmd
GetToolExe.cmd
```

or double-click in Explorer.

> The script does not require administrator rights, but you need appropriate permissions to write to the current folder.

---

## Support Ukraine!

Your help is important for the defense and recovery of Ukraine. Support trusted funds:

- **United24 (official platform)** — the main state platform for raising funds to support Ukraine. Funds are directed to defense, humanitarian aid, medicine, and country recovery.  
  Website: https://u24.gov.ua  
  Bank details: https://u24.gov.ua/donate

- **Come Back Alive Foundation** — one of the largest and most transparent military aid funds. Provides the Armed Forces with modern equipment, training, and support for soldiers and their families.  
  Website: https://savelife.in.ua/donate/  
  Bank details: https://savelife.in.ua/donate/#donate-army-card

- **Serhiy Prytula Foundation** — a public fund that purchases equipment, drones, vehicles, medical equipment for the Armed Forces, and provides humanitarian aid.  
  Website: https://prytulafoundation.org/  
  Bank details: https://prytulafoundation.org/help/donate

- **Sternenko Community Foundation** — a volunteer fund raising money for the Armed Forces, drones, gear, aid for the wounded, and humanitarian initiatives.  
  Website: https://www.sternenkofund.org  
  🏦 Permanent Monobank jar: https://send.monobank.ua/jar/2JbpBYkhMv  
  💳 Monobase: https://base.monobank.ua/rusoriz  
  💸 PayPal: sternenkopaypal@gmail.com  
  🏦 Privat envelope: https://www.privat24.ua/send/gbwmp  
  💸 More details (including for legal entities): https://www.sternenkofund.org/donate

---