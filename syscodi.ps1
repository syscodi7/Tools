#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# ADMIN CHECK
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $r = [Windows.Forms.MessageBox]::Show("Requiere Administrador. Reiniciar como Admin?","SysCodi","YesNo","Warning")
    if ($r -eq "Yes") { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs }
    exit
}

# ============================================================
# LOGS
# ============================================================
$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($m) { Add-Content $logFile "[$(Get-Date -Format 'HH:mm:ss')] $m" -Encoding UTF8 -EA SilentlyContinue }

# ============================================================
# COLORES (nuevo diseño oscuro moderno)
# ============================================================
$cBg       = [Drawing.Color]::FromArgb(13,  17,  23)
$cPanel    = [Drawing.Color]::FromArgb(10,  16,  32)
$cCard     = [Drawing.Color]::FromArgb(17,  25,  39)
$cCardHov  = [Drawing.Color]::FromArgb(22,  32,  48)
$cBorder   = [Drawing.Color]::FromArgb(26,  40,  64)
$cAccent   = [Drawing.Color]::FromArgb(25,  118, 210)
$cAccent2  = [Drawing.Color]::FromArgb(100, 181, 246)
$cGreen    = [Drawing.Color]::FromArgb(76,  175, 80)
$cYellow   = [Drawing.Color]::FromArgb(245, 158, 11)
$cRed      = [Drawing.Color]::FromArgb(244, 67,  54)
$cText     = [Drawing.Color]::FromArgb(226, 232, 240)
$cSubText  = [Drawing.Color]::FromArgb(74,  96,  128)
$cSubText2 = [Drawing.Color]::FromArgb(144, 168, 192)
$cOutput   = [Drawing.Color]::FromArgb(10,  16,  32)
$cSide     = [Drawing.Color]::FromArgb(10,  16,  32)

# ============================================================
# FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text          = "SysCodi WinTool"
$form.Size          = New-Object Drawing.Size(1100, 720)
$form.MinimumSize   = New-Object Drawing.Size(960, 640)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBg
$form.ForeColor     = $cText
$form.Font          = New-Object Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "Sizable"

# ============================================================
# TITLEBAR PERSONALIZADA
# ============================================================
$titleBar = New-Object Windows.Forms.Panel
$titleBar.Dock      = "Top"
$titleBar.Height    = 44
$titleBar.BackColor = $cBg
$form.Controls.Add($titleBar)

$titleLine = New-Object Windows.Forms.Panel
$titleLine.Dock      = "Bottom"
$titleLine.Height    = 1
$titleLine.BackColor = $cBorder
$titleBar.Controls.Add($titleLine)

# Logo
$logoBox = New-Object Windows.Forms.Panel
$logoBox.Location  = New-Object Drawing.Point(10, 8)
$logoBox.Size      = New-Object Drawing.Size(28, 28)
$logoBox.BackColor = [Drawing.Color]::FromArgb(21, 101, 192)
$titleBar.Controls.Add($logoBox)
$logoBox.Add_Paint({
    param($s,$e)
    $e.Graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $font  = New-Object Drawing.Font("Segoe UI", 13, [Drawing.FontStyle]::Bold)
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(100, 181, 246))
    $sf = New-Object Drawing.StringFormat
    $sf.Alignment = [Drawing.StringAlignment]::Center
    $sf.LineAlignment = [Drawing.StringAlignment]::Center
    $e.Graphics.DrawString("S", $font, $brush, [Drawing.RectangleF]::new(0,0,28,28), $sf)
    $font.Dispose(); $brush.Dispose()
})

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text      = "SysCodi WinTool"
$lblTitle.Location  = New-Object Drawing.Point(46, 6)
$lblTitle.Size      = New-Object Drawing.Size(190, 20)
$lblTitle.Font      = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cText
$lblTitle.BackColor = [Drawing.Color]::Transparent
$titleBar.Controls.Add($lblTitle)

$lblTitleSub = New-Object Windows.Forms.Label
$lblTitleSub.Text      = "Herramienta esencial para Windows"
$lblTitleSub.Location  = New-Object Drawing.Point(46, 26)
$lblTitleSub.Size      = New-Object Drawing.Size(260, 14)
$lblTitleSub.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$lblTitleSub.ForeColor = $cSubText
$lblTitleSub.BackColor = [Drawing.Color]::Transparent
$titleBar.Controls.Add($lblTitleSub)

# ============================================================
# BARRA DE TABS
# ============================================================
$tabBar = New-Object Windows.Forms.Panel
$tabBar.Dock      = "Top"
$tabBar.Height    = 42
$tabBar.BackColor = [Drawing.Color]::FromArgb(15, 21, 32)
$form.Controls.Add($tabBar)

$tabBarLine = New-Object Windows.Forms.Panel
$tabBarLine.Dock      = "Bottom"
$tabBarLine.Height    = 1
$tabBarLine.BackColor = $cBorder
$tabBar.Controls.Add($tabBarLine)

# ============================================================
# FOOTER
# ============================================================
$footer = New-Object Windows.Forms.Panel
$footer.Dock      = "Bottom"
$footer.Height    = 28
$footer.BackColor = [Drawing.Color]::FromArgb(10, 16, 32)
$form.Controls.Add($footer)

$footerLine = New-Object Windows.Forms.Panel
$footerLine.Dock      = "Top"
$footerLine.Height    = 1
$footerLine.BackColor = $cBorder
$footer.Controls.Add($footerLine)

