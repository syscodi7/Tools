#Requires -Version 5.1

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $r = [Windows.Forms.MessageBox]::Show("Esta herramienta requiere privilegios de Administrador. ¿Deseas reiniciar como Administrador?", "SysCodi - Privilegios", "YesNo", "Warning")
    if ($r -eq "Yes") { 
        Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs 
    }
    exit
}

$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($m) { 
    Add-Content $logFile "[$(Get-Date -Format 'HH:mm:ss')] $m" -Encoding UTF8 -EA SilentlyContinue 
}

$cBgMain    = [Drawing.Color]::FromArgb(6, 12, 28) 
$cBgSide    = [Drawing.Color]::FromArgb(10, 16, 32) 
$cBgCard    = [Drawing.Color]::FromArgb(13, 21, 41) 
$cBgBtn     = [Drawing.Color]::FromArgb(10, 16, 32) 
$cAccent    = [Drawing.Color]::FromArgb(52, 152, 219) 
$cBorder    = [Drawing.Color]::FromArgb(26, 40, 64) 
$cText      = [Drawing.Color]::FromArgb(226, 232, 240) 
$cSubText   = [Drawing.Color]::FromArgb(144, 168, 192) 
$cGreen     = [Drawing.Color]::FromArgb(46, 204, 113)

$fTitle    = New-Object Drawing.Font("Segoe UI", 12, [Drawing.FontStyle]::Bold)
$fSubTitle = New-Object Drawing.Font("Segoe UI", 8)
$fMenu     = New-Object Drawing.Font("Segoe UI", 9)
$fCardHead = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$fCardDesc = New-Object Drawing.Font("Segoe UI", 8)
$fStatus   = New-Object Drawing.Font("Segoe UI", 8.5)
$fClock    = New-Object Drawing.Font("Consolas", 9)

$form = New-Object Windows.Forms.Form
$form.Text          = "SysCodi WinTool"
$form.Size          = New-Object Drawing.Size(1200, 780)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBgMain
$form.ForeColor     = $cText
$form.FormBorderStyle = "Sizable"

$mainPadding = New-Object Windows.Forms.Padding(16)
$mainContainer = New-Object Windows.Forms.Panel
$mainContainer.Dock = "Fill"
$mainContainer.Padding = $mainPadding
$form.Controls.Add($mainContainer)

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

$sidePanel = New-Object Windows.Forms.Panel
$sidePanel.Dock      = "Left"
$sidePanel.Width     = 220
$sidePanel.BackColor = $cBgSide
$sidePanel.Padding   = New-Object Windows.Forms.Padding(16, 24, 16, 24)
$mainContainer.Controls.Add($sidePanel)

$logoArea = New-Object Windows.Forms.Panel
$logoArea.Dock    = "Top"
$logoArea.Height  = 60
$sidePanel.Controls.Add($logoArea)

$logoArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $rect = New-Object Drawing.Rectangle(0, 0, 40, 40)
    $path = Get-RoundedPath $rect 8
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(41, 128, 185))
    $g.FillPath($brush, $path)
    
    $fS = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
    $bS = New-Object Drawing.SolidBrush($cText)
    $sf = New-Object Drawing.StringFormat
    $sf.Alignment = "Center"
    $sf.LineAlignment = "Center"
    $rectF = New-Object Drawing.RectangleF(0, 0, 40, 40)
    $g.DrawString("S", $fS, $bS, $rectF, $sf)
})

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text      = "SysCodi WinTool"
$lblTitle.Location  = New-Object Drawing.Point(52, 2)
$lblTitle.Size      = New-Object Drawing.Size(150, 22)
$lblTitle.Font      = $fTitle
$lblTitle.ForeColor = $cText
$logoArea.Controls.Add($lblTitle)

