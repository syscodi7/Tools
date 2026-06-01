#Requires -Version 5.1
# Asegurar codificación UTF-8 para evitar caracteres rotos (Ã³)
[console]::InputEncoding = [System.Text.Encoding]::UTF8
[console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
#   PALETA DE COLORES ULTRA-FIEL (Muestreado de tu diseño)
# ============================================================
$cBg       = [Drawing.Color]::FromArgb(6, 14, 28)       # Fondo oscuro profundo
$cPanel    = [Drawing.Color]::FromArgb(10, 26, 51)     # Fondos secundarios
$cCard     = [Drawing.Color]::FromArgb(12, 34, 68)     # Fondo de botones y bloques
$cAccent   = [Drawing.Color]::FromArgb(0, 102, 204)    # Azul brillante (Logo/Bordes)
$cAccent2  = [Drawing.Color]::FromArgb(0, 180, 255)    # Azul cielo para títulos
$cGreen    = [Drawing.Color]::FromArgb(0, 210, 130)    # Verde Estado
$cText     = [Drawing.Color]::FromArgb(240, 245, 255)  # Texto brillante
$cSubText  = [Drawing.Color]::FromArgb(115, 145, 185)  # Texto secundario/meta

# Determinar fuente de iconos nativa de Windows (Fluent en Win11, MDL2 en Win10)
$iconFontName = if ((Get-CimInstance Win32_OperatingSystem).Caption -like "*Windows 11*") { "Segoe Fluent Icons" } else { "Segoe MDL2 Assets" }

# ============================================================
#   FORMULARIO PRINCIPAL STYLED
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text          = "SysCodi WinTool Pro"
$form.Size          = New-Object Drawing.Size(1240, 810)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBg
$form.ForeColor     = $cText
$form.Font          = New-Object Drawing.Font("Segoe UI", 9.5)
$form.FormBorderStyle = "Sizable"

# ============================================================
#   COMPONENTE HEADER
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Size      = New-Object Drawing.Size(1240, 85)
$header.Location  = New-Object Drawing.Point(0, 0)
$header.Anchor    = "Top, Left, Right"
$form.Controls.Add($header)

# Icono de Logo Estilizado (S)
$logoLabel = New-Object Windows.Forms.Label
$logoLabel.Text     = [char]0xE756 # Icono nativo de Red/Sistema adaptado como isotipo
$logoLabel.Font     = New-Object Drawing.Font($iconFontName, 26)
$logoLabel.ForeColor = $cAccent2
$logoLabel.Location = New-Object Drawing.Point(20, 18)
$logoLabel.Size     = New-Object Drawing.Size(50, 50)
$header.Controls.Add($logoLabel)

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text     = "SysCodi WinTool Pro"
$lblTitle.Font     = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cText
$lblTitle.Location = New-Object Drawing.Point(75, 12)
$lblTitle.Size     = New-Object Drawing.Size(400, 42)
$header.Controls.Add($lblTitle)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text      = "Utilidad de sistema avanzada para Windows"
$lblSub.Font      = New-Object Drawing.Font("Segoe UI", 10)
$lblSub.ForeColor = $cSubText
$lblSub.Location  = New-Object Drawing.Point(78, 52)
$lblSub.Size      = New-Object Drawing.Size(400, 20)
$header.Controls.Add($lblSub)

# Metadatos Superior Derecha
$lblSysInfo = New-Object Windows.Forms.Label
$lblSysInfo.Text      = "Windows 11 Pro 23H2 (22631.3527)      Tiempo activo: 0d 2h 15m`r`nUsuario: syscodi                                    Fecha: 24/05/2025 12:38:45`r`nEquipo: DESKTOP-7H5K2Q1"
$lblSysInfo.Font      = New-Object Drawing.Font("Segoe UI", 9)
$lblSysInfo.ForeColor = $cSubText
$lblSysInfo.Location  = New-Object Drawing.Point(680, 18)
$lblSysInfo.Size      = New-Object Drawing.Size(530, 60)
$lblSysInfo.TextAlign = "TopRight"
$lblSysInfo.Anchor    = "Top, Right"
$header.Controls.Add($lblSysInfo)

# ============================================================
#   MENÚ DE PESTAÑAS ESTILIZADO (Fila Superior)
# ============================================================
$navPanel = New-Object Windows.Forms.Panel
$navPanel.Location = New-Object Drawing.Point(20, 95)
$navPanel.Size     = New-Object Drawing.Size(1190, 42)
$navPanel.Anchor   = "Top, Left, Right"
$form.Controls.Add($navPanel)

$tabsData = @(
    @("Reparación", 0xE74C), @("Aplicaciones", 0xE179), @("Tweaks", 0xE713),
    @("Utilidades", 0xE115), @("Transferencia", 0xE895), @("Sistema", 0xE770),
    @("Dashboard", 0xE9D2),  @("Reportes", 0xE9F9),     @("Ajustes", 0xE713)
)

$currentX = 0
foreach ($tab in $tabsData) {
    $btnTab = New-Object Windows.Forms.Button
    $btnTab.Text = "  " + [char]$tab[1] + "  " + $tab[0]
    $btnTab.Size = New-Object Drawing.Size(125, 36)
    $btnTab.Location = New-Object Drawing.Point($currentX, 0)
    $btnTab.FlatStyle = "Flat"
    $btnTab.Font = New-Object Drawing.Font($iconFontName, 9.5)
    
    if ($tab[0] -eq "Reparación") {
        $btnTab.Font = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
        $btnTab.BackColor = $cCard
        $btnTab.ForeColor = $cText
        $btnTab.FlatAppearance.BorderColor = $cAccent
    } else {
        $btnTab.BackColor = $cBg
        $btnTab.ForeColor = $cSubText
        $btnTab.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(25, 45, 75)
    }
    $navPanel.Controls.Add($btnTab)
    $currentX += 130
}

# ============================================================
#   CONTENEDOR DE HERRAMIENTAS (Izquierda) con bordes de diseño
# ============================================================
$mainContent = New-Object Windows.Forms.Panel
$mainContent.Location = New-Object Drawing.Point(20, 155)
$mainContent.Size     = New-Object Drawing.Size(710, 400)
$mainContent.Anchor   = "Top, Left, Bottom, Right"
$form.Controls.Add($mainContent)

function New-DesignSection($titulo, $y) {
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $titulo
    $lbl.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $cAccent2
    $lbl.Location = New-Object Drawing.Point(0, $y)
    $lbl.Size = New-Object Drawing.Size(200, 20)
    $mainContent.Controls.Add($lbl)

    $line = New-Object Windows.Forms.Panel
    $line.Location = New-Object Drawing.Point(0, $y + 22)
    $line.Size = New-Object Drawing.Size(710, 1)
    $line.BackColor = [Drawing.Color]::FromArgb(25, 55, 95)
    $line.Anchor = "Top, Left, Right"
    $mainContent.Controls.Add($line)
}

function New-GridButton($texto, $iconCode, $cmd, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    # Combinar el Icono Fluent/MDL2 con el texto de manera elegante
    $btn.Text = "   " + [char]$iconCode + "    " + $texto
    $btn.TextAlign = "MiddleLeft"
    $btn.Size = New-Object Drawing.Size(165, 42)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cCard
    $btn.FlatStyle = "Flat"
    $btn.Font = New-Object Drawing.Font($iconFontName, 9.5)
    $btn.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(25, 55, 95)
    $btn.Cursor = "Hand"
    $btn.Add_Click({ Run-Cmd-BG $cmd $texto })
    $mainContent.Controls.Add($btn)
}

# --- Bloques de Operaciones ---
New-DesignSection "Limpieza" 5
New-GridButton "Limpiar Temporales" 0xE74D 'Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue' 0 35
New-GridButton "Limpiar Prefetch" 0xE149 'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue' 175 35

New-DesignSection "Reparación de Windows" 100
New-GridButton "SFC /scannow" 0xE73A 'sfc /scannow' 0 130
New-GridButton "DISM RestoreHealth" 0xE7B3 'DISM /Online /Cleanup-Image /RestoreHealth' 175 130
New-GridButton "CheckDisk (C:)" 0xE770 'chkdsk C: /f' 350 130

New-DesignSection "Red" 195
New-GridButton "DNS Flush" 0xE12B 'ipconfig /flushdns' 0 225
New-GridButton "Reset Red (netsh)" 0xE17B 'netsh int ip reset' 175 225
New-GridButton "Ver Puertos" 0xEA37 'netstat -ano' 350 225
New-GridButton "Matar Puerto 80" 0xE74E 'Stop-Process -Id (Get-NetTCPConnection -LocalPort 80).OwningProcess -Force' 525 225

# ============================================================
#   CONSOLA DE SALIDA ESTILIZADA (Derecha)
# ============================================================
$rightPanel = New-Object Windows.Forms.Panel
$rightPanel.Location  = New-Object Drawing.Point(745, 155)
$rightPanel.Size      = New-Object Drawing.Size(465, 400)
$rightPanel.BackColor = $cOutput
$rightPanel.Anchor    = "Top, Right, Bottom"
$form.Controls.Add($rightPanel)

# Header interno de consola con borde inferior
$pnlConHeader = New-Object Windows.Forms.Panel
$pnlConHeader.Location  = New-Object Drawing.Point(0, 0)
$pnlConHeader.Size      = New-Object Drawing.Size(465, 32)
$pnlConHeader.BackColor = $cBg
$rightPanel.Controls.Add($pnlConHeader)

$lblConsole = New-Object Windows.Forms.Label
$lblConsole.Text      = "Consola de salida"
$lblConsole.Location  = New-Object Drawing.Point(5, 0)
$lblConsole.Size      = New-Object Drawing.Size(200, 32)
$lblConsole.ForeColor = $cAccent2
$lblConsole.Font      = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$lblConsole.TextAlign = "MiddleLeft"
$pnlConHeader.Controls.Add($lblConsole)

$lineConsole = New-Object Windows.Forms.Panel
$lineConsole.Location = New-Object Drawing.Point(0, 31)
$lineConsole.Size = New-Object Drawing.Size(465, 1)
$lineConsole.BackColor = $cAccent
$pnlConHeader.Controls.Add($lineConsole)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location    = New-Object Drawing.Point(15, 45)
$outputBox.Size        = New-Object Drawing.Size(435, 340)
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
    $outputBox.Text = "Ejecutando: $label... Por favor espere."
    $job = Start-Job -ScriptBlock { param($c) Invoke-Expression $c 2>&1 } -ArgumentList $cmd
    $timer = New-Object Windows.Forms.Timer
    $timer.Interval = 400
    $timer.Add_Tick({
        if ($job.State -ne "Running") {
            $timer.Stop()
            $res = Receive-Job $job
            Remove-Job $job -Force
            $outputBox.Text = if ($res) { ($res -join "`r`n") } else { "Completado con éxito." }
        }
    })
    $timer.Start()
}