$lblFootL = New-Object Windows.Forms.Label
$lblFootL.Text      = "  SysCodi WinTool  •  Rendimiento y reparación esencial para tu equipo"
$lblFootL.Dock      = "Left"
$lblFootL.Width     = 500
$lblFootL.ForeColor = $cSubText
$lblFootL.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$lblFootL.TextAlign = "MiddleLeft"
$footer.Controls.Add($lblFootL)

$lblFootR = New-Object Windows.Forms.Label
$lblFootR.Text      = "Versión 1.0.0  "
$lblFootR.Dock      = "Right"
$lblFootR.Width     = 150
$lblFootR.ForeColor = $cSubText
$lblFootR.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$lblFootR.TextAlign = "MiddleRight"
$footer.Controls.Add($lblFootR)

# ============================================================
# ÁREA PRINCIPAL (contenido + sidebar)
# ============================================================
$bodyPanel = New-Object Windows.Forms.Panel
$bodyPanel.Dock      = "Fill"
$bodyPanel.BackColor = $cBg
$form.Controls.Add($bodyPanel)

# SIDEBAR derecho
$sidePanel = New-Object Windows.Forms.Panel
$sidePanel.Dock      = "Right"
$sidePanel.Width     = 210
$sidePanel.BackColor = $cSide
$bodyPanel.Controls.Add($sidePanel)

$sideLine = New-Object Windows.Forms.Panel
$sideLine.Dock      = "Left"
$sideLine.Width     = 1
$sideLine.BackColor = $cBorder
$sidePanel.Controls.Add($sideLine)

# Contenido dinámico (tabs)
$contentPanel = New-Object Windows.Forms.Panel
$contentPanel.Dock      = "Fill"
$contentPanel.BackColor = $cBg
$bodyPanel.Controls.Add($contentPanel)

# ============================================================
# HELPERS
# ============================================================
function New-ModernBtn($txt, $icon, $x, $y, $w, $h, $par) {
    $p = New-Object Windows.Forms.Panel
    $p.Location  = New-Object Drawing.Point($x, $y)
    $p.Size      = New-Object Drawing.Size($w, $h)
    $p.BackColor = $cCard
    $p.Cursor    = "Hand"
    $par.Controls.Add($p)

    $p.Add_Paint({
        param($s,$e)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width-1, $s.Height-1)
        $pen.Dispose()
    })

    # Icono (simulado como label unicode)
    $lIcon = New-Object Windows.Forms.Label
    $lIcon.Text      = $icon
    $lIcon.Location  = New-Object Drawing.Point(14, 0)
    $lIcon.Size      = New-Object Drawing.Size(30, $h)
    $lIcon.Font      = New-Object Drawing.Font("Segoe UI", 16)
    $lIcon.ForeColor = $cAccent
    $lIcon.BackColor = [Drawing.Color]::Transparent
    $lIcon.TextAlign = "MiddleLeft"
    $p.Controls.Add($lIcon)

    $lTxt = New-Object Windows.Forms.Label
    $lTxt.Text      = $txt
    $lTxt.Location  = New-Object Drawing.Point(50, 0)
    $lTxt.Size      = New-Object Drawing.Size($w - 60, $h)
    $lTxt.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Regular)
    $lTxt.ForeColor = $cText
    $lTxt.BackColor = [Drawing.Color]::Transparent
    $lTxt.TextAlign = "MiddleLeft"
    $p.Controls.Add($lTxt)

    $p.Add_MouseEnter({ $this.BackColor = $cCardHov; $this.Invalidate() })
    $p.Add_MouseLeave({ $this.BackColor = $cCard; $this.Invalidate() })
    foreach ($c in $p.Controls) {
        $c.Add_MouseEnter({ $this.Parent.BackColor = $cCardHov; $this.Parent.Invalidate() })
        $c.Add_MouseLeave({ $this.Parent.BackColor = $cCard; $this.Parent.Invalidate() })
    }
    return $p
}

function New-SectionLabel($txt, $x, $y, $par) {
    $l = New-Object Windows.Forms.Label
    $l.Text      = $txt
    $l.Location  = New-Object Drawing.Point($x, $y)
    $l.Size      = New-Object Drawing.Size(700, 18)
    $l.Font      = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
    $l.ForeColor = $cSubText2
    $l.BackColor = [Drawing.Color]::Transparent
    $par.Controls.Add($l)
}

function New-SideLabel($txt, $x, $y, $size, $color, $par) {
    $l = New-Object Windows.Forms.Label
    $l.Text      = $txt
    $l.Location  = New-Object Drawing.Point($x, $y)
    $l.Size      = New-Object Drawing.Size(185, $size)
    $l.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $l.ForeColor = $color
    $l.BackColor = [Drawing.Color]::Transparent
    $par.Controls.Add($l)
    return $l
}

# ============================================================
# CONSOLA DE SALIDA (panel derecho del cuerpo)
# ============================================================
function Write-Out($msg, $color = $null) {
    if ($null -eq $color) { $color = $cAccent2 }
    if ($outputBox.IsDisposed) { return }
    try {
        $outputBox.SelectionStart  = $outputBox.TextLength
        $outputBox.SelectionColor  = $color
        $ts = Get-Date -Format "HH:mm:ss"
        $outputBox.AppendText("`r`n[$ts] $msg")
        $outputBox.ScrollToCaret()
        Write-Log $msg
    } catch {}
}

function Write-Section($t) {
    Write-Out ""
    Write-Out "─── $t ───" $cAccent2
}