$lblTitleSub = New-Object Windows.Forms.Label
$lblTitleSub.Text      = "Herramientas esenciales para Windows"
$lblTitleSub.Location  = New-Object Drawing.Point(52, 24)
$lblTitleSub.Size      = New-Object Drawing.Size(150, 30)
$lblTitleSub.Font      = $fSubTitle
$lblTitleSub.ForeColor = $cSubText
$logoArea.Controls.Add($lblTitleSub)

$menuButtons = @()
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
        
        $w = $s.Width - 1
        $h = $s.Height - 1
        $rect = New-Object Drawing.Rectangle(0, 0, $w, $h)
        
        if ($s.Tag -eq $true) {
            $brushBg = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(18, 28, 46))
            $g.FillRectangle($brushBg, $rect)
            $brushAcc = New-Object Drawing.SolidBrush($cAccent)
            $g.FillRectangle($brushAcc, (New-Object Drawing.Rectangle(0, 0, 4, $s.Height)))
        }

        $colorIcon = if($s.Tag -eq $true){$cAccent}else{$cSubText}
        $bI = New-Object Drawing.SolidBrush($colorIcon)
        $fI = New-Object Drawing.Font("Segoe UI", 12)
        $g.DrawString($icon, $fI, $bI, 12, 10)

        $colorText = if($s.Tag -eq $true){$cText}else{$cSubText}
        $bT = New-Object Drawing.SolidBrush($colorText)
        $g.DrawString($txt, $fMenu, $bT, 40, 12)
    })
    
    $sidePanel.Controls.Add($btn)
    $btn.BringToFront()
    $script:menuButtons += $btn
}

New-MenuBtn "Ajustes"      "⚙"
New-MenuBtn "Reportes"     "📄"
New-MenuBtn "Aplicaciones" "⬡"
New-MenuBtn "Tareas"       "📋"
New-MenuBtn "Reparación"   "🛡" $true
New-MenuBtn "Dashboard"    "🏠"

$spacer = New-Object Windows.Forms.Panel
$spacer.Dock = "Top"
$spacer.Height = 20
$sidePanel.Controls.Add($spacer)
$spacer.BringToFront()

$versionArea = New-Object Windows.Forms.Panel
$versionArea.Dock    = "Bottom"
$versionArea.Height  = 40
$sidePanel.Controls.Add($versionArea)

$versionArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    $rect = New-Object Drawing.Rectangle(0, 10, 24, 24)
    $path = Get-RoundedPath $rect 6
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(41, 128, 185))
    $g.FillPath($brush, $path)

    $fS = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
    $bS = New-Object Drawing.SolidBrush($cText)
    $sf = New-Object Drawing.StringFormat
    $sf.Alignment = "Center"
    $sf.LineAlignment = "Center"
    $rectF = New-Object Drawing.RectangleF(0, 10, 24, 24)
    $g.DrawString("S", $fS, $bS, $rectF, $sf)

    $fV = New-Object Drawing.Font("Segoe UI", 7.5)
    $bT = New-Object Drawing.SolidBrush($cText)
    $bSub = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("SysCodi WinTool", $fV, $bT, 32, 12)
    $g.DrawString("Versión 1.0.0", $fV, $bSub, 32, 24)
})

$contentPanel = New-Object Windows.Forms.Panel
$contentPanel.Dock      = "Fill"
$contentPanel.BackColor = $cBgMain
$contentPanel.Padding   = New-Object Windows.Forms.Padding(24, 0, 0, 0)
$mainContainer.Controls.Add($contentPanel)
$contentPanel.BringToFront()

$headerArea = New-Object Windows.Forms.Panel
$headerArea.Dock      = "Top"
$headerArea.Height    = 100
$contentPanel.Controls.Add($headerArea)

$headerArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    $fI = New-Object Drawing.Font("Segoe UI", 28)
    $bI = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("🛡️", $fI, $bI, 0, 10)

    $fT = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
    $bT = New-Object Drawing.SolidBrush($cText)
    $g.DrawString("Reparación", $fT, $bT, 60, 15)

    $fD = New-Object Drawing.Font("Segoe UI", 9)
    $bD = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("Herramientas para reparar y solucionar problemas comunes del sistema.", $fD, $bD, 60, 50)
})

