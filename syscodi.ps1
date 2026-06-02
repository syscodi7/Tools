#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#   ADMIN CHECK
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $r = [Windows.Forms.MessageBox]::Show("Se recomienda ejecutar como Administrador para todas las funciones.`n`nContinuar de todas formas?", "SysEng Tool", "YesNo", "Warning")
    if ($r -eq "No") { exit }
}

# ============================================================
#   RUNSPACE POOL — sin congelamiento
# ============================================================
$script:Pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, 8)
$script:Pool.ApartmentState = "STA"
$script:Pool.Open()

function Run-BG([string]$Label, [scriptblock]$SB, [object[]]$Params) {
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.RunspacePool = $script:Pool
    $ps.AddScript($SB) | Out-Null
    if ($Params) { foreach ($p in $Params) { $ps.AddArgument($p) | Out-Null } }
    $handle = $ps.BeginInvoke()
    Out-Con "> Ejecutando: $Label..." $cSub
    $pb.Style = "Marquee"; $pb.MarqueeAnimationSpeed = 25
    $lbl2 = $Label; $ps2 = $ps; $h2 = $handle
    $t = New-Object Windows.Forms.Timer; $t.Interval = 350
    $t.Add_Tick({
        if ($h2.IsCompleted) {
            $t.Stop()
            $pb.MarqueeAnimationSpeed = 0
            try {
                $out = $ps2.EndInvoke($h2)
                $txt = ($out | Where-Object {$_ -ne $null} | ForEach-Object {$_.ToString().Trim()} | Where-Object {$_}) -join "`r`n  "
                if ($txt) { Out-Con "  $txt" $cText }
                foreach ($e in $ps2.Streams.Error) { Out-Con "  [ERROR] $e" $cRed }
            } catch {}
            $ps2.Dispose()
            Out-Con "[OK] $lbl2`r`n" $cGreen
        }
    })
    $t.Start()
}

# ============================================================
#   COLORES
# ============================================================
$cBg     = [Drawing.Color]::FromArgb(13, 22, 45)
$cPanel  = [Drawing.Color]::FromArgb(18, 32, 65)
$cCard   = [Drawing.Color]::FromArgb(22, 40, 82)
$cHov    = [Drawing.Color]::FromArgb(28, 52, 105)
$cAccent = [Drawing.Color]::FromArgb(0, 140, 255)
$cAcc2   = [Drawing.Color]::FromArgb(70, 175, 255)
$cGreen  = [Drawing.Color]::FromArgb(35, 215, 110)
$cYellow = [Drawing.Color]::FromArgb(255, 190, 40)
$cRed    = [Drawing.Color]::FromArgb(255, 70, 70)
$cText   = [Drawing.Color]::White
$cSub    = [Drawing.Color]::FromArgb(145, 180, 230)
$cBorder = [Drawing.Color]::FromArgb(28, 60, 125)
$cOut    = [Drawing.Color]::FromArgb(7, 14, 32)

# ============================================================
#   FORMULARIO
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text            = "SysEng Tool — Ingeniero de Sistemas"
$form.Size            = New-Object Drawing.Size(1300, 820)
$form.MinimumSize     = New-Object Drawing.Size(1100, 700)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.Font            = New-Object Drawing.Font("Segoe UI", 9)

# ============================================================
#   HEADER
# ============================================================
$pHead = New-Object Windows.Forms.Panel
$pHead.Dock = "Top"; $pHead.Height = 70; $pHead.BackColor = $cPanel
$form.Controls.Add($pHead)

$lTitle = New-Object Windows.Forms.Label
$lTitle.Text = "SysEng Tool"; $lTitle.Location = New-Object Drawing.Point(16,8)
$lTitle.Size = New-Object Drawing.Size(300,30)
$lTitle.Font = New-Object Drawing.Font("Segoe UI",18,[Drawing.FontStyle]::Bold)
$lTitle.ForeColor = $cAcc2; $lTitle.BackColor = [Drawing.Color]::Transparent
$pHead.Controls.Add($lTitle)

$lSub2 = New-Object Windows.Forms.Label
$lSub2.Text = "Herramienta avanzada para Ingenieros de Sistemas — Red | Sistema | Seguridad"
$lSub2.Location = New-Object Drawing.Point(16,42); $lSub2.Size = New-Object Drawing.Size(700,20)
$lSub2.Font = New-Object Drawing.Font("Segoe UI",8.5); $lSub2.ForeColor = $cSub
$lSub2.BackColor = [Drawing.Color]::Transparent; $pHead.Controls.Add($lSub2)

# Info sistema header derecha
$lblAdmin = New-Object Windows.Forms.Label
$lblAdmin.Text = if ($isAdmin) { "  ADMIN  " } else { "  SIN ADMIN  " }
$lblAdmin.Location = New-Object Drawing.Point(1100, 22); $lblAdmin.Size = New-Object Drawing.Size(95, 24)
$lblAdmin.ForeColor = if ($isAdmin) { $cGreen } else { $cYellow }
$lblAdmin.BackColor = [Drawing.Color]::FromArgb(0,40,15)
$lblAdmin.Font = New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$lblAdmin.TextAlign = "MiddleCenter"; $lblAdmin.BorderStyle = "FixedSingle"
$pHead.Controls.Add($lblAdmin)

$lblClock2 = New-Object Windows.Forms.Label
$lblClock2.Location = New-Object Drawing.Point(960,24); $lblClock2.Size = New-Object Drawing.Size(135,20)
$lblClock2.ForeColor = $cSub; $lblClock2.Font = New-Object Drawing.Font("Consolas",8.5)
$lblClock2.BackColor = [Drawing.Color]::Transparent; $pHead.Controls.Add($lblClock2)
$pHead.Controls.Add((New-Object Windows.Forms.Panel -Property @{Dock="Bottom";Height=1;BackColor=$cBorder}))

$ck = New-Object Windows.Forms.Timer; $ck.Interval = 1000
$ck.Add_Tick({ $lblClock2.Text = Get-Date -Format "HH:mm:ss  dd/MM/yyyy" })
$ck.Start()

# ============================================================
#   TABS BAR
# ============================================================
$pTabs2 = New-Object Windows.Forms.Panel
$pTabs2.Dock = "Top"; $pTabs2.Height = 48; $pTabs2.BackColor = $cPanel
$form.Controls.Add($pTabs2)
$pTabs2.Controls.Add((New-Object Windows.Forms.Panel -Property @{Dock="Bottom";Height=2;BackColor=$cAccent}))

# ============================================================
#   LAYOUT PRINCIPAL
# ============================================================
$pBody = New-Object Windows.Forms.Panel
$pBody.Dock = "Fill"; $pBody.BackColor = $cBg
$form.Controls.Add($pBody)

# Consola derecha
$pRight = New-Object Windows.Forms.Panel
$pRight.Width = 440; $pRight.Dock = "Right"; $pRight.BackColor = $cOut
$pBody.Controls.Add($pRight)

$pRHead = New-Object Windows.Forms.Panel
$pRHead.Dock = "Top"; $pRHead.Height = 36; $pRHead.BackColor = $cPanel
$pRight.Controls.Add($pRHead)

$lRTitle = New-Object Windows.Forms.Label
$lRTitle.Text = "  Consola de salida"; $lRTitle.Dock = "Left"; $lRTitle.Width = 240
$lRTitle.ForeColor = $cAcc2; $lRTitle.Font = New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$lRTitle.TextAlign = "MiddleLeft"; $pRHead.Controls.Add($lRTitle)

$bClear = New-Object Windows.Forms.Button
$bClear.Text = "Limpiar"; $bClear.Dock = "Right"; $bClear.Width = 80
$bClear.BackColor = [Drawing.Color]::FromArgb(0,55,110); $bClear.ForeColor = $cText
$bClear.FlatStyle = "Flat"; $bClear.FlatAppearance.BorderSize = 0
$bClear.Font = New-Object Drawing.Font("Segoe UI",8)
$bClear.Add_Click({ $rtb.Clear(); Out-Con "Consola limpiada.`r`n" $cSub })
$pRHead.Controls.Add($bClear)

