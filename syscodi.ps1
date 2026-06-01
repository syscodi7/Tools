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
#   SISTEMA DE LOGS
# ============================================================
$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($msg) {
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] $msg"
    Add-Content -Path $logFile -Value $entry -Encoding UTF8 -EA SilentlyContinue
}

# ============================================================
#   LOGO
# ============================================================
$logoUrl  = "https://raw.githubusercontent.com/syscodi7/Tools/main/sis.png"
$logoPath = "$env:TEMP\syscodi_logo.png"
try { Invoke-WebRequest -Uri $logoUrl -OutFile $logoPath -EA Stop } catch { $logoPath = "" }

# ============================================================
#   COLORES CORPORATIVOS
# ============================================================
$cBg      = [Drawing.Color]::FromArgb(13, 22, 45)
$cPanel   = [Drawing.Color]::FromArgb(20, 35, 70)
$cCard    = [Drawing.Color]::FromArgb(28, 48, 96)
$cAccent  = [Drawing.Color]::FromArgb(0, 120, 215)
$cAccent2 = [Drawing.Color]::FromArgb(0, 180, 255)
$cGreen   = [Drawing.Color]::FromArgb(0, 210, 130)
$cYellow  = [Drawing.Color]::FromArgb(255, 200, 50)
$cRed     = [Drawing.Color]::FromArgb(255, 80, 80)
$cText    = [Drawing.Color]::White
$cSubText = [Drawing.Color]::FromArgb(160, 200, 255)
$cBtn     = [Drawing.Color]::FromArgb(0, 100, 180)
$cOutput  = [Drawing.Color]::FromArgb(8, 15, 35)
$cBorder  = [Drawing.Color]::FromArgb(0, 100, 180)

# ============================================================
#   FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text          = "SysCodi WinTool Pro v2.0"
$form.Size          = New-Object Drawing.Size(1280, 760)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBg
$form.ForeColor     = $cText
$form.Font          = New-Object Drawing.Font("Segoe UI", 9)
$form.FormBorderStyle = "Sizable"
$form.MinimumSize   = New-Object Drawing.Size(1100, 680)

# ============================================================
#   HEADER
# ============================================================
$header = New-Object Windows.Forms.Panel
$header.Size      = New-Object Drawing.Size(1280, 64)
$header.Location  = New-Object Drawing.Point(0, 0)
$header.BackColor = $cPanel
$form.Controls.Add($header)
$header.BringToFront()

if (Test-Path $logoPath) {
    $logoPic = New-Object Windows.Forms.PictureBox
    $logoPic.Location = New-Object Drawing.Point(12, 7)
    $logoPic.Size     = New-Object Drawing.Size(50, 50)
    $logoPic.SizeMode = "Zoom"
    $logoPic.BackColor = $cPanel
    $logoPic.Image    = [Drawing.Image]::FromFile($logoPath)
    $header.Controls.Add($logoPic)
    try { $bmp = [Drawing.Bitmap][Drawing.Image]::FromFile($logoPath); $form.Icon = [Drawing.Icon]::FromHandle($bmp.GetHicon()) } catch {}
    $titleX = 72
} else { $titleX = 15 }

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text     = "SysCodi WinTool Pro"
$lblTitle.Font     = New-Object Drawing.Font("Segoe UI", 15, [Drawing.FontStyle]::Bold)
$lblTitle.ForeColor = $cAccent2
$lblTitle.Location = New-Object Drawing.Point($titleX, 8)
$lblTitle.Size     = New-Object Drawing.Size(420, 32)
$header.Controls.Add($lblTitle)

$lblSub = New-Object Windows.Forms.Label
$lblSub.Text      = "Utilidad avanzada de mantenimiento y optimizacion para Windows  |  v2.0 Pro"
$lblSub.Font      = New-Object Drawing.Font("Segoe UI", 8)
$lblSub.ForeColor = $cSubText
$lblSub.Location  = New-Object Drawing.Point($titleX, 42)
$lblSub.Size      = New-Object Drawing.Size(500, 16)
$header.Controls.Add($lblSub)

# Indicador Admin
$lblAdmin = New-Object Windows.Forms.Label
$lblAdmin.Text      = "  ADMIN  "
$lblAdmin.Font      = New-Object Drawing.Font("Segoe UI", 8, [Drawing.FontStyle]::Bold)
$lblAdmin.ForeColor = $cGreen
$lblAdmin.BackColor = [Drawing.Color]::FromArgb(0, 50, 20)
$lblAdmin.Location  = New-Object Drawing.Point(1130, 22)
$lblAdmin.Size      = New-Object Drawing.Size(70, 22)
$lblAdmin.TextAlign = "MiddleCenter"
$lblAdmin.BorderStyle = "FixedSingle"
$header.Controls.Add($lblAdmin)

# Hora en header
$lblClock = New-Object Windows.Forms.Label
$lblClock.Font      = New-Object Drawing.Font("Consolas", 9)
$lblClock.ForeColor = $cSubText
$lblClock.Location  = New-Object Drawing.Point(1050, 22)
$lblClock.Size      = New-Object Drawing.Size(75, 22)
$lblClock.TextAlign = "MiddleCenter"
$header.Controls.Add($lblClock)

$clockTimer = New-Object Windows.Forms.Timer
$clockTimer.Interval = 1000
$clockTimer.Add_Tick({ $lblClock.Text = Get-Date -Format "HH:mm:ss" })
$clockTimer.Start()

# ============================================================
#   BARRA DE PROGRESO GLOBAL
# ============================================================
$progressBar = New-Object Windows.Forms.ProgressBar
$progressBar.Location = New-Object Drawing.Point(0, 64)
$progressBar.Size     = New-Object Drawing.Size(1280, 5)
$progressBar.Style    = "Marquee"
$progressBar.MarqueeAnimationSpeed = 0
$progressBar.BackColor = $cPanel
$progressBar.ForeColor = $cAccent2
$form.Controls.Add($progressBar)

function Start-Progress { $progressBar.MarqueeAnimationSpeed = 30; $form.Refresh() }
function Stop-Progress  { $progressBar.MarqueeAnimationSpeed = 0;  $progressBar.Value = 0 }

# ============================================================
#   TAB CONTROL
# ============================================================
$tabs = New-Object Windows.Forms.TabControl
$tabs.Location   = New-Object Drawing.Point(5, 73)
$tabs.Size       = New-Object Drawing.Size(790, 635)
$tabs.BackColor  = $cBg
$tabs.Appearance = "FlatButtons"
$tabs.Font       = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$tabs.Anchor     = "Top,Left,Bottom,Right"
$form.Controls.Add($tabs)

function New-Tab($titulo) {
    $t = New-Object Windows.Forms.TabPage
    $t.Text      = "  $titulo  "
    $t.BackColor = $cBg
    $t.ForeColor = $cText
    $tabs.TabPages.Add($t)
    return $t
}

$tabRepair = New-Tab "Reparacion"
$tabApps   = New-Tab "Aplicaciones"
$tabTweaks = New-Tab "Tweaks"
$tabUtils  = New-Tab "Utilidades"
$tabInfo   = New-Tab "Sistema"

# ============================================================
#   PANEL DERECHO - CONSOLA
# ============================================================
$rightPanel = New-Object Windows.Forms.Panel
$rightPanel.Location  = New-Object Drawing.Point(798, 73)
$rightPanel.Size      = New-Object Drawing.Size(474, 635)
$rightPanel.BackColor = $cOutput
$rightPanel.Anchor    = "Top,Right,Bottom"
$form.Controls.Add($rightPanel)

$pnlConHeader = New-Object Windows.Forms.Panel
$pnlConHeader.Location  = New-Object Drawing.Point(0, 0)
$pnlConHeader.Size      = New-Object Drawing.Size(474, 32)
$pnlConHeader.BackColor = $cPanel
$rightPanel.Controls.Add($pnlConHeader)

$lblConsole = New-Object Windows.Forms.Label
$lblConsole.Text      = "  Consola de Salida"
$lblConsole.Location  = New-Object Drawing.Point(0, 0)
$lblConsole.Size      = New-Object Drawing.Size(320, 32)
$lblConsole.ForeColor = $cAccent2
$lblConsole.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$lblConsole.TextAlign = "MiddleLeft"
$pnlConHeader.Controls.Add($lblConsole)

$btnClearOutput = New-Object Windows.Forms.Button
$btnClearOutput.Text      = "Limpiar"
$btnClearOutput.Location  = New-Object Drawing.Point(320, 5)
$btnClearOutput.Size      = New-Object Drawing.Size(70, 22)
$btnClearOutput.BackColor = [Drawing.Color]::FromArgb(0, 70, 130)
$btnClearOutput.ForeColor = $cText
$btnClearOutput.FlatStyle = "Flat"
$btnClearOutput.Font      = New-Object Drawing.Font("Segoe UI", 7)
$btnClearOutput.Add_Click({ $outputBox.Clear(); Write-Out "Consola limpiada." $cSubText })
$pnlConHeader.Controls.Add($btnClearOutput)

$btnSaveLog = New-Object Windows.Forms.Button
$btnSaveLog.Text      = "Guardar"
$btnSaveLog.Location  = New-Object Drawing.Point(394, 5)
$btnSaveLog.Size      = New-Object Drawing.Size(70, 22)
$btnSaveLog.BackColor = [Drawing.Color]::FromArgb(0, 70, 130)
$btnSaveLog.ForeColor = $cText
$btnSaveLog.FlatStyle = "Flat"
$btnSaveLog.Font      = New-Object Drawing.Font("Segoe UI", 7)
$btnSaveLog.Add_Click({
    $dlg = New-Object Windows.Forms.SaveFileDialog
    $dlg.Filter   = "Text files (*.txt)|*.txt"
    $dlg.FileName = "SysCodi_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if ($dlg.ShowDialog() -eq "OK") {
        $outputBox.Text | Set-Content $dlg.FileName -Encoding UTF8
        Write-Out "Log guardado: $($dlg.FileName)" $cGreen
    }
})
$pnlConHeader.Controls.Add($btnSaveLog)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location    = New-Object Drawing.Point(0, 32)
$outputBox.Size        = New-Object Drawing.Size(474, 603)
$outputBox.BackColor   = $cOutput
$outputBox.ForeColor   = $cAccent2
$outputBox.Font        = New-Object Drawing.Font("Consolas", 8.5)
$outputBox.ReadOnly    = $true
$outputBox.BorderStyle = "None"
$outputBox.ScrollBars  = "Vertical"
$rightPanel.Controls.Add($outputBox)

function Write-Out($msg, $color = $null) {
    if ($outputBox.InvokeRequired) {
        $outputBox.Invoke([Action]{
            param($m,$c) 
            $outputBox.SelectionStart = $outputBox.TextLength
            $outputBox.SelectionColor = if($c){$c}else{$cAccent2}
            $outputBox.AppendText("`r`n $m")
            $outputBox.ScrollToCaret()
        }, $msg, $color)
    } else {
        $outputBox.SelectionStart = $outputBox.TextLength
        $outputBox.SelectionColor = if ($color) { $color } else { $cAccent2 }
        $outputBox.AppendText("`r`n $msg")
        $outputBox.ScrollToCaret()
    }
    Write-Log $msg
}

