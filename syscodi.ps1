#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Global:RSPool = [RunspaceFactory]::CreateRunspacePool(1,4)
$Global:RSPool.ApartmentState = 'STA'
$Global:RSPool.Open()
$Global:Jobs = [System.Collections.Generic.List[hashtable]]::new()

function Start-Job2([scriptblock]$Code,[object[]]$Args=@()){
    $ps=[PowerShell]::Create(); $ps.RunspacePool=$Global:RSPool
    [void]$ps.AddScript($Code)
    foreach($a in $Args){[void]$ps.AddArgument($a)}
    $h=$ps.BeginInvoke()
    $Global:Jobs.Add(@{PS=$ps;Handle=$h})
}

$cBg    = [Drawing.Color]::FromArgb(15,23,42)
$cPanel = [Drawing.Color]::FromArgb(22,33,62)
$cCard  = [Drawing.Color]::FromArgb(30,45,80)
$cBdr   = [Drawing.Color]::FromArgb(45,65,110)
$cAcc   = [Drawing.Color]::FromArgb(56,189,248)
$cText  = [Drawing.Color]::FromArgb(226,232,240)
$cMut   = [Drawing.Color]::FromArgb(100,116,139)
$cGreen = [Drawing.Color]::FromArgb(74,222,128)
$cYel   = [Drawing.Color]::FromArgb(250,204,21)
$cRed   = [Drawing.Color]::FromArgb(248,113,113)
$cOut   = [Drawing.Color]::FromArgb(10,16,30)

function Write-Log($msg,$type='n'){
    $ts=Get-Date -Format 'HH:mm:ss'
    $outputBox.SelectionStart=$outputBox.TextLength
    $outputBox.SelectionColor=[Drawing.Color]::FromArgb(50,80,130)
    $outputBox.AppendText("`n[$ts] ")
    $outputBox.SelectionColor=switch($type){
        'ok'{$cGreen}'warn'{$cYel}'err'{$cRed}'info'{$cAcc}'sub'{$cMut}default{$cText}
    }
    $outputBox.AppendText($msg)
    $outputBox.ScrollToCaret()
}

function New-Btn($txt,$x,$y,$w=200,$h=40,$col=''){
    $b=New-Object Windows.Forms.Button
    $b.Text=$txt; $b.Location=New-Object Drawing.Point($x,$y)
    $b.Size=New-Object Drawing.Size($w,$h)
    $b.FlatStyle='Flat'; $b.Cursor='Hand'
    $b.Font=New-Object Drawing.Font('Segoe UI',9)
    $b.FlatAppearance.BorderSize=1
    switch($col){
        'green'{$b.BackColor=[Drawing.Color]::FromArgb(5,46,22);  $b.ForeColor=$cGreen; $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(21,128,61)}
        'blue' {$b.BackColor=[Drawing.Color]::FromArgb(8,47,73);  $b.ForeColor=$cAcc;   $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(14,116,144)}
        'red'  {$b.BackColor=[Drawing.Color]::FromArgb(69,10,10); $b.ForeColor=$cRed;   $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(153,27,27)}
        default{$b.BackColor=$cCard; $b.ForeColor=$cText; $b.FlatAppearance.BorderColor=$cBdr}
    }
    return $b
}

# FORM
$form=New-Object Windows.Forms.Form
$form.Text='SysCodi QuickFix'
$form.Size=New-Object Drawing.Size(780,560)
$form.FormBorderStyle='FixedSingle'
$form.MaximizeBox=$false
$form.StartPosition='CenterScreen'
$form.BackColor=$cBg
$form.ForeColor=$cText
$form.Font=New-Object Drawing.Font('Segoe UI',9)

# HEADER
$header=New-Object Windows.Forms.Panel
$header.Dock='Top'; $header.Height=56; $header.BackColor=$cPanel
$form.Controls.Add($header)

$lT=New-Object Windows.Forms.Label
$lT.Text='SysCodi QuickFix'; $lT.Font=New-Object Drawing.Font('Segoe UI',15,[Drawing.FontStyle]::Bold)
$lT.ForeColor=$cAcc; $lT.Location=New-Object Drawing.Point(16,10); $lT.Size=New-Object Drawing.Size(380,28)
$header.Controls.Add($lT)

