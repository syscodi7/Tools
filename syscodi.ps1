#Requiere -Version 5.1
# SysCodi WinTool - Réplica de Interfaz de Reparación (image_1.png)
# Este script recrea la estética oscura, las tarjetas y los textos exactos.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# COMPROBACIÓN DE ADMINISTRADOR
# ============================================================
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    [Windows.Forms.MessageBox]::Show("Esta herramienta requiere privilegios de Administrador para ejecutar las reparaciones del sistema.", "SysCodi - Error de Privilegios", "OK", "Error")
    exit
}

# ============================================================
# PALETA DE COLORES (Extráida de la imagen de referencia)
# ============================================================
# Fondo de la ventana principal
$cBgMain    = [Drawing.Color]::FromArgb(6, 12, 28) 
# Fondo del panel lateral izquierdo
$cBgSide    = [Drawing.Color]::FromArgb(10, 16, 32) 
# Fondo de las tarjetas de herramientas
$cBgCard    = [Drawing.Color]::FromArgb(13, 21, 41) 
# Fondo del botón "Ejecutar"
$cBgBtn     = [Drawing.Color]::FromArgb(10, 16, 32) 
# Color de acento (Azul eléctrico para el logo y selección)
$cAccent    = [Drawing.Color]::FromArgb(52, 152, 219) 
# Color de borde (Tarjetas, separadores)
$cBorder    = [Drawing.Color]::FromArgb(26, 40, 64) 
# Texto principal (Blanco/Gris muy claro)
$cText      = [Drawing.Color]::FromArgb(226, 232, 240) 
# Texto secundario/descripciones (Gris azulado)
$cSubText   = [Drawing.Color]::FromArgb(144, 168, 192) 
# Estado Verde (Correcto)
$cGreen     = [Drawing.Color]::FromArgb(46, 204, 113)

# ============================================================
# FUENTES
# ============================================================
$fTitle    = New-Object Drawing.Font("Segoe UI", 12, [Drawing.FontStyle]::Bold)
$fSubTitle = New-Object Drawing.Font("Segoe UI", 8)
$fMenu     = New-Object Drawing.Font("Segoe UI", 9)
$fCardHead = New-Object Drawing.Font("Segoe UI", 10, [Drawing.FontStyle]::Bold)
$fCardDesc = New-Object Drawing.Font("Segoe UI", 8)
$fStatus   = New-Object Drawing.Font("Segoe UI", 8.5)
$fClock    = New-Object Drawing.Font("Consolas", 9)

# ============================================================
# CONFIGURACIÓN DEL FORMULARIO PRINCIPAL
# ============================================================
$form = New-Object Windows.Forms.Form
$form.Text          = "SysCodi WinTool"
$form.Size          = New-Object Drawing.Size(1200, 780)
$form.StartPosition = "CenterScreen"
$form.BackColor     = $cBgMain
$form.ForeColor     = $cText
$form.FormBorderStyle = "Sizable" # Permitir cambiar tamaño

# Contenedor para el padding global de la interfaz
$mainPadding = New-Object Windows.Forms.Panel
$mainPadding.Dock = "Fill"
$mainPadding.Padding = New-Object Windows.Forms.Padding(16)
$form.Controls.Add($mainPadding)

# ============================================================
# HELPERS DE DIBUJO (Para bordes redondeados y gráficos custom)
# ============================================================
# Función para crear un GraphicsPath con bordes redondeados
function Get-RoundedPath($rect, $radius) {
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $arcRect = [Drawing.RectangleF]::new($rect.X, $rect.Y, $diameter, $diameter)

    $path.AddArc($arcRect, 180, 90) # Top Left
    $arcRect.X = $rect.Right - $diameter
    $path.AddArc($arcRect, 270, 90) # Top Right
    $arcRect.Y = $rect.Bottom - $diameter
    $path.AddArc($arcRect, 0, 90)  # Bottom Right
    $arcRect.X = $rect.X
    $path.AddArc($arcRect, 90, 90)  # Bottom Left
    $path.CloseFigure()
    return $path
}

# ============================================================
# PANEL LATERAL IZQUIERDO (Menú de Navegación)
# ============================================================
$sidePanel = New-Object Windows.Forms.Panel
$sidePanel.Dock      = "Left"
$sidePanel.Width     = 220
$sidePanel.BackColor = $cBgSide
$sidePanel.Padding   = New-Object Windows.Forms.Padding(16, 24, 16, 24)
$mainPadding.Controls.Add($sidePanel)

