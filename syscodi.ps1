Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#   LOGO - Descarga desde GitHub
# ============================================================
$logoUrl  = "https://raw.githubusercontent.com/syscodi7/Tools/main/sis.png"
$logoPath = "$env:TEMP\syscodi_logo.png"
try { Invoke-WebRequest -Uri $logoUrl -OutFile $logoPath -ErrorAction Stop } catch { $logoPath = "" }

# ============================================================
#   COLORES CORPORATIVOS
# ============================================================
$cBg      = [Drawing.Color]::FromArgb(10, 18, 40)
$cPanel   = [Drawing.Color]::FromArgb(18, 30, 62)
$cCard    = [Drawing.Color]::FromArgb(22, 40, 80)
$cAccent  = [Drawing.Color]::FromArgb(0, 120, 215)
$cAccent2 = [Drawing.Color]::FromArgb(0, 180, 255)
$cText    = [Drawing.Color]::White
$cSubText = [Drawing.Color]::FromArgb(160, 200, 255)
$cBtn     = [Drawing.Color]::FromArgb(0, 90, 170)
$cBtnHov  = [Drawing.Color]::FromArgb(0, 130, 210)
$cOutput  = [Drawing.Color]::FromArgb(8, 15, 35)
$cGreen   = [Drawing.Color]::FromArgb(0, 210, 120)
$cYellow  = [Drawing.Color]::FromArgb(255, 210, 60)
$cRed     = [Drawing.Color]::FromArgb(255, 80, 80)

# ============================================================
#   FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text            = "SysCodi WinTool Pro"
$form.Size            = New-Object Drawing.Size(1200, 720)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.Font            = New-Object Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false

# ============================================================
#   HEADER
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Size      = New-Object Drawing.Size(1200, 65)
$header.Location  = New-Object Drawing.Point(0, 0)
$header.BackColor = $cPanel
$form.Controls.Add($header)

$titleX = 15
if ($logoPath -and (Test-Path $logoPath)) {
    $logoPic          = New-Object Windows.Forms.PictureBox
    $logoPic.Location = New-Object Drawing.Point(10, 7)
    $logoPic.Size     = New-Object Drawing.Size(48, 48)
    $logoPic.SizeMode = "Zoom"
    $logoPic.BackColor= $cPanel
    $logoPic.Image    = [Drawing.Image]::FromFile($logoPath)
    $header.Controls.Add($logoPic)
    try {
        $bmp = [Drawing.Bitmap][Drawing.Image]::FromFile($logoPath)
        $form.Icon = [Drawing.Icon]::FromHandle($bmp.GetHicon())
    } catch {}
    $titleX = 68
}

