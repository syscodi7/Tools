#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#   COMPROBACIÓN DE ADMINISTRADOR
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $r = [Windows.Forms.MessageBox]::Show("Se recomienda ejecutar como Administrador para todas las funciones.`n`n¿Continuar de todas formas?", "SysEng Tool", "YesNo", "Warning")
    if ($r -eq "No") { exit }
}

# ============================================================
#   RUNSPACE POOL (Segundo plano para evitar congelamiento)
# ============================================================
$script:Pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, 5)
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
#   PALETA DE COLORES
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
#   FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text            = "SysEng Tool — Redes & Aplicaciones"
$form.Size            = New-Object Drawing.Size(1200, 750)
$form.MinimumSize     = New-Object Drawing.Size(1000, 600)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBg
$form.ForeColor       = $cText
$form.Font            = New-Object Drawing.Font("Segoe UI", 9)

# ============================================================
#   HEADER
# ============================================================
$pHead = New-Object Windows.Forms.Panel
$pHead.Dock = "Top"; $pHead.Height = 65; $pHead.BackColor = $cPanel
$form.Controls.Add($pHead)

$lTitle = New-Object Windows.Forms.Label
$lTitle.Text = "SysEng Tool"; $lTitle.Location = New-Object Drawing.Point(16,8)
$lTitle.Size = New-Object Drawing.Size(250,30)
$lTitle.Font = New-Object Drawing.Font("Segoe UI",16,[Drawing.FontStyle]::Bold)
$lTitle.ForeColor = $cAcc2
$pHead.Controls.Add($lTitle)

$lSub2 = New-Object Windows.Forms.Label
$lSub2.Text = "Panel de control simplificado — Gestión de Redes y Aplicaciones del Sistema"
$lSub2.Location = New-Object Drawing.Point(16,38); $lSub2.Size = New-Object Drawing.Size(600,20)
$lSub2.Font = New-Object Drawing.Font("Segoe UI",8.5); $lSub2.ForeColor = $cSub
$pHead.Controls.Add($lSub2)

$lblAdmin = New-Object Windows.Forms.Label
$lblAdmin.Text = if ($isAdmin) { "  ADMIN  " } else { "  SIN ADMIN  " }
$lblAdmin.Location = New-Object Drawing.Point(1050, 20); $lblAdmin.Size = New-Object Drawing.Size(95, 24)
$lblAdmin.ForeColor = if ($isAdmin) { $cGreen } else { $cYellow }
$lblAdmin.BackColor = [Drawing.Color]::FromArgb(0,40,15)
$lblAdmin.Font = New-Object Drawing.Font("Segoe UI",8,[Drawing.FontStyle]::Bold)
$lblAdmin.TextAlign = "MiddleCenter"; $lblAdmin.BorderStyle = "FixedSingle"
$pHead.Controls.Add($lblAdmin)

# ============================================================
#   BARRA DE PESTAÑAS
# ============================================================
$pTabs2 = New-Object Windows.Forms.Panel
$pTabs2.Dock = "Top"; $pTabs2.Height = 45; $pTabs2.BackColor = $cPanel
$form.Controls.Add($pTabs2)
$pTabs2.Controls.Add((New-Object Windows.Forms.Panel -Property @{Dock="Bottom";Height=2;BackColor=$cAccent}))

# ============================================================
#   LAYOUT CUERPO
# ============================================================
$pBody = New-Object Windows.Forms.Panel
$pBody.Dock = "Fill"; $pBody.BackColor = $cBg
$form.Controls.Add($pBody)

# Consola derecha fija
$pRight = New-Object Windows.Forms.Panel
$pRight.Width = 420; $pRight.Dock = "Right"; $pRight.BackColor = $cOut
$pBody.Controls.Add($pRight)

$pRHead = New-Object Windows.Forms.Panel
$pRHead.Dock = "Top"; $pRHead.Height = 36; $pRHead.BackColor = $cPanel
$pRight.Controls.Add($pRHead)

$lRTitle = New-Object Windows.Forms.Label
$lRTitle.Text = "  Consola de salida"; $lRTitle.Dock = "Left"; $lRTitle.Width = 200
$lRTitle.ForeColor = $cAcc2; $lRTitle.Font = New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$lRTitle.TextAlign = "MiddleLeft"; $pRHead.Controls.Add($lRTitle)

