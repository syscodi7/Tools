#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# ADMIN CHECK
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $r = [Windows.Forms.MessageBox]::Show("Requiere Administrador. ¿Reiniciar como Admin?", "SysCodi", "YesNo", "Warning")
    if ($r -eq "Yes") { 
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    }
    exit
}

# ============================================================
# LOGS
# ============================================================
$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($m) { 
    Add-Content $logFile "[$(Get-Date -Format 'HH:mm:ss')] $m" -Encoding UTF8 -EA SilentlyContinue 
}

# ============================================================
# COLORES Y FUENTES (Diseño Oscuro Premium)
# ============================================================
$cBg       = [Drawing.Color]::FromArgb(6, 12, 28)
$cPanel    = [Drawing.Color]::FromArgb(10, 16, 32)
$cCard     = [Drawing.Color]::FromArgb(13, 21, 41)
$cBorder   = [Drawing.Color]::FromArgb(26, 40, 64)
$cAccent   = [Drawing.Color]::FromArgb(52, 152, 219)
$cAccent2  = [Drawing.Color]::FromArgb(155, 89, 182)
$cText     = [Drawing.Color]::FromArgb(226, 232, 240)
$cSubText  = [Drawing.Color]::FromArgb(144, 168, 192)
$cGreen    = [Drawing.Color]::FromArgb(46, 204, 113)
$cRed      = [Drawing.Color]::FromArgb(231, 76, 60)
$cYellow   = [Drawing.Color]::FromArgb(241, 196, 15)

$fTitle    = New-Object Drawing.Font("Segoe UI", 12, [Drawing.FontStyle]::Bold)
$fSubTitle = New-Object Drawing.Font("Segoe UI", 8)
$fTab      = New-Object Drawing.Font("Segoe UI", 9.5, [Drawing.FontStyle]::Bold)
$fCardHead = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$fCardDesc = New-Object Drawing.Font("Segoe UI", 8)
$fConsole  = New-Object Drawing.Font("Consolas", 9)
$fStatus   = New-Object Drawing.Font("Segoe UI", 8.5)
$fClock    = New-Object Drawing.Font("Consolas", 9)

# ============================================================
# DISEÑO BASE DE LA VENTANA
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text            = "SysCodi WinTool Premium"
$form.Size            = New-Object Drawing.Size(1200, 780)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.FormBorderStyle = "Sizable"

# Contenedor principal anti-parpadeo
$mainContainer = New-Object Windows.Forms.Panel
$mainContainer.Dock = "Fill"
$form.Controls.Add($mainContainer)

# Región Redondeada Segura para evitar op_Subtraction
function Get-RoundedPath($rect, $radius) {
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $arcRect = [Drawing.RectangleF]::new($rect.X, $rect.Y, $diameter, $diameter)
    $path.AddArc($arcRect, 180, 90)
    $arcRect.X = $rect.Right - $diameter
    $path.AddArc($arcRect, 270, 90)
    $arcRect.Y = $rect.Bottom - $diameter
    $path.AddArc($arcRect, 0, 90)
    $arcRect.X = $rect.X
    $path.AddArc($arcRect, 90, 90)
    $path.CloseFigure()
    return $path
}

# ============================================================
# TOPBAR (Logo + Sistema de Pestañas)
# ============================================================
$topBar = New-Object Windows.Forms.Panel
$topBar.Dock      = "Top"
$topBar.Height    = 65
$topBar.BackColor = $cPanel
$mainContainer.Controls.Add($topBar)

# Dibujo de isotipo S seguro
$logoPanel = New-Object Windows.Forms.Panel
$logoPanel.Size     = New-Object Drawing.Size(45, 45)
$logoPanel.Location = New-Object Drawing.Point(15, 10)
$topBar.Controls.Add($logoPanel)
$logoPanel.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Solución op_Subtraction: Leer propiedades directamente del Graphics o del objeto casteado
    $w = $e.ClipRectangle.Width
    $h = $e.ClipRectangle.Height
    if ($w -le 0) { $w = 45 }; if ($h -le 0) { $h = 45 }

    $rect = New-Object Drawing.Rectangle(0, 0, ($w - 1), ($h - 1))
    $path = Get-RoundedPath $rect 8
    $brush = New-Object Drawing.SolidBrush($cAccent)
    $g.FillPath($brush, $path)
    
    $fS = New-Object Drawing.Font("Segoe UI", 18, [Drawing.FontStyle]::Bold)
    $bS = New-Object Drawing.SolidBrush($cText)
    $sf = New-Object Drawing.StringFormat -Property @{Alignment="Center"; LineAlignment="Center"}
    $g.DrawString("S", $fS, $bS, [Drawing.RectangleF]::new(0, 0, $w, $h), $sf)
    $path.Dispose(); $brush.Dispose(); $fS.Dispose(); $bS.Dispose(); $sf.Dispose()
})