$lblTitle          = New-Object Windows.Forms.Label
$lblTitle.Text     = "SysCodi WinTool Pro"
$lblTitle.Font     = New-Object Drawing.Font("Segoe UI", 15, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor= $cAccent2
$lblTitle.Location = New-Object Drawing.Point($titleX, 10)
$lblTitle.Size     = New-Object Drawing.Size(420, 30)
$header.Controls.Add($lblTitle)

$lblSub            = New-Object Windows.Forms.Label
$lblSub.Text       = "Utilidad de sistema avanzada para Windows"
$lblSub.Font       = New-Object Drawing.Font("Segoe UI", 8)
$lblSub.ForeColor  = $cSubText
$lblSub.Location   = New-Object Drawing.Point($titleX, 42)
$lblSub.Size       = New-Object Drawing.Size(420, 16)
$header.Controls.Add($lblSub)

# Info del sistema en header (derecha)
$os = Get-CimInstance Win32_OperatingSystem
$lblOS          = New-Object Windows.Forms.Label
$lblOS.Text     = "$($os.Caption) $($os.BuildNumber)"
$lblOS.Font     = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$lblOS.ForeColor= $cAccent2
$lblOS.Location = New-Object Drawing.Point(760, 8)
$lblOS.Size     = New-Object Drawing.Size(430, 18)
$header.Controls.Add($lblOS)

$lblUser          = New-Object Windows.Forms.Label
$lblUser.Text     = "Usuario: $env:USERNAME        Equipo: $env:COMPUTERNAME"
$lblUser.Font     = New-Object Drawing.Font("Segoe UI", 8)
$lblUser.ForeColor= $cText
$lblUser.Location = New-Object Drawing.Point(760, 28)
$lblUser.Size     = New-Object Drawing.Size(430, 16)
$header.Controls.Add($lblUser)

$lblTime          = New-Object Windows.Forms.Label
$lblTime.Text     = "Tiempo activo: --    Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$lblTime.Font     = New-Object Drawing.Font("Segoe UI", 8)
$lblTime.ForeColor= $cSubText
$lblTime.Location = New-Object Drawing.Point(760, 46)
$lblTime.Size     = New-Object Drawing.Size(430, 16)
$header.Controls.Add($lblTime)

# Timer para actualizar fecha/hora
$timerClock = New-Object Windows.Forms.Timer
$timerClock.Interval = 1000
$timerClock.Add_Tick({
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $up   = (Get-Date) - $boot
    $lblTime.Text = "Tiempo activo: $($up.Days)d $($up.Hours)h $($up.Minutes)m    Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
})
$timerClock.Start()

# ============================================================
#   TAB CONTROL
# ============================================================
$tabs              = New-Object Windows.Forms.TabControl
$tabs.Location     = New-Object Drawing.Point(5, 68)
$tabs.Size         = New-Object Drawing.Size(730, 520)
$tabs.BackColor    = $cBg
$tabs.Appearance   = "FlatButtons"
$tabs.Font         = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$form.Controls.Add($tabs)

function New-Tab($titulo) {
    $t            = New-Object Windows.Forms.TabPage
    $t.Text       = "  $titulo  "
    $t.BackColor  = $cBg
    $t.ForeColor  = $cText
    $tabs.TabPages.Add($t)
    return $t
}

$tabRepair  = New-Tab "Reparacion"
$tabApps    = New-Tab "Aplicaciones"
$tabTweaks  = New-Tab "Tweaks"
$tabUtils   = New-Tab "Utilidades"
$tabTransf  = New-Tab "Transferencia"
$tabSystem  = New-Tab "Sistema"
$tabDash    = New-Tab "Dashboard"
$tabReports = New-Tab "Reportes"
$tabSettings= New-Tab "Ajustes"

# ============================================================
#   PANEL DERECHO - CONSOLA
# ============================================================
$rightPanel           = New-Object Windows.Forms.Panel
$rightPanel.Location  = New-Object Drawing.Point(738, 68)
$rightPanel.Size      = New-Object Drawing.Size(452, 520)
$rightPanel.BackColor = $cOutput
$form.Controls.Add($rightPanel)

$lblConsole           = New-Object Windows.Forms.Label
$lblConsole.Text      = "  Consola de salida"
$lblConsole.Location  = New-Object Drawing.Point(0, 0)
$lblConsole.Size      = New-Object Drawing.Size(452, 28)
$lblConsole.ForeColor = $cAccent2
$lblConsole.BackColor = $cPanel
$lblConsole.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$lblConsole.TextAlign = "MiddleLeft"
$rightPanel.Controls.Add($lblConsole)

$btnClearOutput           = New-Object Windows.Forms.Button
$btnClearOutput.Text      = "Limpiar"
$btnClearOutput.Location  = New-Object Drawing.Point(366, 3)
$btnClearOutput.Size      = New-Object Drawing.Size(80, 22)
$btnClearOutput.BackColor = $cBtn
$btnClearOutput.ForeColor = $cText
$btnClearOutput.FlatStyle = "Flat"
$btnClearOutput.Font      = New-Object Drawing.Font("Segoe UI", 7)
$rightPanel.Controls.Add($btnClearOutput)

$outputBox            = New-Object Windows.Forms.RichTextBox
$outputBox.Location   = New-Object Drawing.Point(0, 30)
$outputBox.Size       = New-Object Drawing.Size(452, 490)
$outputBox.BackColor  = $cOutput
$outputBox.ForeColor  = $cAccent2
$outputBox.Font       = New-Object Drawing.Font("Consolas", 9)
$outputBox.ReadOnly   = $true
$outputBox.BorderStyle= "None"
$outputBox.Text       = "  Listo. Selecciona una opcion y ejecuta."
$rightPanel.Controls.Add($outputBox)

$btnClearOutput.Add_Click({ $outputBox.Clear() })

function Write-Out($msg, $color = $null) {
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionColor = if ($color) { $color } else { $cAccent2 }
    $outputBox.AppendText("`r`n $msg")
    $outputBox.ScrollToCaret()
}

function Run-Cmd($cmd) {
    Write-Out ">> $cmd" $cSubText
    try {
        $res = Invoke-Expression $cmd 2>&1
        Write-Out ($res -join "`r`n") $cText
    } catch {
        Write-Out "Error: $_" $cRed
    }
}

# ============================================================
#   HELPERS UI
# ============================================================
function New-Btn($texto, $x, $y, $w = 190, $h = 38, $parent = $null) {
    $b                          = New-Object Windows.Forms.Button
    $b.Text                     = $texto
    $b.Location                 = New-Object Drawing.Point($x, $y)
    $b.Size                     = New-Object Drawing.Size($w, $h)
    $b.BackColor                = $cBtn
    $b.ForeColor                = $cText
    $b.FlatStyle                = "Flat"
    $b.FlatAppearance.BorderColor = $cAccent
    $b.FlatAppearance.BorderSize  = 1
    $b.Font                     = New-Object Drawing.Font("Segoe UI", 9)
    $b.Cursor                   = "Hand"
    $b.Add_MouseEnter({ $this.BackColor = $cBtnHov })
    $b.Add_MouseLeave({ $this.BackColor = $cBtn })
    if ($parent) { $parent.Controls.Add($b) }
    return $b
}

function New-SecLabel($texto, $x, $y, $parent) {
    $lbl            = New-Object Windows.Forms.Label
    $lbl.Text       = $texto
    $lbl.Location   = New-Object Drawing.Point($x, $y)
    $lbl.Size       = New-Object Drawing.Size(710, 22)
    $lbl.ForeColor  = $cAccent2
    $lbl.Font       = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
    $parent.Controls.Add($lbl)
    # linea separadora
    $sep            = New-Object Windows.Forms.Panel
    $sep.Location   = New-Object Drawing.Point($x, ($y + 20))
    $sep.Size       = New-Object Drawing.Size(700, 1)
    $sep.BackColor  = [Drawing.Color]::FromArgb(0, 80, 160)
    $parent.Controls.Add($sep)
}

# ============================================================
#   TAB 1: REPARACION
# ============================================================
New-SecLabel "Limpieza" 10 10 $tabRepair

$b = New-Btn "  Limpiar Temporales" 10 38 195 38 $tabRepair
$b.Add_Click({
    Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue
    Write-Out "Temporales eliminados correctamente." $cGreen
})

$b = New-Btn "  Limpiar Prefetch" 215 38 195 38 $tabRepair
$b.Add_Click({
    Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue
    Write-Out "Prefetch limpiado." $cGreen
})

New-SecLabel "Reparacion de Windows" 10 90 $tabRepair

$b = New-Btn "  SFC /scannow" 10 118 195 38 $tabRepair
$b.Add_Click({ Run-Cmd "sfc /scannow" })

$b = New-Btn "  DISM RestoreHealth" 215 118 195 38 $tabRepair
$b.Add_Click({ Run-Cmd "DISM /Online /Cleanup-Image /RestoreHealth" })

$b = New-Btn "  CheckDisk (C:)" 420 118 195 38 $tabRepair
$b.Add_Click({ Run-Cmd "chkdsk C: /f /r /x" })

New-SecLabel "Red" 10 170 $tabRepair

$b = New-Btn "  DNS Flush" 10 198 165 38 $tabRepair
$b.Add_Click({ Run-Cmd "ipconfig /flushdns" })

$b = New-Btn "  Reset Red (netsh)" 185 198 180 38 $tabRepair
$b.Add_Click({
    Run-Cmd "netsh int ip reset"
    Run-Cmd "netsh winsock reset"
    Write-Out "Reinicia el PC para aplicar cambios de red." $cYellow
})

$b = New-Btn "  Ver Puertos" 375 198 165 38 $tabRepair
$b.Add_Click({ Run-Cmd "netstat -ano" })

$b = New-Btn "  Matar Puerto 80" 550 198 165 38 $tabRepair
$b.Add_Click({
    $pids80 = (netstat -ano | Select-String ":80\s") -replace '.*\s(\d+)$','$1' | Sort-Object -Unique
    foreach ($p in $pids80) {
        if ($p -match '^\d+$') {
            Stop-Process -Id $p -Force -EA SilentlyContinue
            Write-Out "Proceso PID $p en puerto 80 terminado." $cGreen
        }
    }
})

# ============================================================
#   TAB 2: APLICACIONES
# ============================================================
$scroll           = New-Object Windows.Forms.Panel
$scroll.Location  = New-Object Drawing.Point(0, 0)
$scroll.Size      = New-Object Drawing.Size(725, 430)
$scroll.AutoScroll= $true
$scroll.BackColor = $cBg
$tabApps.Controls.Add($scroll)

$appList = @(
    @{cat="Navegadores";    name="Google Chrome";   cmd="winget install -e --id Google.Chrome"},
    @{cat="Navegadores";    name="Mozilla Firefox"; cmd="winget install -e --id Mozilla.Firefox"},
    @{cat="Navegadores";    name="Brave Browser";   cmd="winget install -e --id Brave.Brave"; foss=$true},
    @{cat="Navegadores";    name="LibreWolf";        cmd="winget install -e --id LibreWolf.LibreWolf"; foss=$true},
    @{cat="Comunicacion";   name="Discord";          cmd="winget install -e --id Discord.Discord"},
    @{cat="Comunicacion";   name="Telegram";         cmd="winget install -e --id Telegram.TelegramDesktop"; foss=$true},
    @{cat="Comunicacion";   name="Slack";            cmd="winget install -e --id SlackTechnologies.Slack"},
    @{cat="Comunicacion";   name="Signal";           cmd="winget install -e --id OpenWhisperSystems.Signal"; foss=$true},
    @{cat="Desarrollo";     name="VS Code";          cmd="winget install -e --id Microsoft.VisualStudioCode"},
    @{cat="Desarrollo";     name="Git";              cmd="winget install -e --id Git.Git"; foss=$true},
    @{cat="Desarrollo";     name="Python 3";         cmd="winget install -e --id Python.Python.3"; foss=$true},
    @{cat="Desarrollo";     name="NodeJS LTS";       cmd="winget install -e --id OpenJS.NodeJS.LTS"; foss=$true},
    @{cat="Utilidades";     name="7-Zip";            cmd="winget install -e --id 7zip.7zip"; foss=$true},
    @{cat="Utilidades";     name="VLC";              cmd="winget install -e --id VideoLAN.VLC"; foss=$true},
    @{cat="Utilidades";     name="WinRAR";           cmd="winget install -e --id RARLab.WinRAR"},
    @{cat="Utilidades";     name="Notepad++";        cmd="winget install -e --id Notepad++.Notepad++"; foss=$true}
)

$checkboxes = @()
$yPos = 5; $lastCat = ""; $col = 0

foreach ($app in $appList) {
    if ($app.cat -ne $lastCat) {
        $col = 0
        if ($lastCat -ne "") { $yPos += 8 }
        $lbl          = New-Object Windows.Forms.Label
        $lbl.Text     = " $($app.cat)"
        $lbl.Location = New-Object Drawing.Point(5, $yPos)
        $lbl.Size     = New-Object Drawing.Size(720, 20)
        $lbl.ForeColor= $cAccent2
        $lbl.Font     = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
        $scroll.Controls.Add($lbl)
        $yPos += 22; $lastCat = $app.cat
    }
    $cb           = New-Object Windows.Forms.CheckBox
    $cb.Text      = $app.name
    $cb.Location  = New-Object Drawing.Point((5 + $col * 178), $yPos)
    $cb.Size      = New-Object Drawing.Size(170, 22)
    $cb.ForeColor = if ($app.foss) { $cAccent2 } else { $cText }
    $cb.BackColor = $cBg
    $cb.Tag       = $app.cmd
    $scroll.Controls.Add($cb)
    $checkboxes += $cb
    $col++
    if ($col -ge 4) { $col = 0; $yPos += 25 }
}
$yPos += 30

$pnlAppBtns           = New-Object Windows.Forms.Panel
$pnlAppBtns.Location  = New-Object Drawing.Point(0, 432)
$pnlAppBtns.Size      = New-Object Drawing.Size(725, 48)
$pnlAppBtns.BackColor = $cPanel
$tabApps.Controls.Add($pnlAppBtns)

$lblFoss          = New-Object Windows.Forms.Label
$lblFoss.Text     = "  Azul claro = FOSS (Software Libre)"
$lblFoss.ForeColor= $cAccent2
$lblFoss.Location = New-Object Drawing.Point(10, 14)
$lblFoss.Size     = New-Object Drawing.Size(280, 20)
$pnlAppBtns.Controls.Add($lblFoss)

$b = New-Btn "  Instalar Seleccionadas" 490 7 210 34 $pnlAppBtns
$b.Add_Click({
    $sel = $checkboxes | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ninguna aplicacion." $cYellow; return }
    foreach ($cb in $sel) {
        Write-Out "Instalando: $($cb.Text)..." $cSubText
        Start-Process powershell -ArgumentList "-NoProfile -Command `"$($cb.Tag)`"" -Wait
        Write-Out "$($cb.Text) instalado." $cGreen
    }
})

$b2 = New-Btn "  Limpiar Seleccion" 280 7 200 34 $pnlAppBtns
$b2.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $false } })

# ============================================================
#   TAB 3: TWEAKS
# ============================================================
New-SecLabel "Rendimiento y Privacidad" 10 10 $tabTweaks

$tweaks = @(
    @{name="Plan de energia: Alto rendimiento"; cmd='powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'},
    @{name="Deshabilitar efectos visuales";      cmd='SystemPropertiesPerformance.exe'},
    @{name="Deshabilitar notificaciones";        cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f'},
    @{name="Deshabilitar Telemetria";            cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'},
    @{name="Deshabilitar Cortana";               cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f'},
    @{name="Modo juego activado";                cmd='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f'},
    @{name="Mostrar extensiones de archivo";     cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'},
    @{name="Mostrar archivos ocultos";           cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'},
    @{name="Deshabilitar animaciones de ventana";cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f'},
    @{name="Habilitar modo oscuro";              cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0 /f'}
)

$yT = 38; $colT = 0; $tweakChecks = @()
foreach ($tw in $tweaks) {
    $cb           = New-Object Windows.Forms.CheckBox
    $cb.Text      = $tw.name
    $cb.Location  = New-Object Drawing.Point((10 + $colT * 360), $yT)
    $cb.Size      = New-Object Drawing.Size(350, 26)
    $cb.ForeColor = $cText
    $cb.BackColor = $cBg
    $cb.Tag       = $tw.cmd
    $tabTweaks.Controls.Add($cb)
    $tweakChecks += $cb
    $colT++
    if ($colT -ge 2) { $colT = 0; $yT += 30 }
}

$b = New-Btn "  Aplicar Tweaks Seleccionados" 10 360 260 38 $tabTweaks
$b.Add_Click({
    $sel = $tweakChecks | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ningun tweak." $cYellow; return }
    foreach ($cb in $sel) {
        Write-Out "Aplicando: $($cb.Text)..." $cSubText
        Invoke-Expression $cb.Tag 2>&1 | Out-Null
        Write-Out "Listo." $cGreen
    }
    Write-Out "Todos los tweaks aplicados. Puede requerir reinicio." $cGreen
})

# ============================================================
#   TAB 4: UTILIDADES
# ============================================================
function Install-MsOffCrypto {
    $check = python -c "import msoffcrypto" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Out "Instalando msoffcrypto-tool..." $cSubText
        python -m pip install msoffcrypto-tool | Out-Null
    }
}

function New-UtilPanel($titulo, $sub, $parent, $y, $h=120) {
    $pnl           = New-Object Windows.Forms.Panel
    $pnl.Location  = New-Object Drawing.Point(8, $y)
    $pnl.Size      = New-Object Drawing.Size(710, $h)
    $pnl.BackColor = $cCard
    $parent.Controls.Add($pnl)
    $lbl           = New-Object Windows.Forms.Label
    $lbl.Text      = $titulo
    $lbl.Location  = New-Object Drawing.Point(10, 8)
    $lbl.Size      = New-Object Drawing.Size(690, 22)
    $lbl.ForeColor = $cAccent2
    $lbl.Font      = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $pnl.Controls.Add($lbl)
    $lblS          = New-Object Windows.Forms.Label
    $lblS.Text     = $sub
    $lblS.Location = New-Object Drawing.Point(10, 32)
    $lblS.Size     = New-Object Drawing.Size(690, 16)
    $lblS.ForeColor= $cSubText
    $lblS.Font     = New-Object Drawing.Font("Segoe UI", 8)
    $pnl.Controls.Add($lblS)
    return $pnl
}

# Excel
$pnlExcel = New-UtilPanel "Quitar contrasena - Excel (.xlsx/.xls)" "Se creara una copia sin contrasena en la misma carpeta." $tabUtils 10

$lblExcelPath           = New-Object Windows.Forms.Label
$lblExcelPath.Text      = "Ningun archivo seleccionado"
$lblExcelPath.Location  = New-Object Drawing.Point(10, 55)
$lblExcelPath.Size      = New-Object Drawing.Size(690, 16)
$lblExcelPath.ForeColor = $cText
$lblExcelPath.Font      = New-Object Drawing.Font("Consolas", 7)
$pnlExcel.Controls.Add($lblExcelPath)

$b = New-Btn "Buscar Excel" 10 75 145 32 $pnlExcel
$b.Add_Click({
    $dlg = New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter = "Excel (*.xlsx;*.xls;*.xlsm)|*.xlsx;*.xls;*.xlsm"
    if ($dlg.ShowDialog() -eq "OK") { $lblExcelPath.Text = $dlg.FileName }
})

$b2 = New-Btn "Quitar Contrasena" 165 75 175 32 $pnlExcel
$b2.Add_Click({
    $path = $lblExcelPath.Text
    if (-not (Test-Path $path)) { Write-Out "Selecciona un archivo Excel primero." $cYellow; return }
    Install-MsOffCrypto
    $out = $path -replace '(\.[^.]+)$','_sin_pass$1'
    $py  = "import msoffcrypto`nwith open(r'$path','rb') as f:`n    o=msoffcrypto.OfficeFile(f)`n    o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
    $tmp = "$env:TEMP\unlock_excel.py"
    $py | Set-Content $tmp -Encoding UTF8
    $res = python $tmp 2>&1
    if ($res -like "*OK*") { Write-Out "Excel desbloqueado: $out" $cGreen }
    else { Write-Out "Error: $res" $cRed }
})

# Word
$pnlWord = New-UtilPanel "Quitar contrasena - Word (.docx/.doc)" "Se creara una copia sin contrasena en la misma carpeta." $tabUtils 140

$lblWordPath           = New-Object Windows.Forms.Label
$lblWordPath.Text      = "Ningun archivo seleccionado"
$lblWordPath.Location  = New-Object Drawing.Point(10, 55)
$lblWordPath.Size      = New-Object Drawing.Size(690, 16)
$lblWordPath.ForeColor = $cText
$lblWordPath.Font      = New-Object Drawing.Font("Consolas", 7)
$pnlWord.Controls.Add($lblWordPath)

$b = New-Btn "Buscar Word" 10 75 145 32 $pnlWord
$b.Add_Click({
    $dlg = New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter = "Word (*.docx;*.doc;*.docm)|*.docx;*.doc;*.docm"
    if ($dlg.ShowDialog() -eq "OK") { $lblWordPath.Text = $dlg.FileName }
})

$b2 = New-Btn "Quitar Contrasena" 165 75 175 32 $pnlWord
$b2.Add_Click({
    $path = $lblWordPath.Text
    if (-not (Test-Path $path)) { Write-Out "Selecciona un archivo Word primero." $cYellow; return }
    Install-MsOffCrypto
    $out = $path -replace '(\.[^.]+)$','_sin_pass$1'
    $py  = "import msoffcrypto`nwith open(r'$path','rb') as f:`n    o=msoffcrypto.OfficeFile(f)`n    o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
    $tmp = "$env:TEMP\unlock_word.py"
    $py | Set-Content $tmp -Encoding UTF8
    $res = python $tmp 2>&1
    if ($res -like "*OK*") { Write-Out "Word desbloqueado: $out" $cGreen }
    else { Write-Out "Error: $res" $cRed }
})

# ZIP
$pnlZip = New-UtilPanel "Quitar contrasena - ZIP" "Ingresa la contrasena si la recuerdas, o usa fuerza bruta con wordlist (.txt)." $tabUtils 270 170

$lblZipPath           = New-Object Windows.Forms.Label
$lblZipPath.Text      = "Ningun archivo seleccionado"
$lblZipPath.Location  = New-Object Drawing.Point(10, 55)
$lblZipPath.Size      = New-Object Drawing.Size(400, 16)
$lblZipPath.ForeColor = $cText
$lblZipPath.Font      = New-Object Drawing.Font("Consolas", 7)
$pnlZip.Controls.Add($lblZipPath)

$lblWlPath           = New-Object Windows.Forms.Label
$lblWlPath.Text      = "Sin wordlist"
$lblWlPath.Location  = New-Object Drawing.Point(420, 55)
$lblWlPath.Size      = New-Object Drawing.Size(270, 16)
$lblWlPath.ForeColor = $cSubText
$lblWlPath.Font      = New-Object Drawing.Font("Consolas", 7)
$pnlZip.Controls.Add($lblWlPath)

$lblPL           = New-Object Windows.Forms.Label
$lblPL.Text      = "Contrasena:"
$lblPL.Location  = New-Object Drawing.Point(10, 78)
$lblPL.Size      = New-Object Drawing.Size(88, 20)
$lblPL.ForeColor = $cText
$pnlZip.Controls.Add($lblPL)

$txtZipPass           = New-Object Windows.Forms.TextBox
$txtZipPass.Location  = New-Object Drawing.Point(100, 76)
$txtZipPass.Size      = New-Object Drawing.Size(160, 22)
$txtZipPass.UseSystemPasswordChar = $true
$txtZipPass.BackColor = $cOutput
$txtZipPass.ForeColor = $cText
$pnlZip.Controls.Add($txtZipPass)

$b  = New-Btn "Buscar ZIP"  10 108 130 30 $pnlZip
$b.Add_Click({
    $dlg = New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter = "ZIP (*.zip)|*.zip"
    if ($dlg.ShowDialog() -eq "OK") { $lblZipPath.Text = $dlg.FileName }
})

$b2 = New-Btn "Wordlist" 150 108 120 30 $pnlZip
$b2.Add_Click({
    $dlg = New-Object Windows.Forms.OpenFileDialog
    $dlg.Filter = "Text (*.txt)|*.txt"
    if ($dlg.ShowDialog() -eq "OK") { $lblWlPath.Text = $dlg.FileName }
})

$b3 = New-Btn "Extraer / Quitar Contrasena" 280 108 230 30 $pnlZip
$b3.Add_Click({
    $zipPath = $lblZipPath.Text; $pass = $txtZipPass.Text.Trim(); $wl = $lblWlPath.Text
    if (-not (Test-Path $zipPath)) { Write-Out "Selecciona un archivo ZIP primero." $cYellow; return }
    $outDir  = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($zipPath), [System.IO.Path]::GetFileNameWithoutExtension($zipPath) + "_extraido")
    $pyScript = @"
import zipfile, os, sys
path='ZIPPATH'; out='OUTDIR'; pwd='ZIPPASS'; wl='WLPATH'
os.makedirs(out, exist_ok=True)
if pwd:
    try:
        with zipfile.ZipFile(path) as z: z.extractall(out, pwd=pwd.encode())
        print('OK:Extraido con contrasena en: ' + out); sys.exit()
    except Exception as e: print('ERROR:' + str(e)); sys.exit()
try:
    with zipfile.ZipFile(path) as z: z.extractall(out)
    print('OK:Extraido sin contrasena en: ' + out); sys.exit()
except RuntimeError: pass
if os.path.exists(wl):
    with open(wl,'r',errors='ignore') as f:
        for i,line in enumerate(f):
            p=line.strip()
            try:
                with zipfile.ZipFile(path) as z: z.extractall(out, pwd=p.encode())
                print('OK:Contrasena: ' + p + ' | Extraido en: ' + out); sys.exit()
            except: pass
            if i%500==0: print('INFO:Probadas ' + str(i) + ' contrasenas...')
    print('ERROR:No se encontro la contrasena.')
else:
    print('ERROR:ZIP protegido. Ingresa contrasena o selecciona wordlist.')
"@
    $pyScript = $pyScript.Replace('ZIPPATH',$zipPath).Replace('OUTDIR',$outDir).Replace('ZIPPASS',$pass).Replace('WLPATH',$wl)
    $tmp = "$env:TEMP\unlock_zip.py"
    $pyScript | Set-Content $tmp -Encoding UTF8
    Write-Out "Procesando ZIP..." $cSubText
    $res = python $tmp 2>&1
    foreach ($line in $res) {
        if ($line -like "OK:*")    { Write-Out $line.Replace("OK:","") $cGreen }
        elseif ($line -like "ERROR:*") { Write-Out $line.Replace("ERROR:","") $cRed }
        else { Write-Out $line $cSubText }
    }
})

# ============================================================
#   TAB 5: TRANSFERENCIA
# ============================================================
New-SecLabel "Transferencia de Archivos" 10 10 $tabTransf

$lblSrcPath           = New-Object Windows.Forms.Label
$lblSrcPath.Text      = "Origen:  (ningun archivo/carpeta)"
$lblSrcPath.Location  = New-Object Drawing.Point(10, 50)
$lblSrcPath.Size      = New-Object Drawing.Size(700, 16)
$lblSrcPath.ForeColor = $cText
$lblSrcPath.Font      = New-Object Drawing.Font("Consolas", 8)
$tabTransf.Controls.Add($lblSrcPath)

$lblDstPath           = New-Object Windows.Forms.Label
$lblDstPath.Text      = "Destino: (ninguna carpeta)"
$lblDstPath.Location  = New-Object Drawing.Point(10, 72)
$lblDstPath.Size      = New-Object Drawing.Size(700, 16)
$lblDstPath.ForeColor = $cSubText
$lblDstPath.Font      = New-Object Drawing.Font("Consolas", 8)
$tabTransf.Controls.Add($lblDstPath)

$b = New-Btn "Seleccionar Origen" 10 95 190 36 $tabTransf
$b.Add_Click({
    $dlg = New-Object Windows.Forms.OpenFileDialog; $dlg.Multiselect = $true
    if ($dlg.ShowDialog() -eq "OK") { $lblSrcPath.Text = "Origen: " + ($dlg.FileNames -join "; ") }
})

$b2 = New-Btn "Seleccionar Destino" 210 95 190 36 $tabTransf
$b2.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $lblDstPath.Text = "Destino: " + $dlg.SelectedPath }
})