# -- LOGO Y TÍTULO (Área superior del sidebar) --
$logoArea = New-Object Windows.Forms.Panel
$logoArea.Dock    = "Top"
$logoArea.Height  = 60
$sidePanel.Controls.Add($logoArea)

# Dibujo custom del Logo 'S'
$logoArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Dibujar el rectángulo de fondo azul
    $rect = [Drawing.Rectangle]::new(0, 0, 40, 40)
    $path = Get-RoundedPath $rect 8
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(41, 128, 185))
    $g.FillPath($brush, $path)
    
    # Dibujar la 'S' estilizada
    $fS = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
    $bS = New-Object Drawing.SolidBrush($cText)
    $sf = New-Object Drawing.StringFormat
    $sf.Alignment = "Center"; $sf.LineAlignment = "Center"
    $g.DrawString("S", $fS, $bS, [Drawing.RectangleF]::new(0,0,40,40), $sf)
})

$lblTitle = New-Object Windows.Forms.Label
$lblTitle.Text      = "SysCodi WinTool"
$lblTitle.Location  = New-Object Drawing.Point(52, 2)
$lblTitle.Size      = New-Object Drawing.Size(150, 22)
$lblTitle.Font      = $fTitle
$lblTitle.ForeColor = $cText
$logoArea.Controls.Add($lblTitle)

$lblTitleSub = New-Object Windows.Forms.Label
$lblTitleSub.Text      = "Herramientas esenciales para Windows"
$lblTitleSub.Location  = New-Object Drawing.Point(52, 24)
$lblTitleSub.Size      = New-Object Drawing.Size(150, 30)
$lblTitleSub.Font      = $fSubTitle
$lblTitleSub.ForeColor = $cSubText
$logoArea.Controls.Add($lblTitleSub)

# -- BOTONES DE MENÚ (Dibujo custom para selección) --
$menuButtons = @()
function New-MenuBtn($txt, $icon, $selected = $false) {
    $btn = New-Object Windows.Forms.Panel
    $btn.Dock      = "Top"
    $btn.Height    = 44
    $btn.Cursor    = "Hand"
    $btn.Margin    = New-Object Windows.Forms.Padding(0, 4, 0, 4)
    $btn.Tag       = $selected # Usar Tag para guardar estado de selección
    
    # Dibujo custom del botón (Owner-Drawn)
    $btn.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = [Drawing.Rectangle]::new(0, 0, $s.Width-1, $s.Height-1)
        
        # Si está seleccionado, dibujar fondo y barra lateral
        if ($s.Tag -eq $true) {
            # Fondo ligeramente más claro
            $brushBg = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(18, 28, 46))
            $g.FillRectangle($brushBg, $rect)
            # Barra lateral azul
            $brushAcc = New-Object Drawing.SolidBrush($cAccent)
            $g.FillRectangle($brushAcc, [Drawing.Rectangle]::new(0, 0, 4, $s.Height))
        }

        # Dibujar Icono (Usando Unicode para simplificar, idealmente usar imágenes PNG)
        $fI = New-Object Drawing.Font("Segoe UI", 12)
        $bI = New-Object Drawing.SolidBrush(if($s.Tag -eq $true){$cAccent}else{$cSubText})
        $g.DrawString($icon, $fI, $bI, 12, 10)

        # Dibujar Texto
        $bT = New-Object Drawing.SolidBrush(if($s.Tag -eq $true){$cText}else{$cSubText})
        $g.DrawString($txt, $fMenu, $bT, 40, 12)
    })
    
    $sidePanel.Controls.Add($btn)
    $btn.BringToFront()
    $script:menuButtons += $btn
}

# Crear botones (orden invertido por Dock=Top)
New-MenuBtn "Ajustes"     "⚙"
New-MenuBtn "Reportes"    "📄"
New-MenuBtn "Aplicaciones" "⬡"
New-MenuBtn "Tareas"      "📋"
New-MenuBtn "Reparación"  "🛡" $true # Seleccionado por defecto
New-MenuBtn "Dashboard"   "🏠"

# Espaciador para empujar la versión hacia abajo
$spacer = New-Object Windows.Forms.Panel
$spacer.Dock = "Top"; $spacer.Height = 20
$sidePanel.Controls.Add($spacer); $spacer.BringToFront()

# -- INFO DE VERSIÓN (Área inferior) --
$versionArea = New-Object Windows.Forms.Panel
$versionArea.Dock    = "Bottom"
$versionArea.Height  = 40
$versionArea.Padding = New-Object Windows.Forms.Padding(0, 10, 0, 0)
$sidePanel.Controls.Add($versionArea)