$bCopy2 = New-Object Windows.Forms.Button
$bCopy2.Text = "Copiar"; $bCopy2.Dock = "Right"; $bCopy2.Width = 75
$bCopy2.BackColor = [Drawing.Color]::FromArgb(0,55,110); $bCopy2.ForeColor = $cText
$bCopy2.FlatStyle = "Flat"; $bCopy2.FlatAppearance.BorderSize = 0
$bCopy2.Font = New-Object Drawing.Font("Segoe UI",8)
$bCopy2.Add_Click({ [Windows.Forms.Clipboard]::SetText($rtb.Text); Out-Con "Texto copiado." $cGreen })
$pRHead.Controls.Add($bCopy2)

$rtb = New-Object Windows.Forms.RichTextBox
$rtb.Dock = "Fill"; $rtb.BackColor = $cOut; $rtb.ForeColor = $cAcc2
$rtb.Font = New-Object Drawing.Font("Consolas",8.5); $rtb.ReadOnly = $true
$rtb.BorderStyle = "None"; $rtb.ScrollBars = "Vertical"
$pRight.Controls.Add($rtb)

function Out-Con($msg, $color) {
    if (-not $color) { $color = $cAcc2 }
    $rtb.SelectionStart = $rtb.TextLength
    $rtb.SelectionColor = $color
    $rtb.AppendText("$msg`r`n")
    $rtb.ScrollToCaret()
}

# Barra progreso
$pb = New-Object Windows.Forms.ProgressBar
$pb.Dock = "Top"; $pb.Height = 4; $pb.Style = "Marquee"
$pb.MarqueeAnimationSpeed = 0; $pBody.Controls.Add($pb)

# Area contenido
$pLeft = New-Object Windows.Forms.Panel
$pLeft.Dock = "Fill"; $pLeft.BackColor = $cBg; $pBody.Controls.Add($pLeft)

# ============================================================
#   HELPERS
# ============================================================
function New-Btn2($txt,$x,$y,$w,$h,$par,$tip="") {
    $b = New-Object Windows.Forms.Button
    $b.Text = $txt; $b.Location = New-Object Drawing.Point($x,$y)
    $b.Size = New-Object Drawing.Size($w,$h)
    $b.BackColor = $cCard; $b.ForeColor = $cText
    $b.FlatStyle = "Flat"; $b.FlatAppearance.BorderColor = $cBorder
    $b.FlatAppearance.BorderSize = 1
    $b.Font = New-Object Drawing.Font("Segoe UI",8.5)
    $b.Cursor = "Hand"; $b.TextAlign = "MiddleCenter"
    if ($tip) {
        $tt = New-Object Windows.Forms.ToolTip
        $tt.SetToolTip($b, $tip)
    }
    $b.Add_MouseEnter({ $this.BackColor = $cHov; $this.FlatAppearance.BorderColor = $cAccent })
    $b.Add_MouseLeave({ $this.BackColor = $cCard; $this.FlatAppearance.BorderColor = $cBorder })
    $par.Controls.Add($b); return $b
}

function New-Sec2($txt,$x,$y,$par) {
    $l = New-Object Windows.Forms.Label
    $l.Text = "  $txt"; $l.Location = New-Object Drawing.Point($x,$y)
    $l.Size = New-Object Drawing.Size(820,24)
    $l.ForeColor = $cAcc2; $l.BackColor = [Drawing.Color]::FromArgb(14,28,60)
    $l.Font = New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $l.TextAlign = "MiddleLeft"; $par.Controls.Add($l); return $l
}

function New-Input($placeholder,$x,$y,$w,$par) {
    $t = New-Object Windows.Forms.TextBox
    $t.Location = New-Object Drawing.Point($x,$y); $t.Size = New-Object Drawing.Size($w,26)
    $t.BackColor = [Drawing.Color]::FromArgb(13,24,52); $t.ForeColor = $cText
    $t.BorderStyle = "FixedSingle"; $t.Font = New-Object Drawing.Font("Consolas",9)
    $t.Text = $placeholder; $par.Controls.Add($t); return $t
}

function New-ScrollP2($par) {
    $p = New-Object Windows.Forms.Panel; $p.Dock = "Fill"; $p.AutoScroll = $true
    $p.BackColor = $cBg; $par.Controls.Add($p); return $p
}

# ============================================================
#   SISTEMA DE TABS
# ============================================================
$tabs2  = @("Red","Sistema","Seguridad","Herramientas","Info Rapida")
$tBtns2 = @(); $tPnls  = @(); $script:tab2 = 0; $tx2 = 6

foreach ($td in $tabs2) {
    $tb = New-Object Windows.Forms.Button
    $tb.Text = $td; $tb.Location = New-Object Drawing.Point($tx2,7)
    $tb.Size = New-Object Drawing.Size(148,34)
    $tb.BackColor = $cPanel; $tb.ForeColor = $cSub
    $tb.FlatStyle = "Flat"; $tb.FlatAppearance.BorderSize = 0
    $tb.Font = New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $tb.Cursor = "Hand"; $pTabs2.Controls.Add($tb); $tBtns2 += $tb; $tx2 += 152
    $tp = New-Object Windows.Forms.Panel; $tp.Dock = "Fill"; $tp.BackColor = $cBg
    $tp.Visible = $false; $pLeft.Controls.Add($tp); $tPnls += $tp
}

function Go-Tab($i) {
    for ($j = 0; $j -lt $tBtns2.Count; $j++) {
        if ($j -eq $i) { $tBtns2[$j].BackColor=[Drawing.Color]::FromArgb(16,38,80);$tBtns2[$j].ForeColor=$cAcc2;$tPnls[$j].Visible=$true;$tPnls[$j].BringToFront() }
        else { $tBtns2[$j].BackColor=$cPanel;$tBtns2[$j].ForeColor=$cSub;$tPnls[$j].Visible=$false }
    }
    $script:tab2 = $i
}
for ($i=0;$i -lt $tBtns2.Count;$i++){$idx=$i;$tBtns2[$i].Add_Click({Go-Tab $idx})}

# ============================================================
#   TAB 0: RED
# ============================================================
$scrRed = New-ScrollP2 $tPnls[0]
$yN = 6

# --- Ping ---
New-Sec2 "Ping" 6 $yN $scrRed | Out-Null; $yN += 28
$inPing = New-Input "8.8.8.8" 6 $yN 220 $scrRed
$inCount = New-Input "4" 232 $yN 60 $scrRed
$lCount = New-Object Windows.Forms.Label; $lCount.Text="paquetes"; $lCount.Location=New-Object Drawing.Point(298,$yN+4); $lCount.Size=New-Object Drawing.Size(70,18); $lCount.ForeColor=$cSub; $scrRed.Controls.Add($lCount)
$bPing = New-Btn2 "Ping" 376 $yN 100 26 $scrRed "Enviar ping al host"
$bPingC = New-Btn2 "Ping Continuo" 482 $yN 130 26 $scrRed "Ping -t (ctrl+c para detener)"
$bPingC.Add_Click({ $h=$inPing.Text.Trim(); if($h){Run-BG "Ping continuo $h" {param($t);ping -t $t} @($h)} })
$bPing.Add_Click({
    $h=$inPing.Text.Trim(); $c=$inCount.Text.Trim(); if(-not $h){Out-Con "Ingresa un host." $cYellow;return}
    Run-BG "Ping $h" { param($host2,$cnt); ping -n $cnt $host2 } @($h, $c)
})
$yN += 32

# Traceroute
New-Sec2 "Traceroute" 6 $yN $scrRed | Out-Null; $yN += 28
$inTrace = New-Input "google.com" 6 $yN 220 $scrRed
$bTrace = New-Btn2 "Traceroute" 232 $yN 120 26 $scrRed "Rastrear ruta hasta el destino"
$bTrace.Add_Click({ $h=$inTrace.Text.Trim();if($h){Run-BG "Tracert $h" {param($t);tracert $t} @($h)} })
$bPathPing = New-Btn2 "PathPing" 358 $yN 120 26 $scrRed "Analisis de ruta con estadisticas"
$bPathPing.Add_Click({ $h=$inTrace.Text.Trim();if($h){Run-BG "PathPing $h" {param($t);pathping $t} @($h)} })
$yN += 32