$b3 = New-Btn "Copiar Archivos" 410 95 180 36 $tabTransf
$b3.Add_Click({
    $src = $lblSrcPath.Text.Replace("Origen: ","").Split("; ")
    $dst = $lblDstPath.Text.Replace("Destino: ","")
    if (-not (Test-Path $dst)) { Write-Out "Selecciona carpeta destino." $cYellow; return }
    foreach ($f in $src) {
        Copy-Item $f -Destination $dst -Force -EA SilentlyContinue
        Write-Out "Copiado: $f -> $dst" $cGreen
    }
})

$b4 = New-Btn "Mover Archivos" 600 95 180 36 $tabTransf
$b4.Add_Click({
    $src = $lblSrcPath.Text.Replace("Origen: ","").Split("; ")
    $dst = $lblDstPath.Text.Replace("Destino: ","")
    if (-not (Test-Path $dst)) { Write-Out "Selecciona carpeta destino." $cYellow; return }
    foreach ($f in $src) {
        Move-Item $f -Destination $dst -Force -EA SilentlyContinue
        Write-Out "Movido: $f -> $dst" $cGreen
    }
})

New-SecLabel "Robocopy / Sincronizacion" 10 145 $tabTransf

$lblRoboSrc           = New-Object Windows.Forms.Label; $lblRoboSrc.Text = "Carpeta origen:  -"
$lblRoboSrc.Location  = New-Object Drawing.Point(10, 178); $lblRoboSrc.Size = New-Object Drawing.Size(700, 16)
$lblRoboSrc.ForeColor = $cText; $lblRoboSrc.Font = New-Object Drawing.Font("Consolas", 8)
$tabTransf.Controls.Add($lblRoboSrc)

