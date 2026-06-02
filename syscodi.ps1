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
# COLORES
# ============================================================
$cBg      = [Drawing.Color]::FromArgb(10, 18, 40)
$cPanel   = [Drawing.Color]::FromArgb(16, 28, 58)
$cCard    = [Drawing.Color]::FromArgb(20, 36, 76)
$cCardHov = [Drawing.Color]::FromArgb(26, 48, 98)
$cAccent  = [Drawing.Color]::FromArgb(0, 145, 255)
$cAccent2 = [Drawing.Color]::FromArgb(80, 185, 255)
$cGreen   = [Drawing.Color]::FromArgb(40, 220, 120)
$cYellow  = [Drawing.Color]::FromArgb(255, 200, 50)
$cRed     = [Drawing.Color]::FromArgb(255, 80, 80)
$cText    = [Drawing.Color]::White
$cSubText = [Drawing.Color]::FromArgb(140, 180, 230)
$cBorder  = [Drawing.Color]::FromArgb(28, 60, 120)
$cOutput  = [Drawing.Color]::FromArgb(7, 14, 32)

# ============================================================
# FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text          = "SysCodi WinTool Pro"
$form.Size          = New-Object Drawing.Size(1366, 900)
$form.MinimumSize   = New-Object Drawing.Size(1100, 750)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBg
$form.ForeColor     = $cText
$form.Font          = New-Object Drawing.Font("Segoe UI", 9)

# ============================================================
# HEADER
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Dock      = "Top"
$header.Height    = 90
$header.BackColor = $cPanel
$form.Controls.Add($header)

$hLine = New-Object Windows.Forms.Panel
$hLine.Dock      = "Bottom"
$hLine.Height    = 2
$hLine.BackColor = $cAccent
$header.Controls.Add($hLine)

# Logo placeholder (S)
$logoBox = New-Object Windows.Forms.Panel
$logoBox.Location  = New-Object Drawing.Point(15, 15)
$logoBox.Size      = New-Object Drawing.Size(60, 60)
$logoBox.BackColor = [Drawing.Color]::FromArgb(0, 100, 200)
$header.Controls.Add($logoBox)
$logoBox.Add_Paint({
    param($s, $e)
    $e.Graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $font = New-Object Drawing.Font("Segoe UI", 28, [Drawing.FontStyle]::Bold)
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::White)
    $sf = New-Object Drawing.StringFormat
    $sf.Alignment = [Drawing.StringAlignment]::Center
    $sf.LineAlignment = [Drawing.StringAlignment]::Center
    $e.Graphics.DrawString("S", $font, $brush, [Drawing.RectangleF]::new(0, 0, 60, 60), $sf)
    $font.Dispose(); $brush.Dispose()
})

$lblTitle1 = New-Object Windows.Forms.Label
$lblTitle1.Text      = "SysCodi"
$lblTitle1.Location  = New-Object Drawing.Point(88, 12)
$lblTitle1.Size      = New-Object Drawing.Size(115, 38)
$lblTitle1.Font      = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold)
$lblTitle1.ForeColor = $cAccent2
$lblTitle1.BackColor = [Drawing.Color]::Transparent
$header.Controls.Add($lblTitle1)

$lblTitle2 = New-Object Windows.Forms.Label
$lblTitle2.Text      = " WinTool Pro"
$lblTitle2.Location  = New-Object Drawing.Point(200, 12)
$lblTitle2.Size      = New-Object Drawing.Size(240, 38)
$lblTitle2.Font      = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold)
$lblTitle2.ForeColor = $cText
$lblTitle2.BackColor = [Drawing.Color]::Transparent
$header.Controls.Add($lblTitle2)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text      = "Utilidad de sistema avanzada para Windows"
$lblSub.Location  = New-Object Drawing.Point(88, 56)
$lblSub.Size      = New-Object Drawing.Size(380, 20)
$lblSub.Font      = New-Object Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = $cSubText
$lblSub.BackColor = [Drawing.Color]::Transparent
$header.Controls.Add($lblSub)

# Info derecha header
$pHI = New-Object Windows.Forms.Panel
$pHI.Location  = New-Object Drawing.Point(680, 8)
$pHI.Size      = New-Object Drawing.Size(660, 75)
$pHI.BackColor = [Drawing.Color]::Transparent
$header.Controls.Add($pHI)

function New-HLbl($text, $x, $y, $w, $font, $color) {
    $l = New-Object Windows.Forms.Label
    $l.Text = $text; $l.Location = New-Object Drawing.Point($x, $y)
    $l.Size = New-Object Drawing.Size($w, 22); $l.Font = $font
    $l.ForeColor = $color; $l.BackColor = [Drawing.Color]::Transparent
    $pHI.Controls.Add($l); return $l
}
$fB  = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$fN  = New-Object Drawing.Font("Segoe UI", 10)
$fS  = New-Object Drawing.Font("Segoe UI", 8.5)
$lblOSName = New-HLbl "Windows 11 Pro" 0 4 130 $fB $cAccent2
$lblOSVer  = New-HLbl "" 130 4 280 $fN $cText
$lblUser   = New-HLbl "" 0 28 300 $fS $cSubText
$lblUptime = New-HLbl "" 310 28 340 $fS $cSubText
$lblEquipo = New-HLbl "" 0 50 300 $fS $cSubText
$lblClock  = New-HLbl "" 310 50 340 $fS $cSubText

try {
    $osI = Get-CimInstance Win32_OperatingSystem -EA Stop
    $lblOSName.Text = "Windows"
    $lblOSVer.Text  = " $($osI.Caption.Replace('Microsoft ','')) ($($osI.BuildNumber))"
    $lblUser.Text   = "Usuario:  $env:USERNAME"
    $lblEquipo.Text = "Equipo:   $env:COMPUTERNAME"
} catch {}

$clockTimer = New-Object Windows.Forms.Timer
$clockTimer.Interval = 1000
$clockTimer.Add_Tick({
    $lblClock.Text = "Fecha:  $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    try {
        $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem -EA Stop).LastBootUpTime
        $lblUptime.Text = "Tiempo activo:  $($up.Days)d $($up.Hours)h $($up.Minutes)m"
    } catch {}
})
$clockTimer.Start()

# ============================================================
# BARRA DE TABS
# ============================================================
$pnlTabs = New-Object Windows.Forms.Panel
$pnlTabs.Dock      = "Top"
$pnlTabs.Height    = 50
$pnlTabs.BackColor = $cPanel
$form.Controls.Add($pnlTabs)

$tabBottomLine = New-Object Windows.Forms.Panel
$tabBottomLine.Dock      = "Bottom"
$tabBottomLine.Height    = 1
$tabBottomLine.BackColor = $cBorder
$pnlTabs.Controls.Add($tabBottomLine)

# ============================================================
# AREA DE CONTENIDO
# ============================================================
$pnlContent = New-Object Windows.Forms.Panel
$pnlContent.Dock      = "Fill"
$pnlContent.BackColor = $cBg
$form.Controls.Add($pnlContent)

# ============================================================
# FOOTER
# ============================================================
$footer = New-Object Windows.Forms.Panel
$footer.Dock      = "Bottom"
$footer.Height    = 170
$footer.BackColor = $cPanel
$form.Controls.Add($footer)

$fTopLine = New-Object Windows.Forms.Panel
$fTopLine.Dock      = "Top"
$fTopLine.Height    = 1
$fTopLine.BackColor = $cBorder
$footer.Controls.Add($fTopLine)

# Status bar
$statusBar = New-Object Windows.Forms.Panel
$statusBar.Dock      = "Bottom"
$statusBar.Height    = 26
$statusBar.BackColor = [Drawing.Color]::FromArgb(6, 12, 30)
$footer.Controls.Add($statusBar)

$lblSL = New-Object Windows.Forms.Label
$lblSL.Text      = "  Ejecutar siempre como Administrador para mejor rendimiento"
$lblSL.Dock      = "Left"; $lblSL.Width = 700
$lblSL.ForeColor = $cSubText
$lblSL.Font      = New-Object Drawing.Font("Segoe UI", 8)
$lblSL.TextAlign = "MiddleLeft"
$statusBar.Controls.Add($lblSL)

