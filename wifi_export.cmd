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