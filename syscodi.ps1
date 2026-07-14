# ============================================================
#   Syscodi7 System Toolkit v1.1
#   Herramienta de administración avanzada para Windows
#   Requiere: PowerShell 5.1+ | Ejecutar como Administrador
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName Microsoft.VisualBasic

# ============================================================
#   PALETA DE COLORES
# ============================================================
$C = @{
    Bg        = [Drawing.Color]::FromArgb(12, 16, 28)
    Surface   = [Drawing.Color]::FromArgb(18, 24, 42)
    Card      = [Drawing.Color]::FromArgb(26, 34, 58)
    Accent    = [Drawing.Color]::FromArgb(0, 190, 220)
    Accent2   = [Drawing.Color]::FromArgb(100, 220, 255)
    Text      = [Drawing.Color]::FromArgb(230, 235, 245)
    SubText   = [Drawing.Color]::FromArgb(130, 155, 190)
    Btn       = [Drawing.Color]::FromArgb(0, 140, 170)
    BtnHover  = [Drawing.Color]::FromArgb(0, 170, 200)
    Output    = [Drawing.Color]::FromArgb(8, 12, 22)
    Border    = [Drawing.Color]::FromArgb(0, 160, 190)
    Green     = [Drawing.Color]::FromArgb(30, 200, 120)
    Red       = [Drawing.Color]::FromArgb(230, 70, 70)
    Yellow    = [Drawing.Color]::FromArgb(255, 210, 60)
    Orange    = [Drawing.Color]::FromArgb(255, 160, 40)
    Purple    = [Drawing.Color]::FromArgb(160, 100, 255)
}

# ============================================================
#   LOG AUTOMATICO
# ============================================================
$script:LogPath = "$env:TEMP\Syscodi7_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:LogLines = [System.Collections.ArrayList]::new()

# ============================================================
#   FUNCIONES HELPER
# ============================================================
function Log($msg, $level = "INFO") {
    $ts = Get-Date -Format "HH:mm:ss"
    $line = "[$ts] [$level] $msg"
    [void]$script:LogLines.Add($line)
    if ($script:outputBox) {
        $outputBox.SelectionStart = $outputBox.TextLength
        switch ($level) {
            "OK"    { $outputBox.SelectionColor = $C.Green }
            "WARN"  { $outputBox.SelectionColor = $C.Yellow }
            "ERR"   { $outputBox.SelectionColor = $C.Red }
            "TITLE" { $outputBox.SelectionColor = $C.Accent2 }
            default { $outputBox.SelectionColor = $C.SubText }
        }
        $outputBox.AppendText("`r`n$line")
        $outputBox.ScrollToCaret()
    }
}

function Confirm-Action($msg) {
    $r = [Windows.Forms.MessageBox]::Show($msg, "Syscodi7 - Confirmar",
        [Windows.Forms.MessageBoxButtons]::YesNo,
        [Windows.Forms.MessageBoxIcon]::Warning)
    return ($r -eq [Windows.Forms.DialogResult]::Yes)
}

function Make-Button($text, $x, $y, $w = 190, $h = 34, $bgColor = $null) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object Drawing.Point($x, $y)
    $b.Size = New-Object Drawing.Size($w, $h)
    $b.BackColor = $(if ($bgColor) { $bgColor } else { $C.Btn })
    $b.ForeColor = $C.Text
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $C.Border
    $b.FlatAppearance.BorderSize = 1
    $b.Font = New-Object Drawing.Font("Segoe UI", 8.5)
    $b.Cursor = "Hand"
    $b.Add_MouseEnter({ $this.BackColor = $C.BtnHover })
    $b.Add_MouseLeave({ $this.BackColor = $C.Btn })
    return $b
}

function Make-Section($text, $x, $y, $parent) {
    $l = New-Object Windows.Forms.Label
    $l.Text = $text
    $l.Location = New-Object Drawing.Point($x, $y)
    $l.Size = New-Object Drawing.Size(680, 22)
    $l.ForeColor = $C.Accent
    $l.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
    $parent.Controls.Add($l)
}

function Make-Tab($title) {
    $t = New-Object Windows.Forms.TabPage
    $t.Text = " $title "
    $t.BackColor = $C.Bg
    $t.ForeColor = $C.Text
    $t.AutoScroll = $true
    $tabs.TabPages.Add($t)
    return $t
}

function Make-Card($title, $subtitle, $parent, $y, $h = 110) {
    $p = New-Object Windows.Forms.Panel
    $p.Location = New-Object Drawing.Point(6, $y)
    $p.Size = New-Object Drawing.Size(690, $h)
    $p.BackColor = $C.Card
    $parent.Controls.Add($p)
    $lt = New-Object Windows.Forms.Label
    $lt.Text = $title
    $lt.Location = New-Object Drawing.Point(10, 8)
    $lt.Size = New-Object Drawing.Size(670, 20)
    $lt.ForeColor = $C.Accent2
    $lt.Font = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
    $p.Controls.Add($lt)
    if ($subtitle) {
        $ls = New-Object Windows.Forms.Label
        $ls.Text = $subtitle
        $ls.Location = New-Object Drawing.Point(10, 30)
        $ls.Size = New-Object Drawing.Size(670, 16)
        $ls.ForeColor = $C.SubText
        $ls.Font = New-Object Drawing.Font("Segoe UI", 7.5)
        $p.Controls.Add($ls)
    }
    return $p
}

function Run-Safe($cmd, $desc) {
    Log "Ejecutando: $desc" "INFO"
    try {
        $res = Invoke-Expression $cmd 2>&1
        if ($res) { Log ($res -join "`n") "INFO" }
        Log "Completado: $desc" "OK"
    } catch {
        Log "Error en ${desc}: $_" "ERR"
    }
}

# ============================================================
#   FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text = "Syscodi7 System Toolkit v1.1"
$form.Size = New-Object Drawing.Size(1150, 680)
$form.StartPosition = "CenterScreen"
$form.BackColor = $C.Bg
$form.ForeColor = $C.Text
$form.Font = New-Object Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox = $false

