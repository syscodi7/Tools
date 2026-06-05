#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURACIÓN GLOBAL ---
$Global:RSPool = [RunspaceFactory]::CreateRunspacePool(1, 4)
$Global:RSPool.ApartmentState = 'STA'
$Global:RSPool.Open()
$Global:Jobs = [System.Collections.Generic.List[hashtable]]::new()

# --- FUNCIONES BASE ---
function Start-Job2([scriptblock]$Code, [object[]]$Args = @()) {
    $ps = [PowerShell]::Create(); $ps.RunspacePool = $Global:RSPool
    [void]$ps.AddScript($Code)
    foreach ($a in $Args) { [void]$ps.AddArgument($a) }
    $h = $ps.BeginInvoke()
    $Global:Jobs.Add(@{ PS = $ps; Handle = $h })
}

function Write-Log($msg, $type = 'n') {
    $ts = Get-Date -Format 'HH:mm:ss'
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.AppendText("`n[$ts] $msg")
    $outputBox.ScrollToCaret()
}

# --- DISEÑO ---
$cBg = [Drawing.Color]::FromArgb(15, 23, 42); $cCard = [Drawing.Color]::FromArgb(30, 45, 80)
$cAcc = [Drawing.Color]::FromArgb(56, 189, 248); $cText = [Drawing.Color]::FromArgb(226, 232, 240)
$cOut = [Drawing.Color]::FromArgb(10, 16, 30)

$form = New-Object Windows.Forms.Form
$form.Text = 'SysCodi QuickFix Pro'; $form.Size = New-Object Drawing.Size(800, 600)
$form.BackColor = $cBg

# --- SISTEMA DE PESTAÑAS ---
$tabControl = New-Object Windows.Forms.TabControl
$tabControl.Location = New-Object Drawing.Point(0, 60); $tabControl.Size = New-Object Drawing.Size(550, 450)
$tabControl.Appearance = 'FlatButtons'; $tabControl.ItemSize = New-Object Drawing.Size(0, 1); $tabControl.SizeMode = 'Fixed'

$tabLimpieza = New-Object Windows.Forms.TabPage; $tabLimpieza.BackColor = $cBg
$tabRed = New-Object Windows.Forms.TabPage; $tabRed.BackColor = $cBg
$tabControl.Controls.AddRange(@($tabLimpieza, $tabRed))
$form.Controls.Add($tabControl)

# --- BOTONES DE NAVEGACIÓN ---
function New-NavBtn($txt, $x, $tab) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $txt; $b.Location = New-Object Drawing.Point($x, 15); $b.Size = New-Object Drawing.Size(120, 35)
    $b.BackColor = $cCard; $b.ForeColor = $cText; $b.FlatStyle = 'Flat'
    $b.Add_Click({ $tabControl.SelectedTab = $tab })
    return $b
}
$form.Controls.Add((New-NavBtn 'Limpieza' 20 $tabLimpieza))
$form.Controls.Add((New-NavBtn 'Red' 150 $tabRed))

# --- HERRAMIENTAS: LIMPIEZA ---
$btnTemp = New-Object Windows.Forms.Button; $btnTemp.Text = "Borrar Temporales"; $btnTemp.Location = New-Object Drawing.Point(20, 20); $btnTemp.Size = New-Object Drawing.Size(150, 40)
$btnTemp.Add_Click({
    Write-Log "Limpiando temporales..."
    Start-Job2 {
        Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue
        return @{msg="Temporales eliminados"; color='ok'}
    }
})
$tabLimpieza.Controls.Add($btnTemp)

# --- HERRAMIENTAS: RED ---
$btnDns = New-Object Windows.Forms.Button; $btnDns.Text = "Flush DNS"; $btnDns.Location = New-Object Drawing.Point(20, 20); $btnDns.Size = New-Object Drawing.Size(150, 40)
$btnDns.Add_Click({
    Write-Log "Limpiando caché DNS..."
    Start-Job2 {
        ipconfig /flushdns | Out-Null
        return @{msg="Caché DNS limpia"; color='ok'}
    }
})
$tabRed.Controls.Add($btnDns)

# --- CONSOLA ---
$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location = New-Object Drawing.Point(560, 20); $outputBox.Size = New-Object Drawing.Size(210, 520)
$outputBox.BackColor = $cOut; $outputBox.ForeColor = $cAcc; $form.Controls.Add($outputBox)

$form.Add_FormClosing({ $Global:RSPool.Close(); $Global:RSPool.Dispose() })
[Windows.Forms.Application]::Run($form)