$statusArea = New-Object Windows.Forms.Panel
$statusArea.Dock      = "Top"
$statusArea.Height    = 70
$statusArea.Padding   = New-Object Windows.Forms.Padding(0, 0, 0, 10)
$contentPanel.Controls.Add($statusArea)

function New-InfoBlock($txt, $subTxt, $icon, $x) {
    $block = New-Object Windows.Forms.Panel
    $block.Location = New-Object Drawing.Point($x, 0)
    $block.Size     = New-Object Drawing.Size(220, 60)
    $block.BackColor = $cBgCard
    
    $block.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $w = $s.Width - 1
        $h = $s.Height - 1
        $rect = New-Object Drawing.Rectangle(0, 0, $w, $h)
        
        $path = Get-RoundedPath $rect 8
        $brushBg = New-Object Drawing.SolidBrush($cBgCard)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        $fI = New-Object Drawing.Font("Segoe UI", 16)
        $bI = New-Object Drawing.SolidBrush($cAccent)
        $g.DrawString($icon, $fI, $bI, 15, 15)

        $fT = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
        $bT = New-Object Drawing.SolidBrush($cText)
        $g.DrawString($txt, $fT, $bT, 50, 15)

        $fS = New-Object Drawing.Font("Segoe UI", 8)
        $bS = New-Object Drawing.SolidBrush($cSubText)
        $g.DrawString($subTxt, $fS, $bS, 50, 32)
    })
    $statusArea.Controls.Add($block)
}

$os = Get-CimInstance Win32_OperatingSystem
$uptimeSpan = (Get-Date) - $os.LastBootUpTime
$uptimeStr = "$($uptimeSpan.Days)d $($uptimeSpan.Hours)h $($uptimeSpan.Minutes)m"

New-InfoBlock "Tiempo activo" $uptimeStr "🕒" 460
New-InfoBlock $env:COMPUTERNAME $env:USERNAME "👤" 230
New-InfoBlock "Windows 11 Pro" "23H2 (22631.3527)" "🪟" 0

$filterBar = New-Object Windows.Forms.Panel
$filterBar.Dock      = "Top"
$filterBar.Height    = 40
$contentPanel.Controls.Add($filterBar)

$script:fX = 0
function New-FilterBtn($txt, $icon, $selected = $false) {
    $btn = New-Object Windows.Forms.Panel
    $btn.Location = New-Object Drawing.Point($script:fX, 0)
    $btn.Size     = New-Object Drawing.Size(120, 32)
    $btn.Cursor   = "Hand"
    $btn.Tag      = $selected
    
    $btn.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $w = $s.Width - 1
        $h = $s.Height - 1
        $rect = New-Object Drawing.Rectangle(0, 0, $w, $h)
        
        if ($s.Tag -eq $true) {
            $path = Get-RoundedPath $rect 6
            $brushBg = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(31, 51, 84))
            $g.FillPath($brushBg, $path)
        }

        $fT = New-Object Drawing.Font("Segoe UI", 8.5)
        $bT = New-Object Drawing.SolidBrush($cText)
        $sf = New-Object Drawing.StringFormat
        $sf.Alignment = "Center"
        $sf.LineAlignment = "Center"
        $rectF = New-Object Drawing.RectangleF(0, 0, $s.Width, $s.Height)
        $g.DrawString(("$icon  $txt"), $fT, $bT, $rectF, $sf)
    })
    
    $filterBar.Controls.Add($btn)
    $script:fX += 125
}

New-FilterBtn "Avanzado"       "⚙"
New-FilterBtn "Windows Update" "🔁"
New-FilterBtn "Seguridad"      "🛡️"
New-FilterBtn "Disco"          "💾"
New-FilterBtn "Red"            "🌐"
New-FilterBtn "Sistema"        "💻"
New-FilterBtn "Todo"           "📋" $true

