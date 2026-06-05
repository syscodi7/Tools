#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- CONFIGURACIÓN GLOBAL ---
$Global:RSPool = [RunspaceFactory]::CreateRunspacePool(1, 4)
$Global:RSPool.ApartmentState = 'STA'
$Global:RSPool.Open()
$Global:Jobs = [System.Collections.Generic.List[hashtable]]::new()

# --- COLORES ---
$cBg = [Drawing.Color]::FromArgb(15, 23, 42); $cCard = [Drawing.Color]::FromArgb(30, 45, 80)
$cAcc = [Drawing.Color]::FromArgb(56, 189, 248); $cText = [Drawing.Color]::FromArgb(226, 232, 240)
$cMut = [Drawing.Color]::FromArgb(100, 116, 139); $cOut = [Drawing.Color]::FromArgb(10, 16, 30)

# --- FORMULARIO ---
$form = New-Object Windows.Forms.Form
$form.Text = 'SysCodi QuickFix Pro'; $form.Size = New-Object Drawing.Size(800, 600)
$form.StartPosition = 'CenterScreen'; $form.BackColor = $cBg

# --- SISTEMA DE PESTAÑAS ---
$tabControl = New-Object Windows.Forms.TabControl
$tabControl.Location = New-Object Drawing.Point(0, 60); $tabControl.Size = New-Object Drawing.Size(550, 500)
$tabControl.Appearance = 'FlatButtons'; $tabControl.ItemSize = New-Object Drawing.Size(0, 1); $tabControl.SizeMode = 'Fixed'

# Creamos las páginas
$tabLimpieza = New-Object Windows.Forms.TabPage; $tabLimpieza.BackColor = $cBg
$tabRed = New-Object Windows.Forms.TabPage; $tabRed.BackColor = $cBg

$tabControl.Controls.AddRange(@($tabLimpieza, $tabRed))
$form.Controls.Add($tabControl)

# --- MENÚ SUPERIOR (Navegación) ---
function New-NavBtn($txt, $x, $tab) {
    $b = New-Object Windows.Forms.Button
    $b.Text = $txt; $b.Location = New-Object Drawing.Point($x, 15); $b.Size = New-Object Drawing.Size(120, 35)
    $b.FlatStyle = 'Flat'; $b.BackColor = $cCard; $b.ForeColor = $cText
    $b.Add_Click({ $tabControl.SelectedTab = $tab })
    return $b
}

$form.Controls.Add((New-NavBtn 'Limpieza' 20 $tabLimpieza))
$form.Controls.Add((New-NavBtn 'Red' 150 $tabRed))

# --- CONTENIDO DE PÁGINAS ---
# Ejemplo en Limpieza
$lblLimpieza = New-Object Windows.Forms.Label; $lblLimpieza.Text = "Herramientas de Limpieza"; $lblLimpieza.ForeColor = $cAcc
$lblLimpieza.Location = New-Object Drawing.Point(20, 20); $tabLimpieza.Controls.Add($lblLimpieza)

# Ejemplo en Red
$lblRed = New-Object Windows.Forms.Label; $lblRed.Text = "Herramientas de Red"; $lblRed.ForeColor = $cAcc
$lblRed.Location = New-Object Drawing.Point(20, 20); $tabRed.Controls.Add($lblRed)

# --- CONSOLA ---
$outputBox = New-Object Windows.Forms.RichTextBox
$outputBox.Location = New-Object Drawing.Point(560, 20); $outputBox.Size = New-Object Drawing.Size(210, 520)
$outputBox.BackColor = $cOut; $outputBox.ForeColor = $cAcc; $outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# --- CIERRE ---
$form.Add_FormClosing({ $Global:RSPool.Close(); $Global:RSPool.Dispose() })
[Windows.Forms.Application]::Run($form)