function Write-Section($titulo) {
    Write-Out ""
    Write-Out "━━━ $titulo ━━━" $cAccent2
}

function Run-Cmd-BG($cmd, $label) {
    Write-Out "Ejecutando: $label..." $cSubText
    Start-Progress
    $job = Start-Job -ScriptBlock { param($c) Invoke-Expression $c 2>&1 } -ArgumentList $cmd
    $timer2 = New-Object Windows.Forms.Timer
    $timer2.Interval = 500
    $timer2.Add_Tick({
        if ($job.State -ne "Running") {
            $timer2.Stop()
            Stop-Progress
            $res = Receive-Job $job
            Remove-Job $job -Force
            if ($res) {
                $outputBox.SelectionStart = $outputBox.TextLength
                $outputBox.SelectionColor = $cText
                $outputBox.AppendText("`r`n" + ($res -join "`r`n "))
                $outputBox.ScrollToCaret()
            }
            Write-Out "Completado: $label" $cGreen
        }
    })
    $timer2.Start()
}

# ============================================================
#   HELPERS UI
# ============================================================
function New-CorporateButton($texto, $x, $y, $w = 195, $h = 34) {
    $b = New-Object Windows.Forms.Button
    $b.Text      = $texto
    $b.Location  = New-Object Drawing.Point($x, $y)
    $b.Size      = New-Object Drawing.Size($w, $h)
    $b.BackColor = $cBtn
    $b.ForeColor = $cText
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $cAccent
    $b.FlatAppearance.BorderSize  = 1
    $b.Font      = New-Object Drawing.Font("Segoe UI", 8.5)
    $b.Cursor    = "Hand"
    $b.Add_MouseEnter({ $this.BackColor = [Drawing.Color]::FromArgb(0, 140, 220) })
    $b.Add_MouseLeave({ $this.BackColor = $cBtn })
    return $b
}

function New-SectionLabel($texto, $x, $y, $parent) {
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text      = "  $texto"
    $lbl.Location  = New-Object Drawing.Point($x, $y)
    $lbl.Size      = New-Object Drawing.Size(760, 24)
    $lbl.ForeColor = $cAccent2
    $lbl.BackColor = [Drawing.Color]::FromArgb(20, 40, 80)
    $lbl.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
    $lbl.TextAlign = "MiddleLeft"
    $parent.Controls.Add($lbl)
    return $lbl
}

function New-ScrollPanel($parent) {
    $p = New-Object Windows.Forms.Panel
    $p.Location    = New-Object Drawing.Point(0, 0)
    $p.Size        = New-Object Drawing.Size(782, 625)
    $p.AutoScroll  = $true
    $p.BackColor   = $cBg
    $parent.Controls.Add($p)
    return $p
}

# ============================================================
#   TAB 1: REPARACION COMPLETA
# ============================================================
$scrollRepair = New-ScrollPanel $tabRepair
$yR = 5

function Add-RepairSection($titulo) {
    New-SectionLabel $titulo 5 $yR $scrollRepair | Out-Null
    $script:yR += 28
}

function Add-RepairBtn($texto, $cmd, $col = 0) {
    $x = 8 + $col * 200
    $btn = New-CorporateButton $texto $x $yR 192 32
    $btnCmd = $cmd
    $btnLabel = $texto
    $btn.Add_Click({ Run-Cmd-BG $btnCmd $btnLabel })
    $scrollRepair.Controls.Add($btn)
    if ($col -ge 3) { $script:yR += 36 }
}

# === LIMPIEZA ===
Add-RepairSection "Limpieza del Sistema"
Add-RepairBtn "Limpiar Temporales" 'Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue; Remove-Item "C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue; Write-Output "Temporales eliminados"' 0
Add-RepairBtn "Limpiar Prefetch" 'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue; Write-Output "Prefetch limpiado"' 1
Add-RepairBtn "Vaciar Papelera" 'Clear-RecycleBin -Force -EA SilentlyContinue; Write-Output "Papelera vaciada"' 2
Add-RepairBtn "Limpiar DNS Cache" 'ipconfig /flushdns' 3
$yR += 36
Add-RepairBtn "Limpiar Minidumps" 'Remove-Item "C:\Windows\Minidump\*" -Force -EA SilentlyContinue; Write-Output "Minidumps eliminados"' 0
Add-RepairBtn "Limpiar Log de Eventos" 'Get-EventLog -LogName * | ForEach-Object { Clear-EventLog $_.Log -EA SilentlyContinue }; Write-Output "Logs de eventos limpiados"' 1
Add-RepairBtn "Limpiar WinSxS (DISM)" 'DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase' 2
Add-RepairBtn "Purgar Punto Restauracion" 'vssadmin delete shadows /all /quiet; Write-Output "Puntos de restauracion eliminados"' 3
$yR += 36

# === REPARACION WINDOWS ===
Add-RepairSection "Reparacion de Archivos del Sistema"
Add-RepairBtn "SFC /scannow" 'sfc /scannow' 0
Add-RepairBtn "DISM RestoreHealth" 'DISM /Online /Cleanup-Image /RestoreHealth' 1
Add-RepairBtn "DISM ScanHealth" 'DISM /Online /Cleanup-Image /ScanHealth' 2
Add-RepairBtn "DISM CheckHealth" 'DISM /Online /Cleanup-Image /CheckHealth' 3
$yR += 36
Add-RepairBtn "Reparar Boot (bootrec)" 'bootrec /fixmbr; bootrec /fixboot; bootrec /rebuildbcd' 0
Add-RepairBtn "Reparar Tienda Windows" 'wsreset.exe; Write-Output "Tienda reparada"' 1
Add-RepairBtn "Registrar DLLs sistema" 'for /f %i in (''dir /b C:\Windows\system32\*.dll'') do regsvr32 /s %i' 2
Add-RepairBtn "Reiniciar Windows Update" 'Stop-Service wuauserv,bits,cryptsvc -Force -EA SilentlyContinue; Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv,bits,cryptsvc -EA SilentlyContinue; Write-Output "Windows Update reiniciado"' 3
$yR += 36

# === DISCO ===
Add-RepairSection "Disco y Almacenamiento"
$btnChk = New-CorporateButton "CheckDisk C: (reinicio)" 8 $yR 192 32
$btnChk.Add_Click({
    $r = [Windows.Forms.MessageBox]::Show("ChkDsk requiere reinicio para disco activo.`nSe programara para el proximo reinicio.", "ChkDsk", "YesNo", "Question")
    if ($r -eq "Yes") {
        Run-Cmd-BG 'echo Y | chkdsk C: /f /r' "ChkDsk C:"
        Write-Out "ChkDsk programado. Reinicia para ejecutar." $cYellow
    }
})
$scrollRepair.Controls.Add($btnChk)
Add-RepairBtn "Desfragmentar C:" 'defrag C: /U /V' 1
Add-RepairBtn "Optimizar SSD (TRIM)" 'defrag C: /L' 2
Add-RepairBtn "Ver estado SMART" 'wmic diskdrive get status,model,size' 3
$yR += 36
Add-RepairBtn "Limpiar espacio WinRE" 'reagentc /info' 0
Add-RepairBtn "Disco Info detallada" 'Get-PSDrive | Format-Table -AutoSize' 1
Add-RepairBtn "Ver archivos grandes" 'Get-ChildItem C:\ -Recurse -EA SilentlyContinue | Sort-Object Length -Descending | Select-Object -First 20 FullName,@{n="MB";e={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize' 2
Add-RepairBtn "Limpiar carpeta WER" 'Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -EA SilentlyContinue; Write-Output "WER limpiado"' 3
$yR += 36

# === RED ===
Add-RepairSection "Red y Conectividad"
Add-RepairBtn "Flush DNS" 'ipconfig /flushdns' 0
Add-RepairBtn "Reset TCP/IP" 'netsh int ip reset' 1
Add-RepairBtn "Reset Winsock" 'netsh winsock reset' 2
Add-RepairBtn "Renovar IP (DHCP)" 'ipconfig /release; ipconfig /renew' 3
$yR += 36
Add-RepairBtn "Ver IP e interfaces" 'ipconfig /all' 0
Add-RepairBtn "Ver puertos abiertos" 'netstat -ano' 1
Add-RepairBtn "Test DNS publico" 'nslookup google.com 8.8.8.8' 2
Add-RepairBtn "Ping Gateway" 'ping -n 4 (Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Select -First 1 -Exp NextHop)' 3
$yR += 36
Add-RepairBtn "Reset firewall" 'netsh advfirewall reset; Write-Output "Firewall reseteado"' 0
Add-RepairBtn "Ver conexiones activas" 'Get-NetTCPConnection -State Established | Select LocalPort,RemoteAddress,OwningProcess | Format-Table -AutoSize' 1
Add-RepairBtn "Velocidad adaptadores" 'Get-NetAdapter | Select Name,LinkSpeed,Status | Format-Table -AutoSize' 2
Add-RepairBtn "Matar proceso puerto 80" '$pids=(netstat -ano|Select-String ":80 ") -replace ".*\s(\d+)$","$1"|Sort-Object -Unique; $pids|Where{$_ -match "^\d+$"}|%{Stop-Process -Id $_ -Force -EA SilentlyContinue; Write-Output "PID $_ terminado"}' 3
$yR += 36

# === RENDIMIENTO ===
Add-RepairSection "Optimizacion de Rendimiento"
Add-RepairBtn "Alto rendimiento (energia)" 'powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; Write-Output "Plan de alto rendimiento activado"' 0
Add-RepairBtn "Limpiar RAM (vaciar)" '[System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); Write-Output "GC ejecutado"' 1
Add-RepairBtn "Procesos que mas CPU usan" 'Get-Process | Sort-Object CPU -Descending | Select -First 15 Name,CPU,WorkingSet | Format-Table -AutoSize' 2
Add-RepairBtn "Servicios innecesarios" 'Get-Service | Where-Object {$_.Status -eq "Running"} | Select DisplayName,Name | Sort DisplayName | Format-Table -AutoSize' 3
$yR += 36
Add-RepairBtn "Deshabilitar inicio automata" 'Get-CimInstance Win32_StartupCommand | Select Name,Command,Location | Format-Table -AutoSize' 0
Add-RepairBtn "Actualizar drivers (pnputil)" 'pnputil /scan-devices; Write-Output "Escaneo de drivers completado"' 1
Add-RepairBtn "Estado de memoria RAM" 'Get-CimInstance Win32_PhysicalMemory | Select Manufacturer,Speed,Capacity | Format-Table -AutoSize' 2
Add-RepairBtn "Temperatura CPU (WMI)" 'Get-WmiObject MSAcpi_ThermalZoneTemperature -Namespace "root/wmi" -EA SilentlyContinue | Select @{n="Temp C";e={[math]::Round($_.CurrentTemperature/10-273.15,1)}}' 3
$yR += 36

