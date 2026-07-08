# ============================================================
#   NovaTech System Toolkit v1.0
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
$script:LogPath = "$env:TEMP\NovaTech_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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
    $r = [Windows.Forms.MessageBox]::Show($msg, "NovaTech - Confirmar",
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
$form.Text = "NovaTech System Toolkit v1.0"
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
$lblT.Text = "NOVATECH"
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
#   TAB CONTROL (7 PESTANAS)
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
$tabApps    = Make-Tab "Aplicaciones"
$tabTweaks  = Make-Tab "Tweaks"
$tabSec     = Make-Tab "Seguridad"
$tabBackup  = Make-Tab "Backup"
$tabSys     = Make-Tab "Sistema"

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
    $dlg.FileName = "NovaTech_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
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
$outputBox.Text = "  NovaTech System Toolkit v1.0`n  Listo. Selecciona una opcion."
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
        Checkpoint-Computer -Description "NovaTech Backup $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -RestorePointType MODIFY_SETTINGS
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
# PLACEHOLDER: TAB 3 - APLICACIONES
# ============================================================
#   TAB 3: APLICACIONES
# ============================================================
$txtAppSearch = New-Object Windows.Forms.TextBox
$txtAppSearch.Location = New-Object Drawing.Point(5, 5)
$txtAppSearch.Size = New-Object Drawing.Size(340, 24)
$txtAppSearch.BackColor = $C.Card
$txtAppSearch.ForeColor = $C.Text
$txtAppSearch.BorderStyle = "FixedSingle"
$txtAppSearch.Font = New-Object Drawing.Font("Segoe UI", 9)
$txtAppSearch.Text = "Buscar aplicacion..."
$txtAppSearch.Add_Enter({ if ($txtAppSearch.Text -eq "Buscar aplicacion...") { $txtAppSearch.Text = ""; $txtAppSearch.ForeColor = $C.Text } })
$txtAppSearch.Add_Leave({ if ([string]::IsNullOrWhiteSpace($txtAppSearch.Text)) { $txtAppSearch.Text = "Buscar aplicacion..."; $txtAppSearch.ForeColor = $C.SubText } })
$tabApps.Controls.Add($txtAppSearch)

$appScroll = New-Object Windows.Forms.Panel
$appScroll.Location = New-Object Drawing.Point(0, 32)
$appScroll.Size = New-Object Drawing.Size(700, 430)
$appScroll.AutoScroll = $true
$appScroll.BackColor = $C.Bg
$tabApps.Controls.Add($appScroll)

$apps = @(
    @{c="Navegadores";    n="Google Chrome";   id="Google.Chrome"},
    @{c="Navegadores";    n="Firefox";         id="Mozilla.Firefox"},
    @{c="Navegadores";    n="Brave";           id="Brave.Brave";                    f=$true},
    @{c="Navegadores";    n="LibreWolf";       id="LibreWolf.LibreWolf";            f=$true},
    @{c="Comunicacion";   n="Discord";         id="Discord.Discord"},
    @{c="Comunicacion";   n="Telegram";        id="Telegram.TelegramDesktop";        f=$true},
    @{c="Comunicacion";   n="Slack";           id="SlackTechnologies.Slack"},
    @{c="Comunicacion";   n="Signal";          id="OpenWhisperSystems.Signal";       f=$true},
    @{c="Comunicacion";   n="Zoom";            id="Zoom.Zoom"},
    @{c="Desarrollo";     n="VS Code";         id="Microsoft.VisualStudioCode"},
    @{c="Desarrollo";     n="Git";             id="Git.Git";                         f=$true},
    @{c="Desarrollo";     n="Python 3";        id="Python.Python.3";                 f=$true},
    @{c="Desarrollo";     n="Node.js LTS";     id="OpenJS.NodeJS.LTS";              f=$true},
    @{c="Desarrollo";     n="Java JDK 21";     id="EclipseAdoptium.Temurin.21.JDK"; f=$true},
    @{c="Herramientas";   n="7-Zip";           id="7zip.7zip";                       f=$true},
    @{c="Herramientas";   n="VLC";             id="VideoLAN.VLC";                    f=$true},
    @{c="Herramientas";   n="Notepad++";       id="Notepad++.Notepad++";             f=$true},
    @{c="Herramientas";   n="Everything";      id="voidtools.Everything";            f=$true},
    @{c="Herramientas";   n="ShareX";          id="ShareX.ShareX";                   f=$true},
    @{c="Herramientas";   n="Rufus";           id="Rufus.Rufus";                     f=$true},
    @{c="Herramientas";   n="WinRAR";          id="RARLab.WinRAR"},
    @{c="Multimedia";     n="OBS Studio";      id="OBSProject.OBSStudio";            f=$true},
    @{c="Multimedia";     n="Spotify";         id="Spotify.Spotify"},
    @{c="Hardware";       n="CrystalDiskInfo"; id="CrystalDewWorld.CrystalDiskInfo"; f=$true},
    @{c="Hardware";       n="HWiNFO";          id="REALiX.HWiNFO"},
    @{c="Hardware";       n="GPU-Z";           id="TechPowerUp.GPU-Z"},
    @{c="Seguridad";      n="Bitwarden";       id="Bitwarden.Bitwarden";             f=$true},
    @{c="Seguridad";      n="KeePassXC";       id="KeePassXCTeam.KeePassXC";         f=$true},
    @{c="Oficina";        n="LibreOffice";     id="TheDocumentFoundation.LibreOffice"; f=$true},
    @{c="Oficina";        n="Microsoft 365";   id="Microsoft.Microsoft365"},
    @{c="Oficina";        n="OneDrive";        id="Microsoft.OneDrive"},
    @{c="Oficina";        n="Teams";           id="Microsoft.Teams"}
)

$script:appCBs = @()

function Build-AppList($filter = "") {
    $appScroll.Controls.Clear()
    $script:appCBs = @()
    $yy = 5; $lastCat = ""; $col = 0
    foreach ($a in $apps) {
        if ($filter -and $filter -ne "Buscar aplicacion...") {
            $esc = [regex]::Escape($filter)
            if ($a.n -notmatch $esc -and $a.c -notmatch $esc) { continue }
        }
        if ($a.c -ne $lastCat) {
            $col = 0
            if ($lastCat) { $yy += 8 }
            $lc = New-Object Windows.Forms.Label
            $lc.Text = "  $($a.c)"
            $lc.Location = New-Object Drawing.Point(4, $yy)
            $lc.Size = New-Object Drawing.Size(680, 18)
            $lc.ForeColor = $C.Accent
            $lc.Font = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
            $appScroll.Controls.Add($lc)
            $yy += 20; $lastCat = $a.c
        }
        $cb = New-Object Windows.Forms.CheckBox
        $cb.Text = $a.n
        $cb.Location = New-Object Drawing.Point((8 + $col * 170), $yy)
        $cb.Size = New-Object Drawing.Size(165, 22)
        $cb.ForeColor = $(if ($a.f) { $C.Accent2 } else { $C.Text })
        $cb.BackColor = $C.Bg
        $cb.Font = New-Object Drawing.Font("Segoe UI", 8)
        $cb.Tag = "winget install -e --id $($a.id) --silent"
        $appScroll.Controls.Add($cb)
        $script:appCBs += $cb
        $col++
        if ($col -ge 4) { $col = 0; $yy += 25 }
    }
}
Build-AppList

$txtAppSearch.Add_TextChanged({ Build-AppList $txtAppSearch.Text })

$pnlAppBot = New-Object Windows.Forms.Panel
$pnlAppBot.Location = New-Object Drawing.Point(0, 465)
$pnlAppBot.Size = New-Object Drawing.Size(700, 40)
$pnlAppBot.BackColor = $C.Surface
$tabApps.Controls.Add($pnlAppBot)

$lblFoss = New-Object Windows.Forms.Label
$lblFoss.Text = "  Cyan = FOSS (Software Libre)"
$lblFoss.ForeColor = $C.Accent2
$lblFoss.Location = New-Object Drawing.Point(5, 10)
$lblFoss.Size = New-Object Drawing.Size(200, 20)
$lblFoss.Font = New-Object Drawing.Font("Segoe UI", 7.5)
$pnlAppBot.Controls.Add($lblFoss)

$btnListInstalled = Make-Button "Ver Instaladas" 210 4 140 30 $C.Card
$btnListInstalled.Font = New-Object Drawing.Font("Segoe UI", 7.5)
$btnListInstalled.Add_Click({
    Log "--- Apps instaladas (winget) ---" "TITLE"
    $r = winget list 2>&1
    foreach ($l in $r) { Log $l "INFO" }
})
$pnlAppBot.Controls.Add($btnListInstalled)

$btnUpgradeAll = Make-Button "Actualizar Todo" 360 4 140 30 $C.Green
$btnUpgradeAll.Font = New-Object Drawing.Font("Segoe UI", 7.5)
$btnUpgradeAll.Add_Click({
    Log "Actualizando todas las apps..." "INFO"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"winget upgrade --all --silent`"" -Verb RunAs
    Log "Actualizacion lanzada en ventana separada." "OK"
})
$pnlAppBot.Controls.Add($btnUpgradeAll)

$btnInstallSel = Make-Button "Instalar Seleccion" 510 4 170 30 $C.Btn
$btnInstallSel.Font = New-Object Drawing.Font("Segoe UI", 7.5)
$btnInstallSel.Add_Click({
    $sel = $script:appCBs | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Log "No seleccionaste ninguna aplicacion." "WARN"; return }
    foreach ($cb in $sel) {
        Log "Instalando: $($cb.Text)..." "INFO"
        try {
            $r = Invoke-Expression $cb.Tag 2>&1
            Log "$($cb.Text) - Instalado." "OK"
        } catch { Log "Error instalando $($cb.Text): $_" "ERR" }
    }
})
$pnlAppBot.Controls.Add($btnInstallSel)

