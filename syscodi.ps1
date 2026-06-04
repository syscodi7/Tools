#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#  RUNSPACE POOL - Anti freeze
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
}

# ============================================================
#  COLORES
# ============================================================
$cBg     = [Drawing.Color]::FromArgb(13, 27, 46)
$cPanel  = [Drawing.Color]::FromArgb(9, 18, 32)
$cCard   = [Drawing.Color]::FromArgb(16, 36, 66)
$cAccent = [Drawing.Color]::FromArgb(0, 120, 212)
$cAcc2   = [Drawing.Color]::FromArgb(0, 180, 240)
$cText   = [Drawing.Color]::FromArgb(220, 238, 255)
$cSub    = [Drawing.Color]::FromArgb(80, 130, 175)
$cGreen  = [Drawing.Color]::FromArgb(60, 180, 90)
$cRed    = [Drawing.Color]::FromArgb(210, 70, 70)
$cYellow = [Drawing.Color]::FromArgb(230, 170, 50)
$cOutput = [Drawing.Color]::FromArgb(7, 15, 28)
$cBorder = [Drawing.Color]::FromArgb(25, 55, 95)
$cNavAct = [Drawing.Color]::FromArgb(10, 42, 80)

# ============================================================
#  HELPERS
# ============================================================
function New-Btn($text, $x, $y, $w=190, $h=32, $style='normal') {
    $b = New-Object Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object Drawing.Point($x,$y)
    $b.Size = New-Object Drawing.Size($w,$h)
    $b.FlatStyle = 'Flat'
    $b.Cursor = 'Hand'
    $b.Font = New-Object Drawing.Font('Segoe UI',9)
    switch($style){
        'green'  { $b.BackColor=[Drawing.Color]::FromArgb(8,36,22);  $b.ForeColor=[Drawing.Color]::FromArgb(100,210,140); $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(20,80,45) }
        'red'    { $b.BackColor=[Drawing.Color]::FromArgb(36,10,10);  $b.ForeColor=[Drawing.Color]::FromArgb(230,110,110); $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(90,25,25) }
        'orange' { $b.BackColor=[Drawing.Color]::FromArgb(36,22,5);   $b.ForeColor=[Drawing.Color]::FromArgb(230,170,70);  $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(90,55,10) }
        'accent' { $b.BackColor=[Drawing.Color]::FromArgb(0,80,160);  $b.ForeColor=$cText;                                 $b.FlatAppearance.BorderColor=$cAccent }
        default  { $b.BackColor=$cCard; $b.ForeColor=$cText; $b.FlatAppearance.BorderColor=$cBorder }
    }
    $b.FlatAppearance.BorderSize = 1
    return $b
}

function New-Lbl($text,$x,$y,$w,$h,$color,$font){
    $l = New-Object Windows.Forms.Label
    $l.Text=$text; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size($w,$h)
    $l.ForeColor=$color; $l.Font=$font; $l.BackColor=[Drawing.Color]::Transparent
    return $l
}

function New-SecLbl($text,$x,$y,$parent){
    $l = New-Lbl $text $x $y 640 18 $cAccent (New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold))
    $parent.Controls.Add($l)
}

function Write-Log($msg,$type='normal'){
    if(-not $msg){return}
    $ts = Get-Date -Format 'HH:mm:ss'
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionColor = [Drawing.Color]::FromArgb(40,85,135)
    $outputBox.AppendText("`n[$ts] ")
    $outputBox.SelectionColor = switch($type){
        'ok'    {$cGreen}   'warn' {$cYellow} 'err'  {$cRed}
        'info'  {$cAcc2}    'sub'  {$cSub}    default{$cText}
    }
    $outputBox.AppendText($msg)
    $outputBox.ScrollToCaret()
}

function Run-Async($label,[scriptblock]$block,[object[]]$args=@()){
    Write-Log "$label..." 'sub'
    Start-AsyncJob -Code $block -Args $args
}

# ============================================================
#  FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text = 'SysCodi WinTool Pro v3'
$form.Size = New-Object Drawing.Size(1100,680)
$form.MinimumSize = New-Object Drawing.Size(1000,600)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $cBg
$form.ForeColor = $cText
$form.Font = New-Object Drawing.Font('Segoe UI',9)

# ---- TITLEBAR ----
$titleBar = New-Object Windows.Forms.Panel
$titleBar.Dock = 'Top'; $titleBar.Height = 52; $titleBar.BackColor = $cPanel
$form.Controls.Add($titleBar)

$lblT = New-Lbl 'SysCodi WinTool Pro v3' 14 8 400 26 $cAcc2 (New-Object Drawing.Font('Segoe UI',14,[Drawing.FontStyle]::Bold))
$titleBar.Controls.Add($lblT)
$lblS = New-Lbl 'Utilidad avanzada de sistema para Windows  v3.0' 16 34 420 16 $cSub (New-Object Drawing.Font('Segoe UI',8))
$titleBar.Controls.Add($lblS)

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$lblAdm = New-Lbl (if($isAdmin){'[Admin]'}else{'[Sin admin]'}) 940 18 150 20 (if($isAdmin){$cGreen}else{$cRed}) (New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold))
$titleBar.Controls.Add($lblAdm)

# ---- STATUS BAR ----
$statusBar = New-Object Windows.Forms.Panel
$statusBar.Dock = 'Bottom'; $statusBar.Height = 26; $statusBar.BackColor = $cPanel
$form.Controls.Add($statusBar)

$lblSt  = New-Lbl 'Listo' 10 5 100 18 $cGreen (New-Object Drawing.Font('Segoe UI',8))
$lblMon = New-Lbl 'CPU --%   RAM -- GB   C: -- GB' 110 5 500 18 $cSub (New-Object Drawing.Font('Segoe UI',8))
$statusBar.Controls.Add($lblSt)
$statusBar.Controls.Add($lblMon)

# ---- LAYOUT: sidebar | contenido | consola ----
$layout = New-Object Windows.Forms.TableLayoutPanel
$layout.Dock = 'Fill'; $layout.ColumnCount = 3; $layout.RowCount = 1
$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute,155))) | Out-Null
$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Percent,100))) | Out-Null
$layout.ColumnStyles.Add((New-Object Windows.Forms.ColumnStyle([Windows.Forms.SizeType]::Absolute,240))) | Out-Null
$layout.BackColor = $cBg; $layout.Margin = New-Object Windows.Forms.Padding(0)
$form.Controls.Add($layout)

# ============================================================
#  SIDEBAR
# ============================================================
$sidebar = New-Object Windows.Forms.Panel
$sidebar.Dock = 'Fill'; $sidebar.BackColor = $cPanel; $sidebar.Padding = New-Object Windows.Forms.Padding(5,8,5,8)
$layout.Controls.Add($sidebar,0,0)

$navDefs = @('Reparacion','Aplicaciones','Tweaks','Utilidades','Seguridad','Backup','Sistema')
$navBtns = @()
$ny = 8
foreach($nd in $navDefs){
    $nb = New-Object Windows.Forms.Button
    $nb.Text = "  $nd"; $nb.Location = New-Object Drawing.Point(4,$ny)
    $nb.Size = New-Object Drawing.Size(143,38); $nb.FlatStyle = 'Flat'
    $nb.FlatAppearance.BorderSize = 0; $nb.BackColor = $cPanel
    $nb.ForeColor = $cSub; $nb.Font = New-Object Drawing.Font('Segoe UI',9)
    $nb.TextAlign = 'MiddleLeft'; $nb.Cursor = 'Hand'
    $sidebar.Controls.Add($nb); $navBtns += $nb; $ny += 44
}