$bClear = New-Object Windows.Forms.Button
$bClear.Text = "Limpiar"; $bClear.Dock = "Right"; $bClear.Width = 80
$bClear.BackColor = [Drawing.Color]::FromArgb(0,55,110); $bClear.ForeColor = $cText
$bClear.FlatStyle = "Flat"; $bClear.FlatAppearance.BorderSize = 0
$bClear.Add_Click({ $rtb.Clear(); Out-Con "Consola limpiada.`r`n" $cSub })
$pRHead.Controls.Add($bClear)

$rtb = New-Object Windows.Forms.RichTextBox
$rtb.Dock = "Fill"; $rtb.BackColor = $cOut; $rtb.ForeColor = $cAcc2
$rtb.Font = New-Object Drawing.Font("Consolas",9); $rtb.ReadOnly = $true
$rtb.BorderStyle = "None"; $rtb.ScrollBars = "Vertical"
$pRight.Controls.Add($rtb)

function Out-Con($msg, $color) {
    if (-not $color) { $color = $cAcc2 }
    $rtb.SelectionStart = $rtb.TextLength
    $rtb.SelectionColor = $color
    $rtb.AppendText("$msg`r`n")
    $rtb.ScrollToCaret()
}

$pb = New-Object Windows.Forms.ProgressBar
$pb.Dock = "Top"; $pb.Height = 4; $pb.Style = "Marquee"
$pb.MarqueeAnimationSpeed = 0; $pBody.Controls.Add($pb)

$pLeft = New-Object Windows.Forms.Panel
$pLeft.Dock = "Fill"; $pLeft.BackColor = $cBg; $pBody.Controls.Add($pLeft)