# ============================================================
# PROGRESS BAR
# ============================================================
$progBar = New-Object Windows.Forms.ProgressBar
$progBar.Dock                  = "Top"
$progBar.Height                = 3
$progBar.Style                 = "Marquee"
$progBar.MarqueeAnimationSpeed = 0
$progBar.BackColor             = $cBorder
$progBar.ForeColor             = $cAccent
$contentPanel.Controls.Add($progBar)

function Start-Progress { $progBar.MarqueeAnimationSpeed = 20; [Windows.Forms.Application]::DoEvents() }
function Stop-Progress  { $progBar.MarqueeAnimationSpeed = 0 }

# ============================================================
# BACKGROUND JOB RUNNER
# ============================================================
function Run-Cmd-BG($cmd, $label) {
    Write-Out "Ejecutando: $label..." $cSubText
    Start-Progress
    $job = Start-Job -ScriptBlock { param($c) Invoke-Expression $c 2>&1 } -ArgumentList $cmd
    $tmr = New-Object Windows.Forms.Timer
    $tmr.Interval = 800
    $cJob   = $job
    $cLabel = $label
    $tmr.Add_Tick({
        if ($cJob.State -ne "Running") {
            $tmr.Stop(); Stop-Progress
            try {
                $res = Receive-Job $cJob -EA SilentlyContinue
                Remove-Job $cJob -Force -EA SilentlyContinue
                if ($res) {
                    $outputBox.SelectionStart = $outputBox.TextLength
                    $outputBox.SelectionColor = $cText
                    $outputBox.AppendText("`r`n" + ($res -join "`r`n"))
                    $outputBox.ScrollToCaret()
                }
            } catch {}
            Write-Out "Completado: $cLabel" $cGreen
        }
    })
    $tmr.Start()
}

# ============================================================
# TABS
# ============================================================
$tabDefs   = @("Reparación", "Aplicaciones")
$tabIcons  = @("⚒", "⬡")
$tabBtns   = @()
$tabPages  = @()
$script:curTab = 0
$tbX = 6

foreach ($i in 0..($tabDefs.Count-1)) {
    $tb = New-Object Windows.Forms.Button
    $tb.Text      = "  $($tabIcons[$i])  $($tabDefs[$i])"
    $tb.Location  = New-Object Drawing.Point($tbX, 4)
    $tb.Size      = New-Object Drawing.Size(150, 34)
    $tb.BackColor = [Drawing.Color]::FromArgb(15, 21, 32)
    $tb.ForeColor = $cSubText
    $tb.FlatStyle = "Flat"
    $tb.FlatAppearance.BorderSize  = 0
    $tb.Font      = New-Object Drawing.Font("Segoe UI", 9)
    $tb.Cursor    = "Hand"
    $tb.TextAlign = "MiddleLeft"
    $tabBar.Controls.Add($tb)
    $tabBtns += $tb
    $tbX += 154

    $pg = New-Object Windows.Forms.Panel
    $pg.Dock      = "Fill"
    $pg.BackColor = $cBg
    $pg.Visible   = $false
    $contentPanel.Controls.Add($pg)
    $tabPages += $pg
}

function Switch-Tab($i) {
    for ($j = 0; $j -lt $tabBtns.Count; $j++) {
        if ($j -eq $i) {
            $tabBtns[$j].ForeColor = $cAccent2
            $tabBtns[$j].BackColor = [Drawing.Color]::FromArgb(18, 28, 46)
            $tabPages[$j].Visible  = $true
            $tabPages[$j].BringToFront()
        } else {
            $tabBtns[$j].ForeColor = $cSubText
            $tabBtns[$j].BackColor = [Drawing.Color]::FromArgb(15, 21, 32)
            $tabPages[$j].Visible  = $false
        }
    }
    $script:curTab = $i
}

for ($i = 0; $i -lt $tabBtns.Count; $i++) {
    $idx = $i
    $tabBtns[$i].Add_Click({ Switch-Tab $idx })
}

# ============================================================
# SIDEBAR: INFO DEL SISTEMA + CONSOLA
# ============================================================
$ySide = 14

# Título "Sistema"
$lST = New-Object Windows.Forms.Label
$lST.Text      = "SISTEMA"
$lST.Location  = New-Object Drawing.Point(12, $ySide)
$lST.Size      = New-Object Drawing.Size(185, 14)
$lST.Font      = New-Object Drawing.Font("Segoe UI", 7.5, [Drawing.FontStyle]::Bold)
$lST.ForeColor = $cSubText
$lST.BackColor = [Drawing.Color]::Transparent
$sidePanel.Controls.Add($lST)
$ySide += 20

# OS Name grande
$lblOSName = New-Object Windows.Forms.Label
$lblOSName.Text      = "Windows 11 Pro"
$lblOSName.Location  = New-Object Drawing.Point(12, $ySide)
$lblOSName.Size      = New-Object Drawing.Size(185, 20)
$lblOSName.Font      = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$lblOSName.ForeColor = $cAccent2
$lblOSName.BackColor = [Drawing.Color]::Transparent
$sidePanel.Controls.Add($lblOSName)
$ySide += 22

$lblOSBuild = New-Object Windows.Forms.Label
$lblOSBuild.Text      = "(cargando...)"
$lblOSBuild.Location  = New-Object Drawing.Point(12, $ySide)
$lblOSBuild.Size      = New-Object Drawing.Size(185, 14)
$lblOSBuild.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$lblOSBuild.ForeColor = $cSubText
$lblOSBuild.BackColor = [Drawing.Color]::Transparent
$sidePanel.Controls.Add($lblOSBuild)
$ySide += 20