$lS=New-Object Windows.Forms.Label
$lS.Text='Herramienta de optimizacion rapida para Windows'
$lS.Font=New-Object Drawing.Font('Segoe UI',8); $lS.ForeColor=$cMut
$lS.Location=New-Object Drawing.Point(18,36); $lS.Size=New-Object Drawing.Size(400,16)
$header.Controls.Add($lS)

$isAdmin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$lA=New-Object Windows.Forms.Label
$lA.Text=if($isAdmin){'[Admin]'}else{'[Sin admin]'}
$lA.ForeColor=if($isAdmin){$cGreen}else{$cRed}
$lA.Font=New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold)
$lA.Location=New-Object Drawing.Point(660,20); $lA.Size=New-Object Drawing.Size(110,20)
$header.Controls.Add($lA)

# LAYOUT: izq | consola
$layout=New-Object Windows.Forms.TableLayoutPanel
$layout.Dock='Fill'; $layout.ColumnCount=2; $layout.RowCount=1
$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100)))|Out-Null
$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute,240)))|Out-Null
$layout.BackColor=$cBg; $layout.Margin=New-Object Windows.Forms.Padding(0)
$form.Controls.Add($layout)

# PANEL IZQUIERDO
$left=New-Object Windows.Forms.Panel
$left.Dock='Fill'; $left.BackColor=$cBg; $left.Padding=New-Object Windows.Forms.Padding(16,14,12,14)
$left.AutoScroll=$true
$layout.Controls.Add($left,0,0)

function New-SecLbl($txt,$y){
    $l=New-Object Windows.Forms.Label
    $l.Text=$txt; $l.Location=New-Object Drawing.Point(0,$y); $l.Size=New-Object Drawing.Size(480,16)
    $l.ForeColor=$cAcc; $l.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold)
    $l.BackColor=[Drawing.Color]::Transparent; $left.Controls.Add($l)
}

function New-Card($y,$h){
    $p=New-Object Windows.Forms.Panel
    $p.Location=New-Object Drawing.Point(0,$y); $p.Size=New-Object Drawing.Size(488,$h)
    $p.BackColor=$cCard; $left.Controls.Add($p); return $p
}

# ===== SECCION 1: LIMPIEZA =====
New-SecLbl 'Limpieza de temporales' 0

$c1=New-Card 18 90
$l1=New-Object Windows.Forms.Label; $l1.Text='Elimina archivos temporales del sistema y del usuario que ocupan espacio innecesario.'
$l1.Location=New-Object Drawing.Point(12,10); $l1.Size=New-Object Drawing.Size(464,32)
$l1.ForeColor=$cMut; $l1.Font=New-Object Drawing.Font('Segoe UI',8); $l1.BackColor=[Drawing.Color]::Transparent; $c1.Controls.Add($l1)

$bT1=New-Btn 'Limpiar Temporales del Sistema' 12 46 230 34 'blue'
$bT1.Add_Click({
    Write-Log 'Limpiando carpetas temporales...' 'sub'
    Start-Job2 {
        $count=0
        Get-ChildItem "$env:TEMP\*" -EA SilentlyContinue|ForEach-Object{Remove-Item $_ -Recurse -Force -EA SilentlyContinue;$count++}
        Get-ChildItem 'C:\Windows\Temp\*' -EA SilentlyContinue|ForEach-Object{Remove-Item $_ -Recurse -Force -EA SilentlyContinue;$count++}
        return @{msg="Limpieza completada. $count elementos procesados.";color='ok'}
    }
}); $c1.Controls.Add($bT1)

$bT2=New-Btn 'Limpiar Prefetch' 252 46 180 34
$bT2.Add_Click({
    Write-Log 'Limpiando Prefetch...' 'sub'
    Start-Job2 {
        $count=(Get-ChildItem 'C:\Windows\Prefetch\*' -EA SilentlyContinue).Count
        Remove-Item 'C:\Windows\Prefetch\*' -Recurse -Force -EA SilentlyContinue
        return @{msg="Prefetch limpiado. $count archivos eliminados.";color='ok'}
    }
}); $c1.Controls.Add($bT2)

