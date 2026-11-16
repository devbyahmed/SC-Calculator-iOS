# Draws the four disguise icons (1024x1024, no transparency) into the asset catalog.
# Run on Windows:  powershell -ExecutionPolicy Bypass -File scripts\make-icons.ps1
param([string]$Assets = (Join-Path $PSScriptRoot "..\SCCalculator\Assets.xcassets"))

Add-Type -AssemblyName System.Drawing
$S = 1024

function New-Canvas {
    $bmp = New-Object System.Drawing.Bitmap $S, $S, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    return @($bmp, $g)
}

function Fill-Gradient($g, $c1, $c2) {
    # Slightly oversized so the gradient has no seam at the edges.
    $rect = New-Object System.Drawing.Rectangle -4, -4, ($S + 8), ($S + 8)
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 90.0
    $brush.WrapMode = [System.Drawing.Drawing2D.WrapMode]::TileFlipXY
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()
}

function C($hex) { [System.Drawing.ColorTranslator]::FromHtml($hex) }

function Round-Pen($color, $width) {
    $p = New-Object System.Drawing.Pen $color, $width
    $p.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $p.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    return $p
}

function Save-Icon($bmp, $set, $name) {
    $dir = Join-Path $Assets $set
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $bmp.Save((Join-Path $dir $name), [System.Drawing.Imaging.ImageFormat]::Png)
}

function Rounded-Rect($x, $y, $w, $h, $r) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $p.AddArc($x, $y, $d, $d, 180, 90)
    $p.AddArc($x + $w - $d, $y, $d, $d, 270, 90)
    $p.AddArc($x + $w - $d, $y + $h - $d, $d, $d, 0, 90)
    $p.AddArc($x, $y + $h - $d, $d, $d, 90, 90)
    $p.CloseFigure()
    return $p
}

# ---------- Calculator (main icon, from design/AppIcon-source.png) ----------
# The source is a rounded blue tile on a transparent background. Crop to the tile so the
# blue fills the square; iOS rounds the corners itself (its mask is rounder than the tile's).
$src = New-Object System.Drawing.Bitmap (Join-Path $PSScriptRoot "..\design\AppIcon-source.png")
$minX = $src.Width; $minY = $src.Height; $maxX = 0; $maxY = 0
for ($y = 0; $y -lt $src.Height; $y++) {
    for ($x = 0; $x -lt $src.Width; $x++) {
        if ($src.GetPixel($x, $y).A -gt 200) {
            if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
            if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
        }
    }
}
$inset = 6
$side = [Math]::Min($maxX - $minX, $maxY - $minY) - 2 * $inset
$cx = ($minX + $maxX) / 2; $cy = ($minY + $maxY) / 2
$crop = New-Object System.Drawing.RectangleF ([float]($cx - $side / 2)), ([float]($cy - $side / 2)), ([float]$side), ([float]$side)
$bmp, $g = New-Canvas
$bg = New-Object System.Drawing.SolidBrush (C "#4AA6F5")
$g.FillRectangle($bg, 0, 0, $S, $S); $bg.Dispose()
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($src, (New-Object System.Drawing.RectangleF 0, 0, $S, $S), $crop, [System.Drawing.GraphicsUnit]::Pixel)
$src.Dispose()
Save-Icon $bmp "AppIcon.appiconset" "icon.png"
Save-Icon $bmp "Preview-Calculator.imageset" "icon.png"
$g.Dispose(); $bmp.Dispose()

# ---------- Notes ----------
$bmp, $g = New-Canvas
Fill-Gradient $g (C "#FFD54A") (C "#FF9F1C")
$shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(50, 120, 60, 0))
$path = Rounded-Rect 232 212 580 660 64
$m = New-Object System.Drawing.Drawing2D.Matrix
$m.Translate(10, 18); $path.Transform($m)
$g.FillPath($shadow, $path); $path.Dispose(); $shadow.Dispose()
$paper = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$path = Rounded-Rect 222 194 580 660 64
$g.FillPath($paper, $path); $path.Dispose(); $paper.Dispose()
$pen = Round-Pen (C "#C9C9D1") 26
foreach ($y in 340, 450, 560) { $g.DrawLine($pen, 312, $y, 712, $y) }
$g.DrawLine($pen, 312, 670, 560, 670)
$pen.Dispose()
$accent = Round-Pen (C "#FF9F1C") 26
$g.DrawLine($accent, 312, 260, 470, 260)
$accent.Dispose()
Save-Icon $bmp "AppIcon-Notes.appiconset" "icon.png"
Save-Icon $bmp "Preview-Notes.imageset" "icon.png"
$g.Dispose(); $bmp.Dispose()

# ---------- Weather ----------
$bmp, $g = New-Canvas
Fill-Gradient $g (C "#5AB2FF") (C "#1D4FD1")
$sun = New-Object System.Drawing.SolidBrush (C "#FFD43B")
$g.FillEllipse($sun, 230, 210, 360, 360); $sun.Dispose()
$cloud = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$g.FillEllipse($cloud, 300, 470, 300, 300)
$g.FillEllipse($cloud, 500, 390, 340, 340)
$g.FillEllipse($cloud, 200, 590, 260, 200)
$path = Rounded-Rect 300 600 560 170 85
$g.FillPath($cloud, $path); $path.Dispose()
$cloud.Dispose()
Save-Icon $bmp "AppIcon-Weather.appiconset" "icon.png"
Save-Icon $bmp "Preview-Weather.imageset" "icon.png"
$g.Dispose(); $bmp.Dispose()

# ---------- Compass ----------
$bmp, $g = New-Canvas
Fill-Gradient $g (C "#2C2C34") (C "#08080C")
$ring = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), 26
$g.DrawEllipse($ring, 172, 172, 680, 680); $ring.Dispose()
$tick = Round-Pen (C "#9A9AA5") 14
for ($i = 0; $i -lt 12; $i++) {
    $a = $i * [Math]::PI / 6
    $x1 = 512 + 300 * [Math]::Cos($a); $y1 = 512 + 300 * [Math]::Sin($a)
    $x2 = 512 + 270 * [Math]::Cos($a); $y2 = 512 + 270 * [Math]::Sin($a)
    $g.DrawLine($tick, [float]$x1, [float]$y1, [float]$x2, [float]$y2)
}
$tick.Dispose()
$red = New-Object System.Drawing.SolidBrush (C "#FF3B30")
$white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
$north = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF 512, 250), (New-Object System.Drawing.PointF 572, 512), (New-Object System.Drawing.PointF 452, 512))
$south = [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF 512, 774), (New-Object System.Drawing.PointF 572, 512), (New-Object System.Drawing.PointF 452, 512))
$g.FillPolygon($red, $north); $g.FillPolygon($white, $south)
$hub = New-Object System.Drawing.SolidBrush (C "#1C1C22")
$g.FillEllipse($hub, 488, 488, 48, 48)
$red.Dispose(); $white.Dispose(); $hub.Dispose()
Save-Icon $bmp "AppIcon-Compass.appiconset" "icon.png"
Save-Icon $bmp "Preview-Compass.imageset" "icon.png"
$g.Dispose(); $bmp.Dispose()

Write-Output "Icons written to $Assets"
