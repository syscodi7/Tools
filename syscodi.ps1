#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#  ANTI-FREEZE: RunspacePool para todas las operaciones pesadas
# ============================================================
$Global:RSPool = [RunspaceFactory]::CreateRunspacePool(1, 8)
$Global:RSPool.ApartmentState = 'STA'
$Global:RSPool.Open()
$Global:Jobs = [System.Collections.Generic.List[hashtable]]::new()

function Start-AsyncJob {
    param([scriptblock]$Code, [object[]]$Args = @())
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $Global:RSPool
    [void]$ps.AddScript($Code)
    foreach ($a in $Args) { [void]$ps.AddArgument($a) }
    $handle = $ps.BeginInvoke()
    $Global:Jobs.Add(@{ PS = $ps; Handle = $handle })
    return @{ PS = $ps; Handle = $handle }
}

# Timer que recoge resultados de jobs y los vuelca a la consola
$Global:JobTimer = New-Object Windows.Forms.Timer
$Global:JobTimer.Interval = 300
$Global:JobTimer.Add_Tick({
    $done = $Global:Jobs | Where-Object { $_.Handle.IsCompleted }
    foreach ($j in $done) {
        try {
            $results = $j.PS.EndInvoke($j.Handle)
            foreach ($r in $results) {
                if ($r -is [hashtable] -and $r.ContainsKey('msg')) {
                    Write-Log $r.msg $r.color
                } elseif ($r) {
                    Write-Log ($r | Out-String).Trim() 'normal'
                }
            }
            if ($j.PS.Streams.Error.Count -gt 0) {
                foreach ($e in $j.PS.Streams.Error) { Write-Log "Error: $e" 'red' }
            }
        } catch { Write-Log "Error interno: $_" 'red' }
        finally { $j.PS.Dispose() }
    }
    $Global:Jobs.RemoveAll({ param($x) $x.Handle.IsCompleted }) | Out-Null
})

# ============================================================
#  LOGO
# ============================================================
$logoUrl  = 'https://raw.githubusercontent.com/syscodi7/Tools/main/sis.png'
$logoPath = "$env:TEMP\syscodi_logo.png"
try { Invoke-WebRequest -Uri $logoUrl -OutFile $logoPath -EA Stop } catch { $logoPath = '' }

# ============================================================
#  COLORES
# ============================================================
$cBg      = [Drawing.Color]::FromArgb(13, 27, 46)
$cPanel   = [Drawing.Color]::FromArgb(10, 20, 34)
$cSide    = [Drawing.Color]::FromArgb(10, 20, 34)
$cCard    = [Drawing.Color]::FromArgb(12, 34, 68)
$cAccent  = [Drawing.Color]::FromArgb(0, 120, 212)
$cAccent2 = [Drawing.Color]::FromArgb(0, 180, 240)
$cText    = [Drawing.Color]::FromArgb(224, 240, 255)
$cSub     = [Drawing.Color]::FromArgb(77, 126, 168)
$cGreen   = [Drawing.Color]::FromArgb(76, 175, 80)
$cRed     = [Drawing.Color]::FromArgb(224, 96, 96)
$cYellow  = [Drawing.Color]::FromArgb(240, 176, 96)
$cOutput  = [Drawing.Color]::FromArgb(8, 18, 30)
$cBorder  = [Drawing.Color]::FromArgb(30, 58, 95)
$cNavHov  = [Drawing.Color]::FromArgb(13, 31, 53)
$cNavAct  = [Drawing.Color]::FromArgb(12, 45, 82)

# ============================================================
#  HELPERS DE UI
# ============================================================
function New-Btn {
    param($text, $x, $y, $w = 190, $h = 34, $color = 'normal')
    $b = New-Object Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object Drawing.Point($x, $y)
    $b.Size = New-Object Drawing.Size($w, $h)
    $b.FlatStyle = 'Flat'
    $b.Cursor = 'Hand'
    $b.Font = New-Object Drawing.Font('Segoe UI', 9)
    switch ($color) {
        'green'  { $b.BackColor = [Drawing.Color]::FromArgb(10, 34, 24); $b.ForeColor = [Drawing.Color]::FromArgb(111, 212, 154); $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(26, 77, 46) }
        'red'    { $b.BackColor = [Drawing.Color]::FromArgb(32, 13, 13); $b.ForeColor = [Drawing.Color]::FromArgb(240, 128, 128); $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(77, 28, 28) }
        'orange' { $b.BackColor = [Drawing.Color]::FromArgb(31, 18, 8);  $b.ForeColor = [Drawing.Color]::FromArgb(240, 176, 96);  $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(77, 48, 10) }
        default  { $b.BackColor = $cCard; $b.ForeColor = $cText; $b.FlatAppearance.BorderColor = $cBorder }
    }
    $b.FlatAppearance.BorderSize = 1
    return $b
}

function New-SectionLbl {
    param($text, $x, $y, $parent)
    $l = New-Object Windows.Forms.Label
    $l.Text = $text.ToUpper()
    $l.Location = New-Object Drawing.Point($x, $y)
    $l.Size = New-Object Drawing.Size(600, 18)
    $l.ForeColor = $cAccent
    $l.Font = New-Object Drawing.Font('Segoe UI', 8, [Drawing.FontStyle]::Bold)
    $parent.Controls.Add($l)
}

function Write-Log {
    param($msg, $type = 'normal')
    if (-not $msg) { return }
    $ts = Get-Date -Format 'HH:mm:ss'
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionColor = [Drawing.Color]::FromArgb(45, 90, 138)
    $outputBox.AppendText("`n [$ts] ")
    $outputBox.SelectionColor = switch ($type) {
        'ok'     { $cGreen }
        'warn'   { $cYellow }
        'red'    { $cRed }
        'info'   { $cAccent2 }
        'sub'    { $cSub }
        default  { $cText }
    }
    $outputBox.AppendText($msg)
    $outputBox.ScrollToCaret()
}

function Run-Async {
    param([string]$cmd, [string]$label)
    Write-Log "Ejecutando: $label..." 'sub'
    $job = Start-AsyncJob -Code {
        param($c)
        $out = & cmd /c $c 2>&1
        return @{ msg = ($out -join "`n"); color = 'normal' }
    } -Args $cmd
}

function Run-PS-Async {
    param([scriptblock]$block, [string]$label, [object[]]$args = @())
    Write-Log "$label..." 'sub'
    Start-AsyncJob -Code $block -Args $args | Out-Null
}

# ============================================================
#  FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text = 'SysCodi WinTool Pro v3'
$form.Size = New-Object Drawing.Size(1060, 660)
$form.MinimumSize = New-Object Drawing.Size(1060, 660)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $cBg
$form.ForeColor = $cText
$form.Font = New-Object Drawing.Font('Segoe UI', 9)
$form.FormBorderStyle = 'Sizable'

if ($logoPath -and (Test-Path $logoPath)) {
    try {
        $bmp = New-Object Drawing.Bitmap($logoPath)
        $form.Icon = [Drawing.Icon]::FromHandle($bmp.GetHicon())
    } catch {}
}

# ============================================================
#  TITLEBAR
# ============================================================
$titleBar = New-Object Windows.Forms.Panel
$titleBar.Dock = 'Top'
$titleBar.Height = 50
$titleBar.BackColor = $cPanel
$form.Controls.Add($titleBar)

if ($logoPath -and (Test-Path $logoPath)) {
    $pic = New-Object Windows.Forms.PictureBox
    $pic.Location = New-Object Drawing.Point(10, 5)
    $pic.Size = New-Object Drawing.Size(40, 40)
    $pic.SizeMode = 'Zoom'
    $pic.BackColor = $cPanel
    $pic.Image = [Drawing.Image]::FromFile($logoPath)
    $titleBar.Controls.Add($pic)
    $tx = 58
} else { $tx = 14 }

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text = 'SysCodi WinTool Pro v3'
$lblTitle.Font = New-Object Drawing.Font('Segoe UI', 13, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cAccent2
$lblTitle.Location = New-Object Drawing.Point($tx, 8)
$lblTitle.Size = New-Object Drawing.Size(420, 24)
$titleBar.Controls.Add($lblTitle)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text = 'Utilidad avanzada de sistema para Windows — v3.0'
$lblSub.Font = New-Object Drawing.Font('Segoe UI', 8)
$lblSub.ForeColor = $cSub
$lblSub.Location = New-Object Drawing.Point($tx, 32)
$lblSub.Size = New-Object Drawing.Size(420, 14)
$titleBar.Controls.Add($lblSub)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$lblAdmin = New-Object Windows.Forms.Label
$lblAdmin.Text = if ($isAdmin) { '✓  Administrador' } else { '✗  Sin admin' }
$lblAdmin.ForeColor = if ($isAdmin) { $cGreen } else { $cRed }
$lblAdmin.Font = New-Object Drawing.Font('Segoe UI', 8, [Drawing.FontStyle]::Bold)
$lblAdmin.Location = New-Object Drawing.Point(920, 16)
$lblAdmin.Size = New-Object Drawing.Size(130, 18)
$titleBar.Controls.Add($lblAdmin)

# ============================================================
#  LAYOUT PRINCIPAL: sidebar | contenido | consola
# ============================================================
$mainLayout = New-Object Windows.Forms.TableLayoutPanel
$mainLayout.Dock = 'Fill'
$mainLayout.ColumnCount = 3
$mainLayout.RowCount = 1
$mainLayout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute, 158))) | Out-Null
$mainLayout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent, 100))) | Out-Null
$mainLayout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute, 230))) | Out-Null
$mainLayout.BackColor = $cBg
$mainLayout.Padding = New-Object Windows.Forms.Padding(0)
$mainLayout.Margin = New-Object Windows.Forms.Padding(0)
$form.Controls.Add($mainLayout)

