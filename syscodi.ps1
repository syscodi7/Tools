#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#   VERIFICACION DE ADMINISTRADOR
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
#   COLORES CORPORATIVOS (Fieles a la imagen)
# ============================================================
$cBg       = [Drawing.Color]::FromArgb(13, 23, 43)
$cPanel    = [Drawing.Color]::FromArgb(18, 32, 62)
$cCard     = [Drawing.Color]::FromArgb(24, 42, 82)
$cAccent   = [Drawing.Color]::FromArgb(0, 102, 204)
$cAccent2  = [Drawing.Color]::FromArgb(0, 180, 255)
$cGreen    = [Drawing.Color]::FromArgb(0, 210, 130)
$cRed      = [Drawing.Color]::FromArgb(255, 80, 80)
$cText     = [Drawing.Color]::White
$cSubText  = [Drawing.Color]::FromArgb(140, 175, 225)
$cBtn      = [Drawing.Color]::FromArgb(14, 46, 92)
$cOutput   = [Drawing.Color]::FromArgb(8, 16, 32)

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

# ============================================================
#   HEADER (Superior completo)
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Size      = New-Object Drawing.Size(1264, 75)
$header.Location  = New-Object Drawing.Point(0, 0)
$header.BackColor = $cBg
$header.Anchor    = "Top, Left, Right"
$form.Controls.Add($header)

# Simbología del Logo (Cuadrado Azul)
$logoBox = New-Object Windows.Forms.Panel
$logoBox.Location = New-Object Drawing.Point(18, 15)
$logoBox.Size     = New-Object Drawing.Size(45, 45)
$logoBox.BackColor = $cAccent
$header.Controls.Add($logoBox)

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text     = "SysCodi WinTool Pro"
$lblTitle.Font     = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cText
$lblTitle.Location = New-Object Drawing.Point(75, 10)
$lblTitle.Size     = New-Object Drawing.Size(350, 35)
$header.Controls.Add($lblTitle)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text      = "Utilidad de sistema avanzada para Windows"
$lblSub.Font      = New-Object Drawing.Font("Segoe UI", 9.5)
$lblSub.ForeColor = $cSubText
$lblSub.Location  = New-Object Drawing.Point(78, 45)
$lblSub.Size      = New-Object Drawing.Size(400, 20)
$header.Controls.Add($lblSub)

# Meta Datos del Sistema (Superior Derecha)
$lblSysInfo = New-Object Windows.Forms.Label
$lblSysInfo.Text      = "Windows 11 Pro 23H2 (22631.3527)`r`nUsuario: syscodi              Tiempo activo: 0d 2h 15m`r`nEquipo: DESKTOP-7H5K2Q1     Fecha: 24/05/2025 12:38:45"
$lblSysInfo.Font      = New-Object Drawing.Font("Segoe UI", 9)
$lblSysInfo.ForeColor = $cSubText
$lblSysInfo.Location  = New-Object Drawing.Point(720, 15)
$lblSysInfo.Size      = New-Object Drawing.Size(520, 50)
$lblSysInfo.TextAlign = "TopRight"
$lblSysInfo.Anchor    = "Top, Right"
$header.Controls.Add($lblSysInfo)

# ============================================================
#   TABS DE NAVEGACIÓN (Diseño de Botones Planos en Fila)
# ============================================================
$navPanel = New-Object Windows.Forms.Panel
$navPanel.Location = New-Object Drawing.Point(18, 85)
$navPanel.Size     = New-Object Drawing.Size(1228, 40)
$navPanel.Anchor   = "Top, Left, Right"
$form.Controls.Add($navPanel)

