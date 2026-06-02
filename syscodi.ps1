#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
#   ADMIN CHECK
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    $r = [Windows.Forms.MessageBox]::Show("Requiere Administrador. Reiniciar como Admin?","SysCodi","YesNo","Warning")
    if ($r -eq "Yes") { Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs }
    exit
}

# LOGS
$logDir = "C:\SysCodi\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = "$logDir\$(Get-Date -Format 'yyyy-MM-dd').log"
function Write-Log($m) { Add-Content $logFile "[$(Get-Date -Format 'HH:mm:ss')] $m" -Encoding UTF8 -EA SilentlyContinue }

# LOGO
$logoPath = "$env:TEMP\syscodi_logo.png"
try { Invoke-WebRequest "https://raw.githubusercontent.com/syscodi7/Tools/main/sis.png" -OutFile $logoPath -EA Stop } catch { $logoPath = "" }

# COLORES
$cBg      = [Drawing.Color]::FromArgb(11,20,42)
$cPanel   = [Drawing.Color]::FromArgb(18,32,65)
$cCard    = [Drawing.Color]::FromArgb(22,40,82)
$cCardHov = [Drawing.Color]::FromArgb(28,52,105)
$cAccent  = [Drawing.Color]::FromArgb(0,140,255)
$cAccent2 = [Drawing.Color]::FromArgb(80,180,255)
$cGreen   = [Drawing.Color]::FromArgb(40,220,120)
$cYellow  = [Drawing.Color]::FromArgb(255,195,50)
$cRed     = [Drawing.Color]::FromArgb(255,75,75)
$cText    = [Drawing.Color]::White
$cSubText = [Drawing.Color]::FromArgb(150,185,235)
$cBorder  = [Drawing.Color]::FromArgb(30,65,130)
$cOutput  = [Drawing.Color]::FromArgb(8,16,36)

# FORMULARIO
$form = New-Object Windows.Forms.Form
$form.Text = "SysCodi WinTool Pro"
$form.Size = New-Object Drawing.Size(1366,900)
$form.MinimumSize = New-Object Drawing.Size(1200,780)
$form.StartPosition = "CenterScreen"
$form.BackColor = $cBg
$form.ForeColor = $cText
$form.Font = New-Object Drawing.Font("Segoe UI",9)

# HEADER
$header = New-Object Windows.Forms.Panel
$header.Dock = "Top"; $header.Height = 90; $header.BackColor = $cPanel
$form.Controls.Add($header)
$hLine = New-Object Windows.Forms.Panel; $hLine.Dock="Bottom"; $hLine.Height=2; $hLine.BackColor=$cAccent; $header.Controls.Add($hLine)

if (Test-Path $logoPath) {
    $logoPic = New-Object Windows.Forms.PictureBox; $logoPic.Location=New-Object Drawing.Point(18,15); $logoPic.Size=New-Object Drawing.Size(60,60); $logoPic.SizeMode="Zoom"; $logoPic.BackColor=$cPanel; $logoPic.Image=[Drawing.Image]::FromFile($logoPath); $header.Controls.Add($logoPic)
    try { $bmp=[Drawing.Bitmap][Drawing.Image]::FromFile($logoPath); $form.Icon=[Drawing.Icon]::FromHandle($bmp.GetHicon()) } catch {}
    $tx=92
} else { $tx=20 }

$lblBlue = New-Object Windows.Forms.Label; $lblBlue.Text="SysCodi"; $lblBlue.Location=New-Object Drawing.Point($tx,12); $lblBlue.Size=New-Object Drawing.Size(118,38); $lblBlue.Font=New-Object Drawing.Font("Segoe UI",22,[Drawing.FontStyle]::Bold); $lblBlue.ForeColor=$cAccent2; $lblBlue.BackColor=[Drawing.Color]::Transparent; $header.Controls.Add($lblBlue)
$lblWhite = New-Object Windows.Forms.Label; $lblWhite.Text=" WinTool Pro"; $lblWhite.Location=New-Object Drawing.Point(($tx+118),12); $lblWhite.Size=New-Object Drawing.Size(290,38); $lblWhite.Font=New-Object Drawing.Font("Segoe UI",22,[Drawing.FontStyle]::Bold); $lblWhite.ForeColor=$cText; $lblWhite.BackColor=[Drawing.Color]::Transparent; $header.Controls.Add($lblWhite)
$lblSub = New-Object Windows.Forms.Label; $lblSub.Text="Utilidad de sistema avanzada para Windows"; $lblSub.Location=New-Object Drawing.Point($tx,55); $lblSub.Size=New-Object Drawing.Size(420,20); $lblSub.Font=New-Object Drawing.Font("Segoe UI",9); $lblSub.ForeColor=$cSubText; $header.Controls.Add($lblSub)

# Info derecha del header
$pHI = New-Object Windows.Forms.Panel; $pHI.Location=New-Object Drawing.Point(700,8); $pHI.Size=New-Object Drawing.Size(640,75); $pHI.BackColor=[Drawing.Color]::Transparent; $header.Controls.Add($pHI)
function HLbl($t,$x,$y,$w,$font,$color) { $l=New-Object Windows.Forms.Label;$l.Text=$t;$l.Location=New-Object Drawing.Point($x,$y);$l.Size=New-Object Drawing.Size($w,22);$l.Font=$font;$l.ForeColor=$color;$l.BackColor=[Drawing.Color]::Transparent;$pHI.Controls.Add($l);return $l }
$lblOSName  = HLbl "Windows" 0 4 115 (New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold)) $cAccent2
$lblOSVer   = HLbl "" 115 4 320 (New-Object Drawing.Font("Segoe UI",10)) $cText
$lblUser    = HLbl "" 0 28 310 (New-Object Drawing.Font("Segoe UI",8.5)) $cSubText
$lblUptime  = HLbl "" 320 28 310 (New-Object Drawing.Font("Segoe UI",8.5)) $cSubText
$lblEquipo  = HLbl "" 0 50 310 (New-Object Drawing.Font("Segoe UI",8.5)) $cSubText
$lblClock   = HLbl "" 320 50 310 (New-Object Drawing.Font("Segoe UI",8.5)) $cSubText

try { $osI=Get-CimInstance Win32_OperatingSystem; $lblOSVer.Text=" $($osI.Caption.Replace('Microsoft ','')) ($($osI.BuildNumber))"; $lblUser.Text="Usuario:  $env:USERNAME"; $lblEquipo.Text="Equipo:   $env:COMPUTERNAME" } catch {}

$clockT = New-Object Windows.Forms.Timer; $clockT.Interval=1000
$clockT.Add_Tick({
    $lblClock.Text = "Fecha:  $(Get-Date -Format 'dd/MM/yyyy  HH:mm:ss')"
    try { $up=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime; $lblUptime.Text="Tiempo activo:  $($up.Days)d $($up.Hours)h $($up.Minutes)m" } catch {}
})
$clockT.Start()

# TABS BAR
$pnlTabs = New-Object Windows.Forms.Panel; $pnlTabs.Dock="Top"; $pnlTabs.Height=50; $pnlTabs.BackColor=$cPanel; $form.Controls.Add($pnlTabs)
$tabLine = New-Object Windows.Forms.Panel; $tabLine.Dock="Bottom"; $tabLine.Height=1; $tabLine.BackColor=$cBorder; $pnlTabs.Controls.Add($tabLine)

# CONTENT
$pnlContent = New-Object Windows.Forms.Panel; $pnlContent.Dock="Fill"; $pnlContent.BackColor=$cBg; $form.Controls.Add($pnlContent)

# FOOTER
$footer = New-Object Windows.Forms.Panel; $footer.Dock="Bottom"; $footer.Height=175; $footer.BackColor=$cPanel; $form.Controls.Add($footer)
$fLine = New-Object Windows.Forms.Panel; $fLine.Dock="Top"; $fLine.Height=1; $fLine.BackColor=$cBorder; $footer.Controls.Add($fLine)

$statusBar = New-Object Windows.Forms.Panel; $statusBar.Dock="Bottom"; $statusBar.Height=26; $statusBar.BackColor=[Drawing.Color]::FromArgb(8,16,36); $footer.Controls.Add($statusBar)
$lblSL = New-Object Windows.Forms.Label; $lblSL.Text="  Ejecutar siempre como Administrador para mejor rendimiento"; $lblSL.Dock="Left"; $lblSL.Width=700; $lblSL.ForeColor=$cSubText; $lblSL.Font=New-Object Drawing.Font("Segoe UI",8); $lblSL.TextAlign="MiddleLeft"; $statusBar.Controls.Add($lblSL)
$lblSR = New-Object Windows.Forms.Label; $lblSR.Text="Desarrollado por SysCodi     Version 2.5.0 Pro  "; $lblSR.Dock="Right"; $lblSR.Width=400; $lblSR.ForeColor=$cSubText; $lblSR.Font=New-Object Drawing.Font("Segoe UI",8); $lblSR.TextAlign="MiddleRight"; $statusBar.Controls.Add($lblSR)

$footerContent = New-Object Windows.Forms.Panel; $footerContent.Dock="Fill"; $footerContent.BackColor=$cPanel; $footer.Controls.Add($footerContent)

# FOOTER: Metricas
$pnlMet = New-Object Windows.Forms.Panel; $pnlMet.Location=New-Object Drawing.Point(5,8); $pnlMet.Size=New-Object Drawing.Size(300,138); $pnlMet.BackColor=$cCard; $footerContent.Controls.Add($pnlMet)
$lMT = New-Object Windows.Forms.Label; $lMT.Text="Informacion rapida"; $lMT.Location=New-Object Drawing.Point(10,5); $lMT.Size=New-Object Drawing.Size(280,18); $lMT.ForeColor=$cAccent2; $lMT.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $pnlMet.Controls.Add($lMT)

function New-MiniMet($lbl,$x,$y,$par) {
    $p=New-Object Windows.Forms.Panel;$p.Location=New-Object Drawing.Point($x,$y);$p.Size=New-Object Drawing.Size(130,54);$p.BackColor=[Drawing.Color]::FromArgb(15,28,58);$par.Controls.Add($p)
    $ln=New-Object Windows.Forms.Label;$ln.Text=$lbl;$ln.Location=New-Object Drawing.Point(4,4);$ln.Size=New-Object Drawing.Size(90,16);$ln.ForeColor=$cSubText;$ln.Font=New-Object Drawing.Font("Segoe UI",7.5);$p.Controls.Add($ln)
    $lv=New-Object Windows.Forms.Label;$lv.Text="...";$lv.Location=New-Object Drawing.Point(70,2);$lv.Size=New-Object Drawing.Size(55,18);$lv.ForeColor=$cText;$lv.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold);$lv.TextAlign="MiddleRight";$p.Controls.Add($lv)
    $bar=New-Object Windows.Forms.ProgressBar;$bar.Location=New-Object Drawing.Point(4,25);$bar.Size=New-Object Drawing.Size(122,8);$bar.Minimum=0;$bar.Maximum=100;$bar.Style="Continuous";$bar.ForeColor=$cAccent2;$p.Controls.Add($bar)
    $le=New-Object Windows.Forms.Label;$le.Text="";$le.Location=New-Object Drawing.Point(4,36);$le.Size=New-Object Drawing.Size(122,16);$le.ForeColor=$cSubText;$le.Font=New-Object Drawing.Font("Segoe UI",7);$p.Controls.Add($le)
    return @{val=$lv;bar=$bar;extra=$le}
}
$mCPU  = New-MiniMet "CPU Uso"    8   28 $pnlMet
$mRAM  = New-MiniMet "RAM Uso"    152 28 $pnlMet
$mDisk = New-MiniMet "Disco (C:)" 8   86 $pnlMet
$mNet  = New-MiniMet "Red"        152 86 $pnlMet

# FOOTER: Accesos rapidos
$pnlAcc = New-Object Windows.Forms.Panel; $pnlAcc.Location=New-Object Drawing.Point(312,8); $pnlAcc.Size=New-Object Drawing.Size(370,138); $pnlAcc.BackColor=$cCard; $footerContent.Controls.Add($pnlAcc)
$lAT = New-Object Windows.Forms.Label; $lAT.Text="Accesos rapidos"; $lAT.Location=New-Object Drawing.Point(10,5); $lAT.Size=New-Object Drawing.Size(350,18); $lAT.ForeColor=$cAccent2; $lAT.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $pnlAcc.Controls.Add($lAT)
$accList = @(@{n="Explorador";c={Start-Process explorer}},@{n="Adm. dispositivos";c={Start-Process devmgmt.msc}},@{n="Adm. de discos";c={Start-Process diskmgmt.msc}},@{n="Servicios";c={Start-Process services.msc}},@{n="Eventos";c={Start-Process eventvwr.msc}},@{n="Panel de control";c={Start-Process control}})
$ax=8;$ay=28;$ac=0
foreach ($a in $accList) {
    $b=New-Object Windows.Forms.Button;$b.Text=$a.n;$b.Location=New-Object Drawing.Point($ax,$ay);$b.Size=New-Object Drawing.Size(112,48);$b.BackColor=[Drawing.Color]::FromArgb(15,28,58);$b.ForeColor=$cText;$b.FlatStyle="Flat";$b.FlatAppearance.BorderColor=$cBorder;$b.Font=New-Object Drawing.Font("Segoe UI",7.5);$b.Cursor="Hand"
    $ac2=$a.c;$b.Add_Click($ac2);$b.Add_MouseEnter({$this.BackColor=$cCardHov});$b.Add_MouseLeave({$this.BackColor=[Drawing.Color]::FromArgb(15,28,58)});$pnlAcc.Controls.Add($b)
    $ac++;if($ac -ge 3){$ac=0;$ax=8;$ay+=52}else{$ax+=116}
}