# ============================================================
#  SIDEBAR
# ============================================================
$sidebar = New-Object Windows.Forms.Panel
$sidebar.Dock = 'Fill'
$sidebar.BackColor = $cSide
$sidebar.Padding = New-Object Windows.Forms.Padding(6, 8, 6, 8)
$mainLayout.Controls.Add($sidebar, 0, 0)

$navItems = @(
    @{ label = '  Reparación';   icon = '🔧' },
    @{ label = '  Aplicaciones'; icon = '📦' },
    @{ label = '  Tweaks';       icon = '⚙' },
    @{ label = '  Utilidades';   icon = '🛠' },
    @{ label = '  Seguridad';    icon = '🛡' },
    @{ label = '  Backup';       icon = '💾' },
    @{ label = '  Sistema';      icon = '🖥' }
)

$navButtons = @()
$navY = 8
foreach ($item in $navItems) {
    $nb = New-Object Windows.Forms.Button
    $nb.Text = "$($item.icon) $($item.label)"
    $nb.Location = New-Object Drawing.Point(4, $navY)
    $nb.Size = New-Object Drawing.Size(146, 38)
    $nb.FlatStyle = 'Flat'
    $nb.FlatAppearance.BorderSize = 0
    $nb.BackColor = $cSide
    $nb.ForeColor = $cSub
    $nb.Font = New-Object Drawing.Font('Segoe UI', 9)
    $nb.TextAlign = 'MiddleLeft'
    $nb.Cursor = 'Hand'
    $sidebar.Controls.Add($nb)
    $navButtons += $nb
    $navY += 42
}

# ============================================================
#  PANEL DE CONTENIDO con páginas apiladas
# ============================================================
$contentHost = New-Object Windows.Forms.Panel
$contentHost.Dock = 'Fill'
$contentHost.BackColor = $cBg
$mainLayout.Controls.Add($contentHost, 1, 0)

# Función para crear panel de página
function New-Page {
    $p = New-Object Windows.Forms.Panel
    $p.Dock = 'Fill'
    $p.BackColor = $cBg
    $p.AutoScroll = $true
    $p.Visible = $false
    $p.Padding = New-Object Windows.Forms.Padding(14, 14, 14, 14)
    $contentHost.Controls.Add($p)
    return $p
}

$pages = @()
for ($i = 0; $i -lt $navItems.Count; $i++) { $pages += New-Page }

# Activar página
function Set-ActivePage($idx) {
    for ($i = 0; $i -lt $pages.Count; $i++) { $pages[$i].Visible = ($i -eq $idx) }
    for ($i = 0; $i -lt $navButtons.Count; $i++) {
        if ($i -eq $idx) {
            $navButtons[$i].BackColor = $cNavAct
            $navButtons[$i].ForeColor = $cAccent2
            $navButtons[$i].FlatAppearance.BorderSize = 0
        } else {
            $navButtons[$i].BackColor = $cSide
            $navButtons[$i].ForeColor = $cSub
        }
    }
}

# Conectar nav buttons
for ($i = 0; $i -lt $navButtons.Count; $i++) {
    $idx = $i
    $navButtons[$i].Add_Click({ Set-ActivePage $idx }.GetNewClosure())
}

# ============================================================
#  PANEL CONSOLA (derecha)
# ============================================================
$consolePanel = New-Object Windows.Forms.Panel
$consolePanel.Dock = 'Fill'
$consolePanel.BackColor = $cOutput
$mainLayout.Controls.Add($consolePanel, 2, 0)

$consoleHeader = New-Object Windows.Forms.Panel
$consoleHeader.Location = New-Object Drawing.Point(0, 0)
$consoleHeader.Size = New-Object Drawing.Size(230, 28)
$consoleHeader.BackColor = $cPanel
$consolePanel.Controls.Add($consoleHeader)

$lblConsole = New-Object Windows.Forms.Label
$lblConsole.Text = '  Consola'
$lblConsole.Location = New-Object Drawing.Point(0, 4)
$lblConsole.Size = New-Object Drawing.Size(110, 20)
$lblConsole.ForeColor = $cAccent2
$lblConsole.Font = New-Object Drawing.Font('Segoe UI', 8, [Drawing.FontStyle]::Bold)
$consoleHeader.Controls.Add($lblConsole)

$btnSaveLog = New-Object Windows.Forms.Button
$btnSaveLog.Text = 'Guardar'
$btnSaveLog.Location = New-Object Drawing.Point(108, 3)
$btnSaveLog.Size = New-Object Drawing.Size(56, 22)
$btnSaveLog.BackColor = [Drawing.Color]::FromArgb(12, 34, 68)
$btnSaveLog.ForeColor = $cText; $btnSaveLog.FlatStyle = 'Flat'
$btnSaveLog.FlatAppearance.BorderColor = $cBorder
$btnSaveLog.Font = New-Object Drawing.Font('Segoe UI', 7)
$btnSaveLog.Add_Click({
    $d = New-Object Windows.Forms.SaveFileDialog
    $d.Filter = 'Log (*.log)|*.log|Txt (*.txt)|*.txt'
    $d.FileName = "SysCodi_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    if ($d.ShowDialog() -eq 'OK') { $outputBox.Text | Set-Content $d.FileName -Encoding UTF8; Write-Log "Log guardado: $($d.FileName)" 'ok' }
})
$consoleHeader.Controls.Add($btnSaveLog)

$btnClear = New-Object Windows.Forms.Button
$btnClear.Text = 'Limpiar'
$btnClear.Location = New-Object Drawing.Point(166, 3)
$btnClear.Size = New-Object Drawing.Size(56, 22)
$btnClear.BackColor = [Drawing.Color]::FromArgb(12, 34, 68)
$btnClear.ForeColor = $cText; $btnClear.FlatStyle = 'Flat'
$btnClear.FlatAppearance.BorderColor = $cBorder
$btnClear.Font = New-Object Drawing.Font('Segoe UI', 7)
$btnClear.Add_Click({ $outputBox.Clear(); Write-Log 'Consola limpiada.' 'sub' })
$consoleHeader.Controls.Add($btnClear)

$searchBox = New-Object Windows.Forms.TextBox
$searchBox.Location = New-Object Drawing.Point(0, 29)
$searchBox.Size = New-Object Drawing.Size(176, 22)
$searchBox.BackColor = [Drawing.Color]::FromArgb(12, 28, 48)
$searchBox.ForeColor = $cSub
$searchBox.BorderStyle = 'FixedSingle'
$searchBox.Font = New-Object Drawing.Font('Consolas', 8)
$searchBox.Text = 'Buscar...'
$searchBox.Add_Enter({ if ($searchBox.Text -eq 'Buscar...') { $searchBox.Text = ''; $searchBox.ForeColor = $cText } })
$searchBox.Add_Leave({ if ($searchBox.Text -eq '') { $searchBox.Text = 'Buscar...'; $searchBox.ForeColor = $cSub } })
$consolePanel.Controls.Add($searchBox)

$btnFind = New-Object Windows.Forms.Button
$btnFind.Text = 'Ir'
$btnFind.Location = New-Object Drawing.Point(177, 29)
$btnFind.Size = New-Object Drawing.Size(28, 22)
$btnFind.BackColor = [Drawing.Color]::FromArgb(12, 34, 68); $btnFind.ForeColor = $cText; $btnFind.FlatStyle = 'Flat'
$btnFind.FlatAppearance.BorderColor = $cBorder; $btnFind.Font = New-Object Drawing.Font('Segoe UI', 7)
$btnFind.Add_Click({
    $q = $searchBox.Text.Trim()
    if ($q -and $q -ne 'Buscar...') {
        $idx = $outputBox.Text.IndexOf($q, [StringComparison]::OrdinalIgnoreCase)
        if ($idx -ge 0) { $outputBox.Select($idx, $q.Length); $outputBox.ScrollToCaret() }
        else { Write-Log "No encontrado: $q" 'warn' }
    }
})
$consolePanel.Controls.Add($btnFind)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location = New-Object Drawing.Point(0, 52)
$outputBox.Anchor = 'Top,Bottom,Left,Right'
$outputBox.Size = New-Object Drawing.Size(230, 534)
$outputBox.BackColor = $cOutput
$outputBox.ForeColor = $cAccent2
$outputBox.Font = New-Object Drawing.Font('Consolas', 8)
$outputBox.ReadOnly = $true
$outputBox.BorderStyle = 'None'
$outputBox.WordWrap = $true
$outputBox.Text = ' Listo. Selecciona una opción.'
$consolePanel.Controls.Add($outputBox)