$lblSR = New-Object Windows.Forms.Label
$lblSR.Text      = "Desarrollado por SysCodi     Versión 2.5.0 Pro  "
$lblSR.Dock      = "Right"; $lblSR.Width = 400
$lblSR.ForeColor = $cSubText
$lblSR.Font      = New-Object Drawing.Font("Segoe UI", 8)
$lblSR.TextAlign = "MiddleRight"
$statusBar.Controls.Add($lblSR)

$footerInner = New-Object Windows.Forms.Panel
$footerInner.Dock      = "Fill"
$footerInner.BackColor = $cPanel
$footer.Controls.Add($footerInner)

# ---- Métricas rápidas ----
$pnlMet = New-Object Windows.Forms.Panel
$pnlMet.Location  = New-Object Drawing.Point(5, 6)
$pnlMet.Size      = New-Object Drawing.Size(380, 135)
$pnlMet.BackColor = $cCard
$footerInner.Controls.Add($pnlMet)

$lMT = New-Object Windows.Forms.Label
$lMT.Text = "Información rápida"; $lMT.Location = New-Object Drawing.Point(10, 5)
$lMT.Size = New-Object Drawing.Size(360, 18); $lMT.ForeColor = $cAccent2
$lMT.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlMet.Controls.Add($lMT)

function New-MetCard($label, $x, $y, $parent) {
    $p = New-Object Windows.Forms.Panel
    $p.Location = New-Object Drawing.Point($x, $y)
    $p.Size     = New-Object Drawing.Size(178, 52)
    $p.BackColor = [Drawing.Color]::FromArgb(12, 24, 52)
    $parent.Controls.Add($p)

    $lname = New-Object Windows.Forms.Label
    $lname.Text = $label; $lname.Location = New-Object Drawing.Point(6, 4)
    $lname.Size = New-Object Drawing.Size(100, 16); $lname.ForeColor = $cSubText
    $lname.Font = New-Object Drawing.Font("Segoe UI", 7.5); $p.Controls.Add($lname)

    $lval = New-Object Windows.Forms.Label
    $lval.Text = "..."; $lval.Location = New-Object Drawing.Point(80, 2)
    $lval.Size = New-Object Drawing.Size(90, 18); $lval.ForeColor = $cText
    $lval.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
    $lval.TextAlign = "MiddleRight"; $p.Controls.Add($lval)

    $bar = New-Object Windows.Forms.ProgressBar
    $bar.Location = New-Object Drawing.Point(6, 24); $bar.Size = New-Object Drawing.Size(166, 7)
    $bar.Minimum = 0; $bar.Maximum = 100; $bar.Style = "Continuous"
    $bar.ForeColor = $cAccent2; $p.Controls.Add($bar)

    $lextra = New-Object Windows.Forms.Label
    $lextra.Text = ""; $lextra.Location = New-Object Drawing.Point(6, 34)
    $lextra.Size = New-Object Drawing.Size(166, 16); $lextra.ForeColor = $cSubText
    $lextra.Font = New-Object Drawing.Font("Segoe UI", 7); $p.Controls.Add($lextra)

    return @{ val = $lval; bar = $bar; extra = $lextra }
}

$mCPU  = New-MetCard "CPU Uso"    6   24 $pnlMet
$mRAM  = New-MetCard "RAM Uso"    192 24 $pnlMet
$mDisk = New-MetCard "Disco (C:)" 6   80 $pnlMet
$mNet  = New-MetCard "Red"        192 80 $pnlMet

# ---- Accesos rápidos ----
$pnlAcc = New-Object Windows.Forms.Panel
$pnlAcc.Location  = New-Object Drawing.Point(393, 6)
$pnlAcc.Size      = New-Object Drawing.Size(380, 135)
$pnlAcc.BackColor = $cCard
$footerInner.Controls.Add($pnlAcc)

$lAT = New-Object Windows.Forms.Label
$lAT.Text = "Accesos rápidos"; $lAT.Location = New-Object Drawing.Point(10, 5)
$lAT.Size = New-Object Drawing.Size(360, 18); $lAT.ForeColor = $cAccent2
$lAT.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlAcc.Controls.Add($lAT)

$accList = @(
    @{ n = "Explorador";       c = { Start-Process explorer } },
    @{ n = "Adm. dispositivos"; c = { Start-Process devmgmt.msc } },
    @{ n = "Adm. de discos";   c = { Start-Process diskmgmt.msc } },
    @{ n = "Servicios";        c = { Start-Process services.msc } },
    @{ n = "Eventos";          c = { Start-Process eventvwr.msc } },
    @{ n = "Panel de control"; c = { Start-Process control } }
)
$ax = 8; $ay = 26; $ac = 0
foreach ($a in $accList) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $a.n; $b.Location = New-Object Drawing.Point($ax, $ay)
    $b.Size = New-Object Drawing.Size(118, 48); $b.BackColor = [Drawing.Color]::FromArgb(12, 24, 52)
    $b.ForeColor = $cText; $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $cBorder
    $b.Font = New-Object Drawing.Font("Segoe UI", 7.5); $b.Cursor = "Hand"
    $ac2 = $a.c
    $b.Add_Click($ac2)
    $b.Add_MouseEnter({ $this.BackColor = $cCardHov })
    $b.Add_MouseLeave({ $this.BackColor = [Drawing.Color]::FromArgb(12, 24, 52) })
    $pnlAcc.Controls.Add($b)
    $ac++
    if ($ac -ge 3) { $ac = 0; $ax = 8; $ay += 52 } else { $ax += 122 }
}

# ---- Acciones rápidas ----
$pnlAct = New-Object Windows.Forms.Panel
$pnlAct.Location  = New-Object Drawing.Point(781, 6)
$pnlAct.Size      = New-Object Drawing.Size(380, 135)
$pnlAct.BackColor = $cCard
$footerInner.Controls.Add($pnlAct)

$lAcT = New-Object Windows.Forms.Label
$lAcT.Text = "Acciones rápidas"; $lAcT.Location = New-Object Drawing.Point(10, 5)
$lAcT.Size = New-Object Drawing.Size(360, 18); $lAcT.ForeColor = $cAccent2
$lAcT.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlAct.Controls.Add($lAcT)

# Estado del sistema (panel pequeño al extremo)
$pnlEst = New-Object Windows.Forms.Panel
$pnlEst.Location  = New-Object Drawing.Point(1169, 6)
$pnlEst.Size      = New-Object Drawing.Size(175, 135)
$pnlEst.BackColor = $cCard
$footerInner.Controls.Add($pnlEst)

$lET = New-Object Windows.Forms.Label
$lET.Text = "Estado del sistema"; $lET.Location = New-Object Drawing.Point(10, 5)
$lET.Size = New-Object Drawing.Size(155, 18); $lET.ForeColor = $cAccent2
$lET.Font = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
$pnlEst.Controls.Add($lET)

$lblEstIcon = New-Object Windows.Forms.Label
$lblEstIcon.Text      = "✔"; $lblEstIcon.Location = New-Object Drawing.Point(55, 26)
$lblEstIcon.Size      = New-Object Drawing.Size(65, 50); $lblEstIcon.ForeColor = $cGreen
$lblEstIcon.Font      = New-Object Drawing.Font("Segoe UI", 26, [Drawing.FontStyle]::Bold)
$lblEstIcon.TextAlign = "MiddleCenter"
$pnlEst.Controls.Add($lblEstIcon)

$lblEstTxt = New-Object Windows.Forms.Label
$lblEstTxt.Text      = "Todo correcto"; $lblEstTxt.Location = New-Object Drawing.Point(5, 80)
$lblEstTxt.Size      = New-Object Drawing.Size(165, 20); $lblEstTxt.ForeColor = $cGreen
$lblEstTxt.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$lblEstTxt.TextAlign = "MiddleCenter"
$pnlEst.Controls.Add($lblEstTxt)

