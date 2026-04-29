@echo off
title Instalador - Sincronizador Inventario WooCommerce
cd /d "%~dp0"

echo.
echo ============================================================
echo   INSTALADOR - Sincronizador Inventario WooCommerce
echo   Se ejecutara automaticamente cada 2 horas:
echo   - Lunes a Viernes
echo   - 9:30 AM, 11:30 AM, 1:30 PM, 3:30 PM, 5:30 PM
echo ============================================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Ejecutar como ADMINISTRADOR: clic derecho - Ejecutar como administrador
    pause
    exit /b 1
)
echo [OK] Ejecutando como administrador

set PYTHON=
echo [..] Buscando Python...
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command ^
    "$paths = @(); " ^
    "'HKLM','HKCU' | ForEach-Object { " ^
    "  $base = $_+':SOFTWARE\Python\PythonCore'; " ^
    "  if (Test-Path $base) { " ^
    "    Get-ChildItem $base | ForEach-Object { " ^
    "      $ip = $_.PSPath+'\InstallPath'; " ^
    "      if (Test-Path $ip) { " ^
    "        $v = (Get-ItemProperty $ip -ErrorAction SilentlyContinue).'(default)'; " ^
    "        if ($v -and (Test-Path ($v+'python.exe'))) { $paths += $v+'python.exe' } " ^
    "        $ep = (Get-ItemProperty $ip -ErrorAction SilentlyContinue).ExecutablePath; " ^
    "        if ($ep -and (Test-Path $ep)) { $paths += $ep } " ^
    "      } " ^
    "    } " ^
    "  } " ^
    "}; " ^
    "$paths | Select-Object -First 1"`) do (
    if exist "%%P" ( set PYTHON=%%P & goto :python_found )
)

for %%V in (314 313 312 311 310 39 38) do (
    if exist "%LOCALAPPDATA%\Programs\Python\Python%%V\python.exe" (
        set "PYTHON=%LOCALAPPDATA%\Programs\Python\Python%%V\python.exe" & goto :python_found
    )
    if exist "C:\Python%%V\python.exe" (
        set "PYTHON=C:\Python%%V\python.exe" & goto :python_found
    )
    if exist "C:\Program Files\Python%%V\python.exe" (
        set "PYTHON=C:\Program Files\Python%%V\python.exe" & goto :python_found
    )
    if exist "C:\Program Files (x86)\Python%%V\python.exe" (
        set "PYTHON=C:\Program Files (x86)\Python%%V\python.exe" & goto :python_found
    )
    if exist "D:\Python%%V\python.exe" (
        set "PYTHON=D:\Python%%V\python.exe" & goto :python_found
    )
)
if exist "D:\Python\python.exe" ( set "PYTHON=D:\Python\python.exe" & goto :python_found )

echo [..] Buscando python.exe en disco...
for /f "usebackq delims=" %%P in (`powershell -NoProfile -Command ^
    "Get-ChildItem 'C:\' -Recurse -Filter 'python.exe' -ErrorAction SilentlyContinue ^| " ^
    "Where-Object { $_.FullName -notmatch 'WindowsApps|store' } ^| " ^
    "Select-Object -First 1 -ExpandProperty FullName"`) do (
    if exist "%%P" ( set PYTHON=%%P & goto :python_found )
)

echo [ERROR] Python no encontrado. Instala desde https://python.org
pause
exit /b 1

:python_found
echo [OK] Python: %PYTHON%

echo.
echo [..] Creando entorno virtual...
if not exist "venv" (
    %PYTHON% -m venv venv
    if %errorlevel% neq 0 ( echo [ERROR] No se pudo crear venv. & pause & exit /b 1 )
)
echo [OK] Entorno virtual listo

echo [..] Instalando dependencias...
venv\Scripts\pip.exe install -r requirements.txt --quiet
if %errorlevel% neq 0 ( echo [ERROR] Fallo instalacion de dependencias. & pause & exit /b 1 )
echo [OK] Dependencias instaladas

set TASK_NAME=SyncInventarioWooCommerce
set APP_DIR=%~dp0
if "%APP_DIR:~-1%"=="\" set APP_DIR=%APP_DIR:~0,-1%
set PYTHON_EXE=%APP_DIR%\venv\Scripts\python.exe
set APP_SCRIPT=%APP_DIR%\sync_inventory.py

echo.
echo [..] Eliminando tareas programadas anteriores (si existen)...
schtasks /delete /tn "%TASK_NAME%_930AM" /f >nul 2>&1
schtasks /delete /tn "%TASK_NAME%_1130AM" /f >nul 2>&1
schtasks /delete /tn "%TASK_NAME%_130PM" /f >nul 2>&1
schtasks /delete /tn "%TASK_NAME%_330PM" /f >nul 2>&1
schtasks /delete /tn "%TASK_NAME%_530PM" /f >nul 2>&1
schtasks /delete /tn "%TASK_NAME%_7AM" /f >nul 2>&1
schtasks /delete /tn "%TASK_NAME%_1PM" /f >nul 2>&1
schtasks /delete /tn "%TASK_NAME%_7PM" /f >nul 2>&1
echo [OK] Tareas anteriores eliminadas

echo.
echo [..] Creando tarea programada: 9:30 AM (Lun-Vie)...
schtasks /create /tn "%TASK_NAME%_930AM" /tr "\"%PYTHON_EXE%\" \"%APP_SCRIPT%\"" /sc weekly /d MON,TUE,WED,THU,FRI /st 09:30 /rl highest /f
if %errorlevel% neq 0 ( echo [ERROR] No se pudo crear tarea 9:30 AM. & pause & exit /b 1 )
echo [OK] Tarea 9:30 AM creada

echo [..] Creando tarea programada: 11:30 AM (Lun-Vie)...
schtasks /create /tn "%TASK_NAME%_1130AM" /tr "\"%PYTHON_EXE%\" \"%APP_SCRIPT%\"" /sc weekly /d MON,TUE,WED,THU,FRI /st 11:30 /rl highest /f
if %errorlevel% neq 0 ( echo [ERROR] No se pudo crear tarea 11:30 AM. & pause & exit /b 1 )
echo [OK] Tarea 11:30 AM creada

echo [..] Creando tarea programada: 1:30 PM (Lun-Vie)...
schtasks /create /tn "%TASK_NAME%_130PM" /tr "\"%PYTHON_EXE%\" \"%APP_SCRIPT%\"" /sc weekly /d MON,TUE,WED,THU,FRI /st 13:30 /rl highest /f
if %errorlevel% neq 0 ( echo [ERROR] No se pudo crear tarea 1:30 PM. & pause & exit /b 1 )
echo [OK] Tarea 1:30 PM creada

echo [..] Creando tarea programada: 3:30 PM (Lun-Vie)...
schtasks /create /tn "%TASK_NAME%_330PM" /tr "\"%PYTHON_EXE%\" \"%APP_SCRIPT%\"" /sc weekly /d MON,TUE,WED,THU,FRI /st 15:30 /rl highest /f
if %errorlevel% neq 0 ( echo [ERROR] No se pudo crear tarea 3:30 PM. & pause & exit /b 1 )
echo [OK] Tarea 3:30 PM creada

echo [..] Creando tarea programada: 5:30 PM (Lun-Vie)...
schtasks /create /tn "%TASK_NAME%_530PM" /tr "\"%PYTHON_EXE%\" \"%APP_SCRIPT%\"" /sc weekly /d MON,TUE,WED,THU,FRI /st 17:30 /rl highest /f
if %errorlevel% neq 0 ( echo [ERROR] No se pudo crear tarea 5:30 PM. & pause & exit /b 1 )
echo [OK] Tarea 5:30 PM creada

echo.
echo.
echo ============================================================
echo   INSTALACION COMPLETADA
echo ============================================================
echo.
echo   El sincronizador se ejecutara automaticamente:
echo     - Lunes a Viernes (NO sabados ni domingos)
echo     - 9:30 AM, 11:30 AM, 1:30 PM, 3:30 PM, 5:30 PM
echo     - Total: 5 veces al dia cada 2 horas
echo.
echo   Logs de sincronizacion: %APP_DIR%\sync_inventory.log
echo.
echo   Para ejecutar manualmente ahora:
echo     %PYTHON_EXE% %APP_SCRIPT%
echo.
echo   Gestionar tareas programadas:
echo     - Abrir: taskschd.msc
echo     - Buscar: SyncInventarioWooCommerce
echo.
echo   Comandos utiles:
echo     Ver tareas:
echo       schtasks /query /tn "%TASK_NAME%_930AM"
echo       schtasks /query /tn "%TASK_NAME%_1130AM"
echo       schtasks /query /tn "%TASK_NAME%_130PM"
echo       schtasks /query /tn "%TASK_NAME%_330PM"
echo       schtasks /query /tn "%TASK_NAME%_530PM"
echo.
echo     Ejecutar ahora (prueba):
echo       schtasks /run /tn "%TASK_NAME%_930AM"
echo.
echo     Eliminar tareas:
echo       schtasks /delete /tn "%TASK_NAME%_930AM" /f
echo       schtasks /delete /tn "%TASK_NAME%_1130AM" /f
echo       schtasks /delete /tn "%TASK_NAME%_130PM" /f
echo       schtasks /delete /tn "%TASK_NAME%_330PM" /f
echo       schtasks /delete /tn "%TASK_NAME%_530PM" /f
echo.
pause