# Resize consola al cambiar tamaño del form
$consolePanel.Add_Resize({ $outputBox.Size = New-Object Drawing.Size($consolePanel.Width, $consolePanel.Height - 52) })

# ============================================================
#  STATUS BAR
# ============================================================
$statusBar = New-Object Windows.Forms.Panel
$statusBar.Dock = 'Bottom'
$statusBar.Height = 24
$statusBar.BackColor = $cPanel
$form.Controls.Add($statusBar)
$form.Controls.SetChildIndex($statusBar, 0)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = '● Listo'
$lblStatus.Location = New-Object Drawing.Point(10, 4)
$lblStatus.Size = New-Object Drawing.Size(120, 16)
$lblStatus.ForeColor = $cGreen
$lblStatus.Font = New-Object Drawing.Font('Segoe UI', 8)
$statusBar.Controls.Add($lblStatus)

$lblMonitor = New-Object Windows.Forms.Label
$lblMonitor.Text = 'CPU --%   RAM -- GB   C: -- GB'
$lblMonitor.Location = New-Object Drawing.Point(130, 4)
$lblMonitor.Size = New-Object Drawing.Size(600, 16)
$lblMonitor.ForeColor = $cSub
$lblMonitor.Font = New-Object Drawing.Font('Segoe UI', 8)
$statusBar.Controls.Add($lblMonitor)

$lblFooter = New-Object Windows.Forms.Label
$lblFooter.Text = 'SysCodi WinTool Pro v3'
$lblFooter.TextAlign = 'MiddleRight'
$lblFooter.Location = New-Object Drawing.Point(700, 4)
$lblFooter.Size = New-Object Drawing.Size(340, 16)
$lblFooter.ForeColor = [Drawing.Color]::FromArgb(45, 90, 138)
$lblFooter.Font = New-Object Drawing.Font('Segoe UI', 7)
$statusBar.Controls.Add($lblFooter)

# Timer de monitor (async, no bloquea)
$monTimer = New-Object Windows.Forms.Timer
$monTimer.Interval = 3000
$monTimer.Add_Tick({
    try {
        $os = Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue
        $cp = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Measure-Object -Property LoadPercentage -Average).Average
        $rf = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $dk = Get-PSDrive C -EA SilentlyContinue
        $df = [math]::Round($dk.Free / 1GB, 1)
        $cpuColor = if ($cp -gt 80) { $cRed } elseif ($cp -gt 50) { $cYellow } else { $cGreen }
        $lblMonitor.Text = "CPU $($cp)%   RAM libre: $rf GB   C: $df GB libres"
        $lblMonitor.ForeColor = $cpuColor
    } catch {}
})

# ============================================================
#  ──────────────  PAGE 0: REPARACIÓN  ──────────────
# ============================================================
$p0 = $pages[0]

New-SectionLbl '  Limpieza' 0 0 $p0

$b = New-Btn '🧹  Limpiar Temporales' 0 22
$b.Add_Click({
    Run-PS-Async -label 'Limpiando temporales' -block {
        Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue
        Remove-Item 'C:\Windows\Temp\*' -Recurse -Force -EA SilentlyContinue
        return @{ msg = 'Temporales eliminados correctamente.'; color = 'ok' }
    }
}); $p0.Controls.Add($b)

$b = New-Btn '⚡  Limpiar Prefetch' 198 22
$b.Add_Click({
    Run-PS-Async -label 'Limpiando prefetch' -block {
        Remove-Item 'C:\Windows\Prefetch\*' -Recurse -Force -EA SilentlyContinue
        return @{ msg = 'Prefetch limpiado.'; color = 'ok' }
    }
}); $p0.Controls.Add($b)

$b = New-Btn '🔄  Caché Windows Update' 396 22
$b.Add_Click({
    Run-PS-Async -label 'Limpiando caché WU' -block {
        Stop-Service wuauserv -Force -EA SilentlyContinue
        Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -EA SilentlyContinue
        Start-Service wuauserv -EA SilentlyContinue
        return @{ msg = 'Caché de Windows Update limpiada.'; color = 'ok' }
    }
}); $p0.Controls.Add($b)

New-SectionLbl '  Reparación de Windows' 0 66 $p0

$b = New-Btn '🛡  SFC /scannow' 0 88 'green'
$b.Add_Click({ Run-Async 'sfc /scannow' 'SFC /scannow' }); $p0.Controls.Add($b)

$b = New-Btn '💊  DISM RestoreHealth' 198 88 'green'
$b.Add_Click({ Run-Async 'DISM /Online /Cleanup-Image /RestoreHealth' 'DISM RestoreHealth' }); $p0.Controls.Add($b)

$b = New-Btn '💾  CheckDisk (C:)' 396 88 'orange'
$b.Add_Click({ Run-Async 'chkdsk C: /f /r /x' 'CheckDisk C:' }); $p0.Controls.Add($b)

$b = New-Btn '🏪  Reparar Microsoft Store' 0 130
$b.Add_Click({ Write-Log 'Reiniciando Microsoft Store...' 'sub'; Start-Process wsreset.exe; Write-Log 'Store reiniciada.' 'ok' }); $p0.Controls.Add($b)

$b = New-Btn '📌  Crear Punto Restauración' 198 130
$b.Add_Click({
    Run-PS-Async -label 'Creando punto de restauración' -block {
        try {
            Checkpoint-Computer -Description "SysCodi $(Get-Date -Format 'dd/MM/yyyy')" -RestorePointType MODIFY_SETTINGS
            return @{ msg = 'Punto de restauración creado.'; color = 'ok' }
        } catch { return @{ msg = "Error: $_"; color = 'red' } }
    }
}); $p0.Controls.Add($b)

$b = New-Btn '⏮  Abrir Restaurar Sistema' 396 130
$b.Add_Click({ Start-Process rstrui.exe }); $p0.Controls.Add($b)

New-SectionLbl '  Red' 0 174 $p0

$b = New-Btn '🌐  DNS Flush' 0 196
$b.Add_Click({ Run-Async 'ipconfig /flushdns' 'DNS Flush' }); $p0.Controls.Add($b)

$b = New-Btn '🔌  Reset Red (netsh)' 198 196
$b.Add_Click({
    Run-PS-Async -label 'Reseteando red' -block {
        & netsh int ip reset 2>&1 | Out-Null
        & netsh winsock reset 2>&1 | Out-Null
        return @{ msg = 'Red reseteada. Reinicia el PC para aplicar cambios.'; color = 'warn' }
    }
}); $p0.Controls.Add($b)

$b = New-Btn '📡  Ver Puertos Abiertos' 396 196
$b.Add_Click({ Run-Async 'netstat -ano' 'Puertos abiertos' }); $p0.Controls.Add($b)

$b = New-Btn '📶  Diagnóstico de Red' 0 238
$b.Add_Click({
    Run-PS-Async -label 'Diagnóstico de red' -block {
        $r = @()
        $r += '--- Ping a 8.8.8.8 ---'
        $r += (ping 8.8.8.8 -n 3 2>&1)
        $r += '--- Test Google:443 ---'
        $tnc = Test-NetConnection google.com -Port 443 -EA SilentlyContinue
        $r += if ($tnc.TcpTestSucceeded) { 'Conexión TCP a Google:443 OK' } else { 'Sin conexión TCP a Google:443' }
        return @{ msg = ($r -join "`n"); color = 'normal' }
    }
}); $p0.Controls.Add($b)

$b = New-Btn '🔪  Matar Puerto 80' 198 238 'red'
$b.Add_Click({
    Run-PS-Async -label 'Matando procesos en puerto 80' -block {
        $pids = (netstat -ano | Select-String ':80\s') -replace '.*\s(\d+)$','$1' | Sort-Object -Unique
        $killed = 0
        foreach ($p in $pids) {
            if ($p -match '^\d+$') {
                Stop-Process -Id $p -Force -EA SilentlyContinue
                $killed++
            }
        }
        return @{ msg = if ($killed) { "$killed proceso(s) en puerto 80 terminados." } else { 'Ningún proceso encontrado en puerto 80.' }; color = 'ok' }
    }
}); $p0.Controls.Add($b)