$scrollPanel = New-Object Windows.Forms.Panel
$scrollPanel.Dock       = "Fill"
$scrollPanel.AutoScroll = $true
$scrollPanel.Padding    = New-Object Windows.Forms.Padding(0, 10, 10, 10)
$contentPanel.Controls.Add($scrollPanel)
$scrollPanel.BringToFront()

$script:cX = 0; $script:cY = 0; $script:count = 0

function New-ToolCard($txt, $desc, $icon, $cmdBlock) {
    $card = New-Object Windows.Forms.Panel
    $card.Size     = New-Object Drawing.Size(300, 160)
    
    $posX = $script:cX * 315
    $posY = $script:cY * 175
    $card.Location = New-Object Drawing.Point($posX, $posY)
    
    $card.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $w = $s.Width - 1
        $h = $s.Height - 1
        $rect = New-Object Drawing.Rectangle(0, 0, $w, $h)
        
        $path = Get-RoundedPath $rect 10
        $brushBg = New-Object Drawing.SolidBrush($cBgCard)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        $brushCircle = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(26, 40, 64))
        $g.FillEllipse($brushCircle, 20, 20, 40, 40)
        
        $fI = New-Object Drawing.Font("Segoe UI", 16)
        $bI = New-Object Drawing.SolidBrush($cAccent)
        $sf = New-Object Drawing.StringFormat
        $sf.Alignment = "Center"
        $sf.LineAlignment = "Center"
        $rectIcon = New-Object Drawing.RectangleF(20, 20, 40, 40)
        $g.DrawString($icon, $fI, $bI, $rectIcon, $sf)

        $bText = New-Object Drawing.SolidBrush($cText)
        $g.DrawString($txt, $fCardHead, $bText, 75, 22)

        $rectDesc = New-Object Drawing.RectangleF(75, 45, 210, 60)
        $bSubText = New-Object Drawing.SolidBrush($cSubText)
        $g.DrawString($desc, $fCardDesc, $bSubText, $rectDesc)
    })
    
    $btnExe = New-Object Windows.Forms.Panel
    $btnExe.Size     = New-Object Drawing.Size(120, 30)
    $btnExe.Location = New-Object Drawing.Point(75, 110)
    $btnExe.Cursor   = "Hand"
    $btnExe.BackColor = $cBgBtn
    
    $btnExe.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        
        $wB = $s.Width - 1
        $hB = $s.Height - 1
        $rectBtn = New-Object Drawing.Rectangle(0, 0, $wB, $hB)
        
        $pathBtn = Get-RoundedPath $rectBtn 6
        $brushBtnBg = New-Object Drawing.SolidBrush($cBgBtn)
        $g.FillPath($brushBtnBg, $pathBtn)
        $penBtn = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($penBtn, $pathBtn)

        $fB = New-Object Drawing.Font("Segoe UI", 8.5)
        $bBtnText = New-Object Drawing.SolidBrush($cText)
        $sfBtn = New-Object Drawing.StringFormat
        $sfBtn.Alignment = "Center"
        $sfBtn.LineAlignment = "Center"
        $rectBtnF = New-Object Drawing.RectangleF(0, 0, $s.Width, $s.Height)
        $g.DrawString("Ejecutar", $fB, $bBtnText, $rectBtnF, $sfBtn)
    })
    
    $btnExe.Add_Click($cmdBlock)
    $card.Controls.Add($btnExe)
    $scrollPanel.Controls.Add($card)
    
    $script:count++
    $script:cX++
    if ($script:cX -ge 3) { 
        $script:cX = 0 
        $script:cY++ 
    }
}

New-ToolCard "SFC / Scannow" "Verifica y repara archivos de sistema protegidos de Windows." "🛡️" {
    Write-Log "Ejecutando SFC Scannow"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"sfc /scannow`"" -Wait
}

