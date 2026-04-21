@echo off
title Desinstalador - Sincronizador Inventario WooCommerce
cd /d "%~dp0"

echo.
echo ============================================================
echo   DESINSTALADOR - Sincronizador Inventario WooCommerce
echo ============================================================
echo.

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Ejecutar como ADMINISTRADOR: clic derecho - Ejecutar como administrador
    pause
    exit /b 1
)
echo [OK] Ejecutando como administrador

set TASK_NAME=SyncInventarioWooCommerce

echo.
echo [..] Eliminando tareas programadas...
schtasks /delete /tn "%TASK_NAME%_7AM" /f
schtasks /delete /tn "%TASK_NAME%_1PM" /f
schtasks /delete /tn "%TASK_NAME%_7PM" /f

echo.
echo ============================================================
echo   DESINSTALACION COMPLETADA
echo ============================================================
echo.
echo   Las tareas programadas han sido eliminadas.
echo   El sincronizador ya no se ejecutara automaticamente.
echo.
echo   NOTA: Los archivos del proyecto NO fueron eliminados.
echo   Si deseas eliminarlos, borra manualmente esta carpeta.
echo.
pause