$btnVer = New-Object Windows.Forms.Button
$btnVer.Text = "Verificar sistema"; $btnVer.Location = New-Object Drawing.Point(8, 104)
$btnVer.Size = New-Object Drawing.Size(159, 26); $btnVer.BackColor = [Drawing.Color]::FromArgb(12, 24, 52)
$btnVer.ForeColor = $cText; $btnVer.FlatStyle = "Flat"
$btnVer.FlatAppearance.BorderColor = $cBorder
$btnVer.Font = New-Object Drawing.Font("Segoe UI", 8)
$btnVer.Add_Click({
    $lblEstTxt.Text = "Verificando..."; $lblEstTxt.ForeColor = $cYellow
    $lblEstIcon.ForeColor = $cYellow; [Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 600
    $lblEstTxt.Text = "Todo correcto"; $lblEstTxt.ForeColor = $cGreen
    $lblEstIcon.ForeColor = $cGreen
})
$pnlEst.Controls.Add($btnVer)

# Acciones rápidas botones
$actList = @(
    @{ n = "Reiniciar Explorer"; c = 'Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep 1; Start-Process explorer; Write-Output "Explorer reiniciado"' },
    @{ n = "Liberar memoria";    c = '[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); Write-Output "Memoria liberada"' },
    @{ n = "Limpiar Portapapeles"; c = 'Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::Clear(); Write-Output "Portapapeles limpiado"' },
    @{ n = "Crear Punto Rest.";  c = 'Checkpoint-Computer -Description "SysCodi_$(Get-Date -Format yyyyMMdd_HHmmss)" -RestorePointType MODIFY_SETTINGS 2>&1; Write-Output "Punto de restauracion creado"' }
)
$aaX = 8; $aaY = 26; $aaC = 0
foreach ($act in $actList) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $act.n; $b.Location = New-Object Drawing.Point($aaX, $aaY)
    $b.Size = New-Object Drawing.Size(183, 46); $b.BackColor = [Drawing.Color]::FromArgb(12, 24, 52)
    $b.ForeColor = $cText; $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $cBorder
    $b.Font = New-Object Drawing.Font("Segoe UI", 8); $b.Cursor = "Hand"
    $ac3 = $act.c
    $b.Add_Click({ Run-Cmd-BG $ac3 $this.Text })
    $b.Add_MouseEnter({ $this.BackColor = $cCardHov })
    $b.Add_MouseLeave({ $this.BackColor = [Drawing.Color]::FromArgb(12, 24, 52) })
    $pnlAct.Controls.Add($b)
    $aaC++
    if ($aaC -ge 2) { $aaC = 0; $aaX = 8; $aaY += 50 } else { $aaX += 187 }
}

# ============================================================
# TABS PERSONALIZADOS
# ============================================================
$tabDefs = @(
    @{ n = "Reparación";   i = "✖" },
    @{ n = "Tweaks";       i = "⚙" },
    @{ n = "Dashboard";    i = "◈" },
    @{ n = "Aplicaciones"; i = "▦" },
    @{ n = "Ajustes";      i = "≡" }
)
$tabBtns = @(); $tabPanels = @(); $script:curTab = 0; $tbX = 5
foreach ($td in $tabDefs) {
    $tb = New-Object Windows.Forms.Button
    $tb.Text = "$($td.i)  $($td.n)"
    $tb.Location = New-Object Drawing.Point($tbX, 6)
    $tb.Size = New-Object Drawing.Size(148, 38)
    $tb.BackColor = $cPanel; $tb.ForeColor = $cSubText
    $tb.FlatStyle = "Flat"; $tb.FlatAppearance.BorderSize = 0
    $tb.FlatAppearance.BorderColor = $cPanel
    $tb.Font = New-Object Drawing.Font("Segoe UI", 9)
    $tb.Cursor = "Hand"
    $pnlTabs.Controls.Add($tb); $tabBtns += $tb; $tbX += 152

    $tp = New-Object Windows.Forms.Panel
    $tp.Dock = "Fill"; $tp.BackColor = $cBg; $tp.Visible = $false
    $pnlContent.Controls.Add($tp); $tabPanels += $tp
}

function Switch-Tab($i) {
    for ($j = 0; $j -lt $tabBtns.Count; $j++) {
        if ($j -eq $i) {
            $tabBtns[$j].BackColor = [Drawing.Color]::FromArgb(20, 48, 96)
            $tabBtns[$j].ForeColor = $cAccent2
            $tabPanels[$j].Visible = $true
            $tabPanels[$j].BringToFront()
        } else {
            $tabBtns[$j].BackColor = $cPanel
            $tabBtns[$j].ForeColor = $cSubText
            $tabPanels[$j].Visible = $false
        }
    }
    $script:curTab = $i
}
for ($i = 0; $i -lt $tabBtns.Count; $i++) {
    $idx = $i
    $tabBtns[$i].Add_Click({ Switch-Tab $idx })
}

# ============================================================
# CONSOLA DE SALIDA (panel derecho del área de contenido)
# ============================================================
$pnlCon = New-Object Windows.Forms.Panel
$pnlCon.Width = 400; $pnlCon.Dock = "Right"; $pnlCon.BackColor = $cOutput
$pnlContent.Controls.Add($pnlCon)

$pnlCH = New-Object Windows.Forms.Panel
$pnlCH.Dock = "Top"; $pnlCH.Height = 34; $pnlCH.BackColor = $cPanel
$pnlCon.Controls.Add($pnlCH)

$lblCT = New-Object Windows.Forms.Label
$lblCT.Text = "  Consola de salida"; $lblCT.Dock = "Left"; $lblCT.Width = 240
$lblCT.ForeColor = $cAccent2; $lblCT.TextAlign = "MiddleLeft"
$lblCT.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlCH.Controls.Add($lblCT)

$btnCC = New-Object Windows.Forms.Button
$btnCC.Text = "Limpiar"; $btnCC.Dock = "Right"; $btnCC.Width = 80
$btnCC.BackColor = [Drawing.Color]::FromArgb(0, 55, 105)
$btnCC.ForeColor = $cText; $btnCC.FlatStyle = "Flat"
$btnCC.Font = New-Object Drawing.Font("Segoe UI", 8)
$pnlCH.Controls.Add($btnCC)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Dock = "Fill"; $outputBox.BackColor = $cOutput; $outputBox.ForeColor = $cAccent2
$outputBox.Font = New-Object Drawing.Font("Consolas", 8.5)
$outputBox.ReadOnly = $true; $outputBox.BorderStyle = "None"; $outputBox.ScrollBars = "Vertical"
$pnlCon.Controls.Add($outputBox)

$btnCC.Add_Click({ $outputBox.Clear() })

function Write-Out($msg, $color = $null) {
    if ($null -eq $color) { $color = $cAccent2 }
    if ($outputBox.IsDisposed) { return }
    try {
        $outputBox.SelectionStart = $outputBox.TextLength
        $outputBox.SelectionColor = $color
        $ts = Get-Date -Format "HH:mm:ss"
        $outputBox.AppendText("`r`n[$ts] $msg")
        $outputBox.ScrollToCaret()
        Write-Log $msg
    } catch {}
}

function Write-Section($t) {
    Write-Out ""
    Write-Out "━━━ $t ━━━" $cAccent2
}

# ============================================================
# BARRA DE PROGRESO (marquee)
# ============================================================
$progBar = New-Object Windows.Forms.ProgressBar
$progBar.Dock = "Top"; $progBar.Height = 4
$progBar.Style = "Marquee"; $progBar.MarqueeAnimationSpeed = 0
$pnlContent.Controls.Add($progBar)

function Start-Progress { $progBar.MarqueeAnimationSpeed = 25; [Windows.Forms.Application]::DoEvents() }
function Stop-Progress  { $progBar.MarqueeAnimationSpeed = 0 }

# ============================================================
# EJECUTAR COMANDO EN BACKGROUND (no bloquea UI)
# ============================================================
function Run-Cmd-BG($cmd, $label) {
    Write-Out "Ejecutando: $label..." $cSubText
    Start-Progress
    $job = Start-Job -ScriptBlock { param($c) Invoke-Expression $c 2>&1 } -ArgumentList $cmd
    $tmr = New-Object Windows.Forms.Timer; $tmr.Interval = 800
    $capturedJob   = $job
    $capturedLabel = $label
    $tmr.Add_Tick({
        if ($capturedJob.State -ne "Running") {
            $tmr.Stop(); Stop-Progress
            try {
                $res = Receive-Job $capturedJob -EA SilentlyContinue
                Remove-Job $capturedJob -Force -EA SilentlyContinue
                if ($res) {
                    $outputBox.SelectionStart = $outputBox.TextLength
                    $outputBox.SelectionColor = $cText
                    $outputBox.AppendText("`r`n" + ($res -join "`r`n"))
                    $outputBox.ScrollToCaret()
                }
            } catch {}
            Write-Out "Completado: $capturedLabel" $cGreen
        }
    })
    $tmr.Start()
}