$tabTitles = @("Reparación", "Aplicaciones", "Tweaks", "Utilidades", "Transferencia", "Sistema", "Dashboard", "Reportes", "Ajustes")
$currentX = 0
foreach ($title in $tabTitles) {
    $btnTab = New-Object Windows.Forms.Button
    $btnTab.Text = "   $title"
    $btnTab.Size = New-Object Drawing.Size(130, 35)
    $btnTab.Location = New-Object Drawing.Point($currentX, 0)
    $btnTab.FlatStyle = "Flat"
    $btnTab.Font = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
    $btnTab.ForeColor = if ($title -eq "Reparación") { $cText } else { $cSubText }
    $btnTab.BackColor = if ($title -eq "Reparación") { $cBtn } else { $cBg }
    $btnTab.FlatAppearance.BorderColor = if ($title -eq "Reparación") { $cAccent } else { $cPanel }
    $navPanel.Controls.Add($btnTab)
    $currentX += 135
}

# ============================================================
#   PANEL PRINCIPAL CONTENEDOR (Izquierda: Acciones de Reparación)
# ============================================================
$mainContent = New-Object Windows.Forms.Panel
$mainContent.Location = New-Object Drawing.Point(18, 140)
$mainContent.Size     = New-Object Drawing.Size(740, 390)
$mainContent.BackColor = $cBg
$mainContent.Anchor   = "Top, Left, Bottom, Right"
$form.Controls.Add($mainContent)

function New-ToolBlock($titulo, $y, $w=740, $h=100) {
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $titulo
    $lbl.Font = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $cAccent2
    $lbl.Location = New-Object Drawing.Point(0, $y)
    $lbl.Size = New-Object Drawing.Size(200, 20)
    $mainContent.Controls.Add($lbl)

    # Línea divisoria sutil
    $line = New-Object Windows.Forms.Panel
    $line.Location = New-Object Drawing.Point(0, $y + 22)
    $line.Size = New-Object Drawing.Size(740, 1)
    $line.BackColor = [Drawing.Color]::FromArgb(40, 60, 100)
    $mainContent.Controls.Add($line)
}

function New-ActionButton($texto, $cmd, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = "      $texto"
    $btn.TextAlign = "MiddleLeft"
    $btn.Size = New-Object Drawing.Size(180, 45)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cBtn
    $btn.FlatStyle = "Flat"
    $btn.Font = New-Object Drawing.Font("Segoe UI", 9.5)
    $btn.FlatAppearance.BorderColor = $cPanel
    $btn.Cursor = "Hand"
    $btn.Add_Click({ Run-Cmd-BG $cmd $texto })
    $mainContent.Controls.Add($btn)
}

# --- Sección Limpieza ---
New-ToolBlock "Limpieza" 5
New-ActionButton "Limpiar Temporales" 'Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue' 0 35
New-ActionButton "Limpiar Prefetch" 'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue' 195 35

# --- Sección Reparación de Windows ---
New-ToolBlock "Reparación de Windows" 100
New-ActionButton "SFC /scannow" 'sfc /scannow' 0 130
New-ActionButton "DISM RestoreHealth" 'DISM /Online /Cleanup-Image /RestoreHealth' 195 130
New-ActionButton "CheckDisk (C:)" 'chkdsk C: /f' 390 130

# --- Sección Red ---
New-ToolBlock "Red" 195
New-ActionButton "DNS Flush" 'ipconfig /flushdns' 0 225
New-ActionButton "Reset Red (netsh)" 'netsh int ip reset' 195 225
New-ActionButton "Ver Puertos" 'netstat -ano' 390 225
New-ActionButton "Matar Puerto 80" 'Stop-Process -Id (Get-NetTCPConnection -LocalPort 80).OwningProcess -Force' 585 225

# ============================================================
#   PANEL DERECHO - CONSOLA DE SALIDA
# ============================================================
$rightPanel = New-Object Windows.Forms.Panel
$rightPanel.Location  = New-Object Drawing.Point(775, 140)
$rightPanel.Size      = New-Object Drawing.Size(470, 390)
$rightPanel.BackColor = $cOutput
$rightPanel.Anchor    = "Top, Right, Bottom"
$form.Controls.Add($rightPanel)

$pnlConHeader = New-Object Windows.Forms.Panel
$pnlConHeader.Location  = New-Object Drawing.Point(0, 0)
$pnlConHeader.Size      = New-Object Drawing.Size(470, 32)
$pnlConHeader.BackColor = $cPanel
$rightPanel.Controls.Add($pnlConHeader)

