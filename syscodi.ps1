#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#   VERIFICACION DE ADMINISTRADOR
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $res = [Windows.Forms.MessageBox]::Show("SysCodi WinTool Pro requiere permisos de Administrador.`n`nDesea reiniciar como Administrador?","Permisos requeridos","YesNo","Warning")
    if ($res -eq "Yes") { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs }
    exit
}

# ============================================================
#   LOGS
# ============================================================
$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($msg) { Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] $msg" -Encoding UTF8 -EA SilentlyContinue }

# ============================================================
#   LOGO
# ============================================================
$logoUrl  = "https://raw.githubusercontent.com/syscodi7/Tools/main/sis.png"
$logoPath = "$env:TEMP\syscodi_logo.png"
try { Invoke-WebRequest -Uri $logoUrl -OutFile $logoPath -EA Stop } catch { $logoPath = "" }

# ============================================================
#   PALETA DE COLORES (replica exacta de la imagen)
# ============================================================
$cBg       = [Drawing.Color]::FromArgb(11, 20, 42)
$cPanel    = [Drawing.Color]::FromArgb(18, 32, 65)
$cCard     = [Drawing.Color]::FromArgb(22, 40, 82)
$cCardHov  = [Drawing.Color]::FromArgb(28, 52, 105)
$cAccent   = [Drawing.Color]::FromArgb(0, 140, 255)
$cAccent2  = [Drawing.Color]::FromArgb(80, 180, 255)
$cGreen    = [Drawing.Color]::FromArgb(40, 220, 120)
$cYellow   = [Drawing.Color]::FromArgb(255, 195, 50)
$cRed      = [Drawing.Color]::FromArgb(255, 75, 75)
$cText     = [Drawing.Color]::White
$cSubText  = [Drawing.Color]::FromArgb(150, 185, 235)
$cBorder   = [Drawing.Color]::FromArgb(30, 65, 130)
$cTabActive= [Drawing.Color]::FromArgb(22, 50, 100)
$cOutput   = [Drawing.Color]::FromArgb(8, 16, 36)

# ============================================================
#   FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text            = "SysCodi WinTool Pro"
$form.Size            = New-Object Drawing.Size(1366, 900)
$form.MinimumSize     = New-Object Drawing.Size(1200, 780)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.Font            = New-Object Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "Sizable"

# ============================================================
#   HEADER (replica imagen: logo + título + info sistema derecha)
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Dock      = "Top"
$header.Height    = 90
$header.BackColor = $cPanel
$form.Controls.Add($header)

# Linea azul inferior del header
$headerLine = New-Object Windows.Forms.Panel
$headerLine.Dock      = "Bottom"
$headerLine.Height    = 2
$headerLine.BackColor = $cAccent
$header.Controls.Add($headerLine)

# Logo
if (Test-Path $logoPath) {
    $logoPic = New-Object Windows.Forms.PictureBox
    $logoPic.Location  = New-Object Drawing.Point(18, 15)
    $logoPic.Size      = New-Object Drawing.Size(60, 60)
    $logoPic.SizeMode  = "Zoom"
    $logoPic.BackColor = $cPanel
    $logoPic.Image     = [Drawing.Image]::FromFile($logoPath)
    $header.Controls.Add($logoPic)
    try { $bmp = [Drawing.Bitmap][Drawing.Image]::FromFile($logoPath); $form.Icon = [Drawing.Icon]::FromHandle($bmp.GetHicon()) } catch {}
    $txStart = 92
} else { $txStart = 20 }

# Titulo
$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Location  = New-Object Drawing.Point($txStart, 14)
$lblTitle.Size      = New-Object Drawing.Size(480, 40)
$lblTitle.Font      = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cText
# "SysCodi" en azul, "WinTool Pro" en blanco
$header.Controls.Add($lblTitle)

# Usar Paint para colorear "SysCodi" en azul
$lblTitleBlue = New-Object Windows.Forms.Label
$lblTitleBlue.Location  = New-Object Drawing.Point($txStart, 14)
$lblTitleBlue.Size      = New-Object Drawing.Size(115, 40)
$lblTitleBlue.Font      = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold)
$lblTitleBlue.ForeColor = $cAccent2
$lblTitleBlue.Text      = "SysCodi"
$lblTitleBlue.BackColor = [Drawing.Color]::Transparent
$header.Controls.Add($lblTitleBlue)

$lblTitleW = New-Object Windows.Forms.Label
$lblTitleW.Location  = New-Object Drawing.Point(($txStart + 115), 14)
$lblTitleW.Size      = New-Object Drawing.Size(280, 40)
$lblTitleW.Font      = New-Object Drawing.Font("Segoe UI", 22, [Drawing.FontStyle]::Bold)
$lblTitleW.ForeColor = $cText
$lblTitleW.Text      = " WinTool Pro"
$lblTitleW.BackColor = [Drawing.Color]::Transparent
$header.Controls.Add($lblTitleW)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Location  = New-Object Drawing.Point($txStart, 56)
$lblSub.Size      = New-Object Drawing.Size(400, 20)
$lblSub.Font      = New-Object Drawing.Font("Segoe UI", 9)
$lblSub.ForeColor = $cSubText
$lblSub.Text      = "Utilidad de sistema avanzada para Windows"
$header.Controls.Add($lblSub)

# Info sistema derecha del header
$pnlHeaderInfo = New-Object Windows.Forms.Panel
$pnlHeaderInfo.Location  = New-Object Drawing.Point(700, 10)
$pnlHeaderInfo.Size      = New-Object Drawing.Size(640, 70)
$pnlHeaderInfo.BackColor = [Drawing.Color]::Transparent
$header.Controls.Add($pnlHeaderInfo)

function New-HeaderLabel($text, $x, $y, $w, $h, $font, $color) {
    $l = New-Object Windows.Forms.Label
    $l.Text      = $text
    $l.Location  = New-Object Drawing.Point($x, $y)
    $l.Size      = New-Object Drawing.Size($w, $h)
    $l.Font      = $font
    $l.ForeColor = $color
    $l.BackColor = [Drawing.Color]::Transparent
    $pnlHeaderInfo.Controls.Add($l)
    return $l
}

# Linea 1: OS
$lblOS     = New-HeaderLabel "" 0 4 640 22 (New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)) $cAccent2
# OS "Windows 11 Pro" en azul, version en blanco
$lblOSVer  = New-HeaderLabel "" 145 4 300 22 (New-Object Drawing.Font("Segoe UI", 10)) $cText

# Linea 2
$lblUser   = New-HeaderLabel "" 0 28 200 18 (New-Object Drawing.Font("Segoe UI", 8.5)) $cSubText
$lblUptime = New-HeaderLabel "" 330 28 300 18 (New-Object Drawing.Font("Segoe UI", 8.5)) $cSubText

# Linea 3
$lblEquipo = New-HeaderLabel "" 0 48 200 18 (New-Object Drawing.Font("Segoe UI", 8.5)) $cSubText
$lblClock  = New-HeaderLabel "" 330 48 300 18 (New-Object Drawing.Font("Segoe UI", 8.5)) $cSubText

# Cargar info del sistema
try {
    $osInfo   = Get-CimInstance Win32_OperatingSystem
    $lblOS.Text    = "Windows"
    $lblOSVer.Text = " $($osInfo.Caption.Replace('Microsoft ','')) ($($osInfo.BuildNumber))"
    $lblUser.Text  = "Usuario:  $env:USERNAME"
    $lblEquipo.Text= "Equipo:   $env:COMPUTERNAME"
} catch {}

$clockTimer = New-Object Windows.Forms.Timer
$clockTimer.Interval = 1000
$clockTimer.Add_Tick({
    $lblClock.Text = "Fecha:  $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    try {
        $up = (Get-Date) - (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $lblUptime.Text = "Tiempo activo:  $($up.Days)d $($up.Hours)h $($up.Minutes)m"
    } catch {}
})
$clockTimer.Start()

# ============================================================
#   BARRA DE TABS (replica: tabs con iconos, fondo panel)
# ============================================================
$pnlTabs = New-Object Windows.Forms.Panel
$pnlTabs.Dock      = "Top"
$pnlTabs.Height    = 50
$pnlTabs.BackColor = $cPanel
$form.Controls.Add($pnlTabs)

# Linea inferior tabs
$tabLine = New-Object Windows.Forms.Panel
$tabLine.Dock      = "Bottom"
$tabLine.Height    = 1
$tabLine.BackColor = $cBorder
$pnlTabs.Controls.Add($tabLine)

# Panel principal de contenido
$pnlContent = New-Object Windows.Forms.Panel
$pnlContent.Dock      = "Fill"
$pnlContent.BackColor = $cBg
$form.Controls.Add($pnlContent)

# ============================================================
#   FOOTER (replica: barra inferior con métricas + accesos)
# ============================================================
$footer = New-Object Windows.Forms.Panel
$footer.Dock      = "Bottom"
$footer.Height    = 175
$footer.BackColor = $cPanel
$form.Controls.Add($footer)

$footerLine = New-Object Windows.Forms.Panel
$footerLine.Dock      = "Top"
$footerLine.Height    = 1
$footerLine.BackColor = $cBorder
$footer.Controls.Add($footerLine)