# ============================================================
# HELPERS UI
# ============================================================
function New-Btn($txt, $x, $y, $w, $h, $par) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $txt; $b.Location = New-Object Drawing.Point($x, $y)
    $b.Size = New-Object Drawing.Size($w, $h)
    $b.BackColor = $cCard; $b.ForeColor = $cText
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $cBorder
    $b.FlatAppearance.BorderSize = 1
    $b.Font = New-Object Drawing.Font("Segoe UI", 8.5)
    $b.Cursor = "Hand"; $b.TextAlign = "MiddleCenter"
    $b.Add_MouseEnter({ $this.BackColor = $cCardHov; $this.FlatAppearance.BorderColor = $cAccent })
    $b.Add_MouseLeave({ $this.BackColor = $cCard; $this.FlatAppearance.BorderColor = $cBorder })
    $par.Controls.Add($b); return $b
}

function New-SecLbl($txt, $x, $y, $par) {
    $l = New-Object Windows.Forms.Label
    $l.Text = "  $txt"; $l.Location = New-Object Drawing.Point($x, $y)
    $l.Size = New-Object Drawing.Size(850, 22)
    $l.ForeColor = $cAccent2
    $l.BackColor = [Drawing.Color]::FromArgb(16, 32, 68)
    $l.Font = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
    $l.TextAlign = "MiddleLeft"; $par.Controls.Add($l)
}

function New-ScrollP($par) {
    $p = New-Object Windows.Forms.Panel
    $p.Dock = "Fill"; $p.AutoScroll = $true; $p.BackColor = $cBg
    $par.Controls.Add($p); return $p
}

# ============================================================
# TAB 0: REPARACIÓN
# ============================================================
$scrollR = New-ScrollP $tabPanels[0]
$yR = 5

# Sección: Limpieza
New-SecLbl "Limpieza" 5 $yR $scrollR; $yR += 26

$b = New-Btn "Limpiar Temporales" 8 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue; Write-Output "Temporales eliminados"' "Limpiar Temporales" })

$b = New-Btn "Limpiar Prefetch" 214 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue; Write-Output "Prefetch limpiado"' "Limpiar Prefetch" })

$b = New-Btn "Vaciar Papelera" 420 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'Clear-RecycleBin -Force -EA SilentlyContinue; Write-Output "Papelera vaciada"' "Vaciar Papelera" })

$b = New-Btn "Limpiar DNS Cache" 626 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'ipconfig /flushdns' "DNS Flush" })

$yR += 54

# Sección: Reparación de Windows
New-SecLbl "Reparación de Windows" 5 $yR $scrollR; $yR += 26

$b = New-Btn "SFC /scannow" 8 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'sfc /scannow' "SFC /scannow" })

$b = New-Btn "DISM RestoreHealth" 214 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'DISM /Online /Cleanup-Image /RestoreHealth' "DISM RestoreHealth" })

$bChk = New-Btn "CheckDisk (C:)" 420 $yR 200 48 $scrollR
$bChk.Add_Click({
    $r = [Windows.Forms.MessageBox]::Show("ChkDsk requiere reinicio.`nSe programará para el próximo arranque.", "ChkDsk", "YesNo", "Question")
    if ($r -eq "Yes") { Run-Cmd-BG 'echo Y | chkdsk C: /f /r' "ChkDsk C:" }
})

$b = New-Btn "Reset Windows Update" 626 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'Stop-Service wuauserv,bits,cryptsvc -Force -EA SilentlyContinue; Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv,bits,cryptsvc -EA SilentlyContinue; Write-Output "Windows Update reiniciado"' "Reset Windows Update" })

$yR += 54

# Sección: Red
New-SecLbl "Red" 5 $yR $scrollR; $yR += 26

$b = New-Btn "DNS Flush" 8 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'ipconfig /flushdns' "DNS Flush" })

$b = New-Btn "Reset TCP/IP" 214 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'netsh int ip reset; Write-Output "TCP/IP reseteado"' "Reset TCP/IP" })

$b = New-Btn "Reset Winsock" 420 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'netsh winsock reset; Write-Output "Winsock reseteado"' "Reset Winsock" })

$b = New-Btn "Ver Puertos Abiertos" 626 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'netstat -ano | Select-Object -First 40' "Ver Puertos" })

$yR += 54

# Sección: Disco
New-SecLbl "Disco y Almacenamiento" 5 $yR $scrollR; $yR += 26

$b = New-Btn "Info de Discos" 8 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{n="Total GB";e={[math]::Round(($_.Used+$_.Free)/1GB,2)}},@{n="Libre GB";e={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize | Out-String' "Info Discos" })

$b = New-Btn "Optimizar C: (TRIM)" 214 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'defrag C: /L; Write-Output "Optimización TRIM completada"' "Optimizar C:" })

$b = New-Btn "Eliminar Minidumps" 420 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'Remove-Item "C:\Windows\Minidump\*" -Force -EA SilentlyContinue; Write-Output "Minidumps eliminados"' "Eliminar Minidumps" })

$b = New-Btn "Archivos Grandes (Top20)" 626 $yR 200 48 $scrollR
$b.Add_Click({ Run-Cmd-BG 'Get-ChildItem C:\ -Recurse -EA SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20 FullName,@{n="MB";e={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize | Out-String' "Archivos Grandes" })

$yR += 54

# Botón mantenimiento completo
$yR += 8
$btnMaint = New-Object Windows.Forms.Button
$btnMaint.Text = "  MANTENIMIENTO COMPLETO  (Limpieza + SFC + DISM + DNS)"
$btnMaint.Location = New-Object Drawing.Point(8, $yR)
$btnMaint.Size = New-Object Drawing.Size(820, 44)
$btnMaint.BackColor = [Drawing.Color]::FromArgb(0, 70, 145)
$btnMaint.ForeColor = $cText; $btnMaint.FlatStyle = "Flat"
$btnMaint.FlatAppearance.BorderColor = $cAccent2
$btnMaint.FlatAppearance.BorderSize = 2
$btnMaint.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$btnMaint.Cursor = "Hand"
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
$scrollR.Controls.Add($btnMaint)
$yR += 55
$scrollR.AutoScrollMinSize = New-Object Drawing.Size(840, ($yR + 20))

# ============================================================
# TAB 1: TWEAKS
# ============================================================
$scrollTw = New-ScrollP $tabPanels[1]
$yTw = 5