# ============================================================
#   HEADER
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Size = New-Object Drawing.Size(1150, 52)
$header.Location = New-Object Drawing.Point(0, 0)
$header.BackColor = $C.Surface
$form.Controls.Add($header)

$lblT = New-Object Windows.Forms.Label
$lblT.Text = "Syscodi7"
$lblT.Font = New-Object Drawing.Font("Segoe UI", 16, [Drawing.FontStyle]::Bold)
$lblT.ForeColor = $C.Accent
$lblT.Location = New-Object Drawing.Point(15, 8)
$lblT.Size = New-Object Drawing.Size(180, 30)
$header.Controls.Add($lblT)

$lblT2 = New-Object Windows.Forms.Label
$lblT2.Text = "System Toolkit"
$lblT2.Font = New-Object Drawing.Font("Segoe UI", 10)
$lblT2.ForeColor = $C.SubText
$lblT2.Location = New-Object Drawing.Point(195, 14)
$lblT2.Size = New-Object Drawing.Size(200, 22)
$header.Controls.Add($lblT2)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

$lblAdm = New-Object Windows.Forms.Label
$lblAdm.Text = $(if ($isAdmin) { "[ ADMIN ]" } else { "[ SIN ADMIN ]" })
$lblAdm.ForeColor = $(if ($isAdmin) { $C.Green } else { $C.Red })
$lblAdm.Font = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
$lblAdm.Location = New-Object Drawing.Point(1010, 16)
$lblAdm.Size = New-Object Drawing.Size(120, 20)
$header.Controls.Add($lblAdm)

# ============================================================
#   TAB CONTROL (5 PESTANAS)
# ============================================================
$tabs = New-Object Windows.Forms.TabControl
$tabs.Location = New-Object Drawing.Point(4, 56)
$tabs.Size = New-Object Drawing.Size(710, 560)
$tabs.BackColor = $C.Bg
$tabs.Appearance = "FlatButtons"
$tabs.Font = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
$form.Controls.Add($tabs)

$tabClean   = Make-Tab "Limpieza"
$tabRepair  = Make-Tab "Reparacion"
$tabSec     = Make-Tab "Seguridad"
$tabSys     = Make-Tab "Sistema"
$tabYT      = Make-Tab "YouTube"

# ============================================================
#   PANEL DERECHO - CONSOLA
# ============================================================
$rightP = New-Object Windows.Forms.Panel
$rightP.Location = New-Object Drawing.Point(718, 56)
$rightP.Size = New-Object Drawing.Size(420, 560)
$rightP.BackColor = $C.Surface
$form.Controls.Add($rightP)

$lblCons = New-Object Windows.Forms.Label
$lblCons.Text = "  CONSOLA"
$lblCons.Location = New-Object Drawing.Point(0, 0)
$lblCons.Size = New-Object Drawing.Size(280, 26)
$lblCons.ForeColor = $C.Accent2
$lblCons.BackColor = $C.Card
$lblCons.Font = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
$lblCons.TextAlign = "MiddleLeft"
$rightP.Controls.Add($lblCons)

$btnSaveLog = Make-Button "Guardar" 280 3 65 20 $C.Card
$btnSaveLog.Font = New-Object Drawing.Font("Segoe UI", 7)
$btnSaveLog.Add_Click({
    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter = "Log (*.log)|*.log|Texto (*.txt)|*.txt"
    $dlg.FileName = "Syscodi7_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    if ($dlg.ShowDialog() -eq "OK") {
        $outputBox.Text | Set-Content $dlg.FileName -Encoding UTF8
        Log "Log guardado: $($dlg.FileName)" "OK"
    }
})
$rightP.Controls.Add($btnSaveLog)

$btnClear = Make-Button "Limpiar" 348 3 65 20 $C.Card
$btnClear.Font = New-Object Drawing.Font("Segoe UI", 7)
$btnClear.Add_Click({ $outputBox.Clear(); Log "Consola limpiada." "INFO" })
$rightP.Controls.Add($btnClear)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location = New-Object Drawing.Point(0, 28)
$outputBox.Size = New-Object Drawing.Size(420, 532)
$outputBox.BackColor = $C.Output
$outputBox.ForeColor = $C.Accent2
$outputBox.Font = New-Object Drawing.Font("Consolas", 8.5)
$outputBox.ReadOnly = $true
$outputBox.BorderStyle = "None"
$outputBox.Text = "  Syscodi7 System Toolkit v1.1`n  Listo. Selecciona una opcion."
$rightP.Controls.Add($outputBox)

# Guardar log automatico al cerrar
$form.Add_FormClosing({
    try { $script:LogLines | Set-Content $script:LogPath -Encoding UTF8 -EA SilentlyContinue } catch {}
})

# ============================================================
#   TAB 1: LIMPIEZA
# ============================================================
Make-Section "Archivos temporales" 10 8 $tabClean

$btnTemp = Make-Button "Limpiar TEMP" 10 32 190 34
$btnTemp.Add_Click({
    if (-not (Confirm-Action "Eliminar archivos temporales de usuario y sistema?")) { return }
    $count = 0
    Get-ChildItem "$env:TEMP" -Recurse -EA SilentlyContinue | ForEach-Object {
        try { Remove-Item $_.FullName -Recurse -Force -EA Stop; $count++ } catch {}
    }
    Get-ChildItem "C:\Windows\Temp" -Recurse -EA SilentlyContinue | ForEach-Object {
        try { Remove-Item $_.FullName -Recurse -Force -EA Stop; $count++ } catch {}
    }
    Log "Eliminados $count elementos temporales." "OK"
})
$tabClean.Controls.Add($btnTemp)

$btnPrefetch = Make-Button "Limpiar Prefetch" 210 32 190 34
$btnPrefetch.Add_Click({
    if (-not (Confirm-Action "Limpiar carpeta Prefetch?")) { return }
    Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue
    Log "Prefetch limpiado." "OK"
})
$tabClean.Controls.Add($btnPrefetch)

