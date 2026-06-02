#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# CONTROL DE ADMINISTRADOR
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $r = [Windows.Forms.MessageBox]::Show("Esta herramienta requiere privilegios de Administrador. ¿Deseas reiniciar?", "SysCodi - Privilegios", "YesNo", "Warning")
    if ($r -eq "Yes") { 
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    }
    exit
}

# Logs básicos
$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($m) { 
    Add-Content $logFile "[$(Get-Date -Format 'HH:mm:ss')] $m" -Encoding UTF8 -EA SilentlyContinue 
}

# ============================================================
# PALETA DE COLORES (Diseño Oscuro Premium)
# ============================================================
$cBgMain    = [Drawing.Color]::FromArgb(6, 12, 28) 
$cBgSide    = [Drawing.Color]::FromArgb(10, 16, 32) 
$cBgCard    = [Drawing.Color]::FromArgb(13, 21, 41) 
$cBgBtn     = [Drawing.Color]::FromArgb(10, 16, 32) 
$cAccent    = [Drawing.Color]::FromArgb(52, 152, 219) 
$cBorder    = [Drawing.Color]::FromArgb(26, 40, 64) 
$cText      = [Drawing.Color]::FromArgb(226, 232, 240) 
$cSubText   = [Drawing.Color]::FromArgb(144, 168, 192) 
$cGreen     = [Drawing.Color]::FromArgb(46, 204, 113)

# Fuentes seguras del sistema
$fTitle    = New-Object Drawing.Font("Segoe UI", 12, [Drawing.FontStyle]::Bold)
$fSubTitle = New-Object Drawing.Font("Segoe UI", 8)
$fMenu     = New-Object Drawing.Font("Segoe UI", 9)
$fCardHead = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$fCardDesc = New-Object Drawing.Font("Segoe UI", 8)
$fStatus   = New-Object Drawing.Font("Segoe UI", 8.5)
$fClock    = New-Object Drawing.Font("Consolas", 9)

# Formulario Principal
$form = New-Object Windows.Forms.Form
$form.Text            = "SysCodi WinTool"
$form.Size            = New-Object Drawing.Size(1200, 780)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBgMain
$form.ForeColor       = $cText
$form.FormBorderStyle = "Sizable"

# Contenedor para evitar el parpadeo
$mainContainer = New-Object Windows.Forms.Panel
$mainContainer.Dock = "Fill"
$mainContainer.Padding = New-Object Windows.Forms.Padding(0)
$form.Controls.Add($mainContainer)

# Helper para esquinas redondeadas sin fugas de memoria GDI
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
# SIDEBAR IZQUIERDO
# ============================================================
$sidePanel = New-Object Windows.Forms.Panel
$sidePanel.Dock      = "Left"
$sidePanel.Width     = 240
$sidePanel.BackColor = $cBgSide
$sidePanel.Padding   = New-Object Windows.Forms.Padding(16, 24, 16, 24)
$mainContainer.Controls.Add($sidePanel)

# Área del Logo S
$logoArea = New-Object Windows.Forms.Panel
$logoArea.Dock    = "Top"
$logoArea.Height  = 60
$sidePanel.Controls.Add($logoArea)

$logoArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object Drawing.Rectangle(0, 4, 38, 38)
    $path = Get-RoundedPath $rect 8
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(41, 128, 185))
    $g.FillPath($brush, $path)
    
    $fS = New-Object Drawing.Font("Segoe UI", 18, [Drawing.FontStyle]::Bold)
    $bS = New-Object Drawing.SolidBrush($cText)
    $sf = New-Object Drawing.StringFormat
    $sf.Alignment = "Center"
    $sf.LineAlignment = "Center"
    $g.DrawString("S", $fS, $bS, [Drawing.RectangleF]::new(0, 4, 38, 38), $sf)
    $path.Dispose(); $brush.Dispose(); $fS.Dispose(); $bS.Dispose(); $sf.Dispose()
})

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text      = "SysCodi WinTool"
$lblTitle.Location  = New-Object Drawing.Point(48, 6)
$lblTitle.Size      = New-Object Drawing.Size(170, 22)
$lblTitle.Font      = $fTitle
$lblTitle.ForeColor = $cText
$logoArea.Controls.Add($lblTitle)