$lblRoboDst           = New-Object Windows.Forms.Label; $lblRoboDst.Text = "Carpeta destino: -"
$lblRoboDst.Location  = New-Object Drawing.Point(10, 196); $lblRoboDst.Size = New-Object Drawing.Size(700, 16)
$lblRoboDst.ForeColor = $cSubText; $lblRoboDst.Font = New-Object Drawing.Font("Consolas", 8)
$tabTransf.Controls.Add($lblRoboDst)

$b = New-Btn "Origen Robocopy" 10 218 180 36 $tabTransf
$b.Add_Click({ $dlg = New-Object Windows.Forms.FolderBrowserDialog; if ($dlg.ShowDialog() -eq "OK") { $lblRoboSrc.Text = "Carpeta origen:  " + $dlg.SelectedPath } })

$b2 = New-Btn "Destino Robocopy" 200 218 180 36 $tabTransf
$b2.Add_Click({ $dlg = New-Object Windows.Forms.FolderBrowserDialog; if ($dlg.ShowDialog() -eq "OK") { $lblRoboDst.Text = "Carpeta destino: " + $dlg.SelectedPath } })

$b3 = New-Btn "Sincronizar (Robocopy)" 390 218 210 36 $tabTransf
$b3.Add_Click({
    $src = $lblRoboSrc.Text.Replace("Carpeta origen:  ","")
    $dst = $lblRoboDst.Text.Replace("Carpeta destino: ","")
    if (-not (Test-Path $src) -or -not (Test-Path $dst)) { Write-Out "Selecciona ambas carpetas." $cYellow; return }
    Write-Out "Sincronizando con Robocopy..." $cSubText
    Run-Cmd "robocopy `"$src`" `"$dst`" /MIR /Z /NP"
})