# DNS
New-Sec2 "DNS" 6 $yN $scrRed | Out-Null; $yN += 28
$inDNS = New-Input "google.com" 6 $yN 220 $scrRed
$inDNSSrv = New-Input "8.8.8.8 (servidor DNS)" 232 $yN 220 $scrRed
$bNS = New-Btn2 "nslookup" 458 $yN 110 26 $scrRed "Consulta DNS"
$bNS.Add_Click({
    $d=$inDNS.Text.Trim();$s=$inDNSSrv.Text.Trim().Replace(" (servidor DNS)","")
    if($d){Run-BG "nslookup $d" {param($dom,$srv);if($srv -and $srv -ne "8.8.8.8"){nslookup $dom $srv}else{nslookup $dom}} @($d,$s)}
})
$bFlush = New-Btn2 "Flush DNS" 574 $yN 110 26 $scrRed "Vaciar cache DNS"
$bFlush.Add_Click({ Run-BG "Flush DNS" { ipconfig /flushdns } })
$bDNSCache = New-Btn2 "Ver Cache DNS" 690 $yN 120 26 $scrRed "Mostrar cache DNS local"
$bDNSCache.Add_Click({ Run-BG "Cache DNS" { Get-DnsClientCache | Select-Object Entry,RecordType,TimeToLive,Data | Format-Table -AutoSize } })
$yN += 32

# Escaner de puertos
New-Sec2 "Escaner de Puertos" 6 $yN $scrRed | Out-Null; $yN += 28
$inPortHost = New-Input "192.168.1.1" 6 $yN 200 $scrRed
$inPortStart = New-Input "1" 212 $yN 70 $scrRed
$lGuion = New-Object Windows.Forms.Label; $lGuion.Text="-"; $lGuion.Location=New-Object Drawing.Point(288,$yN+4); $lGuion.Size=New-Object Drawing.Size(12,18); $lGuion.ForeColor=$cSub; $scrRed.Controls.Add($lGuion)
$inPortEnd = New-Input "1024" 304 $yN 70 $scrRed
$bScanPort = New-Btn2 "Escanear Puertos" 380 $yN 160 26 $scrRed "Escanea puertos TCP en el rango dado"
$bScanPort.Add_Click({
    $h=$inPortHost.Text.Trim();$ps=[int]$inPortStart.Text;$pe=[int]$inPortEnd.Text
    if(-not $h){Out-Con "Ingresa un host." $cYellow;return}
    if(($pe-$ps) -gt 500){Out-Con "Rango maximo: 500 puertos por escaneo." $cYellow;return}
    Run-BG "Escaneo puertos $h ($ps-$pe)" {
        param($host2,$pStart,$pEnd)
        $open = @()
        for ($port=$pStart;$port -le $pEnd;$port++) {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $conn = $tcp.BeginConnect($host2,$port,$null,$null)
            $wait = $conn.AsyncWaitHandle.WaitOne(150,$false)
            if ($wait -and -not $tcp.Client.Connected -eq $false) {
                try { $tcp.EndConnect($conn); $open += $port } catch {}
            }
            $tcp.Close()
        }
        if ($open.Count -eq 0) { "Sin puertos abiertos en $host2 ($pStart-$pEnd)" }
        else { "Puertos abiertos en ${host2}:`r`n" + ($open -join ", ") }
    } @($h,$ps,$pe)
})
$yN += 32

# Info red
New-Sec2 "Informacion de Red" 6 $yN $scrRed | Out-Null; $yN += 28
$bIPConf = New-Btn2 "ipconfig /all" 6 $yN 150 42 $scrRed "Toda la info de interfaces"
$bIPConf.Add_Click({ Run-BG "ipconfig /all" { ipconfig /all } })
$bAdapt = New-Btn2 "Adaptadores" 162 $yN 150 42 $scrRed "Estado de adaptadores de red"
$bAdapt.Add_Click({ Run-BG "Adaptadores" { Get-NetAdapter | Select-Object Name,Status,LinkSpeed,MacAddress | Format-Table -AutoSize } })
$bConexiones = New-Btn2 "Conexiones TCP" 318 $yN 150 42 $scrRed "Conexiones TCP activas"
$bConexiones.Add_Click({ Run-BG "Conexiones TCP" { Get-NetTCPConnection -State Established | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort,OwningProcess | Sort-Object LocalPort | Format-Table -AutoSize } })
$bRoutes = New-Btn2 "Tabla de rutas" 474 $yN 150 42 $scrRed "Tabla de enrutamiento"
$bRoutes.Add_Click({ Run-BG "Tabla rutas" { route print } })
$bArp = New-Btn2 "Tabla ARP" 630 $yN 130 42 $scrRed "Cache ARP local"
$bArp.Add_Click({ Run-BG "ARP" { arp -a } })
$yN += 50

# Reset red
New-Sec2 "Reparacion de Red" 6 $yN $scrRed | Out-Null; $yN += 28
$bResetTCP = New-Btn2 "Reset TCP/IP" 6 $yN 150 42 $scrRed "Reinicia la pila TCP/IP"
$bResetTCP.Add_Click({ Run-BG "Reset TCP/IP" { netsh int ip reset; "TCP/IP reseteado. Reinicia para aplicar." } })
$bResetWS = New-Btn2 "Reset Winsock" 162 $yN 150 42 $scrRed "Reinicia Winsock"
$bResetWS.Add_Click({ Run-BG "Reset Winsock" { netsh winsock reset; "Winsock reseteado. Reinicia para aplicar." } })
$bRenewIP = New-Btn2 "Renovar IP" 318 $yN 150 42 $scrRed "Release + Renew DHCP"
$bRenewIP.Add_Click({ Run-BG "Renovar IP" { ipconfig /release; ipconfig /renew } })
$bNetDiag = New-Btn2 "Diagnostico Red" 474 $yN 150 42 $scrRed "msdt.exe diagnostico"
$bNetDiag.Add_Click({ Start-Process "msdt.exe" -ArgumentList "/id NetworkDiagnosticsNetworkAdapter" })
$bWifiScan = New-Btn2 "Redes WiFi" 630 $yN 130 42 $scrRed "Escanear redes WiFi cercanas"
$bWifiScan.Add_Click({ Run-BG "Redes WiFi" { netsh wlan show networks mode=bssid } })
$yN += 52

$scrRed.AutoScrollMinSize = New-Object Drawing.Size(840,($yN+20))

# ============================================================
#   TAB 1: SISTEMA
# ============================================================
$scrSys = New-ScrollP2 $tPnls[1]
$yS = 6