function New-InfoBlock($label, $x, $y, $par) {
    $lLbl = New-Object Windows.Forms.Label
    $lLbl.Text      = $label
    $lLbl.Location  = New-Object Drawing.Point($x, $y)
    $lLbl.Size      = New-Object Drawing.Size(185, 13)
    $lLbl.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
    $lLbl.ForeColor = $cSubText
    $lLbl.BackColor = [Drawing.Color]::Transparent
    $par.Controls.Add($lLbl)

    $lVal = New-Object Windows.Forms.Label
    $lVal.Text      = "..."
    $lVal.Location  = New-Object Drawing.Point($x, $y + 14)
    $lVal.Size      = New-Object Drawing.Size(185, 15)
    $lVal.Font      = New-Object Drawing.Font("Segoe UI", 8.5)
    $lVal.ForeColor = $cText
    $lVal.BackColor = [Drawing.Color]::Transparent
    $par.Controls.Add($lVal)
    return $lVal
}

$lblUser   = New-InfoBlock "Usuario"       12 $ySide $sidePanel; $ySide += 36
$lblEquipo = New-InfoBlock "Equipo"        12 $ySide $sidePanel; $ySide += 36
$lblUptime = New-InfoBlock "Tiempo activo" 12 $ySide $sidePanel; $ySide += 36
$lblFecha  = New-InfoBlock "Fecha"         12 $ySide $sidePanel; $ySide += 44

# Divisor
$div1 = New-Object Windows.Forms.Panel
$div1.Location  = New-Object Drawing.Point(12, $ySide)
$div1.Size      = New-Object Drawing.Size(185, 1)
$div1.BackColor = $cBorder
$sidePanel.Controls.Add($div1)
$ySide += 12

# Status panel
$statusPanel = New-Object Windows.Forms.Panel
$statusPanel.Location  = New-Object Drawing.Point(12, $ySide)
$statusPanel.Size      = New-Object Drawing.Size(185, 54)
$statusPanel.BackColor = [Drawing.Color]::FromArgb(13, 32, 16)
$sidePanel.Controls.Add($statusPanel)
$statusPanel.Add_Paint({
    param($s,$e)
    $pen = New-Object Drawing.Pen([Drawing.Color]::FromArgb(26, 58, 32), 1)
    $e.Graphics.DrawRectangle($pen, 0, 0, $s.Width-1, $s.Height-1)
    $pen.Dispose()
})

# Icono check
$lblCheckIcon = New-Object Windows.Forms.Label
$lblCheckIcon.Text      = "✔"
$lblCheckIcon.Location  = New-Object Drawing.Point(8, 10)
$lblCheckIcon.Size      = New-Object Drawing.Size(34, 34)
$lblCheckIcon.Font      = New-Object Drawing.Font("Segoe UI", 14, [Drawing.FontStyle]::Bold)
$lblCheckIcon.ForeColor = $cGreen
$lblCheckIcon.BackColor = [Drawing.Color]::Transparent
$lblCheckIcon.TextAlign = "MiddleCenter"
$statusPanel.Controls.Add($lblCheckIcon)

$lblStatusTxt = New-Object Windows.Forms.Label
$lblStatusTxt.Text      = "Todo correcto"
$lblStatusTxt.Location  = New-Object Drawing.Point(48, 10)
$lblStatusTxt.Size      = New-Object Drawing.Size(130, 16)
$lblStatusTxt.Font      = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
$lblStatusTxt.ForeColor = $cGreen
$lblStatusTxt.BackColor = [Drawing.Color]::Transparent
$statusPanel.Controls.Add($lblStatusTxt)

$lblStatusSub = New-Object Windows.Forms.Label
$lblStatusSub.Text      = "El sistema funciona con normalidad."
$lblStatusSub.Location  = New-Object Drawing.Point(48, 27)
$lblStatusSub.Size      = New-Object Drawing.Size(130, 22)
$lblStatusSub.Font      = New-Object Drawing.Font("Segoe UI", 7)
$lblStatusSub.ForeColor = [Drawing.Color]::FromArgb(42, 80, 48)
$lblStatusSub.BackColor = [Drawing.Color]::Transparent
$statusPanel.Controls.Add($lblStatusSub)

$ySide += 62

$btnVerSist = New-Object Windows.Forms.Button
$btnVerSist.Text      = "Ver detalles del sistema"
$btnVerSist.Location  = New-Object Drawing.Point(12, $ySide)
$btnVerSist.Size      = New-Object Drawing.Size(185, 30)
$btnVerSist.BackColor = $cCard
$btnVerSist.ForeColor = $cSubText2
$btnVerSist.FlatStyle = "Flat"
$btnVerSist.FlatAppearance.BorderColor = $cBorder
$btnVerSist.Font = New-Object Drawing.Font("Segoe UI", 8)
$btnVerSist.Cursor = "Hand"
$btnVerSist.Add_Click({
    Run-Cmd-BG 'Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture,LastBootUpTime | Format-List | Out-String' "Detalles del sistema"
})
$btnVerSist.Add_MouseEnter({ $this.BackColor = $cCardHov; $this.ForeColor = $cAccent2 })
$btnVerSist.Add_MouseLeave({ $this.BackColor = $cCard; $this.ForeColor = $cSubText2 })
$sidePanel.Controls.Add($btnVerSist)
$ySide += 38