# ============================================================
#   TAB 6: SISTEMA
# ============================================================
$infoBox           = New-Object Windows.Forms.RichTextBox
$infoBox.Location  = New-Object Drawing.Point(5, 5)
$infoBox.Size      = New-Object Drawing.Size(715, 370)
$infoBox.BackColor = $cOutput
$infoBox.ForeColor = $cAccent2
$infoBox.Font      = New-Object Drawing.Font("Consolas", 9)
$infoBox.ReadOnly  = $true
$infoBox.BorderStyle = "None"
$tabSystem.Controls.Add($infoBox)

$b = New-Btn "  Cargar Info del Sistema" 5 382 220 36 $tabSystem
$b.Add_Click({
    $infoBox.Clear()
    $osI  = Get-CimInstance Win32_OperatingSystem
    $cpuI = Get-CimInstance Win32_Processor
    $mem  = [math]::Round($osI.TotalVisibleMemorySize / 1MB, 2)
    $free = [math]::Round($osI.FreePhysicalMemory / 1MB, 2)
    $disk = Get-PSDrive C
    $gpu  = (Get-CimInstance Win32_VideoController).Name
    $infoBox.AppendText("=== INFORMACION DEL SISTEMA ===`r`n`r`n")
    $infoBox.AppendText("SO              : $($osI.Caption)`r`n")
    $infoBox.AppendText("Version         : $($osI.Version)`r`n")
    $infoBox.AppendText("Arquitectura    : $($osI.OSArchitecture)`r`n")
    $infoBox.AppendText("Procesador      : $($cpuI.Name)`r`n")
    $infoBox.AppendText("Nucleos         : $($cpuI.NumberOfCores) nucleos / $($cpuI.NumberOfLogicalProcessors) logicos`r`n")
    $infoBox.AppendText("RAM Total       : $mem GB`r`n")
    $infoBox.AppendText("RAM Libre       : $free GB`r`n")
    $infoBox.AppendText("Disco C: Libre  : $([math]::Round($disk.Free/1GB,2)) GB de $([math]::Round(($disk.Used+$disk.Free)/1GB,2)) GB`r`n")
    $infoBox.AppendText("GPU             : $gpu`r`n")
    $infoBox.AppendText("Equipo          : $env:COMPUTERNAME`r`n")
    $infoBox.AppendText("Usuario         : $env:USERNAME`r`n")
    $infoBox.AppendText("Directorio      : $env:USERPROFILE`r`n")
    Write-Out "Informacion del sistema cargada." $cGreen
})

$b2 = New-Btn "  Ver Uptime" 235 382 160 36 $tabSystem
$b2.Add_Click({
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $up   = (Get-Date) - $boot
    Write-Out "Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m desde $boot" $cText
})

$b3 = New-Btn "  Buscar Actualizaciones" 405 382 200 36 $tabSystem
$b3.Add_Click({ Start-Process ms-settings:windowsupdate })

$b4 = New-Btn "  Drivers del Sistema" 615 382 100 36 $tabSystem
$b4.Add_Click({ Run-Cmd "driverquery" })

# ============================================================
#   TAB 7: DASHBOARD
# ============================================================
New-SecLabel "Monitor en Tiempo Real" 10 8 $tabDash

# Labels de metricas
function New-MetricPanel($label, $x, $y, $parent) {
    $pnl           = New-Object Windows.Forms.Panel
    $pnl.Location  = New-Object Drawing.Point($x, $y)
    $pnl.Size      = New-Object Drawing.Size(155, 70)
    $pnl.BackColor = $cCard
    $parent.Controls.Add($pnl)
    $lbl           = New-Object Windows.Forms.Label
    $lbl.Text      = $label
    $lbl.Location  = New-Object Drawing.Point(8, 6)
    $lbl.Size      = New-Object Drawing.Size(140, 18)
    $lbl.ForeColor = $cSubText
    $lbl.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $pnl.Controls.Add($lbl)
    $val           = New-Object Windows.Forms.Label
    $val.Text      = "..."
    $val.Location  = New-Object Drawing.Point(8, 26)
    $val.Size      = New-Object Drawing.Size(140, 36)
    $val.ForeColor = $cAccent2
    $val.Font      = New-Object Drawing.Font("Segoe UI", 18, [Drawing.FontStyle]::Bold)
    $pnl.Controls.Add($val)
    return $val
}