New-Sec2 "CPU y Procesos" 6 $yS $scrSys | Out-Null; $yS += 28
$bCPUInfo = New-Btn2 "Info CPU" 6 $yS 145 42 $scrSys "Informacion detallada del procesador"
$bCPUInfo.Add_Click({ Run-BG "Info CPU" { Get-CimInstance Win32_Processor | Select-Object Name,NumberOfCores,NumberOfLogicalProcessors,MaxClockSpeed,LoadPercentage,Architecture | Format-List } })
$bTopCPU = New-Btn2 "Top 20 CPU" 157 $yS 145 42 $scrSys "Procesos que mas CPU consumen"
$bTopCPU.Add_Click({ Run-BG "Top 20 CPU" { Get-Process | Sort-Object CPU -Descending | Select-Object -First 20 Name,Id,CPU,@{n="RAM MB";e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize } })
$bTopRAM = New-Btn2 "Top 20 RAM" 308 $yS 145 42 $scrSys "Procesos que mas RAM consumen"
$bTopRAM.Add_Click({ Run-BG "Top 20 RAM" { Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 20 Name,Id,@{n="RAM MB";e={[math]::Round($_.WorkingSet64/1MB,1)}},CPU | Format-Table -AutoSize } })
$inProcKill = New-Input "PID o Nombre" 459 ($yS+8) 160 $scrSys
$bKill = New-Btn2 "Terminar Proceso" 625 $yS 160 42 $scrSys "Termina un proceso por nombre o PID"
$bKill.Add_Click({
    $v=$inProcKill.Text.Trim()
    if(-not $v){Out-Con "Ingresa PID o nombre." $cYellow;return}
    $r=[Windows.Forms.MessageBox]::Show("Terminar proceso: $v ?","Confirmar","YesNo","Warning")
    if($r -eq "Yes"){
        Run-BG "Terminar $v" {
            param($target)
            if ($target -match "^\d+$") { Stop-Process -Id ([int]$target) -Force -EA SilentlyContinue; "Proceso PID $target terminado." }
            else { Stop-Process -Name $target -Force -EA SilentlyContinue; "Proceso '$target' terminado." }
        } @($v)
    }
})
$yS += 50

New-Sec2 "Memoria RAM" 6 $yS $scrSys | Out-Null; $yS += 28
$bRAMInfo = New-Btn2 "Info RAM Fisica" 6 $yS 145 42 $scrSys "Fabricante, velocidad, capacidad"
$bRAMInfo.Add_Click({ Run-BG "Info RAM" { Get-CimInstance Win32_PhysicalMemory | Select-Object BankLabel,Manufacturer,Speed,@{n="GB";e={[math]::Round($_.Capacity/1GB,1)}},MemoryType | Format-Table -AutoSize } })
$bRAMUso = New-Btn2 "Uso RAM Actual" 157 $yS 145 42 $scrSys "RAM usada / libre ahora mismo"
$bRAMUso.Add_Click({
    Run-BG "Uso RAM" {
        $os=Get-CimInstance Win32_OperatingSystem
        $total=[math]::Round($os.TotalVisibleMemorySize/1MB,2)
        $libre=[math]::Round($os.FreePhysicalMemory/1MB,2)
        $usada=[math]::Round($total-$libre,2)
        $pct=[math]::Round(($usada/$total)*100,1)
        "RAM Total:  $total GB"
        "RAM Usada:  $usada GB ($pct%)"
        "RAM Libre:  $libre GB"
    }
})
$bVMem = New-Btn2 "Memoria Virtual" 308 $yS 145 42 $scrSys "Informacion de memoria virtual"
$bVMem.Add_Click({ Run-BG "Memoria Virtual" { Get-CimInstance Win32_OperatingSystem | Select-Object TotalVirtualMemorySize,FreeVirtualMemory,SizeStoredInPagingFiles | Format-List } })
$bLiberarRAM = New-Btn2 "Liberar RAM (GC)" 459 $yS 145 42 $scrSys "Fuerza recoleccion de basura .NET"
$bLiberarRAM.Add_Click({ Run-BG "Liberar RAM" { [System.GC]::Collect();[System.GC]::WaitForPendingFinalizers();[System.GC]::Collect();"GC ejecutado correctamente." } })
$yS += 50

New-Sec2 "Disco y Almacenamiento" 6 $yS $scrSys | Out-Null; $yS += 28
$bDiscos = New-Btn2 "Info Discos" 6 $yS 145 42 $scrSys "Espacio libre y usado por unidad"
$bDiscos.Add_Click({ Run-BG "Info Discos" { Get-PSDrive -PSProvider FileSystem | Select-Object Name,@{n="Total GB";e={[math]::Round(($_.Used+$_.Free)/1GB,2)}},@{n="Libre GB";e={[math]::Round($_.Free/1GB,2)}},@{n="Uso %";e={[math]::Round($_.Used/($_.Used+$_.Free)*100,1)}} | Format-Table -AutoSize } })
$bSMART = New-Btn2 "Estado SMART" 157 $yS 145 42 $scrSys "Estado de salud de los discos fisicos"
$bSMART.Add_Click({ Run-BG "Estado SMART" { wmic diskdrive get Status,Model,Size,InterfaceType } })
$bDiskPart = New-Btn2 "Particiones" 308 $yS 145 42 $scrSys "Lista particiones del sistema"
$bDiskPart.Add_Click({ Run-BG "Particiones" { Get-Partition | Select-Object DiskNumber,PartitionNumber,DriveLetter,@{n="GB";e={[math]::Round($_.Size/1GB,1)}},Type | Format-Table -AutoSize } })
$bTemp = New-Btn2 "Archivos Temp" 459 $yS 145 42 $scrSys "Tamano de carpetas temporales"
$bTemp.Add_Click({
    Run-BG "Archivos Temp" {
        $t1=(Get-ChildItem $env:TEMP -Recurse -EA SilentlyContinue|Measure-Object Length -Sum).Sum
        $t2=(Get-ChildItem "C:\Windows\Temp" -Recurse -EA SilentlyContinue|Measure-Object Length -Sum).Sum
        "Temp usuario:    $([math]::Round($t1/1MB,1)) MB"
        "Temp Windows:    $([math]::Round($t2/1MB,1)) MB"
        "Total:           $([math]::Round(($t1+$t2)/1MB,1)) MB"
    }
})
$bLimpTemp = New-Btn2 "Limpiar Temporales" 610 $yS 170 42 $scrSys "Elimina archivos temporales"
$bLimpTemp.Add_Click({ Run-BG "Limpiar Temporales" { Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue;"Temporales eliminados." } })
$yS += 50

New-Sec2 "Servicios" 6 $yS $scrSys | Out-Null; $yS += 28
$bSvcAll = New-Btn2 "Servicios Activos" 6 $yS 155 42 $scrSys "Servicios en ejecucion"
$bSvcAll.Add_Click({ Run-BG "Servicios activos" { Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object DisplayName,Name,Status | Sort-Object DisplayName | Format-Table -AutoSize } })
$bSvcStop = New-Btn2 "Servicios Detenidos" 167 $yS 155 42 $scrSys "Servicios parados"
$bSvcStop.Add_Click({ Run-BG "Servicios detenidos" { Get-Service | Where-Object {$_.Status -eq "Stopped"} | Select-Object DisplayName,Name,StartType | Sort-Object DisplayName | Format-Table -AutoSize } })
$inSvcName = New-Input "Nombre del servicio" 328 ($yS+8) 170 $scrSys
$bSvcStart = New-Btn2 "Iniciar" 504 $yS 85 42 $scrSys "Iniciar servicio"
$bSvcStart.Add_Click({ $n=$inSvcName.Text.Trim();if($n){Run-BG "Iniciar $n" {param($s);Start-Service $s -EA SilentlyContinue;"Servicio '$s' iniciado."} @($n)} })
$bSvcStop2 = New-Btn2 "Detener" 595 $yS 85 42 $scrSys "Detener servicio"
$bSvcStop2.Add_Click({ $n=$inSvcName.Text.Trim();if($n){Run-BG "Detener $n" {param($s);Stop-Service $s -Force -EA SilentlyContinue;"Servicio '$s' detenido."} @($n)} })
$bSvcStatus = New-Btn2 "Estado" 686 $yS 85 42 $scrSys "Ver estado de un servicio"
$bSvcStatus.Add_Click({ $n=$inSvcName.Text.Trim();if($n){Run-BG "Estado $n" {param($s);Get-Service $s -EA SilentlyContinue | Select-Object DisplayName,Status,StartType | Format-List} @($n)} })
$yS += 50

New-Sec2 "Sistema Operativo" 6 $yS $scrSys | Out-Null; $yS += 28
$bOSInfo = New-Btn2 "Info OS" 6 $yS 145 42 $scrSys "Version, build, arquitectura"
$bOSInfo.Add_Click({ Run-BG "Info OS" { $os=Get-CimInstance Win32_OperatingSystem; "OS:          $($os.Caption)"; "Version:     $($os.Version)"; "Build:       $($os.BuildNumber)"; "Arquitectura:$($os.OSArchitecture)"; "Instalado:   $($os.InstallDate)"; "Ultimo boot: $($os.LastBootUpTime)"; "Uptime:      $([math]::Round(((Get-Date)-$os.LastBootUpTime).TotalHours,1)) horas" } })
$bBIOS = New-Btn2 "Info BIOS" 157 $yS 145 42 $scrSys "Fabricante y version del BIOS"
$bBIOS.Add_Click({ Run-BG "Info BIOS" { Get-CimInstance Win32_BIOS | Select-Object Manufacturer,SMBIOSBIOSVersion,ReleaseDate,SerialNumber | Format-List } })
$bPlaca = New-Btn2 "Placa Base" 308 $yS 145 42 $scrSys "Informacion de la placa madre"
$bPlaca.Add_Click({ Run-BG "Placa Base" { Get-CimInstance Win32_BaseBoard | Select-Object Manufacturer,Product,SerialNumber,Version | Format-List } })
$bDrivers = New-Btn2 "Drivers con Error" 459 $yS 145 42 $scrSys "Drivers con problemas"
$bDrivers.Add_Click({ Run-BG "Drivers con error" { Get-WmiObject Win32_PnPEntity | Where-Object {$_.ConfigManagerErrorCode -ne 0} | Select-Object Name,ConfigManagerErrorCode | Format-Table -AutoSize } })
$bUptime2 = New-Btn2 "Uptime" 610 $yS 120 42 $scrSys "Tiempo encendido del sistema"
$bUptime2.Add_Click({ $up=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime; Out-Con "Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m $($up.Seconds)s" $cAcc2 })
$yS += 52

$scrSys.AutoScrollMinSize = New-Object Drawing.Size(840,($yS+20))

# ============================================================
#   TAB 2: SEGURIDAD
# ============================================================
$scrSeg = New-ScrollP2 $tPnls[2]
$ySeg = 6

New-Sec2 "Firewall" 6 $ySeg $scrSeg | Out-Null; $ySeg += 28
$bFWStatus = New-Btn2 "Estado Firewall" 6 $ySeg 160 42 $scrSeg "Perfil activo del firewall"
$bFWStatus.Add_Click({ Run-BG "Estado Firewall" { netsh advfirewall show allprofiles } })
$bFWRules = New-Btn2 "Reglas Activas" 172 $ySeg 160 42 $scrSeg "Reglas habilitadas del firewall"
$bFWRules.Add_Click({ Run-BG "Reglas Firewall" { Get-NetFirewallRule | Where-Object {$_.Enabled -eq "True"} | Select-Object DisplayName,Direction,Action,Profile | Sort-Object Direction | Format-Table -AutoSize } })
$bFWReset = New-Btn2 "Reset Firewall" 338 $ySeg 155 42 $scrSeg "Restablecer firewall a valores predeterminados"
$bFWReset.Add_Click({
    $r=[Windows.Forms.MessageBox]::Show("Resetear el firewall a configuracion predeterminada?","Firewall Reset","YesNo","Warning")
    if($r -eq "Yes"){Run-BG "Reset Firewall" {netsh advfirewall reset;"Firewall reseteado."}}
})
$bFWOn = New-Btn2 "Activar Firewall" 499 $ySeg 145 42 $scrSeg "Habilita el firewall en todos los perfiles"
$bFWOn.Add_Click({ Run-BG "Activar Firewall" { netsh advfirewall set allprofiles state on; "Firewall activado." } })
$bFWOff = New-Btn2 "Desactivar FW" 650 $ySeg 145 42 $scrSeg "Deshabilita el firewall (PRECAUCION)"
$bFWOff.Add_Click({
    $r=[Windows.Forms.MessageBox]::Show("ATENCION: Desactivar el firewall expone el sistema.`nContinuar?","Seguridad","YesNo","Warning")
    if($r -eq "Yes"){Run-BG "Desactivar Firewall" {netsh advfirewall set allprofiles state off;"Firewall DESACTIVADO."}}
})
$ySeg += 50

New-Sec2 "Usuarios y Sesiones" 6 $ySeg $scrSeg | Out-Null; $ySeg += 28
$bUsersLocal = New-Btn2 "Usuarios Locales" 6 $ySeg 155 42 $scrSeg "Lista de usuarios locales del sistema"
$bUsersLocal.Add_Click({ Run-BG "Usuarios locales" { Get-LocalUser | Select-Object Name,Enabled,LastLogon,Description | Format-Table -AutoSize } })
$bGroups = New-Btn2 "Grupos Locales" 167 $ySeg 155 42 $scrSeg "Grupos de usuarios locales"
$bGroups.Add_Click({ Run-BG "Grupos locales" { Get-LocalGroup | Select-Object Name,Description | Format-Table -AutoSize } })
$bAdmins = New-Btn2 "Miembros Admin" 328 $ySeg 155 42 $scrSeg "Usuarios en el grupo Administradores"
$bAdmins.Add_Click({ Run-BG "Miembros Administradores" { Get-LocalGroupMember -Group "Administrators" | Select-Object Name,ObjectClass,PrincipalSource | Format-Table -AutoSize } })
$bSessions = New-Btn2 "Sesiones Activas" 489 $ySeg 155 42 $scrSeg "Sesiones RDP o locales activas"
$bSessions.Add_Click({ Run-BG "Sesiones activas" { query session 2>&1 } })
$bLogonH = New-Btn2 "Historial Logon" 650 $ySeg 145 42 $scrSeg "Ultimos eventos de inicio de sesion"
$bLogonH.Add_Click({ Run-BG "Historial logon" { Get-EventLog Security -InstanceId 4624 -Newest 20 -EA SilentlyContinue | Select-Object TimeGenerated,Message | Format-Table -AutoSize -Wrap } })
$ySeg += 50

New-Sec2 "Puertos y Conexiones" 6 $ySeg $scrSeg | Out-Null; $ySeg += 28
$bPuertosAb = New-Btn2 "Puertos Abiertos" 6 $ySeg 155 42 $scrSeg "Todos los puertos en escucha"
$bPuertosAb.Add_Click({ Run-BG "Puertos abiertos" { Get-NetTCPConnection -State Listen | Select-Object LocalAddress,LocalPort,OwningProcess,@{n="Proceso";e={(Get-Process -Id $_.OwningProcess -EA SilentlyContinue).Name}} | Sort-Object LocalPort | Format-Table -AutoSize } })
$bConExt = New-Btn2 "Conexiones Ext." 167 $ySeg 155 42 $scrSeg "Conexiones a IPs externas"
$bConExt.Add_Click({
    Run-BG "Conexiones externas" {
        Get-NetTCPConnection -State Established | Where-Object {$_.RemoteAddress -notmatch "^(127|10|172|192\.168|::1|0\.0)"} |
        Select-Object LocalPort,RemoteAddress,RemotePort,OwningProcess,@{n="Proceso";e={(Get-Process -Id $_.OwningProcess -EA SilentlyContinue).Name}} |
        Sort-Object RemoteAddress | Format-Table -AutoSize
    }
})
$bNetStat = New-Btn2 "netstat -ano" 328 $ySeg 155 42 $scrSeg "Todas las conexiones y puertos"
$bNetStat.Add_Click({ Run-BG "netstat" { netstat -ano } })
$bUDP = New-Btn2 "Puertos UDP" 489 $ySeg 155 42 $scrSeg "Puertos UDP en escucha"
$bUDP.Add_Click({ Run-BG "Puertos UDP" { Get-NetUDPEndpoint | Select-Object LocalAddress,LocalPort,OwningProcess | Sort-Object LocalPort | Format-Table -AutoSize } })
$ySeg += 50

New-Sec2 "Windows Defender y Actualizaciones" 6 $ySeg $scrSeg | Out-Null; $ySeg += 28
$bDefStatus = New-Btn2 "Estado Defender" 6 $ySeg 155 42 $scrSeg "Estado actual de Windows Defender"
$bDefStatus.Add_Click({ Run-BG "Estado Defender" { Get-MpComputerStatus | Select-Object AMRunningMode,RealTimeProtectionEnabled,AntivirusEnabled,AntispywareEnabled,IoavProtectionEnabled,BehaviorMonitorEnabled | Format-List } })
$bDefScan = New-Btn2 "Escaneo Rapido" 167 $ySeg 155 42 $scrSeg "Escaneo rapido con Defender"
$bDefScan.Add_Click({ Run-BG "Escaneo rapido Defender" { Start-MpScan -ScanType QuickScan; "Escaneo rapido iniciado." } })
$bDefUpdate = New-Btn2 "Actualizar Firmas" 328 $ySeg 155 42 $scrSeg "Actualizar definiciones de Defender"
$bDefUpdate.Add_Click({ Run-BG "Actualizar firmas" { Update-MpSignature; "Firmas actualizadas." } })
$bWinUpdate = New-Btn2 "Windows Update" 489 $ySeg 155 42 $scrSeg "Abrir Windows Update"
$bWinUpdate.Add_Click({ Start-Process ms-settings:windowsupdate })
$bWinVer = New-Btn2 "winver" 650 $ySeg 120 42 $scrSeg "Ventana version de Windows"
$bWinVer.Add_Click({ Start-Process winver })
$ySeg += 50

New-Sec2 "Politicas y Registro" 6 $ySeg $scrSeg | Out-Null; $ySeg += 28
$bUAC = New-Btn2 "Estado UAC" 6 $ySeg 145 42 $scrSeg "Ver nivel de Control de Cuentas"
$bUAC.Add_Click({ Run-BG "Estado UAC" { reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin; reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA } })
$bAutorun = New-Btn2 "Inicio Automatico" 157 $ySeg 145 42 $scrSeg "Programas que inician con Windows"
$bAutorun.Add_Click({ Run-BG "Inicio automatico" { Get-CimInstance Win32_StartupCommand | Select-Object Name,Command,Location,User | Format-Table -AutoSize } })
$bCreds = New-Btn2 "Credenciales" 308 $ySeg 145 42 $scrSeg "Credenciales guardadas en el sistema"
$bCreds.Add_Click({ Run-BG "Credenciales" { cmdkey /list } })
$bEvtSec = New-Btn2 "Eventos Criticos" 459 $ySeg 145 42 $scrSeg "Ultimos 30 eventos de seguridad criticos"
$bEvtSec.Add_Click({ Run-BG "Eventos criticos" { Get-EventLog System -EntryType Error -Newest 30 -EA SilentlyContinue | Select-Object TimeGenerated,Source,Message | Format-Table -AutoSize -Wrap } })
$bSFC2 = New-Btn2 "SFC /scannow" 610 $ySeg 145 42 $scrSeg "Verificar integridad de archivos del sistema"
$bSFC2.Add_Click({ Run-BG "SFC scannow" { sfc /scannow } })
$ySeg += 52

$scrSeg.AutoScrollMinSize = New-Object Drawing.Size(840,($ySeg+20))

# ============================================================
#   TAB 3: HERRAMIENTAS
# ============================================================
$scrHer = New-ScrollP2 $tPnls[3]
$yH = 6

New-Sec2 "Inventario del Sistema" 6 $yH $scrHer | Out-Null; $yH += 28
$bInvFull = New-Btn2 "Inventario Completo" 6 $yH 175 42 $scrHer "Exporta informe completo al escritorio"
$bInvFull.Add_Click({
    Run-BG "Inventario completo" {
        $path="$env:USERPROFILE\Desktop\Inventario_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $os=Get-CimInstance Win32_OperatingSystem
        $cpu=Get-CimInstance Win32_Processor
        $ram=Get-CimInstance Win32_PhysicalMemory
        $bios=Get-CimInstance Win32_BIOS
        $board=Get-CimInstance Win32_BaseBoard
        @(
            "========================================"
            " INVENTARIO DEL SISTEMA — $(Get-Date -Format 'dd/MM/yyyy HH:mm')"
            "========================================"
            ""
            "=== SISTEMA OPERATIVO ==="
            "OS:           $($os.Caption)"
            "Version:      $($os.Version) (Build $($os.BuildNumber))"
            "Arquitectura: $($os.OSArchitecture)"
            "Instalado:    $($os.InstallDate)"
            ""
            "=== PROCESADOR ==="
            "CPU:          $($cpu.Name.Trim())"
            "Nucleos:      $($cpu.NumberOfCores) fisicos / $($cpu.NumberOfLogicalProcessors) logicos"
            "Velocidad:    $($cpu.MaxClockSpeed) MHz"
            ""
            "=== MEMORIA RAM ==="
        ) | Set-Content $path -Encoding UTF8
        $ram | ForEach-Object { "  Slot $($_.BankLabel): $([math]::Round($_.Capacity/1GB,1)) GB — $($_.Speed) MHz — $($_.Manufacturer)" } | Add-Content $path -Encoding UTF8
        @(
            ""
            "=== ALMACENAMIENTO ==="
        ) | Add-Content $path -Encoding UTF8
        Get-PSDrive -PSProvider FileSystem | Where-Object{$_.Used -ne $null} | ForEach-Object { "  Unidad $($_.Name): $([math]::Round(($_.Used+$_.Free)/1GB,2)) GB total, $([math]::Round($_.Free/1GB,2)) GB libre" } | Add-Content $path -Encoding UTF8
        @(
            ""
            "=== RED ==="
        ) | Add-Content $path -Encoding UTF8
        Get-NetAdapter | Where-Object{$_.Status -eq "Up"} | ForEach-Object { "  $($_.Name): $((Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).IPAddress)  $($_.LinkSpeed)" } | Add-Content $path -Encoding UTF8
        @(
            ""
            "=== BIOS ==="
            "BIOS:  $($bios.SMBIOSBIOSVersion) — $($bios.Manufacturer)"
            ""
            "=== PLACA BASE ==="
            "Placa: $($board.Manufacturer) $($board.Product)"
            ""
            "=== DRIVERS CON ERROR ==="
        ) | Add-Content $path -Encoding UTF8
        Get-WmiObject Win32_PnPEntity | Where-Object{$_.ConfigManagerErrorCode -ne 0} | ForEach-Object{"  $($_.Name) (Error: $($_.ConfigManagerErrorCode))"} | Add-Content $path -Encoding UTF8
        "Inventario guardado: $path"
        Start-Process notepad $path
    }
})
$bInvHW = New-Btn2 "Info Hardware" 187 $yH 145 42 $scrHer "CPU, RAM, placa, BIOS"
$bInvHW.Add_Click({
    Run-BG "Info Hardware" {
        $cpu=Get-CimInstance Win32_Processor;$bios=Get-CimInstance Win32_BIOS;$board=Get-CimInstance Win32_BaseBoard
        "=== CPU ==="; "  $($cpu.Name.Trim())  |  $($cpu.NumberOfCores) nucleos  |  $($cpu.MaxClockSpeed) MHz"
        "=== BIOS ==="; "  $($bios.SMBIOSBIOSVersion)  |  $($bios.Manufacturer)  |  $($bios.ReleaseDate)"
        "=== PLACA ==="; "  $($board.Manufacturer)  $($board.Product)  SN:$($board.SerialNumber)"
    }
})
$bDriversAll = New-Btn2 "Lista Drivers" 338 $yH 145 42 $scrHer "Todos los drivers instalados"
$bDriversAll.Add_Click({ Run-BG "Lista drivers" { Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName,DriverVersion,Manufacturer | Sort-Object DeviceName | Format-Table -AutoSize } })
$bPrograms = New-Btn2 "Programas Inst." 489 $yH 145 42 $scrHer "Aplicaciones instaladas en el sistema"
$bPrograms.Add_Click({ Run-BG "Programas instalados" { Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName,DisplayVersion,Publisher,InstallDate | Where-Object{$_.DisplayName} | Sort-Object DisplayName | Format-Table -AutoSize } })
$bWinget2 = New-Btn2 "Lista Winget" 640 $yH 145 42 $scrHer "Apps instaladas con Winget"
$bWinget2.Add_Click({ Run-BG "Lista winget" { winget list 2>&1 } })
$yH += 50

New-Sec2 "Reparacion del Sistema" 6 $yH $scrHer | Out-Null; $yH += 28
$bDISM2 = New-Btn2 "DISM RestoreHealth" 6 $yH 165 42 $scrHer "Repara imagen de Windows"
$bDISM2.Add_Click({ Run-BG "DISM RestoreHealth" { DISM /Online /Cleanup-Image /RestoreHealth } })
$bSFC3 = New-Btn2 "SFC /scannow" 177 $yH 145 42 $scrHer "Verifica archivos del sistema"
$bSFC3.Add_Click({ Run-BG "SFC scannow" { sfc /scannow } })
$bChkDsk = New-Btn2 "ChkDsk C:" 328 $yH 145 42 $scrHer "Programa verificacion disco en reinicio"
$bChkDsk.Add_Click({
    $r=[Windows.Forms.MessageBox]::Show("ChkDsk se programara para el proximo reinicio.`nContinuar?","ChkDsk","YesNo","Question")
    if($r -eq "Yes"){Run-BG "ChkDsk C:" {echo Y | chkdsk C: /f /r;"ChkDsk programado para el proximo reinicio."}}
})
$bWUReset = New-Btn2 "Reset Win Update" 479 $yH 160 42 $scrHer "Reinicia el servicio de Windows Update"
$bWUReset.Add_Click({ Run-BG "Reset Windows Update" { Stop-Service wuauserv,bits,cryptsvc -Force -EA SilentlyContinue; Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv,bits,cryptsvc -EA SilentlyContinue; "Windows Update reiniciado." } })
$bRestorePoint = New-Btn2 "Punto Restauracion" 645 $yH 145 42 $scrHer "Crear punto de restauracion del sistema"
$bRestorePoint.Add_Click({ Run-BG "Crear Punto Restauracion" { Checkpoint-Computer -Description "SysEng_$(Get-Date -Format yyyyMMdd_HHmmss)" -RestorePointType MODIFY_SETTINGS; "Punto de restauracion creado." } })
$yH += 50

New-Sec2 "Utilidades de Archivos" 6 $yH $scrHer | Out-Null; $yH += 28
$inHashFile = New-Input "Ruta del archivo..." 6 ($yH+8) 360 $scrHer
$bBrowse = New-Btn2 "..." 372 $yH 40 42 $scrHer "Seleccionar archivo"
$bBrowse.Add_Click({ $d=New-Object Windows.Forms.OpenFileDialog;$d.Filter="Todos (*.*)|*.*";if($d.ShowDialog() -eq "OK"){$inHashFile.Text=$d.FileName} })
$cmbAlg = New-Object Windows.Forms.ComboBox; $cmbAlg.Location=New-Object Drawing.Point(418,($yH+8)); $cmbAlg.Size=New-Object Drawing.Size(90,26); $cmbAlg.BackColor=[Drawing.Color]::FromArgb(13,24,52); $cmbAlg.ForeColor=$cText; $cmbAlg.FlatStyle="Flat"; $cmbAlg.DropDownStyle="DropDownList"; $cmbAlg.Items.AddRange(@("MD5","SHA1","SHA256","SHA512")); $cmbAlg.SelectedIndex=2; $scrHer.Controls.Add($cmbAlg)
$bHash = New-Btn2 "Calcular Hash" 514 $yH 145 42 $scrHer "Calcular hash del archivo seleccionado"
$bHash.Add_Click({
    $path=$inHashFile.Text.Trim()
    if(-not(Test-Path $path)){Out-Con "Archivo no encontrado." $cYellow;return}
    $alg=$cmbAlg.SelectedItem; $h=Get-FileHash $path -Algorithm $alg
    Out-Con "[$alg] $($h.Hash)" $cGreen; Out-Con "Archivo: $path" $cSub
    [Windows.Forms.Clipboard]::SetText($h.Hash); Out-Con "(Copiado al portapapeles)" $cSub
})
$bSizeFolder = New-Btn2 "Tamano Carpeta" 665 $yH 130 42 $scrHer "Calcular tamano de una carpeta"
$bSizeFolder.Add_Click({
    $d=New-Object Windows.Forms.FolderBrowserDialog
    if($d.ShowDialog() -eq "OK"){
        $folder=$d.SelectedPath
        Run-BG "Tamano carpeta" {
            param($f)
            $size=(Get-ChildItem $f -Recurse -EA SilentlyContinue|Measure-Object Length -Sum).Sum
            $count=(Get-ChildItem $f -Recurse -EA SilentlyContinue).Count
            "Carpeta:  $f"
            "Tamano:   $([math]::Round($size/1MB,2)) MB  ($([math]::Round($size/1GB,3)) GB)"
            "Archivos: $count"
        } @($folder)
    }
})
$yH += 52

New-Sec2 "Herramientas del Sistema" 6 $yH $scrHer | Out-Null; $yH += 28
$tools = @(
    @{n="Administrador de tareas"; c={Start-Process taskmgr}},
    @{n="Editor de registro";      c={Start-Process regedit}},
    @{n="Configuracion del sistema";c={Start-Process msconfig}},
    @{n="Monitor de rendimiento";  c={Start-Process perfmon}},
    @{n="Directivas grupo local";  c={Start-Process gpedit.msc}},
    @{n="ODBC (64 bits)";          c={Start-Process odbcad32}},
    @{n="Herramienta diagn. memoria";c={Start-Process mdsched}},
    @{n="Propiedades avanzadas";   c={Start-Process sysdm.cpl}}
)
$thX=6;$thC=0
foreach($t2 in $tools){
    $b=New-Btn2 $t2.n $thX $yH 195 40 $scrHer
    $tc=$t2.c;$b.Add_Click($tc)
    $thC++;if($thC -ge 4){$thC=0;$thX=6;$yH+=44}else{$thX+=199}
}
if($thC -ne 0){$yH+=44}
$yH+=8

$scrHer.AutoScrollMinSize = New-Object Drawing.Size(840,($yH+20))

# ============================================================
#   TAB 4: INFO RAPIDA (dashboard en tiempo real)
# ============================================================
$pInfo = $tPnls[4]

# Cards metricas
function New-InfoCard($label,$x,$y) {
    $p=New-Object Windows.Forms.Panel;$p.Location=New-Object Drawing.Point($x,$y);$p.Size=New-Object Drawing.Size(185,110);$p.BackColor=$cCard;$pInfo.Controls.Add($p)
    $lt=New-Object Windows.Forms.Label;$lt.Text=$label;$lt.Location=New-Object Drawing.Point(10,8);$lt.Size=New-Object Drawing.Size(165,18);$lt.ForeColor=$cSub;$lt.Font=New-Object Drawing.Font("Segoe UI",8);$p.Controls.Add($lt)
    $lv=New-Object Windows.Forms.Label;$lv.Text="...";$lv.Location=New-Object Drawing.Point(10,26);$lv.Size=New-Object Drawing.Size(165,42);$lv.ForeColor=$cAcc2;$lv.Font=New-Object Drawing.Font("Segoe UI",20,[Drawing.FontStyle]::Bold);$p.Controls.Add($lv)
    $bar=New-Object Windows.Forms.ProgressBar;$bar.Location=New-Object Drawing.Point(10,78);$bar.Size=New-Object Drawing.Size(165,14);$bar.Minimum=0;$bar.Maximum=100;$bar.Style="Continuous";$bar.ForeColor=$cAccent;$p.Controls.Add($bar)
    return @{lv=$lv;bar=$bar;p=$p}
}

$iCPU  = New-InfoCard "CPU" 6 8
$iRAM  = New-InfoCard "RAM" 198 8
$iDisk = New-InfoCard "Disco C:" 390 8
$iNet  = New-InfoCard "Red" 582 8

# Info del sistema
$rtbInfo = New-Object Windows.Forms.RichTextBox
$rtbInfo.Location=New-Object Drawing.Point(6,128);$rtbInfo.Size=New-Object Drawing.Size(760,210)
$rtbInfo.BackColor=$cOut;$rtbInfo.ForeColor=$cAcc2;$rtbInfo.Font=New-Object Drawing.Font("Consolas",8.5)
$rtbInfo.ReadOnly=$true;$rtbInfo.BorderStyle="None";$pInfo.Controls.Add($rtbInfo)

# Top procesos
$pProcPanel=New-Object Windows.Forms.Panel;$pProcPanel.Location=New-Object Drawing.Point(6,346);$pProcPanel.Size=New-Object Drawing.Size(760,280);$pProcPanel.BackColor=$cCard;$pInfo.Controls.Add($pProcPanel)
$ltProc=New-Object Windows.Forms.Label;$ltProc.Text="  Top 15 Procesos — CPU + RAM";$ltProc.Location=New-Object Drawing.Point(0,0);$ltProc.Size=New-Object Drawing.Size(760,26);$ltProc.ForeColor=$cAcc2;$ltProc.BackColor=[Drawing.Color]::FromArgb(14,28,60);$ltProc.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold);$ltProc.TextAlign="MiddleLeft";$pProcPanel.Controls.Add($ltProc)
$rtbProcs=New-Object Windows.Forms.RichTextBox;$rtbProcs.Location=New-Object Drawing.Point(0,26);$rtbProcs.Size=New-Object Drawing.Size(760,254);$rtbProcs.BackColor=$cOut;$rtbProcs.ForeColor=$cText;$rtbProcs.Font=New-Object Drawing.Font("Consolas",9);$rtbProcs.ReadOnly=$true;$rtbProcs.BorderStyle="None";$pProcPanel.Controls.Add($rtbProcs)