New-SectionLbl '  Servicios y eventos' 0 282 $p0

$b = New-Btn '⏱  Servicios Lentos al Inicio' 0 304
$b.Add_Click({
    Run-PS-Async -label 'Listando servicios en inicio' -block {
        $svcs = Get-Service | Where-Object { $_.StartType -eq 'Automatic' -and $_.Status -eq 'Running' } | Select-Object -First 30
        $lines = $svcs | ForEach-Object { "$($_.Name) — $($_.DisplayName)" }
        return @{ msg = "--- Servicios automáticos activos ---`n" + ($lines -join "`n"); color = 'normal' }
    }
}); $p0.Controls.Add($b)

$b = New-Btn '⚠  Errores del Sistema' 198 304 'red'
$b.Add_Click({
    Run-PS-Async -label 'Leyendo errores del sistema' -block {
        try {
            $evts = Get-EventLog -LogName System -EntryType Error -Newest 10
            $lines = $evts | ForEach-Object { "$($_.TimeGenerated.ToString('dd/MM HH:mm')) [$($_.Source)] $($_.Message.Substring(0,[Math]::Min(100,$_.Message.Length)))" }
            return @{ msg = "--- Últimos 10 errores ---`n" + ($lines -join "`n"); color = 'red' }
        } catch { return @{ msg = "Error al leer log: $_"; color = 'red' } }
    }
}); $p0.Controls.Add($b)

# ============================================================
#  ──────────────  PAGE 1: APLICACIONES  ──────────────
# ============================================================
$p1 = $pages[1]

$searchApp = New-Object Windows.Forms.TextBox
$searchApp.Location = New-Object Drawing.Point(0, 0)
$searchApp.Size = New-Object Drawing.Size(340, 26)
$searchApp.BackColor = $cCard
$searchApp.ForeColor = $cSub
$searchApp.BorderStyle = 'FixedSingle'
$searchApp.Font = New-Object Drawing.Font('Segoe UI', 9)
$searchApp.Text = 'Buscar aplicación...'
$p1.Controls.Add($searchApp)

$appScroll = New-Object Windows.Forms.Panel
$appScroll.Location = New-Object Drawing.Point(0, 32)
$appScroll.Size = New-Object Drawing.Size(620, 420)
$appScroll.AutoScroll = $true
$appScroll.BackColor = $cBg
$p1.Controls.Add($appScroll)

$appData = @(
    @{ cat='Navegadores';      name='Google Chrome';    cmd='winget install -e --id Google.Chrome';                          foss=$false },
    @{ cat='Navegadores';      name='Mozilla Firefox';  cmd='winget install -e --id Mozilla.Firefox';                        foss=$true  },
    @{ cat='Navegadores';      name='Brave Browser';    cmd='winget install -e --id Brave.Brave';                            foss=$true  },
    @{ cat='Navegadores';      name='LibreWolf';        cmd='winget install -e --id LibreWolf.LibreWolf';                    foss=$true  },
    @{ cat='Comunicación';     name='Discord';          cmd='winget install -e --id Discord.Discord';                        foss=$false },
    @{ cat='Comunicación';     name='Telegram';         cmd='winget install -e --id Telegram.TelegramDesktop';               foss=$true  },
    @{ cat='Comunicación';     name='Slack';            cmd='winget install -e --id SlackTechnologies.Slack';                foss=$false },
    @{ cat='Comunicación';     name='Signal';           cmd='winget install -e --id OpenWhisperSystems.Signal';              foss=$true  },
    @{ cat='Desarrollo';       name='VS Code';          cmd='winget install -e --id Microsoft.VisualStudioCode';             foss=$false },
    @{ cat='Desarrollo';       name='Git';              cmd='winget install -e --id Git.Git';                                foss=$true  },
    @{ cat='Desarrollo';       name='Python 3';         cmd='winget install -e --id Python.Python.3';                        foss=$true  },
    @{ cat='Desarrollo';       name='NodeJS LTS';       cmd='winget install -e --id OpenJS.NodeJS.LTS';                      foss=$true  },
    @{ cat='Herramientas';     name='7-Zip';            cmd='winget install -e --id 7zip.7zip';                              foss=$true  },
    @{ cat='Herramientas';     name='VLC';              cmd='winget install -e --id VideoLAN.VLC';                           foss=$true  },
    @{ cat='Herramientas';     name='WinRAR';           cmd='winget install -e --id RARLab.WinRAR';                          foss=$false },
    @{ cat='Herramientas';     name='Notepad++';        cmd='winget install -e --id Notepad++.Notepad++';                    foss=$true  },
    @{ cat='Herramientas';     name='Everything';       cmd='winget install -e --id voidtools.Everything';                   foss=$true  },
    @{ cat='Herramientas';     name='ShareX';           cmd='winget install -e --id ShareX.ShareX';                         foss=$true  },
    @{ cat='Herramientas';     name='Rufus';            cmd='winget install -e --id Rufus.Rufus';                            foss=$true  },
    @{ cat='Multimedia';       name='OBS Studio';       cmd='winget install -e --id OBSProject.OBSStudio';                  foss=$true  },
    @{ cat='Hardware';         name='CrystalDiskInfo';  cmd='winget install -e --id CrystalDewWorld.CrystalDiskInfo';        foss=$true  },
    @{ cat='Hardware';         name='HWiNFO';           cmd='winget install -e --id REALiX.HWiNFO';                         foss=$false },
    @{ cat='Hardware';         name='GPU-Z';            cmd='winget install -e --id TechPowerUp.GPU-Z';                     foss=$false },
    @{ cat='Seguridad';        name='Bitwarden';        cmd='winget install -e --id Bitwarden.Bitwarden';                   foss=$true  },
    @{ cat='Microsoft Office'; name='Office 2019';      cmd='winget install -e --id Microsoft.Office2019.HomeAndBusiness';  foss=$false },
    @{ cat='Microsoft Office'; name='Office 2021';      cmd='winget install -e --id Microsoft.Office2021.HomeAndBusiness';  foss=$false },
    @{ cat='Microsoft Office'; name='Office 2024';      cmd='winget install -e --id Microsoft.Office2024.HomeAndBusiness';  foss=$false },
    @{ cat='Microsoft Office'; name='Microsoft 365';    cmd='winget install -e --id Microsoft.Microsoft365';                foss=$false },
    @{ cat='Microsoft Office'; name='Teams';            cmd='winget install -e --id Microsoft.Teams';                       foss=$false }
)

$appCheckboxes = @()

function Rebuild-AppList($filter = '') {
    $appScroll.Controls.Clear()
    $script:appCheckboxes = @()
    $yy = 4; $lastCat = ''
    foreach ($app in $appData) {
        if ($filter -and $app.name -notlike "*$filter*" -and $app.cat -notlike "*$filter*") { continue }
        if ($app.cat -ne $lastCat) {
            if ($lastCat -ne '') { $yy += 6 }
            $cl = New-Object Windows.Forms.Label
            $cl.Text = "  $($app.cat)"
            $cl.Location = New-Object Drawing.Point(0, $yy)
            $cl.Size = New-Object Drawing.Size(600, 18)
            $cl.ForeColor = $cAccent2
            $cl.Font = New-Object Drawing.Font('Segoe UI', 8, [Drawing.FontStyle]::Bold)
            $appScroll.Controls.Add($cl)
            $yy += 20; $lastCat = $app.cat; $col = 0
        }
        $cb = New-Object Windows.Forms.CheckBox
        $cb.Text = $app.name
        $cb.Location = New-Object Drawing.Point((4 + $col * 155), $yy)
        $cb.Size = New-Object Drawing.Size(148, 22)
        $cb.ForeColor = if ($app.foss) { $cAccent2 } else { $cText }
        $cb.BackColor = $cBg
        $cb.Tag = $app.cmd
        $appScroll.Controls.Add($cb)
        $script:appCheckboxes += $cb
        $col++
        if ($col -ge 4) { $col = 0; $yy += 24 }
    }
}

Rebuild-AppList

$searchApp.Add_TextChanged({
    $q = $searchApp.Text.Trim()
    Rebuild-AppList (if ($q -eq 'Buscar aplicación...') { '' } else { $q })
})
$searchApp.Add_Enter({ if ($searchApp.Text -eq 'Buscar aplicación...') { $searchApp.Text = ''; $searchApp.ForeColor = $cText } })
$searchApp.Add_Leave({ if ($searchApp.Text -eq '') { $searchApp.Text = 'Buscar aplicación...'; $searchApp.ForeColor = $cSub } })

$pnlAppBar = New-Object Windows.Forms.Panel
$pnlAppBar.Location = New-Object Drawing.Point(0, 456)
$pnlAppBar.Size = New-Object Drawing.Size(620, 44)
$pnlAppBar.BackColor = $cPanel
$p1.Controls.Add($pnlAppBar)