# Dibujo custom para el logo pequeño y versión
$versionArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Rectángulo azul pequeño
    $rect = [Drawing.Rectangle]::new(0, 10, 24, 24)
    $path = Get-RoundedPath $rect 6
    $brush = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(41, 128, 185))
    $g.FillPath($brush, $path)
    # 'S' pequeña
    $fS = New-Object Drawing.Font("Segoe UI", 11, [Drawing.FontStyle]::Bold)
    $bS = New-Object Drawing.SolidBrush($cText)
    $sf = New-Object Drawing.StringFormat; $sf.Alignment = "Center"; $sf.LineAlignment = "Center"
    $g.DrawString("S", $fS, $bS, [Drawing.RectangleF]::new(0,10,24,24), $sf)

    # Texto de versión
    $fV = New-Object Drawing.Font("Segoe UI", 7.5)
    $bT = New-Object Drawing.SolidBrush($cText)
    $bS = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("SysCodi WinTool", $fV, $bT, 32, 12)
    $g.DrawString("Versión 1.0.0", $fV, $bS, 32, 24)
})

# ============================================================
# PANEL DE CONTENIDO PRINCIPAL (Área de Trabajo)
# ============================================================
$contentPanel = New-Object Windows.Forms.Panel
$contentPanel.Dock      = "Fill"
$contentPanel.BackColor = $cBgMain
$contentPanel.Padding   = New-Object Windows.Forms.Padding(24, 0, 0, 0) # Separación del sidebar
$mainPadding.Controls.Add($contentPanel)
$contentPanel.BringToFront()

# -- CABECERA DE LA SECCIÓN 'REPARACIÓN' --
$headerArea = New-Object Windows.Forms.Panel
$headerArea.Dock      = "Top"
$headerArea.Height    = 100
$contentPanel.Controls.Add($headerArea)

$headerArea.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Icono grande de reparación (Escudo + Llave)
    $fI = New-Object Drawing.Font("Segoe UI", 28)
    $bI = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("🛡️", $fI, $bI, 0, 10)

    # Título Grande
    $fT = New-Object Drawing.Font("Segoe UI", 20, [Drawing.FontStyle]::Bold)
    $bT = New-Object Drawing.SolidBrush($cText)
    $g.DrawString("Reparación", $fT, $bT, 60, 15)

    # Descripción
    $fD = New-Object Drawing.Font("Segoe UI", 9)
    $bD = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("Herramientas para reparar y solucionar problemas comunes del sistema.", $fD, $bD, 60, 50)
})

# -- PANEL DE ESTADO DEL SISTEMA (Info de OS, Usuario, Uptime) --
$statusArea = New-Object Windows.Forms.Panel
$statusArea.Dock      = "Top"
$statusArea.Height    = 70
$statusArea.Padding   = New-Object Windows.Forms.Padding(0, 0, 0, 10)
$contentPanel.Controls.Add($statusArea)

# Función para crear bloques de información (OS, Usuario, etc.)
function New-InfoBlock($txt, $subTxt, $icon, $x) {
    $block = New-Object Windows.Forms.Panel
    $block.Location = New-Object Drawing.Point($x, 0)
    $block.Size     = New-Object Drawing.Size(220, 60)
    $block.BackColor = $cBgCard
    
    $block.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = [Drawing.Rectangle]::new(0, 0, $s.Width-1, $s.Height-1)
        
        # Fondo redondeado y borde
        $path = Get-RoundedPath $rect 8
        $brushBg = New-Object Drawing.SolidBrush($cBgCard)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        # Icono
        $fI = New-Object Drawing.Font("Segoe UI", 16)
        $bI = New-Object Drawing.SolidBrush($cAccent)
        $g.DrawString($icon, $fI, $bI, 15, 15)

        # Texto Principal
        $fT = New-Object Drawing.Font("Segoe UI", 9, [Drawing.FontStyle]::Bold)
        $bT = New-Object Drawing.SolidBrush($cText)
        $g.DrawString($txt, $fT, $bT, 50, 15)

        # Texto Secundario
        $fS = New-Object Drawing.Font("Segoe UI", 8)
        $bS = New-Object Drawing.SolidBrush($cSubText)
        $g.DrawString($subTxt, $fS, $bS, 50, 32)
    })
    $statusArea.Controls.Add($block)
}

New-InfoBlock "Tiempo activo" "0d 2h 15m" "🕒" 460
New-InfoBlock "DESKTOP-7H5K2Q1" "syscodi" "👤" 230
New-InfoBlock "Windows 11 Pro" "23H2 (22631.3527)" "🪟" 0