$btnWU = Make-Button "Limpiar Cache Windows Update" 410 32 260 34
$btnWU.Add_Click({
    if (-not (Confirm-Action "Limpiar cache de Windows Update? Se detendra y reiniciara el servicio.")) { return }
    Stop-Service wuauserv -Force -EA SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -EA SilentlyContinue
    Start-Service wuauserv -EA SilentlyContinue
    Log "Cache de Windows Update limpiada." "OK"
})
$tabClean.Controls.Add($btnWU)

Make-Section "Navegadores" 10 80 $tabClean

$btnChromeCache = Make-Button "Limpiar Cache Chrome" 10 104 190 34
$btnChromeCache.Add_Click({
    $p = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    if (Test-Path $p) { Remove-Item "$p\*" -Recurse -Force -EA SilentlyContinue; Log "Cache de Chrome limpiado." "OK" }
    else { Log "No se encontro cache de Chrome." "WARN" }
})
$tabClean.Controls.Add($btnChromeCache)

$btnEdgeCache = Make-Button "Limpiar Cache Edge" 210 104 190 34
$btnEdgeCache.Add_Click({
    $p = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    if (Test-Path $p) { Remove-Item "$p\*" -Recurse -Force -EA SilentlyContinue; Log "Cache de Edge limpiado." "OK" }
    else { Log "No se encontro cache de Edge." "WARN" }
})
$tabClean.Controls.Add($btnEdgeCache)

$btnFFCache = Make-Button "Limpiar Cache Firefox" 410 104 190 34
$btnFFCache.Add_Click({
    $prof = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $prof) {
        Get-ChildItem $prof -Directory | ForEach-Object {
            $cp = Join-Path $_.FullName "cache2"
            if (Test-Path $cp) { Remove-Item "$cp\*" -Recurse -Force -EA SilentlyContinue }
        }
        Log "Cache de Firefox limpiado." "OK"
    } else { Log "No se encontro cache de Firefox." "WARN" }
})
$tabClean.Controls.Add($btnFFCache)

Make-Section "Papelera y recientes" 10 152 $tabClean

$btnRecycle = Make-Button "Vaciar Papelera" 10 176 190 34
$btnRecycle.Add_Click({
    if (-not (Confirm-Action "Vaciar la Papelera de Reciclaje?")) { return }
    Clear-RecycleBin -Force -EA SilentlyContinue
    Log "Papelera vaciada." "OK"
})
$tabClean.Controls.Add($btnRecycle)

$btnRecent = Make-Button "Limpiar Archivos Recientes" 210 176 220 34
$btnRecent.Add_Click({
    Remove-Item "$env:APPDATA\Microsoft\Windows\Recent\*" -Force -EA SilentlyContinue
    Log "Lista de archivos recientes limpiada." "OK"
})
$tabClean.Controls.Add($btnRecent)

$btnAllClean = Make-Button "LIMPIEZA COMPLETA" 440 176 230 34 $C.Green
$btnAllClean.Add_Click({
    if (-not (Confirm-Action "Ejecutar limpieza completa? Se eliminaran temporales, prefetch, cache de navegadores, papelera y archivos recientes.")) { return }
    Log "=== LIMPIEZA COMPLETA ===" "TITLE"
    Get-ChildItem "$env:TEMP" -Recurse -EA SilentlyContinue | ForEach-Object { try { Remove-Item $_.FullName -Recurse -Force -EA Stop } catch {} }
    Get-ChildItem "C:\Windows\Temp" -Recurse -EA SilentlyContinue | ForEach-Object { try { Remove-Item $_.FullName -Recurse -Force -EA Stop } catch {} }
    Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue
    foreach ($bp in @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache","$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache")) {
        if (Test-Path $bp) { Remove-Item "$bp\*" -Recurse -Force -EA SilentlyContinue }
    }
    Clear-RecycleBin -Force -EA SilentlyContinue
    Log "Limpieza completa finalizada." "OK"
})
$tabClean.Controls.Add($btnAllClean)

# ============================================================
#   TAB 2: REPARACION
# ============================================================
Make-Section "Reparacion de Windows" 10 8 $tabRepair

$btnSFC = Make-Button "SFC /scannow" 10 32 190 34
$btnSFC.Add_Click({ Run-Safe "sfc /scannow" "SFC /scannow" })
$tabRepair.Controls.Add($btnSFC)

$btnDISM = Make-Button "DISM RestoreHealth" 210 32 190 34
$btnDISM.Add_Click({ Run-Safe "DISM /Online /Cleanup-Image /RestoreHealth" "DISM RestoreHealth" })
$tabRepair.Controls.Add($btnDISM)

$btnChkdsk = Make-Button "CheckDisk (C:)" 410 32 190 34
$btnChkdsk.Add_Click({
    if (-not (Confirm-Action "CheckDisk requiere reinicio. Continuar?")) { return }
    Run-Safe "chkdsk C: /f /r /x" "CheckDisk C:"
})
$tabRepair.Controls.Add($btnChkdsk)

Make-Section "Red" 10 80 $tabRepair

$btnDNS = Make-Button "DNS Flush" 10 104 190 34
$btnDNS.Add_Click({ Run-Safe "ipconfig /flushdns" "DNS Flush" })
$tabRepair.Controls.Add($btnDNS)

$btnNetReset = Make-Button "Reset Red (netsh)" 210 104 190 34
$btnNetReset.Add_Click({
    if (-not (Confirm-Action "Se reseteara la configuracion de red. Se requiere reinicio. Continuar?")) { return }
    Run-Safe "netsh int ip reset" "Reset IP"
    Run-Safe "netsh winsock reset" "Reset Winsock"
    Log "Reinicia el PC para aplicar cambios de red." "WARN"
})
$tabRepair.Controls.Add($btnNetReset)

$btnDiag = Make-Button "Diagnostico de Red" 410 104 190 34
$btnDiag.Add_Click({
    Log "--- Diagnostico de red ---" "TITLE"
    Run-Safe "ping 8.8.8.8 -n 3" "Ping"
    Run-Safe "Test-NetConnection google.com -Port 443" "Test-NetConnection"
})
$tabRepair.Controls.Add($btnDiag)

Make-Section "Servicios y Store" 10 152 $tabRepair