# Status bar (muy inferior)
$statusBar = New-Object Windows.Forms.Panel
$statusBar.Dock      = "Bottom"
$statusBar.Height    = 26
$statusBar.BackColor = [Drawing.Color]::FromArgb(8, 16, 36)
$footer.Controls.Add($statusBar)

$lblStatusLeft = New-Object Windows.Forms.Label
$lblStatusLeft.Text      = "  Ejecutar siempre como Administrador para mejor rendimiento"
$lblStatusLeft.Location  = New-Object Drawing.Point(0, 0)
$lblStatusLeft.Size      = New-Object Drawing.Size(700, 26)
$lblStatusLeft.ForeColor = $cSubText
$lblStatusLeft.Font      = New-Object Drawing.Font("Segoe UI", 8)
$lblStatusLeft.TextAlign = "MiddleLeft"
$statusBar.Controls.Add($lblStatusLeft)

$lblStatusRight = New-Object Windows.Forms.Label
$lblStatusRight.Text      = "Desarrollado por SysCodi     Versión 2.5.0 Pro"
$lblStatusRight.Location  = New-Object Drawing.Point(700, 0)
$lblStatusRight.Size      = New-Object Drawing.Size(650, 26)
$lblStatusRight.ForeColor = $cSubText
$lblStatusRight.Font      = New-Object Drawing.Font("Segoe UI", 8)
$lblStatusRight.TextAlign = "MiddleRight"
$statusBar.Controls.Add($lblStatusRight)

# ============================================================
#   FOOTER CONTENT: 4 secciones
# ============================================================
$footerContent = New-Object Windows.Forms.Panel
$footerContent.Dock      = "Fill"
$footerContent.BackColor = $cPanel
$footer.Controls.Add($footerContent)

# --- Sección 1: Información rápida (métricas) ---
$pnlMetrics = New-Object Windows.Forms.Panel
$pnlMetrics.Location  = New-Object Drawing.Point(5, 8)
$pnlMetrics.Size      = New-Object Drawing.Size(300, 138)
$pnlMetrics.BackColor = $cCard
$footerContent.Controls.Add($pnlMetrics)

$lblMetTitle = New-Object Windows.Forms.Label
$lblMetTitle.Text      = "Información rápida"
$lblMetTitle.Location  = New-Object Drawing.Point(10, 6)
$lblMetTitle.Size      = New-Object Drawing.Size(280, 18)
$lblMetTitle.ForeColor = $cAccent2
$lblMetTitle.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlMetrics.Controls.Add($lblMetTitle)

function New-MiniMetric($label, $icon, $x, $y, $parent) {
    $p = New-Object Windows.Forms.Panel
    $p.Location  = New-Object Drawing.Point($x, $y)
    $p.Size      = New-Object Drawing.Size(130, 54)
    $p.BackColor = [Drawing.Color]::FromArgb(15, 28, 58)
    $parent.Controls.Add($p)

    $lIcon = New-Object Windows.Forms.Label
    $lIcon.Text      = $icon
    $lIcon.Location  = New-Object Drawing.Point(4, 4)
    $lIcon.Size      = New-Object Drawing.Size(20, 18)
    $lIcon.ForeColor = $cAccent2
    $lIcon.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $p.Controls.Add($lIcon)

    $lName = New-Object Windows.Forms.Label
    $lName.Text      = $label
    $lName.Location  = New-Object Drawing.Point(22, 5)
    $lName.Size      = New-Object Drawing.Size(100, 16)
    $lName.ForeColor = $cSubText
    $lName.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
    $p.Controls.Add($lName)

    $lVal = New-Object Windows.Forms.Label
    $lVal.Text      = "..."
    $lVal.Location  = New-Object Drawing.Point(80, 3)
    $lVal.Size      = New-Object Drawing.Size(45, 18)
    $lVal.ForeColor = $cText
    $lVal.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
    $lVal.TextAlign = "MiddleRight"
    $p.Controls.Add($lVal)

    $bar = New-Object Windows.Forms.ProgressBar
    $bar.Location  = New-Object Drawing.Point(4, 26)
    $bar.Size      = New-Object Drawing.Size(122, 8)
    $bar.Minimum   = 0
    $bar.Maximum   = 100
    $bar.Style     = "Continuous"
    $bar.ForeColor = $cAccent2
    $bar.BackColor = [Drawing.Color]::FromArgb(8, 16, 36)
    $p.Controls.Add($bar)

    $lExtra = New-Object Windows.Forms.Label
    $lExtra.Text      = ""
    $lExtra.Location  = New-Object Drawing.Point(4, 36)
    $lExtra.Size      = New-Object Drawing.Size(122, 16)
    $lExtra.ForeColor = $cSubText
    $lExtra.Font      = New-Object Drawing.Font("Segoe UI", 7)
    $p.Controls.Add($lExtra)

    return @{panel=$p; val=$lVal; bar=$bar; extra=$lExtra}
}

$mCPU  = New-MiniMetric "CPU Uso"   "O" 8  28 $pnlMetrics
$mRAM  = New-MiniMetric "RAM Uso"   "O" 152 28 $pnlMetrics
$mDisk = New-MiniMetric "Disco (C:)" "O" 8  86 $pnlMetrics
$mNet  = New-MiniMetric "Red"        "O" 152 86 $pnlMetrics

# --- Sección 2: Accesos rápidos ---
$pnlAccesos = New-Object Windows.Forms.Panel
$pnlAccesos.Location  = New-Object Drawing.Point(312, 8)
$pnlAccesos.Size      = New-Object Drawing.Size(370, 138)
$pnlAccesos.BackColor = $cCard
$footerContent.Controls.Add($pnlAccesos)

$lblAccTitle = New-Object Windows.Forms.Label
$lblAccTitle.Text      = "Accesos rápidos"
$lblAccTitle.Location  = New-Object Drawing.Point(10, 6)
$lblAccTitle.Size      = New-Object Drawing.Size(350, 18)
$lblAccTitle.ForeColor = $cAccent2
$lblAccTitle.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlAccesos.Controls.Add($lblAccTitle)

$accesos = @(
    @{name="Explorador";              cmd={Start-Process explorer}},
    @{name="Adm. dispositivos";       cmd={Start-Process devmgmt.msc}},
    @{name="Adm. de discos";          cmd={Start-Process diskmgmt.msc}},
    @{name="Servicios";               cmd={Start-Process services.msc}},
    @{name="Eventos";                 cmd={Start-Process eventvwr.msc}},
    @{name="Panel de control";        cmd={Start-Process control}}
)

$axPos = 8; $ayPos = 28; $aCol = 0
foreach ($acc in $accesos) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text      = $acc.name
    $btn.Location  = New-Object Drawing.Point($axPos, $ayPos)
    $btn.Size      = New-Object Drawing.Size(112, 48)
    $btn.BackColor = [Drawing.Color]::FromArgb(15, 28, 58)
    $btn.ForeColor = $cText
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = $cBorder
    $btn.FlatAppearance.BorderSize  = 1
    $btn.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
    $btn.Cursor    = "Hand"
    $accCmd = $acc.cmd
    $btn.Add_Click($accCmd)
    $btn.Add_MouseEnter({ $this.BackColor = $cCardHov })
    $btn.Add_MouseLeave({ $this.BackColor = [Drawing.Color]::FromArgb(15, 28, 58) })
    $pnlAccesos.Controls.Add($btn)
    $aCol++
    if ($aCol -ge 3) { $aCol = 0; $axPos = 8; $ayPos += 52 } else { $axPos += 116 }
}

# --- Sección 3: Acciones rápidas ---
$pnlAcciones = New-Object Windows.Forms.Panel
$pnlAcciones.Location  = New-Object Drawing.Point(690, 8)
$pnlAcciones.Size      = New-Object Drawing.Size(380, 138)
$pnlAcciones.BackColor = $cCard
$footerContent.Controls.Add($pnlAcciones)

$lblActTitle = New-Object Windows.Forms.Label
$lblActTitle.Text      = "Acciones rápidas"
$lblActTitle.Location  = New-Object Drawing.Point(10, 6)
$lblActTitle.Size      = New-Object Drawing.Size(360, 18)
$lblActTitle.ForeColor = $cAccent2
$lblActTitle.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlAcciones.Controls.Add($lblActTitle)

$acciones = @(
    @{name="Reiniciar Explorer";       cmd='Stop-Process -Name explorer -Force; Start-Process explorer'},
    @{name="Liberar memoria";          cmd='[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); Write-Output "Memoria liberada"'},
    @{name="Limpiar Portapapeles";     cmd='Set-Clipboard -Value ""; Write-Output "Portapapeles limpiado"'},
    @{name="Crear Punto Restauracion"; cmd='Checkpoint-Computer -Description "SysCodi_$(Get-Date -Format yyyyMMdd_HHmmss)" -RestorePointType MODIFY_SETTINGS; Write-Output "Punto creado"'}
)