$lblConsole = New-Object Windows.Forms.Label
$lblConsole.Text      = "Consola de salida"
$lblConsole.Location  = New-Object Drawing.Point(10, 0)
$lblConsole.Size      = New-Object Drawing.Size(200, 32)
$lblConsole.ForeColor = $cAccent2
$lblConsole.Font      = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
$lblConsole.TextAlign = "MiddleLeft"
$pnlConHeader.Controls.Add($lblConsole)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location    = New-Object Drawing.Point(15, 45)
$outputBox.Size        = New-Object Drawing.Size(440, 330)
$outputBox.BackColor   = $cOutput
$outputBox.ForeColor   = $cAccent2
$outputBox.Font        = New-Object Drawing.Font("Consolas", 10)
$outputBox.ReadOnly    = $true
$outputBox.BorderStyle = "None"
$outputBox.ScrollBars  = "Vertical"
$outputBox.Anchor      = "Top,Left,Bottom,Right"
$outputBox.Text        = "Listo. Selecciona una opción y ejecuta."
$rightPanel.Controls.Add($outputBox)

function Run-Cmd-BG($cmd, $label) {
    $outputBox.Text = "Ejecutando: $label..."
    $job = Start-Job -ScriptBlock { param($c) Invoke-Expression $c 2>&1 } -ArgumentList $cmd
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 400
    $timer.Add_Tick({
        if ($job.State -ne "Running") {
            $timer.Stop()
            $res = Receive-Job $job
            Remove-Job $job -Force
            $outputBox.Text = if ($res) { $res -join "`r`n" } else { "Completado con éxito." }
        }
    })
    $timer.Start()
}

# ============================================================
#   PANEL INFERIOR COMPLETO (Estructura de Bloques del Footer)
# ============================================================
$footerPanel = New-Object Windows.Forms.Panel
$footerPanel.Location = New-Object Drawing.Point(18, 545)
$footerPanel.Size     = New-Object Drawing.Size(1228, 145)
$footerPanel.Anchor   = "Bottom, Left, Right"
$form.Controls.Add($footerPanel)

function New-FooterCard($titulo, $x, $w) {
    $pnl = New-Object Windows.Forms.Panel
    $pnl.Location = New-Object Drawing.Point($x, 0)
    $pnl.Size     = New-Object Drawing.Size($w, 135)
    $pnl.BackColor = $cBg
    
    # Borde sutil superior/lateral simulando contenedor
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $titulo
    $lbl.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $cAccent2
    $lbl.Location = New-Object Drawing.Point(0, 0)
    $lbl.Size = New-Object Drawing.Size($w, 20)
    $pnl.Controls.Add($lbl)
    
    $footerPanel.Controls.Add($pnl)
    return $pnl
}

# 1. Información Rápida (Métricas en tiempo real)
$cardInfo = New-FooterCard "Información rápida" 0 300
$lblCPU = New-Object Windows.Forms.Label
$lblCPU.Text = "CPU Uso            3%`r`nRAM Uso          36%"
$lblCPU.Font = New-Object Drawing.Font("Segoe UI", 9.5)
$lblCPU.Location = New-Object Drawing.Point(5, 25)
$lblCPU.Size = New-Object Drawing.Size(280, 40)
$cardInfo.Controls.Add($lblCPU)

$lblDsk = New-Object Windows.Forms.Label
$lblDsk.Text = "Disco (C:)        42%   Libre: 222 GB`r`nRed                 0.0 Mbps"
$lblDsk.Font = New-Object Drawing.Font("Segoe UI", 9.5)
$lblDsk.Location = New-Object Drawing.Point(5, 75)
$lblDsk.Size = New-Object Drawing.Size(280, 40)
$cardInfo.Controls.Add($lblDsk)