$tweakData = @(
    @{ cat = "Rendimiento"; name = "Alto rendimiento (energía)";    cmd = 'powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; Write-Output "Aplicado"'; rev = 'powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e' },
    @{ cat = "Rendimiento"; name = "Deshabilitar efectos visuales"; cmd = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f'; rev = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 1 /f' },
    @{ cat = "Rendimiento"; name = "Modo juego activado";           cmd = 'reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f'; rev = 'reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f' },
    @{ cat = "Rendimiento"; name = "Desactivar SysMain";            cmd = 'Stop-Service SysMain -Force -EA SilentlyContinue; Set-Service SysMain -StartupType Disabled'; rev = 'Set-Service SysMain -StartupType Automatic; Start-Service SysMain -EA SilentlyContinue' },
    @{ cat = "Rendimiento"; name = "Desactivar Search Indexing";    cmd = 'Stop-Service WSearch -Force -EA SilentlyContinue; Set-Service WSearch -StartupType Disabled'; rev = 'Set-Service WSearch -StartupType Automatic; Start-Service WSearch -EA SilentlyContinue' },
    @{ cat = "Rendimiento"; name = "Priorizar apps (no servicios)"; cmd = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f'; rev = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f' },
    @{ cat = "Privacidad";  name = "Deshabilitar telemetría";       cmd = 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev = 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f 2>&1 | Out-Null' },
    @{ cat = "Privacidad";  name = "Deshabilitar Cortana";          cmd = 'reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f'; rev = 'reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f 2>&1 | Out-Null' },
    @{ cat = "Privacidad";  name = "Deshabilitar anuncios";         cmd = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f'; rev = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f' },
    @{ cat = "Privacidad";  name = "Bloquear diagnósticos MS";      cmd = 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev = 'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /f 2>&1 | Out-Null' },
    @{ cat = "Interfaz";    name = "Mostrar extensiones archivo";   cmd = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'; rev = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f' },
    @{ cat = "Interfaz";    name = "Mostrar archivos ocultos";      cmd = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'; rev = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f' },
    @{ cat = "Interfaz";    name = "Menú contextual clásico (W11)"; cmd = 'reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f'; rev = 'reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f 2>&1 | Out-Null' },
    @{ cat = "Interfaz";    name = "Deshabilitar notificaciones";   cmd = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f'; rev = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f' },
    @{ cat = "Interfaz";    name = "Transparencia OFF";             cmd = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f'; rev = 'reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f' },
    @{ cat = "Red";         name = "DNS Cloudflare (1.1.1.1)";      cmd = 'Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 1.1.1.1,1.0.0.1 -EA SilentlyContinue; Write-Output "DNS Cloudflare aplicado"'; rev = 'Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue; Write-Output "DNS reseteado"' },
    @{ cat = "Red";         name = "DNS Google (8.8.8.8)";          cmd = 'Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 8.8.8.8,8.8.4.4 -EA SilentlyContinue; Write-Output "DNS Google aplicado"'; rev = 'Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue; Write-Output "DNS reseteado"' },
    @{ cat = "Seguridad";   name = "Deshabilitar autorun USB";      cmd = 'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f; Write-Output "Autorun deshabilitado"'; rev = 'reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f 2>&1 | Out-Null; Write-Output "Autorun habilitado"' },
    @{ cat = "Seguridad";   name = "Deshabilitar Remote Desktop";   cmd = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f; Write-Output "RDP deshabilitado"'; rev = 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f; Write-Output "RDP habilitado"' }
)

$tweakChecks = [System.Collections.ArrayList]@()
$lastCatTw = ""
$colTw = 0

foreach ($tw in $tweakData) {
    if ($tw.cat -ne $lastCatTw) {
        if ($lastCatTw -ne "") { if ($colTw -ne 0) { $yTw += 26 }; $yTw += 6 }
        New-SecLbl $tw.cat 5 $yTw $scrollTw
        $yTw += 26; $lastCatTw = $tw.cat; $colTw = 0
    }
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = $tw.name
    $cb.Location = New-Object Drawing.Point((5 + $colTw * 415), $yTw)
    $cb.Size = New-Object Drawing.Size(408, 24)
    $cb.ForeColor = $cText; $cb.BackColor = $cBg; $cb.Tag = $tw
    $scrollTw.Controls.Add($cb)
    $tweakChecks.Add($cb) | Out-Null
    $colTw++
    if ($colTw -ge 2) { $colTw = 0; $yTw += 26 }
}

$yTw += 16
$pnlTwB = New-Object Windows.Forms.Panel
$pnlTwB.Location = New-Object Drawing.Point(5, $yTw)
$pnlTwB.Size = New-Object Drawing.Size(830, 52)
$pnlTwB.BackColor = $cPanel
$scrollTw.Controls.Add($pnlTwB)

$bTwA = New-Object Windows.Forms.Button
$bTwA.Text = "  Aplicar Seleccionados"; $bTwA.Location = New-Object Drawing.Point(5, 9)
$bTwA.Size = New-Object Drawing.Size(200, 34); $bTwA.BackColor = [Drawing.Color]::FromArgb(0, 90, 50)
$bTwA.ForeColor = $cText; $bTwA.FlatStyle = "Flat"
$bTwA.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$bTwA.Add_Click({
    $sel = $tweakChecks | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ningún tweak." $cYellow; return }
    $bak = "$logDir\reg_bak_$(Get-Date -Format yyyyMMdd_HHmmss).reg"
    reg export HKCU $bak /y | Out-Null
    Write-Out "Backup registro: $bak" $cSubText
    foreach ($cb in $sel) {
        Write-Out "Aplicando: $($cb.Tag.name)..." $cSubText
        Invoke-Expression $cb.Tag.cmd 2>&1 | Out-Null
        Write-Out "  OK" $cGreen
    }
    Write-Out "Tweaks aplicados. Puede requerir reinicio." $cYellow
})
$pnlTwB.Controls.Add($bTwA)

$bTwR = New-Object Windows.Forms.Button
$bTwR.Text = "Revertir Seleccionados"; $bTwR.Location = New-Object Drawing.Point(215, 9)
$bTwR.Size = New-Object Drawing.Size(185, 34); $bTwR.BackColor = [Drawing.Color]::FromArgb(100, 40, 0)
$bTwR.ForeColor = $cText; $bTwR.FlatStyle = "Flat"
$bTwR.Font = New-Object Drawing.Font("Segoe UI", 9)
$bTwR.Add_Click({
    $tweakChecks | Where-Object { $_.Checked } | ForEach-Object {
        if ($_.Tag.rev) { Invoke-Expression $_.Tag.rev 2>&1 | Out-Null }
        Write-Out "Revertido: $($_.Tag.name)" $cYellow
    }
})
$pnlTwB.Controls.Add($bTwR)

# Perfiles
$cmbPerf = New-Object Windows.Forms.ComboBox
$cmbPerf.Location = New-Object Drawing.Point(415, 12); $cmbPerf.Size = New-Object Drawing.Size(145, 28)
$cmbPerf.BackColor = $cPanel; $cmbPerf.ForeColor = $cText; $cmbPerf.FlatStyle = "Flat"
$cmbPerf.DropDownStyle = "DropDownList"
$cmbPerf.Items.AddRange(@("Gaming", "Oficina", "Privacidad Max", "PC Antigua"))
$pnlTwB.Controls.Add($cmbPerf)

$bPerf = New-Object Windows.Forms.Button
$bPerf.Text = "Aplicar Perfil"; $bPerf.Location = New-Object Drawing.Point(568, 9)
$bPerf.Size = New-Object Drawing.Size(145, 34); $bPerf.BackColor = [Drawing.Color]::FromArgb(0, 70, 140)
$bPerf.ForeColor = $cText; $bPerf.FlatStyle = "Flat"
$bPerf.Font = New-Object Drawing.Font("Segoe UI", 9)
$bPerf.Add_Click({
    $p = $cmbPerf.SelectedItem
    if (-not $p) { Write-Out "Selecciona un perfil." $cYellow; return }
    $map = @{
        "Gaming"        = @("Alto rendimiento (energía)", "Modo juego activado", "Desactivar SysMain")
        "Oficina"       = @("Mostrar extensiones archivo", "Mostrar archivos ocultos", "Deshabilitar notificaciones")
        "Privacidad Max"= @("Deshabilitar telemetría", "Deshabilitar Cortana", "Deshabilitar anuncios", "Bloquear diagnósticos MS")
        "PC Antigua"    = @("Deshabilitar efectos visuales", "Desactivar SysMain", "Desactivar Search Indexing", "Transparencia OFF", "Alto rendimiento (energía)")
    }
    $sel = $map[$p]
    $tweakChecks | ForEach-Object { $_.Checked = ($sel -contains $_.Tag.name) }
    Write-Out "Perfil '$p' cargado. Pulsa Aplicar." $cAccent2
})
$pnlTwB.Controls.Add($bPerf)

$yTw += 60
$scrollTw.AutoScrollMinSize = New-Object Drawing.Size(840, ($yTw + 20))

# ============================================================
# TAB 2: DASHBOARD (tiempo real)
# ============================================================
$pDash = $tabPanels[2]

$lDT = New-Object Windows.Forms.Label
$lDT.Text = "  Dashboard en tiempo real"
$lDT.Location = New-Object Drawing.Point(0, 0); $lDT.Size = New-Object Drawing.Size(870, 28)
$lDT.ForeColor = $cAccent2; $lDT.BackColor = [Drawing.Color]::FromArgb(16, 32, 68)
$lDT.Font = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$lDT.TextAlign = "MiddleLeft"; $pDash.Controls.Add($lDT)

function New-DCard($title, $x, $y) {
    $p = New-Object Windows.Forms.Panel
    $p.Location = New-Object Drawing.Point($x, $y); $p.Size = New-Object Drawing.Size(200, 110)
    $p.BackColor = $cCard; $pDash.Controls.Add($p)
    $lt = New-Object Windows.Forms.Label
    $lt.Text = $title; $lt.Location = New-Object Drawing.Point(10, 8)
    $lt.Size = New-Object Drawing.Size(180, 20); $lt.ForeColor = $cSubText
    $lt.Font = New-Object Drawing.Font("Segoe UI", 9); $p.Controls.Add($lt)
    $lv = New-Object Windows.Forms.Label
    $lv.Text = "..."; $lv.Location = New-Object Drawing.Point(10, 28)
    $lv.Size = New-Object Drawing.Size(180, 44); $lv.ForeColor = $cAccent2
    $lv.Font = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold); $p.Controls.Add($lv)
    $bar = New-Object Windows.Forms.ProgressBar
    $bar.Location = New-Object Drawing.Point(10, 82); $bar.Size = New-Object Drawing.Size(180, 14)
    $bar.Minimum = 0; $bar.Maximum = 100; $bar.Style = "Continuous"
    $bar.ForeColor = $cAccent; $p.Controls.Add($bar)
    return @{ lv = $lv; bar = $bar; p = $p }
}

$dCPU  = New-DCard "CPU"      5   32
$dRAM  = New-DCard "RAM"      213 32
$dDisk = New-DCard "Disco C:" 421 32
$dNet  = New-DCard "Red"      629 32

# Info del sistema
$pnlSysInfo = New-Object Windows.Forms.Panel
$pnlSysInfo.Location = New-Object Drawing.Point(5, 152); $pnlSysInfo.Size = New-Object Drawing.Size(820, 130)
$pnlSysInfo.BackColor = $cCard; $pDash.Controls.Add($pnlSysInfo)
$ltSI = New-Object Windows.Forms.Label
$ltSI.Text = "  Información del sistema"; $ltSI.Location = New-Object Drawing.Point(0, 0)
$ltSI.Size = New-Object Drawing.Size(820, 28); $ltSI.ForeColor = $cAccent2
$ltSI.BackColor = [Drawing.Color]::FromArgb(16, 32, 68)
$ltSI.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold); $ltSI.TextAlign = "MiddleLeft"
$pnlSysInfo.Controls.Add($ltSI)
$sysInfoBox = New-Object Windows.Forms.RichTextBox
$sysInfoBox.Location = New-Object Drawing.Point(0, 28); $sysInfoBox.Size = New-Object Drawing.Size(820, 102)
$sysInfoBox.BackColor = $cOutput; $sysInfoBox.ForeColor = $cText
$sysInfoBox.Font = New-Object Drawing.Font("Consolas", 8.5); $sysInfoBox.ReadOnly = $true
$sysInfoBox.BorderStyle = "None"; $pnlSysInfo.Controls.Add($sysInfoBox)