# FOOTER: Acciones rapidas
$pnlAct = New-Object Windows.Forms.Panel; $pnlAct.Location=New-Object Drawing.Point(690,8); $pnlAct.Size=New-Object Drawing.Size(380,138); $pnlAct.BackColor=$cCard; $footerContent.Controls.Add($pnlAct)
$lAcT = New-Object Windows.Forms.Label; $lAcT.Text="Acciones rapidas"; $lAcT.Location=New-Object Drawing.Point(10,5); $lAcT.Size=New-Object Drawing.Size(360,18); $lAcT.ForeColor=$cAccent2; $lAcT.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $pnlAct.Controls.Add($lAcT)
$actList = @(@{n="Reiniciar Explorer";c='Stop-Process -Name explorer -Force -EA SilentlyContinue; Start-Sleep 1; Start-Process explorer'},@{n="Liberar memoria";c='[System.GC]::Collect();[System.GC]::WaitForPendingFinalizers(); Write-Output "Memoria liberada"'},@{n="Limpiar Portapapeles";c='Set-Clipboard -Value ""; Write-Output "Portapapeles limpiado"'},@{n="Crear Punto Rest.";c='Checkpoint-Computer -Description "SysCodi_$(Get-Date -Format yyyyMMdd_HHmmss)" -RestorePointType MODIFY_SETTINGS; Write-Output "Punto creado"'})
$aaX=8;$aaY=28;$aaC=0
foreach ($act in $actList) {
    $b=New-Object Windows.Forms.Button;$b.Text=$act.n;$b.Location=New-Object Drawing.Point($aaX,$aaY);$b.Size=New-Object Drawing.Size(180,46);$b.BackColor=[Drawing.Color]::FromArgb(15,28,58);$b.ForeColor=$cText;$b.FlatStyle="Flat";$b.FlatAppearance.BorderColor=$cBorder;$b.Font=New-Object Drawing.Font("Segoe UI",8);$b.Cursor="Hand"
    $ac3=$act.c;$b.Add_Click({Run-Cmd-BG $ac3 $this.Text});$b.Add_MouseEnter({$this.BackColor=$cCardHov});$b.Add_MouseLeave({$this.BackColor=[Drawing.Color]::FromArgb(15,28,58)});$pnlAct.Controls.Add($b)
    $aaC++;if($aaC -ge 2){$aaC=0;$aaX=8;$aaY+=50}else{$aaX+=184}
}

# FOOTER: Estado
$pnlEst = New-Object Windows.Forms.Panel; $pnlEst.Location=New-Object Drawing.Point(1078,8); $pnlEst.Size=New-Object Drawing.Size(165,138); $pnlEst.BackColor=$cCard; $footerContent.Controls.Add($pnlEst)
$lET = New-Object Windows.Forms.Label; $lET.Text="Estado"; $lET.Location=New-Object Drawing.Point(10,5); $lET.Size=New-Object Drawing.Size(145,18); $lET.ForeColor=$cAccent2; $lET.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $pnlEst.Controls.Add($lET)
$lblEstIcon = New-Object Windows.Forms.Label; $lblEstIcon.Text="v"; $lblEstIcon.Location=New-Object Drawing.Point(55,28); $lblEstIcon.Size=New-Object Drawing.Size(55,50); $lblEstIcon.ForeColor=$cGreen; $lblEstIcon.Font=New-Object Drawing.Font("Wingdings",30); $lblEstIcon.TextAlign="MiddleCenter"; $pnlEst.Controls.Add($lblEstIcon)
$lblEstTxt = New-Object Windows.Forms.Label; $lblEstTxt.Text="Todo correcto"; $lblEstTxt.Location=New-Object Drawing.Point(10,80); $lblEstTxt.Size=New-Object Drawing.Size(145,20); $lblEstTxt.ForeColor=$cGreen; $lblEstTxt.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $lblEstTxt.TextAlign="MiddleCenter"; $pnlEst.Controls.Add($lblEstTxt)
$btnVer = New-Object Windows.Forms.Button; $btnVer.Text="Verificar sistema"; $btnVer.Location=New-Object Drawing.Point(10,104); $btnVer.Size=New-Object Drawing.Size(145,26); $btnVer.BackColor=[Drawing.Color]::FromArgb(15,28,58); $btnVer.ForeColor=$cText; $btnVer.FlatStyle="Flat"; $btnVer.FlatAppearance.BorderColor=$cBorder; $btnVer.Font=New-Object Drawing.Font("Segoe UI",8)
$btnVer.Add_Click({ $lblEstTxt.Text="Verificando..."; $lblEstTxt.ForeColor=$cYellow; $lblEstIcon.ForeColor=$cYellow; [Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 800; $lblEstTxt.Text="Todo correcto"; $lblEstTxt.ForeColor=$cGreen; $lblEstIcon.ForeColor=$cGreen; Write-Out "Verificacion OK" $cGreen })
$pnlEst.Controls.Add($btnVer)

# SISTEMA DE TABS PERSONALIZADO
$tabDefs = @(@{n="Reparacion";i="X"},@{n="Aplicaciones";i="A"},@{n="Tweaks";i="T"},@{n="Utilidades";i="U"},@{n="Transferencia";i="R"},@{n="Sistema";i="S"},@{n="Dashboard";i="D"},@{n="Reportes";i="P"},@{n="Ajustes";i="C"})
$tabBtns=@(); $tabPanels=@(); $script:curTab=0; $tbX=5
foreach ($td in $tabDefs) {
    $tb=New-Object Windows.Forms.Button;$tb.Text="$($td.i)  $($td.n)";$tb.Location=New-Object Drawing.Point($tbX,6);$tb.Size=New-Object Drawing.Size(126,38);$tb.BackColor=$cPanel;$tb.ForeColor=$cSubText;$tb.FlatStyle="Flat";$tb.FlatAppearance.BorderSize=0;$tb.FlatAppearance.BorderColor=$cPanel;$tb.Font=New-Object Drawing.Font("Segoe UI",8.5);$tb.Cursor="Hand";$pnlTabs.Controls.Add($tb);$tabBtns+=$tb;$tbX+=130
    $tp=New-Object Windows.Forms.Panel;$tp.Dock="Fill";$tp.BackColor=$cBg;$tp.Visible=$false;$pnlContent.Controls.Add($tp);$tabPanels+=$tp
}
function Switch-Tab($i) {
    for ($j=0;$j -lt $tabBtns.Count;$j++) {
        if ($j -eq $i) { $tabBtns[$j].BackColor=[Drawing.Color]::FromArgb(22,50,100);$tabBtns[$j].ForeColor=$cAccent2;$tabPanels[$j].Visible=$true;$tabPanels[$j].BringToFront() }
        else { $tabBtns[$j].BackColor=$cPanel;$tabBtns[$j].ForeColor=$cSubText;$tabPanels[$j].Visible=$false }
    }
    $script:curTab=$i
}
for ($i=0;$i -lt $tabBtns.Count;$i++) { $idx=$i; $tabBtns[$i].Add_Click({Switch-Tab $idx}) }

# CONSOLA DERECHA
$pnlCon = New-Object Windows.Forms.Panel; $pnlCon.Width=420; $pnlCon.Dock="Right"; $pnlCon.BackColor=$cOutput; $pnlContent.Controls.Add($pnlCon)
$pnlCH = New-Object Windows.Forms.Panel; $pnlCH.Dock="Top"; $pnlCH.Height=34; $pnlCH.BackColor=$cPanel; $pnlCon.Controls.Add($pnlCH)
$lblCT = New-Object Windows.Forms.Label; $lblCT.Text="  Consola de salida"; $lblCT.Dock="Left"; $lblCT.Width=240; $lblCT.ForeColor=$cAccent2; $lblCT.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold); $lblCT.TextAlign="MiddleLeft"; $pnlCH.Controls.Add($lblCT)
$btnCS = New-Object Windows.Forms.Button; $btnCS.Text="Guardar"; $btnCS.Dock="Right"; $btnCS.Width=75; $btnCS.BackColor=[Drawing.Color]::FromArgb(0,60,115); $btnCS.ForeColor=$cText; $btnCS.FlatStyle="Flat"; $btnCS.Font=New-Object Drawing.Font("Segoe UI",7.5); $pnlCH.Controls.Add($btnCS)
$btnCC = New-Object Windows.Forms.Button; $btnCC.Text="Limpiar"; $btnCC.Dock="Right"; $btnCC.Width=75; $btnCC.BackColor=[Drawing.Color]::FromArgb(0,60,115); $btnCC.ForeColor=$cText; $btnCC.FlatStyle="Flat"; $btnCC.Font=New-Object Drawing.Font("Segoe UI",7.5); $pnlCH.Controls.Add($btnCC)
$outputBox = New-Object Windows.Forms.RichTextBox; $outputBox.Dock="Fill"; $outputBox.BackColor=$cOutput; $outputBox.ForeColor=$cAccent2; $outputBox.Font=New-Object Drawing.Font("Consolas",8.5); $outputBox.ReadOnly=$true; $outputBox.BorderStyle="None"; $outputBox.ScrollBars="Vertical"; $pnlCon.Controls.Add($outputBox)
$btnCC.Add_Click({ $outputBox.Clear(); Write-Out "Consola limpiada." $cSubText })
$btnCS.Add_Click({ $d=New-Object Windows.Forms.SaveFileDialog;$d.Filter="Text (*.txt)|*.txt";$d.FileName="SysCodi_log_$(Get-Date -Format yyyyMMdd_HHmmss).txt";if($d.ShowDialog() -eq "OK"){$outputBox.Text|Set-Content $d.FileName -Encoding UTF8;Write-Out "Guardado: $($d.FileName)" $cGreen} })

function Write-Out($msg,$color=$null) {
    if ($null -eq $color){$color=$cAccent2}
    $outputBox.SelectionStart=$outputBox.TextLength; $outputBox.SelectionColor=$color
    $outputBox.AppendText("`r`n $msg"); $outputBox.ScrollToCaret(); Write-Log $msg
}
function Write-Section($t) { Write-Out ""; Write-Out "━━━ $t ━━━" $cAccent2 }

# BARRA PROGRESO
$progBar = New-Object Windows.Forms.ProgressBar; $progBar.Dock="Top"; $progBar.Height=4; $progBar.Style="Marquee"; $progBar.MarqueeAnimationSpeed=0; $pnlContent.Controls.Add($progBar)
function Start-Progress { $progBar.MarqueeAnimationSpeed=25; [Windows.Forms.Application]::DoEvents() }
function Stop-Progress  { $progBar.MarqueeAnimationSpeed=0 }

function Run-Cmd-BG($cmd,$label) {
    Write-Out "Ejecutando: $label..." $cSubText; Start-Progress
    $job=Start-Job -ScriptBlock{param($c) Invoke-Expression $c 2>&1} -ArgumentList $cmd
    $tmr=New-Object Windows.Forms.Timer; $tmr.Interval=600
    $tmr.Add_Tick({
        if ($job.State -ne "Running") {
            $tmr.Stop(); Stop-Progress
            $res=Receive-Job $job; Remove-Job $job -Force
            if ($res){$outputBox.SelectionStart=$outputBox.TextLength;$outputBox.SelectionColor=$cText;$outputBox.AppendText("`r`n "+($res -join "`r`n "));$outputBox.ScrollToCaret()}
            Write-Out "OK: $label" $cGreen
        }
    })
    $tmr.Start()
}