$lblFoss = New-Object Windows.Forms.Label
$lblFoss.Text = '● Azul = FOSS (Software Libre)'
$lblFoss.ForeColor = $cAccent2
$lblFoss.Font = New-Object Drawing.Font('Segoe UI', 8)
$lblFoss.Location = New-Object Drawing.Point(8, 12)
$lblFoss.Size = New-Object Drawing.Size(200, 20)
$pnlAppBar.Controls.Add($lblFoss)

$btnVerApps = New-Btn '📋  Ver Instaladas' 208 5 160 34
$btnVerApps.Add_Click({
    Run-PS-Async -label 'Listando apps instaladas (winget list)' -block {
        $r = winget list 2>&1
        return @{ msg = ($r -join "`n"); color = 'normal' }
    }
}); $pnlAppBar.Controls.Add($btnVerApps)

$btnUpAll = New-Btn '↑  Actualizar Todo' 376 5 160 34 'green'
$btnUpAll.Add_Click({
    Write-Log 'Actualizando todas las apps con winget...' 'sub'
    Start-Process powershell -ArgumentList '-NoProfile -Command "winget upgrade --all --silent"' -Verb RunAs
    Write-Log 'Actualización iniciada en ventana separada.' 'ok'
}); $pnlAppBar.Controls.Add($btnUpAll)

$btnInstall = New-Btn '⬇  Instalar Seleccionadas' 544 5 200 34 'green'
$btnInstall.Add_Click({
    $sel = $script:appCheckboxes | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Log 'No seleccionaste ninguna aplicación.' 'warn'; return }
    foreach ($cb in $sel) {
        $cmd = $cb.Tag
        $name = $cb.Text
        Write-Log "Instalando: $name" 'sub'
        Run-PS-Async -label "Instalando $name" -block {
            param($c, $n)
            & powershell -NoProfile -Command $c 2>&1 | Out-Null
            return @{ msg = "$n instalado."; color = 'ok' }
        } -args @($cmd, $name)
    }
}); $pnlAppBar.Controls.Add($btnInstall)

# ============================================================
#  ──────────────  PAGE 2: TWEAKS  ──────────────
# ============================================================
$p2 = $pages[2]
New-SectionLbl '  Rendimiento, privacidad y experiencia' 0 0 $p2