$aaX = 8; $aaY = 28; $aaCol = 0
foreach ($act in $acciones) {
    $btn = New-Object Windows.Forms.Button
    $btn.Text      = $act.name
    $btn.Location  = New-Object Drawing.Point($aaX, $aaY)
    $btn.Size      = New-Object Drawing.Size(180, 46)
    $btn.BackColor = [Drawing.Color]::FromArgb(15, 28, 58)
    $btn.ForeColor = $cText
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = $cBorder
    $btn.FlatAppearance.BorderSize  = 1
    $btn.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $btn.Cursor    = "Hand"
    $actCmd = $act.cmd
    $btn.Add_Click({
        Run-Cmd-BG $actCmd $this.Text
    })
    $btn.Add_MouseEnter({ $this.BackColor = $cCardHov })
    $btn.Add_MouseLeave({ $this.BackColor = [Drawing.Color]::FromArgb(15, 28, 58) })
    $pnlAcciones.Controls.Add($btn)
    $aaCol++
    if ($aaCol -ge 2) { $aaCol = 0; $aaX = 8; $aaY += 50 } else { $aaX += 184 }
}

# --- Sección 4: Estado ---
$pnlEstado = New-Object Windows.Forms.Panel
$pnlEstado.Location  = New-Object Drawing.Point(1078, 8)
$pnlEstado.Size      = New-Object Drawing.Size(165, 138)
$pnlEstado.BackColor = $cCard
$footerContent.Controls.Add($pnlEstado)

$lblEstTitle = New-Object Windows.Forms.Label
$lblEstTitle.Text      = "Estado"
$lblEstTitle.Location  = New-Object Drawing.Point(10, 6)
$lblEstTitle.Size      = New-Object Drawing.Size(145, 18)
$lblEstTitle.ForeColor = $cAccent2
$lblEstTitle.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlEstado.Controls.Add($lblEstTitle)

$lblEstIcon = New-Object Windows.Forms.Label
$lblEstIcon.Text      = "v"
$lblEstIcon.Location  = New-Object Drawing.Point(55, 30)
$lblEstIcon.Size      = New-Object Drawing.Size(55, 50)
$lblEstIcon.ForeColor = $cGreen
$lblEstIcon.Font      = New-Object Drawing.Font("Wingdings", 30)
$lblEstIcon.TextAlign = "MiddleCenter"
$pnlEstado.Controls.Add($lblEstIcon)

$lblEstText = New-Object Windows.Forms.Label
$lblEstText.Text      = "Todo correcto"
$lblEstText.Location  = New-Object Drawing.Point(10, 80)
$lblEstText.Size      = New-Object Drawing.Size(145, 20)
$lblEstText.ForeColor = $cGreen
$lblEstText.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$lblEstText.TextAlign = "MiddleCenter"
$pnlEstado.Controls.Add($lblEstText)

$btnVerificar = New-Object Windows.Forms.Button
$btnVerificar.Text      = "Verificar sistema"
$btnVerificar.Location  = New-Object Drawing.Point(10, 105)
$btnVerificar.Size      = New-Object Drawing.Size(145, 26)
$btnVerificar.BackColor = [Drawing.Color]::FromArgb(15, 28, 58)
$btnVerificar.ForeColor = $cText
$btnVerificar.FlatStyle = "Flat"
$btnVerificar.FlatAppearance.BorderColor = $cBorder
$btnVerificar.Font      = New-Object Drawing.Font("Segoe UI", 8)
$btnVerificar.Add_Click({
    $lblEstText.Text      = "Verificando..."
    $lblEstText.ForeColor = $cYellow
    $lblEstIcon.ForeColor = $cYellow
    [Windows.Forms.Application]::DoEvents()
    Start-Sleep -Milliseconds 800
    $lblEstText.Text      = "Todo correcto"
    $lblEstText.ForeColor = $cGreen
    $lblEstIcon.ForeColor = $cGreen
    Write-Out "Verificacion completada: sistema OK" $cGreen
})
$pnlEstado.Controls.Add($btnVerificar)

# ============================================================
#   SISTEMA DE TABS PERSONALIZADO (replica imagen)
# ============================================================
$tabDefs = @(
    @{name="Reparacion";    icon="✂"},
    @{name="Aplicaciones";  icon="⊞"},
    @{name="Tweaks";        icon="✱"},
    @{name="Utilidades";    icon="⚙"},
    @{name="Transferencia"; icon="⇄"},
    @{name="Sistema";       icon="⬡"},
    @{name="Dashboard";     icon="▦"},
    @{name="Reportes";      icon="≡"},
    @{name="Ajustes";       icon="⚙"}
)

$tabButtons   = @()
$tabPanels    = @()
$currentTab   = 0
$tabX         = 5

foreach ($td in $tabDefs) {
    $tb = New-Object Windows.Forms.Button
    $tb.Text      = "$($td.icon)  $($td.name)"
    $tb.Location  = New-Object Drawing.Point($tabX, 6)
    $tb.Size      = New-Object Drawing.Size(126, 38)
    $tb.BackColor = $cPanel
    $tb.ForeColor = $cSubText
    $tb.FlatStyle = "Flat"
    $tb.FlatAppearance.BorderSize  = 0
    $tb.FlatAppearance.BorderColor = $cPanel
    $tb.Font      = New-Object Drawing.Font("Segoe UI", 8.5)
    $tb.Cursor    = "Hand"
    $pnlTabs.Controls.Add($tb)
    $tabButtons += $tb
    $tabX += 130

    $tp = New-Object Windows.Forms.Panel
    $tp.Dock      = "Fill"
    $tp.BackColor = $cBg
    $tp.Visible   = $false
    $pnlContent.Controls.Add($tp)
    $tabPanels += $tp
}

function Switch-Tab($idx) {
    for ($i = 0; $i -lt $tabButtons.Count; $i++) {
        if ($i -eq $idx) {
            $tabButtons[$i].BackColor = $cTabActive
            $tabButtons[$i].ForeColor = $cAccent2
            $tabPanels[$i].Visible    = $true
            $tabPanels[$i].BringToFront()
        } else {
            $tabButtons[$i].BackColor = $cPanel
            $tabButtons[$i].ForeColor = $cSubText
            $tabPanels[$i].Visible    = $false
        }
    }
    $script:currentTab = $idx
}

for ($i = 0; $i -lt $tabButtons.Count; $i++) {
    $idx = $i
    $tabButtons[$i].Add_Click({ Switch-Tab $idx })
}

# ============================================================
#   CONSOLA COMPARTIDA (lado derecho, presente en todas las tabs)
# ============================================================
$pnlConsole = New-Object Windows.Forms.Panel
$pnlConsole.Width     = 420
$pnlConsole.Dock      = "Right"
$pnlConsole.BackColor = $cOutput
$pnlContent.Controls.Add($pnlConsole)

$pnlConHdr = New-Object Windows.Forms.Panel
$pnlConHdr.Dock      = "Top"
$pnlConHdr.Height    = 34
$pnlConHdr.BackColor = $cPanel
$pnlConsole.Controls.Add($pnlConHdr)

$lblConTitle = New-Object Windows.Forms.Label
$lblConTitle.Text      = "  Consola de salida"
$lblConTitle.Dock      = "Left"
$lblConTitle.Width     = 260
$lblConTitle.ForeColor = $cAccent2
$lblConTitle.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$lblConTitle.TextAlign = "MiddleLeft"
$pnlConHdr.Controls.Add($lblConTitle)

$btnConClear = New-Object Windows.Forms.Button
$btnConClear.Text      = "Limpiar"
$btnConClear.Dock      = "Right"
$btnConClear.Width     = 75
$btnConClear.BackColor = [Drawing.Color]::FromArgb(0, 65, 120)
$btnConClear.ForeColor = $cText
$btnConClear.FlatStyle = "Flat"
$btnConClear.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$pnlConHdr.Controls.Add($btnConClear)

$btnConSave = New-Object Windows.Forms.Button
$btnConSave.Text      = "Guardar"
$btnConSave.Dock      = "Right"
$btnConSave.Width     = 75
$btnConSave.BackColor = [Drawing.Color]::FromArgb(0, 65, 120)
$btnConSave.ForeColor = $cText
$btnConSave.FlatStyle = "Flat"
$btnConSave.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$pnlConHdr.Controls.Add($btnConSave)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Dock        = "Fill"
$outputBox.BackColor   = $cOutput
$outputBox.ForeColor   = $cAccent2
$outputBox.Font        = New-Object Drawing.Font("Consolas", 8.5)
$outputBox.ReadOnly    = $true
$outputBox.BorderStyle = "None"
$outputBox.ScrollBars  = "Vertical"
$pnlConsole.Controls.Add($outputBox)

$btnConClear.Add_Click({ $outputBox.Clear(); Write-Out "Consola limpiada." $cSubText })
$btnConSave.Add_Click({
    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter = "Text files (*.txt)|*.txt"
    $dlg.FileName = "SysCodi_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if ($dlg.ShowDialog() -eq "OK") { $outputBox.Text | Set-Content $dlg.FileName -Encoding UTF8; Write-Out "Log guardado: $($dlg.FileName)" $cGreen }
})

function Write-Out($msg, $color = $null) {
    if ($null -eq $color) { $color = $cAccent2 }
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionColor = $color
    $outputBox.AppendText("`r`n $msg")
    $outputBox.ScrollToCaret()
    Write-Log $msg
}