# Divisor
$div2 = New-Object Windows.Forms.Panel
$div2.Location  = New-Object Drawing.Point(12, $ySide)
$div2.Size      = New-Object Drawing.Size(185, 1)
$div2.BackColor = $cBorder
$sidePanel.Controls.Add($div2)
$ySide += 10

# CONSOLA en el sidebar (parte inferior)
$lConT = New-Object Windows.Forms.Label
$lConT.Text      = "CONSOLA"
$lConT.Location  = New-Object Drawing.Point(12, $ySide)
$lConT.Size      = New-Object Drawing.Size(130, 14)
$lConT.Font      = New-Object Drawing.Font("Segoe UI", 7.5, [Drawing.FontStyle]::Bold)
$lConT.ForeColor = $cSubText
$lConT.BackColor = [Drawing.Color]::Transparent
$sidePanel.Controls.Add($lConT)

$btnClearCon = New-Object Windows.Forms.Button
$btnClearCon.Text      = "Limpiar"
$btnClearCon.Location  = New-Object Drawing.Point(140, $ySide - 2)
$btnClearCon.Size      = New-Object Drawing.Size(58, 18)
$btnClearCon.BackColor = [Drawing.Color]::FromArgb(0, 55, 105)
$btnClearCon.ForeColor = $cText
$btnClearCon.FlatStyle = "Flat"
$btnClearCon.FlatAppearance.BorderSize = 0
$btnClearCon.Font = New-Object Drawing.Font("Segoe UI", 7)
$sidePanel.Controls.Add($btnClearCon)
$ySide += 18

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location    = New-Object Drawing.Point(1, $ySide)
$outputBox.Size        = New-Object Drawing.Size(208, 200)
$outputBox.BackColor   = $cOutput
$outputBox.ForeColor   = $cAccent2
$outputBox.Font        = New-Object Drawing.Font("Consolas", 7.5)
$outputBox.ReadOnly    = $true
$outputBox.BorderStyle = "None"
$outputBox.ScrollBars  = "Vertical"
$outputBox.Anchor      = "Top,Left,Right,Bottom"
$sidePanel.Controls.Add($outputBox)

$btnClearCon.Add_Click({ $outputBox.Clear() })

# Ajustar consola al resize
$sidePanel.Add_Resize({
    $outputBox.Size = New-Object Drawing.Size(208, ($sidePanel.Height - $outputBox.Top - 4))
})

# ============================================================
# CARGAR INFO DEL SISTEMA (una sola vez al inicio)
# ============================================================
$script:bootTime = $null
try {
    $osI = Get-CimInstance Win32_OperatingSystem -EA Stop
    $lblOSName.Text  = "Windows"
    $osCaption = $osI.Caption.Replace("Microsoft ","")
    $lblOSName.Text  = $osCaption.Split(" ")[0..2] -join " "
    $lblOSBuild.Text = "($($osI.BuildNumber))"
    $lblUser.Text    = $env:USERNAME
    $lblEquipo.Text  = $env:COMPUTERNAME
    $script:bootTime = $osI.LastBootUpTime
} catch {}

# Timer reloj + uptime (solo fecha, sin CimInstance)
$clockTimer = New-Object Windows.Forms.Timer
$clockTimer.Interval = 1000
$clockTimer.Add_Tick({
    $lblFecha.Text = (Get-Date -Format "dd/MM/yyyy HH:mm:ss")
    if ($script:bootTime) {
        $up = (Get-Date) - $script:bootTime
        $lblUptime.Text = "$($up.Days)d $($up.Hours)h $($up.Minutes)m"
    }
})
$clockTimer.Start()

# ============================================================
# TAB 0: REPARACIÓN
# ============================================================
$scrollRep = New-Object Windows.Forms.Panel
$scrollRep.Dock      = "Fill"
$scrollRep.AutoScroll = $true
$scrollRep.BackColor = $cBg
$tabPages[0].Controls.Add($scrollRep)

$yR = 16

# Sección: Reparación rápida
New-SectionLabel "Reparación rápida" 16 $yR $scrollRep; $yR += 22

$repButtons = @(
    @{ t = "SFC /scannow";       i = "🛡"; c = 'sfc /scannow' },
    @{ t = "DISM RestoreHealth"; i = "♥"; c = 'DISM /Online /Cleanup-Image /RestoreHealth' },
    @{ t = "CheckDisk (C:)";     i = "💾"; c = 'echo Y | chkdsk C: /f /r' },
    @{ t = "Limpiar Temporales"; i = "🗑"; c = 'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue; Write-Output "Temporales eliminados"' },
    @{ t = "Limpiar Prefetch";   i = "⚡"; c = 'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue; Write-Output "Prefetch limpiado"' },
    @{ t = "DNS Flush";          i = "🌐"; c = 'ipconfig /flushdns' }
)

$bX = 16; $bY = $yR; $bCol = 0
foreach ($rb in $repButtons) {
    $btn = New-ModernBtn $rb.t $rb.i $bX $bY 202 54 $scrollRep
    $cmdVal  = $rb.c
    $lblVal  = $rb.t
    $btn.Add_Click({ Run-Cmd-BG $cmdVal $lblVal })
    foreach ($c in $btn.Controls) {
        $c.Add_Click({ $this.Parent.BackColor = $cCard })
    }
    $bCol++
    if ($bCol -ge 3) { $bCol = 0; $bX = 16; $bY += 62 } else { $bX += 210 }
}
$yR = $bY + 62

# Sección: Red
New-SectionLabel "Red" 16 $yR $scrollRep; $yR += 22