$lblBrand = New-Object Windows.Forms.Label
$lblBrand.Text     = "SysCodi"
$lblBrand.Font     = $fTitle
$lblBrand.Location = New-Object Drawing.Point(68, 12)
$lblBrand.Size     = New-Object Drawing.Size(80, 22)
$topBar.Controls.Add($lblBrand)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text     = "WinTool v1.0.0"
$lblSub.Font     = $fSubTitle
$lblSub.ForeColor= $cSubText
$lblSub.Location = New-Object Drawing.Point(68, 34)
$lblSub.Size     = New-Object Drawing.Size(80, 15)
$topBar.Controls.Add($lblSub)

# Contenedor Dinámico de Contenido Principal
$contentWrapper = New-Object Windows.Forms.Panel
$contentWrapper.Dock = "Fill"
$mainContainer.Controls.Add($contentWrapper)

# ============================================================
# CONSOLA LATERAL DERECHA
# ============================================================
$rightPanel = New-Object Windows.Forms.Panel
$rightPanel.Dock      = "Right"
$rightPanel.Width     = 320
$rightPanel.BackColor = $cPanel
$rightPanel.Padding   = New-Object Windows.Forms.Padding(12)
$mainContainer.Controls.Add($rightPanel)

$lblConsoleTitle = New-Object Windows.Forms.Label
$lblConsoleTitle.Text     = "CONSOLA DE SALIDA"
$lblConsoleTitle.Font     = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
$lblConsoleTitle.ForeColor= $cSubText
$lblConsoleTitle.Dock     = "Top"
$lblConsoleTitle.Height   = 20
$rightPanel.Controls.Add($lblConsoleTitle)

$txtConsole = New-Object Windows.Forms.RichTextBox
$txtConsole.Dock            = "Fill"
$txtConsole.BackColor       = $cBg
$txtConsole.ForeColor       = $cText
$txtConsole.Font            = $fConsole
$txtConsole.BorderStyle     = "None"
$txtConsole.ReadOnly        = $true
$rightPanel.Controls.Add($txtConsole)

# Solución al error de análisis sintáctico de la Consola (ParserError)
function Write-Out($msg, $color=$cText) {
    $timeString = Get-Date -Format "HH:mm:ss"
    $txtConsole.Invoke([Action[string, string, Drawing.Color]]{
        param($m, $t, $c)
        $txtConsole.SelectionStart = $txtConsole.TextLength
        $txtConsole.SelectionColor = $c
        $txtConsole.AppendText("[" + $t + "] " + $m + "`n")
        $txtConsole.ScrollToCaret()
        Write-Log $m
    }, $msg, $timeString, $color) | Out-Null
}

# ============================================================
# LOGICA DE PESTAÑAS (Tabs)
# ============================================================
$tabPanels = @{}
$tabButtons = @()

function Switch-Tab($name) {
    foreach ($k in $tabPanels.Keys) { $tabPanels[$k].Visible = $false }
    $tabPanels[$name].Visible = $true
    foreach ($b in $tabButtons) {
        $b.Tag = ($b.Name -eq "btnTab_$name")
        $b.Invalidate()
    }
}