# ===== SECCION 2: INICIO DEL SISTEMA =====
New-SecLbl 'Configuracion de inicio' 120

$c2=New-Card 138 112
$l2=New-Object Windows.Forms.Label; $l2.Text='Configura el modo de inicio de Windows para diagnostico o uso normal.'
$l2.Location=New-Object Drawing.Point(12,10); $l2.Size=New-Object Drawing.Size(464,22)
$l2.ForeColor=$cMut; $l2.Font=New-Object Drawing.Font('Segoe UI',8); $l2.BackColor=[Drawing.Color]::Transparent; $c2.Controls.Add($l2)

$lMode=New-Object Windows.Forms.Label; $lMode.Text='Modo actual: Consultando...'
$lMode.Location=New-Object Drawing.Point(12,34); $lMode.Size=New-Object Drawing.Size(464,18)
$lMode.ForeColor=$cYel; $lMode.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold); $lMode.BackColor=[Drawing.Color]::Transparent; $c2.Controls.Add($lMode)

$bNorm=New-Btn 'Inicio Normal' 12 56 190 34 'green'
$bNorm.Add_Click({
    Write-Log 'Configurando inicio normal...' 'sub'
    Start-Job2 {
        bcdedit /deletevalue safeboot 2>&1|Out-Null
        $cfg=& msconfig /query 2>&1
        try{
            $r=New-Object -ComObject Shell.Application
            $ms=New-Object System.Diagnostics.ProcessStartInfo('msconfig.exe')
            $ms.UseShellExecute=$true; $ms.Verb='runas'
        }catch{}
        reg add 'HKLM\SYSTEM\CurrentControlSet\Control\SafeBoot\Option' /v 'OptionValue' /t REG_DWORD /d 0 /f 2>&1|Out-Null
        return @{msg='Inicio normal configurado. Reinicia el equipo para aplicar.';color='ok'}
    }
}); $c2.Controls.Add($bNorm)

$bMsconf=New-Btn 'Abrir Config. del Sistema' 212 56 230 34
$bMsconf.Add_Click({Start-Process msconfig.exe; Write-Log 'Configuracion del sistema abierta.' 'info'}); $c2.Controls.Add($bMsconf)