$lblTitleSub = New-Object Windows.Forms.Label
$lblTitleSub.Text      = "Herramientas de Windows"
$lblTitleSub.Location  = New-Object Drawing.Point(48, 28)
$lblTitleSub.Size      = New-Object Drawing.Size(170, 20)
$lblTitleSub.Font      = $fSubTitle
$lblTitleSub.ForeColor = $cSubText
$logoArea.Controls.Add($lblTitleSub)

# Botones del Menú Lateral
function New-MenuBtn($txt, $icon, $selected = $false) {
    $btn = New-Object Windows.Forms.Panel
    $btn.Dock      = "Top"
    $btn.Height    = 44
    $btn.Cursor    = "Hand"
    $btn.Margin    = New-Object Windows.Forms.Padding(0, 4, 0, 4)
    $btn.Tag       = $selected
    
    $btn.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        if ($s.Tag -eq $true) {
            $brushBg = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(18, 28, 46))
            $g.FillRectangle($brushBg, (New-Object Drawing.Rectangle(0, 0, $s.Width, $s.Height)))
            $brushAcc = New-Object Drawing.SolidBrush($cAccent)
            $g.FillRectangle($brushAcc, (New-Object Drawing.Rectangle(0, 0, 4, $s.Height)))
            $brushBg.Dispose(); $brushAcc.Dispose()
        }

        $colorTxt = if($s.Tag -eq $true){$cText}else{$cSubText}
        $bT = New-Object Drawing.SolidBrush($colorTxt)
        $g.DrawString($txt, $fMenu, $bT, 20, 14)
        $bT.Dispose()
    })
    
    $sidePanel.Controls.Add($btn)
    $btn.BringToFront()
}

New-MenuBtn "Ajustes"
New-MenuBtn "Reportes"
New-MenuBtn "Aplicaciones"
New-MenuBtn "Tareas"
New-MenuBtn "Reparacion" $true
New-MenuBtn "Dashboard"

# ============================================================
# CUERPO PRINCIPAL DE CONTENIDO
# ============================================================
$contentPanel = New-Object Windows.Forms.Panel
$contentPanel.Dock      = "Fill"
$contentPanel.BackColor = $cBgMain
$contentPanel.Padding   = New-Object Windows.Forms.Padding(24, 16, 24, 16)
$mainContainer.Controls.Add($contentPanel)
$contentPanel.BringToFront()

# Encabezado de la sección
$headerArea = New-Object Windows.Forms.Panel
$headerArea.Dock      = "Top"
$headerArea.Height    = 75
$contentPanel.Controls.Add($headerArea)

$headerArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    $fT = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
    $bT = New-Object Drawing.SolidBrush($cText)
    $g.DrawString("Reparacion de Sistema", $fT, $bT, 0, 4)

    $fD = New-Object Drawing.Font("Segoe UI", 9)
    $bD = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("Herramientas avanzadas para optimizar, reparar y solucionar inconsistencias en Windows.", $fD, $bD, 0, 40)
    
    $fT.Dispose(); $bT.Dispose(); $fD.Dispose(); $bD.Dispose()
})

# Tarjetas superiores de Estado / Información
$statusArea = New-Object Windows.Forms.Panel
$statusArea.Dock      = "Top"
$statusArea.Height    = 75
$contentPanel.Controls.Add($statusArea)