# ============================================================
#  CONTENIDO - paginas apiladas
# ============================================================
$contentHost = New-Object Windows.Forms.Panel
$contentHost.Dock = 'Fill'; $contentHost.BackColor = $cBg
$layout.Controls.Add($contentHost,1,0)

function New-Page{
    $p = New-Object Windows.Forms.Panel
    $p.Dock = 'Fill'; $p.BackColor = $cBg; $p.AutoScroll = $true
    $p.Padding = New-Object Windows.Forms.Padding(16,14,16,14); $p.Visible = $false
    $contentHost.Controls.Add($p); return $p
}

$pages = 0..6 | ForEach-Object { New-Page }

function Set-Page($i){
    for($j=0;$j-lt$pages.Count;$j++){ $pages[$j].Visible=($j-eq$i) }
    for($j=0;$j-lt$navBtns.Count;$j++){
        if($j-eq$i){ $navBtns[$j].BackColor=$cNavAct; $navBtns[$j].ForeColor=$cAcc2 }
        else         { $navBtns[$j].BackColor=$cPanel;   $navBtns[$j].ForeColor=$cSub  }
    }
}
for($i=0;$i-lt$navBtns.Count;$i++){ $idx=$i; $navBtns[$i].Add_Click({Set-Page $idx}.GetNewClosure()) }

# ============================================================
#  CONSOLA
# ============================================================
$conPanel = New-Object Windows.Forms.Panel
$conPanel.Dock = 'Fill'; $conPanel.BackColor = $cOutput
$layout.Controls.Add($conPanel,2,0)

$conTop = New-Object Windows.Forms.Panel
$conTop.Location = New-Object Drawing.Point(0,0); $conTop.Size = New-Object Drawing.Size(240,28)
$conTop.BackColor = $cPanel; $conPanel.Controls.Add($conTop)

$lConTitle = New-Lbl 'Consola de salida' 8 6 130 18 $cAcc2 (New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold))
$conTop.Controls.Add($lConTitle)

$btnSave = New-Object Windows.Forms.Button
$btnSave.Text='Guardar'; $btnSave.Location=New-Object Drawing.Point(140,4); $btnSave.Size=New-Object Drawing.Size(48,20)
$btnSave.BackColor=$cCard; $btnSave.ForeColor=$cText; $btnSave.FlatStyle='Flat'
$btnSave.FlatAppearance.BorderColor=$cBorder; $btnSave.Font=New-Object Drawing.Font('Segoe UI',7)
$btnSave.Add_Click({
    $d=New-Object Windows.Forms.SaveFileDialog; $d.Filter='Log (*.log)|*.log|Txt (*.txt)|*.txt'
    $d.FileName="SysCodi_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
    if($d.ShowDialog()-eq'OK'){$outputBox.Text|Set-Content $d.FileName -Encoding UTF8; Write-Log "Log guardado: $($d.FileName)" 'ok'}
}); $conTop.Controls.Add($btnSave)

$btnClr = New-Object Windows.Forms.Button
$btnClr.Text='Limpiar'; $btnClr.Location=New-Object Drawing.Point(190,4); $btnClr.Size=New-Object Drawing.Size(48,20)
$btnClr.BackColor=$cCard; $btnClr.ForeColor=$cText; $btnClr.FlatStyle='Flat'
$btnClr.FlatAppearance.BorderColor=$cBorder; $btnClr.Font=New-Object Drawing.Font('Segoe UI',7)
$btnClr.Add_Click({$outputBox.Clear(); Write-Log 'Consola limpiada.' 'sub'}); $conTop.Controls.Add($btnClr)

$searchTxt = New-Object Windows.Forms.TextBox
$searchTxt.Location=New-Object Drawing.Point(0,29); $searchTxt.Size=New-Object Drawing.Size(200,22)
$searchTxt.BackColor=[Drawing.Color]::FromArgb(10,22,40); $searchTxt.ForeColor=$cSub
$searchTxt.BorderStyle='FixedSingle'; $searchTxt.Font=New-Object Drawing.Font('Consolas',8)
$searchTxt.Text='Buscar en consola...'
$searchTxt.Add_Enter({if($searchTxt.Text-eq'Buscar en consola...'){$searchTxt.Text='';$searchTxt.ForeColor=$cText}})
$searchTxt.Add_Leave({if($searchTxt.Text-eq''){$searchTxt.Text='Buscar en consola...';$searchTxt.ForeColor=$cSub}})
$conPanel.Controls.Add($searchTxt)

$btnFind = New-Object Windows.Forms.Button
$btnFind.Text='Ir'; $btnFind.Location=New-Object Drawing.Point(201,29); $btnFind.Size=New-Object Drawing.Size(34,22)
$btnFind.BackColor=$cCard; $btnFind.ForeColor=$cText; $btnFind.FlatStyle='Flat'
$btnFind.FlatAppearance.BorderColor=$cBorder; $btnFind.Font=New-Object Drawing.Font('Segoe UI',7)
$btnFind.Add_Click({
    $q=$searchTxt.Text.Trim()
    if($q-and$q-ne'Buscar en consola...'){
        $idx=$outputBox.Text.IndexOf($q,[StringComparison]::OrdinalIgnoreCase)
        if($idx-ge0){$outputBox.Select($idx,$q.Length);$outputBox.ScrollToCaret()}
        else{Write-Log "No encontrado: $q" 'warn'}
    }
}); $conPanel.Controls.Add($btnFind)

$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location=New-Object Drawing.Point(0,52); $outputBox.Size=New-Object Drawing.Size(240,530)
$outputBox.BackColor=$cOutput; $outputBox.ForeColor=$cAcc2
$outputBox.Font=New-Object Drawing.Font('Consolas',8); $outputBox.ReadOnly=$true
$outputBox.BorderStyle='None'; $outputBox.WordWrap=$true
$outputBox.Text='Listo. Selecciona una opcion y ejecuta.'
$conPanel.Controls.Add($outputBox)

$conPanel.Add_Resize({ $outputBox.Size=New-Object Drawing.Size($conPanel.Width, $conPanel.Height-52) })

# ============================================================
#  TIMER - recoge jobs async
# ============================================================
$jobTimer = New-Object Windows.Forms.Timer; $jobTimer.Interval=350
$jobTimer.Add_Tick({
    $done = $Global:Jobs|Where-Object{$_.Handle.IsCompleted}
    foreach($j in $done){
        try{
            $results=$j.PS.EndInvoke($j.Handle)
            foreach($r in $results){
                if($r-is[hashtable]-and$r.ContainsKey('msg')){Write-Log $r.msg $r.color}
                elseif($r){Write-Log ($r|Out-String).Trim() 'normal'}
            }
            if($j.PS.Streams.Error.Count-gt0){
                foreach($e in $j.PS.Streams.Error){Write-Log "Error: $e" 'err'}
            }
        }catch{Write-Log "Error job: $_" 'err'}
        finally{$j.PS.Dispose()}
    }
    $Global:Jobs.RemoveAll({param($x)$x.Handle.IsCompleted})|Out-Null
})
$jobTimer.Start()