# PLACEHOLDER: TAB 4 - TWEAKS
# ============================================================
#   TAB 4: TWEAKS
# ============================================================
Make-Section "Optimizaciones del sistema" 10 8 $tabTweaks

$tweaks = @(
    @{n="Alto rendimiento (energia)"; cmd='powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'; rev='powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e'},
    @{n="Desactivar efectos visuales"; cmd='SystemPropertiesPerformance.exe'; rev=''},
    @{n="Desactivar notificaciones"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f'},
    @{n="Desactivar telemetria"; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f'},
    @{n="Desactivar Cortana"; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f'},
    @{n="Modo juego activado"; cmd='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f'},
    @{n="Mostrar extensiones de archivo"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f'},
    @{n="Mostrar archivos ocultos"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f'},
    @{n="Desactivar Xbox Game Bar"; cmd='reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f'},
    @{n="God Mode en Escritorio"; cmd='$gm="$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"; New-Item -ItemType Directory -Path $gm -EA SilentlyContinue'; rev='Remove-Item "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -EA SilentlyContinue'},
    @{n="Desactivar actualizaciones auto"; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f'},
    @{n="Desactivar Bing en busqueda Start"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 1 /f'}
)

$script:tweakCBs = @()
$yT = 32; $colT = 0
foreach ($tw in $tweaks) {
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = $tw.n
    $cb.Location = New-Object Drawing.Point((10 + $colT * 340), $yT)
    $cb.Size = New-Object Drawing.Size(330, 24)
    $cb.ForeColor = $C.Text
    $cb.BackColor = $C.Bg
    $cb.Font = New-Object Drawing.Font("Segoe UI", 8)
    $cb.Tag = $tw.cmd
    $cb.AccessibleDescription = $tw.rev
    $tabTweaks.Controls.Add($cb)
    $script:tweakCBs += $cb
    $colT++
    if ($colT -ge 2) { $colT = 0; $yT += 28 }
}

$btnApplyT = Make-Button "Aplicar Seleccionados" 10 380 220 36 $C.Green
$btnApplyT.Add_Click({
    $sel = $script:tweakCBs | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Log "No seleccionaste ningun tweak." "WARN"; return }
    if (-not (Confirm-Action "Aplicar $($sel.Count) tweak(s) al sistema?")) { return }
    foreach ($cb in $sel) {
        Log "Aplicando: $($cb.Text)..." "INFO"
        try { Invoke-Expression $cb.Tag 2>&1 | Out-Null; Log "Aplicado." "OK" }
        catch { Log "Error: $_" "ERR" }
    }
    Log "Tweaks aplicados. Puede requerir reinicio." "OK"
})
$tabTweaks.Controls.Add($btnApplyT)

$btnRevertT = Make-Button "Revertir Seleccionados" 240 380 220 36 $C.Orange
$btnRevertT.Add_Click({
    $sel = $script:tweakCBs | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Log "No seleccionaste ningun tweak." "WARN"; return }
    foreach ($cb in $sel) {
        if ($cb.AccessibleDescription) {
            Log "Revirtiendo: $($cb.Text)..." "INFO"
            try { Invoke-Expression $cb.AccessibleDescription 2>&1 | Out-Null; Log "Revertido." "OK" }
            catch { Log "Error al revertir: $_" "ERR" }
        } else { Log "Sin reverso disponible para: $($cb.Text)" "WARN" }
    }
})
$tabTweaks.Controls.Add($btnRevertT)

$btnCheckTweaks = Make-Button "Ver Estado Actual" 470 380 200 36 $C.Card
$btnCheckTweaks.Font = New-Object Drawing.Font("Segoe UI", 8)
$btnCheckTweaks.Add_Click({
    Log "--- Estado de tweaks ---" "TITLE"
    try {
        $tel = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -EA SilentlyContinue).AllowTelemetry
        Log "Telemetria: $(if($tel -eq 0){'DESACTIVADA'}else{'ACTIVA (nivel $tel)'})" $(if($tel -eq 0){'OK'}else{'WARN'})
        $cortana = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -EA SilentlyContinue).AllowCortana
        Log "Cortana: $(if($cortana -eq 0){'DESACTIVADA'}else{'ACTIVA'})" $(if($cortana -eq 0){'OK'}else{'WARN'})
        $ext = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -EA SilentlyContinue).HideFileExt
        Log "Extensiones archivo: $(if($ext -eq 0){'VISIBLES'}else{'OCULTAS'})" $(if($ext -eq 0){'OK'}else{'WARN'})
        $plan = (powercfg /getactivescheme) -replace '.*:\s+(.+)\s*\(.*','$1'
        Log "Plan energia: $plan" "INFO"
    } catch { Log "Error leyendo estado: $_" "ERR" }
})
$tabTweaks.Controls.Add($btnCheckTweaks)
# PLACEHOLDER: TAB 5 - SEGURIDAD
# ============================================================
#   TAB 5: SEGURIDAD
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

# PLACEHOLDER: TAB 6 - BACKUP
# ============================================================
#   TAB 6: BACKUP
# ============================================================
Make-Section "Backup de archivos personales" 10 8 $tabBackup

$lblDest = New-Object Windows.Forms.Label
$lblDest.Text = "Destino: $env:USERPROFILE\Desktop"
$lblDest.Location = New-Object Drawing.Point(10, 32)
$lblDest.Size = New-Object Drawing.Size(480, 20)
$lblDest.ForeColor = $C.SubText
$lblDest.Font = New-Object Drawing.Font("Consolas", 8)
$tabBackup.Controls.Add($lblDest)

$btnDest = Make-Button "Cambiar Destino" 500 30 170 28 $C.Card
$btnDest.Font = New-Object Drawing.Font("Segoe UI", 8)
$btnDest.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Selecciona carpeta de destino"
    if ($dlg.ShowDialog() -eq "OK") { $lblDest.Text = "Destino: $($dlg.SelectedPath)" }
})
$tabBackup.Controls.Add($btnDest)