$netButtons = @(
    @{ t = "Reset TCP/IP";       i = "📡"; c = 'netsh int ip reset; Write-Output "TCP/IP reseteado"' },
    @{ t = "Reset Winsock";      i = "🔌"; c = 'netsh winsock reset; Write-Output "Winsock reseteado"' },
    @{ t = "Ver Puertos";        i = "🔍"; c = 'netstat -ano | Select-Object -First 30 | Out-String' },
    @{ t = "Reset Windows Update"; i = "🔁"; c = 'Stop-Service wuauserv,bits,cryptsvc -Force -EA SilentlyContinue; Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv,bits,cryptsvc -EA SilentlyContinue; Write-Output "Windows Update reiniciado"' }
)

$bX = 16; $bCol = 0
foreach ($rb in $netButtons) {
    $btn = New-ModernBtn $rb.t $rb.i $bX $yR 202 54 $scrollRep
    $cmdVal = $rb.c; $lblVal = $rb.t
    $btn.Add_Click({ Run-Cmd-BG $cmdVal $lblVal })
    foreach ($c in $btn.Controls) { $c.Add_Click({ $this.Parent.BackColor = $cCard }) }
    $bCol++
    if ($bCol -ge 3) { $bCol = 0; $bX = 16; $yR += 62 } else { $bX += 210 }
}
$yR += 62

# Sección: Disco
New-SectionLabel "Disco y almacenamiento" 16 $yR $scrollRep; $yR += 22

$diskButtons = @(
    @{ t = "Info de discos";         i = "💿"; c = 'Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{n="Total GB";e={[math]::Round(($_.Used+$_.Free)/1GB,2)}},@{n="Libre GB";e={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize | Out-String' },
    @{ t = "Optimizar C: (TRIM)";    i = "⚙";  c = 'defrag C: /L; Write-Output "Optimización TRIM completada"' },
    @{ t = "Eliminar Minidumps";     i = "🗑";  c = 'Remove-Item "C:\Windows\Minidump\*" -Force -EA SilentlyContinue; Write-Output "Minidumps eliminados"' },
    @{ t = "Vaciar Papelera";        i = "🗂";  c = 'Clear-RecycleBin -Force -EA SilentlyContinue; Write-Output "Papelera vaciada"' },
    @{ t = "Archivos Grandes Top20"; i = "📋"; c = 'Get-ChildItem C:\ -Recurse -EA SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20 FullName,@{n="MB";e={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize | Out-String' }
)

$bX = 16; $bCol = 0
foreach ($rb in $diskButtons) {
    $btn = New-ModernBtn $rb.t $rb.i $bX $yR 202 54 $scrollRep
    $cmdVal = $rb.c; $lblVal = $rb.t
    $btn.Add_Click({ Run-Cmd-BG $cmdVal $lblVal })
    foreach ($c in $btn.Controls) { $c.Add_Click({ $this.Parent.BackColor = $cCard }) }
    $bCol++
    if ($bCol -ge 3) { $bCol = 0; $bX = 16; $yR += 62 } else { $bX += 210 }
}
$yR += 62 + 12

# BOTÓN MANTENIMIENTO COMPLETO
$btnMaint = New-Object Windows.Forms.Button
$btnMaint.Text      = "  ⚡  MANTENIMIENTO COMPLETO  (Temporales + DNS + Papelera + SFC + DISM)"
$btnMaint.Location  = New-Object Drawing.Point(16, $yR)
$btnMaint.Size      = New-Object Drawing.Size(640, 44)
$btnMaint.BackColor = [Drawing.Color]::FromArgb(21, 101, 192)
$btnMaint.ForeColor = $cText
$btnMaint.FlatStyle = "Flat"
$btnMaint.FlatAppearance.BorderColor = $cAccent2
$btnMaint.FlatAppearance.BorderSize  = 1
$btnMaint.Font   = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$btnMaint.Cursor = "Hand"
$btnMaint.TextAlign = "MiddleLeft"
$btnMaint.Add_MouseEnter({ $this.BackColor = [Drawing.Color]::FromArgb(30, 120, 210) })
$btnMaint.Add_MouseLeave({ $this.BackColor = [Drawing.Color]::FromArgb(21, 101, 192) })
$btnMaint.Add_Click({
    Write-Section "MANTENIMIENTO COMPLETO"
    $cmds = @(
        @("Temporales",   'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue'),
        @("DNS Flush",    'ipconfig /flushdns'),
        @("Papelera",     'Clear-RecycleBin -Force -EA SilentlyContinue'),
        @("SFC",          'sfc /scannow'),
        @("DISM",         'DISM /Online /Cleanup-Image /RestoreHealth')
    )
    Start-Progress
    foreach ($c in $cmds) {
        Write-Out ">>> $($c[0])..." $cSubText
        Invoke-Expression $c[1] 2>&1 | Out-Null
        Write-Out "OK: $($c[0])" $cGreen
        [Windows.Forms.Application]::DoEvents()
    }
    Stop-Progress
    Write-Out "MANTENIMIENTO COMPLETADO" $cGreen
})
$scrollRep.Controls.Add($btnMaint)
$yR += 55
$scrollRep.AutoScrollMinSize = New-Object Drawing.Size(680, ($yR + 20))

# ============================================================
# TAB 1: APLICACIONES (winget)
# ============================================================
$pTopApp = New-Object Windows.Forms.Panel
$pTopApp.Dock      = "Top"
$pTopApp.Height    = 50
$pTopApp.BackColor = [Drawing.Color]::FromArgb(15, 21, 32)
$tabPages[1].Controls.Add($pTopApp)