# HELPERS
function New-Btn($txt,$x,$y,$w=190,$h=44,$par) {
    $b=New-Object Windows.Forms.Button;$b.Text=$txt;$b.Location=New-Object Drawing.Point($x,$y);$b.Size=New-Object Drawing.Size($w,$h);$b.BackColor=$cCard;$b.ForeColor=$cText;$b.FlatStyle="Flat";$b.FlatAppearance.BorderColor=$cBorder;$b.FlatAppearance.BorderSize=1;$b.Font=New-Object Drawing.Font("Segoe UI",8.5);$b.Cursor="Hand";$b.TextAlign="MiddleCenter"
    $b.Add_MouseEnter({$this.BackColor=$cCardHov;$this.FlatAppearance.BorderColor=$cAccent});$b.Add_MouseLeave({$this.BackColor=$cCard;$this.FlatAppearance.BorderColor=$cBorder});$par.Controls.Add($b);return $b
}
function New-SecLbl($txt,$x,$y,$par) {
    $l=New-Object Windows.Forms.Label;$l.Text="  $txt";$l.Location=New-Object Drawing.Point($x,$y);$l.Size=New-Object Drawing.Size(860,22);$l.ForeColor=$cAccent2;$l.BackColor=[Drawing.Color]::FromArgb(18,35,72);$l.Font=New-Object Drawing.Font("Segoe UI",8.5,[Drawing.FontStyle]::Bold);$l.TextAlign="MiddleLeft";$par.Controls.Add($l)
}
function New-ScrollP($par) {
    $p=New-Object Windows.Forms.Panel;$p.Dock="Fill";$p.AutoScroll=$true;$p.BackColor=$cBg;$par.Controls.Add($p);return $p
}
# ============================================================
#   TAB 0: REPARACION
# ============================================================
$scrollR = New-ScrollP $tabPanels[0]
$yR=5; $script:colR=0

function Add-RSec($t) { New-SecLbl $t 5 $script:yR $scrollR; $script:yR+=26 }
function Add-RBtn($txt,$cmd) {
    $x=8+($script:colR)*198
    $b=New-Btn $txt $x $script:yR 192 42 $scrollR
    $c2=$cmd;$lb=$txt;$b.Add_Click({Run-Cmd-BG $c2 $lb})
    $script:colR++;if($script:colR -ge 4){$script:colR=0;$script:yR+=46}
}

Add-RSec "Limpieza"
Add-RBtn "Limpiar Temporales"   'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue; "Temporales eliminados"'
Add-RBtn "Limpiar Prefetch"     'Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -EA SilentlyContinue; "Prefetch limpiado"'
Add-RBtn "Vaciar Papelera"      'Clear-RecycleBin -Force -EA SilentlyContinue; "Papelera vaciada"'
Add-RBtn "Limpiar DNS Cache"    'ipconfig /flushdns'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

Add-RSec "Reparacion de Windows"
Add-RBtn "SFC /scannow"         'sfc /scannow'
Add-RBtn "DISM RestoreHealth"   'DISM /Online /Cleanup-Image /RestoreHealth'
Add-RBtn "DISM ScanHealth"      'DISM /Online /Cleanup-Image /ScanHealth'
Add-RBtn "Reset Windows Update" 'Stop-Service wuauserv,bits,cryptsvc -Force -EA SilentlyContinue; Remove-Item "C:\Windows\SoftwareDistribution" -Recurse -Force -EA SilentlyContinue; Start-Service wuauserv,bits,cryptsvc -EA SilentlyContinue; "WU reiniciado"'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}
Add-RBtn "Reparar Tienda (WSReset)" 'wsreset.exe; "Tienda reparada"'
Add-RBtn "Reparar Boot"         'bootrec /fixmbr; bootrec /fixboot; bootrec /rebuildbcd'
Add-RBtn "Limpiar WinSxS"       'DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase'
Add-RBtn "Registrar DLLs"       'for /f %i in (''dir /b C:\Windows\system32\*.dll'') do regsvr32 /s %i'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

Add-RSec "Red y Conectividad"
Add-RBtn "DNS Flush"            'ipconfig /flushdns'
Add-RBtn "Reset TCP/IP"         'netsh int ip reset; "TCP/IP reseteado"'
Add-RBtn "Reset Winsock"        'netsh winsock reset; "Winsock reseteado"'
Add-RBtn "Renovar IP"           'ipconfig /release; ipconfig /renew'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}
Add-RBtn "Ver IP completa"      'ipconfig /all'
Add-RBtn "Ver puertos abiertos" 'netstat -ano'
Add-RBtn "Test DNS 8.8.8.8"     'nslookup google.com 8.8.8.8'
Add-RBtn "Matar proceso pto 80" '$p=(netstat -ano|Select-String ":80 ")-replace ".*\s(\d+)$","$1"|Sort-Object -Unique;$p|Where{$_ -match "^\d+$"}|%{Stop-Process -Id $_ -Force -EA SilentlyContinue;"PID $_ terminado"}'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}
Add-RBtn "Reset Firewall"       'netsh advfirewall reset; "Firewall reseteado"'
Add-RBtn "Velocidad adaptadores" 'Get-NetAdapter | Select Name,LinkSpeed,Status | Format-Table -AutoSize'
Add-RBtn "Ver conexiones activas" 'Get-NetTCPConnection -State Established | Select LocalPort,RemoteAddress,OwningProcess | Format-Table -AutoSize'
Add-RBtn "DNS Cloudflare"       'Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 1.1.1.1,1.0.0.1 -EA SilentlyContinue; "DNS Cloudflare aplicado"'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

Add-RSec "Disco y Almacenamiento"
$btnChk=New-Btn "CheckDisk (C:)" 8 $script:yR 192 42 $scrollR
$btnChk.Add_Click({ $r=[Windows.Forms.MessageBox]::Show("ChkDsk requiere reinicio.`nSe programara para el proximo arranque.","ChkDsk","YesNo","Question"); if($r -eq "Yes"){Run-Cmd-BG 'echo Y | chkdsk C: /f /r' "ChkDsk C:"} })
$script:colR=1
Add-RBtn "Desfragmentar C:"     'defrag C: /U /V'
Add-RBtn "Optimizar SSD (TRIM)" 'defrag C: /L'
Add-RBtn "Info SMART disco"     'wmic diskdrive get status,model,size'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}
Add-RBtn "Limpiar WER"          'Remove-Item "C:\ProgramData\Microsoft\Windows\WER\*" -Recurse -Force -EA SilentlyContinue; "WER limpiado"'
Add-RBtn "Ver archivos grandes" 'Get-ChildItem C:\ -Recurse -EA SilentlyContinue | Sort-Object Length -Descending | Select -First 20 FullName,@{n="MB";e={[math]::Round($_.Length/1MB,2)}} | Format-Table -AutoSize'
Add-RBtn "Info de discos"       'Get-PSDrive -PSProvider FileSystem | Select Name,@{n="Total GB";e={[math]::Round(($_.Used+$_.Free)/1GB,2)}},@{n="Libre GB";e={[math]::Round($_.Free/1GB,2)}} | Format-Table'
Add-RBtn "Eliminar minidumps"   'Remove-Item "C:\Windows\Minidump\*" -Force -EA SilentlyContinue; "Minidumps eliminados"'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

Add-RSec "Rendimiento y Optimizacion"
Add-RBtn "Alto rendimiento"     'powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c; "Plan alto rendimiento activado"'
Add-RBtn "Top procesos CPU"     'Get-Process | Sort-Object CPU -Descending | Select -First 15 Name,CPU,@{n="RAM MB";e={[math]::Round($_.WorkingSet64/1MB,1)}} | Format-Table -AutoSize'
Add-RBtn "Actualizar drivers"   'pnputil /scan-devices; "Escaneo de drivers completado"'
Add-RBtn "Estado memoria RAM"   'Get-CimInstance Win32_PhysicalMemory | Select Manufacturer,Speed,@{n="GB";e={[math]::Round($_.Capacity/1GB,1)}} | Format-Table -AutoSize'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

Add-RSec "Seguridad"
Add-RBtn "Estado Defender"      'Get-MpComputerStatus | Select AMRunningMode,RealTimeProtectionEnabled,AntivirusEnabled | Format-List'
Add-RBtn "Escaneo rapido"       'Start-MpScan -ScanType QuickScan; "Escaneo iniciado"'
Add-RBtn "Actualizar firmas"    'Update-MpSignature; "Firmas actualizadas"'
Add-RBtn "Ver usuarios locales" 'Get-LocalUser | Select Name,Enabled,LastLogon | Format-Table -AutoSize'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}
Add-RBtn "Eventos seguridad"    'Get-EventLog Security -Newest 20 -EA SilentlyContinue | Select TimeGenerated,EntryType,Message | Format-Table -AutoSize'
Add-RBtn "Deshab. autorun USB"  'reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f; "Autorun deshabilitado"'
Add-RBtn "Deshab. Remote Desktop" 'reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f; "RDP deshabilitado"'
Add-RBtn "Listar credenciales"  'cmdkey /list'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

Add-RSec "Arranque y Recuperacion"
Add-RBtn "Crear Punto Rest."    'Checkpoint-Computer -Description "SysCodi_$(Get-Date -Format yyyyMMdd_HHmmss)" -RestorePointType MODIFY_SETTINGS; "Punto creado"'
Add-RBtn "Ver Puntos Rest."     'Get-ComputerRestorePoint | Select Description,CreationTime | Format-Table -AutoSize'
Add-RBtn "Ver entradas BCD"     'bcdedit /enum'
Add-RBtn "Exportar errores CSV" 'Get-EventLog System -EntryType Error -Newest 50 -EA SilentlyContinue | Export-Csv "$env:USERPROFILE\Desktop\errores.csv" -NoTypeInformation; "Exportado al escritorio"'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

Add-RSec "Drivers y Dispositivos"
Add-RBtn "Ver drivers instalados" 'Get-WmiObject Win32_PnPSignedDriver | Select DeviceName,DriverVersion,Manufacturer | Sort DeviceName | Format-Table -AutoSize'
Add-RBtn "Drivers con error"    'Get-WmiObject Win32_PnPEntity | Where-Object{$_.ConfigManagerErrorCode -ne 0} | Select Name,ConfigManagerErrorCode | Format-Table -AutoSize'
Add-RBtn "Exportar lista drivers" 'Get-WmiObject Win32_PnPSignedDriver | Select DeviceName,DriverVersion | Export-Csv "$env:USERPROFILE\Desktop\drivers.csv" -NoTypeInformation; "Exportado al escritorio"'
Add-RBtn "Buscar nuevos hw"     'pnputil /scan-devices; "Escaneo completado"'
if ($script:colR -ne 0){$script:yR+=46;$script:colR=0}

# Boton Mantenimiento Completo
$script:yR+=8
$btnMaint=New-Object Windows.Forms.Button;$btnMaint.Text="  MANTENIMIENTO COMPLETO (Limpieza + SFC + DISM + Red + Disco)";$btnMaint.Location=New-Object Drawing.Point(8,$script:yR);$btnMaint.Size=New-Object Drawing.Size(860,44);$btnMaint.BackColor=[Drawing.Color]::FromArgb(0,75,155);$btnMaint.ForeColor=$cText;$btnMaint.FlatStyle="Flat";$btnMaint.FlatAppearance.BorderColor=$cAccent2;$btnMaint.FlatAppearance.BorderSize=2;$btnMaint.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold);$btnMaint.Cursor="Hand"
$btnMaint.Add_Click({
    Write-Section "MANTENIMIENTO COMPLETO"
    $cmds=@(@("Temporales",'Remove-Item "$env:TEMP\*","C:\Windows\Temp\*" -Recurse -Force -EA SilentlyContinue'),@("Flush DNS",'ipconfig /flushdns'),@("SFC",'sfc /scannow'),@("DISM",'DISM /Online /Cleanup-Image /RestoreHealth'),@("Papelera",'Clear-RecycleBin -Force -EA SilentlyContinue'),@("Optimizar disco",'Optimize-Volume -DriveLetter C -EA SilentlyContinue'))
    Start-Progress
    foreach ($c in $cmds){Write-Out ">>> $($c[0])..." $cSubText;Invoke-Expression $c[1] 2>&1|Out-Null;Write-Out "OK: $($c[0])" $cGreen;[Windows.Forms.Application]::DoEvents()}
    Stop-Progress;Write-Out "MANTENIMIENTO COMPLETO FINALIZADO" $cGreen
})
$scrollR.Controls.Add($btnMaint);$script:yR+=55
$scrollR.AutoScrollMinSize=New-Object Drawing.Size(875,($script:yR+20))