# Consultar modo actual al iniciar
Start-Job2 {
    try{
        $sb=(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\SafeBoot\Option' -EA SilentlyContinue).OptionValue
        $modo=if($sb -and $sb -ne 0){'Modo seguro activo'}else{'Inicio normal'}
        return @{msg="__MODE__$modo";color='mode'}
    }catch{return @{msg='__MODE__Inicio normal';color='mode'}}
}

# ===== SECCION 3: NUCLEOS CPU =====
New-SecLbl 'Optimizacion de CPU' 262

$c3=New-Card 280 112
$l3=New-Object Windows.Forms.Label; $l3.Text='Activa todos los nucleos del procesador en el arranque de Windows para mejorar el rendimiento.'
$l3.Location=New-Object Drawing.Point(12,10); $l3.Size=New-Object Drawing.Size(464,22)
$l3.ForeColor=$cMut; $l3.Font=New-Object Drawing.Font('Segoe UI',8); $l3.BackColor=[Drawing.Color]::Transparent; $c3.Controls.Add($l3)

$cpuInfo=Get-CimInstance Win32_Processor -EA SilentlyContinue
$numCores=if($cpuInfo){$cpuInfo.NumberOfLogicalProcessors}else{4}
$lCpu=New-Object Windows.Forms.Label; $lCpu.Text="CPU detectada: $($cpuInfo.Name)  |  Nucleos logicos: $numCores"
$lCpu.Location=New-Object Drawing.Point(12,34); $lCpu.Size=New-Object Drawing.Size(464,18)
$lCpu.ForeColor=$cAcc; $lCpu.Font=New-Object Drawing.Font('Segoe UI',8); $lCpu.BackColor=[Drawing.Color]::Transparent; $c3.Controls.Add($lCpu)

$bCores=New-Btn "Activar todos los nucleos ($numCores)" 12 56 240 34 'green'
$bCores.Add_Click({
    $nc=$numCores
    Write-Log "Activando $nc nucleos logicos en el arranque..." 'sub'
    Start-Job2 {
        param($n)
        bcdedit /set numproc $n 2>&1|Out-Null
        $key='HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
        Set-ItemProperty $key -Name 'ProcessorControl' -Value $n -EA SilentlyContinue
        return @{msg="Todos los nucleos ($n) activados para el arranque. Reinicia para aplicar.";color='ok'}
    } @($nc)
}); $c3.Controls.Add($bCores)

$bBootCfg=New-Btn 'Abrir Config. de Arranque' 262 56 200 34
$bBootCfg.Add_Click({Start-Process msconfig.exe; Write-Log 'Config de arranque abierta (pestaña Arranque > Opciones avanzadas).' 'info'}); $c3.Controls.Add($bBootCfg)

# ===== SECCION 4: WINDOWS UPDATE =====
New-SecLbl 'Windows Update' 404

$c4=New-Card 422 112
$l4=New-Object Windows.Forms.Label; $l4.Text='Busca e instala las actualizaciones pendientes de Windows para mantener el sistema seguro.'
$l4.Location=New-Object Drawing.Point(12,10); $l4.Size=New-Object Drawing.Size(464,22)
$l4.ForeColor=$cMut; $l4.Font=New-Object Drawing.Font('Segoe UI',8); $l4.BackColor=[Drawing.Color]::Transparent; $c4.Controls.Add($l4)

$lUpdSt=New-Object Windows.Forms.Label; $lUpdSt.Text='Presiona "Buscar actualizaciones" para verificar el estado.'
$lUpdSt.Location=New-Object Drawing.Point(12,34); $lUpdSt.Size=New-Object Drawing.Size(464,18)
$lUpdSt.ForeColor=$cMut; $lUpdSt.Font=New-Object Drawing.Font('Segoe UI',8); $lUpdSt.BackColor=[Drawing.Color]::Transparent; $c4.Controls.Add($lUpdSt)

$bWU=New-Btn 'Buscar Actualizaciones' 12 56 210 34 'blue'
$bWU.Add_Click({
    Start-Process 'ms-settings:windowsupdate'
    Write-Log 'Windows Update abierto. Verifica si hay actualizaciones disponibles.' 'info'
    $lUpdSt.Text='Windows Update abierto en Configuracion de Windows.'
    $lUpdSt.ForeColor=$cAcc
}); $c4.Controls.Add($bWU)

$bWUcmd=New-Btn 'Forzar Busqueda (cmd)' 232 56 210 34 'green'
$bWUcmd.Add_Click({
    Write-Log 'Forzando busqueda de actualizaciones via UsoClient...' 'sub'
    $lUpdSt.Text='Buscando actualizaciones en segundo plano...'
    $lUpdSt.ForeColor=$cYel
    Start-Job2 {
        try{
            UsoClient StartScan 2>&1|Out-Null
            Start-Sleep 3
            return @{msg='Busqueda de actualizaciones iniciada. Revisa Windows Update para ver resultados.';color='ok'}
        }catch{return @{msg="Error al buscar: $_";color='err'}}
    }
}); $c4.Controls.Add($bWUcmd)

# CONSOLA
$conPanel=New-Object Windows.Forms.Panel
$conPanel.Dock='Fill'; $conPanel.BackColor=$cOut
$layout.Controls.Add($conPanel,1,0)

$conTop=New-Object Windows.Forms.Panel
$conTop.Location=New-Object Drawing.Point(0,0); $conTop.Size=New-Object Drawing.Size(240,30)
$conTop.BackColor=$cPanel; $conPanel.Controls.Add($conTop)

$lCon=New-Object Windows.Forms.Label; $lCon.Text='  Registro de actividad'
$lCon.Location=New-Object Drawing.Point(0,6); $lCon.Size=New-Object Drawing.Size(148,18)
$lCon.ForeColor=$cAcc; $lCon.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold)
$lCon.BackColor=[Drawing.Color]::Transparent; $conTop.Controls.Add($lCon)