$bkFolders = @(
    @{n="Documentos";  p="$env:USERPROFILE\Documents";  c=$true},
    @{n="Escritorio";  p="$env:USERPROFILE\Desktop";    c=$true},
    @{n="Descargas";   p="$env:USERPROFILE\Downloads";  c=$false},
    @{n="Imagenes";    p="$env:USERPROFILE\Pictures";   c=$false},
    @{n="Videos";      p="$env:USERPROFILE\Videos";     c=$false},
    @{n="Musica";      p="$env:USERPROFILE\Music";      c=$false}
)

$script:bkCBs = @(); $xF = 10; $yF = 58
foreach ($bf in $bkFolders) {
    $cb = New-Object Windows.Forms.CheckBox; $cb.Text = $bf.n; $cb.Checked = $bf.c
    $cb.Location = New-Object Drawing.Point($xF, $yF); $cb.Size = New-Object Drawing.Size(150, 22)
    $cb.ForeColor = $C.Text; $cb.BackColor = $C.Bg; $cb.Tag = $bf.p
    $tabBackup.Controls.Add($cb)
    $script:bkCBs += $cb; $xF += 155; if ($xF -gt 650) { $xF = 10; $yF += 26 }
}

$btnBackup = Make-Button "CREAR BACKUP ZIP" 10 115 220 36 $C.Green
$btnBackup.Add_Click({
    $dest = ($lblDest.Text -replace "^Destino: ","").Trim()
    $sel = $script:bkCBs | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Log "Selecciona al menos una carpeta." "WARN"; return }
    $zipName = "NovaTech_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
    $zipPath = Join-Path $dest $zipName
    Log "Creando backup: $zipPath" "INFO"
    $tmp = "$env:TEMP\novatech_bk_tmp"
    Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
    New-Item $tmp -ItemType Directory | Out-Null
    foreach ($cb in $sel) {
        if (Test-Path $cb.Tag) {
            $fn = Split-Path $cb.Tag -Leaf
            Copy-Item $cb.Tag "$tmp\$fn" -Recurse -Force -EA SilentlyContinue
            Log "Copiado: $($cb.Tag)" "INFO"
        }
    }
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $zipPath)
    Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
    Log "Backup creado: $zipPath" "OK"
})
$tabBackup.Controls.Add($btnBackup)