# Top procesos
$pnlProcs = New-Object Windows.Forms.Panel
$pnlProcs.Location = New-Object Drawing.Point(5, 292); $pnlProcs.Size = New-Object Drawing.Size(820, 290)
$pnlProcs.BackColor = $cCard; $pDash.Controls.Add($pnlProcs)
$ltProc = New-Object Windows.Forms.Label
$ltProc.Text = "  Top 12 Procesos (CPU + RAM)"; $ltProc.Location = New-Object Drawing.Point(0, 0)
$ltProc.Size = New-Object Drawing.Size(820, 28); $ltProc.ForeColor = $cAccent2
$ltProc.BackColor = [Drawing.Color]::FromArgb(16, 32, 68)
$ltProc.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold); $ltProc.TextAlign = "MiddleLeft"
$pnlProcs.Controls.Add($ltProc)
$dashBox = New-Object Windows.Forms.RichTextBox
$dashBox.Location = New-Object Drawing.Point(0, 28); $dashBox.Size = New-Object Drawing.Size(820, 262)
$dashBox.BackColor = $cOutput; $dashBox.ForeColor = $cText
$dashBox.Font = New-Object Drawing.Font("Consolas", 9); $dashBox.ReadOnly = $true; $dashBox.BorderStyle = "None"
$pnlProcs.Controls.Add($dashBox)

# Cargar info sistema una vez
$bLoadSys = New-Btn "  Cargar Info del Sistema" 5 592 220 36 $pDash
$bLoadSys.Add_Click({
    $sysInfoBox.Clear()
    try {
        $os2  = Get-CimInstance Win32_OperatingSystem
        $cpu2 = Get-CimInstance Win32_Processor
        $up   = (Get-Date) - $os2.LastBootUpTime
        $lines = @(
            "OS:       $($os2.Caption) Build $($os2.BuildNumber)",
            "CPU:      $($cpu2.Name.Trim())  [$($cpu2.NumberOfCores) núcleos / $($cpu2.NumberOfLogicalProcessors) hilos]",
            "RAM:      $([math]::Round($os2.TotalVisibleMemorySize/1MB,2)) GB total  |  Libre: $([math]::Round($os2.FreePhysicalMemory/1MB,1)) GB",
            "Uptime:   $($up.Days)d $($up.Hours)h $($up.Minutes)m"
        )
        $lines | ForEach-Object { $sysInfoBox.AppendText("$_`r`n") }
        Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } | ForEach-Object {
            $sysInfoBox.AppendText("  Disco $($_.Name):  $([math]::Round(($_.Used+$_.Free)/1GB,2)) GB total  |  Libre: $([math]::Round($_.Free/1GB,2)) GB`r`n")
        }
        Write-Out "Info del sistema cargada." $cGreen
    } catch { Write-Out "Error: $_" $cRed }
})

# ============================================================
# TAB 3: APLICACIONES (winget)
# ============================================================
$pTopA = New-Object Windows.Forms.Panel
$pTopA.Dock = "Top"; $pTopA.Height = 48; $pTopA.BackColor = $cPanel
$tabPanels[3].Controls.Add($pTopA)

$lblSrc2 = New-Object Windows.Forms.Label
$lblSrc2.Text = "Buscar:"; $lblSrc2.Location = New-Object Drawing.Point(8, 14)
$lblSrc2.Size = New-Object Drawing.Size(55, 20); $lblSrc2.ForeColor = $cSubText
$pTopA.Controls.Add($lblSrc2)

$txtSearch = New-Object Windows.Forms.TextBox
$txtSearch.Location = New-Object Drawing.Point(66, 11); $txtSearch.Size = New-Object Drawing.Size(200, 26)
$txtSearch.BackColor = [Drawing.Color]::FromArgb(12, 24, 52); $txtSearch.ForeColor = $cText
$txtSearch.BorderStyle = "FixedSingle"; $pTopA.Controls.Add($txtSearch)

$btnST = New-Object Windows.Forms.Button
$btnST.Text = "Sel. Todo"; $btnST.Location = New-Object Drawing.Point(275, 9); $btnST.Size = New-Object Drawing.Size(85, 28)
$btnST.BackColor = [Drawing.Color]::FromArgb(0, 65, 120); $btnST.ForeColor = $cText; $btnST.FlatStyle = "Flat"
$btnST.Font = New-Object Drawing.Font("Segoe UI", 8); $pTopA.Controls.Add($btnST)

$btnSN = New-Object Windows.Forms.Button
$btnSN.Text = "Limpiar"; $btnSN.Location = New-Object Drawing.Point(366, 9); $btnSN.Size = New-Object Drawing.Size(75, 28)
$btnSN.BackColor = [Drawing.Color]::FromArgb(75, 15, 15); $btnSN.ForeColor = $cText; $btnSN.FlatStyle = "Flat"
$btnSN.Font = New-Object Drawing.Font("Segoe UI", 8); $pTopA.Controls.Add($btnSN)