# ============================================================
#   PANEL INFERIOR CARDS COMPLETOS (Footer Modular)
# ============================================================
$footerPanel = New-Object Windows.Forms.Panel
$footerPanel.Location = New-Object Drawing.Point(20, 570)
$footerPanel.Size     = New-Object Drawing.Size(1190, 160)
$footerPanel.Anchor   = "Bottom, Left, Right"
$form.Controls.Add($footerPanel)

function New-FooterContainer($titulo, $x, $w) {
    $pnl = New-Object Windows.Forms.Panel
    $pnl.Location = New-Object Drawing.Point($x, 0)
    $pnl.Size     = New-Object Drawing.Size($w, 145)
    $pnl.BackColor = $cBg
    
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $titulo
    $lbl.Font = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $cAccent2
    $lbl.Location = New-Object Drawing.Point(0, 0)
    $lbl.Size = New-Object Drawing.Size($w, 20)
    $pnl.Controls.Add($lbl)
    
    $footerPanel.Controls.Add($pnl)
    return $pnl
}

# 1. Info Rápida
$cardInfo = New-FooterContainer "Información rápida" 0 280
$lblCPU = New-Object Windows.Forms.Label
$lblCPU.Text = "   " + [char]0xE9D2 + "  CPU Uso             3%`r`n`r`n   " + [char]0xE7F1 + "  RAM Uso           36%`r`n`r`n   " + [char]0xE770 + "  Disco (C:)         42%   Libre: 222 GB`r`n`r`n   " + [char]0xE704 + "  Red                  0.0 Mbps"
$lblCPU.Font = New-Object Drawing.Font($iconFontName, 9.5)
$lblCPU.ForeColor = $cText
$lblCPU.Location = New-Object Drawing.Point(0, 25)
$lblCPU.Size = New-Object Drawing.Size(280, 120)
$cardInfo.Controls.Add($lblCPU)