# Boton cargar info
$bInfoLoad=New-Btn2 "  Cargar Info del Sistema" 6 634 220 40 $pInfo "Carga informacion detallada del OS"
$bInfoLoad.Add_Click({
    Run-BG "Cargar Info" {
        $os=Get-CimInstance Win32_OperatingSystem;$cpu=Get-CimInstance Win32_Processor;$bios=Get-CimInstance Win32_BIOS
        "OS:        $($os.Caption) $($os.Version)"
        "CPU:       $($cpu.Name.Trim())"
        "Nucleos:   $($cpu.NumberOfCores) fisicos / $($cpu.NumberOfLogicalProcessors) logicos"
        "RAM:       $([math]::Round($os.TotalVisibleMemorySize/1MB,2)) GB total  |  $([math]::Round($os.FreePhysicalMemory/1MB,1)) GB libre"
        "Disco C:   $(Get-PSDrive C | ForEach-Object {"$([math]::Round(($_.Used+$_.Free)/1GB,2)) GB total, $([math]::Round($_.Free/1GB,2)) GB libre"})"
        "BIOS:      $($bios.SMBIOSBIOSVersion) — $($bios.Manufacturer)"
        "Equipo:    $env:COMPUTERNAME  |  Usuario: $env:USERNAME"
        "Uptime:    $([math]::Round(((Get-Date)-$os.LastBootUpTime).TotalHours,1)) horas"
        ""
        "=== INTERFACES DE RED ACTIVAS ==="
        Get-NetAdapter|Where-Object{$_.Status -eq "Up"}|ForEach-Object{"  $($_.Name): $((Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).IPAddress)  $($_.LinkSpeed)"}
    }
})