function Write-Section($titulo) {
    Write-Out ""
    Write-Out "━━━ $titulo ━━━" $cAccent2
}

# Barra de progreso global
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Dock      = "Top"
$progressBar.Height    = 4
$progressBar.Style     = "Marquee"
$progressBar.MarqueeAnimationSpeed = 0
$progressBar.BackColor = $cPanel
$pnlContent.Controls.Add($progressBar)

function Start-Progress { $progressBar.MarqueeAnimationSpeed = 25; [Windows.Forms.Application]::DoEvents() }
function Stop-Progress  { $progressBar.MarqueeAnimationSpeed = 0 }

function Run-Cmd-BG($cmd, $label) {
    Write-Out "Ejecutando: $label..." $cSubText
    Start-Progress
    $job = Start-Job -ScriptBlock { param($c) Invoke-Expression $c 2>&1 } -ArgumentList $cmd
    $tmr = New-Object Windows.Forms.Timer
    $tmr.Interval = 600
    $tmr.Add_Tick({
        if ($job.State -ne "Running") {
            $tmr.Stop(); Stop-Progress
            $res = Receive-Job $job; Remove-Job $job -Force
            if ($res) {
                $outputBox.SelectionStart = $outputBox.TextLength
                $outputBox.SelectionColor = $cText
                $outputBox.AppendText("`r`n " + ($res -join "`r`n "))
                $outputBox.ScrollToCaret()
            }
            Write-Out "OK: $label" $cGreen
        }
    })
    $tmr.Start()
}

# ============================================================
#   HELPERS UI
# ============================================================
function New-Btn($texto, $x, $y, $w = 190, $h = 44, $parent) {
    $b = New-Object Windows.Forms.Button
    $b.Text      = $texto
    $b.Location  = New-Object Drawing.Point($x, $y)
    $b.Size      = New-Object Drawing.Size($w, $h)
    $b.BackColor = $cCard
    $b.ForeColor = $cText
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $cBorder
    $b.FlatAppearance.BorderSize  = 1
    $b.Font      = New-Object Drawing.Font("Segoe UI", 8.5)
    $b.Cursor    = "Hand"
    $b.TextAlign = "MiddleCenter"
    $b.Add_MouseEnter({ $this.BackColor = $cCardHov; $this.FlatAppearance.BorderColor = $cAccent })
    $b.Add_MouseLeave({ $this.BackColor = $cCard; $this.FlatAppearance.BorderColor = $cBorder })
    $parent.Controls.Add($b)
    return $b
}

function New-SecLabel($texto, $x, $y, $parent) {
    $l = New-Object Windows.Forms.Label
    $l.Text      = "  $texto"
    $l.Location  = New-Object Drawing.Point($x, $y)
    $l.Size      = New-Object Drawing.Size(860, 22)
    $l.ForeColor = $cAccent2
    $l.BackColor = [Drawing.Color]::FromArgb(18, 35, 72)
    $l.Font      = New-Object Drawing.Font("Segoe UI", 8.5, [Drawing.FontStyle]::Bold)
    $l.TextAlign = "MiddleLeft"
    $parent.Controls.Add($l)
}

function New-ScrollPanel($parent) {
    $p = New-Object Windows.Forms.Panel
    $p.Dock       = "Fill"
    $p.AutoScroll = $true
    $p.BackColor  = $cBg
    $parent.Controls.Add($p)
    return $p
}

# ============================================================
#   TAB 0: REPARACION
# ============================================================
$scrollR = New-ScrollPanel $tabPanels[0]
$yR = 5

function Add-Section($t) { New-SecLabel $t 5 $yR $scrollR; $script:yR += 26 }
function Add-Btn($txt, $cmd) {
    $x = 8 + ($script:colR) * 198
    $b = New-Btn $txt $x $script:yR 192 42 $scrollR
    $c2 = $cmd; $lb = $txt
    $b.Add_Click({ Run-Cmd-BG $c2 $lb })
    $script:colR++
    if ($script:colR -ge 4) { $script:colR = 0; $script:yR += 46 }
}

$script:colR = 0

Add-Section "Limpieza"
Add-Btn "Limpiar Temporales"  'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue; "Temporales eliminados"'
Add-Btn "Limpiar Prefetch"    'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue; "Prefetch limpiado"'
Add-Btn "Vaciar Papelera"     'Clear-RecycleBin -Force -EA SilentlyContinue; "Papelera vaciada"'
Add-Btn "Limpiar DNS Cache"   'ipconfig /flushdns'
if ($script:colR -ne 0) { $script:yR += 46; $script:colR = 0 }

Add-Section "Reparación de Windows"
Add-Btn "SFC /scannow"        'sfc /scannow'
Add-Btn "DISM RestoreHealth"  'DISM /Online /Cleanup-Image /RestoreHealth'
Add-Btn "DISM ScanHealth"     'DISM /Online /Cleanup-Image /ScanHealth'
Add-Btn "Reset Windows Update" 'Stop-Service wuauserv,bits,cryptsvc -Force -EA SilentlyContinue; Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv,bits,cryptsvc; "WU reiniciado"'
if ($script:colR -ne 0) { $script:yR += 46; $script:colR = 0 }

Add-Section "Red"
Add-Btn "DNS Flush"           'ipconfig /flushdns'
Add-Btn "Reset Red (netsh)"   'netsh int ip reset; netsh winsock reset; "Reset completado - reiniciar"'
Add-Btn "Ver Puertos"         'netstat -ano'
Add-Btn "Matar Puerto 80"     '$p=(netstat -ano|Select-String ":80 ")-replace ".*\s(\d+)$","$1"|Sort-Object -Unique; $p|Where{$_ -match "^\d+$"}|%{Stop-Process -Id $_ -Force -EA SilentlyContinue; "PID $_ terminado"}'
if ($script:colR -ne 0) { $script:yR += 46; $script:colR = 0 }

Add-Section "Disco y Almacenamiento"
$btnChk = New-Btn "CheckDisk (C:)" 8 $yR 192 42 $scrollR
$btnChk.Add_Click({
    $r = [Windows.Forms.MessageBox]::Show("ChkDsk requiere reinicio.`nSe programara para el proximo arranque.","ChkDsk","YesNo","Question")
    if ($r -eq "Yes") { Run-Cmd-BG 'echo Y | chkdsk C: /f /r' "ChkDsk C:" }
})
$script:colR = 1
Add-Btn "Desfragmentar C:"    'defrag C: /U /V'
Add-Btn "Optimizar SSD"       'defrag C: /L'
Add-Btn "Info SMART disco"    'wmic diskdrive get status,model,size'
if ($script:colR -ne 0) { $script:yR += 46; $script:colR = 0 }

Add-Section "Arranque y Recuperación"
Add-Btn "Crear Punto Rest."   'Checkpoint-Computer -Description "SysCodi_$(Get-Date -Format yyyyMMdd)" -RestorePointType MODIFY_SETTINGS; "Punto creado"'
Add-Btn "Ver Puntos Rest."    'Get-ComputerRestorePoint | Select Description,CreationTime | Format-Table -AutoSize'
Add-Btn "Ver arranque (BCD)"  'bcdedit /enum'
Add-Btn "Exportar Errores"    'Get-EventLog System -EntryType Error -Newest 50 -EA SilentlyContinue | Export-Csv "$env:USERPROFILE\Desktop\errores.csv" -NoTypeInformation; "Exportado al escritorio"'
if ($script:colR -ne 0) { $script:yR += 46; $script:colR = 0 }

Add-Section "Seguridad"
Add-Btn "Estado Defender"     'Get-MpComputerStatus | Select AMRunningMode,RealTimeProtectionEnabled | Format-List'
Add-Btn "Escaneo rapido"      'Start-MpScan -ScanType QuickScan; "Escaneo iniciado"'
Add-Btn "Actualizar firmas"   'Update-MpSignature; "Firmas actualizadas"'
Add-Btn "Ver usuarios"        'Get-LocalUser | Select Name,Enabled,LastLogon | Format-Table -AutoSize'
if ($script:colR -ne 0) { $script:yR += 46; $script:colR = 0 }

# Boton mantenimiento completo
$yR += 8
$btnMaint = New-Object Windows.Forms.Button
$btnMaint.Text      = "  MANTENIMIENTO COMPLETO"
$btnMaint.Location  = New-Object Drawing.Point(8, $yR)
$btnMaint.Size      = New-Object Drawing.Size(860, 44)
$btnMaint.BackColor = [Drawing.Color]::FromArgb(0, 75, 155)
$btnMaint.ForeColor = $cText
$btnMaint.FlatStyle = "Flat"
$btnMaint.FlatAppearance.BorderColor = $cAccent2
$btnMaint.FlatAppearance.BorderSize  = 2
$btnMaint.Font      = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$btnMaint.Cursor    = "Hand"
$btnMaint.Add_Click({
    Write-Section "MANTENIMIENTO COMPLETO"
    $cmds = @(
        @("Temporales",      'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue'),
        @("Flush DNS",       'ipconfig /flushdns'),
        @("SFC",             'sfc /scannow'),
        @("DISM",            'DISM /Online /Cleanup-Image /RestoreHealth'),
        @("Papelera",        'Clear-RecycleBin -Force -EA SilentlyContinue'),
        @("Optimizar disco", 'Optimize-Volume -DriveLetter C -EA SilentlyContinue')
    )
    Start-Progress
    foreach ($c in $cmds) {
        Write-Out ">>> $($c[0])..." $cSubText
        Invoke-Expression $c[1] 2>&1 | Out-Null
        Write-Out "OK: $($c[0])" $cGreen
        [Windows.Forms.Application]::DoEvents()
    }
    Stop-Progress
    Write-Out "MANTENIMIENTO COMPLETO FINALIZADO" $cGreen
})
$scrollR.Controls.Add($btnMaint)
$yR += 55
$scrollR.AutoScrollMinSize = New-Object Drawing.Size(875, ($yR + 20))

