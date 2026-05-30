@echo off
chcp 65001 >nul
title Monitor PRO de Puertos
color 0A
mode con: cols=120 lines=40
setlocal enabledelayedexpansion

:MENU
cls

echo ==============================================================================================
echo                                   MONITOR DE PUERTOS
echo ==============================================================================================
echo.
echo PUERTO                          PID        PROCESO
echo ----------------------------------------------------------------------------------------------

for /f "tokens=1,2,3,4,5" %%A in ('netstat -ano ^| findstr LISTENING') do (
    
    set "PORT=%%B"
    set "PID=%%E"
    set "PROC=Desconocido"

    for /f "tokens=1" %%P in ('tasklist /FI "PID eq %%E" /NH') do (
        set "PROC=%%P"
    )

    call :PRINT
)

echo.
echo ==============================================================================================
echo [R] Refrescar   [K] Matar proceso   [Q] Salir
echo ==============================================================================================

choice /C RKQ /N /M "Opcion: "

if errorlevel 3 exit
if errorlevel 2 goto KILL
if errorlevel 1 goto MENU

goto MENU

:PRINT

set "COLOR=07"

echo !PROC! | find /I "node" >nul && set "COLOR=0A"
echo !PROC! | find /I "java" >nul && set "COLOR=0E"
echo !PROC! | find /I "docker" >nul && set "COLOR=0B"
echo !PROC! | find /I "postgres" >nul && set "COLOR=0D"
echo !PROC! | find /I "mysql" >nul && set "COLOR=09"

color !COLOR!

echo !PORT!                          !PID!        !PROC!

color 0A

exit /b

:KILL
cls
echo ==========================================
echo            MATAR PROCESO
echo ==========================================
echo.

set /p PIDKILL=Ingresa el PID: 

taskkill /F /PID %PIDKILL%

echo.
pause
goto MENU