# ============================================================
#   MONITOR TIEMPO REAL — Get-Counter (no bloquea)
# ============================================================
$script:lastNetBG = 0
$mon = New-Object Windows.Forms.Timer; $mon.Interval = 2000
$mon.Add_Tick({
    try {
        # CPU
        $cpuL=[int]((Get-Counter '\Processor(_Total)\% Processor Time' -EA SilentlyContinue).CounterSamples.CookedValue)
        $cpuC=if($cpuL -gt 85){$cRed}elseif($cpuL -gt 65){$cYellow}else{$cGreen}
        # RAM
        $os5=Get-CimInstance Win32_OperatingSystem -Property TotalVisibleMemorySize,FreePhysicalMemory
        $ramPct=[int](($os5.TotalVisibleMemorySize-$os5.FreePhysicalMemory)/$os5.TotalVisibleMemorySize*100)
        $ramFree=[math]::Round($os5.FreePhysicalMemory/1MB,1)
        $ramC=if($ramPct -gt 85){$cRed}elseif($ramPct -gt 65){$cYellow}else{$cAccent}
        # Disco
        $drv=Get-PSDrive C -EA SilentlyContinue
        $dPct=[int]($drv.Used/($drv.Used+$drv.Free)*100)
        $dFree=[math]::Round($drv.Free/1GB,1)
        $dC=if($dPct -gt 90){$cRed}elseif($dPct -gt 75){$cYellow}else{$cAccent}
        # Red
        $ns=Get-NetAdapterStatistics -EA SilentlyContinue|Select-Object -First 1
        $netKB=0
        if($ns){$tot=$ns.ReceivedBytes+$ns.SentBytes;$netKB=[math]::Round(($tot-$script:lastNetBG)/1KB/2,1);$script:lastNetBG=$tot}
        # Cards Info Rapida
        $iCPU.lv.Text="$cpuL%";  $iCPU.bar.Value=[Math]::Min($cpuL,100);  $iCPU.lv.ForeColor=$cpuC; $iCPU.bar.ForeColor=$cpuC
        $iRAM.lv.Text="$ramPct%";$iRAM.bar.Value=[Math]::Min($ramPct,100);$iRAM.lv.ForeColor=$ramC; $iRAM.bar.ForeColor=$ramC
        $iDisk.lv.Text="$dPct%"; $iDisk.bar.Value=[Math]::Min($dPct,100); $iDisk.lv.ForeColor=$dC;  $iDisk.bar.ForeColor=$dC
        $iNet.lv.Text="$netKB";  $iNet.bar.Value=[Math]::Min([int]($netKB/10),100)
        # Procesos — solo si tab Info Rapida activa
        if($script:tab2 -eq 4){
            $procs=Get-Process -EA SilentlyContinue|Sort-Object CPU -Descending|Select-Object -First 15
            $rtbProcs.Clear()
            $rtbProcs.SelectionColor=$cSub
            $rtbProcs.AppendText(("{0,-36} {1,10} {2,12} {3,8}`r`n" -f "Proceso","CPU (seg)","RAM (MB)","PID"))
            $rtbProcs.AppendText(("─"*72+"`r`n"))
            foreach($pr in $procs){
                $rtbProcs.SelectionColor=if($pr.CPU -gt 60){$cYellow}else{$cText}
                $rtbProcs.AppendText(("{0,-36} {1,10:N1} {2,12:N1} {3,8}`r`n" -f $pr.Name.Substring(0,[Math]::Min($pr.Name.Length,35)),$pr.CPU,($pr.WorkingSet64/1MB),$pr.Id))
            }
        }
    } catch {}
})
$mon.Start()

# ============================================================
#   INICIO
# ============================================================
Go-Tab 0

# Cargar info en la consola al inicio
Out-Con "╔══════════════════════════════════════╗" $cAccent
Out-Con "║   SysEng Tool — Listo para usar      ║" $cAccent
Out-Con "╚══════════════════════════════════════╝`r`n" $cAccent
Out-Con "Equipo:  $env:COMPUTERNAME" $cSub
Out-Con "Usuario: $env:USERNAME" $cSub
Out-Con "Admin:   $(if($isAdmin){'SI'}else{'NO (algunas funciones limitadas)'})" $(if($isAdmin){$cGreen}else{$cYellow})
Out-Con "Hora:    $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')`r`n" $cSub
Out-Con "Selecciona una tab y ejecuta una funcion." $cAcc2

$form.Add_FormClosing({
    $mon.Stop(); $ck.Stop()
    try { $script:Pool.Close(); $script:Pool.Dispose() } catch {}
})

[Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog()