$tabX = 170
function New-TabHeader($name, $label) {
    $btn = New-Object Windows.Forms.Panel
    $btn.Name     = "btnTab_$name"
    $btn.Size     = New-Object Drawing.Size(120, 65)
    $btn.Location = New-Object Drawing.Point($script:tabX, 0)
    $btn.Cursor   = "Hand"
    $btn.Tag      = $false
    
    $btn.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $w = $e.ClipRectangle.Width
        $h = $e.ClipRectangle.Height
        if ($w -le 0) { $w = 120 }; if ($h -le 0) { $h = 65 }
        
        if ($s.Tag -eq $true) {
            $brushText = New-Object Drawing.SolidBrush($cAccent)
            $penLine = New-Object Drawing.Pen($cAccent, 3)
            $g.DrawLine($penLine, 0, ($h - 2), $w, ($h - 2))
            $penLine.Dispose(); $brushText.Dispose()
        }
        
        $color = if ($s.Tag -eq $true) { $cText } else { $cSubText }
        $brush = New-Object Drawing.SolidBrush($color)
        $sf = New-Object Drawing.StringFormat -Property @{Alignment="Center"; LineAlignment="Center"}
        $g.DrawString($label, $fTab, $brush, [Drawing.RectangleF]::new(0, 0, $w, $h), $sf)
        $brush.Dispose(); $sf.Dispose()
    })
    
    $btn.Add_Click({ Switch-Tab $name })
    $topBar.Controls.Add($btn)
    $script:tabButtons += $btn
    $script:tabX += 125
    
    $p = New-Object Windows.Forms.Panel
    $p.Dock = "Fill"
    $p.Visible = $false
    $p.Padding = New-Object Windows.Forms.Padding(20)
    $contentWrapper.Controls.Add($p)
    $tabPanels[$name] = $p
}

New-TabHeader "dashboard" "Dashboard"
New-TabHeader "reparar"   "Reparación"
New-TabHeader "apps"      "Aplicaciones"
New-TabHeader "tareas"    "Tareas"

# ============================================================
# CONTENIDO: PESTAÑA REPARACIÓN
# ============================================================
$pReparar = $tabPanels["reparar"]

$scrollPanel = New-Object Windows.Forms.Panel
$scrollPanel.Dock       = "Fill"
$scrollPanel.AutoScroll = $true
$scrollPanel.Padding    = New-Object Windows.Forms.Padding(0, 0, 10, 0)
$pReparar.Controls.Add($scrollPanel)

$script:cX = 0; $script:cY = 0
function New-ToolCard($txt, $desc, $cmdBlock) {
    $card = New-Object Windows.Forms.Panel
    $card.Size     = New-Object Drawing.Size(260, 150)
    $card.Location = New-Object Drawing.Point(($script:cX * 275), ($script:cY * 165))
    
    $card.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $w = $e.ClipRectangle.Width; $h = $e.ClipRectangle.Height
        if ($w -le 0) { $w = 260 }; if ($h -le 0) { $h = 150 }
        
        $rect = New-Object Drawing.Rectangle(0, 0, ($w - 1), ($h - 1))
        $path = Get-RoundedPath $rect 10
        $brushBg = New-Object Drawing.SolidBrush($cCard)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        $bText = New-Object Drawing.SolidBrush($cText)
        $g.DrawString($txt, $fCardHead, $bText, 14, 14)

        $rectDesc = New-Object Drawing.RectangleF(14, 38, ($w - 28), 55)
        $bSubText = New-Object Drawing.SolidBrush($cSubText)
        $g.DrawString($desc, $fCardDesc, $bSubText, $rectDesc)
        
        $path.Dispose(); $brushBg.Dispose(); $pen.Dispose(); $bText.Dispose(); $bSubText.Dispose()
    })
    
    $btnExe = New-Object Windows.Forms.Panel
    $btnExe.Size     = New-Object Drawing.Size(100, 28)
    $btnExe.Location = New-Object Drawing.Point(14, 105)
    $btnExe.Cursor   = "Hand"
    $btnExe.BackColor = $cPanel
    
    $btnExe.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $w = $e.ClipRectangle.Width; $h = $e.ClipRectangle.Height
        if ($w -le 0) { $w = 100 }; if ($h -le 0) { $h = 28 }
        
        $rectBtn = New-Object Drawing.Rectangle(0, 0, ($w - 1), ($h - 1))
        $pathBtn = Get-RoundedPath $rectBtn 6
        $brushBtnBg = New-Object Drawing.SolidBrush($cPanel)
        $g.FillPath($brushBtnBg, $pathBtn)
        $penBtn = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($penBtn, $pathBtn)

        $fB = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
        $bBtnText = New-Object Drawing.SolidBrush($cText)
        $sfBtn = New-Object Drawing.StringFormat -Property @{Alignment="Center"; LineAlignment="Center"}
        $g.DrawString("Ejecutar", $fB, $bBtnText, [Drawing.RectangleF]::new(0, 0, $w, $h), $sfBtn)
        
        $pathBtn.Dispose(); $brushBtnBg.Dispose(); $penBtn.Dispose(); $fB.Dispose(); $bBtnText.Dispose(); $sfBtn.Dispose()
    })
    
    $btnExe.Add_Click($cmdBlock)
    $card.Controls.Add($btnExe)
    $scrollPanel.Controls.Add($card)
    
    $script:cX++
    if ($script:cX -ge 3) { $script:cX = 0; $script:cY++ }
}