# ============================================================
#   TAB 1: APLICACIONES
# ============================================================
$pTopA=New-Object Windows.Forms.Panel;$pTopA.Dock="Top";$pTopA.Height=48;$pTopA.BackColor=$cPanel;$tabPanels[1].Controls.Add($pTopA)
$lblSrc2=New-Object Windows.Forms.Label;$lblSrc2.Text="Buscar:";$lblSrc2.Location=New-Object Drawing.Point(8,14);$lblSrc2.Size=New-Object Drawing.Size(55,20);$lblSrc2.ForeColor=$cSubText;$pTopA.Controls.Add($lblSrc2)
$txtSearch=New-Object Windows.Forms.TextBox;$txtSearch.Location=New-Object Drawing.Point(66,11);$txtSearch.Size=New-Object Drawing.Size(200,26);$txtSearch.BackColor=[Drawing.Color]::FromArgb(15,28,58);$txtSearch.ForeColor=$cText;$txtSearch.BorderStyle="FixedSingle";$pTopA.Controls.Add($txtSearch)
$btnST=New-Object Windows.Forms.Button;$btnST.Text="Sel. Todo";$btnST.Location=New-Object Drawing.Point(276,9);$btnST.Size=New-Object Drawing.Size(88,28);$btnST.BackColor=[Drawing.Color]::FromArgb(0,70,130);$btnST.ForeColor=$cText;$btnST.FlatStyle="Flat";$btnST.Font=New-Object Drawing.Font("Segoe UI",8);$pTopA.Controls.Add($btnST)
$btnSN=New-Object Windows.Forms.Button;$btnSN.Text="Limpiar";$btnSN.Location=New-Object Drawing.Point(370,9);$btnSN.Size=New-Object Drawing.Size(75,28);$btnSN.BackColor=[Drawing.Color]::FromArgb(80,20,20);$btnSN.ForeColor=$cText;$btnSN.FlatStyle="Flat";$btnSN.Font=New-Object Drawing.Font("Segoe UI",8);$pTopA.Controls.Add($btnSN)
$btnFoss=New-Object Windows.Forms.Button;$btnFoss.Text="Solo FOSS";$btnFoss.Location=New-Object Drawing.Point(452,9);$btnFoss.Size=New-Object Drawing.Size(90,28);$btnFoss.BackColor=[Drawing.Color]::FromArgb(0,55,28);$btnFoss.ForeColor=$cAccent2;$btnFoss.FlatStyle="Flat";$btnFoss.Font=New-Object Drawing.Font("Segoe UI",8);$pTopA.Controls.Add($btnFoss)
$btnInst=New-Object Windows.Forms.Button;$btnInst.Text="  INSTALAR SELECCIONADAS";$btnInst.Location=New-Object Drawing.Point(558,6);$btnInst.Size=New-Object Drawing.Size(220,36);$btnInst.BackColor=[Drawing.Color]::FromArgb(0,110,55);$btnInst.ForeColor=$cText;$btnInst.FlatStyle="Flat";$btnInst.FlatAppearance.BorderColor=$cGreen;$btnInst.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold);$pTopA.Controls.Add($btnInst)

$scrollA=New-Object Windows.Forms.Panel;$scrollA.Dock="Fill";$scrollA.AutoScroll=$true;$scrollA.BackColor=$cBg;$tabPanels[1].Controls.Add($scrollA)

$appList=@(
    @{cat="Navegadores";   name="Google Chrome";      cmd="winget install -e --id Google.Chrome -h";                     foss=$false},
    @{cat="Navegadores";   name="Mozilla Firefox";    cmd="winget install -e --id Mozilla.Firefox -h";                   foss=$true},
    @{cat="Navegadores";   name="Brave Browser";      cmd="winget install -e --id Brave.Brave -h";                       foss=$true},
    @{cat="Navegadores";   name="LibreWolf";           cmd="winget install -e --id LibreWolf.LibreWolf -h";               foss=$true},
    @{cat="Navegadores";   name="Opera GX";            cmd="winget install -e --id Opera.OperaGX -h";                    foss=$false},
    @{cat="Navegadores";   name="Microsoft Edge";      cmd="winget install -e --id Microsoft.Edge -h";                   foss=$false},
    @{cat="Comunicacion";  name="Discord";             cmd="winget install -e --id Discord.Discord -h";                  foss=$false},
    @{cat="Comunicacion";  name="Telegram";            cmd="winget install -e --id Telegram.TelegramDesktop -h";         foss=$true},
    @{cat="Comunicacion";  name="Slack";               cmd="winget install -e --id SlackTechnologies.Slack -h";          foss=$false},
    @{cat="Comunicacion";  name="Signal";              cmd="winget install -e --id OpenWhisperSystems.Signal -h";        foss=$true},
    @{cat="Comunicacion";  name="WhatsApp";            cmd="winget install -e --id 9NKSQGP7F2NH -h";                     foss=$false},
    @{cat="Comunicacion";  name="Zoom";                cmd="winget install -e --id Zoom.Zoom -h";                        foss=$false},
    @{cat="Comunicacion";  name="Microsoft Teams";     cmd="winget install -e --id Microsoft.Teams -h";                  foss=$false},
    @{cat="Desarrollo";    name="VS Code";             cmd="winget install -e --id Microsoft.VisualStudioCode -h";       foss=$true},
    @{cat="Desarrollo";    name="Git";                 cmd="winget install -e --id Git.Git -h";                          foss=$true},
    @{cat="Desarrollo";    name="Python 3";            cmd="winget install -e --id Python.Python.3 -h";                  foss=$true},
    @{cat="Desarrollo";    name="NodeJS LTS";          cmd="winget install -e --id OpenJS.NodeJS.LTS -h";                foss=$true},
    @{cat="Desarrollo";    name="JDK 21";              cmd="winget install -e --id Microsoft.OpenJDK.21 -h";             foss=$true},
    @{cat="Desarrollo";    name="Docker Desktop";      cmd="winget install -e --id Docker.DockerDesktop -h";             foss=$false},
    @{cat="Desarrollo";    name="Postman";             cmd="winget install -e --id Postman.Postman -h";                  foss=$false},
    @{cat="Desarrollo";    name="GitHub Desktop";      cmd="winget install -e --id GitHub.GitHubDesktop -h";             foss=$false},
    @{cat="Desarrollo";    name="PowerShell 7";        cmd="winget install -e --id Microsoft.PowerShell -h";             foss=$true},
    @{cat="Desarrollo";    name="Windows Terminal";    cmd="winget install -e --id Microsoft.WindowsTerminal -h";        foss=$true},
    @{cat="Utilidades";    name="7-Zip";               cmd="winget install -e --id 7zip.7zip -h";                        foss=$true},
    @{cat="Utilidades";    name="WinRAR";              cmd="winget install -e --id RARLab.WinRAR -h";                    foss=$false},
    @{cat="Utilidades";    name="Notepad++";           cmd="winget install -e --id Notepad++.Notepad++ -h";              foss=$true},
    @{cat="Utilidades";    name="Everything";          cmd="winget install -e --id voidtools.Everything -h";             foss=$false},
    @{cat="Utilidades";    name="TreeSize Free";       cmd="winget install -e --id JAMSoftware.TreeSize.Free -h";        foss=$false},
    @{cat="Utilidades";    name="CPU-Z";               cmd="winget install -e --id CPUID.CPU-Z -h";                      foss=$false},
    @{cat="Utilidades";    name="GPU-Z";               cmd="winget install -e --id TechPowerUp.GPU-Z -h";                foss=$false},
    @{cat="Utilidades";    name="HWMonitor";           cmd="winget install -e --id CPUID.HWMonitor -h";                  foss=$false},
    @{cat="Utilidades";    name="CrystalDiskInfo";     cmd="winget install -e --id CrystalDewWorld.CrystalDiskInfo -h";  foss=$false},
    @{cat="Utilidades";    name="WinDirStat";          cmd="winget install -e --id WinDirStat.WinDirStat -h";            foss=$true},
    @{cat="Multimedia";    name="VLC";                 cmd="winget install -e --id VideoLAN.VLC -h";                     foss=$true},
    @{cat="Multimedia";    name="Spotify";             cmd="winget install -e --id Spotify.Spotify -h";                  foss=$false},
    @{cat="Multimedia";    name="OBS Studio";          cmd="winget install -e --id OBSProject.OBSStudio -h";             foss=$true},
    @{cat="Multimedia";    name="HandBrake";           cmd="winget install -e --id HandBrake.HandBrake -h";              foss=$true},
    @{cat="Multimedia";    name="Audacity";            cmd="winget install -e --id Audacity.Audacity -h";                foss=$true},
    @{cat="Multimedia";    name="GIMP";                cmd="winget install -e --id GIMP.GIMP -h";                        foss=$true},
    @{cat="Multimedia";    name="Inkscape";            cmd="winget install -e --id Inkscape.Inkscape -h";                foss=$true},
    @{cat="Multimedia";    name="Krita";               cmd="winget install -e --id KDE.Krita -h";                        foss=$true},
    @{cat="Oficina";       name="LibreOffice";         cmd="winget install -e --id TheDocumentFoundation.LibreOffice -h"; foss=$true},
    @{cat="Oficina";       name="SumatraPDF";          cmd="winget install -e --id SumatraPDF.SumatraPDF -h";            foss=$true},
    @{cat="Oficina";       name="Adobe Reader";        cmd="winget install -e --id Adobe.Acrobat.Reader.64-bit -h";      foss=$false},
    @{cat="Oficina";       name="Obsidian";            cmd="winget install -e --id Obsidian.Obsidian -h";                foss=$false},
    @{cat="Oficina";       name="Notion";              cmd="winget install -e --id Notion.Notion -h";                    foss=$false},
    @{cat="Seguridad";     name="Malwarebytes";        cmd="winget install -e --id Malwarebytes.Malwarebytes -h";        foss=$false},
    @{cat="Seguridad";     name="Bitwarden";           cmd="winget install -e --id Bitwarden.Bitwarden -h";              foss=$true},
    @{cat="Seguridad";     name="KeePassXC";           cmd="winget install -e --id KeePassXCTeam.KeePassXC -h";          foss=$true},
    @{cat="Seguridad";     name="Wireshark";           cmd="winget install -e --id WiresharkFoundation.Wireshark -h";    foss=$true},
    @{cat="Gaming";        name="Steam";               cmd="winget install -e --id Valve.Steam -h";                      foss=$false},
    @{cat="Gaming";        name="Epic Games";          cmd="winget install -e --id EpicGames.EpicGamesLauncher -h";      foss=$false},
    @{cat="Gaming";        name="GOG Galaxy";          cmd="winget install -e --id GOG.Galaxy -h";                       foss=$false},
    @{cat="Gaming";        name="Xbox App";            cmd="winget install -e --id Microsoft.GamingApp -h";              foss=$false},
    @{cat="Gaming";        name="MSI Afterburner";     cmd="winget install -e --id Guru3D.Afterburner -h";               foss=$false},
    @{cat="Virtualizacion";name="VirtualBox";          cmd="winget install -e --id Oracle.VirtualBox -h";                foss=$true},
    @{cat="Virtualizacion";name="VMware Player";       cmd="winget install -e --id VMware.WorkstationPlayer -h";         foss=$false},
    @{cat="Virtualizacion";name="WSL2 Ubuntu";         cmd="wsl --install -d Ubuntu";                                    foss=$true}
)

$checkboxes=[System.Collections.ArrayList]@(); $yA=5; $lastCatA=""; $colA=0
foreach ($app in $appList) {
    if ($app.cat -ne $lastCatA) {
        if ($lastCatA -ne ""){if($colA -ne 0){$yA+=26};$yA+=6}
        $l=New-Object Windows.Forms.Label;$l.Text="  $($app.cat)";$l.Location=New-Object Drawing.Point(5,$yA);$l.Size=New-Object Drawing.Size(860,22);$l.ForeColor=$cAccent2;$l.BackColor=[Drawing.Color]::FromArgb(18,35,72);$l.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold);$scrollA.Controls.Add($l);$yA+=24;$lastCatA=$app.cat;$colA=0
    }
    $cb=New-Object Windows.Forms.CheckBox;$cb.Text=$app.name;$cb.Location=New-Object Drawing.Point((5+$colA*185),$yA);$cb.Size=New-Object Drawing.Size(180,22);$cb.ForeColor=if($app.foss){$cAccent2}else{$cText};$cb.BackColor=$cBg;$cb.Tag=$app;$scrollA.Controls.Add($cb);$checkboxes.Add($cb)|Out-Null
    $colA++;if($colA -ge 5){$colA=0;$yA+=24}
}
$yA+=24;$scrollA.AutoScrollMinSize=New-Object Drawing.Size(870,($yA+20))