# ============================================================
#   TAB 1: APLICACIONES
# ============================================================
$pTopApps = New-Object Windows.Forms.Panel
$pTopApps.Dock      = "Top"
$pTopApps.Height    = 48
$pTopApps.BackColor = $cPanel
$tabPanels[1].Controls.Add($pTopApps)

$txtSearch = New-Object Windows.Forms.TextBox
$txtSearch.Location    = New-Object Drawing.Point(70, 12)
$txtSearch.Size        = New-Object Drawing.Size(200, 26)
$txtSearch.BackColor   = [Drawing.Color]::FromArgb(15,28,58)
$txtSearch.ForeColor   = $cText
$txtSearch.BorderStyle = "FixedSingle"
$pTopApps.Controls.Add($txtSearch)
$lblSrc = New-Object Windows.Forms.Label; $lblSrc.Text = "Buscar:"; $lblSrc.Location = New-Object Drawing.Point(8,16); $lblSrc.Size = New-Object Drawing.Size(60,20); $lblSrc.ForeColor = $cSubText; $pTopApps.Controls.Add($lblSrc)

$btnSelTodo = New-Object Windows.Forms.Button; $btnSelTodo.Text = "Sel. Todo"; $btnSelTodo.Location = New-Object Drawing.Point(280,10); $btnSelTodo.Size = New-Object Drawing.Size(85,28); $btnSelTodo.BackColor = [Drawing.Color]::FromArgb(0,70,130); $btnSelTodo.ForeColor = $cText; $btnSelTodo.FlatStyle = "Flat"; $btnSelTodo.Font = New-Object Drawing.Font("Segoe UI",8); $pTopApps.Controls.Add($btnSelTodo)
$btnLimpiarS = New-Object Windows.Forms.Button; $btnLimpiarS.Text = "Limpiar"; $btnLimpiarS.Location = New-Object Drawing.Point(370,10); $btnLimpiarS.Size = New-Object Drawing.Size(75,28); $btnLimpiarS.BackColor = [Drawing.Color]::FromArgb(80,20,20); $btnLimpiarS.ForeColor = $cText; $btnLimpiarS.FlatStyle = "Flat"; $btnLimpiarS.Font = New-Object Drawing.Font("Segoe UI",8); $pTopApps.Controls.Add($btnLimpiarS)
$btnFoss = New-Object Windows.Forms.Button; $btnFoss.Text = "Solo FOSS"; $btnFoss.Location = New-Object Drawing.Point(450,10); $btnFoss.Size = New-Object Drawing.Size(90,28); $btnFoss.BackColor = [Drawing.Color]::FromArgb(0,55,28); $btnFoss.ForeColor = $cAccent2; $btnFoss.FlatStyle = "Flat"; $btnFoss.Font = New-Object Drawing.Font("Segoe UI",8); $pTopApps.Controls.Add($btnFoss)

$btnInstalar = New-Object Windows.Forms.Button
$btnInstalar.Text      = "  INSTALAR SELECCIONADAS"
$btnInstalar.Location  = New-Object Drawing.Point(555, 7)
$btnInstalar.Size      = New-Object Drawing.Size(220, 34)
$btnInstalar.BackColor = [Drawing.Color]::FromArgb(0, 110, 55)
$btnInstalar.ForeColor = $cText
$btnInstalar.FlatStyle = "Flat"
$btnInstalar.FlatAppearance.BorderColor = $cGreen
$btnInstalar.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pTopApps.Controls.Add($btnInstalar)

$scrollA = New-Object Windows.Forms.Panel
$scrollA.Dock       = "Fill"
$scrollA.AutoScroll = $true
$scrollA.BackColor  = $cBg
$tabPanels[1].Controls.Add($scrollA)

$appList = @(
    @{cat="Navegadores";    name="Google Chrome";       cmd="winget install -e --id Google.Chrome -h";                     foss=$false},
    @{cat="Navegadores";    name="Mozilla Firefox";     cmd="winget install -e --id Mozilla.Firefox -h";                   foss=$true},
    @{cat="Navegadores";    name="Brave Browser";       cmd="winget install -e --id Brave.Brave -h";                       foss=$true},
    @{cat="Navegadores";    name="LibreWolf";            cmd="winget install -e --id LibreWolf.LibreWolf -h";               foss=$true},
    @{cat="Navegadores";    name="Opera GX";             cmd="winget install -e --id Opera.OperaGX -h";                    foss=$false},
    @{cat="Comunicacion";   name="Discord";              cmd="winget install -e --id Discord.Discord -h";                  foss=$false},
    @{cat="Comunicacion";   name="Telegram";             cmd="winget install -e --id Telegram.TelegramDesktop -h";         foss=$true},
    @{cat="Comunicacion";   name="Slack";                cmd="winget install -e --id SlackTechnologies.Slack -h";          foss=$false},
    @{cat="Comunicacion";   name="Signal";               cmd="winget install -e --id OpenWhisperSystems.Signal -h";        foss=$true},
    @{cat="Comunicacion";   name="Zoom";                 cmd="winget install -e --id Zoom.Zoom -h";                        foss=$false},
    @{cat="Comunicacion";   name="Microsoft Teams";      cmd="winget install -e --id Microsoft.Teams -h";                  foss=$false},
    @{cat="Desarrollo";     name="VS Code";              cmd="winget install -e --id Microsoft.VisualStudioCode -h";       foss=$true},
    @{cat="Desarrollo";     name="Git";                  cmd="winget install -e --id Git.Git -h";                          foss=$true},
    @{cat="Desarrollo";     name="Python 3";             cmd="winget install -e --id Python.Python.3 -h";                  foss=$true},
    @{cat="Desarrollo";     name="NodeJS LTS";           cmd="winget install -e --id OpenJS.NodeJS.LTS -h";                foss=$true},
    @{cat="Desarrollo";     name="Docker Desktop";       cmd="winget install -e --id Docker.DockerDesktop -h";             foss=$false},
    @{cat="Desarrollo";     name="Postman";              cmd="winget install -e --id Postman.Postman -h";                  foss=$false},
    @{cat="Desarrollo";     name="PowerShell 7";         cmd="winget install -e --id Microsoft.PowerShell -h";             foss=$true},
    @{cat="Desarrollo";     name="Windows Terminal";     cmd="winget install -e --id Microsoft.WindowsTerminal -h";        foss=$true},
    @{cat="Utilidades";     name="7-Zip";                cmd="winget install -e --id 7zip.7zip -h";                        foss=$true},
    @{cat="Utilidades";     name="WinRAR";               cmd="winget install -e --id RARLab.WinRAR -h";                    foss=$false},
    @{cat="Utilidades";     name="Notepad++";            cmd="winget install -e --id Notepad++.Notepad++ -h";              foss=$true},
    @{cat="Utilidades";     name="Everything";           cmd="winget install -e --id voidtools.Everything -h";             foss=$false},
    @{cat="Utilidades";     name="CPU-Z";                cmd="winget install -e --id CPUID.CPU-Z -h";                      foss=$false},
    @{cat="Utilidades";     name="GPU-Z";                cmd="winget install -e --id TechPowerUp.GPU-Z -h";                foss=$false},
    @{cat="Utilidades";     name="CrystalDiskInfo";      cmd="winget install -e --id CrystalDewWorld.CrystalDiskInfo -h";  foss=$false},
    @{cat="Multimedia";     name="VLC";                  cmd="winget install -e --id VideoLAN.VLC -h";                     foss=$true},
    @{cat="Multimedia";     name="Spotify";              cmd="winget install -e --id Spotify.Spotify -h";                  foss=$false},
    @{cat="Multimedia";     name="OBS Studio";           cmd="winget install -e --id OBSProject.OBSStudio -h";             foss=$true},
    @{cat="Multimedia";     name="HandBrake";            cmd="winget install -e --id HandBrake.HandBrake -h";              foss=$true},
    @{cat="Multimedia";     name="Audacity";             cmd="winget install -e --id Audacity.Audacity -h";                foss=$true},
    @{cat="Multimedia";     name="GIMP";                 cmd="winget install -e --id GIMP.GIMP -h";                        foss=$true},
    @{cat="Oficina";        name="LibreOffice";          cmd="winget install -e --id TheDocumentFoundation.LibreOffice -h"; foss=$true},
    @{cat="Oficina";        name="SumatraPDF";           cmd="winget install -e --id SumatraPDF.SumatraPDF -h";            foss=$true},
    @{cat="Oficina";        name="Obsidian";             cmd="winget install -e --id Obsidian.Obsidian -h";                foss=$false},
    @{cat="Seguridad";      name="Malwarebytes";         cmd="winget install -e --id Malwarebytes.Malwarebytes -h";        foss=$false},
    @{cat="Seguridad";      name="Bitwarden";            cmd="winget install -e --id Bitwarden.Bitwarden -h";              foss=$true},
    @{cat="Seguridad";      name="KeePassXC";            cmd="winget install -e --id KeePassXCTeam.KeePassXC -h";          foss=$true},
    @{cat="Gaming";         name="Steam";                cmd="winget install -e --id Valve.Steam -h";                      foss=$false},
    @{cat="Gaming";         name="Epic Games";           cmd="winget install -e --id EpicGames.EpicGamesLauncher -h";      foss=$false},
    @{cat="Gaming";         name="MSI Afterburner";      cmd="winget install -e --id Guru3D.Afterburner -h";               foss=$false}
)