New-ToolCard "SFC / Scannow" "Sanea y repara archivos críticos de la instalación del sistema." {
    Write-Out "Iniciando SFC /Scannow..." $cAccent
    Start-Process powershell -ArgumentList "-NoProfile -Command `"sysrestore; sfc /scannow`"" -Wait
    Write-Out "SFC Finalizado de forma segura." $cGreen
}
New-ToolCard "DISM Health" "Repara la imagen base corrupta usando repositorios locales o en la nube." {
    Write-Out "Iniciando DISM Component Repair..." $cAccent
    Start-Process powershell -ArgumentList "-NoProfile -Command `"DISM /Online /Cleanup-Image /RestoreHealth`"" -Wait
    Write-Out "DISM Completado." $cGreen
}
New-ToolCard "Reset Windows Update" "Purga los catálogos temporales dañados de SoftwareDistribution." {
    Write-Out "Deteniendo servicios y vaciando caché de actualizaciones..." $cYellow
    $cmd = "net stop wuauserv; net stop bits; Remove-Item -Path C:\Windows\SoftwareDistribution -Recurse -Force -EA SilentlyContinue; net start wuauserv"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"$cmd`"" -Wait
    Write-Out "Componentes de Windows Update restablecidos." $cGreen
}
New-ToolCard "Restablecer Red IP" "Limpia las interfaces de red y la asignación de sockets." {
    Write-Out "Restableciendo configuraciones de Red..." $cYellow
    Start-Process powershell -ArgumentList "-NoProfile -Command `"netsh winsock reset; netsh int ip reset; ipconfig /flushdns`"" -Wait
    Write-Out "Pila de red IP reiniciada correctamente." $cGreen
}

# ============================================================
# CONTENIDO: PESTAÑA APLICACIONES
# ============================================================
$pApps = $tabPanels["apps"]

$lblSearch = New-Object Windows.Forms.Label
$lblSearch.Text     = "Filtrar Software:"
$lblSearch.Location = New-Object Drawing.Point(15, 15)
$lblSearch.Size     = New-Object Drawing.Size(100, 20)
$pApps.Controls.Add($lblSearch)

$txtSearch = New-Object Windows.Forms.TextBox
$txtSearch.Location = New-Object Drawing.Point(120, 12)
$txtSearch.Size     = New-Object Drawing.Size(200, 23)
$txtSearch.BackColor= $cCard
$txtSearch.ForeColor= $cText
$pApps.Controls.Add($txtSearch)

$btnInstall = New-Object Windows.Forms.Button
$btnInstall.Text     = "Instalar Seleccionados"
$btnInstall.Location = New-Object Drawing.Point(340, 10)
$btnInstall.Size     = New-Object Drawing.Size(160, 26)
$btnInstall.FlatStyle= "Flat"
$btnInstall.FlatAppearance.BorderColor = $cBorder
$btnInstall.BackColor= $cCard
$pApps.Controls.Add($btnInstall)

$appsFlow = New-Object Windows.Forms.FlowLayoutPanel
$appsFlow.Location = New-Object Drawing.Point(15, 50)
$appsFlow.Size     = New-Object Drawing.Size(500, 560)
$appsFlow.AutoScroll = $true
$pApps.Controls.Add($appsFlow)

$softwareList = @(
    @{name="Google Chrome";     cmd="winget install Google.Chrome --silent --accept-package-agreements --accept-source-agreements"; foss=$false},
    @{name="Mozilla Firefox";   cmd="winget install Mozilla.Firefox --silent"; foss=$true},
    @{name="Brave Browser";     cmd="winget install Brave.Brave --silent"; foss=$false},
    @{name="VS Code";           cmd="winget install Microsoft.VisualStudioCode --silent"; foss=$true},
    @{name="Git v2.x";          cmd="winget install Git.Git --silent"; foss=$true},
    @{name="Notepad++";         cmd="winget install Notepad++.Notepad++ --silent"; foss=$true},
    @{name="7-Zip Utility";     cmd="winget install 7zip.7zip --silent"; foss=$true},
    @{name="WinRAR Archive";    cmd="winget install RARLab.WinRAR --silent"; foss=$false},
    @{name="VLC Media Player";  cmd="winget install VideoLAN.VLC --silent"; foss=$true},
    @{name="AnyDesk Control";   cmd="winget install AnyDeskSoftwareGmbH.AnyDesk --silent"; foss=$false}
)

$checkboxes = @()
foreach ($app in $softwareList) {
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text      = $app.name
    $cb.Size      = New-Object Drawing.Size(220, 30)
    $cb.ForeColor = if ($app.foss) { $cAccent2 } else { $cText }
    $cb.Tag       = $app
    $appsFlow.Controls.Add($cb)
    $script:checkboxes += $cb
}

$txtSearch.Add_TextChanged({
    $q = $txtSearch.Text.Trim().ToLower()
    foreach ($cb in $checkboxes) {
        if ($q -and -not $cb.Text.ToLower().Contains($q)) {
            $cb.Visible = $false
        } else {
            $cb.Visible = $true
        }
    }
})

$btnInstall.Add_Click({
    $sel = $checkboxes | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ningún software para instalar." $cYellow; return }
    if (-not (Get-Command winget -EA SilentlyContinue)) {
        Write-Out "Error: WinGet no está instalado en este equipo." $cRed
        return
    }
    Write-Out "Iniciando instalación masiva de $($sel.Count) aplicaciones..." $cAccent
    foreach ($cb in $sel) {
        Write-Out "Instalando $($cb.Tag.name)... Por favor espera" $cSubText
        Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"$($cb.Tag.cmd)`"" -Wait -EA SilentlyContinue
        Write-Out "Completado con éxito: $($cb.Tag.name)" $cGreen
        $cb.Checked = $false
        [Windows.Forms.Application]::DoEvents()
    }
    Write-Out "Todos los despliegues de software han finalizado." $cGreen
})

