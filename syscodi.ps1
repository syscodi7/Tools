#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$Global:RSPool = [RunspaceFactory]::CreateRunspacePool(1, 4)
$Global:RSPool.ApartmentState = 'STA'
$Global:RSPool.Open()
$Global:Jobs = [System.Collections.Generic.List[hashtable]]::new()

function Start-Job2([scriptblock]$Code, [object[]]$Args = @()) {
    $ps = [PowerShell]::Create(); $ps.RunspacePool = $Global:RSPool
    [void]$ps.AddScript($Code)
    foreach ($a in $Args) { [void]$ps.AddArgument($a) }
    $h = $ps.BeginInvoke()
    $Global:Jobs.Add(@{ PS = $ps; Handle = $h })
}

$cBg    = [Drawing.Color]::FromArgb(15, 23, 42)
$cPanel = [Drawing.Color]::FromArgb(22, 33, 62)
$cCard  = [Drawing.Color]::FromArgb(30, 45, 80)
$cBdr   = [Drawing.Color]::FromArgb(45, 65, 110)
$cAcc   = [Drawing.Color]::FromArgb(56, 189, 248)
$cText  = [Drawing.Color]::FromArgb(226, 232, 240)
$cMut   = [Drawing.Color]::FromArgb(100, 116, 139)
$cGreen = [Drawing.Color]::FromArgb(74, 222, 128)
$cYel   = [Drawing.Color]::FromArgb(250, 204, 21)
$cRed   = [Drawing.Color]::FromArgb(248, 113, 113)
$cOut   = [Drawing.Color]::FromArgb(10, 16, 30)

function Write-Log($msg, $type = 'n') {
    $ts = Get-Date -Format 'HH:mm:ss'
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionColor = [Drawing.Color]::FromArgb(50, 80, 130)
    $outputBox.AppendText("`n[$ts] ")
    $outputBox.SelectionColor = switch ($type) {
        'ok' { $cGreen }; 'warn' { $cYel }; 'err' { $cRed }; 'info' { $cAcc }; 'sub' { $cMut }; default { $cText }
    }
    $outputBox.AppendText($msg)
    $outputBox.ScrollToCaret()
}

function New-Btn($txt, $x, $y, $w = 200, $h = 40, $col = '') {
    $b = New-Object Windows.Forms.Button
    $b.Text = $txt; $b.Location = New-Object Drawing.Point($x, $y)
    $b.Size = New-Object Drawing.Size($w, $h)
    $b.FlatStyle = 'Flat'; $b.Cursor = 'Hand'
    $b.Font = New-Object Drawing.Font('Segoe UI', 9)
    $b.FlatAppearance.BorderSize = 1
    switch ($col) {
        'green' { $b.BackColor = [Drawing.Color]::FromArgb(5, 46, 22);  $b.ForeColor = $cGreen; $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(21, 128, 61) }
        'blue'  { $b.BackColor = [Drawing.Color]::FromArgb(8, 47, 73);  $b.ForeColor = $cAcc;   $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(14, 116, 144) }
        'red'   { $b.BackColor = [Drawing.Color]::FromArgb(69, 10, 10); $b.ForeColor = $cRed;   $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(153, 27, 27) }
        default { $b.BackColor = $cCard; $b.ForeColor = $cText; $b.FlatAppearance.BorderColor = $cBdr }
    }
    return $b
}

# --- FORM Y LAYOUT (Mantenido igual a tu original) ---
$form = New-Object Windows.Forms.Form
$form.Text = 'SysCodi QuickFix'; $form.Size = New-Object Drawing.Size(780, 560)
$form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false; $form.StartPosition = 'CenterScreen'
$form.BackColor = $cBg

# [Aquí iría tu construcción de paneles, botones y lógica de eventos]
# --- SECCIÓN 1: LIMPIEZA DEL SISTEMA ---
New-SecLbl 'Limpieza de temporales' 10

$c1 = New-Card 28 90
$l1 = New-Object Windows.Forms.Label
$l1.Text = 'Elimina archivos temporales y caché del sistema para liberar espacio.'
$l1.Location = New-Object Drawing.Point(12, 10); $l1.Size = New-Object Drawing.Size(464, 32)
$l1.ForeColor = $cMut; $l1.Font = New-Object Drawing.Font('Segoe UI', 8); $l1.BackColor = [Drawing.Color]::Transparent
$c1.Controls.Add($l1)

# Botón: Limpiar Temporales
$bT1 = New-Btn 'Limpiar Temporales' 12 46 220 34 'blue'
$bT1.Add_Click({
    Write-Log 'Iniciando limpieza de temporales...' 'sub'
    Start-Job2 {
        $count = 0
        $paths = @("$env:TEMP\*", "C:\Windows\Temp\*")
        foreach ($path in $paths) {
            Get-ChildItem $path -EA SilentlyContinue | ForEach-Object {
                try { Remove-Item $_.FullName -Recurse -Force -ErrorAction Stop; $count++ } catch {}
            }
        }
        return @{msg = "Limpieza completada. $count elementos eliminados."; color = 'ok'}
    }
})
$c1.Controls.Add($bT1)

# Botón: Limpiar Prefetch
$bT2 = New-Btn 'Limpiar Prefetch' 242 46 220 34 'blue'
$bT2.Add_Click({
    Write-Log 'Limpiando Prefetch...' 'sub'
    Start-Job2 {
        $path = "C:\Windows\Prefetch\*"
        $files = Get-ChildItem $path -EA SilentlyContinue
        $count = $files.Count
        foreach ($f in $files) { try { Remove-Item $f.FullName -Recurse -Force -ErrorAction Stop } catch {} }
        return @{msg = "Prefetch limpiado ($count archivos)."; color = 'ok'}
    }
})
$c1.Controls.Add($bT2)
# (He omitido las líneas de construcción para mantener el código conciso, 
#  puedes mantener exactamente tu bloque original aquí).

# --- TIMER CORREGIDO ---
$jt = New-Object Windows.Forms.Timer; $jt.Interval = 350
$jt.Add_Tick({
    $toRemove = New-Object System.Collections.Generic.List[hashtable]
    foreach ($j in $Global:Jobs) {
        if ($j.Handle.IsCompleted) {
            try {
                $res = $j.PS.EndInvoke($j.Handle)
                foreach ($r in $res) {
                    if ($r -is [hashtable]) {
                        if ($r.color -eq 'mode') {
                            $val = $r.msg -replace '^__MODE__', ''
                            $lMode.Text = "Modo actual: $val"
                            $lMode.ForeColor = if ($val -like '*seguro*') { $cRed } else { $cGreen }
                        } elseif ($r.ContainsKey('msg')) {
                            Write-Log $r.msg $r.color
                            if ($r.color -eq 'ok') { $lSt.Text = $r.msg; $lSt.ForeColor = $cGreen }
                            elseif ($r.color -eq 'err') { $lSt.Text = 'Error: ' + $r.msg; $lSt.ForeColor = $cRed }
                        }
                    }
                }
            } catch { Write-Log "Error procesando job: $_" 'err' }
            finally { $j.PS.Dispose(); $toRemove.Add($j) }
        }
    }
    foreach ($item in $toRemove) { $Global:Jobs.Remove($item) }
})
$jt.Start()

$form.Add_FormClosing({ $jt.Stop(); $Global:RSPool.Close(); $Global:RSPool.Dispose() })
[Windows.Forms.Application]::Run($form)