# -- BARRA DE FILTROS (Pestañas internas) --
$filterBar = New-Object Windows.Forms.Panel
$filterBar.Dock      = "Top"
$filterBar.Height    = 40
$filterBar.Padding   = New-Object Windows.Forms.Padding(0, 0, 0, 5)
$contentPanel.Controls.Add($filterBar)

# Función para crear botones de filtro
$filterButtons = @()
$script:fX = 0
function New-FilterBtn($txt, $icon, $selected = $false) {
    $btn = New-Object Windows.Forms.Panel
    $btn.Location = New-Object Drawing.Point($script:fX, 0)
    $btn.Size     = New-Object Drawing.Size(120, 32)
    $btn.Cursor   = "Hand"
    $btn.Tag      = $selected
    
    $btn.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = [Drawing.Rectangle]::new(0, 0, $s.Width-1, $s.Height-1)
        
        # Fondo redondeado (solo si está seleccionado o hover)
        if ($s.Tag -eq $true) {
            $path = Get-RoundedPath $rect 6
            $brushBg = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(31, 51, 84)) # Azul selección
            $g.FillPath($brushBg, $path)
        }

        # Texto e Icono
        $fT = New-Object Drawing.Font("Segoe UI", 8.5)
        $bT = New-Object Drawing.SolidBrush($cText)
        $sf = New-Object Drawing.StringFormat; $sf.Alignment = "Center"; $sf.LineAlignment = "Center"
        $g.DrawString("$icon  $txt", $fT, $bT, [Drawing.RectangleF]::new(0,0,$s.Width,$s.Height), $sf)
    })
    
    $filterBar.Controls.Add($btn)
    $script:fX += 125
}

New-FilterBtn "Avanzado"      "⚙"
New-FilterBtn "Windows Update" "🔁"
New-FilterBtn "Seguridad"     "🛡️"
New-FilterBtn "Disco"         "💾"
New-FilterBtn "Red"           "🌐"
New-FilterBtn "Sistema"       "💻"
New-FilterBtn "Todo"          "📋" $true # Seleccionado

# -- GRILLA DE TARJETAS DE HERRAMIENTAS (Área inferior) --
$scrollPanel = New-Object Windows.Forms.Panel
$scrollPanel.Dock       = "Fill"
$scrollPanel.AutoScroll = $true # Permitir scroll si hay muchas tarjetas
$scrollPanel.Padding    = New-Object Windows.Forms.Padding(0, 10, 10, 10)
$contentPanel.Controls.Add($scrollPanel)
$scrollPanel.BringToFront()

# Función para crear una tarjeta de herramienta
$script:cX = 0; $script:cY = 0; $script:count = 0
function New-ToolCard($txt, $desc, $icon, $cmd) {
    $card = New-Object Windows.Forms.Panel
    $card.Size     = New-Object Drawing.Size(300, 160)
    # Calcular posición en grilla de 3 columnas
    $card.Location = New-Object Drawing.Point(($script:cX * 315), ($script:cY * 175))
    
    $card.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = [Drawing.Rectangle]::new(0, 0, $s.Width-1, $s.Height-1)
        
        # Fondo redondeado y borde
        $path = Get-RoundedPath $rect 10
        $brushBg = New-Object Drawing.SolidBrush($cBgCard)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        # Icono (Círculo azul de fondo)
        $g.FillEllipse(New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(26, 40, 64)), 20, 20, 40, 40)
        $fI = New-Object Drawing.Font("Segoe UI", 16)
        $bI = New-Object Drawing.SolidBrush($cAccent)
        $sf = New-Object Drawing.StringFormat; $sf.Alignment = "Center"; $sf.LineAlignment = "Center"
        $g.DrawString($icon, $fI, $bI, [Drawing.RectangleF]::new(20,20,40,40), $sf)

        # Título
        $g.DrawString($txt, $fCardHead, New-Object Drawing.SolidBrush($cText), 75, 22)

        # Descripción (con ajuste de texto)
        $rectDesc = [Drawing.RectangleF]::new(75, 45, 210, 60)
        $g.DrawString($desc, $fCardDesc, New-Object Drawing.SolidBrush($cSubText), $rectDesc)
    })
    
    # Botón "Ejecutar" dentro de la tarjeta
    $btnExe = New-Object Windows.Forms.Panel
    $btnExe.Size     = New-Object Drawing.Size(120, 30)
    $btnExe.Location = New-Object Drawing.Point(75, 110)
    $btnExe.Cursor   = "Hand"
    $btnExe.BackColor = $cBgBtn
    
    $btnExe.Add_Paint({
        param($s,$e)
        $g = $e.Graphics
        $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = [Drawing.Rectangle]::new(0, 0, $s.Width-1, $s.Height-1)
        
        # Fondo redondeado y borde del botón
        $path = Get-RoundedPath $rect 6
        $brushBg = New-Object Drawing.SolidBrush($cBgBtn)
        $g.FillPath($brushBg, $path)
        $pen = New-Object Drawing.Pen($cBorder, 1)
        $g.DrawPath($pen, $path)

        # Texto del botón
        $fB = New-Object Drawing.Font("Segoe UI", 8.5)
        $sf = New-Object Drawing.StringFormat; $sf.Alignment = "Center"; $sf.LineAlignment = "Center"
        $g.DrawString("Ejecutar", $fB, New-Object Drawing.SolidBrush($cText), [Drawing.RectangleF]::new(0,0,$s.Width,$s.Height), $sf)
    })
    
    # Lógica de ejecución
    $btnExe.Add_Click({
        [Windows.Forms.MessageBox]::Show("Ejecutando: $cmd", "SysCodi - Acción")
    })
    
    $card.Controls.Add($btnExe)
    $scrollPanel.Controls.Add($card)
    
    # Actualizar contadores de grilla
    $script:count++
    $script:cX++
    if ($script:cX -ge 3) { $script:cX = 0; $script:cY++ }
}