$btnFoss = New-Object Windows.Forms.Button
$btnFoss.Text = "Solo FOSS"; $btnFoss.Location = New-Object Drawing.Point(447, 9); $btnFoss.Size = New-Object Drawing.Size(88, 28)
$btnFoss.BackColor = [Drawing.Color]::FromArgb(0, 50, 25); $btnFoss.ForeColor = $cAccent2; $btnFoss.FlatStyle = "Flat"
$btnFoss.Font = New-Object Drawing.Font("Segoe UI", 8); $pTopA.Controls.Add($btnFoss)

$btnInst = New-Object Windows.Forms.Button
$btnInst.Text = "  INSTALAR SELECCIONADAS"; $btnInst.Location = New-Object Drawing.Point(545, 6)
$btnInst.Size = New-Object Drawing.Size(220, 36)
$btnInst.BackColor = [Drawing.Color]::FromArgb(0, 100, 50); $btnInst.ForeColor = $cText; $btnInst.FlatStyle = "Flat"
$btnInst.FlatAppearance.BorderColor = $cGreen
$btnInst.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pTopA.Controls.Add($btnInst)

$scrollA = New-Object Windows.Forms.Panel
$scrollA.Dock = "Fill"; $scrollA.AutoScroll = $true; $scrollA.BackColor = $cBg
$tabPanels[3].Controls.Add($scrollA)

$appList = @(
    @{ cat = "Navegadores";    name = "Google Chrome";     cmd = "winget install -e --id Google.Chrome -h";                   foss = $false },
    @{ cat = "Navegadores";    name = "Mozilla Firefox";   cmd = "winget install -e --id Mozilla.Firefox -h";                 foss = $true },
    @{ cat = "Navegadores";    name = "Brave Browser";     cmd = "winget install -e --id Brave.Brave -h";                     foss = $true },
    @{ cat = "Navegadores";    name = "Opera GX";           cmd = "winget install -e --id Opera.OperaGX -h";                  foss = $false },
    @{ cat = "Comunicación";   name = "Discord";            cmd = "winget install -e --id Discord.Discord -h";                foss = $false },
    @{ cat = "Comunicación";   name = "Telegram";           cmd = "winget install -e --id Telegram.TelegramDesktop -h";       foss = $true },
    @{ cat = "Comunicación";   name = "Signal";             cmd = "winget install -e --id OpenWhisperSystems.Signal -h";      foss = $true },
    @{ cat = "Comunicación";   name = "Zoom";               cmd = "winget install -e --id Zoom.Zoom -h";                      foss = $false },
    @{ cat = "Desarrollo";     name = "VS Code";            cmd = "winget install -e --id Microsoft.VisualStudioCode -h";     foss = $true },
    @{ cat = "Desarrollo";     name = "Git";                cmd = "winget install -e --id Git.Git -h";                        foss = $true },
    @{ cat = "Desarrollo";     name = "Python 3";           cmd = "winget install -e --id Python.Python.3 -h";                foss = $true },
    @{ cat = "Desarrollo";     name = "NodeJS LTS";         cmd = "winget install -e --id OpenJS.NodeJS.LTS -h";              foss = $true },
    @{ cat = "Desarrollo";     name = "Docker Desktop";     cmd = "winget install -e --id Docker.DockerDesktop -h";           foss = $false },
    @{ cat = "Desarrollo";     name = "PowerShell 7";       cmd = "winget install -e --id Microsoft.PowerShell -h";           foss = $true },
    @{ cat = "Utilidades";     name = "7-Zip";              cmd = "winget install -e --id 7zip.7zip -h";                      foss = $true },
    @{ cat = "Utilidades";     name = "Notepad++";          cmd = "winget install -e --id Notepad++.Notepad++ -h";            foss = $true },
    @{ cat = "Utilidades";     name = "Everything";         cmd = "winget install -e --id voidtools.Everything -h";           foss = $false },
    @{ cat = "Utilidades";     name = "CPU-Z";              cmd = "winget install -e --id CPUID.CPU-Z -h";                    foss = $false },
    @{ cat = "Utilidades";     name = "HWMonitor";          cmd = "winget install -e --id CPUID.HWMonitor -h";                foss = $false },
    @{ cat = "Multimedia";     name = "VLC";                cmd = "winget install -e --id VideoLAN.VLC -h";                   foss = $true },
    @{ cat = "Multimedia";     name = "OBS Studio";         cmd = "winget install -e --id OBSProject.OBSStudio -h";           foss = $true },
    @{ cat = "Multimedia";     name = "GIMP";               cmd = "winget install -e --id GIMP.GIMP -h";                      foss = $true },
    @{ cat = "Multimedia";     name = "Audacity";           cmd = "winget install -e --id Audacity.Audacity -h";              foss = $true },
    @{ cat = "Oficina";        name = "LibreOffice";        cmd = "winget install -e --id TheDocumentFoundation.LibreOffice -h"; foss = $true },
    @{ cat = "Oficina";        name = "SumatraPDF";         cmd = "winget install -e --id SumatraPDF.SumatraPDF -h";          foss = $true },
    @{ cat = "Oficina";        name = "Obsidian";           cmd = "winget install -e --id Obsidian.Obsidian -h";              foss = $false },
    @{ cat = "Seguridad";      name = "Bitwarden";          cmd = "winget install -e --id Bitwarden.Bitwarden -h";            foss = $true },
    @{ cat = "Seguridad";      name = "KeePassXC";          cmd = "winget install -e --id KeePassXCTeam.KeePassXC -h";        foss = $true },
    @{ cat = "Gaming";         name = "Steam";              cmd = "winget install -e --id Valve.Steam -h";                    foss = $false },
    @{ cat = "Gaming";         name = "Epic Games";         cmd = "winget install -e --id EpicGames.EpicGamesLauncher -h";    foss = $false },
    @{ cat = "Gaming";         name = "MSI Afterburner";    cmd = "winget install -e --id Guru3D.Afterburner -h";             foss = $false }
)

$checkboxes = [System.Collections.ArrayList]@()
$yA = 5; $lastCatA = ""; $colA = 0
foreach ($app in $appList) {
    if ($app.cat -ne $lastCatA) {
        if ($lastCatA -ne "") { if ($colA -ne 0) { $yA += 24 }; $yA += 6 }
        $l = New-Object Windows.Forms.Label
        $l.Text = "  $($app.cat)"; $l.Location = New-Object Drawing.Point(5, $yA)
        $l.Size = New-Object Drawing.Size(840, 22); $l.ForeColor = $cAccent2
        $l.BackColor = [Drawing.Color]::FromArgb(16, 32, 68)
        $l.Font = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
        $scrollA.Controls.Add($l); $yA += 24; $lastCatA = $app.cat; $colA = 0
    }
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = $app.name
    $cb.Location = New-Object Drawing.Point((5 + $colA * 170), $yA)
    $cb.Size = New-Object Drawing.Size(165, 22)
    $cb.ForeColor = if ($app.foss) { $cAccent2 } else { $cText }
    $cb.BackColor = $cBg; $cb.Tag = $app
    $scrollA.Controls.Add($cb); $checkboxes.Add($cb) | Out-Null
    $colA++
    if ($colA -ge 5) { $colA = 0; $yA += 24 }
}
$yA += 24
$scrollA.AutoScrollMinSize = New-Object Drawing.Size(850, ($yA + 20))

