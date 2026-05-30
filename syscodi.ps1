Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "SysCodi WinTool (Pro Style)"
$form.Size = New-Object Drawing.Size(650,450)
$form.StartPosition = "CenterScreen"

$list = New-Object Windows.Forms.ListBox
$list.Size = New-Object Drawing.Size(300,350)
$list.Location = New-Object Drawing.Point(10,10)

$list.Items.Add("1. Limpieza del sistema")
$list.Items.Add("2. Reparar Windows (SFC)")
$list.Items.Add("3. Reparar imagen (DISM)")
$list.Items.Add("4. DNS Flush")
$list.Items.Add("5. Ver puertos")
$list.Items.Add("6. Matar puerto 80")
$list.Items.Add("7. Info del sistema")
$list.Items.Add("8. Salir")

$form.Controls.Add($list)

$btn = New-Object Windows.Forms.Button
$btn.Text = "Ejecutar"
$btn.Location = New-Object Drawing.Point(350,50)
$btn.Size = New-Object Drawing.Size(200,40)

$output = New-Object Windows.Forms.TextBox
$output.Multiline = $true
$output.Size = New-Object Drawing.Size(250,250)
$output.Location = New-Object Drawing.Point(350,100)
$form.Controls.Add($output)

function Run($cmd){
    $output.AppendText("`r`n> $cmd")
    $res = Invoke-Expression $cmd
    $output.AppendText("`r`n$res`r`n")
}

$btn.Add_Click({
    switch ($list.SelectedItem) {

        "1. Limpieza del sistema" {
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            $output.Text = "Sistema limpiado"
        }

        "2. Reparar Windows (SFC)" {
            Run "sfc /scannow"
        }

        "3. Reparar imagen (DISM)" {
            Run "DISM /Online /Cleanup-Image /RestoreHealth"
        }

        "4. DNS Flush" {
            Run "ipconfig /flushdns"
        }

        "5. Ver puertos" {
            Run "netstat -ano"
        }

        "6. Matar puerto 80" {
            $pid = netstat -ano | findstr ":80" | ForEach-Object { ($_ -split '\s+')[-1] }
            if ($pid) {
                taskkill /F /PID $pid
                $output.Text = "Puerto 80 liberado"
            }
        }

        "7. Info del sistema" {
            Run "systeminfo"
        }

        "8. Salir" {
            $form.Close()
        }
    }
})

$form.Controls.Add($btn)

$form.ShowDialog()