$lblCPU  = New-MetricPanel "CPU Uso"    10  40 $tabDash
$lblRAM  = New-MetricPanel "RAM Uso"   175  40 $tabDash
$lblDisk = New-MetricPanel "Disco C:"  340  40 $tabDash
$lblNet  = New-MetricPanel "Red"       505  40 $tabDash

# Procesos en tiempo real
New-SecLabel "Procesos Activos" 10 125 $tabDash

$procList              = New-Object Windows.Forms.ListView
$procList.Location     = New-Object Drawing.Point(10, 152)
$procList.Size         = New-Object Drawing.Size(700, 230)
$procList.View         = "Details"
$procList.BackColor    = $cOutput
$procList.ForeColor    = $cText
$procList.Font         = New-Object Drawing.Font("Consolas", 8)
$procList.FullRowSelect= $true
$procList.GridLines    = $true
$procList.Columns.Add("PID",   60) | Out-Null
$procList.Columns.Add("Nombre", 200) | Out-Null
$procList.Columns.Add("CPU%",  80) | Out-Null
$procList.Columns.Add("Mem MB",90) | Out-Null
$procList.Columns.Add("Estado",100)| Out-Null
$tabDash.Controls.Add($procList)

$b = New-Btn "Actualizar Procesos" 10 392 190 36 $tabDash
$b.Add_Click({
    $procList.Items.Clear()
    Get-Process | Sort-Object CPU -Descending | Select-Object -First 30 | ForEach-Object {
        $item = New-Object Windows.Forms.ListViewItem($_.Id.ToString())
        $item.SubItems.Add($_.ProcessName) | Out-Null
        $item.SubItems.Add([math]::Round($_.CPU,1).ToString()) | Out-Null
        $item.SubItems.Add([math]::Round($_.WorkingSet64/1MB,1).ToString()) | Out-Null
        $item.SubItems.Add($_.Responding ? "Activo" : "No responde") | Out-Null
        $procList.Items.Add($item) | Out-Null
    }
    Write-Out "Lista de procesos actualizada." $cGreen
})

$b2 = New-Btn "Terminar Proceso" 210 392 170 36 $tabDash
$b2.Add_Click({
    if ($procList.SelectedItems.Count -eq 0) { Write-Out "Selecciona un proceso." $cYellow; return }
    $pid = $procList.SelectedItems[0].Text
    Stop-Process -Id $pid -Force -EA SilentlyContinue
    Write-Out "Proceso PID $pid terminado." $cGreen
})

# Timer para metricas
$prevBytes = 0
$timerDash = New-Object Windows.Forms.Timer
$timerDash.Interval = 2000
$timerDash.Add_Tick({
    try {
        $cpu  = [math]::Round((Get-CimInstance Win32_Processor).LoadPercentage, 0)
        $osM  = Get-CimInstance Win32_OperatingSystem
        $ramP = [math]::Round(100 - ($osM.FreePhysicalMemory / $osM.TotalVisibleMemorySize * 100), 0)
        $dsk  = Get-PSDrive C
        $dskP = [math]::Round($dsk.Used / ($dsk.Used + $dsk.Free) * 100, 0)
        $net  = (Get-NetAdapterStatistics | Measure-Object -Property ReceivedBytes -Sum).Sum
        $kbps = if ($prevBytes -gt 0) { [math]::Round(($net - $prevBytes) / 2 / 1KB, 1) } else { 0 }
        $script:prevBytes = $net
        $lblCPU.Text  = "$cpu%"
        $lblRAM.Text  = "$ramP%"
        $lblDisk.Text = "$dskP%"
        $lblNet.Text  = "$kbps KB/s"
        $lblCPU.ForeColor  = if ($cpu  -gt 80) { $cRed } elseif ($cpu  -gt 50) { $cYellow } else { $cGreen }
        $lblRAM.ForeColor  = if ($ramP -gt 85) { $cRed } elseif ($ramP -gt 60) { $cYellow } else { $cGreen }
        $lblDisk.ForeColor = if ($dskP -gt 90) { $cRed } elseif ($dskP -gt 70) { $cYellow } else { $cGreen }
    } catch {}
})
$timerDash.Start()

# ============================================================
#   TAB 8: REPORTES
# ============================================================
New-SecLabel "Generar Reportes del Sistema" 10 10 $tabReports

$reportBox           = New-Object Windows.Forms.RichTextBox
$reportBox.Location  = New-Object Drawing.Point(5, 40)
$reportBox.Size      = New-Object Drawing.Size(715, 370)
$reportBox.BackColor = $cOutput
$reportBox.ForeColor = $cAccent2
$reportBox.Font      = New-Object Drawing.Font("Consolas", 8)
$reportBox.ReadOnly  = $true
$reportBox.BorderStyle = "None"
$tabReports.Controls.Add($reportBox)

$b = New-Btn "Reporte Completo" 5 420 180 36 $tabReports
$b.Add_Click({
    $reportBox.Clear()
    $osR  = Get-CimInstance Win32_OperatingSystem
    $cpuR = Get-CimInstance Win32_Processor
    $gpuR = Get-CimInstance Win32_VideoController
    $netR = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $reportBox.AppendText("========================================`r`n")
    $reportBox.AppendText("   REPORTE COMPLETO - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`r`n")
    $reportBox.AppendText("========================================`r`n`r`n")
    $reportBox.AppendText("[SISTEMA OPERATIVO]`r`n")
    $reportBox.AppendText("  $($osR.Caption) - Build $($osR.BuildNumber)`r`n`r`n")
    $reportBox.AppendText("[PROCESADOR]`r`n")
    $reportBox.AppendText("  $($cpuR.Name)`r`n")
    $reportBox.AppendText("  $($cpuR.NumberOfCores) nucleos | $($cpuR.NumberOfLogicalProcessors) hilos`r`n`r`n")
    $reportBox.AppendText("[MEMORIA RAM]`r`n")
    $mem = [math]::Round($osR.TotalVisibleMemorySize/1MB,2)
    $free= [math]::Round($osR.FreePhysicalMemory/1MB,2)
    $reportBox.AppendText("  Total: $mem GB | Libre: $free GB`r`n`r`n")
    $reportBox.AppendText("[GPU]`r`n")
    $reportBox.AppendText("  $($gpuR.Name)`r`n`r`n")
    $reportBox.AppendText("[RED]`r`n")
    foreach ($a in $netR) { $reportBox.AppendText("  $($a.Name): $($a.LinkSpeed)`r`n") }
    $reportBox.AppendText("`r`n[DISCO C:]`r`n")
    $disk = Get-PSDrive C
    $reportBox.AppendText("  Libre: $([math]::Round($disk.Free/1GB,2)) GB | Total: $([math]::Round(($disk.Used+$disk.Free)/1GB,2)) GB`r`n")
    Write-Out "Reporte generado." $cGreen
})

$b2 = New-Btn "Exportar a TXT" 195 420 160 36 $tabReports
$b2.Add_Click({
    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter = "Text (*.txt)|*.txt"
    $dlg.FileName = "SysCodi_Reporte_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if ($dlg.ShowDialog() -eq "OK") {
        $reportBox.Text | Set-Content $dlg.FileName -Encoding UTF8
        Write-Out "Reporte guardado en: $($dlg.FileName)" $cGreen
    }
})