# MONITOR STATUS
$monTimer = New-Object Windows.Forms.Timer; $monTimer.Interval=3500
$monTimer.Add_Tick({
    try{
        $os=(Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue)
        $cp=(Get-CimInstance Win32_Processor -EA SilentlyContinue|Measure-Object -Property LoadPercentage -Average).Average
        $rf=[math]::Round($os.FreePhysicalMemory/1MB,1)
        $dk=Get-PSDrive C -EA SilentlyContinue
        $df=[math]::Round($dk.Free/1GB,1)
        $lblMon.Text="CPU $($cp)%   RAM libre: $rf GB   C: $df GB libres"
        $lblMon.ForeColor=if($cp-gt80){$cRed}elseif($cp-gt50){$cYellow}else{$cGreen}
    }catch{}
})

# ============================================================
#  PAGINA 0: REPARACION
# ============================================================
$p0=$pages[0]

New-SecLbl 'Limpieza del sistema' 0 4 $p0

$b=New-Btn 'Limpiar Temporales' 0 26; $b.Add_Click({
    Run-Async 'Limpiando temporales' {
        Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue
        Remove-Item 'C:\Windows\Temp\*' -Recurse -Force -EA SilentlyContinue
        return @{msg='Temporales eliminados.';color='ok'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'Limpiar Prefetch' 198 26; $b.Add_Click({
    Run-Async 'Limpiando Prefetch' {
        Remove-Item 'C:\Windows\Prefetch\*' -Recurse -Force -EA SilentlyContinue
        return @{msg='Prefetch limpiado.';color='ok'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'Cache Windows Update' 396 26; $b.Add_Click({
    Run-Async 'Limpiando cache WU' {
        Stop-Service wuauserv -Force -EA SilentlyContinue
        Remove-Item 'C:\Windows\SoftwareDistribution\Download\*' -Recurse -Force -EA SilentlyContinue
        Start-Service wuauserv -EA SilentlyContinue
        return @{msg='Cache de Windows Update limpiada.';color='ok'}
    }
}); $p0.Controls.Add($b)

New-SecLbl 'Reparacion de Windows' 0 70 $p0

$b=New-Btn 'SFC /scannow' 0 92 190 32 'green'; $b.Add_Click({
    Run-Async 'SFC /scannow' {
        $r=& sfc /scannow 2>&1; return @{msg=($r-join"`n");color='normal'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'DISM RestoreHealth' 198 92 190 32 'green'; $b.Add_Click({
    Run-Async 'DISM RestoreHealth' {
        $r=& DISM /Online /Cleanup-Image /RestoreHealth 2>&1; return @{msg=($r-join"`n");color='normal'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'CheckDisk (C:)' 396 92 190 32 'orange'; $b.Add_Click({
    Run-Async 'CheckDisk C:' {
        $r=& chkdsk C: /f /r /x 2>&1; return @{msg=($r-join"`n");color='normal'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'Reparar Microsoft Store' 0 132; $b.Add_Click({
    Write-Log 'Reiniciando Microsoft Store...' 'sub'; Start-Process wsreset.exe; Write-Log 'Store reiniciada.' 'ok'
}); $p0.Controls.Add($b)

$b=New-Btn 'Crear Punto Restauracion' 198 132; $b.Add_Click({
    Run-Async 'Creando punto de restauracion' {
        try{
            Checkpoint-Computer -Description "SysCodi $(Get-Date -Format 'dd/MM/yyyy')" -RestorePointType MODIFY_SETTINGS
            return @{msg='Punto de restauracion creado.';color='ok'}
        }catch{return @{msg="Error: $_";color='err'}}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'Abrir Restaurar Sistema' 396 132; $b.Add_Click({Start-Process rstrui.exe}); $p0.Controls.Add($b)

New-SecLbl 'Red' 0 176 $p0

$b=New-Btn 'DNS Flush' 0 198; $b.Add_Click({
    Run-Async 'DNS Flush' {$r=& ipconfig /flushdns 2>&1;return @{msg=($r-join"`n");color='ok'}}
}); $p0.Controls.Add($b)

$b=New-Btn 'Reset Red (netsh)' 198 198; $b.Add_Click({
    Run-Async 'Reseteando red' {
        netsh int ip reset 2>&1|Out-Null; netsh winsock reset 2>&1|Out-Null
        return @{msg='Red reseteada. Reinicia el PC para aplicar cambios.';color='warn'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'Ver Puertos Abiertos' 396 198; $b.Add_Click({
    Run-Async 'Puertos abiertos' {$r=& netstat -ano 2>&1;return @{msg=($r-join"`n");color='normal'}}
}); $p0.Controls.Add($b)

$b=New-Btn 'Diagnostico de Red' 0 238; $b.Add_Click({
    Run-Async 'Diagnostico de red' {
        $r=@('--- Ping 8.8.8.8 ---')
        $r+=(ping 8.8.8.8 -n 3 2>&1)
        $tnc=Test-NetConnection google.com -Port 443 -EA SilentlyContinue
        $r+="Google 443: $(if($tnc.TcpTestSucceeded){'OK'}else{'SIN CONEXION'})"
        return @{msg=($r-join"`n");color='normal'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'Matar Puerto 80' 198 238 190 32 'red'; $b.Add_Click({
    Run-Async 'Matando procesos en puerto 80' {
        $pids=(netstat -ano|Select-String ':80\s')-replace'.*\s(\d+)$','$1'|Sort-Object -Unique
        $k=0
        foreach($p in $pids){if($p-match'^\d+$'){Stop-Process -Id $p -Force -EA SilentlyContinue;$k++}}
        return @{msg=if($k){"$k proceso(s) en puerto 80 terminados."}else{'Ningun proceso en puerto 80.'};color='ok'}
    }
}); $p0.Controls.Add($b)

New-SecLbl 'Servicios y Eventos' 0 282 $p0

$b=New-Btn 'Servicios Activos al Inicio' 0 304; $b.Add_Click({
    Run-Async 'Servicios en inicio' {
        $s=Get-Service|Where-Object{$_.StartType-eq'Automatic'-and$_.Status-eq'Running'}|Select-Object -First 30
        $lines=$s|ForEach-Object{"$($_.Name) - $($_.DisplayName)"}
        return @{msg="--- Servicios automaticos activos ---`n"+($lines-join"`n");color='normal'}
    }
}); $p0.Controls.Add($b)

$b=New-Btn 'Errores del Sistema' 198 304 190 32 'red'; $b.Add_Click({
    Run-Async 'Leyendo errores del sistema' {
        try{
            $e=Get-EventLog -LogName System -EntryType Error -Newest 10
            $lines=$e|ForEach-Object{"$($_.TimeGenerated.ToString('dd/MM HH:mm')) [$($_.Source)] $($_.Message.Substring(0,[Math]::Min(90,$_.Message.Length)))"}
            return @{msg="--- Ultimos 10 errores ---`n"+($lines-join"`n");color='err'}
        }catch{return @{msg="Error al leer log: $_";color='err'}}
    }
}); $p0.Controls.Add($b)

# ============================================================
#  PAGINA 1: APLICACIONES
# ============================================================
$p1=$pages[1]

$txtFilt=New-Object Windows.Forms.TextBox
$txtFilt.Location=New-Object Drawing.Point(0,0); $txtFilt.Size=New-Object Drawing.Size(380,26)
$txtFilt.BackColor=$cCard; $txtFilt.ForeColor=$cSub; $txtFilt.BorderStyle='FixedSingle'
$txtFilt.Font=New-Object Drawing.Font('Segoe UI',9); $txtFilt.Text='Buscar aplicacion...'
$p1.Controls.Add($txtFilt)

$btnVerInst=New-Btn 'Ver instaladas' 390 0 150 26; $btnVerInst.Add_Click({
    Run-Async 'Listando apps instaladas' {$r=winget list 2>&1;return @{msg=($r-join"`n");color='normal'}}
}); $p1.Controls.Add($btnVerInst)

$btnUpAll=New-Btn 'Actualizar todo' 548 0 150 26 'green'; $btnUpAll.Add_Click({
    Write-Log 'Actualizando apps con winget...' 'sub'
    Start-Process powershell -ArgumentList '-NoProfile -Command "winget upgrade --all --silent"' -Verb RunAs
    Write-Log 'Actualizacion iniciada en ventana separada.' 'ok'
}); $p1.Controls.Add($btnUpAll)

$appScroll=New-Object Windows.Forms.Panel
$appScroll.Location=New-Object Drawing.Point(0,34); $appScroll.Size=New-Object Drawing.Size(700,370)
$appScroll.AutoScroll=$true; $appScroll.BackColor=$cBg
$p1.Controls.Add($appScroll)

$appData=@(
    @{cat='Navegadores';      name='Google Chrome';   cmd='winget install -e --id Google.Chrome';                         foss=$false}
    @{cat='Navegadores';      name='Mozilla Firefox';  cmd='winget install -e --id Mozilla.Firefox';                       foss=$true }
    @{cat='Navegadores';      name='Brave Browser';    cmd='winget install -e --id Brave.Brave';                           foss=$true }
    @{cat='Navegadores';      name='LibreWolf';        cmd='winget install -e --id LibreWolf.LibreWolf';                   foss=$true }
    @{cat='Comunicacion';     name='Discord';          cmd='winget install -e --id Discord.Discord';                       foss=$false}
    @{cat='Comunicacion';     name='Telegram';         cmd='winget install -e --id Telegram.TelegramDesktop';              foss=$true }
    @{cat='Comunicacion';     name='Slack';            cmd='winget install -e --id SlackTechnologies.Slack';               foss=$false}
    @{cat='Comunicacion';     name='Signal';           cmd='winget install -e --id OpenWhisperSystems.Signal';             foss=$true }
    @{cat='Desarrollo';       name='VS Code';          cmd='winget install -e --id Microsoft.VisualStudioCode';            foss=$false}
    @{cat='Desarrollo';       name='Git';              cmd='winget install -e --id Git.Git';                               foss=$true }
    @{cat='Desarrollo';       name='Python 3';         cmd='winget install -e --id Python.Python.3';                       foss=$true }
    @{cat='Desarrollo';       name='NodeJS LTS';       cmd='winget install -e --id OpenJS.NodeJS.LTS';                     foss=$true }
    @{cat='Herramientas';     name='7-Zip';            cmd='winget install -e --id 7zip.7zip';                             foss=$true }
    @{cat='Herramientas';     name='VLC';              cmd='winget install -e --id VideoLAN.VLC';                          foss=$true }
    @{cat='Herramientas';     name='WinRAR';           cmd='winget install -e --id RARLab.WinRAR';                         foss=$false}
    @{cat='Herramientas';     name='Notepad++';        cmd='winget install -e --id Notepad++.Notepad++';                   foss=$true }
    @{cat='Herramientas';     name='Everything';       cmd='winget install -e --id voidtools.Everything';                  foss=$true }
    @{cat='Herramientas';     name='ShareX';           cmd='winget install -e --id ShareX.ShareX';                        foss=$true }
    @{cat='Herramientas';     name='Rufus';            cmd='winget install -e --id Rufus.Rufus';                           foss=$true }
    @{cat='Multimedia';       name='OBS Studio';       cmd='winget install -e --id OBSProject.OBSStudio';                 foss=$true }
    @{cat='Hardware';         name='CrystalDiskInfo';  cmd='winget install -e --id CrystalDewWorld.CrystalDiskInfo';       foss=$true }
    @{cat='Hardware';         name='HWiNFO';           cmd='winget install -e --id REALiX.HWiNFO';                        foss=$false}
    @{cat='Hardware';         name='GPU-Z';            cmd='winget install -e --id TechPowerUp.GPU-Z';                    foss=$false}
    @{cat='Seguridad';        name='Bitwarden';        cmd='winget install -e --id Bitwarden.Bitwarden';                  foss=$true }
    @{cat='Microsoft Office'; name='Office 2019';      cmd='winget install -e --id Microsoft.Office2019.HomeAndBusiness'; foss=$false}
    @{cat='Microsoft Office'; name='Office 2021';      cmd='winget install -e --id Microsoft.Office2021.HomeAndBusiness'; foss=$false}
    @{cat='Microsoft Office'; name='Office 2024';      cmd='winget install -e --id Microsoft.Office2024.HomeAndBusiness'; foss=$false}
    @{cat='Microsoft Office'; name='Microsoft 365';    cmd='winget install -e --id Microsoft.Microsoft365';               foss=$false}
    @{cat='Microsoft Office'; name='Teams';            cmd='winget install -e --id Microsoft.Teams';                      foss=$false}
)

$appCbs=@()
function Rebuild-Apps($filter=''){
    $appScroll.Controls.Clear(); $script:appCbs=@()
    $yy=4; $lastCat=''; $col=0
    foreach($a in $appData){
        if($filter -and $a.name -notlike "*$filter*" -and $a.cat -notlike "*$filter*"){continue}
        if($a.cat-ne$lastCat){
            if($lastCat-ne''){$yy+=6}
            $col=0
            $cl=New-Object Windows.Forms.Label
            $cl.Text="  $($a.cat)"; $cl.Location=New-Object Drawing.Point(2,$yy)
            $cl.Size=New-Object Drawing.Size(680,18); $cl.ForeColor=$cAcc2
            $cl.Font=New-Object Drawing.Font('Segoe UI',8,[Drawing.FontStyle]::Bold)
            $cl.BackColor=[Drawing.Color]::Transparent
            $appScroll.Controls.Add($cl); $yy+=20; $lastCat=$a.cat
        }
        $cb=New-Object Windows.Forms.CheckBox
        $cb.Text=$a.name
        $cb.Location=New-Object Drawing.Point((4+$col*168),$yy)
        $cb.Size=New-Object Drawing.Size(162,22)
        $cb.ForeColor=if($a.foss){$cAcc2}else{$cText}
        $cb.BackColor=$cBg; $cb.Tag=$a.cmd
        $appScroll.Controls.Add($cb); $script:appCbs+=$cb
        $col++; if($col-ge4){$col=0;$yy+=24}
    }
}
Rebuild-Apps

$txtFilt.Add_TextChanged({
    $q=$txtFilt.Text.Trim()
    Rebuild-Apps (if($q-eq'Buscar aplicacion...'){''}else{$q})
})
$txtFilt.Add_Enter({if($txtFilt.Text-eq'Buscar aplicacion...'){$txtFilt.Text='';$txtFilt.ForeColor=$cText}})
$txtFilt.Add_Leave({if($txtFilt.Text-eq''){$txtFilt.Text='Buscar aplicacion...';$txtFilt.ForeColor=$cSub}})

$pBar=New-Object Windows.Forms.Panel
$pBar.Location=New-Object Drawing.Point(0,412); $pBar.Size=New-Object Drawing.Size(700,44)
$pBar.BackColor=$cPanel; $p1.Controls.Add($pBar)

$lFoss=New-Lbl 'Azul claro = FOSS (Software Libre)' 8 13 220 18 $cAcc2 (New-Object Drawing.Font('Segoe UI',8))
$pBar.Controls.Add($lFoss)

$bInst=New-Btn 'Instalar seleccionadas' 470 6 220 32 'accent'; $bInst.Add_Click({
    $sel=$script:appCbs|Where-Object{$_.Checked}
    if($sel.Count-eq0){Write-Log 'No seleccionaste ninguna aplicacion.' 'warn';return}
    foreach($cb in $sel){
        $cmd=$cb.Tag; $name=$cb.Text
        Write-Log "Instalando: $name" 'sub'
        Start-AsyncJob -Code{
            param($c,$n)
            & powershell -NoProfile -Command $c 2>&1|Out-Null
            return @{msg="$n instalado.";color='ok'}
        } -Args @($cmd,$name)
    }
}); $pBar.Controls.Add($bInst)

# ============================================================
#  PAGINA 2: TWEAKS
# ============================================================
$p2=$pages[2]
New-SecLbl 'Rendimiento, privacidad y experiencia' 0 4 $p2

$tweaksData=@(
    @{name='Plan energia: alto rendimiento';   cmd='powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c';undo='powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e'}
    @{name='Deshabilitar notificaciones';       cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f';undo='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f'}
    @{name='Deshabilitar telemetria';           cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f';undo='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f'}
    @{name='Deshabilitar Cortana';              cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f';undo='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f'}
    @{name='Activar modo juego';                cmd='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f';undo='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f'}
    @{name='Mostrar extensiones de archivo';    cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f';undo='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f'}
    @{name='Mostrar archivos ocultos';          cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f';undo='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f'}
    @{name='Deshabilitar OneDrive al inicio';   cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /t REG_SZ /d "" /f';undo=''}
    @{name='Deshabilitar Xbox Game Bar';        cmd='reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f';undo='reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 1 /f'}
    @{name='Activar GodMode en Escritorio';     cmd='$gm="$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}";New-Item -ItemType Directory -Path $gm -EA SilentlyContinue';undo='Remove-Item "$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}" -EA SilentlyContinue'}
    @{name='Deshabilitar actualizaciones auto'; cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f';undo='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /f'}
)

$twCbs=@(); $yT=26; $colT=0
foreach($tw in $tweaksData){
    $cb=New-Object Windows.Forms.CheckBox
    $cb.Text=$tw.name
    $cb.Location=New-Object Drawing.Point(($colT*320),$yT)
    $cb.Size=New-Object Drawing.Size(312,26)
    $cb.ForeColor=$cText; $cb.BackColor=$cBg
    $cb.Tag=$tw.cmd; $cb.AccessibleDescription=$tw.undo
    $p2.Controls.Add($cb); $twCbs+=$cb
    $colT++; if($colT-ge2){$colT=0;$yT+=28}
}

$bApl=New-Btn 'Aplicar seleccionados' 0 ($yT+16) 210 34 'green'; $bApl.Add_Click({
    $sel=$twCbs|Where-Object{$_.Checked}
    if($sel.Count-eq0){Write-Log 'No seleccionaste ningun tweak.' 'warn';return}
    foreach($cb in $sel){
        $cmd=$cb.Tag; $name=$cb.Text
        Start-AsyncJob -Code{
            param($c,$n)
            try{Invoke-Expression $c 2>&1|Out-Null;return @{msg="Tweak aplicado: $n";color='ok'}}
            catch{return @{msg="Error en $n`: $_";color='err'}}
        } -Args @($cmd,$name)
    }
    Write-Log 'Tweaks aplicados. Puede requerir reinicio.' 'warn'
}); $p2.Controls.Add($bApl)

$bRev=New-Btn 'Revertir seleccionados' 218 ($yT+16) 210 34 'orange'; $bRev.Add_Click({
    $sel=$twCbs|Where-Object{$_.Checked-and$_.AccessibleDescription}
    if($sel.Count-eq0){Write-Log 'Nada para revertir.' 'warn';return}
    foreach($cb in $sel){
        $cmd=$cb.AccessibleDescription; $name=$cb.Text
        Start-AsyncJob -Code{
            param($c,$n)
            try{Invoke-Expression $c 2>&1|Out-Null;return @{msg="Revertido: $n";color='warn'}}
            catch{return @{msg="Error revirtiendo $n`: $_";color='err'}}
        } -Args @($cmd,$name)
    }
}); $p2.Controls.Add($bRev)

# ============================================================
#  PAGINA 3: UTILIDADES
# ============================================================
$p3=$pages[3]

function New-Card($title,$sub,$y,$parent,$h=112){
    $pnl=New-Object Windows.Forms.Panel
    $pnl.Location=New-Object Drawing.Point(0,$y); $pnl.Size=New-Object Drawing.Size(660,$h)
    $pnl.BackColor=$cCard; $parent.Controls.Add($pnl)
    $lt=New-Lbl $title 10 8 640 20 $cAcc2 (New-Object Drawing.Font('Segoe UI',9,[Drawing.FontStyle]::Bold))
    $ls=New-Lbl $sub 10 28 640 16 $cSub (New-Object Drawing.Font('Segoe UI',8))
    $pnl.Controls.Add($lt); $pnl.Controls.Add($ls); return $pnl
}

# --- Excel ---
$pE=New-Card 'Quitar contrasena - Excel (.xlsx / .xls / .xlsm)' 'Genera una copia sin contrasena en la misma carpeta. Requiere Python.' 0 $p3
$lEp=New-Lbl 'Ningun archivo seleccionado' 10 50 640 15 $cText (New-Object Drawing.Font('Consolas',7)); $pE.Controls.Add($lEp)
$bBE=New-Btn 'Buscar Excel' 10 68 140 30; $bBE.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog;$d.Filter='Excel (*.xlsx;*.xls;*.xlsm)|*.xlsx;*.xls;*.xlsm';if($d.ShowDialog()-eq'OK'){$lEp.Text=$d.FileName}}); $pE.Controls.Add($bBE)
$bRE=New-Btn 'Quitar Contrasena' 158 68 165 30 'green'; $bRE.Add_Click({
    $path=$lEp.Text
    if(-not(Test-Path $path)){Write-Log 'Selecciona un archivo Excel primero.' 'warn';return}
    Run-Async 'Desbloqueando Excel' {
        param($p)
        $check=python -c 'import msoffcrypto' 2>&1
        if($LASTEXITCODE-ne0){python -m pip install msoffcrypto-tool 2>&1|Out-Null}
        $out=$p-replace'(\.[^.]+)$','_sin_pass$1'
        $py="import msoffcrypto`nwith open(r'$p','rb') as f:`n    o=msoffcrypto.OfficeFile(f)`n    o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
        $tmp="$env:TEMP\unlock_excel.py";$py|Set-Content $tmp -Encoding UTF8
        $res=python $tmp 2>&1
        if($res-like'*OK*'){return @{msg="Excel desbloqueado: $out";color='ok'}}
        else{return @{msg="Error: $res";color='err'}}
    } @($path)
}); $pE.Controls.Add($bRE)

# --- Word ---
$pW=New-Card 'Quitar contrasena - Word (.docx / .doc / .docm)' 'Genera una copia sin contrasena en la misma carpeta. Requiere Python.' 120 $p3
$lWp=New-Lbl 'Ningun archivo seleccionado' 10 50 640 15 $cText (New-Object Drawing.Font('Consolas',7)); $pW.Controls.Add($lWp)
$bBW=New-Btn 'Buscar Word' 10 68 140 30; $bBW.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog;$d.Filter='Word (*.docx;*.doc;*.docm)|*.docx;*.doc;*.docm';if($d.ShowDialog()-eq'OK'){$lWp.Text=$d.FileName}}); $pW.Controls.Add($bBW)
$bRW=New-Btn 'Quitar Contrasena' 158 68 165 30 'green'; $bRW.Add_Click({
    $path=$lWp.Text
    if(-not(Test-Path $path)){Write-Log 'Selecciona un archivo Word primero.' 'warn';return}
    Run-Async 'Desbloqueando Word' {
        param($p)
        $check=python -c 'import msoffcrypto' 2>&1
        if($LASTEXITCODE-ne0){python -m pip install msoffcrypto-tool 2>&1|Out-Null}
        $out=$p-replace'(\.[^.]+)$','_sin_pass$1'
        $py="import msoffcrypto`nwith open(r'$p','rb') as f:`n    o=msoffcrypto.OfficeFile(f)`n    o.load_key(password='')`n    with open(r'$out','wb') as fw: o.decrypt(fw)`nprint('OK')"
        $tmp="$env:TEMP\unlock_word.py";$py|Set-Content $tmp -Encoding UTF8
        $res=python $tmp 2>&1
        if($res-like'*OK*'){return @{msg="Word desbloqueado: $out";color='ok'}}
        else{return @{msg="Error: $res";color='err'}}
    } @($path)
}); $pW.Controls.Add($bRW)

# --- PDF ---
$pP=New-Card 'Quitar contrasena - PDF' 'Requiere Python + pikepdf (se instala automaticamente si no esta).' 240 $p3 132
$lPp=New-Lbl 'Ningun archivo seleccionado' 10 50 500 15 $cText (New-Object Drawing.Font('Consolas',7)); $pP.Controls.Add($lPp)
$lPass=New-Lbl 'Contrasena:' 10 70 80 20 $cSub (New-Object Drawing.Font('Segoe UI',8)); $pP.Controls.Add($lPass)
$txtPass=New-Object Windows.Forms.TextBox
$txtPass.Location=New-Object Drawing.Point(93,68);$txtPass.Size=New-Object Drawing.Size(175,22)
$txtPass.UseSystemPasswordChar=$true;$txtPass.BackColor=[Drawing.Color]::FromArgb(9,18,32);$txtPass.ForeColor=$cText
$pP.Controls.Add($txtPass)
$bBP=New-Btn 'Buscar PDF' 10 96 130 28; $bBP.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog;$d.Filter='PDF (*.pdf)|*.pdf';if($d.ShowDialog()-eq'OK'){$lPp.Text=$d.FileName}}); $pP.Controls.Add($bBP)
$bRP=New-Btn 'Quitar Contrasena PDF' 148 96 200 28 'green'; $bRP.Add_Click({
    $path=$lPp.Text; $pw=$txtPass.Text.Trim()
    if(-not(Test-Path $path)){Write-Log 'Selecciona un archivo PDF primero.' 'warn';return}
    Run-Async 'Desbloqueando PDF' {
        param($p,$pw)
        $check=python -c 'import pikepdf' 2>&1
        if($LASTEXITCODE-ne0){python -m pip install pikepdf 2>&1|Out-Null}
        $out=$p-replace'\.pdf$','_sin_pass.pdf'
        $py="import pikepdf`ntry:`n    pdf=pikepdf.open(r'$p',password='$pw')`n    pdf.save(r'$out')`n    print('OK')`nexcept Exception as e:`n    print('ERROR:'+str(e))"
        $tmp="$env:TEMP\unlock_pdf.py";$py|Set-Content $tmp -Encoding UTF8
        $res=python $tmp 2>&1
        if($res-like'*OK*'){return @{msg="PDF desbloqueado: $out";color='ok'}}
        else{return @{msg="Error: $res";color='err'}}
    } @($path,$pw)
}); $pP.Controls.Add($bRP)

# --- Hash ---
$pH=New-Card 'Verificador de Hashes' 'Calcula MD5, SHA1 y SHA256 de cualquier archivo.' 380 $p3 100
$lHp=New-Lbl 'Ningun archivo seleccionado' 10 50 640 15 $cText (New-Object Drawing.Font('Consolas',7)); $pH.Controls.Add($lHp)
$bBH=New-Btn 'Seleccionar archivo' 10 68 165 28; $bBH.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog;if($d.ShowDialog()-eq'OK'){$lHp.Text=$d.FileName}}); $pH.Controls.Add($bBH)
$bCH=New-Btn 'Calcular Hashes' 183 68 155 28 'green'; $bCH.Add_Click({
    $f=$lHp.Text
    if(-not(Test-Path $f)){Write-Log 'Selecciona un archivo primero.' 'warn';return}
    Run-Async 'Calculando hashes' {
        param($file)
        $md5=(Get-FileHash $file -Algorithm MD5).Hash
        $sh1=(Get-FileHash $file -Algorithm SHA1).Hash
        $sh2=(Get-FileHash $file -Algorithm SHA256).Hash
        return @{msg="--- $(Split-Path $file -Leaf) ---`nMD5   : $md5`nSHA1  : $sh1`nSHA256: $sh2";color='info'}
    } @($f)
}); $pH.Controls.Add($bCH)

# --- Activacion ---
$pA=New-Card 'Activacion Windows / Office (MAS)' 'Proyecto open source: irm https://get.activated.win | iex' 488 $p3 80
$bAW=New-Btn 'Activar Windows' 10 52 180 28 'green'; $bAW.Add_Click({
    $c=[Windows.Forms.MessageBox]::Show("Ejecutara: irm https://get.activated.win | iex`nContinuar?","Activar Windows",'YesNo','Warning')
    if($c-eq'Yes'){Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"' -Verb RunAs;Write-Log 'Script MAS lanzado.' 'ok'}
}); $pA.Controls.Add($bAW)
$bAO=New-Btn 'Activar Office' 198 52 180 28 'green'; $bAO.Add_Click({
    $c=[Windows.Forms.MessageBox]::Show("Ejecutara: irm https://get.activated.win | iex`nContinuar?","Activar Office",'YesNo','Warning')
    if($c-eq'Yes'){Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command "irm https://get.activated.win | iex"' -Verb RunAs;Write-Log 'Script MAS lanzado.' 'ok'}
}); $pA.Controls.Add($bAO)

# ============================================================
#  PAGINA 4: SEGURIDAD
# ============================================================
$p4=$pages[4]
New-SecLbl 'Estado de seguridad' 0 4 $p4

$b=New-Btn 'Estado de Defender' 0 26 200 32 'green'; $b.Add_Click({
    Run-Async 'Consultando Defender' {
        try{
            $s=Get-MpComputerStatus
            $lines=@("Antivirus activo     : $($s.AntivirusEnabled)","Proteccion real-time : $($s.RealTimeProtectionEnabled)","Ultima actualizacion : $($s.AntivirusSignatureLastUpdated)","Version definiciones : $($s.AntivirusSignatureVersion)")
            return @{msg="--- Windows Defender ---`n"+($lines-join"`n");color='ok'}
        }catch{return @{msg="Error: $_";color='err'}}
    }
}); $p4.Controls.Add($b)

$b=New-Btn 'Quick Scan Defender' 208 26; $b.Add_Click({
    Write-Log 'Iniciando Quick Scan...' 'sub'
    Start-Process powershell -ArgumentList '-NoProfile -Command "Start-MpScan -ScanType QuickScan"' -Verb RunAs
    Write-Log 'Scan iniciado en segundo plano.' 'ok'
}); $p4.Controls.Add($b)

$b=New-Btn 'Estado del Firewall' 416 26; $b.Add_Click({
    Run-Async 'Consultando firewall' {
        try{
            $profs=Get-NetFirewallProfile
            $lines=$profs|ForEach-Object{"$($_.Name): $(if($_.Enabled){'ACTIVO'}else{'INACTIVO'})"}
            return @{msg="--- Firewall ---`n"+($lines-join"`n");color='info'}
        }catch{$r=netsh advfirewall show allprofiles state 2>&1;return @{msg=($r-join"`n");color='normal'}}
    }
}); $p4.Controls.Add($b)

$b=New-Btn 'Activar Firewall' 0 66 200 32 'green'; $b.Add_Click({
    Run-Async 'Activando Firewall' {$r=netsh advfirewall set allprofiles state on 2>&1;return @{msg="Firewall activado. $r";color='ok'}}
}); $p4.Controls.Add($b)

$b=New-Btn 'Desactivar Firewall' 208 66 200 32 'red'; $b.Add_Click({
    $c=[Windows.Forms.MessageBox]::Show('Seguro que deseas desactivar el Firewall?','Advertencia','YesNo','Warning')
    if($c-eq'Yes'){Run-Async 'Desactivando Firewall' {$r=netsh advfirewall set allprofiles state off 2>&1;return @{msg="Firewall desactivado. $r";color='warn'}}}
}); $p4.Controls.Add($b)

New-SecLbl 'Usuarios y dispositivos' 0 110 $p4

$b=New-Btn 'Listar Usuarios Locales' 0 132; $b.Add_Click({
    Run-Async 'Listando usuarios' {
        $u=Get-LocalUser|ForEach-Object{"$($_.Name) - $(if($_.Enabled){'Activo'}else{'Desactivado'}) - Ultimo acceso: $($_.LastLogon)"}
        return @{msg="--- Usuarios locales ---`n"+($u-join"`n");color='normal'}
    }
}); $p4.Controls.Add($b)

$b=New-Btn 'Dispositivos con Error' 208 132 200 32 'red'; $b.Add_Click({
    Run-Async 'Buscando dispositivos con error' {
        $devs=Get-PnpDevice -Status Error,Unknown -EA SilentlyContinue
        if($devs){
            $lines=$devs|ForEach-Object{"$($_.Class): $($_.FriendlyName) - $($_.Status)"}
            return @{msg="--- Dispositivos con problema ---`n"+($lines-join"`n");color='err'}
        }else{return @{msg='No se encontraron dispositivos con error.';color='ok'}}
    }
}); $p4.Controls.Add($b)

$b=New-Btn 'Administrador Dispositivos' 416 132; $b.Add_Click({Start-Process devmgmt.msc}); $p4.Controls.Add($b)

New-SecLbl 'Certificados y politicas' 0 176 $p4

$b=New-Btn 'Certificados Caducados' 0 198 210 32; $b.Add_Click({
    Run-Async 'Revisando certificados' {
        $hoy=Get-Date
        $certs=Get-ChildItem Cert:\LocalMachine\My|Where-Object{$_.NotAfter-lt$hoy.AddDays(30)}
        if($certs){
            $lines=$certs|ForEach-Object{"$($_.Subject) - Vence: $($_.NotAfter.ToString('dd/MM/yyyy'))"}
            return @{msg="--- Certificados proximos a vencer ---`n"+($lines-join"`n");color='warn'}
        }else{return @{msg='No hay certificados proximos a vencer.';color='ok'}}
    }
}); $p4.Controls.Add($b)

$b=New-Btn 'Politicas de Seguridad' 218 198; $b.Add_Click({Start-Process secpol.msc}); $p4.Controls.Add($b)
$b=New-Btn 'Configurar UAC' 416 198; $b.Add_Click({Start-Process UserAccountControlSettings.exe}); $p4.Controls.Add($b)

# ============================================================
#  PAGINA 5: BACKUP
# ============================================================
$p5=$pages[5]
New-SecLbl 'Carpetas a respaldar' 0 4 $p5

$bkFolders=@(
    @{name='Documentos';path="$env:USERPROFILE\Documents";checked=$true}
    @{name='Escritorio'; path="$env:USERPROFILE\Desktop";  checked=$true}
    @{name='Descargas';  path="$env:USERPROFILE\Downloads";checked=$false}
    @{name='Imagenes';   path="$env:USERPROFILE\Pictures"; checked=$false}
    @{name='Videos';     path="$env:USERPROFILE\Videos";   checked=$false}
    @{name='Musica';     path="$env:USERPROFILE\Music";    checked=$false}
)
$cbFolders=@(); $xF=0; $yF=24
foreach($bf in $bkFolders){
    $cb=New-Object Windows.Forms.CheckBox
    $cb.Text=$bf.name; $cb.Checked=$bf.checked
    $cb.Location=New-Object Drawing.Point($xF,$yF); $cb.Size=New-Object Drawing.Size(148,24)
    $cb.ForeColor=$cText; $cb.BackColor=$cBg; $cb.Tag=$bf.path
    $p5.Controls.Add($cb); $cbFolders+=$cb; $xF+=150
    if($xF-gt580){$xF=0;$yF+=26}
}

$lblDest=New-Lbl "Destino: $env:USERPROFILE\Desktop" 0 58 520 18 $cSub (New-Object Drawing.Font('Consolas',8))
$p5.Controls.Add($lblDest)

$bDest=New-Btn 'Cambiar destino' 530 52 160 28; $bDest.Add_Click({
    $d=New-Object Windows.Forms.FolderBrowserDialog; $d.Description='Carpeta destino para el backup'
    if($d.ShowDialog()-eq'OK'){$lblDest.Text="Destino: $($d.SelectedPath)"}
}); $p5.Controls.Add($bDest)

New-SecLbl 'Operaciones de backup' 0 88 $p5

$bZip=New-Btn 'Crear Backup ZIP' 0 110 190 34 'green'; $bZip.Add_Click({
    $dest=($lblDest.Text-replace'^Destino: ','').Trim()
    $sel=$cbFolders|Where-Object{$_.Checked}
    if($sel.Count-eq0){Write-Log 'Selecciona al menos una carpeta.' 'warn';return}
    $flds=$sel|ForEach-Object{$_.Tag}
    Write-Log "Creando backup ZIP en: $dest" 'sub'
    Start-AsyncJob -Code{
        param($dst,$flds)
        Add-Type -Assembly System.IO.Compression.FileSystem
        $zipPath=Join-Path $dst "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
        $tmp="$env:TEMP\syscodi_backup_tmp"
        Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
        New-Item $tmp -ItemType Directory|Out-Null
        foreach($f in $flds){if(Test-Path $f){Copy-Item $f "$tmp\$(Split-Path $f -Leaf)" -Recurse -Force -EA SilentlyContinue}}
        [System.IO.Compression.ZipFile]::CreateFromDirectory($tmp,$zipPath)
        Remove-Item $tmp -Recurse -Force -EA SilentlyContinue
        return @{msg="Backup creado: $zipPath";color='ok'}
    } -Args @($dest,$flds)
}); $p5.Controls.Add($bZip)

$bDrv=New-Btn 'Exportar Drivers' 198 110 180 34; $bDrv.Add_Click({
    $d=New-Object Windows.Forms.FolderBrowserDialog
    if($d.ShowDialog()-eq'OK'){
        $path=$d.SelectedPath; Write-Log "Exportando drivers a: $path" 'sub'
        Start-Process powershell -ArgumentList "-NoProfile -Command `"pnputil /export-driver * '$path'`"" -Verb RunAs
        Write-Log 'Exportacion de drivers iniciada en ventana separada.' 'ok'
    }
}); $p5.Controls.Add($bDrv)

$bReg=New-Btn 'Exportar Registro HKCU' 386 110 210 34; $bReg.Add_Click({
    $d=New-Object Windows.Forms.SaveFileDialog; $d.Filter='Registry (*.reg)|*.reg'
    $d.FileName="HKCU_Backup_$(Get-Date -Format 'yyyyMMdd').reg"
    if($d.ShowDialog()-eq'OK'){
        Run-Async 'Exportando registro' {
            param($fn) $r=reg export HKCU $fn /y 2>&1; return @{msg="Registro exportado: $fn";color='ok'}
        } @($d.FileName)
    }
}); $p5.Controls.Add($bReg)

$bWB=New-Btn 'Copia de Seguridad Windows' 0 152 230 32; $bWB.Add_Click({Start-Process 'control' -ArgumentList '/name Microsoft.BackupAndRestore'}); $p5.Controls.Add($bWB)

# ============================================================
#  PAGINA 6: SISTEMA
# ============================================================
$p6=$pages[6]

$sysKeys=@('SO','Version','CPU','Nucleos','RAM Total','Disco C')
$sysVals=@{}
$cx=0; $cy=0
foreach($key in $sysKeys){
    $card=New-Object Windows.Forms.Panel
    $card.Location=New-Object Drawing.Point(($cx*222),($cy*74))
    $card.Size=New-Object Drawing.Size(214,66)
    $card.BackColor=$cCard
    $p6.Controls.Add($card)

    $lk=New-Lbl $key 10 8 194 16 $cSub (New-Object Drawing.Font('Segoe UI',8))
    $lv=New-Lbl '---' 10 26 194 28 $cAcc2 (New-Object Drawing.Font('Segoe UI',10,[Drawing.FontStyle]::Bold))
    $card.Controls.Add($lk); $card.Controls.Add($lv)
    $sysVals[$key]=$lv
    $cx++; if($cx-ge3){$cx=0;$cy++}
}

New-SecLbl 'Acciones' 0 156 $p6

$bLoad=New-Btn 'Cargar Info del Sistema' 0 178 210 34 'green'; $bLoad.Add_Click({
    Run-Async 'Cargando info del sistema' {
        $os=Get-CimInstance Win32_OperatingSystem
        $cpu=Get-CimInstance Win32_Processor
        $mem=[math]::Round($os.TotalVisibleMemorySize/1MB,1)
        $free=[math]::Round($os.FreePhysicalMemory/1MB,1)
        $disk=Get-PSDrive C
        $df=[math]::Round($disk.Free/1GB,1)
        $dt=[math]::Round(($disk.Used+$disk.Free)/1GB,1)
        return @(
            @{msg="__SYS__SO__$($os.Caption)";color='sysinfo'}
            @{msg="__SYS__Version__$($os.Version)";color='sysinfo'}
            @{msg="__SYS__CPU__$($cpu.Name)";color='sysinfo'}
            @{msg="__SYS__Nucleos__$($cpu.NumberOfCores) nucleos / $($cpu.NumberOfLogicalProcessors) logicos";color='sysinfo'}
            @{msg="__SYS__RAM Total__$mem GB total / $free GB libres";color='sysinfo'}
            @{msg="__SYS__Disco C__$df GB libres / $dt GB total";color='sysinfo'}
        )
    }
}); $p6.Controls.Add($bLoad)

$bUp=New-Btn 'Ver Uptime' 218 178 160 34; $bUp.Add_Click({
    Run-Async 'Consultando uptime' {
        $boot=(Get-CimInstance Win32_OperatingSystem).LastBootUpTime
        $up=(Get-Date)-$boot
        return @{msg="Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m  (desde $($boot.ToString('dd/MM/yyyy HH:mm')))";color='info'}
    }
}); $p6.Controls.Add($bUp)

$bWU=New-Btn 'Buscar Actualizaciones' 386 178 210 34; $bWU.Add_Click({Start-Process 'ms-settings:windowsupdate'}); $p6.Controls.Add($bWU)

$bExp=New-Btn 'Exportar Reporte TXT' 0 220 200 32; $bExp.Add_Click({
    $d=New-Object Windows.Forms.SaveFileDialog; $d.Filter='Txt (*.txt)|*.txt'
    $d.FileName="Reporte_Sistema_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    if($d.ShowDialog()-eq'OK'){
        $os=Get-CimInstance Win32_OperatingSystem; $cpu=Get-CimInstance Win32_Processor
        @("SysCodi WinTool Pro v3 - Reporte","Generado: $(Get-Date)","==============================","OS    : $($os.Caption) $($os.Version)","CPU   : $($cpu.Name)","RAM   : $([math]::Round($os.TotalVisibleMemorySize/1MB,1)) GB","Equipo: $env:COMPUTERNAME","Usuario: $env:USERNAME")|Set-Content $d.FileName -Encoding UTF8
        Write-Log "Reporte exportado: $($d.FileName)" 'ok'
    }
}); $p6.Controls.Add($bExp)

$bMon=New-Btn 'Iniciar Monitor en Tiempo Real' 208 220 250 32 'green'; $bMon.Add_Click({
    $monTimer.Start(); Write-Log 'Monitor de recursos iniciado (status bar).' 'ok'
}); $p6.Controls.Add($bMon)

# ============================================================
#  JOB TIMER EXTENDIDO - maneja sysinfo para tarjetas
# ============================================================
$jobTimer.Remove_Tick($null)
$jobTimer.Add_Tick({
    $done=$Global:Jobs|Where-Object{$_.Handle.IsCompleted}
    foreach($j in $done){
        try{
            $results=$j.PS.EndInvoke($j.Handle)
            foreach($r in $results){
                if($r-is[hashtable]-and$r.color-eq'sysinfo'){
                    if($r.msg-match'^__SYS__(.+?)__(.+)$'){
                        $key=$Matches[1]; $val=$Matches[2]
                        if($sysVals.ContainsKey($key)){$sysVals[$key].Text=$val}
                    }
                }elseif($r-is[hashtable]-and$r.ContainsKey('msg')){
                    Write-Log $r.msg $r.color
                }elseif($r){Write-Log ($r|Out-String).Trim() 'normal'}
            }
            if($j.PS.Streams.Error.Count-gt0){foreach($e in $j.PS.Streams.Error){Write-Log "Error: $e" 'err'}}
        }catch{Write-Log "Error job: $_" 'err'}
        finally{$j.PS.Dispose()}
    }
    $Global:Jobs.RemoveAll({param($x)$x.Handle.IsCompleted})|Out-Null
})

# ============================================================
#  INICIO
# ============================================================
Set-Page 0
Write-Log 'SysCodi WinTool Pro v3 iniciado.' 'info'
Write-Log "Usuario: $env:USERNAME  |  $(if($isAdmin){'Administrador'}else{'Sin privilegios de admin - algunas funciones no funcionaran'})" $(if($isAdmin){'ok'}else{'warn'})
Write-Log 'Selecciona una opcion del menu lateral.' 'sub'

$form.Add_FormClosing({
    $monTimer.Stop(); $jobTimer.Stop()
    $Global:RSPool.Close(); $Global:RSPool.Dispose()
})

[Windows.Forms.Application]::Run($form)
