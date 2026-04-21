@echo off
REM Script para configurar tarea programada en Windows

set SCRIPT_DIR=%~dp0
set PYTHON_PATH=python

REM Crear tarea programada (ejecutar diariamente a las 7 PM)
schtasks /create /tn "SyncInventarioWordPress" /tr "%PYTHON_PATH% %SCRIPT_DIR%sync_inventory.py" /sc daily /st 19:00 /f

echo.
echo Tarea programada configurada exitosamente
echo El script se ejecutara diariamente a las 7:00 PM
echo.
echo Para verificar: schtasks /query /tn "SyncInventarioWordPress"
echo Para ejecutar manualmente: schtasks /run /tn "SyncInventarioWordPress"
echo Para eliminar: schtasks /delete /tn "SyncInventarioWordPress" /f
pause