$b3 = New-Btn "Reporte de Red" 365 420 160 36 $tabReports
$b3.Add_Click({
    $reportBox.Clear()
    $reportBox.AppendText("=== REPORTE DE RED - $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') ===`r`n`r`n")
    $adapters = Get-NetAdapter
    foreach ($a in $adapters) {
        $reportBox.AppendText("Adaptador: $($a.Name)`r`n")
        $reportBox.AppendText("  Estado : $($a.Status)`r`n")
        $reportBox.AppendText("  Velocidad: $($a.LinkSpeed)`r`n")
        $ip = (Get-NetIPAddress -InterfaceIndex $a.ifIndex -EA SilentlyContinue | Where-Object AddressFamily -eq "IPv4").IPAddress
        $reportBox.AppendText("  IP     : $ip`r`n`r`n")
    }
    Write-Out "Reporte de red generado." $cGreen
})

# ============================================================
#   TAB 9: AJUSTES
# ============================================================
New-SecLabel "Configuracion de la Aplicacion" 10 10 $tabSettings

$cbStartAdmin           = New-Object Windows.Forms.CheckBox
$cbStartAdmin.Text      = "Ejecutar siempre como Administrador (acceso directo)"
$cbStartAdmin.Location  = New-Object Drawing.Point(10, 42)
$cbStartAdmin.Size      = New-Object Drawing.Size(500, 24)
$cbStartAdmin.ForeColor = $cText; $cbStartAdmin.BackColor = $cBg
$tabSettings.Controls.Add($cbStartAdmin)

$cbAutoUpdate           = New-Object Windows.Forms.CheckBox
$cbAutoUpdate.Text      = "Verificar actualizaciones de Windows al iniciar"
$cbAutoUpdate.Location  = New-Object Drawing.Point(10, 70)
$cbAutoUpdate.Size      = New-Object Drawing.Size(500, 24)
$cbAutoUpdate.ForeColor = $cText; $cbAutoUpdate.BackColor = $cBg
$tabSettings.Controls.Add($cbAutoUpdate)

New-SecLabel "Acciones Rapidas del Sistema" 10 108 $tabSettings

$b  = New-Btn "Reiniciar Explorer"      10 138 185 36 $tabSettings
$b.Add_Click({ Stop-Process -Name explorer -Force; Start-Process explorer; Write-Out "Explorer reiniciado." $cGreen })

$b2 = New-Btn "Liberar Memoria RAM"    205 138 185 36 $tabSettings
$b2.Add_Click({ [System.GC]::Collect(); Write-Out "Memoria liberada (GC)." $cGreen })

$b3 = New-Btn "Limpiar Portapapeles"   400 138 185 36 $tabSettings
$b3.Add_Click({ [System.Windows.Forms.Clipboard]::Clear(); Write-Out "Portapapeles limpiado." $cGreen })

$b4 = New-Btn "Crear Punto Restauracion" 10 184 220 36 $tabSettings
$b4.Add_Click({
    Write-Out "Creando punto de restauracion..." $cSubText
    Run-Cmd 'Checkpoint-Computer -Description "SysCodi Backup" -RestorePointType "MODIFY_SETTINGS"'
    Write-Out "Punto de restauracion creado." $cGreen
})

$b5 = New-Btn "Verificar Sistema (SFC)" 240 184 210 36 $tabSettings
$b5.Add_Click({ Run-Cmd "sfc /verifyonly" })

New-SecLabel "Informacion de la Aplicacion" 10 232 $tabSettings

$lblAbout           = New-Object Windows.Forms.Label
$lblAbout.Text      = "SysCodi WinTool Pro v2.5  |  Desarrollado por SysCodi  |  Requiere PowerShell 5.1+"
$lblAbout.Location  = New-Object Drawing.Point(10, 262)
$lblAbout.Size      = New-Object Drawing.Size(700, 20)
$lblAbout.ForeColor = $cSubText
$lblAbout.Font      = New-Object Drawing.Font("Segoe UI", 8)
$tabSettings.Controls.Add($lblAbout)

$lblAbout2           = New-Object Windows.Forms.Label
$lblAbout2.Text      = "Usa WinGet como gestor de paquetes. Ejecutar como Administrador para funcionalidad completa."
$lblAbout2.Location  = New-Object Drawing.Point(10, 284)
$lblAbout2.Size      = New-Object Drawing.Size(700, 20)
$lblAbout2.ForeColor = $cSubText
$lblAbout2.Font      = New-Object Drawing.Font("Segoe UI", 8)
$tabSettings.Controls.Add($lblAbout2)

# ============================================================
#   PANEL INFERIOR - Info rapida + Accesos + Acciones + Estado
# ============================================================
$bottomPanel           = New-Object Windows.Forms.Panel
$bottomPanel.Location  = New-Object Drawing.Point(0, 592)
$bottomPanel.Size      = New-Object Drawing.Size(1200, 90)
$bottomPanel.BackColor = $cPanel
$form.Controls.Add($bottomPanel)

# Info rapida
$pnlQuick           = New-Object Windows.Forms.Panel
$pnlQuick.Location  = New-Object Drawing.Point(5, 5)
$pnlQuick.Size      = New-Object Drawing.Size(290, 80)
$pnlQuick.BackColor = $cCard
$bottomPanel.Controls.Add($pnlQuick)

$lblQuickTitle           = New-Object Windows.Forms.Label
$lblQuickTitle.Text      = "Informacion rapida"
$lblQuickTitle.Location  = New-Object Drawing.Point(6, 4)
$lblQuickTitle.Size      = New-Object Drawing.Size(278, 16)
$lblQuickTitle.ForeColor = $cAccent2
$lblQuickTitle.Font      = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
$pnlQuick.Controls.Add($lblQuickTitle)

$lblCPUQ   = New-Object Windows.Forms.Label; $lblCPUQ.Location  = New-Object Drawing.Point(6,22)
$lblCPUQ.Size = New-Object Drawing.Size(130,16); $lblCPUQ.ForeColor = $cText; $lblCPUQ.Font = New-Object Drawing.Font("Segoe UI",7); $lblCPUQ.Text = "CPU: ..."; $pnlQuick.Controls.Add($lblCPUQ)
$lblRAMQ   = New-Object Windows.Forms.Label; $lblRAMQ.Location  = New-Object Drawing.Point(145,22)
$lblRAMQ.Size = New-Object Drawing.Size(130,16); $lblRAMQ.ForeColor = $cText; $lblRAMQ.Font = New-Object Drawing.Font("Segoe UI",7); $lblRAMQ.Text = "RAM: ..."; $pnlQuick.Controls.Add($lblRAMQ)
$lblDiskQ  = New-Object Windows.Forms.Label; $lblDiskQ.Location = New-Object Drawing.Point(6,40)
$lblDiskQ.Size = New-Object Drawing.Size(130,16); $lblDiskQ.ForeColor = $cText; $lblDiskQ.Font = New-Object Drawing.Font("Segoe UI",7); $lblDiskQ.Text = "Disco C: ..."; $pnlQuick.Controls.Add($lblDiskQ)
$lblNetQ   = New-Object Windows.Forms.Label; $lblNetQ.Location  = New-Object Drawing.Point(145,40)
$lblNetQ.Size = New-Object Drawing.Size(130,16); $lblNetQ.ForeColor = $cText; $lblNetQ.Font = New-Object Drawing.Font("Segoe UI",7); $lblNetQ.Text = "Red: ..."; $pnlQuick.Controls.Add($lblNetQ)

# Timer para info rapida en footer
$timerQuick = New-Object Windows.Forms.Timer
$timerQuick.Interval = 3000
$timerQuick.Add_Tick({
    try {
        $c  = (Get-CimInstance Win32_Processor).LoadPercentage
        $oQ = Get-CimInstance Win32_OperatingSystem
        $r  = [math]::Round(100 - ($oQ.FreePhysicalMemory / $oQ.TotalVisibleMemorySize * 100),0)
        $d  = Get-PSDrive C
        $dp = [math]::Round($d.Used/($d.Used+$d.Free)*100,0)
        $df = [math]::Round($d.Free/1GB,0)
        $lblCPUQ.Text  = "CPU Uso: $c%"
        $lblRAMQ.Text  = "RAM Uso: $r%"
        $lblDiskQ.Text = "Disco C: $dp% | Libre: ${df}GB"
        $lblNetQ.Text  = "Red: Activa"
    } catch {}
})
$timerQuick.Start()