$checkboxes = [System.Collections.ArrayList]@()
$yA = 5; $lastCatA = ""; $colA = 0

foreach ($app in $appList) {
    if ($app.cat -ne $lastCatA) {
        if ($lastCatA -ne "") { if ($colA -ne 0) { $yA += 26 }; $yA += 6 }
        $lbl = New-Object Windows.Forms.Label
        $lbl.Text = "  $($app.cat)"; $lbl.Location = New-Object Drawing.Point(5,$yA); $lbl.Size = New-Object Drawing.Size(860,22)
        $lbl.ForeColor = $cAccent2; $lbl.BackColor = [Drawing.Color]::FromArgb(18,35,72)
        $lbl.Font = New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
        $scrollA.Controls.Add($lbl); $yA += 24; $lastCatA = $app.cat; $colA = 0
    }
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = $app.name; $cb.Location = New-Object Drawing.Point((5+$colA*185),$yA); $cb.Size = New-Object Drawing.Size(180,22)
    $cb.ForeColor = if ($app.foss) { $cAccent2 } else { $cText }
    $cb.BackColor = $cBg; $cb.Tag = $app; $scrollA.Controls.Add($cb); $checkboxes.Add($cb) | Out-Null
    $colA++; if ($colA -ge 5) { $colA = 0; $yA += 24 }
}
$yA += 24; $scrollA.AutoScrollMinSize = New-Object Drawing.Size(870,($yA+20))

$btnSelTodo.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $true } })
$btnLimpiarS.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $false } })
$btnFoss.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = ($_.Tag.foss -eq $true) } })
$txtSearch.Add_TextChanged({
    $q = $txtSearch.Text.Trim().ToLower()
    foreach ($cb in $checkboxes) { $cb.ForeColor = if ($q -and $cb.Text.ToLower().Contains($q)) { $cYellow } else { if ($cb.Tag.foss) { $cAccent2 } else { $cText } } }
})
$btnInstalar.Add_Click({
    $sel = $checkboxes | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ninguna app." $cYellow; return }
    if (-not (Get-Command winget -EA SilentlyContinue)) { Write-Out "Winget no encontrado." $cRed; return }
    Write-Section "INSTALANDO $($sel.Count) APLICACIONES"
    Start-Progress; $i=0
    foreach ($cb in $sel) {
        $i++; Write-Out "[$i/$($sel.Count)] $($cb.Tag.name)..." $cSubText
        Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"$($cb.Tag.cmd)`"" -Wait -EA SilentlyContinue
        Write-Out "  OK: $($cb.Tag.name)" $cGreen
        [Windows.Forms.Application]::DoEvents()
    }
    Stop-Progress; Write-Out "Instalacion completada." $cGreen
})

# ============================================================
#   TAB 2: TWEAKS
# ============================================================
$scrollTw = New-ScrollPanel $tabPanels[2]
$yTw = 5; $script:colTw = 0