$pTopAppLine = New-Object Windows.Forms.Panel
$pTopAppLine.Dock      = "Bottom"
$pTopAppLine.Height    = 1
$pTopAppLine.BackColor = $cBorder
$pTopApp.Controls.Add($pTopAppLine)

$lblSearch = New-Object Windows.Forms.Label
$lblSearch.Text      = "Buscar:"
$lblSearch.Location  = New-Object Drawing.Point(14, 15)
$lblSearch.Size      = New-Object Drawing.Size(52, 20)
$lblSearch.ForeColor = $cSubText
$lblSearch.Font      = New-Object Drawing.Font("Segoe UI", 8.5)
$pTopApp.Controls.Add($lblSearch)

$txtSearch = New-Object Windows.Forms.TextBox
$txtSearch.Location    = New-Object Drawing.Point(68, 12)
$txtSearch.Size        = New-Object Drawing.Size(180, 26)
$txtSearch.BackColor   = [Drawing.Color]::FromArgb(17, 25, 39)
$txtSearch.ForeColor   = $cText
$txtSearch.BorderStyle = "FixedSingle"
$txtSearch.Font        = New-Object Drawing.Font("Segoe UI", 9)
$pTopApp.Controls.Add($txtSearch)

function New-AppTopBtn($txt, $x, $bg) {
    $b = New-Object Windows.Forms.Button
    $b.Text      = $txt
    $b.Location  = New-Object Drawing.Point($x, 11)
    $b.Size      = New-Object Drawing.Size(90, 28)
    $b.BackColor = $bg
    $b.ForeColor = $cText
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $b.Cursor    = "Hand"
    $pTopApp.Controls.Add($b)
    return $b
}

$btnSelAll  = New-AppTopBtn "Sel. todo"   256 ([Drawing.Color]::FromArgb(0, 65, 120))
$btnClear   = New-AppTopBtn "Limpiar"     352 ([Drawing.Color]::FromArgb(75, 15, 15))
$btnFoss    = New-AppTopBtn "Solo FOSS"   448 ([Drawing.Color]::FromArgb(0, 50, 25))

$btnInstall = New-Object Windows.Forms.Button
$btnInstall.Text      = "  ⬇  INSTALAR SELECCIONADAS"
$btnInstall.Location  = New-Object Drawing.Point(548, 8)
$btnInstall.Size      = New-Object Drawing.Size(210, 34)
$btnInstall.BackColor = [Drawing.Color]::FromArgb(0, 100, 50)
$btnInstall.ForeColor = $cText
$btnInstall.FlatStyle = "Flat"
$btnInstall.FlatAppearance.BorderColor = $cGreen
$btnInstall.FlatAppearance.BorderSize  = 1
$btnInstall.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$btnInstall.TextAlign = "MiddleLeft"
$pTopApp.Controls.Add($btnInstall)

$scrollApp = New-Object Windows.Forms.Panel
$scrollApp.Dock      = "Fill"
$scrollApp.AutoScroll = $true
$scrollApp.BackColor = $cBg
$tabPages[1].Controls.Add($scrollApp)

$appList = @(
    @{ cat="Navegadores";  name="Google Chrome";  cmd="winget install -e --id Google.Chrome -h";                      foss=$false },
    @{ cat="Navegadores";  name="Mozilla Firefox"; cmd="winget install -e --id Mozilla.Firefox -h";                   foss=$true  },
    @{ cat="Navegadores";  name="Brave Browser";   cmd="winget install -e --id Brave.Brave -h";                       foss=$true  },
    @{ cat="Navegadores";  name="Opera GX";        cmd="winget install -e --id Opera.OperaGX -h";                     foss=$false },
    @{ cat="Comunicación"; name="Discord";         cmd="winget install -e --id Discord.Discord -h";                   foss=$false },
    @{ cat="Comunicación"; name="Telegram";        cmd="winget install -e --id Telegram.TelegramDesktop -h";          foss=$true  },
    @{ cat="Comunicación"; name="Signal";          cmd="winget install -e --id OpenWhisperSystems.Signal -h";         foss=$true  },
    @{ cat="Comunicación"; name="Zoom";            cmd="winget install -e --id Zoom.Zoom -h";                         foss=$false },
    @{ cat="Desarrollo";   name="VS Code";         cmd="winget install -e --id Microsoft.VisualStudioCode -h";        foss=$true  },
    @{ cat="Desarrollo";   name="Git";             cmd="winget install -e --id Git.Git -h";                           foss=$true  },
    @{ cat="Desarrollo";   name="Python 3";        cmd="winget install -e --id Python.Python.3 -h";                   foss=$true  },
    @{ cat="Desarrollo";   name="NodeJS LTS";      cmd="winget install -e --id OpenJS.NodeJS.LTS -h";                 foss=$true  },
    @{ cat="Desarrollo";   name="Docker Desktop";  cmd="winget install -e --id Docker.DockerDesktop -h";              foss=$false },
    @{ cat="Desarrollo";   name="PowerShell 7";    cmd="winget install -e --id Microsoft.PowerShell -h";              foss=$true  },
    @{ cat="Utilidades";   name="7-Zip";           cmd="winget install -e --id 7zip.7zip -h";                         foss=$true  },
    @{ cat="Utilidades";   name="Notepad++";       cmd="winget install -e --id Notepad++.Notepad++ -h";               foss=$true  },
    @{ cat="Utilidades";   name="Everything";      cmd="winget install -e --id voidtools.Everything -h";               foss=$false },
    @{ cat="Utilidades";   name="CPU-Z";           cmd="winget install -e --id CPUID.CPU-Z -h";                       foss=$false },
    @{ cat="Utilidades";   name="HWMonitor";       cmd="winget install -e --id CPUID.HWMonitor -h";                   foss=$false },
    @{ cat="Multimedia";   name="VLC";             cmd="winget install -e --id VideoLAN.VLC -h";                      foss=$true  },
    @{ cat="Multimedia";   name="OBS Studio";      cmd="winget install -e --id OBSProject.OBSStudio -h";              foss=$true  },
    @{ cat="Multimedia";   name="GIMP";            cmd="winget install -e --id GIMP.GIMP -h";                         foss=$true  },
    @{ cat="Multimedia";   name="Audacity";        cmd="winget install -e --id Audacity.Audacity -h";                 foss=$true  },
    @{ cat="Oficina";      name="LibreOffice";     cmd="winget install -e --id TheDocumentFoundation.LibreOffice -h"; foss=$true  },
    @{ cat="Oficina";      name="SumatraPDF";      cmd="winget install -e --id SumatraPDF.SumatraPDF -h";             foss=$true  },
    @{ cat="Oficina";      name="Obsidian";        cmd="winget install -e --id Obsidian.Obsidian -h";                 foss=$false },
    @{ cat="Seguridad";    name="Bitwarden";       cmd="winget install -e --id Bitwarden.Bitwarden -h";               foss=$true  },
    @{ cat="Seguridad";    name="KeePassXC";       cmd="winget install -e --id KeePassXCTeam.KeePassXC -h";           foss=$true  },
    @{ cat="Gaming";       name="Steam";           cmd="winget install -e --id Valve.Steam -h";                       foss=$false },
    @{ cat="Gaming";       name="Epic Games";      cmd="winget install -e --id EpicGames.EpicGamesLauncher -h";       foss=$false },
    @{ cat="Gaming";       name="MSI Afterburner"; cmd="winget install -e --id Guru3D.Afterburner -h";                foss=$false }
)