Make-Section "Backup de drivers y registro" 10 170 $tabBackup

$btnExpDrivers = Make-Button "Exportar Drivers" 10 194 200 34
$btnExpDrivers.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Carpeta destino para drivers"
    if ($dlg.ShowDialog() -eq "OK") {
        Log "Exportando drivers a: $($dlg.SelectedPath)" "INFO"
        Start-Process powershell -ArgumentList "-NoProfile -Command `"pnputil /export-driver * '$($dlg.SelectedPath)'`"" -Verb RunAs -Wait
        Log "Drivers exportados." "OK"
    }
})
$tabBackup.Controls.Add($btnExpDrivers)

$btnExpReg = Make-Button "Exportar Registro (HKCU)" 220 194 220 34
$btnExpReg.Add_Click({
    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter = "Registry (*.reg)|*.reg"
    $dlg.FileName = "HKCU_Backup_$(Get-Date -Format 'yyyyMMdd').reg"
    if ($dlg.ShowDialog() -eq "OK") {
        Run-Safe "reg export HKCU `"$($dlg.FileName)`" /y" "Exportar Registro"
        Log "Registro exportado: $($dlg.FileName)" "OK"
    }
})
$tabBackup.Controls.Add($btnExpReg)

$btnWinBk = Make-Button "Copia de Seguridad Windows" 450 194 220 34
$btnWinBk.Add_Click({ Start-Process "control /name Microsoft.BackupAndRestore" })
$tabBackup.Controls.Add($btnWinBk)

# PLACEHOLDER: TAB 7 - SISTEMA
# ============================================================
#   TAB 7: SISTEMA
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
    $dlg.FileName = "NovaTech_Reporte_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
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
    $input = [Microsoft.VisualBasic.Interaction]::InputBox("Nombre del proceso (sin .exe):", "NovaTech", "")
    if ($input) {
        $procs = Get-Process -Name $input -EA SilentlyContinue
        if ($procs) {
            if (Confirm-Action "Matar $($procs.Count) proceso(s) '$input'?") {
                $procs | Stop-Process -Force -EA SilentlyContinue
                Log "Proceso(s) '$input' terminados." "OK"
            }
        } else { Log "No se encontro proceso: $input" "WARN" }
    }
})
$tabSys.Controls.Add($btnKillProc)

# ============================================================
#   FOOTER
# ============================================================
$footer = New-Object Windows.Forms.Label
$footer.Text = "NovaTech System Toolkit v1.0  |  PowerShell + WinForms  |  Ejecutar como Administrador"
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