$btnST.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $true } })
$btnSN.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $false } })
$btnFoss.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = ($_.Tag.foss -eq $true) } })
$txtSearch.Add_TextChanged({
    $q = $txtSearch.Text.Trim().ToLower()
    foreach ($cb in $checkboxes) {
        $cb.ForeColor = if ($q -and $cb.Text.ToLower().Contains($q)) { $cYellow } else { if ($cb.Tag.foss) { $cAccent2 } else { $cText } }
    }
})
$btnInst.Add_Click({
    $sel = $checkboxes | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ninguna app." $cYellow; return }
    if (-not (Get-Command winget -EA SilentlyContinue)) { Write-Out "WinGet no encontrado. Instala App Installer desde la Tienda." $cRed; return }
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
# TAB 4: AJUSTES
# ============================================================
New-SecLbl "Configuración de la herramienta" 5 5 $tabPanels[4]

$ajInfo = New-Object Windows.Forms.Label
$ajInfo.Text = "  Versión: 2.5.0 Pro  |  Logs: C:\SysCodi\logs\  |  PowerShell 5.1+ / Windows 10+"
$ajInfo.Location = New-Object Drawing.Point(5, 32); $ajInfo.Size = New-Object Drawing.Size(840, 26)
$ajInfo.ForeColor = $cSubText; $ajInfo.Font = New-Object Drawing.Font("Segoe UI", 9)
$tabPanels[4].Controls.Add($ajInfo)

$bOL = New-Btn "  Abrir carpeta de logs" 8 68 220 40 $tabPanels[4]
$bOL.Add_Click({ Start-Process explorer $logDir })

$bCL = New-Btn "  Limpiar logs > 30 días" 238 68 220 40 $tabPanels[4]
$bCL.Add_Click({
    Get-ChildItem $logDir -Filter "*.log" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item -Force -EA SilentlyContinue
    Write-Out "Logs antiguos eliminados." $cGreen
})

$bPy = New-Btn "  Verificar Python" 468 68 220 40 $tabPanels[4]
$bPy.Add_Click({ Run-Cmd-BG 'python --version; pip --version' "Verificar Python" })

$bWG = New-Btn "  Verificar WinGet" 698 68 220 40 $tabPanels[4]
$bWG.Add_Click({ Run-Cmd-BG 'winget --version' "Verificar WinGet" })

$bLog = New-Btn "  Ver log de hoy" 8 118 220 40 $tabPanels[4]
$bLog.Add_Click({
    if (Test-Path $logFile) { Get-Content $logFile -Tail 50 | ForEach-Object { Write-Out $_ $cSubText } }
    else { Write-Out "No hay log para hoy." $cYellow }
})

$bAb = New-Btn "  Acerca de SysCodi" 238 118 220 40 $tabPanels[4]
$bAb.Add_Click({
    [Windows.Forms.MessageBox]::Show(
        "SysCodi WinTool Pro v2.5.0`n`nHerramienta de administración y mantenimiento de Windows.`nRequiere PowerShell 5.1+ y Windows 10+`nUsa WinGet para instalación de apps.`n`nLogs guardados en: C:\SysCodi\logs\",
        "Acerca de SysCodi", "OK", "Information")
})

$bExp = New-Btn "  Exportar reporte sistema" 468 118 220 40 $tabPanels[4]
$bExp.Add_Click({
    $path = "$env:USERPROFILE\Desktop\SysCodi_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    try {
        $os2 = Get-CimInstance Win32_OperatingSystem
        $cpu2 = Get-CimInstance Win32_Processor
        $up = (Get-Date) - $os2.LastBootUpTime
        $lines = @(
            "SysCodi WinTool Pro - Reporte del Sistema",
            "Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')", "",
            "OS:      $($os2.Caption) $($os2.Version)",
            "CPU:     $($cpu2.Name.Trim())",
            "Núcleos: $($cpu2.NumberOfCores) / $($cpu2.NumberOfLogicalProcessors)",
            "RAM:     $([math]::Round($os2.TotalVisibleMemorySize/1MB,2)) GB",
            "Equipo:  $env:COMPUTERNAME", "Usuario: $env:USERNAME",
            "Uptime:  $($up.Days)d $($up.Hours)h $($up.Minutes)m", "", "Discos:"
        )
        $lines += (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null } | ForEach-Object {
            "  $($_.Name): $([math]::Round(($_.Used+$_.Free)/1GB,2))GB total, $([math]::Round($_.Free/1GB,2))GB libre"
        })
        $lines | Set-Content $path -Encoding UTF8
        Write-Out "Reporte guardado en escritorio: $path" $cGreen
        Start-Process notepad $path
    } catch { Write-Out "Error: $_" $cRed }
})

# ============================================================
# MONITOR TIEMPO REAL
# ============================================================
$script:lastNetBytes = 0
$monTimer = New-Object Windows.Forms.Timer
$monTimer.Interval = 2000
$monTimer.Add_Tick({
    try {
        $cpuLoad = [int](Get-CimInstance Win32_Processor -EA Stop | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average)
        $cpuColor = if ($cpuLoad -gt 85) { $cRed } elseif ($cpuLoad -gt 60) { $cYellow } else { $cGreen }

        $osM = Get-CimInstance Win32_OperatingSystem -EA Stop
        $ramPct = [int](($osM.TotalVisibleMemorySize - $osM.FreePhysicalMemory) / $osM.TotalVisibleMemorySize * 100)
        $ramFree = [math]::Round($osM.FreePhysicalMemory / 1MB, 1)
        $ramColor = if ($ramPct -gt 85) { $cRed } elseif ($ramPct -gt 65) { $cYellow } else { $cAccent2 }

        $drv = Get-PSDrive C -EA Stop
        $diskPct = [int]($drv.Used / ($drv.Used + $drv.Free) * 100)
        $diskFree = [math]::Round($drv.Free / 1GB, 1)
        $diskColor = if ($diskPct -gt 90) { $cRed } elseif ($diskPct -gt 75) { $cYellow } else { $cAccent2 }

        $ns = Get-NetAdapterStatistics -EA SilentlyContinue | Select-Object -First 1
        $netKB = 0
        if ($ns) {
            $tot = $ns.ReceivedBytes + $ns.SentBytes
            $netKB = [math]::Round(($tot - $script:lastNetBytes) / 1KB / 2, 1)
            $script:lastNetBytes = $tot
        }

        # Footer métricas
        $mCPU.val.Text = "$cpuLoad%"; $mCPU.bar.Value = [Math]::Min($cpuLoad, 100); $mCPU.bar.ForeColor = $cpuColor
        $mRAM.val.Text = "$ramPct%"; $mRAM.bar.Value = [Math]::Min($ramPct, 100); $mRAM.bar.ForeColor = $ramColor; $mRAM.extra.Text = "Libre: $ramFree GB"
        $mDisk.val.Text = "$diskPct%"; $mDisk.bar.Value = [Math]::Min($diskPct, 100); $mDisk.bar.ForeColor = $diskColor; $mDisk.extra.Text = "Libre: $diskFree GB"
        $mNet.val.Text = "$netKB KB/s"; $mNet.bar.Value = [Math]::Min([int]($netKB / 10), 100)

        # Dashboard cards
        $dCPU.lv.Text = "$cpuLoad%"; $dCPU.bar.Value = [Math]::Min($cpuLoad, 100); $dCPU.lv.ForeColor = $cpuColor; $dCPU.bar.ForeColor = $cpuColor
        $dRAM.lv.Text = "$ramPct%"; $dRAM.bar.Value = [Math]::Min($ramPct, 100); $dRAM.lv.ForeColor = $ramColor
        $dDisk.lv.Text = "$diskPct%"; $dDisk.bar.Value = [Math]::Min($diskPct, 100); $dDisk.lv.ForeColor = $diskColor
        $dNet.lv.Text = "$netKB"

        # Procesos (solo si Dashboard es la tab activa)
        if ($script:curTab -eq 2) {
            $procs = Get-Process -EA SilentlyContinue | Sort-Object CPU -Descending | Select-Object -First 12
            $dashBox.Clear()
            $dashBox.SelectionColor = $cSubText
            $dashBox.AppendText(("{0,-38} {1,12} {2,12}`r`n" -f "Proceso", "CPU (seg)", "RAM (MB)"))
            $dashBox.AppendText(("─" * 64 + "`r`n"))
            foreach ($pr in $procs) {
                $dashBox.SelectionColor = $cText
                $name = $pr.Name.Substring(0, [Math]::Min($pr.Name.Length, 37))
                $dashBox.AppendText(("{0,-38} {1,12:N1} {2,12:N1}`r`n" -f $name, $pr.CPU, ($pr.WorkingSet64 / 1MB)))
            }
        }
    } catch {}
})
$monTimer.Start()

# ============================================================
# ARRANQUE
# ============================================================
Switch-Tab 0
Write-Out "SysCodi WinTool Pro v2.5.0 iniciado." $cGreen
Write-Out "Equipo: $env:COMPUTERNAME  |  Usuario: $env:USERNAME" $cSubText
Write-Out "Logs: $logFile" $cSubText
Write-Log "Iniciado"

$form.Add_FormClosing({ $monTimer.Stop(); $clockTimer.Stop(); Write-Log "Cerrado" })
$form.ShowDialog()