New-ToolCard "DISM RestoreHealth" "Repara la imagen del sistema usando DISM." "⚙️" {
    Write-Log "Ejecutando DISM RestoreHealth"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"DISM /Online /Cleanup-Image /RestoreHealth`"" -Wait
}

New-ToolCard "Restablecer Windows Update" "Restaura los componentes de Windows Update." "🔁" {
    Write-Log "Restableciendo servicios de Windows Update"
    $cmd = "net stop wuauserv; net stop cryptSvc; net stop bits; net stop msiserver; Remove-Item -Path C:\Windows\SoftwareDistribution -Recurse -Force -EA SilentlyContinue; net start wuauserv"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"$cmd`"" -Wait
}

New-ToolCard "Restablecer Red" "Restablece la configuración de red a los valores predeterminados." "🌐" {
    Write-Log "Restableciendo pila de red"
    $cmd = "netsh winsock reset; netsh int ip reset; ipconfig /release; ipconfig /renew"
    Start-Process powershell -ArgumentList "-NoProfile -Command `"$cmd`"" -Wait
}

New-ToolCard "Limpiar DNS" "Limpia la caché del DNS para solucionar problemas de conexión." "🌐" {
    Write-Log "Vaciando cache DNS"
    Clear-DnsClientCache -EA SilentlyContinue
    ipconfig /flushdns | Out-Null
    [Windows.Forms.MessageBox]::Show("Caché DNS limpia correctamente.", "SysCodi")
}

New-ToolCard "CheckDisk (C:)" "Busca y repara errores en la unidad seleccionada." "💾" {
    Write-Log "Programando CHKDSK en C:"
    Start-Process cmd -ArgumentList "/c echo Y | chkdsk C: /f /r" -Wait
    [Windows.Forms.MessageBox]::Show("Escaneo programado para el próximo reinicio.", "SysCodi")
}

New-ToolCard "Inicio Avanzado" "Abre las opciones avanzadas de inicio de Windows." "🪟" {
    Write-Log "Lanzando reinicio a entorno de recuperación WinRE"
    Start-Process shutdown -ArgumentList "/r /o /t 5"
}

New-ToolCard "Reparar Store" "Repara problemas relacionados con Microsoft Store." "🛒" {
    Write-Log "Restableciendo Microsoft Store"
    Start-Process wsreset.exe -Wait
}

$footerBar = New-Object Windows.Forms.Panel
$footerBar.Dock      = "Bottom"
$footerBar.Height    = 30
$footerBar.BackColor = $cBgMain
$footerBar.Padding   = New-Object Windows.Forms.Padding(220, 0, 0, 0)
$mainContainer.Controls.Add($footerBar)

# Separación del Reloj en un control independiente para evitar invalidaciones infinitas en cascada
$lblClock = New-Object Windows.Forms.Label
$lblClock.AutoSize = $false
$lblClock.Size = New-Object Drawing.Size(180, 20)
$lblClock.Location = New-Object Drawing.Point(980, 5)
$lblClock.Font = $fClock
$lblClock.ForeColor = $cSubText
$lblClock.TextAlign = "MiddleRight"
$lblClock.Text = (Get-Date -Format "dd/MM/yyyy  HH:mm:ss")
$footerBar.Controls.Add($lblClock)

$footerBar.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    $pen = New-Object Drawing.Pen($cBorder, 1)
    $g.DrawLine($pen, 240, 0, $s.Width, 0)

    $bG = New-Object Drawing.SolidBrush($cGreen)
    $g.DrawString("✔", $fStatus, $bG, 240, 5)
    
    $bT = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("Sistema funcionando correctamente", $fStatus, $bT, 260, 5)
})

$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({ 
    # Actualiza exclusivamente el texto del Label en lugar de redibujar todo el panel
    $lblClock.Text = (Get-Date -Format "dd/MM/yyyy  HH:mm:ss") 
})
$timer.Start()

$form.Add_FormClosing({ $timer.Stop() })
$form.ShowDialog() | Out-Null