$btnStore = Make-Button "Reparar Microsoft Store" 10 176 190 34
$btnStore.Add_Click({
    Log "Reiniciando Microsoft Store..." "INFO"
    Start-Process wsreset.exe
    Log "Store reiniciada." "OK"
})
$tabRepair.Controls.Add($btnStore)

$btnRestorePt = Make-Button "Crear Punto de Restauracion" 210 176 220 34
$btnRestorePt.Add_Click({
    Log "Creando punto de restauracion..." "INFO"
    try {
        Checkpoint-Computer -Description "Syscodi7 Backup $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS
        Log "Punto de restauracion creado." "OK"
    } catch { Log "Error: $_" "ERR" }
})
$tabRepair.Controls.Add($btnRestorePt)

$btnRestoreSys = Make-Button "Abrir Restaurar Sistema" 440 176 220 34
$btnRestoreSys.Add_Click({ Start-Process rstrui.exe })
$tabRepair.Controls.Add($btnRestoreSys)

Make-Section "Diagnostico" 10 224 $tabRepair

$btnErrors = Make-Button "Errores del Sistema" 10 248 190 34
$btnErrors.Add_Click({
    Log "--- Ultimos 15 errores del sistema ---" "TITLE"
    try {
        Get-EventLog -LogName System -EntryType Error -Newest 15 | ForEach-Object {
            Log "$($_.TimeGenerated.ToString('dd/MM HH:mm')) - $($_.Source): $($_.Message.Substring(0,[Math]::Min(80,$_.Message.Length)))" "ERR"
        }
    } catch { Log "Error al leer log: $_" "ERR" }
})
$tabRepair.Controls.Add($btnErrors)

$btnServices = Make-Button "Servicios Automaticos" 210 248 190 34
$btnServices.Add_Click({
    Log "--- Servicios automaticos activos ---" "TITLE"
    Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Running' } |
        ForEach-Object { Log "$($_.Name) - $($_.DisplayName)" "INFO" }
})
$tabRepair.Controls.Add($btnServices)

$btnStartup = Make-Button "Programas al Inicio" 410 248 190 34
$btnStartup.Add_Click({
    Log "--- Programas al inicio ---" "TITLE"
    Get-CimInstance Win32_StartupCommand | ForEach-Object {
        Log "$($_.Name) - $($_.Command)" "INFO"
    }
})
$tabRepair.Controls.Add($btnStartup)

Make-Section "Activacion Windows / Office (MAS)" 10 296 $tabRepair

$btnActivarWin = Make-Button "Activar Windows" 10 320 190 34 $C.Purple
$btnActivarWin.Add_Click({
    if (-not (Confirm-Action "Se ejecutara: irm https://get.activated.win | iex`n`nEsto activa Windows usando Microsoft Activation Scripts (MAS).`n`nAVISO: Ejecutas codigo remoto bajo tu responsabilidad.`n`nContinuar?")) { return }
    Log "Lanzando script MAS para activar Windows..." "INFO"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.activated.win | iex`"" -Verb RunAs
    Log "Script MAS lanzado en ventana separada. Sigue las instrucciones." "OK"
})
$tabRepair.Controls.Add($btnActivarWin)

$btnActivarOffice = Make-Button "Activar Office" 210 320 190 34 $C.Purple
$btnActivarOffice.Add_Click({
    if (-not (Confirm-Action "Se ejecutara: irm https://get.activated.win | iex`n`nEsto activa Office usando Microsoft Activation Scripts (MAS).`n`nAVISO: Ejecutas codigo remoto bajo tu responsabilidad.`n`nContinuar?")) { return }
    Log "Lanzando script MAS para activar Office..." "INFO"
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.activated.win | iex`"" -Verb RunAs
    Log "Script MAS lanzado en ventana separada. Sigue las instrucciones." "OK"
})
$tabRepair.Controls.Add($btnActivarOffice)

$btnMASInfo = Make-Button "Info sobre MAS" 410 320 190 34 $C.Card
$btnMASInfo.Font = New-Object Drawing.Font("Segoe UI", 8)
$btnMASInfo.Add_Click({
    Log "--- Microsoft Activation Scripts (MAS) ---" "TITLE"
    Log "Proyecto open source: https://github.com/massgravel/Microsoft-Activation-Scripts" "INFO"
    Log "Comando: irm https://get.activated.win | iex" "INFO"
    Log "Soporta: Windows 7/8.1/10/11, Server 2008-2022, Office 2010-2024, Microsoft 365" "INFO"
    Log "Metodo: HWID (Windows), Ohook (Office), KMS38 (Windows alternativo)" "INFO"
    Log "Requiere conexion a internet y ejecucion como administrador." "WARN"
})
$tabRepair.Controls.Add($btnMASInfo)

# ============================================================
#   TAB 3: SEGURIDAD
# ============================================================
Make-Section "Windows Defender" 10 8 $tabSec

$btnDefender = Make-Button "Estado de Defender" 10 32 190 34
$btnDefender.Add_Click({
    Log "--- Windows Defender ---" "TITLE"
    try {
        $s = Get-MpComputerStatus
        Log "Antivirus activo     : $($s.AntivirusEnabled)" $(if($s.AntivirusEnabled){'OK'}else{'ERR'})
        Log "Proteccion tiempo real: $($s.RealTimeProtectionEnabled)" $(if($s.RealTimeProtectionEnabled){'OK'}else{'ERR'})
        Log "Ultima actualizacion  : $($s.AntivirusSignatureLastUpdated)" "INFO"
        Log "Version definiciones  : $($s.AntivirusSignatureVersion)" "INFO"
    } catch { Log "Error al leer Defender: $_" "ERR" }
})
$tabSec.Controls.Add($btnDefender)

$btnQuickScan = Make-Button "Quick Scan" 210 32 190 34
$btnQuickScan.Add_Click({
    Log "Iniciando Quick Scan..." "INFO"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"Start-MpScan -ScanType QuickScan`"" -Verb RunAs
    Log "Scan iniciado en segundo plano." "OK"
})
$tabSec.Controls.Add($btnQuickScan)