$checkboxes = [System.Collections.ArrayList]@()
$yA = 8; $lastCat = ""; $colA = 0

foreach ($app in $appList) {
    if ($app.cat -ne $lastCat) {
        if ($lastCat -ne "") { if ($colA -ne 0) { $yA += 26 }; $yA += 6 }
        $lCat = New-Object Windows.Forms.Label
        $lCat.Text      = "  $($app.cat)"
        $lCat.Location  = New-Object Drawing.Point(14, $yA)
        $lCat.Size      = New-Object Drawing.Size(640, 20)
        $lCat.ForeColor = $cSubText2
        $lCat.BackColor = [Drawing.Color]::FromArgb(15, 21, 32)
        $lCat.Font      = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
        $scrollApp.Controls.Add($lCat)
        $yA += 22; $lastCat = $app.cat; $colA = 0
    }

    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text      = $app.name
    $cb.Location  = New-Object Drawing.Point((14 + $colA * 160), $yA)
    $cb.Size      = New-Object Drawing.Size(155, 22)
    $cb.ForeColor = if ($app.foss) { $cAccent2 } else { $cText }
    $cb.BackColor = $cBg
    $cb.Tag       = $app
    $scrollApp.Controls.Add($cb)
    $checkboxes.Add($cb) | Out-Null
    $colA++
    if ($colA -ge 4) { $colA = 0; $yA += 24 }
}
$yA += 30
$scrollApp.AutoScrollMinSize = New-Object Drawing.Size(660, ($yA + 20))

$btnSelAll.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $true } })
$btnClear.Add_Click({  $checkboxes | ForEach-Object { $_.Checked = $false } })
$btnFoss.Add_Click({   $checkboxes | ForEach-Object { $_.Checked = ($_.Tag.foss -eq $true) } })

$txtSearch.Add_TextChanged({
    $q = $txtSearch.Text.Trim().ToLower()
    foreach ($cb in $checkboxes) {
        $cb.ForeColor = if ($q -and $cb.Text.ToLower().Contains($q)) {
            $cYellow
        } else {
            if ($cb.Tag.foss) { $cAccent2 } else { $cText }
        }
    }
})

$btnInstall.Add_Click({
    $sel = $checkboxes | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ninguna app." $cYellow; return }
    if (-not (Get-Command winget -EA SilentlyContinue)) {
        Write-Out "WinGet no encontrado. Instala App Installer desde la Tienda de Microsoft." $cRed
        return
    }
    Write-Section "INSTALANDO $($sel.Count) APPS"
    Start-Progress; $i = 0
    foreach ($cb in $sel) {
        $i++
        Write-Out "[$i/$($sel.Count)] $($cb.Tag.name)..." $cSubText
        Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"$($cb.Tag.cmd)`"" -Wait -EA SilentlyContinue
        Write-Out "  OK: $($cb.Tag.name)" $cGreen
        [Windows.Forms.Application]::DoEvents()
    }
    Stop-Progress
    Write-Out "Instalación completada: $i apps." $cGreen
})

# ============================================================
# ARRANQUE
# ============================================================
Switch-Tab 0
Write-Out "SysCodi WinTool v1.0.0 iniciado." $cGreen
Write-Out "Equipo: $env:COMPUTERNAME  |  Usuario: $env:USERNAME" $cSubText
Write-Log "Iniciado"

$form.Add_FormClosing({ $clockTimer.Stop(); Write-Log "Cerrado" })
$form.ShowDialog()