# === SEGURIDAD ===
Add-RepairSection "Seguridad del Sistema"
Add-RepairBtn "Estado Windows Defender" 'Get-MpComputerStatus | Select AMRunningMode,RealTimeProtectionEnabled,AntivirusEnabled | Format-List' 0
Add-RepairBtn "Escaneo rapido (Defender)" 'Start-MpScan -ScanType QuickScan; Write-Output "Escaneo rapido iniciado"' 1
Add-RepairBtn "Actualizar firmas Defender" 'Update-MpSignature; Write-Output "Firmas actualizadas"' 2
Add-RepairBtn "Ver usuarios del sistema" 'Get-LocalUser | Select Name,Enabled,LastLogon | Format-Table -AutoSize' 3
$yR += 36
Add-RepairBtn "Ver politicas UAC" 'reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin' 0
Add-RepairBtn "Auditoria de seguridad" 'Get-EventLog Security -Newest 20 -EA SilentlyContinue | Select TimeGenerated,EntryType,Message | Format-Table -AutoSize' 1
Add-RepairBtn "Limpiar credenciales" 'cmdkey /list' 2
Add-RepairBtn "Ver permisos carpeta" 'icacls C:\Windows\System32 | Select-Object -First 10' 3
$yR += 36

# === ARRANQUE ===
Add-RepairSection "Arranque y Recuperacion"
Add-RepairBtn "Ver entradas de arranque" 'bcdedit /enum' 0
Add-RepairBtn "Habilitar modo seguro" 'bcdedit /set {current} safeboot minimal; Write-Output "Modo seguro activado (reiniciar)"' 1
Add-RepairBtn "Deshabilitar modo seguro" 'bcdedit /deletevalue {current} safeboot; Write-Output "Modo seguro desactivado"' 2
Add-RepairBtn "Crear punto restauracion" 'Checkpoint-Computer -Description "SysCodi_$(Get-Date -Format yyyyMMdd)" -RestorePointType "MODIFY_SETTINGS"; Write-Output "Punto de restauracion creado"' 3
$yR += 36
Add-RepairBtn "Ver puntos restauracion" 'Get-ComputerRestorePoint | Select Description,CreationTime | Format-Table -AutoSize' 0
Add-RepairBtn "Exportar eventos criticos" 'Get-EventLog System -EntryType Error -Newest 50 -EA SilentlyContinue | Export-Csv "$env:USERPROFILE\Desktop\eventos_error.csv" -NoTypeInformation; Write-Output "Exportado al escritorio"' 1
Add-RepairBtn "Configurar volcado memoria" 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v CrashDumpEnabled /t REG_DWORD /d 7 /f; Write-Output "Volcado completo configurado"' 2
Add-RepairBtn "Ver ultimo BSOD" 'Get-EventLog System -Source "Microsoft-Windows-WER-SystemErrorReporting" -Newest 5 -EA SilentlyContinue | Select TimeGenerated,Message | Format-List' 3
$yR += 36

# === DRIVERS ===
Add-RepairSection "Drivers y Dispositivos"
Add-RepairBtn "Ver drivers instalados" 'Get-WmiObject Win32_PnPSignedDriver | Select DeviceName,DriverVersion,Manufacturer | Sort DeviceName | Format-Table -AutoSize' 0
Add-RepairBtn "Drivers con error" 'Get-WmiObject Win32_PnPEntity | Where-Object{$_.ConfigManagerErrorCode -ne 0} | Select Name,ConfigManagerErrorCode | Format-Table -AutoSize' 1
Add-RepairBtn "Buscar actualizaciones" 'pnputil /enum-drivers | Select-String "Published Name","Driver Date"' 2
Add-RepairBtn "Exportar lista drivers" 'Get-WmiObject Win32_PnPSignedDriver | Select DeviceName,DriverVersion | Export-Csv "$env:USERPROFILE\Desktop\drivers.csv" -NoTypeInformation; Write-Output "Lista exportada al escritorio"' 3
$yR += 36

# Boton mantenimiento completo
$btnMaint = New-Object Windows.Forms.Button
$btnMaint.Text      = "  MANTENIMIENTO COMPLETO (Todo en uno)"
$btnMaint.Location  = New-Object Drawing.Point(8, ($yR + 10))
$btnMaint.Size      = New-Object Drawing.Size(762, 42)
$btnMaint.BackColor = [Drawing.Color]::FromArgb(0, 80, 160)
$btnMaint.ForeColor = $cText
$btnMaint.FlatStyle = "Flat"
$btnMaint.FlatAppearance.BorderColor = $cAccent2
$btnMaint.FlatAppearance.BorderSize  = 2
$btnMaint.Font      = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$btnMaint.Cursor    = "Hand"
$btnMaint.Add_Click({
    Write-Section "MANTENIMIENTO COMPLETO"
    $cmds = @(
        @("Limpieza temporales", 'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue'),
        @("Flush DNS",           'ipconfig /flushdns'),
        @("SFC scannow",         'sfc /scannow'),
        @("DISM RestoreHealth",  'DISM /Online /Cleanup-Image /RestoreHealth'),
        @("Papelera",            'Clear-RecycleBin -Force -EA SilentlyContinue'),
        @("Optimizar disco",     'Optimize-Volume -DriveLetter C -Verbose -EA SilentlyContinue')
    )
    Start-Progress
    foreach ($c in $cmds) {
        Write-Out ">>> $($c[0])..." $cSubText
        $res = Invoke-Expression $c[1] 2>&1
        Write-Out "Completado: $($c[0])" $cGreen
        [Windows.Forms.Application]::DoEvents()
    }
    Stop-Progress
    Write-Out "MANTENIMIENTO COMPLETO FINALIZADO" $cGreen
})
$scrollRepair.Controls.Add($btnMaint)
$yR += 60

# Ajustar altura scroll
$scrollRepair.AutoScrollMinSize = New-Object Drawing.Size(760, ($yR + 20))

# ============================================================
#   TAB 2: APLICACIONES
# ============================================================
$topApps = New-Object Windows.Forms.Panel
$topApps.Location  = New-Object Drawing.Point(0, 0)
$topApps.Size      = New-Object Drawing.Size(782, 46)
$topApps.BackColor = $cPanel
$tabApps.Controls.Add($topApps)

# Barra busqueda
$lblSearch = New-Object Windows.Forms.Label
$lblSearch.Text      = "Buscar:"
$lblSearch.Location  = New-Object Drawing.Point(8, 13)
$lblSearch.Size      = New-Object Drawing.Size(50, 20)
$lblSearch.ForeColor = $cSubText
$topApps.Controls.Add($lblSearch)

$txtSearch = New-Object Windows.Forms.TextBox
$txtSearch.Location  = New-Object Drawing.Point(60, 10)
$txtSearch.Size      = New-Object Drawing.Size(200, 24)
$txtSearch.BackColor = [Drawing.Color]::FromArgb(20, 35, 70)
$txtSearch.ForeColor = $cText
$txtSearch.BorderStyle = "FixedSingle"
$topApps.Controls.Add($txtSearch)

$btnSelAll = New-Object Windows.Forms.Button
$btnSelAll.Text      = "Sel. Todo"
$btnSelAll.Location  = New-Object Drawing.Point(270, 8)
$btnSelAll.Size      = New-Object Drawing.Size(85, 28)
$btnSelAll.BackColor = [Drawing.Color]::FromArgb(0, 80, 140)
$btnSelAll.ForeColor = $cText
$btnSelAll.FlatStyle = "Flat"
$btnSelAll.Font      = New-Object Drawing.Font("Segoe UI", 8)
$topApps.Controls.Add($btnSelAll)

$btnSelNone = New-Object Windows.Forms.Button
$btnSelNone.Text      = "Limpiar"
$btnSelNone.Location  = New-Object Drawing.Point(360, 8)
$btnSelNone.Size      = New-Object Drawing.Size(75, 28)
$btnSelNone.BackColor = [Drawing.Color]::FromArgb(60, 20, 20)
$btnSelNone.ForeColor = $cText
$btnSelNone.FlatStyle = "Flat"
$btnSelNone.Font      = New-Object Drawing.Font("Segoe UI", 8)
$topApps.Controls.Add($btnSelNone)

$btnFoss = New-Object Windows.Forms.Button
$btnFoss.Text      = "Solo FOSS"
$btnFoss.Location  = New-Object Drawing.Point(440, 8)
$btnFoss.Size      = New-Object Drawing.Size(85, 28)
$btnFoss.BackColor = [Drawing.Color]::FromArgb(0, 60, 30)
$btnFoss.ForeColor = $cAccent2
$btnFoss.FlatStyle = "Flat"
$btnFoss.Font      = New-Object Drawing.Font("Segoe UI", 8)
$topApps.Controls.Add($btnFoss)

$btnInstallApps = New-Object Windows.Forms.Button
$btnInstallApps.Text      = "  INSTALAR SELECCIONADAS"
$btnInstallApps.Location  = New-Object Drawing.Point(540, 5)
$btnInstallApps.Size      = New-Object Drawing.Size(220, 36)
$btnInstallApps.BackColor = [Drawing.Color]::FromArgb(0, 120, 60)
$btnInstallApps.ForeColor = $cText
$btnInstallApps.FlatStyle = "Flat"
$btnInstallApps.FlatAppearance.BorderColor = $cGreen
$btnInstallApps.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$topApps.Controls.Add($btnInstallApps)

$scrollApps = New-Object Windows.Forms.Panel
$scrollApps.Location   = New-Object Drawing.Point(0, 46)
$scrollApps.Size       = New-Object Drawing.Size(782, 579)
$scrollApps.AutoScroll = $true
$scrollApps.BackColor  = $cBg
$tabApps.Controls.Add($scrollApps)