$btnFullScan = Make-Button "Full Scan" 410 32 190 34 $C.Orange
$btnFullScan.Add_Click({
    if (-not (Confirm-Action "Iniciar analisis completo? Puede tardar bastante.")) { return }
    Log "Iniciando Full Scan..." "INFO"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"Start-MpScan -ScanType FullScan`"" -Verb RunAs
    Log "Full Scan iniciado." "OK"
})
$tabSec.Controls.Add($btnFullScan)

Make-Section "Firewall" 10 80 $tabSec

$btnFWStatus = Make-Button "Estado del Firewall" 10 104 190 34
$btnFWStatus.Add_Click({
    Log "--- Estado del Firewall ---" "TITLE"
    try {
        Get-NetFirewallProfile | ForEach-Object {
            $col = if ($_.Enabled) { "OK" } else { "ERR" }
            Log "$($_.Name): $(if($_.Enabled){'ACTIVO'}else{'INACTIVO'})" $col
        }
    } catch { Run-Safe "netsh advfirewall show allprofiles state" "Firewall status" }
})
$tabSec.Controls.Add($btnFWStatus)

$btnFWOn = Make-Button "Activar Firewall" 210 104 190 34 $C.Green
$btnFWOn.Add_Click({
    Run-Safe "netsh advfirewall set allprofiles state on" "Activar Firewall"
    Log "Firewall activado en todos los perfiles." "OK"
})
$tabSec.Controls.Add($btnFWOn)

$btnFWOff = Make-Button "Desactivar Firewall" 410 104 190 34 $C.Red
$btnFWOff.Add_Click({
    if (-not (Confirm-Action "ADVERTENCIA: Desactivar el Firewall expone tu equipo. Continuar?")) { return }
    Run-Safe "netsh advfirewall set allprofiles state off" "Desactivar Firewall"
    Log "Firewall desactivado." "WARN"
})
$tabSec.Controls.Add($btnFWOff)

Make-Section "Usuarios y dispositivos" 10 152 $tabSec

$btnUsers = Make-Button "Listar Usuarios" 10 176 190 34
$btnUsers.Add_Click({
    Log "--- Usuarios locales ---" "TITLE"
    Get-LocalUser | ForEach-Object {
        $col = if ($_.Enabled) { "OK" } else { "WARN" }
        Log "$($_.Name) - $(if($_.Enabled){'Activo'}else{'Desactivado'}) - Ultimo acceso: $($_.LastLogon)" $col
    }
})
$tabSec.Controls.Add($btnUsers)

$btnBadDev = Make-Button "Dispositivos con Error" 210 176 190 34
$btnBadDev.Add_Click({
    Log "--- Dispositivos con problema ---" "TITLE"
    $devs = Get-PnpDevice -Status Error,Unknown -EA SilentlyContinue
    if ($devs) { $devs | ForEach-Object { Log "$($_.Class): $($_.FriendlyName) - $($_.Status)" "ERR" } }
    else { Log "Sin dispositivos con error." "OK" }
})
$tabSec.Controls.Add($btnBadDev)

$btnDevMgr = Make-Button "Administrador Dispositivos" 410 176 260 34
$btnDevMgr.Add_Click({ Start-Process devmgmt.msc })
$tabSec.Controls.Add($btnDevMgr)

Make-Section "Certificados y politicas" 10 224 $tabSec

$btnCerts = Make-Button "Certificados por Vencer" 10 248 200 34
$btnCerts.Add_Click({
    Log "--- Certificados proximos a vencer ---" "TITLE"
    $hoy = Get-Date
    Get-ChildItem Cert:\LocalMachine\My -EA SilentlyContinue | Where-Object { $_.NotAfter -lt $hoy.AddDays(30) } | ForEach-Object {
        $col = if ($_.NotAfter -lt $hoy) { "ERR" } else { "WARN" }
        Log "$($_.Subject) - Vence: $($_.NotAfter.ToString('dd/MM/yyyy'))" $col
    }
    Log "Revision completada." "OK"
})
$tabSec.Controls.Add($btnCerts)

$btnPolicies = Make-Button "Politicas de Seguridad" 220 248 200 34
$btnPolicies.Add_Click({ Start-Process secpol.msc })
$tabSec.Controls.Add($btnPolicies)

$btnUAC = Make-Button "Configurar UAC" 430 248 170 34
$btnUAC.Add_Click({ Start-Process UserAccountControlSettings.exe })
$tabSec.Controls.Add($btnUAC)

# ============================================================
#   TAB 4: SISTEMA
# ============================================================
$infoBox = New-Object Windows.Forms.RichTextBox
$infoBox.Location = New-Object Drawing.Point(5, 5)
$infoBox.Size = New-Object Drawing.Size(690, 280)
$infoBox.BackColor = $C.Output
$infoBox.ForeColor = $C.Accent2
$infoBox.Font = New-Object Drawing.Font("Consolas", 9)
$infoBox.ReadOnly = $true
$infoBox.BorderStyle = "None"
$tabSys.Controls.Add($infoBox)

$lblMonitor = New-Object Windows.Forms.Label
$lblMonitor.Location = New-Object Drawing.Point(5, 290)
$lblMonitor.Size = New-Object Drawing.Size(690, 22)
$lblMonitor.ForeColor = $C.Green
$lblMonitor.Font = New-Object Drawing.Font("Consolas", 9)
$lblMonitor.Text = "  CPU: --%  |  RAM: -- GB libres  |  Disco C: -- GB libres"
$tabSys.Controls.Add($lblMonitor)

$timerMon = New-Object Windows.Forms.Timer
$timerMon.Interval = 5000
$timerMon.Add_Tick({
    try {
        $os = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        $cpu = (Get-CimInstance Win32_Processor -EA SilentlyContinue).LoadPercentage
        $ramFree = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $disk = Get-PSDrive C -EA SilentlyContinue
        $diskFree = [math]::Round($disk.Free / 1GB, 1)
        $lblMonitor.Text = "  CPU: $cpu%  |  RAM libre: $ramFree GB  |  Disco C libre: $diskFree GB"
        $lblMonitor.ForeColor = $(if ($cpu -gt 80) { $C.Red } elseif ($cpu -gt 50) { $C.Yellow } else { $C.Green })
    } catch {}
})