function New-InfoBlock($txt, $subTxt, $x) {
    $block = New-Object Windows.Forms.Panel
    $block.Location = New-Object Drawing.Point($x, 0)
    $block.Size     = New-Object Drawing.Size(220, 60)
    $block.BackColor = $cBgCard
    
    $block.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $rect = New-Object Drawing.Rectangle(0, 0, $s.Width-1, $s.Height-1)
        $path = Get-RoundedPath $rect 8
        $brushBg = New-Object Drawing.SolidBrush($cBgCard)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        $fT = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
        $bT = New-Object Drawing.SolidBrush($cText)
        $g.DrawString($txt, $fT, $bT, 16, 12)

        $fS = New-Object Drawing.Font("Segoe UI", 8)
        $bS = New-Object Drawing.SolidBrush($cSubText)
        $g.DrawString($subTxt, $fS, $bS, 16, 30)
        
        $path.Dispose(); $brushBg.Dispose(); $pen.Dispose(); $fT.Dispose(); $bT.Dispose(); $fS.Dispose(); $bS.Dispose()
    })
    $statusArea.Controls.Add($block)
}

# Obtención de datos reales del sistema
$os = Get-CimInstance Win32_OperatingSystem
$uptimeSpan = (Get-Date) - $os.LastBootUpTime
$uptimeStr = "$($uptimeSpan.Days)d $($uptimeSpan.Hours)h $($uptimeSpan.Minutes)m"

New-InfoBlock "Windows 11 Pro" "Build $($os.BuildNumber)" 0
New-InfoBlock $env:COMPUTERNAME $env:USERNAME 235
New-InfoBlock "Tiempo Activo" $uptimeStr 470

# ============================================================
# PANEL DE SCROLL CON TARJETAS DE HERRAMIENTAS
# ============================================================
$scrollPanel = New-Object Windows.Forms.Panel
$scrollPanel.Dock       = "Fill"
$scrollPanel.AutoScroll = $true
$scrollPanel.Padding    = New-Object Windows.Forms.Padding(0, 0, 20, 0)
$contentPanel.Controls.Add($scrollPanel)
$scrollPanel.BringToFront()

$script:cX = 0; $script:cY = 0

function New-ToolCard($txt, $desc, $cmdBlock) {
    $card = New-Object Windows.Forms.Panel
    $card.Size     = New-Object Drawing.Size(280, 150)
    
    $posX = $script:cX * 295
    $posY = $script:cY * 165
    $card.Location = New-Object Drawing.Point($posX, $posY)
    
    $card.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $rect = New-Object Drawing.Rectangle(0, 0, $s.Width-1, $s.Height-1)
        $path = Get-RoundedPath $rect 10
        $brushBg = New-Object Drawing.SolidBrush($cBgCard)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        $bText = New-Object Drawing.SolidBrush($cText)
        $g.DrawString($txt, $fCardHead, $bText, 16, 16)

        $rectDesc = New-Object Drawing.RectangleF(16, 42, 248, 55)
        $bSubText = New-Object Drawing.SolidBrush($cSubText)
        $g.DrawString($desc, $fCardDesc, $bSubText, $rectDesc)
        
        $path.Dispose(); $brushBg.Dispose(); $pen.Dispose(); $bText.Dispose(); $bSubText.Dispose()
    })
    
    $btnExe = New-Object Windows.Forms.Panel
    $btnExe.Size     = New-Object Drawing.Size(110, 30)
    $btnExe.Location = New-Object Drawing.Point(16, 104)
    $btnExe.Cursor   = "Hand"
    $btnExe.BackColor = $cBgBtn
    
    $btnExe.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $rectBtn = New-Object Drawing.Rectangle(0, 0, $s.Width-1, $s.Height-1)
        $pathBtn = Get-RoundedPath $rectBtn 6
        $brushBtnBg = New-Object Drawing.SolidBrush($cBgBtn)
        $g.FillPath($brushBtnBg, $pathBtn)
        $penBtn = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($penBtn, $pathBtn)

        $fB = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
        $bBtnText = New-Object Drawing.SolidBrush($cText)
        $sfBtn = New-Object Drawing.StringFormat
        $sfBtn.Alignment = "Center"
        $sfBtn.LineAlignment = "Center"
        $g.DrawString("Ejecutar", $fB, $bBtnText, [Drawing.RectangleF]::new(0, 0, $s.Width, $s.Height), $sfBtn)
        
        $pathBtn.Dispose(); $brushBtnBg.Dispose(); $penBtn.Dispose(); $fB.Dispose(); $bBtnText.Dispose(); $sfBtn.Dispose()
    })
    
    $btnExe.Add_Click($cmdBlock)
    $card.Controls.Add($btnExe)
    $scrollPanel.Controls.Add($card)
    
    $script:cX++
    if ($script:cX -ge 3) { 
        $script:cX = 0 
        $script:cY++ 
    }
}

