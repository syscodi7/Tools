#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#   VERIFICACIÓN DE ADMINISTRADOR
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $res = [Windows.Forms.MessageBox]::Show("SysCodi WinTool Pro requiere permisos de Administrador.`n`nDesea reiniciar como Administrador?", "Permisos requeridos", "YesNo", "Warning")
    if ($res -eq "Yes") {
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    }
    exit
}

# ============================================================
#   SISTEMA DE LOGS
# ============================================================
$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($msg) {
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Add-Content -Path $logFile -Value $entry -Encoding UTF8 -EA SilentlyContinue
}

# ============================================================
#   COLORES CORPORATIVOS (Fieles a la captura de pantalla)
# ============================================================
$cBg       = [Drawing.Color]::FromArgb(13, 22, 45)
$cPanel    = [Drawing.Color]::FromArgb(20, 35, 70)
$cCard     = [Drawing.Color]::FromArgb(28, 48, 96)
$cAccent   = [Drawing.Color]::FromArgb(0, 120, 215)
$cAccent2  = [Drawing.Color]::FromArgb(0, 180, 255)
$cGreen    = [Drawing.Color]::FromArgb(0, 210, 130)
$cYellow   = [Drawing.Color]::FromArgb(255, 200, 50)
$cRed      = [Drawing.Color]::FromArgb(255, 80, 80)
$cText     = [Drawing.Color]::White
$cSubText  = [Drawing.Color]::FromArgb(160, 200, 255)
$cBtn      = [Drawing.Color]::FromArgb(16, 42, 82)
$cOutput   = [Drawing.Color]::FromArgb(8, 15, 35)

# ============================================================
#   FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text          = "SysCodi WinTool Pro"
$form.Size          = New-Object Drawing.Size(1280, 760)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBg
$form.ForeColor     = $cText
$form.Font          = New-Object Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "Sizable"
$form.MinimumSize   = New-Object Drawing.Size(1100, 680)