$btnInfo = Make-Button "Cargar Info del Sistema" 5 320 200 34
$btnInfo.Add_Click({
    $infoBox.Clear()
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $mem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $free = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $disk = Get-PSDrive C
    $infoBox.ForeColor = $C.Accent2
    $infoBox.AppendText("Sistema Operativo  : $($os.Caption)`r`n")
    $infoBox.AppendText("Version            : $($os.Version)`r`n")
    $infoBox.AppendText("Arquitectura       : $($os.OSArchitecture)`r`n")
    $infoBox.AppendText("Procesador         : $($cpu.Name)`r`n")
    $infoBox.AppendText("Nucleos            : $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors) logico`r`n")
    $infoBox.AppendText("RAM Total          : $mem GB`r`n")
    $infoBox.AppendText("RAM Libre          : $free GB`r`n")
    $infoBox.AppendText("Disco C: Libre     : $([math]::Round($disk.Free/1GB,2)) GB de $([math]::Round(($disk.Used+$disk.Free)/1GB,2)) GB`r`n")
    $infoBox.AppendText("Equipo             : $env:COMPUTERNAME`r`n")
    $infoBox.AppendText("Usuario            : $env:USERNAME`r`n")
    $infoBox.AppendText("Admin              : $isAdmin`r`n")
    $timerMon.Start()
    Log "Info del sistema cargada. Monitor activo (5s)." "OK"
})
$tabSys.Controls.Add($btnInfo)

$btnUptime = Make-Button "Ver Uptime" 215 320 150 34
$btnUptime.Add_Click({
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $up = (Get-Date) - $boot
    Log "Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m desde $($boot.ToString('dd/MM/yyyy HH:mm'))" "INFO"
})
$tabSys.Controls.Add($btnUptime)

$btnUpdates = Make-Button "Windows Update" 375 320 160 34
$btnUpdates.Add_Click({ Start-Process ms-settings:windowsupdate })
$tabSys.Controls.Add($btnUpdates)

$btnExpReport = Make-Button "Exportar Reporte" 545 320 150 34
$btnExpReport.Add_Click({
    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter = "Texto (*.txt)|*.txt"
    $dlg.FileName = "Syscodi7_Reporte_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if ($dlg.ShowDialog() -eq "OK") {
        $infoBox.Text | Set-Content $dlg.FileName -Encoding UTF8
        Log "Reporte guardado: $($dlg.FileName)" "OK"
    }
})
$tabSys.Controls.Add($btnExpReport)

Make-Section "Procesos" 10 365 $tabSys

$btnTopProc = Make-Button "Top 10 Procesos (CPU)" 10 389 200 34
$btnTopProc.Add_Click({
    Log "--- Top 10 procesos por CPU ---" "TITLE"
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 10 | ForEach-Object {
        Log "$($_.ProcessName.PadRight(25)) CPU: $([math]::Round($_.CPU,1).ToString().PadLeft(10))s  RAM: $([math]::Round($_.WorkingSet64/1MB,0).ToString().PadLeft(6)) MB" "INFO"
    }
})
$tabSys.Controls.Add($btnTopProc)

$btnTopMem = Make-Button "Top 10 Procesos (RAM)" 220 389 200 34
$btnTopMem.Add_Click({
    Log "--- Top 10 procesos por RAM ---" "TITLE"
    Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 10 | ForEach-Object {
        Log "$($_.ProcessName.PadRight(25)) RAM: $([math]::Round($_.WorkingSet64/1MB,0).ToString().PadLeft(6)) MB  CPU: $([math]::Round($_.CPU,1).ToString().PadLeft(10))s" "INFO"
    }
})
$tabSys.Controls.Add($btnTopMem)

$btnKillProc = Make-Button "Matar Proceso por Nombre" 430 389 240 34 $C.Red
$btnKillProc.Add_Click({
    $input = [Microsoft.VisualBasic.Interaction]::InputBox("Nombre del proceso (sin .exe):", "Syscodi7", "")
    if ($input) {
        $procs = Get-Process -Name $input -EA SilentlyContinue
        if ($procs) {
            if (Confirm-Action "Matar $($procs.Count) proceso(s) '$input'??") {
                $procs | Stop-Process -Force -EA SilentlyContinue
                Log "Proceso(s) '$input' terminados." "OK"
            }
        } else { Log "No se encontro proceso: $input" "WARN" }
    }
})
$tabSys.Controls.Add($btnKillProc)

# ============================================================
#   TAB 5: YOUTUBE DOWNLOADER
# ============================================================
Make-Section "Descargador de YouTube" 10 8 $tabYT

# Card: URL y Formato
$cardYT = Make-Card "Configuracion de Descarga" "Requiere yt-dlp y ffmpeg instalados" $tabYT 32 160

$lblURL = New-Object Windows.Forms.Label
$lblURL.Text = "URL del video:"
$lblURL.Location = New-Object Drawing.Point(10, 35)
$lblURL.Size = New-Object Drawing.Size(100, 20)
$lblURL.ForeColor = $C.Text
$lblURL.Font = New-Object Drawing.Font("Segoe UI", 8.5)
$cardYT.Controls.Add($lblURL)

$txtURL = New-Object Windows.Forms.TextBox
$txtURL.Location = New-Object Drawing.Point(115, 33)
$txtURL.Size = New-Object Drawing.Size(560, 24)
$txtURL.BackColor = $C.Surface
$txtURL.ForeColor = $C.Text
$txtURL.BorderStyle = "FixedSingle"
$txtURL.Font = New-Object Drawing.Font("Segoe UI", 9)
$cardYT.Controls.Add($txtURL)

$lblFormat = New-Object Windows.Forms.Label
$lblFormat.Text = "Formato:"
$lblFormat.Location = New-Object Drawing.Point(10, 65)
$lblFormat.Size = New-Object Drawing.Size(100, 20)
$lblFormat.ForeColor = $C.Text
$lblFormat.Font = New-Object Drawing.Font("Segoe UI", 8.5)
$cardYT.Controls.Add($lblFormat)