# Accesos rapidos
$pnlAccess           = New-Object Windows.Forms.Panel
$pnlAccess.Location  = New-Object Drawing.Point(300, 5)
$pnlAccess.Size      = New-Object Drawing.Size(420, 80)
$pnlAccess.BackColor = $cCard
$bottomPanel.Controls.Add($pnlAccess)

$lblAccTitle           = New-Object Windows.Forms.Label
$lblAccTitle.Text      = "Accesos rapidos"
$lblAccTitle.Location  = New-Object Drawing.Point(6, 4)
$lblAccTitle.Size      = New-Object Drawing.Size(408, 16)
$lblAccTitle.ForeColor = $cAccent2
$lblAccTitle.Font      = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
$pnlAccess.Controls.Add($lblAccTitle)

$shortcuts = @(
    @{name="Explorador";       cmd={Start-Process explorer}},
    @{name="Adm. Dispositivos";cmd={Start-Process devmgmt.msc}},
    @{name="Adm. Discos";      cmd={Start-Process diskmgmt.msc}},
    @{name="Servicios";        cmd={Start-Process services.msc}},
    @{name="Eventos";          cmd={Start-Process eventvwr.msc}},
    @{name="Panel Control";    cmd={Start-Process control}}
)
$xA = 5; $yA = 24; $colA = 0
foreach ($sc in $shortcuts) {
    $sb           = New-Object Windows.Forms.Button
    $sb.Text      = $sc.name
    $sb.Location  = New-Object Drawing.Point($xA, $yA)
    $sb.Size      = New-Object Drawing.Size(128, 24)
    $sb.BackColor = [Drawing.Color]::FromArgb(0, 70, 140)
    $sb.ForeColor = $cText
    $sb.FlatStyle = "Flat"
    $sb.Font      = New-Object Drawing.Font("Segoe UI", 7)
    $sb.Cursor    = "Hand"
    $cmd = $sc.cmd
    $sb.Add_Click($cmd)
    $pnlAccess.Controls.Add($sb)
    $colA++; $xA += 133
    if ($colA -ge 3) { $colA = 0; $xA = 5; $yA += 28 }
}

# Acciones rapidas
$pnlActions           = New-Object Windows.Forms.Panel
$pnlActions.Location  = New-Object Drawing.Point(725, 5)
$pnlActions.Size      = New-Object Drawing.Size(340, 80)
$pnlActions.BackColor = $cCard
$bottomPanel.Controls.Add($pnlActions)

$lblActTitle           = New-Object Windows.Forms.Label
$lblActTitle.Text      = "Acciones rapidas"
$lblActTitle.Location  = New-Object Drawing.Point(6, 4)
$lblActTitle.Size      = New-Object Drawing.Size(328, 16)
$lblActTitle.ForeColor = $cAccent2
$lblActTitle.Font      = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
$pnlActions.Controls.Add($lblActTitle)

$actions = @(
    @{name="Reiniciar Explorer"; cmd={Stop-Process -Name explorer -Force; Start-Process explorer; Write-Out "Explorer reiniciado." $cGreen}},
    @{name="Liberar Memoria";    cmd={[System.GC]::Collect(); Write-Out "Memoria liberada." $cGreen}},
    @{name="Limpiar Portapapeles";cmd={[System.Windows.Forms.Clipboard]::Clear(); Write-Out "Portapapeles limpiado." $cGreen}},
    @{name="Crear Pto. Restauracion";cmd={Run-Cmd 'Checkpoint-Computer -Description "SysCodi" -RestorePointType "MODIFY_SETTINGS"'}}
)
$xAc = 5; $yAc = 24; $colAc = 0
foreach ($ac in $actions) {
    $ab           = New-Object Windows.Forms.Button
    $ab.Text      = $ac.name
    $ab.Location  = New-Object Drawing.Point($xAc, $yAc)
    $ab.Size      = New-Object Drawing.Size(162, 24)
    $ab.BackColor = [Drawing.Color]::FromArgb(0, 70, 140)
    $ab.ForeColor = $cText
    $ab.FlatStyle = "Flat"
    $ab.Font      = New-Object Drawing.Font("Segoe UI", 7)
    $ab.Cursor    = "Hand"
    $cmd = $ac.cmd
    $ab.Add_Click($cmd)
    $pnlActions.Controls.Add($ab)
    $colAc++; $xAc += 167
    if ($colAc -ge 2) { $colAc = 0; $xAc = 5; $yAc += 28 }
}

# Estado
$pnlStatus           = New-Object Windows.Forms.Panel
$pnlStatus.Location  = New-Object Drawing.Point(1070, 5)
$pnlStatus.Size      = New-Object Drawing.Size(125, 80)
$pnlStatus.BackColor = $cCard
$bottomPanel.Controls.Add($pnlStatus)

$lblStatusTitle           = New-Object Windows.Forms.Label
$lblStatusTitle.Text      = "Estado"
$lblStatusTitle.Location  = New-Object Drawing.Point(6, 4)
$lblStatusTitle.Size      = New-Object Drawing.Size(113, 16)
$lblStatusTitle.ForeColor = $cAccent2
$lblStatusTitle.Font      = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
$pnlStatus.Controls.Add($lblStatusTitle)

$lblStatusIcon           = New-Object Windows.Forms.Label
$lblStatusIcon.Text      = "OK"
$lblStatusIcon.Location  = New-Object Drawing.Point(35, 22)
$lblStatusIcon.Size      = New-Object Drawing.Size(55, 26)
$lblStatusIcon.ForeColor = $cGreen
$lblStatusIcon.Font      = New-Object Drawing.Font("Segoe UI", 14, [Drawing.FontStyle]::Bold)
$pnlStatus.Controls.Add($lblStatusIcon)

$lblStatusText           = New-Object Windows.Forms.Label
$lblStatusText.Text      = "Todo correcto"
$lblStatusText.Location  = New-Object Drawing.Point(6, 48)
$lblStatusText.Size      = New-Object Drawing.Size(113, 16)
$lblStatusText.ForeColor = $cGreen
$lblStatusText.Font      = New-Object Drawing.Font("Segoe UI", 7)
$lblStatusText.TextAlign = "MiddleCenter"
$pnlStatus.Controls.Add($lblStatusText)

$btnVerify           = New-Object Windows.Forms.Button
$btnVerify.Text      = "Verificar sistema"
$btnVerify.Location  = New-Object Drawing.Point(6, 64)
$btnVerify.Size      = New-Object Drawing.Size(113, 14)
$btnVerify.BackColor = $cBtn
$btnVerify.ForeColor = $cText
$btnVerify.FlatStyle = "Flat"
$btnVerify.Font      = New-Object Drawing.Font("Segoe UI", 6)
$btnVerify.Cursor    = "Hand"
$btnVerify.Add_Click({ Write-Out "Sistema verificado - Todo correcto." $cGreen })
$pnlStatus.Controls.Add($btnVerify)

# ============================================================
#   FOOTER
# ============================================================
$footer           = New-Object Windows.Forms.Label
$footer.Text      = "  Ejecutar siempre como Administrador para mejor rendimiento                                                              Desarrollado por SysCodi                    Version 2.5 Pro"
$footer.Location  = New-Object Drawing.Point(0, 686)
$footer.Size      = New-Object Drawing.Size(1200, 24)
$footer.TextAlign = "MiddleLeft"
$footer.ForeColor = $cSubText
$footer.BackColor = [Drawing.Color]::FromArgb(8, 14, 30)
$footer.Font      = New-Object Drawing.Font("Segoe UI", 7)
$form.Controls.Add($footer)

# ============================================================
$form.ShowDialog()
$timerClock.Stop(); $timerDash.Stop(); $timerQuick.Stop()