# Crear las 8 tarjetas de la imagen
New-ToolCard "SFC / Scannow" "Verifica y repara archivos de sistema protegidos de Windows." "🛡️" "sfc /scannow"
New-ToolCard "DISM RestoreHealth" "Repara la imagen del sistema usando DISM." "⚙️" "DISM /Online /Cleanup-Image /RestoreHealth"
New-ToolCard "Restablecer Windows Update" "Restaura los componentes de Windows Update." "🔁" "Reset-WindowsUpdate"
New-ToolCard "Restablecer Red" "Restablece la configuración de red a los valores predeterminados." "🌐" "netsh winsock reset"
New-ToolCard "Limpiar DNS" "Limpia la caché del DNS para solucionar problemas de conexión." "🌐" "ipconfig /flushdns"
New-ToolCard "CheckDisk (C:)" "Busca y repara errores en la unidad seleccionada." "💾" "chkdsk C: /f /r"
New-ToolCard "Inicio Avanzado" "Abre las opciones avanzadas de inicio de Windows." "🪟" "shutdown /r /o /t 0"
New-ToolCard "Reparar Store" "Repara problemas relacionados con Microsoft Store." "🛒" "wsreset.exe"

# ============================================================
# BARRA DE ESTADO INFERIOR (Footer)
# ============================================================
$footerBar = New-Object Windows.Forms.Panel
$footerBar.Dock      = "Bottom"
$footerBar.Height    = 30
$footerBar.BackColor = $cBgMain
$footerBar.Padding   = New-Object Windows.Forms.Padding(220, 0, 0, 0) # Alinear con el contenido, no sidebar
$mainPadding.Controls.Add($footerBar)

# Dibujo custom para el estado y el reloj
$footerBar.Add_Paint({
    param($s,$e)
    $g = $e.Graphics
    $g.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    
    # Separador superior
    $pen = New-Object Drawing.Pen($cBorder, 1)
    $g.DrawLine($pen, 240, 0, $s.Width, 0)

    # Estado Verde
    $fS = $fStatus
    $bG = New-Object Drawing.SolidBrush($cGreen)
    $g.DrawString("✔", $fS, $bG, 240, 8)
    $bT = New-Object Drawing.SolidBrush($cSubText)
    $g.DrawString("Sistema funcionando correctamente", $fS, $bT, 260, 8)

    # Reloj (alineado a la derecha)
    $time = (Get-Date -Format "dd/MM/yyyy  HH:mm:ss")
    $bC = New-Object Drawing.SolidBrush($cSubText)
    $sf = New-Object Drawing.StringFormat; $sf.Alignment = "Far"
    $g.DrawString($time, $fClock, $bC, [Drawing.RectangleF]::new(0,8,$s.Width-10,20), $sf)
})

# Timer para actualizar el reloj
$timer = New-Object Windows.Forms.Timer
$timer.Interval = 1000
$timer.Add_Tick({ $footerBar.Invalidate() })
$timer.Start()

# ============================================================
# ARRANQUE DE LA APLICACIÓN
# ============================================================
$form.Add_FormClosing({ $timer.Stop() })
$form.ShowDialog()