$comboFormat = New-Object Windows.Forms.ComboBox
$comboFormat.Location = New-Object Drawing.Point(115, 63)
$comboFormat.Size = New-Object Drawing.Size(200, 24)
$comboFormat.BackColor = $C.Surface
$comboFormat.ForeColor = $C.Text
$comboFormat.FlatStyle = "Flat"
$comboFormat.Font = New-Object Drawing.Font("Segoe UI", 9)
$comboFormat.DropDownStyle = "DropDownList"
[void]$comboFormat.Items.Add("Video MP4 (HD)")
[void]$comboFormat.Items.Add("Video WEBM")
[void]$comboFormat.Items.Add("Audio MP3 (192kbps)")
[void]$comboFormat.Items.Add("Audio MP3 (320kbps)")
[void]$comboFormat.Items.Add("Audio M4A")
[void]$comboFormat.Items.Add("Audio WAV")
$comboFormat.SelectedIndex = 0
$cardYT.Controls.Add($comboFormat)

$lblDest = New-Object Windows.Forms.Label
$lblDest.Text = "Destino:"
$lblDest.Location = New-Object Drawing.Point(330, 65)
$lblDest.Size = New-Object Drawing.Size(60, 20)
$lblDest.ForeColor = $C.Text
$lblDest.Font = New-Object Drawing.Font("Segoe UI", 8.5)
$cardYT.Controls.Add($lblDest)

$txtDest = New-Object Windows.Forms.TextBox
$txtDest.Location = New-Object Drawing.Point(390, 63)
$txtDest.Size = New-Object Drawing.Size(200, 24)
$txtDest.BackColor = $C.Surface
$txtDest.ForeColor = $C.Text
$txtDest.BorderStyle = "FixedSingle"
$txtDest.Font = New-Object Drawing.Font("Segoe UI", 9)
$txtDest.Text = "$env:USERPROFILE\Downloads"
$cardYT.Controls.Add($txtDest)

$btnBrowse = Make-Button "..." 600 63 30 24 $C.Card
$btnBrowse.Font = New-Object Drawing.Font("Segoe UI", 8)
$btnBrowse.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Selecciona carpeta de descargas"
    if ($dlg.ShowDialog() -eq "OK") {
        $txtDest.Text = $dlg.SelectedPath
    }
})
$cardYT.Controls.Add($btnBrowse)

$lblFileName = New-Object Windows.Forms.Label
$lblFileName.Text = "Nombre:"
$lblFileName.Location = New-Object Drawing.Point(10, 95)
$lblFileName.Size = New-Object Drawing.Size(100, 20)
$lblFileName.ForeColor = $C.Text
$lblFileName.Font = New-Object Drawing.Font("Segoe UI", 8.5)
$cardYT.Controls.Add($lblFileName)

$txtFileName = New-Object Windows.Forms.TextBox
$txtFileName.Location = New-Object Drawing.Point(115, 93)
$txtFileName.Size = New-Object Drawing.Size(350, 24)
$txtFileName.BackColor = $C.Surface
$txtFileName.ForeColor = $C.Text
$txtFileName.BorderStyle = "FixedSingle"
$txtFileName.Font = New-Object Drawing.Font("Segoe UI", 9)
$txtFileName.Text = "%(title)s"
$cardYT.Controls.Add($txtFileName)

$lblHint = New-Object Windows.Forms.Label
$lblHint.Text = "%(title)s = titulo original"
$lblHint.Location = New-Object Drawing.Point(470, 95)
$lblHint.Size = New-Object Drawing.Size(200, 20)
$lblHint.ForeColor = $C.SubText
$lblHint.Font = New-Object Drawing.Font("Segoe UI", 7.5)
$cardYT.Controls.Add($lblHint)

$chkPlaylist = New-Object Windows.Forms.CheckBox
$chkPlaylist.Text = "Descargar playlist completa"
$chkPlaylist.Location = New-Object Drawing.Point(115, 125)
$chkPlaylist.Size = New-Object Drawing.Size(220, 22)
$chkPlaylist.ForeColor = $C.Text
$chkPlaylist.BackColor = $C.Card
$chkPlaylist.Font = New-Object Drawing.Font("Segoe UI", 8)
$cardYT.Controls.Add($chkPlaylist)

$chkSubtitles = New-Object Windows.Forms.CheckBox
$chkSubtitles.Text = "Incluir subtitulos"
$chkSubtitles.Location = New-Object Drawing.Point(340, 125)
$chkSubtitles.Size = New-Object Drawing.Size(150, 22)
$chkSubtitles.ForeColor = $C.Text
$chkSubtitles.BackColor = $C.Card
$chkSubtitles.Font = New-Object Drawing.Font("Segoe UI", 8)
$cardYT.Controls.Add($chkSubtitles)