$appList = @(
    # Navegadores
    @{cat="Navegadores";       name="Google Chrome";       cmd="winget install -e --id Google.Chrome -h";                    foss=$false},
    @{cat="Navegadores";       name="Mozilla Firefox";     cmd="winget install -e --id Mozilla.Firefox -h";                  foss=$true},
    @{cat="Navegadores";       name="Brave Browser";       cmd="winget install -e --id Brave.Brave -h";                      foss=$true},
    @{cat="Navegadores";       name="LibreWolf";            cmd="winget install -e --id LibreWolf.LibreWolf -h";              foss=$true},
    @{cat="Navegadores";       name="Opera GX";             cmd="winget install -e --id Opera.OperaGX -h";                   foss=$false},
    @{cat="Navegadores";       name="Microsoft Edge";       cmd="winget install -e --id Microsoft.Edge -h";                  foss=$false},
    # Comunicacion
    @{cat="Comunicacion";      name="Discord";              cmd="winget install -e --id Discord.Discord -h";                 foss=$false},
    @{cat="Comunicacion";      name="Telegram";             cmd="winget install -e --id Telegram.TelegramDesktop -h";        foss=$true},
    @{cat="Comunicacion";      name="Slack";                cmd="winget install -e --id SlackTechnologies.Slack -h";         foss=$false},
    @{cat="Comunicacion";      name="Signal";               cmd="winget install -e --id OpenWhisperSystems.Signal -h";       foss=$true},
    @{cat="Comunicacion";      name="WhatsApp";             cmd="winget install -e --id 9NKSQGP7F2NH -h";                    foss=$false},
    @{cat="Comunicacion";      name="Zoom";                 cmd="winget install -e --id Zoom.Zoom -h";                       foss=$false},
    @{cat="Comunicacion";      name="Microsoft Teams";      cmd="winget install -e --id Microsoft.Teams -h";                 foss=$false},
    # Desarrollo
    @{cat="Desarrollo";        name="VS Code";              cmd="winget install -e --id Microsoft.VisualStudioCode -h";      foss=$true},
    @{cat="Desarrollo";        name="Git";                  cmd="winget install -e --id Git.Git -h";                         foss=$true},
    @{cat="Desarrollo";        name="Python 3";             cmd="winget install -e --id Python.Python.3 -h";                 foss=$true},
    @{cat="Desarrollo";        name="NodeJS LTS";           cmd="winget install -e --id OpenJS.NodeJS.LTS -h";               foss=$true},
    @{cat="Desarrollo";        name="JDK 21";               cmd="winget install -e --id Microsoft.OpenJDK.21 -h";            foss=$true},
    @{cat="Desarrollo";        name="Docker Desktop";       cmd="winget install -e --id Docker.DockerDesktop -h";            foss=$false},
    @{cat="Desarrollo";        name="Postman";              cmd="winget install -e --id Postman.Postman -h";                 foss=$false},
    @{cat="Desarrollo";        name="GitHub Desktop";       cmd="winget install -e --id GitHub.GitHubDesktop -h";            foss=$false},
    @{cat="Desarrollo";        name="PowerShell 7";         cmd="winget install -e --id Microsoft.PowerShell -h";            foss=$true},
    @{cat="Desarrollo";        name="Windows Terminal";     cmd="winget install -e --id Microsoft.WindowsTerminal -h";       foss=$true},
    # Utilidades
    @{cat="Utilidades";        name="7-Zip";                cmd="winget install -e --id 7zip.7zip -h";                       foss=$true},
    @{cat="Utilidades";        name="WinRAR";               cmd="winget install -e --id RARLab.WinRAR -h";                   foss=$false},
    @{cat="Utilidades";        name="Notepad++";            cmd="winget install -e --id Notepad++.Notepad++ -h";             foss=$true},
    @{cat="Utilidades";        name="Everything";           cmd="winget install -e --id voidtools.Everything -h";            foss=$false},
    @{cat="Utilidades";        name="TreeSize Free";        cmd="winget install -e --id JAMSoftware.TreeSize.Free -h";       foss=$false},
    @{cat="Utilidades";        name="CPU-Z";                cmd="winget install -e --id CPUID.CPU-Z -h";                     foss=$false},
    @{cat="Utilidades";        name="GPU-Z";                cmd="winget install -e --id TechPowerUp.GPU-Z -h";               foss=$false},
    @{cat="Utilidades";        name="HWMonitor";            cmd="winget install -e --id CPUID.HWMonitor -h";                 foss=$false},
    @{cat="Utilidades";        name="CrystalDiskInfo";      cmd="winget install -e --id CrystalDewWorld.CrystalDiskInfo -h"; foss=$false},
    @{cat="Utilidades";        name="WinDirStat";           cmd="winget install -e --id WinDirStat.WinDirStat -h";           foss=$true},
    # Multimedia
    @{cat="Multimedia";        name="VLC";                  cmd="winget install -e --id VideoLAN.VLC -h";                    foss=$true},
    @{cat="Multimedia";        name="Spotify";              cmd="winget install -e --id Spotify.Spotify -h";                 foss=$false},
    @{cat="Multimedia";        name="OBS Studio";           cmd="winget install -e --id OBSProject.OBSStudio -h";            foss=$true},
    @{cat="Multimedia";        name="HandBrake";            cmd="winget install -e --id HandBrake.HandBrake -h";             foss=$true},
    @{cat="Multimedia";        name="Audacity";             cmd="winget install -e --id Audacity.Audacity -h";               foss=$true},
    @{cat="Multimedia";        name="GIMP";                 cmd="winget install -e --id GIMP.GIMP -h";                       foss=$true},
    @{cat="Multimedia";        name="Inkscape";             cmd="winget install -e --id Inkscape.Inkscape -h";               foss=$true},
    @{cat="Multimedia";        name="Krita";                cmd="winget install -e --id KDE.Krita -h";                       foss=$true},
    # Oficina
    @{cat="Oficina";           name="LibreOffice";          cmd="winget install -e --id TheDocumentFoundation.LibreOffice -h"; foss=$true},
    @{cat="Oficina";           name="Foxit PDF Reader";     cmd="winget install -e --id Foxit.FoxitReader -h";               foss=$false},
    @{cat="Oficina";           name="Adobe Reader";         cmd="winget install -e --id Adobe.Acrobat.Reader.64-bit -h";     foss=$false},
    @{cat="Oficina";           name="SumatraPDF";           cmd="winget install -e --id SumatraPDF.SumatraPDF -h";           foss=$true},
    @{cat="Oficina";           name="Obsidian";             cmd="winget install -e --id Obsidian.Obsidian -h";               foss=$false},
    @{cat="Oficina";           name="Notion";               cmd="winget install -e --id Notion.Notion -h";                   foss=$false},
    # Seguridad
    @{cat="Seguridad";         name="Malwarebytes";         cmd="winget install -e --id Malwarebytes.Malwarebytes -h";       foss=$false},
    @{cat="Seguridad";         name="Bitwarden";            cmd="winget install -e --id Bitwarden.Bitwarden -h";             foss=$true},
    @{cat="Seguridad";         name="KeePassXC";            cmd="winget install -e --id KeePassXCTeam.KeePassXC -h";         foss=$true},
    @{cat="Seguridad";         name="Wireshark";            cmd="winget install -e --id WiresharkFoundation.Wireshark -h";   foss=$true},
    @{cat="Seguridad";         name="Nmap";                 cmd="winget install -e --id Insecure.Nmap -h";                   foss=$true},
    # Gaming
    @{cat="Gaming";            name="Steam";                cmd="winget install -e --id Valve.Steam -h";                     foss=$false},
    @{cat="Gaming";            name="Epic Games Launcher";  cmd="winget install -e --id EpicGames.EpicGamesLauncher -h";     foss=$false},
    @{cat="Gaming";            name="GOG Galaxy";           cmd="winget install -e --id GOG.Galaxy -h";                      foss=$false},
    @{cat="Gaming";            name="Xbox App";             cmd="winget install -e --id Microsoft.GamingApp -h";             foss=$false},
    @{cat="Gaming";            name="MSI Afterburner";      cmd="winget install -e --id Guru3D.Afterburner -h";              foss=$false},
    # Fuentes tipograficas
    @{cat="Fuentes";           name="Cascadia Code";        cmd="winget install -e --id Microsoft.CascadiaCode -h";          foss=$true},
    @{cat="Fuentes";           name="Fira Code (Nerd)";     cmd="winget install -e --id DEVCOM.JetBrainsMonoNerdFont -h";    foss=$true},
    # Virtualizacion
    @{cat="Virtualizacion";    name="VirtualBox";           cmd="winget install -e --id Oracle.VirtualBox -h";               foss=$true},
    @{cat="Virtualizacion";    name="VMware Workstation";   cmd="winget install -e --id VMware.WorkstationPlayer -h";        foss=$false},
    @{cat="Virtualizacion";    name="WSL2 (Ubuntu)";        cmd="wsl --install -d Ubuntu";                                   foss=$true}
)

$checkboxes = [System.Collections.ArrayList]@()
$yA = 5
$lastCat = ""

foreach ($app in $appList) {
    if ($app.cat -ne $lastCat) {
        if ($lastCat -ne "") { $yA += 8 }
        $lbl = New-Object Windows.Forms.Label
        $lbl.Text      = "  $($app.cat)"
        $lbl.Location  = New-Object Drawing.Point(5, $yA)
        $lbl.Size      = New-Object Drawing.Size(770, 22)
        $lbl.ForeColor = $cAccent2
        $lbl.BackColor = [Drawing.Color]::FromArgb(20, 40, 80)
        $lbl.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
        $scrollApps.Controls.Add($lbl)
        $yA += 24
        $lastCat = $app.cat
        $colA = 0
    }
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text      = $app.name
    $cb.Location  = New-Object Drawing.Point((5 + $colA * 190), $yA)
    $cb.Size      = New-Object Drawing.Size(185, 22)
    $cb.ForeColor = if ($app.foss) { $cAccent2 } else { $cText }
    $cb.BackColor = $cBg
    $cb.Tag       = $app
    $scrollApps.Controls.Add($cb)
    $checkboxes.Add($cb) | Out-Null
    $colA++
    if ($colA -ge 4) { $colA = 0; $yA += 24 }
}
$yA += 24
$scrollApps.AutoScrollMinSize = New-Object Drawing.Size(770, ($yA + 20))

$btnSelAll.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $true } })
$btnSelNone.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = $false } })
$btnFoss.Add_Click({ $checkboxes | ForEach-Object { $_.Checked = ($_.Tag.foss -eq $true) } })

$txtSearch.Add_TextChanged({
    $q = $txtSearch.Text.Trim().ToLower()
    foreach ($cb in $checkboxes) {
        $cb.ForeColor = if ($q -and $cb.Text.ToLower().Contains($q)) { $cYellow } else { if ($cb.Tag.foss) { $cAccent2 } else { $cText } }
    }
})

$btnInstallApps.Add_Click({
    $sel = $checkboxes | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ninguna aplicacion." $cYellow; return }
    # Verificar winget
    if (-not (Get-Command winget -EA SilentlyContinue)) {
        Write-Out "WINGET no encontrado. Instala App Installer desde la Tienda de Windows." $cRed
        return
    }
    Write-Section "INSTALACION DE APLICACIONES ($($sel.Count) seleccionadas)"
    Start-Progress
    $i = 0
    foreach ($cb in $sel) {
        $i++
        Write-Out "[$i/$($sel.Count)] Instalando: $($cb.Tag.name)..." $cSubText
        Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"$($cb.Tag.cmd)`"" -Wait -EA SilentlyContinue
        Write-Out "  Completado: $($cb.Tag.name)" $cGreen
        [Windows.Forms.Application]::DoEvents()
    }
    Stop-Progress
    Write-Out "Instalacion completada: $i apps instaladas." $cGreen
})

# ============================================================
#   TAB 3: TWEAKS
# ============================================================
$scrollTweaks = New-ScrollPanel $tabTweaks
$yTw = 5