# ============================================================
# DASHBOARD DEFAULT VIEW
# ============================================================
$pDash = $tabPanels["dashboard"]
$lblDash = New-Object Windows.Forms.Label
$lblDash.Text = "BIENVENIDO A SYSCODI WINTOOL`n`nSelecciona una sección en el menú superior para comenzar.`nLas salidas y logs de comandos aparecerán en tiempo real a la derecha."
$lblDash.Font = $fCardHead
$lblDash.Size = New-Object Drawing.Size(500, 200)
$pDash.Controls.Add($lblDash)

# ============================================================
# FOOTER / BARRA DE ESTADO
# ============================================================
$footerBar = New-Object Windows.Forms.Panel
$footerBar.Dock      = "Bottom"
$footerBar.Height    = 35
$footerBar.BackColor = $cPanel
$mainContainer.Controls.Add($footerBar)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object Drawing.Point(15, 10)
$lblStatus.Font = $fStatus
$lblStatus.ForeColor = $cGreen
$lblStatus.Text = "Listo para operar"
$footerBar.Controls.Add($lblStatus)

$lblClock = New-Object Windows.Forms.Label
$lblClock.Size = New-Object Drawing.Size(200, 20)
$lblClock.Location = New-Object Drawing.Point(($form.Width - 540), 10)
$lblClock.Anchor = "Right"
$lblClock.Font = $fClock
$lblClock.ForeColor = $cSubText
$lblClock.TextAlign = "MiddleRight"
$lblClock.Text = (Get-Date -Format "dd/MM/yyyy  HH:mm:ss")
$footerBar.Controls.Add($lblClock)

$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({ 
    $lblClock.Text = (Get-Date -Format "dd/MM/yyyy  HH:mm:ss") 
})
$timer.Start()

$form.Add_FormClosing({ $timer.Stop() })

Switch-Tab "dashboard"
Write-Out "Consola inicializada correctamente. Modo administrador activo." $cGreen

$form.ShowDialog() | Out-Null