$btnClr=New-Object Windows.Forms.Button
$btnClr.Text='Limpiar'; $btnClr.Location=New-Object Drawing.Point(150,4); $btnClr.Size=New-Object Drawing.Size(60,22)
$btnClr.BackColor=$cCard; $btnClr.ForeColor=$cMut; $btnClr.FlatStyle='Flat'
$btnClr.FlatAppearance.BorderColor=$cBdr; $btnClr.Font=New-Object Drawing.Font('Segoe UI',7)
$btnClr.Add_Click({$outputBox.Clear();Write-Log 'Consola limpiada.' 'sub'}); $conTop.Controls.Add($btnClr)

$outputBox=New-Object Windows.Forms.RichTextBox
$outputBox.Location=New-Object Drawing.Point(0,31); $outputBox.Size=New-Object Drawing.Size(240,435)
$outputBox.BackColor=$cOut; $outputBox.ForeColor=$cAcc
$outputBox.Font=New-Object Drawing.Font('Consolas',8); $outputBox.ReadOnly=$true
$outputBox.BorderStyle='None'; $outputBox.WordWrap=$true
$conPanel.Controls.Add($outputBox)
$conPanel.Add_Resize({ $w = $conPanel.Width; $h = $conPanel.Height - 31; $outputBox.Size = New-Object Drawing.Size($w, $h) })

# STATUS BAR
$sb=New-Object Windows.Forms.Panel
$sb.Dock='Bottom'; $sb.Height=26; $sb.BackColor=$cPanel
$form.Controls.Add($sb)

$lSt=New-Object Windows.Forms.Label; $lSt.Text='Listo'
$lSt.Location=New-Object Drawing.Point(12,5); $lSt.Size=New-Object Drawing.Size(500,16)
$lSt.ForeColor=$cGreen; $lSt.Font=New-Object Drawing.Font('Segoe UI',8)
$sb.Controls.Add($lSt)

# TIMER JOBS
$jt=New-Object Windows.Forms.Timer; $jt.Interval=350
$jt.Add_Tick({
    $done=$Global:Jobs|Where-Object{$_.Handle.IsCompleted}
    foreach($j in $done){
        try{
            $res=$j.PS.EndInvoke($j.Handle)
            foreach($r in $res){
                if($r -is [hashtable] -and $r.color -eq 'mode'){
                    $val=$r.msg -replace '^__MODE__',''
                    $lMode.Text="Modo actual: $val"
                    $lMode.ForeColor=if($val-like'*seguro*'){$cRed}else{$cGreen}
                }elseif($r -is [hashtable] -and $r.ContainsKey('msg')){
                    Write-Log $r.msg $r.color
                    if($r.color-eq'ok'){$lSt.Text=$r.msg;$lSt.ForeColor=$cGreen}
                    elseif($r.color-eq'err'){$lSt.Text='Error: '+$r.msg;$lSt.ForeColor=$cRed}
                }elseif($r){Write-Log ($r|Out-String).Trim() 'n'}
            }
            if($j.PS.Streams.Error.Count-gt0){foreach($e in $j.PS.Streams.Error){Write-Log "Error: $e" 'err'}}
        }catch{}finally{$j.PS.Dispose()}
    }
    $Global:Jobs.RemoveAll({param($x)$x.Handle.IsCompleted})|Out-Null
}); $jt.Start()

# INICIO
Write-Log 'SysCodi QuickFix listo.' 'info'
Write-Log "Usuario: $env:USERNAME  |  $(if($isAdmin){'Administrador'}else{'ADVERTENCIA: ejecutar como administrador para todas las funciones'})" $(if($isAdmin){'ok'}else{'warn'})

$form.Add_FormClosing({$jt.Stop();$Global:RSPool.Close();$Global:RSPool.Dispose()})
[Windows.Forms.Application]::Run($form)