# 2. Accesos Rápidos (Botones pequeños alineados en grilla)
$cardLaunch = New-FooterCard "Accesos rápidos" 320 380
function New-GridLaunch($txt, $cmd, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = "  $txt"
    $btn.TextAlign = "MiddleLeft"
    $btn.Size = New-Object Drawing.Size(115, 32)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cBtn
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = $cPanel
    $btn.Font = New-Object Drawing.Font("Segoe UI", 8.5)
    $btn.Add_Click({ Start-Process $cmd })
    $cardLaunch.Controls.Add($btn)
}
New-GridLaunch "Explorador" "explorer.exe" 0 25
New-GridLaunch "Admin. disp." "devmgmt.msc" 125 25
New-GridLaunch "Administración`nde discos" "diskmgmt.msc" 250 25
New-GridLaunch "Servicios" "services.msc" 0 75
New-GridLaunch "Eventos" "eventvwr.msc" 125 75
New-GridLaunch "Panel de control" "control.exe" 250 75

# 3. Acciones Rápidas
$cardActions = New-FooterCard "Acciones rápidas" 720 300
function New-GridAction($txt, $script, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = $txt
    $btn.Size = New-Object Drawing.Size(135, 35)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cBtn
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = $cPanel
    $btn.Font = New-Object Drawing.Font("Segoe UI", 8.5)
    $btn.Add_Click($script)
    $cardActions.Controls.Add($btn)
}
New-GridAction "Reiniciar Explorer" { Stop-Process -Name explorer -Force } 0 25
New-GridAction "Liberar memoria" { [System.GC]::Collect() } 145 25
New-GridAction "Limpiar`nPortapapeles" { [Windows.Forms.Clipboard]::Clear() } 0 75
New-GridAction "Crear Punto de`nRestauración" { Checkpoint-Computer -Description "SysCodiManual" } 145 75

# 4. Estado (Lado derecho inferior)
$cardStatus = New-FooterCard "Estado" 1040 180
$lblStatusText = New-Object Windows.Forms.Label
$lblStatusText.Text = "Todo correcto"
$lblStatusText.ForeColor = $cGreen
$lblStatusText.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$lblStatusText.Location = New-Object Drawing.Point(0, 30)
$lblStatusText.Size = New-Object Drawing.Size(180, 25)
$lblStatusText.TextAlign = "MiddleCenter"
$cardStatus.Controls.Add($lblStatusText)

$btnVerify = New-Object Windows.Forms.Button
$btnVerify.Text = "Verificar sistema"
$btnVerify.Size = New-Object Drawing.Size(140, 35)
$btnVerify.Location = New-Object Drawing.Point(20, 65)
$btnVerify.BackColor = $cBtn
$btnVerify.FlatStyle = "Flat"
$btnVerify.FlatAppearance.BorderColor = $cAccent
$cardStatus.Controls.Add($btnVerify)

# ============================================================
#   BARRA DE PIE DE PÁGINA (Créditos)
# ============================================================
$footerBar = New-Object Windows.Forms.Panel
$footerBar.Location = New-Object Drawing.Point(0, 700)
$footerBar.Size     = New-Object Drawing.Size(1264, 25)
$footerBar.Anchor   = "Bottom, Left, Right"
$form.Controls.Add($footerBar)

$lblWarn = New-Object Windows.Forms.Label
$lblWarn.Text = " Ejecutar siempre como Administrador para mejor rendimiento"
$lblWarn.Font = New-Object Drawing.Font("Segoe UI", 8.5)
$lblWarn.ForeColor = $cSubText
$lblWarn.Location = New-Object Drawing.Point(18, 0)
$lblWarn.Size = New-Object Drawing.Size(400, 20)
$footerBar.Controls.Add($lblWarn)

$lblDev = New-Object Windows.Forms.Label
$lblDev.Text = "Desarrollado por SysCodi      Versión 2.5.0 Pro "
$lblDev.Font = New-Object Drawing.Font("Segoe UI", 8.5)
$lblDev.ForeColor = $cSubText
$lblDev.Location = New-Object Drawing.Point(840, 0)
$lblDev.Size = New-Object Drawing.Size(400, 20)
$lblDev.TextAlign = "TopRight"
$footerBar.Controls.Add($lblDev)

# Desplegar la interfaz
$form.ShowDialog()