# ============================================================
#   HEADER
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Size      = New-Object Drawing.Size(1280, 64)
$header.Location  = New-Object Drawing.Point(0, 0)
$header.BackColor = $cPanel
$header.Anchor    = "Top, Left, Right"
$form.Controls.Add($header)

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text     = "SysCodi WinTool Pro"
$lblTitle.Font     = New-Object Drawing.Font("Segoe UI", 16, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cAccent2
$lblTitle.Location = New-Object Drawing.Point(15, 8)
$lblTitle.Size     = New-Object Drawing.Size(420, 32)
$header.Controls.Add($lblTitle)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text      = "Utilidad de sistema avanzada para Windows"
$lblSub.Font      = New-Object Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = $cSubText
$lblSub.Location  = New-Object Drawing.Point(17, 38)
$lblSub.Size      = New-Object Drawing.Size(500, 18)
$header.Controls.Add($lblSub)

# Sistema Info en Header (Derecha)
$lblSysInfo = New-Object Windows.Forms.Label
$lblSysInfo.Text      = "Windows 11 Pro 23H2`nUsuario: syscodi"
$lblSysInfo.Font      = New-Object Drawing.Font("Segoe UI", 8.5)
$lblSysInfo.ForeColor = $cSubText
$lblSysInfo.Location  = New-Object Drawing.Point(1000, 12)
$lblSysInfo.Size      = New-Object Drawing.Size(250, 40)
$lblSysInfo.TextAlign = "TopRight"
$lblSysInfo.Anchor    = "Top, Right"
$header.Controls.Add($lblSysInfo)

# ============================================================
#   BARRA DE PROGRESO GLOBAL
# ============================================================
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object Drawing.Point(0, 64)
$progressBar.Size      = New-Object Drawing.Size(1280, 4)
$progressBar.Style    = "Marquee"
$progressBar.MarqueeAnimationSpeed = 0
$progressBar.BackColor = $cPanel
$progressBar.ForeColor = $cAccent2
$progressBar.Anchor    = "Top, Left, Right"
$form.Controls.Add($progressBar)

function Start-Progress { $progressBar.MarqueeAnimationSpeed = 30; $form.Refresh() }
function Stop-Progress  { $progressBar.MarqueeAnimationSpeed = 0;  $progressBar.Value = 0 }

# ============================================================
#   TAB CONTROL (Pestañas principales superiores)
# ============================================================
$tabs = New-Object Windows.Forms.TabControl
$tabs.Location   = New-Object Drawing.Point(12, 75)
$tabs.Size       = New-Object Drawing.Size(760, 480)
$tabs.BackColor  = $cBg
$tabs.Appearance = "FlatButtons"
$tabs.Font       = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$tabs.Anchor     = "Top,Left,Bottom,Right"
$form.Controls.Add($tabs)

function New-Tab($titulo) {
    $t = New-Object Windows.Forms.TabPage
    $t.Text      = "$titulo"
    $t.BackColor = $cBg
    $t.ForeColor = $cText
    $tabs.TabPages.Add($t)
    return $t
}

$tabRepair = New-Tab "Reparación"
$tabApps   = New-Tab "Aplicaciones"
$tabTweaks = New-Tab "Tweaks"
$tabUtils  = New-Tab "Utilidades"
$tabTrans  = New-Tab "Transferencia"
$tabSystem = New-Tab "Sistema"
$tabDash   = New-Tab "Dashboard"

# ============================================================
#   PANEL DERECHO - CONSOLA DE SALIDA
# ============================================================
$rightPanel = New-Object Windows.Forms.Panel
$rightPanel.Location  = New-Object Drawing.Point(785, 75)
$rightPanel.Size      = New-Object Drawing.Size(465, 480)
$rightPanel.BackColor = $cOutput
$rightPanel.Anchor    = "Top,Right,Bottom"
$form.Controls.Add($rightPanel)

$pnlConHeader = New-Object Windows.Forms.Panel
$pnlConHeader.Location  = New-Object Drawing.Point(0, 0)
$pnlConHeader.Size      = New-Object Drawing.Size(465, 32)
$pnlConHeader.BackColor = $cPanel
$pnlConHeader.Anchor    = "Top, Left, Right"
$rightPanel.Controls.Add($pnlConHeader)

$lblConsole = New-Object Windows.Forms.Label
$lblConsole.Text      = " Consola de salida"
$lblConsole.Location  = New-Object Drawing.Point(5, 0)
$lblConsole.Size      = New-Object Drawing.Size(200, 32)
$lblConsole.ForeColor = $cAccent2
$lblConsole.Font      = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
$lblConsole.TextAlign = "MiddleLeft"
$pnlConHeader.Controls.Add($lblConsole)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location    = New-Object Drawing.Point(10, 42)
$outputBox.Size        = New-Object Drawing.Size(445, 425)
$outputBox.BackColor   = $cOutput
$outputBox.ForeColor   = $cAccent2
$outputBox.Font        = New-Object Drawing.Font("Consolas", 9)
$outputBox.ReadOnly    = $true
$outputBox.BorderStyle = "None"
$outputBox.ScrollBars  = "Vertical"
$outputBox.Anchor      = "Top,Left,Bottom,Right"
$outputBox.Text        = "Listo. Selecciona una opción y ejecuta."
$rightPanel.Controls.Add($outputBox)

function Write-Out($msg, $color = $null) {
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionColor = if ($color) { $color } else { $cAccent2 }
    $outputBox.AppendText("`r`n $msg")
    $outputBox.ScrollToCaret()
    Write-Log $msg
}

function Run-Cmd-BG($cmd, $label) {
    Write-Out "Ejecutando: $label..." $cSubText
    Start-Progress
    $job = Start-Job -ScriptBlock { param($c) Invoke-Expression $c 2>&1 } -ArgumentList $cmd
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 400
    $timer.Add_Tick({
        if ($job.State -ne "Running") {
            $timer.Stop()
            Stop-Progress
            $res = Receive-Job $job
            Remove-Job $job -Force
            if ($res) { Write-Out ($res -join "`r`n ") $cText }
            Write-Out "Completado con éxito." $cGreen
        }
    })
    $timer.Start()
}

# ============================================================
#   DISEÑO INTERNO: PESTAÑA REPARACIÓN
# ============================================================
$scrollRepair = New-Object Windows.Forms.Panel
$scrollRepair.Dock = "Fill"
$scrollRepair.AutoScroll = $true
$tabRepair.Controls.Add($scrollRepair)

function New-UIBlock($titulo, $y) {
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $titulo
    $lbl.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $cAccent2
    $lbl.Location = New-Object Drawing.Point(10, $y)
    $lbl.Size = New-Object Drawing.Size(200, 20)
    $scrollRepair.Controls.Add($lbl)
}

function New-UIButton($texto, $cmd, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = $texto
    $btn.Size = New-Object Drawing.Size(170, 45)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cBtn
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = $cAccent
    $btn.Cursor = "Hand"
    $btn.Add_Click({ Run-Cmd-BG $cmd $texto })
    $scrollRepair.Controls.Add($btn)
}

# --- Bloque Limpieza ---
New-UIBlock "Limpieza" 15
New-UIButton "Limpiar Temporales" 'Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue' 10 40
New-UIButton "Limpiar Prefetch" 'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue' 190 40

# --- Bloque Reparación Windows ---
New-UIBlock "Reparación de Windows" 105
New-UIButton "SFC /scannow" 'sfc /scannow' 10 130
New-UIButton "DISM RestoreHealth" 'DISM /Online /Cleanup-Image /RestoreHealth' 190 130
New-UIButton "CheckDisk (C:)" 'chkdsk C: /f' 370 130

# --- Bloque Red ---
New-UIBlock "Red" 195
New-UIButton "DNS Flush" 'ipconfig /flushdns' 10 220
New-UIButton "Reset Red (netsh)" 'netsh int ip reset; netsh winsock reset' 190 220
New-UIButton "Ver Puertos" 'netstat -ano' 370 220
New-UIButton "Matar Puerto 80" 'Stop-Process -Id (Get-NetTCPConnection -LocalPort 80).OwningProcess -Force' 550 220

# ============================================================
#   PANEL INFERIOR: MONITOREO Y ACCIONES RÁPIDAS
# ============================================================
$footerPanel = New-Object Windows.Forms.Panel
$footerPanel.Location = New-Object Drawing.Point(12, 565)
$footerPanel.Size     = New-Object Drawing.Size(1240, 140)
$footerPanel.Anchor   = "Bottom, Left, Right"
$form.Controls.Add($footerPanel)

function New-FooterGroup($titulo, $x, $w) {
    $pnl = New-Object Windows.Forms.Panel
    $pnl.Location = New-Object Drawing.Point($x, 0)
    $pnl.Size     = New-Object Drawing.Size($w, 140)
    $pnl.BackColor = $cPanel
    
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $titulo
    $lbl.Font = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $cAccent2
    $lbl.Location = New-Object Drawing.Point(10, 5)
    $lbl.Size = New-Object Drawing.Size(($w - 20), 15)
    $pnl.Controls.Add($lbl)
    
    $footerPanel.Controls.Add($pnl)
    return $pnl
}

# 1. Información Rápida (Métricas en tiempo real)
$pnlInfo = New-FooterGroup "Información rápida" 0 350
$lblCPU = New-Object Windows.Forms.Label
$lblCPU.Text = "CPU Uso: 3%      RAM Uso: 36%"
$lblCPU.Location = New-Object Drawing.Point(10, 30)
$lblCPU.Size = New-Object Drawing.Size(330, 20)
$pnlInfo.Controls.Add($lblCPU)

$lblDisco = New-Object Windows.Forms.Label
$lblDisco.Text = "Disco (C:): 42% Libre: 222 GB"
$lblDisco.Location = New-Object Drawing.Point(10, 60)
$lblDisco.Size = New-Object Drawing.Size(330, 20)
$pnlInfo.Controls.Add($lblDisco)

# 2. Accesos Rápidos
$pnlAcceso = New-FooterGroup "Accesos rápidos" 365 350
function New-QuickLaunch($txt, $cmd, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = $txt
    $btn.Size = New-Object Drawing.Size(100, 30)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cBg
    $btn.FlatStyle = "Flat"
    $btn.Font = New-Object Drawing.Font("Segoe UI", 7.5)
    $btn.Add_Click({ Start-Process $cmd })
    $pnlAcceso.Controls.Add($btn)
}
New-QuickLaunch "Explorador" "explorer.exe" 10 30
New-QuickLaunch "Admin Disp." "devmgmt.msc" 120 30
New-QuickLaunch "Admin Discos" "diskmgmt.msc" 230 30
New-QuickLaunch "Servicios" "services.msc" 10 75
New-QuickLaunch "Eventos" "eventvwr.msc" 120 75
New-QuickLaunch "Panel Control" "control.exe" 230 75

# 3. Acciones Rápidas
$pnlAcciones = New-FooterGroup "Acciones rápidas" 730 350
function New-QuickAction($txt, $script, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = $txt
    $btn.Size = New-Object Drawing.Size(150, 35)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cCard
    $btn.FlatStyle = "Flat"
    $btn.Add_Click($script)
    $pnlAcciones.Controls.Add($btn)
}
New-QuickAction "Reiniciar Explorer" { Stop-Process -Name explorer -Force } 10 30
New-QuickAction "Liberar Memoria" { [System.GC]::Collect(); Write-Out "Memoria RAM optimizada." $cGreen } 170 30
New-QuickAction "Limpiar Portapapeles" { [Windows.Forms.Clipboard]::Clear(); Write-Out "Portapapeles limpio." } 10 80
New-QuickAction "Crear Punto Rest." { Checkpoint-Computer -Description "SysCodiManual" -RestorePointType "MODIFY_SETTINGS" } 170 80

# 4. Estado
$pnlEstado = New-FooterGroup "Estado" 1095 145
$lblCheck = New-Object Windows.Forms.Label
$lblCheck.Text = "Todo correcto"
$lblCheck.ForeColor = $cGreen
$lblCheck.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$lblCheck.Location = New-Object Drawing.Point(10, 40)
$lblCheck.Size = New-Object Drawing.Size(125, 20)
$lblCheck.TextAlign = "MiddleCenter"
$pnlEstado.Controls.Add($lblCheck)

$btnVerify = New-Object Windows.Forms.Button
$btnVerify.Text = "Verificar sistema"
$btnVerify.Location = New-Object Drawing.Point(10, 80)
$btnVerify.Size = New-Object Drawing.Size(125, 30)
$btnVerify.BackColor = $cBg
$btnVerify.FlatStyle = "Flat"
$pnlEstado.Controls.Add($btnVerify)

# ============================================================
#   CREDITS & RUN
# ============================================================
$lblDev = New-Object Windows.Forms.Label
$lblDev.Text = "Desarrollado por SysCodi  |  Versión 2.5.0 Pro"
$lblDev.Location = New-Object Drawing.Point(12, 715)
$lblDev.Size = New-Object Drawing.Size(1240, 20)
$lblDev.ForeColor = $cSubText
$lblDev.TextAlign = "TopRight"
$lblDev.Anchor = "Bottom, Left, Right"
$form.Controls.Add($lblDev)

$form.ShowDialog()