$btnST.Add_Click({$checkboxes|ForEach-Object{$_.Checked=$true}})
$btnSN.Add_Click({$checkboxes|ForEach-Object{$_.Checked=$false}})
$btnFoss.Add_Click({$checkboxes|ForEach-Object{$_.Checked=($_.Tag.foss -eq $true)}})
$txtSearch.Add_TextChanged({ $q=$txtSearch.Text.Trim().ToLower(); foreach($cb in $checkboxes){$cb.ForeColor=if($q -and $cb.Text.ToLower().Contains($q)){$cYellow}else{if($cb.Tag.foss){$cAccent2}else{$cText}}} })
$btnInst.Add_Click({
    $sel=$checkboxes|Where-Object{$_.Checked};if($sel.Count -eq 0){Write-Out "No seleccionaste ninguna app." $cYellow;return}
    if(-not(Get-Command winget -EA SilentlyContinue)){Write-Out "Winget no encontrado. Instala App Installer desde la Tienda." $cRed;return}
    Write-Section "INSTALANDO $($sel.Count) APLICACIONES";Start-Progress;$i=0
    foreach($cb in $sel){$i++;Write-Out "[$i/$($sel.Count)] $($cb.Tag.name)..." $cSubText;Start-Process powershell -ArgumentList "-NoProfile -WindowStyle Hidden -Command `"$($cb.Tag.cmd)`"" -Wait -EA SilentlyContinue;Write-Out "  OK: $($cb.Tag.name)" $cGreen;[Windows.Forms.Application]::DoEvents()}
    Stop-Progress;Write-Out "Instalacion completada: $i apps." $cGreen
})

# ============================================================
#   TAB 2: TWEAKS
# ============================================================
$scrollTw=New-ScrollP $tabPanels[2];$yTw=5;$script:colTw=0

$tweakData=@(
    @{cat="Rendimiento";  name="Alto rendimiento (energia)";     cmd='powercfg /s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c';  rev='powercfg /s 381b4222-f694-41f0-9685-ff5bb260df2e';  warn=$false},
    @{cat="Rendimiento";  name="Deshabilitar efectos visuales";  cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 2 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Rendimiento";  name="Modo juego activado";            cmd='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 0 /f'; warn=$false},
    @{cat="Rendimiento";  name="GPU Hardware Scheduling [!]";    cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 1 /f'; warn=$true},
    @{cat="Rendimiento";  name="Desactivar SysMain";             cmd='Stop-Service SysMain -Force; Set-Service SysMain -StartupType Disabled'; rev='Set-Service SysMain -StartupType Automatic; Start-Service SysMain'; warn=$false},
    @{cat="Rendimiento";  name="Desactivar Search Indexing";     cmd='Stop-Service WSearch -Force; Set-Service WSearch -StartupType Disabled'; rev='Set-Service WSearch -StartupType Automatic; Start-Service WSearch'; warn=$false},
    @{cat="Rendimiento";  name="Priorizar apps (no servicios)";  cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 2 /f'; warn=$false},
    @{cat="Rendimiento";  name="FSO (fullscreen optim OFF)";     cmd='reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 2 /f'; rev='reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 0 /f'; warn=$false},
    @{cat="Privacidad";   name="Deshabilitar telemetria";        cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /f'; warn=$false},
    @{cat="Privacidad";   name="Deshabilitar Cortana";           cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v AllowCortana /f'; warn=$false},
    @{cat="Privacidad";   name="Deshabilitar Activity History";  cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v EnableActivityFeed /f'; warn=$false},
    @{cat="Privacidad";   name="Deshabilitar anuncios";          cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Privacidad";   name="Deshabilitar ubicacion";         cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 0 /f'; rev='reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Privacidad";   name="Bloquear diagnosticos MS";       cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /f'; warn=$false},
    @{cat="Interfaz";     name="Mostrar extensiones archivo";    cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz";     name="Mostrar archivos ocultos";       cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 1 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f'; warn=$false},
    @{cat="Interfaz";     name="Menu contextual clasico (W11)";  cmd='reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f'; rev='reg delete "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}" /f'; warn=$false},
    @{cat="Interfaz";     name="Deshabilitar notificaciones";    cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications" /v ToastEnabled /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz";     name="Transparencia OFF";              cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f'; warn=$false},
    @{cat="Interfaz";     name="Barra tareas compacta (W11)";    cmd='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSi /t REG_DWORD /d 0 /f'; rev='reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarSi /t REG_DWORD /d 2 /f'; warn=$false},
    @{cat="Red";          name="DNS Cloudflare (1.1.1.1)";       cmd='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 1.1.1.1,1.0.0.1 -EA SilentlyContinue'; rev='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue'; warn=$false},
    @{cat="Red";          name="DNS Google (8.8.8.8)";            cmd='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ServerAddresses 8.8.8.8,8.8.4.4 -EA SilentlyContinue'; rev='Set-DnsClientServerAddress -InterfaceAlias "Ethernet*","Wi-Fi*" -ResetServerAddresses -EA SilentlyContinue'; warn=$false},
    @{cat="Red";          name="Limitar banda reservada";         cmd='reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f'; rev='reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /f'; warn=$false},
    @{cat="Seguridad";    name="Deshabilitar autorun USB";        cmd='reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /t REG_DWORD /d 255 /f'; rev='reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoDriveTypeAutoRun /f'; warn=$false},
    @{cat="Seguridad";    name="Deshabilitar Remote Desktop";     cmd='reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f'; rev='reg add "HKLM\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 0 /f'; warn=$false},
    @{cat="Seguridad";    name="Habilitar DEP [!]";              cmd='bcdedit /set {current} nx AlwaysOn'; rev='bcdedit /set {current} nx OptIn'; warn=$true}
)

$tweakChecks=[System.Collections.ArrayList]@(); $lastCatTw=""
foreach ($tw in $tweakData) {
    if ($tw.cat -ne $lastCatTw) {
        if ($lastCatTw -ne ""){if($script:colTw -ne 0){$yTw+=26};$yTw+=6}
        New-SecLbl $tw.cat 5 $yTw $scrollTw;$yTw+=26;$lastCatTw=$tw.cat;$script:colTw=0
    }
    $cb=New-Object Windows.Forms.CheckBox;$cb.Text=if($tw.warn){"$($tw.name)  [!]"}else{$tw.name};$cb.Location=New-Object Drawing.Point((5+$script:colTw*430),$yTw);$cb.Size=New-Object Drawing.Size(422,24);$cb.ForeColor=if($tw.warn){$cYellow}else{$cText};$cb.BackColor=$cBg;$cb.Tag=$tw;$scrollTw.Controls.Add($cb);$tweakChecks.Add($cb)|Out-Null
    $script:colTw++;if($script:colTw -ge 2){$script:colTw=0;$yTw+=26}
}
$yTw+=12
$pnlTwB=New-Object Windows.Forms.Panel;$pnlTwB.Location=New-Object Drawing.Point(5,$yTw);$pnlTwB.Size=New-Object Drawing.Size(860,48);$pnlTwB.BackColor=$cPanel;$scrollTw.Controls.Add($pnlTwB)
$bTwA=New-Object Windows.Forms.Button;$bTwA.Text="  Aplicar Seleccionados";$bTwA.Location=New-Object Drawing.Point(5,7);$bTwA.Size=New-Object Drawing.Size(200,34);$bTwA.BackColor=[Drawing.Color]::FromArgb(0,95,55);$bTwA.ForeColor=$cText;$bTwA.FlatStyle="Flat";$bTwA.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
$bTwA.Add_Click({
    $sel=$tweakChecks|Where-Object{$_.Checked};if($sel.Count -eq 0){Write-Out "No seleccionaste ningun tweak." $cYellow;return}
    $bak="$logDir\reg_bak_$(Get-Date -Format yyyyMMdd_HHmmss).reg";reg export HKCU $bak /y|Out-Null;Write-Out "Backup: $bak" $cSubText
    foreach($cb in $sel){Write-Out "Aplicando: $($cb.Tag.name)..." $cSubText;Invoke-Expression $cb.Tag.cmd 2>&1|Out-Null;Write-Out "  OK" $cGreen}
    Write-Out "Tweaks aplicados. Puede requerir reinicio." $cYellow
})
$pnlTwB.Controls.Add($bTwA)
$bTwR=New-Object Windows.Forms.Button;$bTwR.Text="Revertir Seleccionados";$bTwR.Location=New-Object Drawing.Point(215,7);$bTwR.Size=New-Object Drawing.Size(185,34);$bTwR.BackColor=[Drawing.Color]::FromArgb(100,45,0);$bTwR.ForeColor=$cText;$bTwR.FlatStyle="Flat";$bTwR.Font=New-Object Drawing.Font("Segoe UI",9)
$bTwR.Add_Click({$tweakChecks|Where-Object{$_.Checked}|ForEach-Object{if($_.Tag.rev){Invoke-Expression $_.Tag.rev 2>&1|Out-Null};Write-Out "Revertido: $($_.Tag.name)" $cYellow}})
$pnlTwB.Controls.Add($bTwR)
$cmbPerf=New-Object Windows.Forms.ComboBox;$cmbPerf.Location=New-Object Drawing.Point(415,10);$cmbPerf.Size=New-Object Drawing.Size(145,28);$cmbPerf.BackColor=$cPanel;$cmbPerf.ForeColor=$cText;$cmbPerf.FlatStyle="Flat";$cmbPerf.DropDownStyle="DropDownList";$cmbPerf.Items.AddRange(@("Gaming","Oficina","Privacidad Max","PC Antigua"));$pnlTwB.Controls.Add($cmbPerf)
$bPerf=New-Object Windows.Forms.Button;$bPerf.Text="Aplicar Perfil";$bPerf.Location=New-Object Drawing.Point(568,7);$bPerf.Size=New-Object Drawing.Size(140,34);$bPerf.BackColor=[Drawing.Color]::FromArgb(0,75,145);$bPerf.ForeColor=$cText;$bPerf.FlatStyle="Flat";$bPerf.Font=New-Object Drawing.Font("Segoe UI",9)
$bPerf.Add_Click({
    $p=$cmbPerf.SelectedItem;if(-not $p){Write-Out "Selecciona un perfil." $cYellow;return}
    $map=@{"Gaming"=@("Alto rendimiento (energia)","Modo juego activado","GPU Hardware Scheduling [!]","Desactivar SysMain","FSO (fullscreen optim OFF)");"Oficina"=@("Mostrar extensiones archivo","Mostrar archivos ocultos","Deshabilitar notificaciones","Deshabilitar telemetria");"Privacidad Max"=@("Deshabilitar telemetria","Deshabilitar Cortana","Deshabilitar Activity History","Deshabilitar anuncios","Deshabilitar ubicacion","Bloquear diagnosticos MS");"PC Antigua"=@("Deshabilitar efectos visuales","Desactivar SysMain","Desactivar Search Indexing","Transparencia OFF","Alto rendimiento (energia)")}
    $sel=$map[$p];$tweakChecks|ForEach-Object{$_.Checked=($sel -contains $_.Tag.name)};Write-Out "Perfil '$p' cargado. Pulsa Aplicar." $cAccent2
})
$pnlTwB.Controls.Add($bPerf)
$yTw+=60;$scrollTw.AutoScrollMinSize=New-Object Drawing.Size(870,($yTw+20))
# ============================================================
#   TAB 3: UTILIDADES
# ============================================================
$scrollU=New-ScrollP $tabPanels[3]

function New-UCard($tit,$sub,$y,$h=125) {
    $p=New-Object Windows.Forms.Panel;$p.Location=New-Object Drawing.Point(5,$y);$p.Size=New-Object Drawing.Size(860,$h);$p.BackColor=$cCard;$scrollU.Controls.Add($p)
    $lt=New-Object Windows.Forms.Label;$lt.Text="  $tit";$lt.Location=New-Object Drawing.Point(0,0);$lt.Size=New-Object Drawing.Size(860,28);$lt.ForeColor=$cAccent2;$lt.BackColor=[Drawing.Color]::FromArgb(18,35,72);$lt.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold);$lt.TextAlign="MiddleLeft";$p.Controls.Add($lt)
    $ls=New-Object Windows.Forms.Label;$ls.Text="  $sub";$ls.Location=New-Object Drawing.Point(0,28);$ls.Size=New-Object Drawing.Size(860,20);$ls.ForeColor=$cSubText;$ls.Font=New-Object Drawing.Font("Segoe UI",8);$p.Controls.Add($ls)
    return $p
}
function New-FP($pnl,$y,$filter) {
    $lbl=New-Object Windows.Forms.Label;$lbl.Text="Ningun archivo";$lbl.Location=New-Object Drawing.Point(10,$y);$lbl.Size=New-Object Drawing.Size(620,18);$lbl.ForeColor=$cSubText;$lbl.Font=New-Object Drawing.Font("Consolas",7.5);$pnl.Controls.Add($lbl)
    $b=New-Object Windows.Forms.Button;$b.Text="Buscar";$b.Location=New-Object Drawing.Point(640,($y-3));$b.Size=New-Object Drawing.Size(110,24);$b.BackColor=$cCard;$b.ForeColor=$cText;$b.FlatStyle="Flat";$b.Font=New-Object Drawing.Font("Segoe UI",8)
    $f2=$filter;$b.Add_Click({$d=New-Object Windows.Forms.OpenFileDialog;$d.Filter=$f2;if($d.ShowDialog() -eq "OK"){$lbl.Text=$d.FileName}});$pnl.Controls.Add($b);return $lbl
}
function Inst-Dep($pkg) { $c=python -c "import $pkg" 2>&1; if($LASTEXITCODE -ne 0){Write-Out "Instalando $pkg..." $cSubText;python -m pip install $pkg --quiet 2>&1|Out-Null} }

# Excel
$pE=New-UCard "Quitar contrasena - Excel (.xlsx / .xls / .xlsm)" "Genera copia sin contrasena en la misma carpeta. Requiere Python." 5 130
$lblEF=New-FP $pE 52 "Excel (*.xlsx;*.xls;*.xlsm)|*.xlsx;*.xls;*.xlsm"
$bE=New-Btn "  Quitar Contrasena" 10 80 195 36 $pE
$bE.Add_Click({ $path=$lblEF.Text;if(-not(Test-Path $path)){Write-Out "Selecciona Excel." $cYellow;return};Inst-Dep "msoffcrypto";$out=$path -replace '(\.[^.]+)$','_sin_pass$1';$py="import msoffcrypto`nwith open(r'$path','rb') as f:`n    o=msoffcrypto.OfficeFile(f);o.load_key(password='')`n    with open(r'$out','wb') as fw:o.decrypt(fw)`nprint('OK')";$py|Set-Content "$env:TEMP\ux_e.py" -Encoding UTF8;$r=python "$env:TEMP\ux_e.py" 2>&1;if($r -like "*OK*"){Write-Out "Desbloqueado: $out" $cGreen}else{Write-Out "Error: $r" $cRed} })

# Word
$pW=New-UCard "Quitar contrasena - Word (.docx / .doc / .docm)" "Genera copia sin contrasena en la misma carpeta. Requiere Python." 143 130
$lblWF=New-FP $pW 52 "Word (*.docx;*.doc;*.docm)|*.docx;*.doc;*.docm"
$bW=New-Btn "  Quitar Contrasena" 10 80 195 36 $pW
$bW.Add_Click({ $path=$lblWF.Text;if(-not(Test-Path $path)){Write-Out "Selecciona Word." $cYellow;return};Inst-Dep "msoffcrypto";$out=$path -replace '(\.[^.]+)$','_sin_pass$1';$py="import msoffcrypto`nwith open(r'$path','rb') as f:`n    o=msoffcrypto.OfficeFile(f);o.load_key(password='')`n    with open(r'$out','wb') as fw:o.decrypt(fw)`nprint('OK')";$py|Set-Content "$env:TEMP\ux_w.py" -Encoding UTF8;$r=python "$env:TEMP\ux_w.py" 2>&1;if($r -like "*OK*"){Write-Out "Desbloqueado: $out" $cGreen}else{Write-Out "Error: $r" $cRed} })

# ZIP
$pZ=New-UCard "Quitar contrasena - ZIP" "Extrae con contrasena conocida o fuerza bruta con wordlist .txt" 281 175
$lblZF=New-FP $pZ 52 "ZIP (*.zip)|*.zip"
$lblWLF=New-FP $pZ 74 "Wordlist (*.txt)|*.txt";$lblWLF.Text="Sin wordlist (opcional)"
$lblPL=New-Object Windows.Forms.Label;$lblPL.Text="Contrasena:";$lblPL.Location=New-Object Drawing.Point(10,98);$lblPL.Size=New-Object Drawing.Size(90,20);$lblPL.ForeColor=$cSubText;$pZ.Controls.Add($lblPL)
$txtZP=New-Object Windows.Forms.TextBox;$txtZP.Location=New-Object Drawing.Point(105,96);$txtZP.Size=New-Object Drawing.Size(190,24);$txtZP.BackColor=[Drawing.Color]::FromArgb(15,25,50);$txtZP.ForeColor=$cText;$txtZP.UseSystemPasswordChar=$true;$pZ.Controls.Add($txtZP)
$bZ=New-Btn "  Extraer/Desbloquear" 10 130 210 34 $pZ
$bZ.Add_Click({
    $zp=$lblZF.Text;$pass=$txtZP.Text.Trim();$wl=$lblWLF.Text;if(-not(Test-Path $zp)){Write-Out "Selecciona ZIP." $cYellow;return}
    $od=[IO.Path]::Combine([IO.Path]::GetDirectoryName($zp),[IO.Path]::GetFileNameWithoutExtension($zp)+"_extraido")
    $py=@"
import zipfile,os,sys
path=r'$zp';out=r'$od';pwd=r'$pass';wl=r'$wl'
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
            if i%1000==0: print('INFO:'+str(i)+' probadas...')
    print('ERROR:No se encontro contrasena.')
else: print('ERROR:ZIP protegido. Ingresa contrasena o wordlist.')
"@
    $py|Set-Content "$env:TEMP\ux_z.py" -Encoding UTF8;Start-Progress;$r=python "$env:TEMP\ux_z.py" 2>&1;Stop-Progress
    $r|ForEach-Object{if($_ -like "OK:*"){Write-Out $_.Substring(3) $cGreen}elseif($_ -like "ERROR:*"){Write-Out $_.Substring(6) $cRed}else{Write-Out $_ $cSubText}}
})

# Hash
$pH=New-UCard "Calcular Hash de Archivo" "MD5 / SHA1 / SHA256 / SHA512 — verifica integridad (copiado al portapapeles)" 464 115
$lblHF=New-FP $pH 52 "Todos (*.*)|*.*"
$cmbH=New-Object Windows.Forms.ComboBox;$cmbH.Location=New-Object Drawing.Point(10,80);$cmbH.Size=New-Object Drawing.Size(90,26);$cmbH.BackColor=$cPanel;$cmbH.ForeColor=$cText;$cmbH.FlatStyle="Flat";$cmbH.DropDownStyle="DropDownList";$cmbH.Items.AddRange(@("MD5","SHA1","SHA256","SHA512"));$cmbH.SelectedIndex=2;$pH.Controls.Add($cmbH)
$bH=New-Btn "  Calcular Hash" 110 78 165 32 $pH
$bH.Add_Click({ $path=$lblHF.Text;if(-not(Test-Path $path)){Write-Out "Selecciona archivo." $cYellow;return};$h=Get-FileHash $path -Algorithm $cmbH.SelectedItem;Write-Out "[$($cmbH.SelectedItem)] $($h.Hash)" $cGreen;[Windows.Forms.Clipboard]::SetText($h.Hash);Write-Out "(Copiado al portapapeles)" $cSubText })

# Renombrar lote
$pRen=New-UCard "Renombrar Archivos en Lote" "Prefijo, sufijo o reemplazar texto en nombres de archivo de una carpeta" 587 150
$lblRF=New-Object Windows.Forms.Label;$lblRF.Text="Ningun directorio";$lblRF.Location=New-Object Drawing.Point(10,52);$lblRF.Size=New-Object Drawing.Size(620,18);$lblRF.ForeColor=$cSubText;$lblRF.Font=New-Object Drawing.Font("Consolas",7.5);$pRen.Controls.Add($lblRF)
$bRD=New-Object Windows.Forms.Button;$bRD.Text="Carpeta";$bRD.Location=New-Object Drawing.Point(640,49);$bRD.Size=New-Object Drawing.Size(110,24);$bRD.BackColor=$cCard;$bRD.ForeColor=$cText;$bRD.FlatStyle="Flat";$bRD.Font=New-Object Drawing.Font("Segoe UI",8);$bRD.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq "OK"){$lblRF.Text=$d.SelectedPath}});$pRen.Controls.Add($bRD)
function Lbl2($t,$x,$y,$p){$l=New-Object Windows.Forms.Label;$l.Text=$t;$l.Location=New-Object Drawing.Point($x,$y);$l.Size=New-Object Drawing.Size(55,20);$l.ForeColor=$cSubText;$l.Font=New-Object Drawing.Font("Segoe UI",8);$p.Controls.Add($l)}
function TBox($x,$y,$w,$p,$ph=""){$t=New-Object Windows.Forms.TextBox;$t.Location=New-Object Drawing.Point($x,$y);$t.Size=New-Object Drawing.Size($w,24);$t.BackColor=[Drawing.Color]::FromArgb(15,28,58);$t.ForeColor=$cText;if($ph){$t.PlaceholderText=$ph};$p.Controls.Add($t);return $t}
Lbl2 "Prefijo:" 10 80 $pRen;$txtPre=TBox 68 78 90 $pRen
Lbl2 "Sufijo:"  175 80 $pRen;$txtSuf=TBox 228 78 90 $pRen
Lbl2 "De:"      335 80 $pRen;$txtRF=TBox 368 78 90 $pRen "buscar"
Lbl2 "A:"       470 80 $pRen;$txtRT=TBox 492 78 90 $pRen "reemplazar"
$bRen=New-Btn "  Renombrar" 10 112 170 30 $pRen
$bRen.Add_Click({ $f=$lblRF.Text;if(-not(Test-Path $f)){Write-Out "Selecciona carpeta." $cYellow;return};$cnt=0;Get-ChildItem $f -File|ForEach-Object{$n=$_.BaseName;if($txtRF.Text){$n=$n.Replace($txtRF.Text,$txtRT.Text)};$n="$($txtPre.Text)$n$($txtSuf.Text)$($_.Extension)";if($n -ne $_.Name){Rename-Item $_.FullName $n -EA SilentlyContinue;$cnt++}};Write-Out "Renombrados: $cnt archivos" $cGreen })

# Convertir imagenes
$pImg=New-UCard "Convertir / Comprimir Imagenes en Lote" "JPG/PNG/WEBP/BMP — ajusta calidad. Requiere Python + Pillow (pip install Pillow)" 745 140
$lblIF=New-Object Windows.Forms.Label;$lblIF.Text="Ningun directorio";$lblIF.Location=New-Object Drawing.Point(10,52);$lblIF.Size=New-Object Drawing.Size(620,18);$lblIF.ForeColor=$cSubText;$lblIF.Font=New-Object Drawing.Font("Consolas",7.5);$pImg.Controls.Add($lblIF)
$bIF=New-Object Windows.Forms.Button;$bIF.Text="Carpeta";$bIF.Location=New-Object Drawing.Point(640,49);$bIF.Size=New-Object Drawing.Size(110,24);$bIF.BackColor=$cCard;$bIF.ForeColor=$cText;$bIF.FlatStyle="Flat";$bIF.Font=New-Object Drawing.Font("Segoe UI",8);$bIF.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq "OK"){$lblIF.Text=$d.SelectedPath}});$pImg.Controls.Add($bIF)
Lbl2 "Formato:" 10 78 $pImg;$cmbFmt=New-Object Windows.Forms.ComboBox;$cmbFmt.Location=New-Object Drawing.Point(68,76);$cmbFmt.Size=New-Object Drawing.Size(80,26);$cmbFmt.BackColor=$cPanel;$cmbFmt.ForeColor=$cText;$cmbFmt.FlatStyle="Flat";$cmbFmt.DropDownStyle="DropDownList";$cmbFmt.Items.AddRange(@("JPEG","PNG","WEBP","BMP"));$cmbFmt.SelectedIndex=0;$pImg.Controls.Add($cmbFmt)
Lbl2 "Calidad:" 165 78 $pImg;$txtQual=TBox 218 76 55 $pImg;$txtQual.Text="85"
$bCI=New-Btn "  Convertir" 285 75 170 32 $pImg
$bCI.Add_Click({
    $folder=$lblIF.Text;if(-not(Test-Path $folder)){Write-Out "Selecciona carpeta." $cYellow;return};Inst-Dep "PIL";$fmt=$cmbFmt.SelectedItem.ToLower();$qual=[int]($txtQual.Text)
    $py=@"
from PIL import Image
import os,glob
folder=r'$folder';fmt='$fmt';qual=$qual
out_folder=os.path.join(folder,'convertidas_'+fmt)
os.makedirs(out_folder,exist_ok=True)
count=0
for ext in ['*.jpg','*.jpeg','*.png','*.webp','*.bmp']:
    for path in glob.glob(os.path.join(folder,ext)):
        try:
            img=Image.open(path)
            if fmt in ['jpeg','jpg']:img=img.convert('RGB')
            name=os.path.splitext(os.path.basename(path))[0]+'.'+fmt
            img.save(os.path.join(out_folder,name),quality=qual);count+=1
        except Exception as e:print('WARN:'+str(e))
print('OK:'+str(count)+' convertidas en: '+out_folder)
"@
    $py|Set-Content "$env:TEMP\ux_img.py" -Encoding UTF8;Start-Progress;$r=python "$env:TEMP\ux_img.py" 2>&1;Stop-Progress
    $r|ForEach-Object{if($_ -like "OK:*"){Write-Out $_.Substring(3) $cGreen}elseif($_ -like "WARN:*"){Write-Out $_.Substring(5) $cYellow}else{Write-Out $_ $cSubText}}
})

$scrollU.AutoScrollMinSize=New-Object Drawing.Size(870,905)

# ============================================================
#   TAB 4: TRANSFERENCIA
# ============================================================
New-SecLbl "Transferencia de Archivos" 5 5 $tabPanels[4]
$pCopy=New-Object Windows.Forms.Panel;$pCopy.Location=New-Object Drawing.Point(5,35);$pCopy.Size=New-Object Drawing.Size(860,135);$pCopy.BackColor=$cCard;$tabPanels[4].Controls.Add($pCopy)
$ltC=New-Object Windows.Forms.Label;$ltC.Text="  Copiar Carpeta con Robocopy (progreso real)";$ltC.Location=New-Object Drawing.Point(0,0);$ltC.Size=New-Object Drawing.Size(860,28);$ltC.ForeColor=$cAccent2;$ltC.BackColor=[Drawing.Color]::FromArgb(18,35,72);$ltC.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold);$ltC.TextAlign="MiddleLeft";$pCopy.Controls.Add($ltC)
$lblSrcP=New-Object Windows.Forms.Label;$lblSrcP.Text="Origen: (no seleccionado)";$lblSrcP.Location=New-Object Drawing.Point(10,36);$lblSrcP.Size=New-Object Drawing.Size(700,18);$lblSrcP.ForeColor=$cSubText;$pCopy.Controls.Add($lblSrcP)
$bSrc=New-Object Windows.Forms.Button;$bSrc.Text="Seleccionar Origen";$bSrc.Location=New-Object Drawing.Point(720,33);$bSrc.Size=New-Object Drawing.Size(130,24);$bSrc.BackColor=$cCard;$bSrc.ForeColor=$cText;$bSrc.FlatStyle="Flat";$bSrc.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq "OK"){$lblSrcP.Text="Origen: $($d.SelectedPath)"}});$pCopy.Controls.Add($bSrc)
$lblDstP=New-Object Windows.Forms.Label;$lblDstP.Text="Destino: (no seleccionado)";$lblDstP.Location=New-Object Drawing.Point(10,60);$lblDstP.Size=New-Object Drawing.Size(700,18);$lblDstP.ForeColor=$cSubText;$pCopy.Controls.Add($lblDstP)
$bDst=New-Object Windows.Forms.Button;$bDst.Text="Seleccionar Destino";$bDst.Location=New-Object Drawing.Point(720,57);$bDst.Size=New-Object Drawing.Size(130,24);$bDst.BackColor=$cCard;$bDst.ForeColor=$cText;$bDst.FlatStyle="Flat";$bDst.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq "OK"){$lblDstP.Text="Destino: $($d.SelectedPath)"}});$pCopy.Controls.Add($bDst)
$bCopy=New-Btn "  Copiar con Robocopy" 10 90 220 36 $pCopy
$bCopy.Add_Click({ $src=$lblSrcP.Text.Replace("Origen: ","");$dst=$lblDstP.Text.Replace("Destino: ","");if(-not(Test-Path $src)){Write-Out "Selecciona origen." $cYellow;return};Run-Cmd-BG "robocopy `"$src`" `"$dst`" /E /Z /NJH /NJS /ETA" "Copia Robocopy" })

# Mover carpeta
$pMove=New-Object Windows.Forms.Panel;$pMove.Location=New-Object Drawing.Point(5,178);$pMove.Size=New-Object Drawing.Size(860,100);$pMove.BackColor=$cCard;$tabPanels[4].Controls.Add($pMove)
$ltM=New-Object Windows.Forms.Label;$ltM.Text="  Mover Carpeta";$ltM.Location=New-Object Drawing.Point(0,0);$ltM.Size=New-Object Drawing.Size(860,28);$ltM.ForeColor=$cAccent2;$ltM.BackColor=[Drawing.Color]::FromArgb(18,35,72);$ltM.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold);$ltM.TextAlign="MiddleLeft";$pMove.Controls.Add($ltM)
$lblMovSrc=New-Object Windows.Forms.Label;$lblMovSrc.Text="Origen: (no seleccionado)";$lblMovSrc.Location=New-Object Drawing.Point(10,34);$lblMovSrc.Size=New-Object Drawing.Size(500,18);$lblMovSrc.ForeColor=$cSubText;$pMove.Controls.Add($lblMovSrc)
$bMovS=New-Object Windows.Forms.Button;$bMovS.Text="Origen";$bMovS.Location=New-Object Drawing.Point(520,31);$bMovS.Size=New-Object Drawing.Size(100,24);$bMovS.BackColor=$cCard;$bMovS.ForeColor=$cText;$bMovS.FlatStyle="Flat";$bMovS.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq "OK"){$lblMovSrc.Text="Origen: $($d.SelectedPath)"}});$pMove.Controls.Add($bMovS)
$lblMovDst=New-Object Windows.Forms.Label;$lblMovDst.Text="Destino: (no seleccionado)";$lblMovDst.Location=New-Object Drawing.Point(630,34);$lblMovDst.Size=New-Object Drawing.Size(220,18);$lblMovDst.ForeColor=$cSubText;$pMove.Controls.Add($lblMovDst)
$bMovD=New-Object Windows.Forms.Button;$bMovD.Text="Destino";$bMovD.Location=New-Object Drawing.Point(760,31);$bMovD.Size=New-Object Drawing.Size(90,24);$bMovD.BackColor=$cCard;$bMovD.ForeColor=$cText;$bMovD.FlatStyle="Flat";$bMovD.Add_Click({$d=New-Object Windows.Forms.FolderBrowserDialog;if($d.ShowDialog() -eq "OK"){$lblMovDst.Text="Destino: $($d.SelectedPath)"}});$pMove.Controls.Add($bMovD)
$bMov=New-Btn "  Mover Carpeta" 10 64 190 30 $pMove
$bMov.Add_Click({ $src=$lblMovSrc.Text.Replace("Origen: ","");$dst=$lblMovDst.Text.Replace("Destino: ","");if(-not(Test-Path $src)){Write-Out "Selecciona origen." $cYellow;return};Run-Cmd-BG "Move-Item -Path `"$src`" -Destination `"$dst`" -Force; Write-Output 'Movido OK'" "Mover carpeta" })

# ============================================================
#   TAB 5: SISTEMA
# ============================================================
$pnlSys=New-Object Windows.Forms.Panel;$pnlSys.Dock="Fill";$pnlSys.BackColor=$cBg;$tabPanels[5].Controls.Add($pnlSys)

function New-SysCard2($lbl,$x,$y) {
    $p=New-Object Windows.Forms.Panel;$p.Location=New-Object Drawing.Point($x,$y);$p.Size=New-Object Drawing.Size(200,100);$p.BackColor=$cCard;$pnlSys.Controls.Add($p)
    $lt=New-Object Windows.Forms.Label;$lt.Text=$lbl;$lt.Location=New-Object Drawing.Point(10,8);$lt.Size=New-Object Drawing.Size(180,18);$lt.ForeColor=$cSubText;$lt.Font=New-Object Drawing.Font("Segoe UI",8);$p.Controls.Add($lt)
    $lv=New-Object Windows.Forms.Label;$lv.Text="...";$lv.Location=New-Object Drawing.Point(10,26);$lv.Size=New-Object Drawing.Size(180,38);$lv.ForeColor=$cAccent2;$lv.Font=New-Object Drawing.Font("Segoe UI",20,[Drawing.FontStyle]::Bold);$p.Controls.Add($lv)
    $bar=New-Object Windows.Forms.ProgressBar;$bar.Location=New-Object Drawing.Point(10,74);$bar.Size=New-Object Drawing.Size(180,12);$bar.Minimum=0;$bar.Maximum=100;$bar.Style="Continuous";$bar.ForeColor=$cAccent2;$p.Controls.Add($bar)
    return @{lv=$lv;bar=$bar;panel=$p}
}
$cCPU=New-SysCard2 "CPU" 8 8; $cRAM=New-SysCard2 "RAM" 215 8; $cDisk=New-SysCard2 "Disco C:" 422 8; $cNet=New-SysCard2 "Red" 629 8

$infoBox=New-Object Windows.Forms.RichTextBox;$infoBox.Location=New-Object Drawing.Point(5,118);$infoBox.Size=New-Object Drawing.Size(830,280);$infoBox.BackColor=$cOutput;$infoBox.ForeColor=$cAccent2;$infoBox.Font=New-Object Drawing.Font("Consolas",8.5);$infoBox.ReadOnly=$true;$infoBox.BorderStyle="None";$pnlSys.Controls.Add($infoBox)

$pnlSB=New-Object Windows.Forms.Panel;$pnlSB.Location=New-Object Drawing.Point(5,405);$pnlSB.Size=New-Object Drawing.Size(830,52);$pnlSB.BackColor=$cPanel;$pnlSys.Controls.Add($pnlSB)
$bSysInfo=New-Btn "  Cargar Info" 5 9 170 34 $pnlSB
$bSysInfo.Add_Click({
    $infoBox.Clear();$os2=Get-CimInstance Win32_OperatingSystem;$cpu2=Get-CimInstance Win32_Processor;$bios=Get-CimInstance Win32_BIOS
    @("OS:       $($os2.Caption) $($os2.Version)","CPU:      $($cpu2.Name.Trim())","Nucleos:  $($cpu2.NumberOfCores)/$($cpu2.NumberOfLogicalProcessors)","RAM:      $([math]::Round($os2.TotalVisibleMemorySize/1MB,2)) GB total, $([math]::Round($os2.FreePhysicalMemory/1MB,1)) GB libre","BIOS:     $($bios.SMBIOSBIOSVersion) - $($bios.Manufacturer)","Equipo:   $env:COMPUTERNAME","Usuario:  $env:USERNAME","Uptime:   $([math]::Round(((Get-Date)-$os2.LastBootUpTime).TotalHours,1)) horas","","--- DISCOS ---") | ForEach-Object{$infoBox.AppendText("$_`r`n")}
    Get-PSDrive -PSProvider FileSystem|Where-Object{$_.Used -ne $null}|ForEach-Object{$infoBox.AppendText("  $($_.Name): $([math]::Round(($_.Used+$_.Free)/1GB,2))GB total, $([math]::Round($_.Free/1GB,2))GB libre`r`n")}
    $infoBox.AppendText("`r`n--- RED ---`r`n")
    Get-NetAdapter|Where-Object{$_.Status -eq "Up"}|ForEach-Object{$infoBox.AppendText("  $($_.Name): $((Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).IPAddress)  $($_.LinkSpeed)`r`n")}
    Write-Out "Info del sistema cargada." $cGreen
})
$bUptime=New-Btn "  Ver Uptime" 185 9 140 34 $pnlSB;$bUptime.Add_Click({$up=(Get-Date)-(Get-CimInstance Win32_OperatingSystem).LastBootUpTime;Write-Out "Uptime: $($up.Days)d $($up.Hours)h $($up.Minutes)m" $cAccent2})
$bWU=New-Btn "  Windows Update" 335 9 175 34 $pnlSB;$bWU.Add_Click({Start-Process ms-settings:windowsupdate})
$bReport=New-Btn "  Exportar Reporte" 520 9 175 34 $pnlSB
$bReport.Add_Click({
    $path="$env:USERPROFILE\Desktop\SysCodi_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    $os2=Get-CimInstance Win32_OperatingSystem;$cpu2=Get-CimInstance Win32_Processor
    @("SysCodi WinTool Pro - Reporte del Sistema","Generado: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')","","OS:      $($os2.Caption) $($os2.Version)","CPU:     $($cpu2.Name.Trim())","Nucleos: $($cpu2.NumberOfCores)/$($cpu2.NumberOfLogicalProcessors)","RAM:     $([math]::Round($os2.TotalVisibleMemorySize/1MB,2)) GB","Equipo:  $env:COMPUTERNAME","Usuario: $env:USERNAME","Uptime:  $([math]::Round(((Get-Date)-$os2.LastBootUpTime).TotalHours,1)) h","","Discos:")+
    (Get-PSDrive -PSProvider FileSystem|Where-Object{$_.Used -ne $null}|ForEach-Object{"  $($_.Name): $([math]::Round(($_.Used+$_.Free)/1GB,2))GB total, $([math]::Round($_.Free/1GB,2))GB libre"})+
    @("","Red:")+
    (Get-NetAdapter|Where-Object{$_.Status -eq "Up"}|ForEach-Object{"  $($_.Name): $((Get-NetIPAddress -InterfaceIndex $_.InterfaceIndex -AddressFamily IPv4 -EA SilentlyContinue).IPAddress)"}) | Set-Content $path -Encoding UTF8
    Write-Out "Reporte guardado: $path" $cGreen
})

# ============================================================
#   TAB 6: DASHBOARD
# ============================================================
$pDash=$tabPanels[6]
$lDT=New-Object Windows.Forms.Label;$lDT.Text="  Dashboard en tiempo real";$lDT.Location=New-Object Drawing.Point(0,0);$lDT.Size=New-Object Drawing.Size(870,28);$lDT.ForeColor=$cAccent2;$lDT.BackColor=[Drawing.Color]::FromArgb(18,35,72);$lDT.Font=New-Object Drawing.Font("Segoe UI",10,[Drawing.FontStyle]::Bold);$lDT.TextAlign="MiddleLeft";$pDash.Controls.Add($lDT)

function New-DCard($t,$x,$y) {
    $p=New-Object Windows.Forms.Panel;$p.Location=New-Object Drawing.Point($x,$y);$p.Size=New-Object Drawing.Size(205,115);$p.BackColor=$cCard;$pDash.Controls.Add($p)
    $lt=New-Object Windows.Forms.Label;$lt.Text=$t;$lt.Location=New-Object Drawing.Point(10,8);$lt.Size=New-Object Drawing.Size(185,20);$lt.ForeColor=$cSubText;$lt.Font=New-Object Drawing.Font("Segoe UI",9);$p.Controls.Add($lt)
    $lv=New-Object Windows.Forms.Label;$lv.Text="...";$lv.Location=New-Object Drawing.Point(10,28);$lv.Size=New-Object Drawing.Size(185,44);$lv.ForeColor=$cAccent2;$lv.Font=New-Object Drawing.Font("Segoe UI",22,[Drawing.FontStyle]::Bold);$p.Controls.Add($lv)
    $bar=New-Object Windows.Forms.ProgressBar;$bar.Location=New-Object Drawing.Point(10,84);$bar.Size=New-Object Drawing.Size(185,14);$bar.Minimum=0;$bar.Maximum=100;$bar.Style="Continuous";$bar.ForeColor=$cAccent;$p.Controls.Add($bar)
    return @{lv=$lv;bar=$bar;p=$p}
}
$dCPU=New-DCard "CPU" 5 32; $dRAM=New-DCard "RAM" 217 32; $dDisk=New-DCard "Disco C:" 429 32; $dNet=New-DCard "Red" 641 32

$pDashProcs=New-Object Windows.Forms.Panel;$pDashProcs.Location=New-Object Drawing.Point(5,158);$pDashProcs.Size=New-Object Drawing.Size(860,370);$pDashProcs.BackColor=$cCard;$pDash.Controls.Add($pDashProcs)
$ltP2=New-Object Windows.Forms.Label;$ltP2.Text="  Top 15 Procesos (CPU + RAM)";$ltP2.Location=New-Object Drawing.Point(0,0);$ltP2.Size=New-Object Drawing.Size(860,28);$ltP2.ForeColor=$cAccent2;$ltP2.BackColor=[Drawing.Color]::FromArgb(18,35,72);$ltP2.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold);$ltP2.TextAlign="MiddleLeft";$pDashProcs.Controls.Add($ltP2)
$dashBox=New-Object Windows.Forms.RichTextBox;$dashBox.Location=New-Object Drawing.Point(0,28);$dashBox.Size=New-Object Drawing.Size(860,342);$dashBox.BackColor=$cOutput;$dashBox.ForeColor=$cText;$dashBox.Font=New-Object Drawing.Font("Consolas",9);$dashBox.ReadOnly=$true;$dashBox.BorderStyle="None";$pDashProcs.Controls.Add($dashBox)

# ============================================================
#   TAB 7: REPORTES
# ============================================================
$scrollRep=New-ScrollP $tabPanels[7];New-SecLbl "Generar Reportes del Sistema" 5 5 $scrollRep
$reps=@(@{n="Reporte completo sistema";c='$p="$env:USERPROFILE\Desktop\SysCodi_Full_$(Get-Date -Format yyyyMMdd_HHmmss).txt"; Get-CimInstance Win32_OperatingSystem,Win32_Processor,Win32_PhysicalMemory|Out-File $p; "Guardado: $p"'},@{n="Reporte de red";c='$p="$env:USERPROFILE\Desktop\SysCodi_Red_$(Get-Date -Format yyyyMMdd_HHmmss).txt"; ipconfig /all|Out-File $p; netstat -ano>>$p; "Guardado: $p"'},@{n="Eventos de error";c='$p="$env:USERPROFILE\Desktop\SysCodi_Errores_$(Get-Date -Format yyyyMMdd_HHmmss).csv"; Get-EventLog System -EntryType Error -Newest 100 -EA SilentlyContinue|Export-Csv $p -NoTypeInformation; "Guardado: $p"'},@{n="Lista de drivers";c='$p="$env:USERPROFILE\Desktop\SysCodi_Drivers_$(Get-Date -Format yyyyMMdd_HHmmss).csv"; Get-WmiObject Win32_PnPSignedDriver|Select DeviceName,DriverVersion,Manufacturer|Export-Csv $p -NoTypeInformation; "Guardado: $p"'},@{n="Apps instaladas (winget)";c='winget list|Out-File "$env:USERPROFILE\Desktop\SysCodi_Apps_$(Get-Date -Format yyyyMMdd_HHmmss).txt"; "Guardado"'},@{n="Reporte de bateria";c='$p="$env:USERPROFILE\Desktop\SysCodi_Bateria_$(Get-Date -Format yyyyMMdd_HHmmss).html"; powercfg /batteryreport /output $p; Start-Process $p; "Abierto"'},@{n="Diagnostico rendimiento";c='perfmon /report'},@{n="Informe de estabilidad";c='perfmon /rel'})
$ry=32;$rc=0
foreach ($rep in $reps) { $b=New-Btn $rep.n (8+$rc*215) $ry 210 44 $scrollRep;$rc2=$rep.c;$rn=$rep.n;$b.Add_Click({Run-Cmd-BG $rc2 $rn});$rc++;if($rc -ge 4){$rc=0;$ry+=50} }
$scrollRep.AutoScrollMinSize=New-Object Drawing.Size(870,200)

# ============================================================
#   TAB 8: AJUSTES
# ============================================================
New-SecLbl "Configuracion de la Herramienta" 5 5 $tabPanels[8]
$ajInfo=New-Object Windows.Forms.Label;$ajInfo.Text="  Version: 2.5.0 Pro  |  Logs: C:\SysCodi\logs\  |  Requiere: PowerShell 5.1+ / Windows 10+";$ajInfo.Location=New-Object Drawing.Point(5,32);$ajInfo.Size=New-Object Drawing.Size(860,26);$ajInfo.ForeColor=$cSubText;$ajInfo.Font=New-Object Drawing.Font("Segoe UI",9);$tabPanels[8].Controls.Add($ajInfo)
$bOL=New-Btn "  Abrir carpeta logs" 8 68 220 40 $tabPanels[8];$bOL.Add_Click({Start-Process explorer $logDir})
$bCL=New-Btn "  Limpiar logs >30 dias" 238 68 220 40 $tabPanels[8];$bCL.Add_Click({Get-ChildItem $logDir -Filter "*.log"|Where-Object{$_.LastWriteTime -lt (Get-Date).AddDays(-30)}|Remove-Item -Force -EA SilentlyContinue;Write-Out "Logs antiguos eliminados." $cGreen})
$bAb=New-Btn "  Acerca de SysCodi" 468 68 220 40 $tabPanels[8];$bAb.Add_Click({[Windows.Forms.MessageBox]::Show("SysCodi WinTool Pro v2.5.0`nDiseñado con la UI de la imagen de referencia.`nUsa WinGet, Python, Robocopy.`nRequiere PowerShell 5.1+ y Windows 10+","Acerca de","OK","Information")})
$bPy=New-Btn "  Verificar Python" 698 68 220 40 $tabPanels[8];$bPy.Add_Click({$v=python --version 2>&1;Write-Out "Python: $v" $cGreen;$pip=pip --version 2>&1;Write-Out "Pip: $pip" $cSubText})
$bWG=New-Btn "  Verificar WinGet" 8 118 220 40 $tabPanels[8];$bWG.Add_Click({$v=winget --version 2>&1;Write-Out "WinGet: $v" $cGreen})
$bLog=New-Btn "  Ver log de hoy" 238 118 220 40 $tabPanels[8];$bLog.Add_Click({if(Test-Path $logFile){Get-Content $logFile -Tail 50|ForEach-Object{Write-Out $_ $cSubText}}else{Write-Out "No hay log para hoy." $cYellow}})

# ============================================================
#   MONITOR TIEMPO REAL
# ============================================================
$script:lastNetB=0
$monTimer=New-Object Windows.Forms.Timer;$monTimer.Interval=2000
$monTimer.Add_Tick({
    try {
        $cpuL=[int](Get-CimInstance Win32_Processor|Measure-Object -Property LoadPercentage -Average|Select -Exp Average)
        $cpuC=if($cpuL -gt 85){$cRed}elseif($cpuL -gt 60){$cYellow}else{$cGreen}
        $osM=Get-CimInstance Win32_OperatingSystem
        $ramPct=[int](($osM.TotalVisibleMemorySize-$osM.FreePhysicalMemory)/$osM.TotalVisibleMemorySize*100)
        $ramFG=[math]::Round($osM.FreePhysicalMemory/1MB,1)
        $ramC=if($ramPct -gt 85){$cRed}elseif($ramPct -gt 65){$cYellow}else{$cAccent2}
        $drv=Get-PSDrive C;$dPct=[int]($drv.Used/($drv.Used+$drv.Free)*100)
        $dFG=[math]::Round($drv.Free/1GB,1);$dC=if($dPct -gt 90){$cRed}elseif($dPct -gt 75){$cYellow}else{$cAccent2}
        $ns=Get-NetAdapterStatistics -EA SilentlyContinue|Select -First 1
        $netKB=0;if($ns){$tot=$ns.ReceivedBytes+$ns.SentBytes;$netKB=[math]::Round(($tot-$script:lastNetB)/1KB/2,1);$script:lastNetB=$tot}
        # Footer
        $mCPU.val.Text="$cpuL%";$mCPU.bar.Value=[Math]::Min($cpuL,100);$mCPU.bar.ForeColor=$cpuC
        $mRAM.val.Text="$ramPct%";$mRAM.bar.Value=[Math]::Min($ramPct,100);$mRAM.bar.ForeColor=$ramC;$mRAM.extra.Text="Libre: $ramFG GB"
        $mDisk.val.Text="$dPct%";$mDisk.bar.Value=[Math]::Min($dPct,100);$mDisk.bar.ForeColor=$dC;$mDisk.extra.Text="Libre: $dFG GB"
        $mNet.val.Text="$netKB KB/s";$mNet.bar.Value=[Math]::Min([int]($netKB/10),100)
        # Sistema tab
        $cCPU.lv.Text="$cpuL%";$cCPU.bar.Value=[Math]::Min($cpuL,100);$cCPU.lv.ForeColor=$cpuC
        $cRAM.lv.Text="$ramPct%";$cRAM.bar.Value=[Math]::Min($ramPct,100);$cRAM.lv.ForeColor=$ramC
        $cDisk.lv.Text="$dPct%";$cDisk.bar.Value=[Math]::Min($dPct,100);$cDisk.lv.ForeColor=$dC
        $cNet.lv.Text="$netKB KB/s"
        # Dashboard
        $dCPU.lv.Text="$cpuL%";$dCPU.bar.Value=[Math]::Min($cpuL,100);$dCPU.lv.ForeColor=$cpuC;$dCPU.bar.ForeColor=$cpuC
        $dRAM.lv.Text="$ramPct%";$dRAM.bar.Value=[Math]::Min($ramPct,100);$dRAM.lv.ForeColor=$ramC
        $dDisk.lv.Text="$dPct%";$dDisk.bar.Value=[Math]::Min($dPct,100);$dDisk.lv.ForeColor=$dC
        $dNet.lv.Text="$netKB"
        # Procesos en dashboard (solo si es la tab activa)
        if ($script:curTab -eq 6) {
            $procs=Get-Process|Sort-Object CPU -Descending|Select -First 15
            $dashBox.Clear();$dashBox.SelectionColor=$cSubText
            $dashBox.AppendText(("{0,-38} {1,10} {2,12}`r`n" -f "Proceso","CPU (seg)","RAM (MB)"))
            $dashBox.AppendText(("─"*65+"`r`n"))
            foreach($pr in $procs){$dashBox.SelectionColor=$cText;$dashBox.AppendText(("{0,-38} {1,10:N1} {2,12:N1}`r`n" -f $pr.Name.Substring(0,[Math]::Min($pr.Name.Length,37)),$pr.CPU,($pr.WorkingSet64/1MB)))}
        }
    } catch {}
})
$monTimer.Start()

# ============================================================
#   ARRANQUE
# ============================================================
Switch-Tab 0
Write-Out "SysCodi WinTool Pro v2.5.0 iniciado correctamente." $cGreen
Write-Out "Logs: $logFile" $cSubText
Write-Out "Equipo: $env:COMPUTERNAME  |  Usuario: $env:USERNAME" $cSubText
Write-Out "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" $cSubText
Write-Log "Iniciado"

$form.Add_FormClosing({$monTimer.Stop();$clockT.Stop();Write-Log "Cerrado"})
[Windows.Forms.Application]::EnableVisualStyles()
$form.ShowDialog()