$tweaksData = @(
    @{ name='Plan energía: alto rendimiento';    cmd='powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'; undo='powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e' },
    @{ name='Deshabilitar notificaciones';        cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f'; undo='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f' },
    @{ name='Deshabilitar telemetría';            cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; undo='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f' },
    @{ name='Deshabilitar Cortana';               cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f'; undo='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f' },
    @{ name='Modo Juego activado';                cmd='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f'; undo='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f' },
    @{ name='Mostrar extensiones de archivo';     cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'; undo='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f' },
    @{ name='Mostrar archivos ocultos';           cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'; undo='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f' },
    @{ name='Deshabilitar OneDrive al inicio';    cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /t REG_SZ /d "" /f'; undo='' },
    @{ name='Deshabilitar Xbox Game Bar';         cmd='reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f'; undo='reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f' },
    @{ name='Activar GodMode en Escritorio';      cmd='$gm="$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"; New-Item -ItemType Directory -Path $gm -EA SilentlyContinue'; undo='Remove-Item "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -EA SilentlyContinue' },
    @{ name='Deshabilitar actualizaciones auto';  cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f'; undo='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f' }
)

$tweakChecks = @(); $yT = 24; $colT = 0
foreach ($tw in $tweaksData) {
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = $tw.name
    $cb.Location = New-Object Drawing.Point((0 + $colT * 310), $yT)
    $cb.Size = New-Object Drawing.Size(300, 26)
    $cb.ForeColor = $cText; $cb.BackColor = $cBg
    $cb.Tag = $tw.cmd
    $cb.AccessibleDescription = $tw.undo
    $p2.Controls.Add($cb); $tweakChecks += $cb
    $colT++; if ($colT -ge 2) { $colT = 0; $yT += 28 }
}

$btnApply = New-Btn '✅  Aplicar Seleccionados' 0 ($yT + 16) 240 36 'green'
$btnApply.Add_Click({
    $sel = $tweakChecks | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Log 'No seleccionaste ningún tweak.' 'warn'; return }
    foreach ($cb in $sel) {
        $cmd = $cb.Tag; $name = $cb.Text
        Run-PS-Async -label "Aplicando: $name" -block {
            param($c, $n)
            try { Invoke-Expression $c 2>&1 | Out-Null; return @{ msg = "Tweak aplicado: $n"; color = 'ok' } }
            catch { return @{ msg = "Error en $n`: $_"; color = 'red' } }
        } -args @($cmd, $name)
    }
    Write-Log 'Tweaks enviados. Puede requerir reinicio.' 'warn'
}); $p2.Controls.Add($btnApply)

$btnRevert = New-Btn '↩  Revertir Seleccionados' 248 ($yT + 16) 240 36 'orange'
$btnRevert.Add_Click({
    $sel = $tweakChecks | Where-Object { $_.Checked -and $_.AccessibleDescription }
    if ($sel.Count -eq 0) { Write-Log 'Nada para revertir.' 'warn'; return }
    foreach ($cb in $sel) {
        $cmd = $cb.AccessibleDescription; $name = $cb.Text
        Run-PS-Async -label "Revirtiendo: $name" -block {
            param($c, $n)
            try { Invoke-Expression $c 2>&1 | Out-Null; return @{ msg = "Revertido: $n"; color = 'warn' } }
            catch { return @{ msg = "Error revirtiendo $n`: $_"; color = 'red' } }
        } -args @($cmd, $name)
    }
}); $p2.Controls.Add($btnRevert)

# ============================================================
#  ──────────────  PAGE 3: UTILIDADES  ──────────────
# ============================================================
$p3 = $pages[3]

function New-UtilCard($title, $subtitle, $y, $parent, $h = 110) {
    $pnl = New-Object Windows.Forms.Panel
    $pnl.Location = New-Object Drawing.Point(0, $y)
    $pnl.Size = New-Object Drawing.Size(630, $h)
    $pnl.BackColor = $cCard
    $parent.Controls.Add($pnl)
    $lt = New-Object Windows.Forms.Label; $lt.Text = $title
    $lt.Location = New-Object Drawing.Point(10, 8); $lt.Size = New-Object Drawing.Size(610, 20)
    $lt.ForeColor = $cAccent2; $lt.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold); $pnl.Controls.Add($lt)
    $ls = New-Object Windows.Forms.Label; $ls.Text = $subtitle
    $ls.Location = New-Object Drawing.Point(10, 28); $ls.Size = New-Object Drawing.Size(610, 16)
    $ls.ForeColor = $cSub; $ls.Font = New-Object Drawing.Font('Segoe UI', 8); $pnl.Controls.Add($ls)
    return $pnl
}

# Excel
$pnlExcel = New-UtilCard '📊  Quitar contraseña — Excel (.xlsx / .xls)' 'Crea una copia sin contraseña en la misma carpeta. Requiere Python.' 0 $p3
$lblEPath = New-Object Windows.Forms.Label; $lblEPath.Text = 'Ningún archivo seleccionado'
$lblEPath.Location = New-Object Drawing.Point(10, 48); $lblEPath.Size = New-Object Drawing.Size(610, 14)
$lblEPath.ForeColor = $cText; $lblEPath.Font = New-Object Drawing.Font('Consolas', 7); $pnlExcel.Controls.Add($lblEPath)
$bBE = New-Btn '📁  Buscar Excel' 10 66 150 30
$bBE.Add_Click({ $d = New-Object Windows.Forms.OpenFileDialog; $d.Filter = 'Excel (*.xlsx;*.xls;*.xlsm)|*.xlsx;*.xls;*.xlsm'; if ($d.ShowDialog() -eq 'OK') { $lblEPath.Text = $d.FileName } }); $pnlExcel.Controls.Add($bBE)
$bRE = New-Btn '🔓  Quitar Contraseña' 168 66 180 30 'green'
$bRE.Add_Click({
    $path = $lblEPath.Text
    if (-not (Test-Path $path)) { Write-Log 'Selecciona un archivo Excel primero.' 'warn'; return }
    Write-Log 'Desbloqueando Excel...' 'sub'
    Run-PS-Async -label 'Desbloquear Excel' -block {
        param($p)
        $check = python -c 'import msoffcrypto' 2>&1
        if ($LASTEXITCODE -ne 0) { python -m pip install msoffcrypto-tool 2>&1 | Out-Null }
        $out = $p -replace '(\.[^.]+)$','_sin_pass$1'
        $py = "import msoffcrypto`nwith open(r'$p','rb') as f:`n    o=msoffcrypto.OfficeFile(f)`n    o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
        $tmp = "$env:TEMP\unlock_excel.py"; $py | Set-Content $tmp -Encoding UTF8
        $res = python $tmp 2>&1
        if ($res -like '*OK*') { return @{ msg = "Excel desbloqueado: $out"; color = 'ok' } }
        else { return @{ msg = "Error: $res"; color = 'red' } }
    } -args $path
}); $pnlExcel.Controls.Add($bRE)

# Word
$pnlWord = New-UtilCard '📝  Quitar contraseña — Word (.docx / .doc)' 'Crea una copia sin contraseña en la misma carpeta. Requiere Python.' 118 $p3
$lblWPath = New-Object Windows.Forms.Label; $lblWPath.Text = 'Ningún archivo seleccionado'
$lblWPath.Location = New-Object Drawing.Point(10, 48); $lblWPath.Size = New-Object Drawing.Size(610, 14)
$lblWPath.ForeColor = $cText; $lblWPath.Font = New-Object Drawing.Font('Consolas', 7); $pnlWord.Controls.Add($lblWPath)
$bBW = New-Btn '📁  Buscar Word' 10 66 150 30
$bBW.Add_Click({ $d = New-Object Windows.Forms.OpenFileDialog; $d.Filter = 'Word (*.docx;*.doc;*.docm)|*.docx;*.doc;*.docm'; if ($d.ShowDialog() -eq 'OK') { $lblWPath.Text = $d.FileName } }); $pnlWord.Controls.Add($bBW)
$bRW = New-Btn '🔓  Quitar Contraseña' 168 66 180 30 'green'
$bRW.Add_Click({
    $path = $lblWPath.Text
    if (-not (Test-Path $path)) { Write-Log 'Selecciona un archivo Word primero.' 'warn'; return }
    Run-PS-Async -label 'Desbloquear Word' -block {
        param($p)
        $check = python -c 'import msoffcrypto' 2>&1
        if ($LASTEXITCODE -ne 0) { python -m pip install msoffcrypto-tool 2>&1 | Out-Null }
        $out = $p -replace '(\.[^.]+)$','_sin_pass$1'
        $py = "import msoffcrypto`nwith open(r'$p','rb') as f:`n    o=msoffcrypto.OfficeFile(f)`n    o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
        $tmp = "$env:TEMP\unlock_word.py"; $py | Set-Content $tmp -Encoding UTF8
        $res = python $tmp 2>&1
        if ($res -like '*OK*') { return @{ msg = "Word desbloqueado: $out"; color = 'ok' } }
        else { return @{ msg = "Error: $res"; color = 'red' } }
    } -args $path
}); $pnlWord.Controls.Add($bRW)

# PDF
$pnlPdf = New-UtilCard '📄  Quitar contraseña — PDF' 'Requiere Python + pikepdf (se instala automáticamente).' 236 $p3 130
$lblPPath = New-Object Windows.Forms.Label; $lblPPath.Text = 'Ningún archivo seleccionado'
$lblPPath.Location = New-Object Drawing.Point(10, 48); $lblPPath.Size = New-Object Drawing.Size(500, 14)
$lblPPath.ForeColor = $cText; $lblPPath.Font = New-Object Drawing.Font('Consolas', 7); $pnlPdf.Controls.Add($lblPPath)
$lblPPass = New-Object Windows.Forms.Label; $lblPPass.Text = 'Contraseña:'
$lblPPass.Location = New-Object Drawing.Point(10, 68); $lblPPass.Size = New-Object Drawing.Size(80, 20)
$lblPPass.ForeColor = $cSub; $pnlPdf.Controls.Add($lblPPass)
$txtPPass = New-Object Windows.Forms.TextBox; $txtPPass.Location = New-Object Drawing.Point(93, 66); $txtPPass.Size = New-Object Drawing.Size(160, 22)
$txtPPass.UseSystemPasswordChar = $true; $txtPPass.BackColor = [Drawing.Color]::FromArgb(10, 18, 30); $txtPPass.ForeColor = $cText; $pnlPdf.Controls.Add($txtPPass)
$bBP = New-Btn '📁  Buscar PDF' 10 94 140 28
$bBP.Add_Click({ $d = New-Object Windows.Forms.OpenFileDialog; $d.Filter = 'PDF (*.pdf)|*.pdf'; if ($d.ShowDialog() -eq 'OK') { $lblPPath.Text = $d.FileName } }); $pnlPdf.Controls.Add($bBP)
$bRP = New-Btn '🔓  Quitar Contraseña PDF' 158 94 210 28 'green'
$bRP.Add_Click({
    $path = $lblPPath.Text; $pass = $txtPPass.Text.Trim()
    if (-not (Test-Path $path)) { Write-Log 'Selecciona un archivo PDF primero.' 'warn'; return }
    Run-PS-Async -label 'Desbloquear PDF' -block {
        param($p, $pw)
        $check = python -c 'import pikepdf' 2>&1
        if ($LASTEXITCODE -ne 0) { python -m pip install pikepdf 2>&1 | Out-Null }
        $out = $p -replace '\.pdf$','_sin_pass.pdf'
        $py = "import pikepdf`ntry:`n    pdf=pikepdf.open(r'$p',password='$pw')`n    pdf.save(r'$out')`n    print('OK')`nexcept Exception as e:`n    print('ERROR:'+str(e))"
        $tmp = "$env:TEMP\unlock_pdf.py"; $py | Set-Content $tmp -Encoding UTF8
        $res = python $tmp 2>&1
        if ($res -like '*OK*') { return @{ msg = "PDF desbloqueado: $out"; color = 'ok' } }
        else { return @{ msg = "Error: $res"; color = 'red' } }
    } -args @($path, $pass)
}); $pnlPdf.Controls.Add($bRP)

# Hash
$pnlHash = New-UtilCard '🔐  Verificador de Hashes' 'Calcula MD5, SHA1 y SHA256 de cualquier archivo.' 374 $p3 100
$lblHPath = New-Object Windows.Forms.Label; $lblHPath.Text = 'Ningún archivo seleccionado'
$lblHPath.Location = New-Object Drawing.Point(10, 48); $lblHPath.Size = New-Object Drawing.Size(610, 14)
$lblHPath.ForeColor = $cText; $lblHPath.Font = New-Object Drawing.Font('Consolas', 7); $pnlHash.Controls.Add($lblHPath)
$bBH = New-Btn '📁  Seleccionar Archivo' 10 66 180 28
$bBH.Add_Click({ $d = New-Object Windows.Forms.OpenFileDialog; if ($d.ShowDialog() -eq 'OK') { $lblHPath.Text = $d.FileName } }); $pnlHash.Controls.Add($bBH)
$bCH = New-Btn '🧮  Calcular Hashes' 198 66 180 28 'green'
$bCH.Add_Click({
    $f = $lblHPath.Text
    if (-not (Test-Path $f)) { Write-Log 'Selecciona un archivo primero.' 'warn'; return }
    Run-PS-Async -label 'Calculando hashes' -block {
        param($file)
        $md5 = (Get-FileHash $file -Algorithm MD5).Hash
        $sh1 = (Get-FileHash $file -Algorithm SHA1).Hash
        $sh2 = (Get-FileHash $file -Algorithm SHA256).Hash
        return @{ msg = "--- $(Split-Path $file -Leaf) ---`nMD5   : $md5`nSHA1  : $sh1`nSHA256: $sh2"; color = 'info' }
    } -args $f
}); $pnlHash.Controls.Add($bCH)

# Activación
$pnlAct = New-UtilCard '🔑  Activación Windows / Office (MAS)' 'irm https://get.activated.win | iex — Proyecto open source MAS' 482 $p3 80
$bActW = New-Btn '🪟  Activar Windows' 10 54 190 28 'green'
$bActW.Add_Click({
    $c = [Windows.Forms.MessageBox]::Show("Comando: irm https://get.activated.win | iex`n¿Continuar?", 'Activación Windows', 'YesNo', 'Warning')
    if ($c -eq 'Yes') { Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"' -Verb RunAs; Write-Log 'Script MAS lanzado para Windows.' 'ok' }
}); $pnlAct.Controls.Add($bActW)
$bActO = New-Btn '📦  Activar Office' 208 54 190 28 'green'
$bActO.Add_Click({
    $c = [Windows.Forms.MessageBox]::Show("Comando: irm https://get.activated.win | iex`n¿Continuar?", 'Activación Office', 'YesNo', 'Warning')
    if ($c -eq 'Yes') { Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"' -Verb RunAs; Write-Log 'Script MAS lanzado para Office.' 'ok' }
}); $pnlAct.Controls.Add($bActO)

# ============================================================
#  ──────────────  PAGE 4: SEGURIDAD  ──────────────
# ============================================================
$p4 = $pages[4]
New-SectionLbl '  Estado de seguridad' 0 0 $p4

$b = New-Btn '🛡  Estado de Defender' 0 22 'green'
$b.Add_Click({
    Run-PS-Async -label 'Consultando Windows Defender' -block {
        try {
            $s = Get-MpComputerStatus
            $lines = @(
                "Antivirus activo     : $($s.AntivirusEnabled)",
                "Protección real-time : $($s.RealTimeProtectionEnabled)",
                "Última actualización : $($s.AntivirusSignatureLastUpdated)",
                "Versión definiciones : $($s.AntivirusSignatureVersion)"
            )
            return @{ msg = "--- Windows Defender ---`n" + ($lines -join "`n"); color = 'ok' }
        } catch { return @{ msg = "Error al leer Defender: $_"; color = 'red' } }
    }
}); $p4.Controls.Add($b)

$b = New-Btn '🔍  Quick Scan' 198 22
$b.Add_Click({
    Write-Log 'Iniciando Quick Scan de Defender...' 'sub'
    Start-Process powershell -ArgumentList '-NoProfile -Command "Start-MpScan -ScanType QuickScan"' -Verb RunAs
    Write-Log 'Scan iniciado en segundo plano.' 'ok'
}); $p4.Controls.Add($b)

$b = New-Btn '🔥  Estado del Firewall' 396 22
$b.Add_Click({
    Run-PS-Async -label 'Consultando firewall' -block {
        try {
            $profs = Get-NetFirewallProfile
            $lines = $profs | ForEach-Object { "$($_.Name): $(if($_.Enabled){'ACTIVO'}else{'INACTIVO'})" }
            return @{ msg = "--- Firewall ---`n" + ($lines -join "`n"); color = 'info' }
        } catch {
            $r = & netsh advfirewall show allprofiles state 2>&1
            return @{ msg = $r -join "`n"; color = 'normal' }
        }
    }
}); $p4.Controls.Add($b)

$b = New-Btn '✅  Activar Firewall' 0 66 190 34 'green'
$b.Add_Click({ Run-Async 'netsh advfirewall set allprofiles state on' 'Activar Firewall' }); $p4.Controls.Add($b)

$b = New-Btn '🚫  Desactivar Firewall' 198 66 210 34 'red'
$b.Add_Click({
    $c = [Windows.Forms.MessageBox]::Show('¿Seguro que deseas desactivar el Firewall?', 'Advertencia', 'YesNo', 'Warning')
    if ($c -eq 'Yes') { Run-Async 'netsh advfirewall set allprofiles state off' 'Desactivar Firewall' }
}); $p4.Controls.Add($b)

New-SectionLbl '  Usuarios y dispositivos' 0 112 $p4

$b = New-Btn '👥  Listar Usuarios' 0 134
$b.Add_Click({
    Run-PS-Async -label 'Listando usuarios locales' -block {
        $u = Get-LocalUser | ForEach-Object { "$($_.Name) — $(if($_.Enabled){'Activo'}else{'Desactivado'}) — Último acceso: $($_.LastLogon)" }
        return @{ msg = "--- Usuarios locales ---`n" + ($u -join "`n"); color = 'normal' }
    }
}); $p4.Controls.Add($b)

$b = New-Btn '⚠  Dispositivos con Error' 198 134 210 34 'red'
$b.Add_Click({
    Run-PS-Async -label 'Buscando dispositivos con error' -block {
        $devs = Get-PnpDevice -Status Error,Unknown -EA SilentlyContinue
        if ($devs) {
            $lines = $devs | ForEach-Object { "$($_.Class): $($_.FriendlyName) — $($_.Status)" }
            return @{ msg = "--- Dispositivos con problema ---`n" + ($lines -join "`n"); color = 'red' }
        } else { return @{ msg = 'No se encontraron dispositivos con error.'; color = 'ok' } }
    }
}); $p4.Controls.Add($b)

$b = New-Btn '🖥  Adm. Dispositivos' 416 134 200 34
$b.Add_Click({ Start-Process devmgmt.msc }); $p4.Controls.Add($b)

New-SectionLbl '  Certificados y políticas' 0 182 $p4

$b = New-Btn '📜  Certificados Caducados' 0 204 220 34
$b.Add_Click({
    Run-PS-Async -label 'Revisando certificados' -block {
        $hoy = Get-Date
        $certs = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.NotAfter -lt $hoy.AddDays(30) }
        if ($certs) {
            $lines = $certs | ForEach-Object { "$($_.Subject) — Vence: $($_.NotAfter.ToString('dd/MM/yyyy'))" }
            return @{ msg = "--- Certificados próximos a vencer ---`n" + ($lines -join "`n"); color = 'warn' }
        } else { return @{ msg = 'No hay certificados próximos a vencer.'; color = 'ok' } }
    }
}); $p4.Controls.Add($b)

$b = New-Btn '🔏  Políticas de Seguridad' 228 204 210 34
$b.Add_Click({ Start-Process secpol.msc }); $p4.Controls.Add($b)

$b = New-Btn '🔒  Configurar UAC' 446 204 180 34
$b.Add_Click({ Start-Process UserAccountControlSettings.exe }); $p4.Controls.Add($b)

# ============================================================
#  ──────────────  PAGE 5: BACKUP  ──────────────
# ============================================================
$p5 = $pages[5]
New-SectionLbl '  Carpetas a respaldar' 0 0 $p5

$backupFolders = @(
    @{ name='Documentos'; path="$env:USERPROFILE\Documents"; checked=$true  },
    @{ name='Escritorio';  path="$env:USERPROFILE\Desktop";   checked=$true  },
    @{ name='Descargas';   path="$env:USERPROFILE\Downloads"; checked=$false },
    @{ name='Imágenes';    path="$env:USERPROFILE\Pictures";  checked=$false },
    @{ name='Videos';      path="$env:USERPROFILE\Videos";    checked=$false },
    @{ name='Música';      path="$env:USERPROFILE\Music";     checked=$false }
)

$cbFolders = @(); $xF = 0; $yF = 22
foreach ($bf in $backupFolders) {
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text = $bf.name; $cb.Checked = $bf.checked
    $cb.Location = New-Object Drawing.Point($xF, $yF)
    $cb.Size = New-Object Drawing.Size(140, 24)
    $cb.ForeColor = $cText; $cb.BackColor = $cBg; $cb.Tag = $bf.path
    $p5.Controls.Add($cb); $cbFolders += $cb
    $xF += 148; if ($xF -gt 580) { $xF = 0; $yF += 26 }
}

$lblDest = New-Object Windows.Forms.Label
$lblDest.Text = "Destino: $env:USERPROFILE\Desktop"
$lblDest.Location = New-Object Drawing.Point(0, 56)
$lblDest.Size = New-Object Drawing.Size(500, 18)
$lblDest.ForeColor = $cSub; $lblDest.Font = New-Object Drawing.Font('Consolas', 8)
$p5.Controls.Add($lblDest)

$bDest = New-Btn '📁  Cambiar Destino' 510 50 170 28
$bDest.Add_Click({
    $d = New-Object Windows.Forms.FolderBrowserDialog; $d.Description = 'Carpeta destino para el backup'
    if ($d.ShowDialog() -eq 'OK') { $lblDest.Text = "Destino: $($d.SelectedPath)" }
}); $p5.Controls.Add($bDest)

New-SectionLbl '  Crear backup' 0 86 $p5

$bZip = New-Btn '📦  Crear Backup ZIP' 0 108 200 36 'green'
$bZip.Add_Click({
    $dest = ($lblDest.Text -replace '^Destino: ','').Trim()
    $sel = $cbFolders | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Log 'Selecciona al menos una carpeta.' 'warn'; return }
    $folders = $sel | ForEach-Object { $_.Tag }
    Write-Log "Creando backup ZIP en: $dest" 'sub'
    Run-PS-Async -label 'Creando backup ZIP' -block {
        param($dst, $flds)
        Add-Type -Assembly System.IO.Compression.FileSystem
        $zipName = "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        $zipPath = Join-Path $dst $zipName
        $tmp = "$env:TEMP\syscodi_backup_tmp"
        Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
        New-Item $tmp -ItemType Directory | Out-Null
        foreach ($f in $flds) {
            if (Test-Path $f) {
                Copy-Item $f "$tmp\$(Split-Path $f -Leaf)" -Recurse -Force -EA SilentlyContinue
            }
        }
        [System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $zipPath)
        Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
        return @{ msg = "Backup creado: $zipPath"; color = 'ok' }
    } -args @($dest, $folders)
}); $p5.Controls.Add($bZip)

$bDrv = New-Btn '🔧  Exportar Drivers' 208 108 190 36
$bDrv.Add_Click({
    $d = New-Object Windows.Forms.FolderBrowserDialog; $d.Description = 'Carpeta destino para drivers'
    if ($d.ShowDialog() -eq 'OK') {
        $path = $d.SelectedPath; Write-Log "Exportando drivers a: $path" 'sub'
        Start-Process powershell -ArgumentList "-NoProfile -Command `"pnputil /export-driver * '$path'`"" -Verb RunAs
        Write-Log 'Exportación de drivers iniciada.' 'ok'
    }
}); $p5.Controls.Add($bDrv)

$bReg = New-Btn '📋  Exportar Registro' 406 108 190 36
$bReg.Add_Click({
    $d = New-Object Windows.Forms.SaveFileDialog; $d.Filter = 'Registry (*.reg)|*.reg'
    $d.FileName = "HKCU_Backup_$(Get-Date -Format 'yyyyMMdd').reg"
    if ($d.ShowDialog() -eq 'OK') {
        Run-Async "reg export HKCU `"$($d.FileName)`" /y" "Exportar registro a $($d.FileName)"
    }
}); $p5.Controls.Add($bReg)

$bWBak = New-Btn '🪟  Copia de Seguridad Windows' 0 152 250 34
$bWBak.Add_Click({ Start-Process 'control' -ArgumentList '/name Microsoft.BackupAndRestore' }); $p5.Controls.Add($bWBak)

# ============================================================
#  ──────────────  PAGE 6: SISTEMA  ──────────────
# ============================================================
$p6 = $pages[6]

# Tarjetas de info del sistema (grid 2x3)
$sysCards = @('OS', 'Version', 'CPU', 'Nucleos', 'RAM', 'Disco')
$cardLabels = @{}; $cardValues = @{}
$cx = 0; $cy = 0
foreach ($key in $sysCards) {
    $card = New-Object Windows.Forms.Panel
    $card.Location = New-Object Drawing.Point(($cx * 208), ($cy * 72))
    $card.Size = New-Object Drawing.Size(200, 64)
    $card.BackColor = $cCard
    $p6.Controls.Add($card)

    $lbl = New-Object Windows.Forms.Label
    $lbl.Text = $key; $lbl.Location = New-Object Drawing.Point(10, 8)
    $lbl.Size = New-Object Drawing.Size(180, 16)
    $lbl.ForeColor = $cSub; $lbl.Font = New-Object Drawing.Font('Segoe UI', 8)
    $card.Controls.Add($lbl); $cardLabels[$key] = $lbl

    $val = New-Object Windows.Forms.Label
    $val.Text = '—'; $val.Location = New-Object Drawing.Point(10, 26)
    $val.Size = New-Object Drawing.Size(180, 30)
    $val.ForeColor = $cAccent2; $val.Font = New-Object Drawing.Font('Segoe UI', 10, [Drawing.FontStyle]::Bold)
    $card.Controls.Add($val); $cardValues[$key] = $val

    $cx++; if ($cx -ge 3) { $cx = 0; $cy++ }
}

New-SectionLbl '  Acciones' 0 152 $p6

$bLoad = New-Btn '▶  Cargar Info del Sistema' 0 172 220 36 'green'
$bLoad.Add_Click({
    Run-PS-Async -label 'Cargando info del sistema' -block {
        $os  = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor
        $mem = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
        $free= [math]::Round($os.FreePhysicalMemory / 1MB, 1)
        $disk= Get-PSDrive C
        $df  = [math]::Round($disk.Free/1GB, 1)
        $dt  = [math]::Round(($disk.Used+$disk.Free)/1GB, 1)
        return @(
            @{ msg = "__SYSINFO__"; color = 'info' }
            @{ msg = $os.Caption;              color = '__OS__' }
            @{ msg = $os.Version;              color = '__Version__' }
            @{ msg = $cpu.Name;                color = '__CPU__' }
            @{ msg = "$($cpu.NumberOfCores) núcleos / $($cpu.NumberOfLogicalProcessors) lógicos"; color = '__Nucleos__' }
            @{ msg = "$mem GB total / $free GB libre"; color = '__RAM__' }
            @{ msg = "$df GB libres / $dt GB total";   color = '__Disco__' }
        )
    }
}); $p6.Controls.Add($bLoad)

$bUptime = New-Btn '⏱  Ver Uptime' 228 172 160 36
$bUptime.Add_Click({
    Run-PS-Async -label 'Consultando uptime' -block {
        $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $up   = (Get-Date) - $boot
        return @{ msg = "Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m — desde $($boot.ToString('dd/MM/yyyy HH:mm'))"; color = 'info' }
    }
}); $p6.Controls.Add($bUptime)

$bWU = New-Btn '🔄  Buscar Actualizaciones' 396 172 220 36
$bWU.Add_Click({ Start-Process 'ms-settings:windowsupdate' }); $p6.Controls.Add($bWU)

$bExp = New-Btn '📄  Exportar Reporte' 0 216 200 34
$bExp.Add_Click({
    $d = New-Object Windows.Forms.SaveFileDialog
    $d.Filter = 'Text (*.txt)|*.txt'; $d.FileName = "Reporte_Sistema_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if ($d.ShowDialog() -eq 'OK') {
        $os  = Get-CimInstance Win32_OperatingSystem
        $cpu = Get-CimInstance Win32_Processor
        $report = @(
            "SysCodi WinTool Pro v3 — Reporte de Sistema",
            "Generado: $(Get-Date)",
            "==========================================",
            "OS       : $($os.Caption) $($os.Version)",
            "CPU      : $($cpu.Name)",
            "RAM      : $([math]::Round($os.TotalVisibleMemorySize/1MB,1)) GB",
            "Equipo   : $env:COMPUTERNAME",
            "Usuario  : $env:USERNAME"
        )
        $report | Set-Content $d.FileName -Encoding UTF8
        Write-Log "Reporte guardado: $($d.FileName)" 'ok'
    }
}); $p6.Controls.Add($bExp)

# ============================================================
#  RECOGEDOR DE RESULTADOS ESPECIALES (sysinfo para tarjetas)
# ============================================================
$Global:JobTimer.Add_Tick({
    # Procesar resultados de sysinfo (actualizar tarjetas UI)
})

# Parchar el timer para manejar sysinfo desde el job
$Global:JobTimer2 = New-Object Windows.Forms.Timer
$Global:JobTimer2.Interval = 500
$Global:JobTimer2.Add_Tick({
    $done = $Global:Jobs | Where-Object { $_.Handle.IsCompleted }
    foreach ($j in $done) {
        try {
            $results = $j.PS.EndInvoke($j.Handle)
            $isSysInfo = $results | Where-Object { $_ -is [hashtable] -and $_.msg -eq '__SYSINFO__' }
            if ($isSysInfo) {
                $map = @{ 'OS'='__OS__'; 'Version'='__Version__'; 'CPU'='__CPU__'; 'Nucleos'='__Nucleos__'; 'RAM'='__RAM__'; 'Disco'='__Disco__' }
                foreach ($r in $results) {
                    if ($r -is [hashtable] -and $r.color -like '__*__') {
                        $key = $r.color.Trim('_')
                        if ($cardValues.ContainsKey($key)) { $cardValues[$key].Text = $r.msg }
                    } elseif ($r -is [hashtable] -and $r.msg -ne '__SYSINFO__' -and $r.color -notlike '__*__') {
                        Write-Log $r.msg $r.color
                    }
                }
                Write-Log 'Información del sistema cargada. Monitor activo.' 'ok'
                $monTimer.Start()
            } else {
                foreach ($r in $results) {
                    if ($r -is [hashtable] -and $r.ContainsKey('msg')) { Write-Log $r.msg $r.color }
                    elseif ($r) { Write-Log ($r | Out-String).Trim() 'normal' }
                }
            }
            if ($j.PS.Streams.Error.Count -gt 0) {
                foreach ($e in $j.PS.Streams.Error) { Write-Log "Error: $e" 'red' }
            }
        } catch { Write-Log "Error interno job: $_" 'red' }
        finally { $j.PS.Dispose() }
    }
    $Global:Jobs.RemoveAll({ param($x) $x.Handle.IsCompleted }) | Out-Null
})
$Global:JobTimer.Stop()  # Detener el timer base, usar solo el extendido
$Global:JobTimer2.Start()

# ============================================================
#  ARRANQUE
# ============================================================
Set-ActivePage 0
Write-Log 'SysCodi WinTool Pro v3 iniciado.' 'info'
Write-Log "Ejecutando como: $env:USERNAME $(if($isAdmin){'(Administrador)'}else{'(Sin privilegios de admin)'})" $(if($isAdmin){'ok'}else{'warn'})
Write-Log 'Listo. Selecciona una opción del menú.' 'sub'

# Limpieza al cerrar
$form.Add_FormClosing({
    $monTimer.Stop(); $Global:JobTimer2.Stop()
    $Global:RSPool.Close(); $Global:RSPool.Dispose()
})

[Windows.Forms.Application]::Run($form)