# Boton Descargar
$btnDownload = Make-Button "DESCARGAR" 10 200 300 40 $C.Green
$btnDownload.Font = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
$btnDownload.Add_Click({
    $url = $txtURL.Text.Trim()
    if (-not $url) {
        Log "Ingresa una URL de YouTube." "WARN"
        return
    }
    if ($url -notmatch "youtube\.com|youtu\.be") {
        Log "La URL no parece ser de YouTube." "WARN"
        return
    }

    $dest = $txtDest.Text.Trim()
    if (-not (Test-Path $dest)) {
        try { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        catch { Log "No se pudo crear la carpeta destino." "ERR"; return }
    }

    $formato = $comboFormat.SelectedItem
    $fileName = $txtFileName.Text.Trim()
    if (-not $fileName) { $fileName = "%(title)s" }

    # Construir opciones segun formato
    $ydlArgs = @()
    $ydlArgs += "-o `"$dest\$fileName.%(ext)s`""

    switch ($formato) {
        "Video MP4 (HD)" {
            $ydlArgs += "-f `"bestvideo[ext=mp4][height<=1080]+bestaudio[ext=m4a]/best[ext=mp4]/best`""
            $ydlArgs += "--merge-output-format mp4"
        }
        "Video WEBM" {
            $ydlArgs += "-f `"bestvideo[ext=webm]+bestaudio[ext=webm]/best[ext=webm]/best`""
        }
        "Audio MP3 (192kbps)" {
            $ydlArgs += "-f bestaudio/best"
            $ydlArgs += "--extract-audio"
            $ydlArgs += "--audio-format mp3"
            $ydlArgs += "--audio-quality 192K"
        }
        "Audio MP3 (320kbps)" {
            $ydlArgs += "-f bestaudio/best"
            $ydlArgs += "--extract-audio"
            $ydlArgs += "--audio-format mp3"
            $ydlArgs += "--audio-quality 320K"
        }
        "Audio M4A" {
            $ydlArgs += "-f bestaudio[ext=m4a]/bestaudio/best"
        }
        "Audio WAV" {
            $ydlArgs += "-f bestaudio/best"
            $ydlArgs += "--extract-audio"
            $ydlArgs += "--audio-format wav"
        }
    }

    if ($chkPlaylist.Checked) {
        $ydlArgs += "--yes-playlist"
    } else {
        $ydlArgs += "--no-playlist"
    }

    if ($chkSubtitles.Checked) {
        $ydlArgs += "--write-subs"
        $ydlArgs += "--sub-langs es,en"
    }

    $ydlArgs += "--no-warnings"
    $ydlArgs += "--progress"

    $cmd = "yt-dlp $([string]::Join(' ', $ydlArgs)) `"$url`""

    Log "--- Descarga YouTube ---" "TITLE"
    Log "URL: $url" "INFO"
    Log "Formato: $formato" "INFO"
    Log "Destino: $dest" "INFO"
    Log "Ejecutando yt-dlp..." "INFO"

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "yt-dlp"
        $psi.Arguments = ([string]::Join(' ', $ydlArgs)) + " `"$url`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true

        $proc = [System.Diagnostics.Process]::Start($psi)

        # Leer salida en tiempo real
        while (-not $proc.StandardOutput.EndOfStream) {
            $line = $proc.StandardOutput.ReadLine()
            if ($line -match "\[download\]") {
                Log $line "INFO"
            }
        }

        $proc.WaitForExit()

        if ($proc.ExitCode -eq 0) {
            Log "Descarga completada exitosamente." "OK"
        } else {
            $err = $proc.StandardError.ReadToEnd()
            if ($err) { Log $err "ERR" }
        }
    } catch {
        if ($_ -match "no se reconoce como un comando") {
            Log "yt-dlp no esta instalado. Instalalo con: pip install yt-dlp" "ERR"
            Log "O descargalo desde: https://github.com/yt-dlp/yt-dlp/releases" "INFO"
        } else {
            Log "Error: $_" "ERR"
        }
    }
})
$tabYT.Controls.Add($btnDownload)

# Boton Info
$btnYTInfo = Make-Button "Ver Info del Video" 320 200 200 40 $C.Card
$btnYTInfo.Add_Click({
    $url = $txtURL.Text.Trim()
    if (-not $url) { Log "Ingresa una URL primero." "WARN"; return }

    Log "--- Informacion del video ---" "TITLE"
    try {
        $info = yt-dlp --dump-json --no-warnings $url 2>$null | ConvertFrom-Json
        Log "Titulo: $($info.title)" "INFO"
        Log "Canal: $($info.uploader)" "INFO"
        Log "Duracion: $([math]::Floor($info.duration / 60))m $($info.duration % 60)s" "INFO"
        Log "Vistas: $($info.view_count)" "INFO"
        Log "Mejor calidad video: $($info.format | Where-Object { $_.vcodec -ne 'none' } | Select-Object -First 1 -ExpandProperty format)" "INFO"
        Log "Mejor calidad audio: $($info.format | Where-Object { $_.acodec -ne 'none' -and $_.vcodec -eq 'none' } | Select-Object -First 1 -ExpandProperty format)" "INFO"
    } catch {
        Log "Error obteniendo info. Verifica la URL y que yt-dlp este instalado." "ERR"
    }
})
$tabYT.Controls.Add($btnYTInfo)

# Boton Abrir carpeta
$btnOpenFolder = Make-Button "Abrir Carpeta" 530 200 150 40 $C.Card
$btnOpenFolder.Add_Click({
    $dest = $txtDest.Text.Trim()
    if (Test-Path $dest) {
        Start-Process explorer $dest
    } else {
        Log "La carpeta no existe." "WARN"
    }
})
$tabYT.Controls.Add($btnOpenFolder)

# Card: Requisitos
$cardReq = Make-Card "Requisitos" $null $tabYT 250 100
$cardReq.Size = New-Object Drawing.Size(690, 100)

$lblReq = New-Object Windows.Forms.Label
$lblReq.Text = "Requisitos:`n`n1. Python instalado (python.org)`n2. yt-dlp:  pip install yt-dlp`n3. FFmpeg:  winget install Gyan.FFmpeg  (o desde ffmpeg.org)"
$lblReq.Location = New-Object Drawing.Point(10, 30)
$lblReq.Size = New-Object Drawing.Size(670, 60)
$lblReq.ForeColor = $C.SubText
$lblReq.Font = New-Object Drawing.Font("Consolas", 8.5)
$cardReq.Controls.Add($lblReq)



# ============================================================
#   FOOTER
# ============================================================
$footer = New-Object Windows.Forms.Label
$footer.Text = "Syscodi7 System Toolkit v1.1  |  PowerShell + WinForms  |  Ejecutar como Administrador"
$footer.Location = New-Object Drawing.Point(0, 622)
$footer.Size = New-Object Drawing.Size(1150, 20)
$footer.TextAlign = "MiddleCenter"
$footer.ForeColor = $C.SubText
$footer.Font = New-Object Drawing.Font("Segoe UI", 7)
$form.Controls.Add($footer)

# Limpiar timer al cerrar
$form.Add_FormClosing({ $timerMon.Stop() })

# ============================================================
#   MOSTRAR FORMULARIO
# ============================================================
$form.ShowDialog()
