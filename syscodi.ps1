#Requires -Version 5.1
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- GESTIÓN DE TRABAJOS (MOTOR) ---
$Global:RSPool = [RunspaceFactory]::CreateRunspacePool(1, 4)
$Global:RSPool.ApartmentState = 'STA'
$Global:RSPool.Open()
$Global:Jobs = [System.Collections.Generic.List[hashtable]]::new()

function Start-Job2([scriptblock]$Code) {
    $ps = [PowerShell]::Create(); $ps.RunspacePool = $Global:RSPool
    [void]$ps.AddScript($Code)
    $h = $ps.BeginInvoke()
    $Global:Jobs.Add(@{ PS = $ps; Handle = $h })
}

# --- INTERFAZ ---
$form = New-Object Windows.Forms.Form
$form.Text = 'SysCodi QuickFix Lite'; $form.Size = New-Object Drawing.Size(400, 350)
$form.StartPosition = 'CenterScreen'

$output = New-Object Windows.Forms.ListBox
$output.Location = New-Object Drawing.Point(10, 100); $output.Size = New-Object Drawing.Size(360, 200)
$form.Controls.Add($output)

# --- BOTONES ---
$btn1 = New-Object Windows.Forms.Button; $btn1.Text = "Limpiar Temp"; $btn1.Location = New-Object Drawing.Point(10, 10); $btn1.Size = New-Object Drawing.Size(120, 30)
$btn1.Add_Click({
    $output.Items.Add("Iniciando limpieza...")
    Start-Job2 {
        # Usamos 'Write-Output' para devolver el texto correctamente
        Remove-Item "$env:TEMP\*" -Recurse -Force -EA SilentlyContinue
        Write-Output "Limpieza de temporales completada."
    }
})
$form.Controls.Add($btn1)

$btn2 = New-Object Windows.Forms.Button; $btn2.Text = "Flush DNS"; $btn2.Location = New-Object Drawing.Point(140, 10); $btn2.Size = New-Object Drawing.Size(120, 30)
$btn2.Add_Click({
    $output.Items.Add("Limpiando DNS...")
    Start-Job2 { 
        ipconfig /flushdns | Out-Null
        Write-Output "Caché DNS vaciada con éxito." 
    }
})
$form.Controls.Add($btn2)

# --- TIMER (VIGILANTE) ---
$jt = New-Object Windows.Forms.Timer; $jt.Interval = 800
$jt.Add_Tick({
    foreach ($j in $Global:Jobs.ToArray()) {
        if ($j.Handle.IsCompleted) {
            # Recogemos la salida del PowerShell y convertimos a texto plano
            $results = $j.PS.EndInvoke($j.Handle)
            foreach ($res in $results) {
                $output.Items.Add($res.ToString())
            }
            $j.PS.Dispose(); $Global:Jobs.Remove($j)
        }
    }
})
$jt.Start()

$form.Add_FormClosing({ $Global:RSPool.Close(); $Global:RSPool.Dispose() })
[Windows.Forms.Application]::Run($form)