$tweakData = @(
    # Rendimiento
    @{cat="Rendimiento";   name="Plan de energia: Alto rendimiento";     cmd='powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c';  rev='powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e';  warn=$false},
    @{cat="Rendimiento";   name="Deshabilitar efectos visuales";          cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Rendimiento";   name="Modo juego activado";                    cmd='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f'; warn=$false},
    @{cat="Rendimiento";   name="Hardware-accelerated GPU scheduling";    cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f'; warn=$true},
    @{cat="Rendimiento";   name="Desactivar Superfetch/SysMain";          cmd='Stop-Service SysMain -Force; Set-Service SysMain -StartupType Disabled'; rev='Set-Service SysMain -StartupType Automatic; Start-Service SysMain'; warn=$false},
    @{cat="Rendimiento";   name="Desactivar Search Indexing";             cmd='Stop-Service WSearch -Force; Set-Service WSearch -StartupType Disabled'; rev='Set-Service WSearch -StartupType Automatic; Start-Service WSearch'; warn=$false},
    @{cat="Rendimiento";   name="Priorizar programas (no servicios)";     cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f'; warn=$false},
    @{cat="Rendimiento";   name="FSO (Full-screen optimization OFF)";     cmd='reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f'; rev='reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 0 /f'; warn=$false},
    # Privacidad
    @{cat="Privacidad";    name="Deshabilitar telemetria";                 cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f'; warn=$false},
    @{cat="Privacidad";    name="Deshabilitar Cortana";                    cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f'; warn=$false},
    @{cat="Privacidad";    name="Deshabilitar Activity History";           cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f'; warn=$false},
    @{cat="Privacidad";    name="Deshabilitar anuncios personalizados";    cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Privacidad";    name="Bloquear diagnosticos a Microsoft";       cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /f'; warn=$false},
    @{cat="Privacidad";    name="Deshabilitar rastreo de ubicacion";       cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 0 /f'; rev='reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 1 /f'; warn=$false},
    # Interfaz
    @{cat="Interfaz";      name="Mostrar extensiones de archivo";          cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz";      name="Mostrar archivos ocultos";                cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f'; warn=$false},
    @{cat="Interfaz";      name="Deshabilitar notificaciones sistema";     cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz";      name="Barra de tareas compacta (W11)";          cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSi /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSi /t REG_DWORD /d 2 /f'; warn=$false},
    @{cat="Interfaz";      name="Habilitar menu contextual clasico (W11)"; cmd='reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f'; rev='reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f'; warn=$false},
    @{cat="Interfaz";      name="Transparencia desactivada";               cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f'; warn=$false},
    # Red
    @{cat="Red";           name="Deshabilitar IPv6 (si no se usa)";        cmd='Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -EA SilentlyContinue'; rev='Enable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -EA SilentlyContinue'; warn=$true},
    @{cat="Red";           name="DNS Cloudflare (1.1.1.1)";                cmd='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 1.1.1.1,1.0.0.1 -EA SilentlyContinue'; rev='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue'; warn=$false},
    @{cat="Red";           name="DNS Google (8.8.8.8)";                    cmd='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 8.8.8.8,8.8.4.4 -EA SilentlyContinue'; rev='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue'; warn=$false},
    @{cat="Red";           name="Limitar banda reservada Windows";         cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /f'; warn=$false},
    # Seguridad
    @{cat="Seguridad";     name="Deshabilitar autorun USB";                cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f'; rev='reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f'; warn=$false},
    @{cat="Seguridad";     name="Deshabilitar Remote Desktop";             cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f'; warn=$false},
    @{cat="Seguridad";     name="Habilitar DEP (prevencion datos)";        cmd='bcdedit /set {current} nx AlwaysOn'; rev='bcdedit /set {current} nx OptIn'; warn=$true},
    @{cat="Seguridad";     name="Mostrar extension en explorador";         cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f'; warn=$false}
)

$tweakChecks = [System.Collections.ArrayList]@()
$lastCatTw = ""
$colTw = 0

foreach ($tw in $tweakData) {
    if ($tw.cat -ne $lastCatTw) {
        if ($lastCatTw -ne "") { $yTw += 8 }
        New-SectionLabel $tw.cat 5 $yTw $scrollTweaks | Out-Null
        $yTw += 28
        $lastCatTw = $tw.cat
        $colTw = 0
    }
    $cb = New-Object Windows.Forms.CheckBox
    $cb.Text      = if ($tw.warn) { "$($tw.name)  [!]" } else { $tw.name }
    $cb.Location  = New-Object Drawing.Point((5 + $colTw * 375), $yTw)
    $cb.Size      = New-Object Drawing.Size(368, 24)
    $cb.ForeColor = if ($tw.warn) { $cYellow } else { $cText }
    $cb.BackColor = $cBg
    $cb.Tag       = $tw
    $scrollTweaks.Controls.Add($cb)
    $tweakChecks.Add($cb) | Out-Null
    $colTw++
    if ($colTw -ge 2) { $colTw = 0; $yTw += 26 }
}
$yTw += 10

# Panel botones tweaks
$pnlTwBtns = New-Object Windows.Forms.Panel
$pnlTwBtns.Location  = New-Object Drawing.Point(5, $yTw)
$pnlTwBtns.Size      = New-Object Drawing.Size(770, 48)
$pnlTwBtns.BackColor = $cPanel
$scrollTweaks.Controls.Add($pnlTwBtns)

$btnApplyTw = New-Object Windows.Forms.Button
$btnApplyTw.Text      = "  Aplicar Seleccionados"
$btnApplyTw.Location  = New-Object Drawing.Point(5, 7)
$btnApplyTw.Size      = New-Object Drawing.Size(200, 34)
$btnApplyTw.BackColor = [Drawing.Color]::FromArgb(0, 100, 60)
$btnApplyTw.ForeColor = $cText
$btnApplyTw.FlatStyle = "Flat"
$btnApplyTw.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$btnApplyTw.Add_Click({
    $sel = $tweakChecks | Where-Object { $_.Checked }
    if ($sel.Count -eq 0) { Write-Out "No seleccionaste ningun tweak." $cYellow; return }
    # Backup registro
    $bakPath = "$logDir\registry_backup_$(Get-Date -Format yyyyMMdd_HHmmss).reg"
    reg export HKCU $bakPath /y | Out-Null
    Write-Out "Backup registro: $bakPath" $cSubText
    Write-Section "APLICANDO TWEAKS"
    foreach ($cb in $sel) {
        Write-Out "Aplicando: $($cb.Tag.name)..." $cSubText
        Invoke-Expression $cb.Tag.cmd 2>&1 | Out-Null
        Write-Out "  OK: $($cb.Tag.name)" $cGreen
    }
    Write-Out "Tweaks aplicados. Algunos requieren reinicio." $cYellow
})
$pnlTwBtns.Controls.Add($btnApplyTw)

$btnRevertTw = New-Object Windows.Forms.Button
$btnRevertTw.Text      = "Revertir Seleccionados"
$btnRevertTw.Location  = New-Object Drawing.Point(215, 7)
$btnRevertTw.Size      = New-Object Drawing.Size(180, 34)
$btnRevertTw.BackColor = [Drawing.Color]::FromArgb(100, 50, 0)
$btnRevertTw.ForeColor = $cText
$btnRevertTw.FlatStyle = "Flat"
$btnRevertTw.Font      = New-Object Drawing.Font("Segoe UI", 9)
$btnRevertTw.Add_Click({
    $sel = $tweakChecks | Where-Object { $_.Checked }
    foreach ($cb in $sel) {
        Write-Out "Revirtiendo: $($cb.Tag.name)..." $cSubText
        if ($cb.Tag.rev) { Invoke-Expression $cb.Tag.rev 2>&1 | Out-Null }
        Write-Out "  Revertido: $($cb.Tag.name)" $cYellow
    }
})
$pnlTwBtns.Controls.Add($btnRevertTw)

# Perfiles
$lblProfiles = New-Object Windows.Forms.Label
$lblProfiles.Text      = "Perfil:"
$lblProfiles.Location  = New-Object Drawing.Point(410, 14)
$lblProfiles.Size      = New-Object Drawing.Size(50, 20)
$lblProfiles.ForeColor = $cSubText
$pnlTwBtns.Controls.Add($lblProfiles)

$cmbProfile = New-Object Windows.Forms.ComboBox
$cmbProfile.Location    = New-Object Drawing.Point(462, 10)
$cmbProfile.Size        = New-Object Drawing.Size(150, 26)
$cmbProfile.BackColor   = $cPanel
$cmbProfile.ForeColor   = $cText
$cmbProfile.FlatStyle   = "Flat"
$cmbProfile.DropDownStyle = "DropDownList"
$cmbProfile.Items.AddRange(@("Gaming", "Oficina", "Privacidad Max", "PC Antigua"))
$pnlTwBtns.Controls.Add($cmbProfile)

$btnApplyProfile = New-Object Windows.Forms.Button
$btnApplyProfile.Text      = "Aplicar Perfil"
$btnApplyProfile.Location  = New-Object Drawing.Point(620, 7)
$btnApplyProfile.Size      = New-Object Drawing.Size(140, 34)
$btnApplyProfile.BackColor = [Drawing.Color]::FromArgb(0, 80, 150)
$btnApplyProfile.ForeColor = $cText
$btnApplyProfile.FlatStyle = "Flat"
$btnApplyProfile.Add_Click({
    $perfil = $cmbProfile.SelectedItem
    $gaming   = @("Plan de energia: Alto rendimiento","Modo juego activado","FSO (Full-screen optimization OFF)","Hardware-accelerated GPU scheduling","Priorizar programas (no servicios)")
    $oficina  = @("Mostrar extensiones de archivo","Mostrar archivos ocultos","Deshabilitar notificaciones sistema","Deshabilitar telemetria")
    $privMax  = @("Deshabilitar telemetria","Deshabilitar Cortana","Deshabilitar Activity History","Deshabilitar anuncios personalizados","Bloquear diagnosticos a Microsoft","Deshabilitar rastreo de ubicacion")
    $antigua  = @("Deshabilitar efectos visuales","Desactivar Superfetch/SysMain","Desactivar Search Indexing","Transparencia desactivada","Plan de energia: Alto rendimiento")
    $selected = switch ($perfil) { "Gaming" {$gaming} "Oficina" {$oficina} "Privacidad Max" {$privMax} "PC Antigua" {$antigua} default {@()} }
    $tweakChecks | ForEach-Object { $_.Checked = ($selected -contains $_.Tag.name) }
    Write-Out "Perfil '$perfil' cargado. Haz clic en 'Aplicar Seleccionados'." $cAccent2
})
$pnlTwBtns.Controls.Add($btnApplyProfile)

$yTw += 60
$scrollTweaks.AutoScrollMinSize = New-Object Drawing.Size(760, ($yTw + 20))

# ============================================================
#   TAB 4: UTILIDADES
# ============================================================
$scrollUtils = New-ScrollPanel $tabUtils

function New-UtilPanel2($titulo, $subtitulo, $y, $h = 120) {
    $pnl = New-Object Windows.Forms.Panel
    $pnl.Location  = New-Object Drawing.Point(5, $y)
    $pnl.Size      = New-Object Drawing.Size(762, $h)
    $pnl.BackColor = $cCard
    $scrollUtils.Controls.Add($pnl)

    $lblT = New-Object Windows.Forms.Label
    $lblT.Text      = "  $titulo"
    $lblT.Location  = New-Object Drawing.Point(0, 0)
    $lblT.Size      = New-Object Drawing.Size(762, 28)
    $lblT.ForeColor = $cAccent2
    $lblT.BackColor = [Drawing.Color]::FromArgb(20, 40, 80)
    $lblT.Font      = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
    $lblT.TextAlign = "MiddleLeft"
    $pnl.Controls.Add($lblT)

    $lblS = New-Object Windows.Forms.Label
    $lblS.Text      = "  $subtitulo"
    $lblS.Location  = New-Object Drawing.Point(0, 28)
    $lblS.Size      = New-Object Drawing.Size(762, 20)
    $lblS.ForeColor = $cSubText
    $lblS.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $pnl.Controls.Add($lblS)
    return $pnl
}

function New-FilePicker($panel, $y, $filter, $labelRef) {
    $lbl = New-Object Windows.Forms.Label
    $lbl.Text      = "Ningun archivo seleccionado"
    $lbl.Location  = New-Object Drawing.Point(10, $y)
    $lbl.Size      = New-Object Drawing.Size(600, 18)
    $lbl.ForeColor = $cSubText
    $lbl.Font      = New-Object Drawing.Font("Consolas", 7.5)
    $panel.Controls.Add($lbl)
    $btn = New-Object Windows.Forms.Button
    $btn.Text      = "Buscar"
    $btn.Location  = New-Object Drawing.Point(618, ($y - 3))
    $btn.Size      = New-Object Drawing.Size(130, 24)
    $btn.BackColor = $cBtn
    $btn.ForeColor = $cText
    $btn.FlatStyle = "Flat"
    $btn.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $theFilter = $filter
    $btn.Add_Click({
        $dlg = New-Object Windows.Forms.OpenFileDialog
        $dlg.Filter = $theFilter
        if ($dlg.ShowDialog() -eq "OK") { $lbl.Text = $dlg.FileName }
    })
    $panel.Controls.Add($btn)
    return $lbl
}

function Install-PyDep($pkg) {
    $check = python -c "import $pkg" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Out "Instalando dependencia: $pkg..." $cSubText
        python -m pip install $pkg --quiet 2>&1 | Out-Null
    }
}

# --- EXCEL ---
$pExcel = New-UtilPanel2 "Quitar contrasena - Excel (.xlsx / .xls / .xlsm)" "Genera una copia sin contrasena en la misma carpeta del archivo" 5 130
$lblExcelFile = New-FilePicker $pExcel 50 "Excel (*.xlsx;*.xls;*.xlsm)|*.xlsx;*.xls;*.xlsm" $null
$btnDoExcel = New-CorporateButton "  Quitar Contrasena" 10 76 190 34
$btnDoExcel.Add_Click({
    $path = $lblExcelFile.Text
    if (-not (Test-Path $path)) { Write-Out "Selecciona un Excel primero." $cYellow; return }
    Install-PyDep "msoffcrypto"
    $out = $path -replace '(\.[^.]+)$','_sin_pass$1'
    $py = @"
import msoffcrypto, sys
try:
    with open(r'$path','rb') as f:
        o = msoffcrypto.OfficeFile(f)
        o.load_key(password='')
        with open(r'$out','wb') as fw:
            o.decrypt(fw)
    print('OK')
except Exception as e:
    print('ERROR:' + str(e))
"@
    $py | Set-Content "$env:TEMP\ux_excel.py" -Encoding UTF8
    $res = python "$env:TEMP\ux_excel.py" 2>&1
    if ($res -like "*OK*") { Write-Out "Excel desbloqueado: $out" $cGreen }
    else { Write-Out "Error: $res" $cRed }
})
$pExcel.Controls.Add($btnDoExcel)

# --- WORD ---
$pWord = New-UtilPanel2 "Quitar contrasena - Word (.docx / .doc / .docm)" "Genera una copia sin contrasena en la misma carpeta del archivo" 143 130
$lblWordFile = New-FilePicker $pWord 50 "Word (*.docx;*.doc;*.docm)|*.docx;*.doc;*.docm" $null
$btnDoWord = New-CorporateButton "  Quitar Contrasena" 10 76 190 34
$btnDoWord.Add_Click({
    $path = $lblWordFile.Text
    if (-not (Test-Path $path)) { Write-Out "Selecciona un Word primero." $cYellow; return }
    Install-PyDep "msoffcrypto"
    $out = $path -replace '(\.[^.]+)$','_sin_pass$1'
    $py = @"
import msoffcrypto
try:
    with open(r'$path','rb') as f:
        o = msoffcrypto.OfficeFile(f)
        o.load_key(password='')
        with open(r'$out','wb') as fw:
            o.decrypt(fw)
    print('OK')
except Exception as e:
    print('ERROR:' + str(e))
"@
    $py | Set-Content "$env:TEMP\ux_word.py" -Encoding UTF8
    $res = python "$env:TEMP\ux_word.py" 2>&1
    if ($res -like "*OK*") { Write-Out "Word desbloqueado: $out" $cGreen }
    else { Write-Out "Error: $res" $cRed }
})
$pWord.Controls.Add($btnDoWord)

# --- ZIP ---
$pZip = New-UtilPanel2 "Quitar contrasena - ZIP" "Extrae con contrasena conocida o fuerza bruta con wordlist .txt" 281 175
$lblZipFile = New-FilePicker $pZip 50 "ZIP (*.zip)|*.zip" $null
$lblWlFile  = New-FilePicker $pZip 72 "Wordlist (*.txt)|*.txt" $null
$lblWlFile.Text = "Sin wordlist (opcional)"

$lblPassLabel = New-Object Windows.Forms.Label
$lblPassLabel.Text      = "Contrasena (si la conoces):"
$lblPassLabel.Location  = New-Object Drawing.Point(10, 95)
$lblPassLabel.Size      = New-Object Drawing.Size(190, 20)
$lblPassLabel.ForeColor = $cSubText
$pZip.Controls.Add($lblPassLabel)

$txtZipPass = New-Object Windows.Forms.TextBox
$txtZipPass.Location  = New-Object Drawing.Point(208, 93)
$txtZipPass.Size      = New-Object Drawing.Size(200, 24)
$txtZipPass.BackColor = [Drawing.Color]::FromArgb(15,25,50)
$txtZipPass.ForeColor = $cText
$txtZipPass.UseSystemPasswordChar = $true
$pZip.Controls.Add($txtZipPass)

$btnDoZip = New-CorporateButton "  Extraer / Desbloquear" 10 128 220 34
$btnDoZip.Add_Click({
    $zipPath = $lblZipFile.Text
    $pass    = $txtZipPass.Text.Trim()
    $wl      = $lblWlFile.Text
    if (-not (Test-Path $zipPath)) { Write-Out "Selecciona un ZIP primero." $cYellow; return }
    $outDir = [IO.Path]::Combine([IO.Path]::GetDirectoryName($zipPath), [IO.Path]::GetFileNameWithoutExtension($zipPath) + "_extraido")
    $py = @"
import zipfile, os, sys
path = r'$zipPath'
out  = r'$outDir'
pwd  = r'$pass'
wl   = r'$wl'
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
    print('INFO:Fuerza bruta...')
    with open(wl,'r',errors='ignore') as f:
        for i,line in enumerate(f):
            p = line.strip()
            try:
                with zipfile.ZipFile(path) as z: z.extractall(out, pwd=p.encode())
                print('OK:Contrasena encontrada: ' + p); sys.exit()
            except: pass
            if i % 1000 == 0: print('INFO:Probadas ' + str(i) + '...')
    print('ERROR:No se encontro la contrasena.')
else:
    print('ERROR:ZIP protegido. Ingresa contrasena o selecciona wordlist.')
"@
    $py | Set-Content "$env:TEMP\ux_zip.py" -Encoding UTF8
    Write-Out "Procesando ZIP..." $cSubText
    Start-Progress
    $res = python "$env:TEMP\ux_zip.py" 2>&1
    Stop-Progress
    foreach ($line in $res) {
        if   ($line -like "OK:*")    { Write-Out $line.Substring(3) $cGreen }
        elseif ($line -like "ERROR:*") { Write-Out $line.Substring(6) $cRed }
        else                          { Write-Out $line $cSubText }
    }
})
$pZip.Controls.Add($btnDoZip)

# --- HASH ARCHIVO ---
$pHash = New-UtilPanel2 "Calcular Hash de Archivo" "Verifica integridad de archivos con MD5 / SHA1 / SHA256" 463 110
$lblHashFile = New-FilePicker $pHash 50 "Todos (*.*)|*.*" $null
$cmbHash = New-Object Windows.Forms.ComboBox
$cmbHash.Location    = New-Object Drawing.Point(10, 76)
$cmbHash.Size        = New-Object Drawing.Size(100, 26)
$cmbHash.BackColor   = $cPanel
$cmbHash.ForeColor   = $cText
$cmbHash.FlatStyle   = "Flat"
$cmbHash.DropDownStyle = "DropDownList"
$cmbHash.Items.AddRange(@("MD5","SHA1","SHA256","SHA512"))
$cmbHash.SelectedIndex = 2
$pHash.Controls.Add($cmbHash)
$btnDoHash = New-CorporateButton "  Calcular Hash" 120 73 180 32
$btnDoHash.Add_Click({
    $path = $lblHashFile.Text
    if (-not (Test-Path $path)) { Write-Out "Selecciona un archivo." $cYellow; return }
    $alg = $cmbHash.SelectedItem
    $hash = Get-FileHash $path -Algorithm $alg
    Write-Out "[$alg] $($hash.Hash)" $cGreen
    Write-Out "Archivo: $path" $cSubText
    [Windows.Forms.Clipboard]::SetText($hash.Hash)
    Write-Out "(Copiado al portapapeles)" $cSubText
})
$pHash.Controls.Add($btnDoHash)

# --- RENOMBRAR EN LOTE ---
$pRename = New-UtilPanel2 "Renombrar Archivos en Lote" "Agrega prefijo, sufijo o reemplaza texto en nombres de archivo de una carpeta" 580 145

$lblFolderRen = New-Object Windows.Forms.Label
$lblFolderRen.Text      = "Ningun directorio seleccionado"
$lblFolderRen.Location  = New-Object Drawing.Point(10, 50)
$lblFolderRen.Size      = New-Object Drawing.Size(600, 18)
$lblFolderRen.ForeColor = $cSubText
$lblFolderRen.Font      = New-Object Drawing.Font("Consolas", 7.5)
$pRename.Controls.Add($lblFolderRen)

$btnPickFolder = New-Object Windows.Forms.Button
$btnPickFolder.Text      = "Seleccionar Carpeta"
$btnPickFolder.Location  = New-Object Drawing.Point(618, 46)
$btnPickFolder.Size      = New-Object Drawing.Size(130, 26)
$btnPickFolder.BackColor = $cBtn
$btnPickFolder.ForeColor = $cText
$btnPickFolder.FlatStyle = "Flat"
$btnPickFolder.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $lblFolderRen.Text = $dlg.SelectedPath }
})
$pRename.Controls.Add($btnPickFolder)

$lblPre = New-Object Windows.Forms.Label; $lblPre.Text = "Prefijo:"; $lblPre.Location = New-Object Drawing.Point(10,76); $lblPre.Size = New-Object Drawing.Size(55,20); $lblPre.ForeColor = $cSubText; $pRename.Controls.Add($lblPre)
$txtPre = New-Object Windows.Forms.TextBox; $txtPre.Location = New-Object Drawing.Point(68,73); $txtPre.Size = New-Object Drawing.Size(100,24); $txtPre.BackColor = $cPanel; $txtPre.ForeColor = $cText; $pRename.Controls.Add($txtPre)
$lblSuf = New-Object Windows.Forms.Label; $lblSuf.Text = "Sufijo:"; $lblSuf.Location = New-Object Drawing.Point(180,76); $lblSuf.Size = New-Object Drawing.Size(50,20); $lblSuf.ForeColor = $cSubText; $pRename.Controls.Add($lblSuf)
$txtSuf = New-Object Windows.Forms.TextBox; $txtSuf.Location = New-Object Drawing.Point(232,73); $txtSuf.Size = New-Object Drawing.Size(100,24); $txtSuf.BackColor = $cPanel; $txtSuf.ForeColor = $cText; $pRename.Controls.Add($txtSuf)
$lblRep = New-Object Windows.Forms.Label; $lblRep.Text = "Reemplazar:"; $lblRep.Location = New-Object Drawing.Point(345,76); $lblRep.Size = New-Object Drawing.Size(80,20); $lblRep.ForeColor = $cSubText; $pRename.Controls.Add($lblRep)
$txtRepF = New-Object Windows.Forms.TextBox; $txtRepF.Location = New-Object Drawing.Point(430,73); $txtRepF.Size = New-Object Drawing.Size(90,24); $txtRepF.BackColor = $cPanel; $txtRepF.ForeColor = $cText; $txtRepF.PlaceholderText = "de"; $pRename.Controls.Add($txtRepF)
$txtRepT = New-Object Windows.Forms.TextBox; $txtRepT.Location = New-Object Drawing.Point(528,73); $txtRepT.Size = New-Object Drawing.Size(90,24); $txtRepT.BackColor = $cPanel; $txtRepT.ForeColor = $cText; $txtRepT.PlaceholderText = "a"; $pRename.Controls.Add($txtRepT)

$btnDoRename = New-CorporateButton "  Renombrar" 10 106 180 32
$btnDoRename.Add_Click({
    $folder = $lblFolderRen.Text
    if (-not (Test-Path $folder)) { Write-Out "Selecciona una carpeta." $cYellow; return }
    $pre  = $txtPre.Text
    $suf  = $txtSuf.Text
    $repF = $txtRepF.Text
    $repT = $txtRepT.Text
    $files = Get-ChildItem $folder -File
    $count = 0
    foreach ($f in $files) {
        $newName = $f.BaseName
        if ($repF) { $newName = $newName.Replace($repF, $repT) }
        $newName = "$pre$newName$suf$($f.Extension)"
        if ($newName -ne $f.Name) {
            Rename-Item $f.FullName $newName -EA SilentlyContinue
            $count++
        }
    }
    Write-Out "Renombrados $count archivos en: $folder" $cGreen
})
$pRename.Controls.Add($btnDoRename)

# --- CONVERTIR IMAGENES ---
$pImg = New-UtilPanel2 "Convertir / Comprimir Imagenes en Lote" "Convierte JPG/PNG/WEBP y ajusta calidad. Requiere Python + Pillow" 732 130

$lblImgFolder = New-Object Windows.Forms.Label
$lblImgFolder.Text      = "Ningun directorio seleccionado"
$lblImgFolder.Location  = New-Object Drawing.Point(10, 50)
$lblImgFolder.Size      = New-Object Drawing.Size(600, 18)
$lblImgFolder.ForeColor = $cSubText
$lblImgFolder.Font      = New-Object Drawing.Font("Consolas", 7.5)
$pImg.Controls.Add($lblImgFolder)

$btnPickImgFolder = New-Object Windows.Forms.Button
$btnPickImgFolder.Text      = "Carpeta Imagenes"
$btnPickImgFolder.Location  = New-Object Drawing.Point(618, 46)
$btnPickImgFolder.Size      = New-Object Drawing.Size(130, 26)
$btnPickImgFolder.BackColor = $cBtn
$btnPickImgFolder.ForeColor = $cText
$btnPickImgFolder.FlatStyle = "Flat"
$btnPickImgFolder.Add_Click({
    $dlg = New-Object Windows.Forms.FolderBrowserDialog
    if ($dlg.ShowDialog() -eq "OK") { $lblImgFolder.Text = $dlg.SelectedPath }
})
$pImg.Controls.Add($btnPickImgFolder)

$lblFmt = New-Object Windows.Forms.Label; $lblFmt.Text = "Formato salida:"; $lblFmt.Location = New-Object Drawing.Point(10,76); $lblFmt.Size = New-Object Drawing.Size(100,20); $lblFmt.ForeColor = $cSubText; $pImg.Controls.Add($lblFmt)
$cmbFmt = New-Object Windows.Forms.ComboBox; $cmbFmt.Location = New-Object Drawing.Point(115,73); $cmbFmt.Size = New-Object Drawing.Size(80,26); $cmbFmt.BackColor = $cPanel; $cmbFmt.ForeColor = $cText; $cmbFmt.FlatStyle = "Flat"; $cmbFmt.DropDownStyle = "DropDownList"; $cmbFmt.Items.AddRange(@("JPEG","PNG","WEBP","BMP")); $cmbFmt.SelectedIndex = 0; $pImg.Controls.Add($cmbFmt)
$lblQual = New-Object Windows.Forms.Label; $lblQual.Text = "Calidad (1-95):"; $lblQual.Location = New-Object Drawing.Point(210,76); $lblQual.Size = New-Object Drawing.Size(100,20); $lblQual.ForeColor = $cSubText; $pImg.Controls.Add($lblQual)
$txtQual = New-Object Windows.Forms.TextBox; $txtQual.Text = "85"; $txtQual.Location = New-Object Drawing.Point(315,73); $txtQual.Size = New-Object Drawing.Size(50,24); $txtQual.BackColor = $cPanel; $txtQual.ForeColor = $cText; $pImg.Controls.Add($txtQual)

$btnDoImg = New-CorporateButton "  Convertir Imagenes" 10 100 200 32
$btnDoImg.Add_Click({
    $folder = $lblImgFolder.Text
    if (-not (Test-Path $folder)) { Write-Out "Selecciona una carpeta." $cYellow; return }
    Install-PyDep "PIL"
    $fmt  = $cmbFmt.SelectedItem.ToLower()
    $qual = [int]($txtQual.Text)
    $py = @"
from PIL import Image
import os, glob
folder = r'$folder'
fmt = '$fmt'
qual = $qual
out_folder = os.path.join(folder, 'convertidas_' + fmt)
os.makedirs(out_folder, exist_ok=True)
count = 0
for ext in ['*.jpg','*.jpeg','*.png','*.webp','*.bmp']:
    for path in glob.glob(os.path.join(folder, ext)):
        try:
            img = Image.open(path).convert('RGB') if fmt in ['jpeg','jpg'] else Image.open(path)
            name = os.path.splitext(os.path.basename(path))[0] + '.' + fmt
            out = os.path.join(out_folder, name)
            img.save(out, quality=qual)
            count += 1
        except Exception as e:
            print('WARN:' + str(e))
print('OK:' + str(count) + ' imagenes convertidas en: ' + out_folder)
"@
    $py | Set-Content "$env:TEMP\ux_img.py" -Encoding UTF8
    Start-Progress
    $res = python "$env:TEMP\ux_img.py" 2>&1
    Stop-Progress
    foreach ($line in $res) {
        if   ($line -like "OK:*")   { Write-Out $line.Substring(3) $cGreen }
        elseif ($line -like "WARN:*") { Write-Out $line.Substring(5) $cYellow }
        else                          { Write-Out $line $cSubText }
    }
})
$pImg.Controls.Add($btnDoImg)

$scrollUtils.AutoScrollMinSize = New-Object Drawing.Size(760, 880)

# ============================================================
#   TAB 5: SISTEMA - Dashboard en tiempo real
# ============================================================
$pnlDash = New-Object Windows.Forms.Panel
$pnlDash.Location  = New-Object Drawing.Point(0, 0)
$pnlDash.Size      = New-Object Drawing.Size(782, 635)
$pnlDash.BackColor = $cBg
$tabInfo.Controls.Add($pnlDash)

# Cards de metricas
function New-MetricCard($titulo, $x, $y, $w = 180, $h = 100) {
    $pCard = New-Object Windows.Forms.Panel
    $pCard.Location  = New-Object Drawing.Point($x, $y)
    $pCard.Size      = New-Object Drawing.Size($w, $h)
    $pCard.BackColor = $cCard
    $pnlDash.Controls.Add($pCard)

    $lblT = New-Object Windows.Forms.Label
    $lblT.Text      = $titulo
    $lblT.Location  = New-Object Drawing.Point(8, 6)
    $lblT.Size      = New-Object Drawing.Size($w - 16, 18)
    $lblT.ForeColor = $cSubText
    $lblT.Font      = New-Object Drawing.Font("Segoe UI", 8)
    $pCard.Controls.Add($lblT)

    $lblV = New-Object Windows.Forms.Label
    $lblV.Text      = "..."
    $lblV.Location  = New-Object Drawing.Point(8, 26)
    $lblV.Size      = New-Object Drawing.Size($w - 16, 36)
    $lblV.ForeColor = $cAccent2
    $lblV.Font      = New-Object Drawing.Font("Segoe UI", 18, [Drawing.FontStyle]::Bold)
    $pCard.Controls.Add($lblV)

    $bar = New-Object Windows.Forms.ProgressBar
    $bar.Location  = New-Object Drawing.Point(8, 70)
    $bar.Size      = New-Object Drawing.Size($w - 16, 12)
    $bar.Minimum   = 0
    $bar.Maximum   = 100
    $bar.ForeColor = $cAccent2
    $bar.BackColor = [Drawing.Color]::FromArgb(10, 20, 45)
    $bar.Style     = "Continuous"
    $pCard.Controls.Add($bar)
    return @{card=$pCard; val=$lblV; bar=$bar}
}

$cardCPU  = New-MetricCard "CPU"    8    8
$cardRAM  = New-MetricCard "RAM"    198  8
$cardDisk = New-MetricCard "Disco C:" 388  8
$cardNet  = New-MetricCard "Red"    578  8

# Info estatica
$infoBox = New-Object Windows.Forms.RichTextBox
$infoBox.Location    = New-Object Drawing.Point(5, 118)
$infoBox.Size        = New-Object Drawing.Size(772, 300)
$infoBox.BackColor   = $cOutput
$infoBox.ForeColor   = $cAccent2
$infoBox.Font        = New-Object Drawing.Font("Consolas", 8.5)
$infoBox.ReadOnly    = $true
$infoBox.BorderStyle = "None"
$infoBox.ScrollBars  = "Vertical"
$pnlDash.Controls.Add($infoBox)

# Top procesos
$lblProcs = New-Object Windows.Forms.Label
$lblProcs.Text      = "  Top 10 Procesos (CPU + RAM):"
$lblProcs.Location  = New-Object Drawing.Point(5, 425)
$lblProcs.Size      = New-Object Drawing.Size(772, 22)
$lblProcs.ForeColor = $cAccent2
$lblProcs.BackColor = [Drawing.Color]::FromArgb(20,40,80)
$lblProcs.Font      = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
$pnlDash.Controls.Add($lblProcs)

$procBox = New-Object Windows.Forms.RichTextBox
$procBox.Location    = New-Object Drawing.Point(5, 448)
$procBox.Size        = New-Object Drawing.Size(772, 120)
$procBox.BackColor   = $cOutput
$procBox.ForeColor   = $cText
$procBox.Font        = New-Object Drawing.Font("Consolas", 8)
$procBox.ReadOnly    = $true
$procBox.BorderStyle = "None"
$pnlDash.Controls.Add($procBox)

# Botones info
$pnlInfoBtns = New-Object Windows.Forms.Panel
$pnlInfoBtns.Location  = New-Object Drawing.Point(5, 575)
$pnlInfoBtns.Size      = New-Object Drawing.Size(772, 50)
$pnlInfoBtns.BackColor = $cPanel
$pnlDash.Controls.Add($pnlInfoBtns)

$btnCargarInfo = New-CorporateButton "  Cargar Info Sistema" 5 8 200 34
$btnCargarInfo.Add_Click({
    $infoBox.Clear()
    $os   = Get-CimInstance Win32_OperatingSystem
    $cpu  = Get-CimInstance Win32_Processor
    $bios = Get-CimInstance Win32_BIOS
    $mem  = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $free = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $used = [math]::Round($mem - $free, 2)
    $disk = Get-PSDrive C
    $diskTotal = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
    $diskFree  = [math]::Round($disk.Free / 1GB, 2)

    $lines = @(
        "Sistema Operativo  : $($os.Caption)",
        "Version            : $($os.Version) ($($os.BuildNumber))",
        "Arquitectura       : $($os.OSArchitecture)",
        "Procesador         : $($cpu.Name.Trim())",
        "Nucleos / Logicos  : $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)",
        "Velocidad CPU      : $($cpu.MaxClockSpeed) MHz",
        "RAM Total          : $mem GB  |  Usada: $used GB  |  Libre: $free GB",
        "Disco C: Total     : $diskTotal GB  |  Libre: $diskFree GB  |  Usado: $([math]::Round($disk.Used/1GB,2)) GB",
        "Equipo             : $env:COMPUTERNAME  |  Usuario: $env:USERNAME",
        "BIOS               : $($bios.SMBIOSBIOSVersion)  |  Fabricante: $($bios.Manufacturer)",
        "Ultimo inicio      : $($os.LastBootUpTime)",
        "Uptime             : $([math]::Round(((Get-Date) - $os.LastBootUpTime).TotalHours,1)) horas",
        "",
        "--- RED ---"
    )
    $lines | ForEach-Object { $infoBox.AppendText("$_`r`n") }
    Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | ForEach-Object {
        $ip = (Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).IPAddress
        $infoBox.AppendText("  $($_.Name): $ip  |  $($_.LinkSpeed)`r`n")
    }
    $infoBox.AppendText("`r`n--- DISCOS ---`r`n")
    Get-PSDrive -PSProvider FileSystem | ForEach-Object {
        if ($_.Used -ne $null) {
            $tot = [math]::Round(($_.Used+$_.Free)/1GB,2)
            $fr  = [math]::Round($_.Free/1GB,2)
            $infoBox.AppendText("  Unidad $($_.Name):  Total $tot GB | Libre $fr GB`r`n")
        }
    }
    Write-Out "Informacion del sistema cargada." $cGreen
})
$pnlInfoBtns.Controls.Add($btnCargarInfo)

$btnUptime = New-CorporateButton "  Uptime" 215 8 140 34
$btnUptime.Add_Click({
    $boot = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
    $up   = (Get-Date) - $boot
    Write-Out "Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m  (desde $($boot.ToString('dd/MM/yyyy HH:mm')))" $cAccent2
})
$pnlInfoBtns.Controls.Add($btnUptime)

$btnWinUpdate = New-CorporateButton "  Windows Update" 365 8 175 34
$btnWinUpdate.Add_Click({ Start-Process ms-settings:windowsupdate })
$pnlInfoBtns.Controls.Add($btnWinUpdate)

$btnExportReport = New-CorporateButton "  Exportar Reporte" 550 8 180 34
$btnExportReport.Add_Click({
    $path = "$env:USERPROFILE\Desktop\SysCodi_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $os  = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor
    $report = @"
====================================================
 SysCodi WinTool Pro - Reporte del Sistema
 Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
====================================================
OS       : $($os.Caption) $($os.Version)
CPU      : $($cpu.Name.Trim())
Nucleos  : $($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)
RAM      : $([math]::Round($os.TotalVisibleMemorySize/1MB,2)) GB Total
Equipo   : $env:COMPUTERNAME
Usuario  : $env:USERNAME
Uptime   : $([math]::Round(((Get-Date)-$os.LastBootUpTime).TotalHours,1)) horas
====================================================
DISCOS:
$((Get-PSDrive -PSProvider FileSystem | Where-Object{$_.Used -ne $null} | ForEach-Object{"  $($_.Name): $([math]::Round(($_.Used+$_.Free)/1GB,2))GB total, $([math]::Round($_.Free/1GB,2))GB libre"}) -join "`n")
====================================================
RED:
$((Get-NetAdapter | Where-Object{$_.Status -eq 'Up'} | ForEach-Object{"  $($_.Name): $((Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).IPAddress)  $($_.LinkSpeed)"}) -join "`n")
====================================================
"@
    $report | Set-Content $path -Encoding UTF8
    Write-Out "Reporte guardado: $path" $cGreen
})
$pnlInfoBtns.Controls.Add($btnExportReport)

# Timer monitoreo en tiempo real (cada 2 seg)
$lastNetBytes = 0
$monitorTimer = New-Object Windows.Forms.Timer
$monitorTimer.Interval = 2000
$monitorTimer.Add_Tick({
    try {
        # CPU
        $cpuLoad = (Get-CimInstance Win32_Processor).LoadPercentage
        $cardCPU.val.Text = "$cpuLoad%"
        $cardCPU.bar.Value = [Math]::Min($cpuLoad, 100)
        $cardCPU.val.ForeColor = if ($cpuLoad -gt 85) { $cRed } elseif ($cpuLoad -gt 60) { $cYellow } else { $cGreen }

        # RAM
        $os2 = Get-CimInstance Win32_OperatingSystem
        $ramUsed = [math]::Round(($os2.TotalVisibleMemorySize - $os2.FreePhysicalMemory)/1MB,1)
        $ramTot  = [math]::Round($os2.TotalVisibleMemorySize/1MB,1)
        $ramPct  = [math]::Round(($ramUsed/$ramTot)*100)
        $cardRAM.val.Text = "$ramPct%"
        $cardRAM.bar.Value = [Math]::Min($ramPct, 100)
        $cardRAM.val.ForeColor = if ($ramPct -gt 85) { $cRed } elseif ($ramPct -gt 65) { $cYellow } else { $cAccent2 }

        # DISCO
        $drive = Get-PSDrive C
        $diskPct = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100)
        $cardDisk.val.Text = "$diskPct%"
        $cardDisk.bar.Value = [Math]::Min($diskPct, 100)
        $cardDisk.val.ForeColor = if ($diskPct -gt 90) { $cRed } elseif ($diskPct -gt 75) { $cYellow } else { $cAccent2 }

        # RED
        $netStat = Get-NetAdapterStatistics -EA SilentlyContinue | Select -First 1
        if ($netStat) {
            $totalBytes = $netStat.ReceivedBytes + $netStat.SentBytes
            $delta = [math]::Round(($totalBytes - $script:lastNetBytes) / 1KB / 2)
            $script:lastNetBytes = $totalBytes
            $cardNet.val.Text = "$delta KB/s"
            $cardNet.val.ForeColor = $cAccent2
        }

        # Top procesos
        $procs = Get-Process | Sort-Object CPU -Descending | Select -First 10
        $procBox.Clear()
        $procBox.SelectionColor = $cSubText
        $procBox.AppendText(("{0,-35} {1,8} {2,10}`r`n" -f "Proceso","CPU (s)","RAM (MB)"))
        $procBox.AppendText(("-" * 60 + "`r`n"))
        foreach ($p in $procs) {
            $procBox.SelectionColor = $cText
            $procBox.AppendText(("{0,-35} {1,8:N1} {2,10:N1}`r`n" -f $p.Name.Substring(0,[Math]::Min($p.Name.Length,34)), $p.CPU, ($p.WorkingSet64/1MB)))
        }
    } catch {}
})
$monitorTimer.Start()

# ============================================================
#   FOOTER
# ============================================================
$footer = New-Object Windows.Forms.Panel
$footer.Location  = New-Object Drawing.Point(0, 718)
$footer.Size      = New-Object Drawing.Size(1280, 26)
$footer.BackColor = $cPanel
$footer.Anchor    = "Bottom,Left,Right"
$form.Controls.Add($footer)

$lblFooter = New-Object Windows.Forms.Label
$lblFooter.Text      = "SysCodi WinTool Pro v2.0  |  Logs: C:\SysCodi\logs\  |  Ejecutar siempre como Administrador"
$lblFooter.Location  = New-Object Drawing.Point(0, 0)
$lblFooter.Size      = New-Object Drawing.Size(900, 26)
$lblFooter.TextAlign = "MiddleCenter"
$lblFooter.ForeColor = $cSubText
$lblFooter.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$footer.Controls.Add($lblFooter)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text      = "Listo"
$lblStatus.Location  = New-Object Drawing.Point(920, 0)
$lblStatus.Size      = New-Object Drawing.Size(340, 26)
$lblStatus.TextAlign = "MiddleRight"
$lblStatus.ForeColor = $cGreen
$lblStatus.Font      = New-Object Drawing.Font("Segoe UI", 7.5)
$footer.Controls.Add($lblStatus)

$btnClearOutput.Add_Click({ $outputBox.Clear(); Write-Out "Consola limpiada." $cSubText })

# ============================================================
#   INICIO
# ============================================================
Write-Out "SysCodi WinTool Pro v2.0 iniciado correctamente." $cGreen
Write-Out "Logs guardados en: $logFile" $cSubText
Write-Out "Sistema: $env:COMPUTERNAME  |  Usuario: $env:USERNAME" $cSubText
Write-Out "Fecha: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" $cSubText

$form.Add_FormClosing({
    $monitorTimer.Stop()
    $clockTimer.Stop()
    Write-Log "Aplicacion cerrada"
})

[Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog()