# 2. Accesos Rápidos
$cardLaunch = New-FooterContainer "Accesos rápidos" 300 370
function New-FooterLaunchBtn($txt, $icon, $cmd, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = " " + [char]$icon + "  " + $txt
    $btn.TextAlign = "MiddleLeft"
    $btn.Size = New-Object Drawing.Size(115, 34)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cCard
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(25, 45, 75)
    $btn.Font = New-Object Drawing.Font($iconFontName, 8.5)
    $btn.Add_Click({ Start-Process $cmd })
    $cardLaunch.Controls.Add($btn)
}
New-FooterLaunchBtn "Explorador" 0xE8B7 "explorer.exe" 0 25
New-FooterLaunchBtn "Admin. disp." 0xE772 "devmgmt.msc" 120 25
New-FooterLaunchBtn "Admin. discos" 0xE7C1 "diskmgmt.msc" 240 25
New-FooterLaunchBtn "Servicios" 0xE71D "services.msc" 0 75
New-FooterLaunchBtn "Eventos" 0xE7BA "eventvwr.msc" 120 75
New-FooterLaunchBtn "Panel control" 0xE713 "control.exe" 240 75

# 3. Acciones Rápidas
$cardActions = New-FooterContainer "Acciones rápidas" 690 320
function New-FooterActionBtn($txt, $icon, $script, $x, $y) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text = " " + [char]$icon + "  " + $txt
    $btn.TextAlign = "MiddleLeft"
    $btn.Size = New-Object Drawing.Size(145, 34)
    $btn.Location = New-Object Drawing.Point($x, $y)
    $btn.BackColor = $cCard
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(25, 45, 75)
    $btn.Font = New-Object Drawing.Font($iconFontName, 8.5)
    $btn.Add_Click($script)
    $cardActions.Controls.Add($btn)
}
New-FooterActionBtn "Reiniciar Explorer" 0xE149 { Stop-Process -Name explorer -Force } 0 25
New-FooterActionBtn "Liberar memoria" 0xE815 { [System.GC]::Collect() } 155 25
New-FooterActionBtn "Limpiar Portapap." 0xE74D { [Windows.Forms.Clipboard]::Clear() } 0 75
New-FooterActionBtn "Crear Punto Rest." 0xE74E { Checkpoint-Computer -Description "SysCodiManual" } 155 75