# Declaración limpia de módulos de ejecución
New-ToolCard "SFC / Scannow" "Verifica y repara archivos dañados o ausentes del ecosistema Windows." {
    Write-Log "Ejecutando SFC"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"sfc /scannow; pause`""
}

New-ToolCard "DISM RestoreHealth" "Repara y descarga imágenes limpias del sistema operativo mediante Windows Update." {
    Write-Log "Ejecutando DISM"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"DISM /Online /Cleanup-Image /RestoreHealth; pause`""
}

New-ToolCard "Restablecer Windows Update" "Detiene y limpia el repositorio corrupto de SoftwareDistribution." {
    Write-Log "Restableciendo actualizaciones"
    $cmd = "net stop wuauserv; net stop bits; Remove-Item -Path C:\Windows\SoftwareDistribution -Recurse -Force -EA SilentlyContinue; net start wuauserv; pause"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"$cmd`""
}

New-ToolCard "Restablecer Red" "Limpia de raíz la pila de sockets e interfaces de red IP locales." {
    Write-Log "Reset de Red"
    $cmd = "netsh winsock reset; netsh int ip reset; ipconfig /release; ipconfig /renew; pause"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"$cmd`""
}

New-ToolCard "Limpiar DNS" "Vacía el caché local de resolución de nombres DNS." {
    Write-Log "Flush DNS"
    Clear-DnsClientCache -EA SilentlyContinue
    ipconfig /flushdns | Out-Null
    [Windows.Forms.MessageBox]::Show("Cache DNS purgado de forma exitosa.", "SysCodi")
}

New-ToolCard "CheckDisk (C:)" "Sanea y repara sectores físicos corruptos en la unidad principal." {
    Write-Log "CHKDSK Programado"
    Start-Process cmd -ArgumentList "/c echo Y | chkdsk C: /f /r"
    [Windows.Forms.MessageBox]::Show("Análisis de disco duro programado para el próximo reinicio de hardware.", "SysCodi")
}

# ============================================================
# BARRA DE ESTADO / FOOTER (Separada del Reloj)
# ============================================================
$footerBar = New-Object Windows.Forms.Panel
$footerBar.Dock      = "Bottom"
$footerBar.Height    = 35
$footerBar.BackColor = $cBgSide
$footerBar.Padding   = New-Object Windows.Forms.Padding(24, 0, 24, 0)
$mainContainer.Controls.Add($footerBar)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.AutoSize = $true
$lblStatus.Location = New-Object Drawing.Point(12, 10)
$lblStatus.Font = $fStatus
$lblStatus.ForeColor = $cGreen
$lblStatus.Text = "Sistema funcionando correctamente"
$footerBar.Controls.Add($lblStatus)

$lblClock = New-Object Windows.Forms.Label
$lblClock.Size = New-Object Drawing.Size(200, 20)
$lblClock.Location = New-Object Drawing.Point(($footerBar.Width - 210), 10)
$lblClock.Anchor = "Right"
$lblClock.Font = $fClock
$lblClock.ForeColor = $cSubText
$lblClock.TextAlign = "MiddleRight"
$lblClock.Text = (Get-Date -Format "dd/MM/yyyy  HH:mm:ss")
$footerBar.Controls.Add($lblClock)

# Timer dedicado exclusivamente al reloj (Evita invalidaciones recursivas pesadas)
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({ 
    $lblClock.Text = (Get-Date -Format "dd/MM/yyyy  HH:mm:ss") 
})
$timer.Start()

$form.Add_FormClosing({ $timer.Stop() })
$form.ShowDialog() | Out-Null