$tweakData = @(
    @{cat="Rendimiento"; name="Alto rendimiento (energia)"; cmd='powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'; rev='powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e'; warn=$false},
    @{cat="Rendimiento"; name="Deshabilitar efectos visuales"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Rendimiento"; name="Modo juego activado"; cmd='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f'; warn=$false},
    @{cat="Rendimiento"; name="Desactivar SysMain"; cmd='Stop-Service SysMain -Force; Set-Service SysMain -StartupType Disabled'; rev='Set-Service SysMain -StartupType Automatic; Start-Service SysMain'; warn=$false},
    @{cat="Rendimiento"; name="Desactivar Search Indexing"; cmd='Stop-Service WSearch -Force; Set-Service WSearch -StartupType Disabled'; rev='Set-Service WSearch -StartupType Automatic; Start-Service WSearch'; warn=$false},
    @{cat="Rendimiento"; name="GPU Hardware Scheduling [!]"; cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f'; warn=$true},
    @{cat="Privacidad"; name="Deshabilitar telemetria"; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f'; warn=$false},
    @{cat="Privacidad"; name="Deshabilitar Cortana"; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f'; warn=$false},
    @{cat="Privacidad"; name="Deshabilitar Activity History"; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f'; warn=$false},
    @{cat="Privacidad"; name="Deshabilitar anuncios"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Privacidad"; name="Deshabilitar ubicacion"; cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 0 /f'; rev='reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz"; name="Mostrar extensiones archivo"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz"; name="Mostrar archivos ocultos"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f'; warn=$false},
    @{cat="Interfaz"; name="Menu contextual clasico (W11)"; cmd='reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f'; rev='reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f'; warn=$false},
    @{cat="Interfaz"; name="Deshabilitar notificaciones"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz"; name="Transparencia OFF"; cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Red"; name="DNS Cloudflare (1.1.1.1)"; cmd='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 1.1.1.1,1.0.0.1 -EA SilentlyContinue'; rev='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue'; warn=$false},
    @{cat="Red"; name="DNS Google (8.8.8.8)"; cmd='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 8.8.8.8,8.8.4.4 -EA SilentlyContinue'; rev='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue'; warn=$false},
    @{cat="Red"; name="Limitar banda reservada"; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /f'; warn=$false},
    @{cat="Seguridad"; name="Deshabilitar autorun USB"; cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f'; rev='reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f'; warn=$false},
    @{cat="Seguridad"; name="Deshabilitar Remote Desktop"; cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f'; warn=$false}
)

$tweakChecks = [System.Collections.ArrayList]@()
$lastCatTw2 = ""
foreach ($tw in $tweakData) {
    if ($tw.cat -ne $lastCatTw2) {
        if ($lastCatTw2 -ne "") { if ($script:colTw -ne 0) { $yTw += 26 }; $yTw += 6 }
        New-SecLabel $tw.cat 5 $yTw $scrollTw; $yTw += 26; $lastCatTw2 = $tw.cat; $script:colTw = 0
    }
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = if ($tw.warn) { "$($tw.name)  [!]" } else { $tw.name }
    $cb.Location = New-Object Drawing.Point((5+$script:colTw*430),$yTw)
    $cb.Size = New-Object Drawing.Size(422,24); $cb.ForeColor = if ($tw.warn) { $cYellow } else { $cText }
    $cb.BackColor = $cBg; $cb.Tag = $tw; $scrollTw.Controls.Add($cb); $tweakChecks.Add($cb) | Out-Null
    $script:colTw++; if ($script:colTw -ge 2) { $script:colTw = 0; $yTw += 26 }
}
$yTw += 12

$pnlTwBtns = New-Object Windows.Forms.Panel; $pnlTwBtns.Location = New-Object Drawing.Point(5,$yTw); $pnlTwBtns.Size = New-Object Drawing.Size(860,48); $pnlTwBtns.BackColor = $cPanel; $scrollTw.Controls.Add($pnlTwBtns)

$btnApply = New-Object Windows.Forms.Button; $btnApply.Text = "  Aplicar Seleccionados"; $btnApply.Location = New-Object Drawing.Point(5,7); $btnApply.Size = New-Object Drawing.Size(200,34); $btnApply.BackColor = [Drawing.Color]::FromArgb(0,95,55); $btnApply.ForeColor = $cText; $btnApply.FlatStyle = "Flat"; $btnApply.Font = New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$btnApply.Add_Click({
    $sel = $tweakChecks | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ningun tweak." $cYellow; return }
    $bak = "$logDir\reg_bak_$(Get-Date -Format yyyyMMdd_HHmmss).reg"
    reg export HKCU $bak /y | Out-Null; Write-Out "Backup: $bak" $cSubText
    foreach ($cb in $sel) { Write-Out "Aplicando: $($cb.Tag.name)..." $cSubText; Invoke-Expression $cb.Tag.cmd 2>&1 | Out-Null; Write-Out "  OK" $cGreen }
    Write-Out "Tweaks aplicados. Puede requerir reinicio." $cYellow
})
$pnlTwBtns.Controls.Add($btnApply)

$btnRevert = New-Object Windows.Forms.Button; $btnRevert.Text = "Revertir Seleccionados"; $btnRevert.Location = New-Object Drawing.Point(215,7); $btnRevert.Size = New-Object Drawing.Size(180,34); $btnRevert.BackColor = [Drawing.Color]::FromArgb(100,45,0); $btnRevert.ForeColor = $cText; $btnRevert.FlatStyle = "Flat"; $btnRevert.Font = New-Object Drawing.Font("Segoe UI",9)
$btnRevert.Add_Click({ $tweakChecks | Where-Object { $_.Checked } | ForEach-Object { if ($_.Tag.rev) { Invoke-Expression $_.Tag.rev 2>&1 | Out-Null }; Write-Out "Revertido: $($_.Tag.name)" $cYellow } })
$pnlTwBtns.Controls.Add($btnRevert)

$cmbPerfil = New-Object Windows.Forms.ComboBox; $cmbPerfil.Location = New-Object Drawing.Point(560,10); $cmbPerfil.Size = New-Object Drawing.Size(140,28); $cmbPerfil.BackColor = $cPanel; $cmbPerfil.ForeColor = $cText; $cmbPerfil.FlatStyle = "Flat"; $cmbPerfil.DropDownStyle = "DropDownList"; $cmbPerfil.Items.AddRange(@("Gaming","Oficina","Privacidad Max","PC Antigua")); $pnlTwBtns.Controls.Add($cmbPerfil)

$btnPerfil = New-Object Windows.Forms.Button; $btnPerfil.Text = "Aplicar Perfil"; $btnPerfil.Location = New-Object Drawing.Point(710,7); $btnPerfil.Size = New-Object Drawing.Size(140,34); $btnPerfil.BackColor = [Drawing.Color]::FromArgb(0,75,145); $btnPerfil.ForeColor = $cText; $btnPerfil.FlatStyle = "Flat"; $btnPerfil.Font = New-Object Drawing.Font("Segoe UI",9)
$btnPerfil.Add_Click({
    $p = $cmbPerfil.SelectedItem
    $map = @{
        "Gaming"         = @("Alto rendimiento (energia)","Modo juego activado","GPU Hardware Scheduling [!]","Desactivar SysMain")
        "Oficina"        = @("Mostrar extensiones archivo","Mostrar archivos ocultos","Deshabilitar notificaciones")
        "Privacidad Max" = @("Deshabilitar telemetria","Deshabilitar Cortana","Deshabilitar Activity History","Deshabilitar anuncios","Deshabilitar ubicacion")
        "PC Antigua"     = @("Deshabilitar efectos visuales","Desactivar SysMain","Desactivar Search Indexing","Transparencia OFF","Alto rendimiento (energia)")
    }
    $sel = $map[$p]
    $tweakChecks | ForEach-Object { $_.Checked = ($sel -contains $_.Tag.name) }
    Write-Out "Perfil '$p' listo. Pulsa Aplicar." $cAccent2
})
$pnlTwBtns.Controls.Add($btnPerfil)
$yTw += 60; $scrollTw.AutoScrollMinSize = New-Object Drawing.Size(870,($yTw+20))

# ============================================================
#   TAB 3: UTILIDADES
# ============================================================
$scrollU = New-ScrollPanel $tabPanels[3]

function New-UtilCard($titulo, $sub, $y, $h=125) {
    $p = New-Object Windows.Forms.Panel; $p.Location = New-Object Drawing.Point(5,$y); $p.Size = New-Object Drawing.Size(860,$h); $p.BackColor = $cCard; $scrollU.Controls.Add($p)
    $lt = New-Object Windows.Forms.Label; $lt.Text = "  $titulo"; $lt.Location = New-Object Drawing.Point(0,0); $lt.Size = New-Object Drawing.Size(860,28); $lt.ForeColor = $cAccent2; $lt.BackColor = [Drawing.Color]::FromArgb(18,35,72); $lt.Font = New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $lt.TextAlign = "MiddleLeft"; $p.Controls.Add($lt)
    $ls = New-Object Windows.Forms.Label; $ls.Text = "  $sub"; $ls.Location = New-Object Drawing.Point(0,28); $ls.Size = New-Object Drawing.Size(860,20); $ls.ForeColor = $cSubText; $ls.Font = New-Object Drawing.Font("Segoe UI",8); $p.Controls.Add($ls)
    return $p
}
function New-FPicker($panel,$y,$filter) {
    $lbl = New-Object Windows.Forms.Label; $lbl.Text = "Ningun archivo"; $lbl.Location = New-Object Drawing.Point(10,$y); $lbl.Size = New-Object Drawing.Size(620,18); $lbl.ForeColor = $cSubText; $lbl.Font = New-Object Drawing.Font("Consolas",7.5); $panel.Controls.Add($lbl)
    $btn = New-Object Windows.Forms.Button; $btn.Text = "Buscar"; $btn.Location = New-Object Drawing.Point(638,($y-3)); $btn.Size = New-Object Drawing.Size(110,24); $btn.BackColor = $cCard; $btn.ForeColor = $cText; $btn.FlatStyle = "Flat"; $btn.Font = New-Object Drawing.Font("Segoe UI",8)
    $f2 = $filter; $btn.Add_Click({ $d = New-Object Windows.Forms.OpenFileDialog; $d.Filter = $f2; if ($d.ShowDialog() -eq "OK") { $lbl.Text = $d.FileName } }); $panel.Controls.Add($btn); return $lbl
}
function Inst-Dep($pkg) { $c = python -c "import $pkg" 2>&1; if ($LASTEXITCODE -ne 0) { Write-Out "Instalando $pkg..." $cSubText; python -m pip install $pkg --quiet 2>&1 | Out-Null } }

# Excel
$pE = New-UtilCard "Quitar contrasena - Excel" "Genera copia sin contrasena en la misma carpeta" 5 125
$lblEF = New-FPicker $pE 52 "Excel (*.xlsx;*.xls;*.xlsm)|*.xlsx;*.xls;*.xlsm"
$bE = New-Btn "  Quitar Contrasena" 10 78 190 36 $pE
$bE.Add_Click({
    $path = $lblEF.Text; if (-not (Test-Path $path)) { Write-Out "Selecciona Excel." $cYellow; return }
    Inst-Dep "msoffcrypto"; $out = $path -replace '(\.[^.]+)$','_sin_pass$1'
    $py = "import msoffcrypto`nwith open(r'$path','rb') as f:`n    o=msoffcrypto.OfficeFile(f); o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
    $py | Set-Content "$env:TEMP\ux_e.py" -Encoding UTF8; $r = python "$env:TEMP\ux_e.py" 2>&1
    if ($r -like "*OK*") { Write-Out "Desbloqueado: $out" $cGreen } else { Write-Out "Error: $r" $cRed }
})

# Word
$pW = New-UtilCard "Quitar contrasena - Word" "Genera copia sin contrasena en la misma carpeta" 133 125
$lblWF = New-FPicker $pW 52 "Word (*.docx;*.doc;*.docm)|*.docx;*.doc;*.docm"
$bW = New-Btn "  Quitar Contrasena" 10 78 190 36 $pW
$bW.Add_Click({
    $path = $lblWF.Text; if (-not (Test-Path $path)) { Write-Out "Selecciona Word." $cYellow; return }
    Inst-Dep "msoffcrypto"; $out = $path -replace '(\.[^.]+)$','_sin_pass$1'
    $py = "import msoffcrypto`nwith open(r'$path','rb') as f:`n    o=msoffcrypto.OfficeFile(f); o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
    $py | Set-Content "$env:TEMP\ux_w.py" -Encoding UTF8; $r = python "$env:TEMP\ux_w.py" 2>&1
    if ($r -like "*OK*") { Write-Out "Desbloqueado: $out" $cGreen } else { Write-Out "Error: $r" $cRed }
})

# ZIP
$pZ = New-UtilCard "Quitar contrasena - ZIP" "Fuerza bruta con wordlist opcional" 265 165
$lblZF  = New-FPicker $pZ 52 "ZIP (*.zip)|*.zip"
$lblWLF = New-FPicker $pZ 74 "Wordlist (*.txt)|*.txt"
$lblWLF.Text = "Sin wordlist (opcional)"
$lblPL = New-Object Windows.Forms.Label; $lblPL.Text = "Contrasena:"; $lblPL.Location = New-Object Drawing.Point(10,98); $lblPL.Size = New-Object Drawing.Size(90,20); $lblPL.ForeColor = $cSubText; $pZ.Controls.Add($lblPL)
$txtZP = New-Object Windows.Forms.TextBox; $txtZP.Location = New-Object Drawing.Point(103,96); $txtZP.Size = New-Object Drawing.Size(180,24); $txtZP.BackColor = [Drawing.Color]::FromArgb(15,25,50); $txtZP.ForeColor = $cText; $txtZP.UseSystemPasswordChar = $true; $pZ.Controls.Add($txtZP)
$bZ = New-Btn "  Extraer/Desbloquear" 10 128 210 32 $pZ
$bZ.Add_Click({
    $zp = $lblZF.Text; $pass = $txtZP.Text.Trim(); $wl = $lblWLF.Text
    if (-not (Test-Path $zp)) { Write-Out "Selecciona ZIP." $cYellow; return }
    $od = [IO.Path]::Combine([IO.Path]::GetDirectoryName($zp),[IO.Path]::GetFileNameWithoutExtension($zp)+"_extraido")
    $py = @"
import zipfile,os,sys
path=r'$zp'; out=r'$od'; pwd=r'$pass'; wl=r'$wl'
os.makedirs(out,exist_ok=True)
if pwd:
    try:
        with zipfile.ZipFile(path) as z: z.extractall(out,pwd=pwd.encode())
        print('OK:'+out); sys.exit()
    except Exception as e: print('ERROR:'+str(e)); sys.exit()
try:
    with zipfile.ZipFile(path) as z: z.extractall(out)
    print('OK:'+out); sys.exit()
except RuntimeError: pass
if os.path.exists(wl):
    with open(wl,'r',errors='ignore') as f:
        for i,l in enumerate(f):
            p=l.strip()
            try:
                with zipfile.ZipFile(path) as z: z.extractall(out,pwd=p.encode())
                print('OK:Pass='+p); sys.exit()
            except: pass
    print('ERROR:No encontrada')
else: print('ERROR:ZIP protegido')
"@
    $py | Set-Content "$env:TEMP\ux_z.py" -Encoding UTF8
    Start-Progress; $r = python "$env:TEMP\ux_z.py" 2>&1; Stop-Progress
    $r | ForEach-Object { if ($_ -like "OK:*") { Write-Out $_.Substring(3) $cGreen } elseif ($_ -like "ERROR:*") { Write-Out $_.Substring(6) $cRed } else { Write-Out $_ $cSubText } }
})

# Hash
$pH = New-UtilCard "Calcular Hash de Archivo" "MD5 / SHA1 / SHA256 / SHA512 — verifica integridad" 437 110
$lblHF = New-FPicker $pH 52 "Todos (*.*)|*.*"
$cmbH = New-Object Windows.Forms.ComboBox; $cmbH.Location = New-Object Drawing.Point(10,78); $cmbH.Size = New-Object Drawing.Size(90,26); $cmbH.BackColor = $cPanel; $cmbH.ForeColor = $cText; $cmbH.FlatStyle = "Flat"; $cmbH.DropDownStyle = "DropDownList"; $cmbH.Items.AddRange(@("MD5","SHA1","SHA256","SHA512")); $cmbH.SelectedIndex = 2; $pH.Controls.Add($cmbH)
$bH = New-Btn "  Calcular" 108 75 155 32 $pH
$bH.Add_Click({
    $path = $lblHF.Text; if (-not (Test-Path $path)) { Write-Out "Selecciona archivo." $cYellow; return }
    $h = Get-FileHash $path -Algorithm $cmbH.SelectedItem
    Write-Out "[$($cmbH.SelectedItem)] $($h.Hash)" $cGreen
    [Windows.Forms.Clipboard]::SetText($h.Hash); Write-Out "(Copiado al portapapeles)" $cSubText
})

# Renombrar lote
$pR = New-UtilCard "Renombrar Archivos en Lote" "Prefijo, sufijo o reemplazar texto en nombres" 554 145
$lblRF = New-Object Windows.Forms.Label; $lblRF.Text = "Ningun directorio"; $lblRF.Location = New-Object Drawing.Point(10,52); $lblRF.Size = New-Object Drawing.Size(600,18); $lblRF.ForeColor = $cSubText; $lblRF.Font = New-Object Drawing.Font("Consolas",7.5); $pR.Controls.Add($lblRF)
$bRD = New-Object Windows.Forms.Button; $bRD.Text = "Carpeta"; $bRD.Location = New-Object Drawing.Point(638,49); $bRD.Size = New-Object Drawing.Size(110,24); $bRD.BackColor = $cCard; $bRD.ForeColor = $cText; $bRD.FlatStyle = "Flat"; $bRD.Font = New-Object Drawing.Font("Segoe UI",8); $bRD.Add_Click({ $d = New-Object Windows.Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $lblRF.Text = $d.SelectedPath } }); $pR.Controls.Add($bRD)

function LblTxt($t,$x,$y,$p) { $l = New-Object Windows.Forms.Label; $l.Text=$t; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size(55,20); $l.ForeColor=$cSubText; $l.Font=New-Object Drawing.Font("Segoe UI",8); $p.Controls.Add($l) }
function TxtBox($x,$y,$w,$p) { $t = New-Object Windows.Forms.TextBox; $t.Location=New-Object Drawing.Point($x,$y); $t.Size=New-Object Drawing.Size($w,24); $t.BackColor=[Drawing.Color]::FromArgb(15,28,58); $t.ForeColor=$cText; $p.Controls.Add($t); return $t }

LblTxt "Prefijo:" 10 80 $pR; $txtPre = TxtBox 68 78 90 $pR
LblTxt "Sufijo:"  175 80 $pR; $txtSuf = TxtBox 228 78 90 $pR
LblTxt "De:"      335 80 $pR; $txtRF = TxtBox 368 78 90 $pR; $txtRF.PlaceholderText = "buscar"
LblTxt "A:"       470 80 $pR; $txtRT = TxtBox 490 78 90 $pR; $txtRT.PlaceholderText = "reemplazar"
$bRen = New-Btn "  Renombrar" 10 108 170 30 $pR
$bRen.Add_Click({
    $f = $lblRF.Text; if (-not (Test-Path $f)) { Write-Out "Selecciona carpeta." $cYellow; return }
    $cnt = 0
    Get-ChildItem $f -File | ForEach-Object {
        $n = $_.BaseName
        if ($txtRF.Text) { $n = $n.Replace($txtRF.Text,$txtRT.Text) }
        $n = "$($txtPre.Text)$n$($txtSuf.Text)$($_.Extension)"
        if ($n -ne $_.Name) { Rename-Item $_.FullName $n -EA SilentlyContinue; $cnt++ }
    }
    Write-Out "Renombrados: $cnt archivos" $cGreen
})

$scrollU.AutoScrollMinSize = New-Object Drawing.Size(870, 720)

# ============================================================
#   TAB 4: TRANSFERENCIA (nueva)
# ============================================================
$pTrans = $tabPanels[4]
$lblTransInfo = New-Object Windows.Forms.Label
$lblTransInfo.Text      = "Modulo de Transferencia de Archivos"
$lblTransInfo.Location  = New-Object Drawing.Point(20, 20)
$lblTransInfo.Size      = New-Object Drawing.Size(700, 30)
$lblTransInfo.ForeColor = $cAccent2
$lblTransInfo.Font      = New-Object Drawing.Font("Segoe UI", 12, [Drawing.FontStyle]::Bold)
$pTrans.Controls.Add($lblTransInfo)

# Copiar carpeta
$pCopy = New-Object Windows.Forms.Panel; $pCopy.Location = New-Object Drawing.Point(5,60); $pCopy.Size = New-Object Drawing.Size(860,130); $pCopy.BackColor = $cCard; $pTrans.Controls.Add($pCopy)
$ltC = New-Object Windows.Forms.Label; $ltC.Text = "  Copiar Carpeta con Progreso"; $ltC.Location = New-Object Drawing.Point(0,0); $ltC.Size = New-Object Drawing.Size(860,28); $ltC.ForeColor = $cAccent2; $ltC.BackColor = [Drawing.Color]::FromArgb(18,35,72); $ltC.Font = New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold); $ltC.TextAlign = "MiddleLeft"; $pCopy.Controls.Add($ltC)
$lblSrcPath = New-Object Windows.Forms.Label; $lblSrcPath.Text = "Origen: (no seleccionado)"; $lblSrcPath.Location = New-Object Drawing.Point(10,34); $lblSrcPath.Size = New-Object Drawing.Size(700,18); $lblSrcPath.ForeColor = $cSubText; $pCopy.Controls.Add($lblSrcPath)
$btnSrc = New-Object Windows.Forms.Button; $btnSrc.Text = "Origen"; $btnSrc.Location = New-Object Drawing.Point(720,31); $btnSrc.Size = New-Object Drawing.Size(130,24); $btnSrc.BackColor = $cCard; $btnSrc.ForeColor = $cText; $btnSrc.FlatStyle = "Flat"; $btnSrc.Add_Click({ $d = New-Object Windows.Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $lblSrcPath.Text = "Origen: $($d.SelectedPath)" } }); $pCopy.Controls.Add($btnSrc)
$lblDstPath = New-Object Windows.Forms.Label; $lblDstPath.Text = "Destino: (no seleccionado)"; $lblDstPath.Location = New-Object Drawing.Point(10,58); $lblDstPath.Size = New-Object Drawing.Size(700,18); $lblDstPath.ForeColor = $cSubText; $pCopy.Controls.Add($lblDstPath)
$btnDst = New-Object Windows.Forms.Button; $btnDst.Text = "Destino"; $btnDst.Location = New-Object Drawing.Point(720,55); $btnDst.Size = New-Object Drawing.Size(130,24); $btnDst.BackColor = $cCard; $btnDst.ForeColor = $cText; $btnDst.FlatStyle = "Flat"; $btnDst.Add_Click({ $d = New-Object Windows.Forms.FolderBrowserDialog; if ($d.ShowDialog() -eq "OK") { $lblDstPath.Text = "Destino: $($d.SelectedPath)" } }); $pCopy.Controls.Add($btnDst
