#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURACIÓN GLOBAL ---
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

# --- PALETA DE COLORES ---
$cBg = [Drawing.Color]::FromArgb(15, 23, 42); $cPanel = [Drawing.Color]::FromArgb(22, 33, 62)
$cCard = [Drawing.Color]::FromArgb(30, 45, 80); $cBdr = [Drawing.Color]::FromArgb(45, 65, 110)
$cAcc = [Drawing.Color]::FromArgb(56, 189, 248); $cText = [Drawing.Color]::FromArgb(226, 232, 240)
$cMut = [Drawing.Color]::FromArgb(100, 116, 139); $cGreen = [Drawing.Color]::FromArgb(74, 222, 128)
$cYel = [Drawing.Color]::FromArgb(250, 204, 21); $cRed = [Drawing.Color]::FromArgb(248, 113, 113)
$cOut = [Drawing.Color]::FromArgb(10, 16, 30)

# --- FUNCIONES DE UI ---
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
    $b.Text = $txt; $b.Location = New-Object Drawing.Point($x, $y); $b.Size = New-Object Drawing.Size($w, $h)
    $b.FlatStyle = 'Flat'; $b.Cursor = 'Hand'; $b.Font = New-Object Drawing.Font('Segoe UI', 9)
    $b.FlatAppearance.BorderSize = 1
    switch ($col) {
        'green' { $b.BackColor = [Drawing.Color]::FromArgb(5, 46, 22); $b.ForeColor = $cGreen; $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(21, 128, 61) }
        'blue'  { $b.BackColor = [Drawing.Color]::FromArgb(8, 47, 73); $b.ForeColor = $cAcc; $b.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(14, 116, 144) }
        default { $b.BackColor = $cCard; $b.ForeColor = $cText; $b.FlatAppearance.BorderColor = $cBdr }
    }
    return $b
}

# --- CONSTRUCCIÓN DEL FORMULARIO ---
$form = New-Object Windows.Forms.Form
$form.Text = 'SysCodi QuickFix'; $form.Size = New-Object Drawing.Size(780, 560)
$form.FormBorderStyle = 'FixedSingle'; $form.StartPosition = 'CenterScreen'; $form.BackColor = $cBg

# Panel Izquierdo (Contenedor de herramientas)
$left = New-Object Windows.Forms.Panel
$left.Dock = 'Left'; $left.Width = 520; $left.AutoScroll = $true

# Funciones de Layout
function New-SecLbl($txt, $y) {
    $l = New-Object Windows.Forms.Label
    $l.Text = $txt; $l.Location = New-Object Drawing.Point(16, $y); $l.Size = New-Object Drawing.Size(480, 20)
    $l.ForeColor = $cAcc; $l.Font = New-Object Drawing.Font('Segoe UI', 9, [Drawing.FontStyle]::Bold)
    $left.Controls.Add($l)
}

function New-Card($y, $h) {
    $p = New-Object Windows.Forms.Panel
    $p.Location = New-Object Drawing.Point(16, $y); $p.Size = New-Object Drawing.Size(488, $h)
    $p.BackColor = $cCard; $left.Controls.Add($p); return $p
}

$form.Controls.Add($left)

# Consola de Salida
$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location = New-Object Drawing.Point(530, 10); $outputBox.Size = New-Object Drawing.Size(220, 500)
$outputBox.BackColor = $cOut; $outputBox.ForeColor = $cAcc; $outputBox.ReadOnly = $true; $outputBox.BorderStyle = 'None'
$form.Controls.Add($outputBox)

# --- SECCIÓN 1: LIMPIEZA ---
New-SecLbl 'Limpieza de temporales' 10
$c1 = New-Card 35 90
$bT1 = New-Btn 'Limpiar Temporales' 12 40 220 34 'blue'
$bT1.Add_Click({
    Write-Log 'Limpiando...' 'sub'
    Start-Job2 {
        $paths = @("$env:TEMP\*", "C:\Windows\Temp\*")
        $count = 0
        foreach ($p in $paths) { Get-ChildItem $p -Recurse -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue; $count++ }
        return @{msg="Limpieza terminada."; color='ok'}
    }
})
$c1.Controls.Add($bT1)

# --- TIMER Y CIERRE ---
$jt = New-Object Windows.Forms.Timer; $jt.Interval = 500
$jt.Add_Tick({
    $toRemove = New-Object System.Collections.Generic.List[hashtable]
    foreach ($j in $Global:Jobs) {
        if ($j.Handle.IsCompleted) {
            $res = $j.PS.EndInvoke($j.Handle)
            foreach ($r in $res) { if ($r -is [hashtable]) { Write-Log $r.msg $r.color } }
            $j.PS.Dispose(); $toRemove.Add($j)
        }
    }
    foreach ($item in $toRemove) { $Global:Jobs.Remove($item) }
})
$jt.Start()

$form.Add_FormClosing({ $jt.Stop(); $Global:RSPool.Close(); $Global:RSPool.Dispose() })
[Windows.Forms.Application]::Run($form)
