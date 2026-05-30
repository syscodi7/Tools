Clear-Host

Write-Host "===================================="
Write-Host "        SYSCODI TOOLS v1.0"
Write-Host "===================================="
Write-Host ""

Write-Host "1. Info del sistema"
Write-Host "2. Limpiar DNS"
Write-Host "3. Ver procesos"
Write-Host "4. Salir"
Write-Host ""

$opcion = Read-Host "Selecciona una opcion"

switch ($opcion) {

    "1" {
        systeminfo
        Pause
    }

    "2" {
        ipconfig /flushdns
        Write-Host "DNS limpiado"
        Pause
    }

    "3" {
        tasklist | more
        Pause
    }

    "4" {
        exit
    }

    default {
        Write-Host "Opcion invalida"
        Pause
    }
}