# ============================================================
#   ELEMENTOS DE INTERFAZ (HELPERS)
# ============================================================
function New-Btn2($txt,$x,$y,$w,$h,$par,$tip="") {
    $b = New-Object Windows.Forms.Button
    $b.Text = $txt; $b.Location = New-Object Drawing.Point($x,$y)
    $b.Size = New-Object Drawing.Size($w,$h)
    $b.BackColor = $cCard; $b.ForeColor = $cText
    $b.FlatStyle = "Flat"; $b.FlatAppearance.BorderColor = $cBorder
    $b.Font = New-Object Drawing.Font("Segoe UI",8.5)
    $b.Cursor = "Hand"
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
    $l.Size = New-Object Drawing.Size(730,24)
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

# ============================================================
#   SISTEMA DE DOS PESTAÑAS
# ============================================================
$tabs2  = @("Redes", "Aplicaciones")
$tBtns2 = @(); $tPnls  = @(); $tx2 = 6

foreach ($td in $tabs2) {
    $tb = New-Object Windows.Forms.Button
    $tb.Text = $td; $tb.Location = New-Object Drawing.Point($tx2,6)
    $tb.Size = New-Object Drawing.Size(140,32)
    $tb.BackColor = $cPanel; $tb.ForeColor = $cSub
    $tb.FlatStyle = "Flat"; $tb.FlatAppearance.BorderSize = 0
    $tb.Font = New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $tb.Cursor = "Hand"; $pTabs2.Controls.Add($tb); $tBtns2 += $tb; $tx2 += 145
    
    $tp = New-Object Windows.Forms.Panel; $tp.Dock = "Fill"; $tp.AutoScroll = $true; $tp.BackColor = $cBg
    $tp.Visible = $false; $pLeft.Controls.Add($tp); $tPnls += $tp
}

function Go-Tab($i) {
    for ($j = 0; $j -lt $tBtns2.Count; $j++) {
        if ($j -eq $i) { 
            $tBtns2[$j].BackColor=[Drawing.Color]::FromArgb(16,38,80)
            $tBtns2[$j].ForeColor=$cAcc2
            $tPnls[$j].Visible=$true
            $tPnls[$j].BringToFront() 
        } else { 
            $tBtns2[$j].BackColor=$cPanel
            $tBtns2[$j].ForeColor=$cSub
            $tPnls[$j].Visible=$false 
        }
    }
}
for ($i=0;$i -lt $tBtns2.Count;$i++){$idx=$i;$tBtns2[$i].Add_Click({Go-Tab $idx})}

# ============================================================
#   SECCIÓN 1: REDES
# ============================================================
$scrRed = $tPnls[0]
$yN = 6

# Diagnósticos base
New-Sec2 "Diagnóstico de Red rápido" 6 $yN $scrRed | Out-Null; $yN += 28
$inPing = New-Input "8.8.8.8" 6 $yN 200 $scrRed
$bPing = New-Btn2 "Lanzar Ping" 212 $yN 110 24 $scrRed "Enviar 4 paquetes de ping"
$bPing.Add_Click({
    $h=$inPing.Text.Trim(); if(-not $h){return}
    Run-BG "Ping a $h" { param($host2); ping -n 4 $host2 } @($h)
})
$inTrace = New-Input "google.com" 335 $yN 200 $scrRed
$bTrace = New-Btn2 "Traceroute" 540 $yN 110 24 $scrRed "Rastrear ruta de red"
$bTrace.Add_Click({ $h=$inTrace.Text.Trim();if($h){Run-BG "Tracert $h" {param($t);tracert $t} @($h)} })
$yN += 35

# DNS e IPs
New-Sec2 "Resolución DNS e Interfaces" 6 $yN $scrRed | Out-Null; $yN += 28
$bIPConf = New-Btn2 "Ver IPConfig /all" 6 $yN 170 35 $scrRed "Configuración completa de red"
$bIPConf.Add_Click({ Run-BG "ipconfig /all" { ipconfig /all } })
$bAdapt = New-Btn2 "Estado Adaptadores" 182 $yN 170 35 $scrRed "Listar tarjetas de red"
$bAdapt.Add_Click({ Run-BG "Adaptadores" { Get-NetAdapter | Select-Object Name,Status,LinkSpeed,MacAddress | Format-Table -AutoSize } })
$bFlush = New-Btn2 "Vaciar Caché DNS" 358 $yN 170 35 $scrRed "Flush DNS"
$bFlush.Add_Click({ Run-BG "Flush DNS" { ipconfig /flushdns } })
$bConexiones = New-Btn2 "Conexiones TCP" 534 $yN 170 35 $scrRed "Ver conexiones establecidas"
$bConexiones.Add_Click({ Run-BG "Conexiones TCP" { Get-NetTCPConnection -State Established | Select-Object LocalAddress,LocalPort,RemoteAddress,RemotePort | Format-Table -AutoSize } })
$yN += 45

# Escáner y Reparación
New-Sec2 "Herramientas Avanzadas de Red" 6 $yN $scrRed | Out-Null; $yN += 28
$inPortHost = New-Input "192.168.1.1" 6 ($yN+5) 150 $scrRed
$bScanPort = New-Btn2 "Escanear Puertos (1-100)" 162 $yN 180 30 $scrRed "Escaneo rápido de puertos comunes"
$bScanPort.Add_Click({
    $h=$inPortHost.Text.Trim()
    if(-not $h){return}
    Run-BG "Escaneo puertos en $h" {
        param($host2)
        $open = @()
        for ($port=1;$port -le 100;$port++) {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $conn = $tcp.BeginConnect($host2,$port,$null,$null)
            if ($conn.AsyncWaitHandle.WaitOne(100,$false) -and $tcp.Client.Connected) { $open += $port }
            $tcp.Close()
        }
        if ($open.Count -eq 0) { "Sin puertos abiertos en rango 1-100" } else { "Puertos abiertos: " + ($open -join ", ") }
    } @($h)
})
$bResetTCP = New-Btn2 "Resetear Pila IP" 350 $yN 170 30 $scrRed "Reinicia protocolos de red"
$bResetTCP.Add_Click({ Run-BG "Reset TCP/IP" { netsh int ip reset; netsh winsock reset; "Pila de red reseteada. Reinicie el equipo." } })
$bRenewIP = New-Btn2 "Renovar IP (DHCP)" 526 $yN 175 30 $scrRed "Liberar y renovar IP"
$bRenewIP.Add_Click({ Run-BG "Renovando IP" { ipconfig /release; ipconfig /renew } })
$yN += 45

$scrRed.AutoScrollMinSize = New-Object Drawing.Size(730,$yN)

# ============================================================
#   SECCIÓN 2: APLICACIONES
# ============================================================
$scrApp = $tPnls[1]
$yA = 6

# Monitoreo y control de procesos
New-Sec2 "Procesos y Rendimiento de Aplicaciones" 6 $yA $scrApp | Out-Null; $yA += 28
$bTopCPU = New-Btn2 "Top Consumo CPU" 6 $yA 170 35 $scrApp "Procesos más pesados en CPU"
$bTopCPU.Add_Click({ Run-BG "Top CPU" { Get-Process | Sort-Object CPU -Descending | Select-Object -First 15 Name,Id,CPU | Format-Table -AutoSize } })
$bTopRAM = New-Btn2 "Top Consumo RAM" 182 $yA 170 35 $scrApp "Procesos más pesados en RAM"
$bTopRAM.Add_Click({ Run-BG "Top RAM" { Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 15 Name,Id,@{n="RAM MB";e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize } })
$inProcKill = New-Input "PID o Nombre" 360 ($yA+5) 150 $scrApp
$bKill = New-Btn2 "Forzar Cierre" 515 $yA 120 35 $scrApp "Finaliza el proceso seleccionado"
$bKill.Add_Click({
    $v=$inProcKill.Text.Trim(); if(-not $v){return}
    Run-BG "Matando $v" {
        param($t)
        if ($t -match "^\d+$") { Stop-Process -Id ([int]$t) -Force; "Proceso PID $t cerrado." }
        else { Stop-Process -Name $t -Force; "Proceso '$t' cerrado." }
    } @($v)
})
$yA += 45

# Servicios de Windows
New-Sec2 "Gestión de Servicios del Sistema" 6 $yA $scrApp | Out-Null; $yA += 28
$bSvcAll = New-Btn2 "Listar Ejecutándose" 6 $yA 170 35 $scrApp "Servicios activos"
$bSvcAll.Add_Click({ Run-BG "Servicios Activos" { Get-Service | Where-Object {$_.Status -eq "Running"} | Select-Object Name,DisplayName | Sort-Object Name | Select-Object -First 30 | Format-Table -AutoSize } })
$inSvcName = New-Input "NombreServicio" 182 ($yA+5) 170 $scrApp
$bSvcStart = New-Btn2 "Iniciar" 358 $yA 85 35 $scrApp "Iniciar Servicio"
$bSvcStart.Add_Click({ $n=$inSvcName.Text.Trim(); if($n){Run-BG "Iniciar $n" {param($s); Start-Service $s; "Servicio $s iniciado."} @($n)} })
$bSvcStop = New-Btn2 "Detener" 448 $yA 85 35 $scrApp "Detener Servicio"
$bSvcStop.Add_Click({ $n=$inSvcName.Text.Trim(); if($n){Run-BG "Detener $n" {param($s); Stop-Service $s -Force; "Servicio $s detenido."} @($n)} })
$yA += 45

# Aplicaciones instaladas
New-Sec2 "Software Instalado en el Equipo" 6 $yA $scrApp | Out-Null; $yA += 28
$bPrograms = New-Btn2 "Listar Programas (Panel de Control)" 6 $yA 250 35 $scrApp "Aplicaciones del registro"
$bPrograms.Add_Click({ Run-BG "Programas Instalados" { Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName,DisplayVersion | Where-Object{$_.DisplayName} | Sort-Object DisplayName | Format-Table -AutoSize } })
$bWinget2 = New-Btn2 "Listar Software por Winget" 262 $yA 220 35 $scrApp "Apps manejadas por repositorio"
$bWinget2.Add_Click({ Run-BG "Lista Winget" { winget list | Select-Object -First 40 } })
$yA += 45

$scrApp.AutoScrollMinSize = New-Object Drawing.Size(730,$yA)

# ============================================================
#   INICIALIZACIÓN Y INICIO
# ============================================================
Go-Tab 0

Out-Con "╔══════════════════════════════════════╗" $cAccent
Out-Con "║   SysEng Tool — Módulo Redes/Apps    ║" $cAccent
Out-Con "╚══════════════════════════════════════╝`r`n" $cAccent
Out-Con "Equipo:  $env:COMPUTERNAME" $cSub
Out-Con "Usuario: $env:USERNAME" $cSub
Out-Con "Admin:   $(if($isAdmin){'SÍ'}else{'NO'})" $(if($isAdmin){$cGreen}else{$cYellow})

$form.Add_FormClosing({
    try { $script:Pool.Close(); $script:Pool.Dispose() } catch {}
})

[Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog()
