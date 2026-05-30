Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# =========================
# FORM PRINCIPAL
# =========================
$form = New-Object System.Windows.Forms.Form
$form.Text = "SYSCODI TOOLS PRO v4"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.StartPosition = "CenterScreen"

# =========================
# TEXT BOX OUTPUT
# =========================
$output = New-Object System.Windows.Forms.TextBox
$output.Multiline = $true
$output.Size = New-Object System.Drawing.Size(560,200)
$output.Location = New-Object System.Drawing.Point(10,10)
$output.ScrollBars = "Vertical"
$form.Controls.Add($output)

function Log($text){
    $output.AppendText("`r`n$text")
}

# =========================
# VER PUERTOS
# =========================
$btnPorts = New-Object System.Windows.Forms.Button
$btnPorts.Text = "Ver Puertos"
$btnPorts.Location = New-Object System.Drawing.Point(10,230)
$btnPorts.Add_Click({
    $output.Clear()
    $data = netstat -ano
    Log $data
})
$form.Controls.Add($btnPorts)

# =========================
# MATAR PROCESO POR PUERTO
# =========================
$btnKill = New-Object System.Windows.Forms.Button
$btnKill.Text = "Liberar Puerto 80/3306"
$btnKill.Location = New-Object System.Drawing.Point(120,230)
$btnKill.Add_Click({
    
    $ports = @(80, 3306)

    foreach ($p in $ports) {
        $id = netstat -ano | findstr ":$p" | ForEach-Object {
            ($_ -split "\s+")[-1]
        }

        if ($id) {
            taskkill /F /PID $id
            Log "Puerto $p liberado (PID $id)"
        } else {
            Log "Puerto $p libre"
        }
    }
})
$form.Controls.Add($btnKill)

# =========================
# LIMPIAR TEMP
# =========================
$btnClean = New-Object System.Windows.Forms.Button
$btnClean.Text = "Limpiar Sistema"
$btnClean.Location = New-Object System.Drawing.Point(320,230)
$btnClean.Add_Click({
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Log "Sistema limpiado"
})
$form.Controls.Add($btnClean)

# =========================
# INFO RED
# =========================
$btnNet = New-Object System.Windows.Forms.Button
$btnNet.Text = "Red"
$btnNet.Location = New-Object System.Drawing.Point(10,280)
$btnNet.Add_Click({
    $output.Clear()
    Log (ipconfig /all)
})
$form.Controls.Add($btnNet)

# =========================
# SALIR
# =========================
$btnExit = New-Object System.Windows.Forms.Button
$btnExit.Text = "Salir"
$btnExit.Location = New-Object System.Drawing.Point(120,280)
$btnExit.Add_Click({ $form.Close() })
$form.Controls.Add($btnExit)

# =========================
# MOSTRAR FORM
# =========================
$form.ShowDialog()