# 4. Estado Card Superior Derecho
$cardStatus = New-FooterContainer "Estado" 1030 160
$lblStatusText = New-Object Windows.Forms.Label
$lblStatusText.Text = [char]0xE73E + "`r`nTodo correcto"
$lblStatusText.ForeColor = $cGreen
$lblStatusText.Font = New-Object Drawing.Font($iconFontName, 10, [Drawing.FontStyle]::Bold)
$lblStatusText.Location = New-Object Drawing.Point(0, 22)
$lblStatusText.Size = New-Object Drawing.Size(160, 45)
$lblStatusText.TextAlign = "MiddleCenter"
$cardStatus.Controls.Add($lblStatusText)

$btnVerify = New-Object Windows.Forms.Button
$btnVerify.Text = "Verificar sistema"
$btnVerify.Size = New-Object Drawing.Size(130, 34)
$btnVerify.Location = New-Object Drawing.Point(15, 75)
$btnVerify.BackColor = $cCard
$btnVerify.FlatStyle = "Flat"
$btnVerify.FlatAppearance.BorderColor = $cAccent
$cardStatus.Controls.Add($btnVerify)

# ============================================================
#   PIE DE PÁGINA FINAL (Créditos)
# ============================================================
$lblWarn = New-Object Windows.Forms.Label
$lblWarn.Text = [char]0xE7BA + " Ejecutar siempre como Administrador para mejor rendimiento"
$lblWarn.Font = New-Object Drawing.Font($iconFontName, 8.5)
$lblWarn.ForeColor = $cSubText
$lblWarn.Location = New-Object Drawing.Point(20, 745)
$lblWarn.Size = New-Object Drawing.Size(450, 20)
$form.Controls.Add($lblWarn)

$lblDev = New-Object Windows.Forms.Label
$lblDev.Text = "Desarrollado por SysCodi      Versión 2.5.0 Pro"
$lblDev.Font = New-Object Drawing.Font("Segoe UI", 8.5)
$lblDev.ForeColor = $cSubText
$lblDev.Location = New-Object Drawing.Point(810, 745)
$lblDev.Size = New-Object Drawing.Size(400, 20)
$lblDev.TextAlign = "TopRight"
$form.Controls.Add($lblDev)

# Inicializar y Dibujar Formulario sin parpadeos
$form.ShowDialog()
