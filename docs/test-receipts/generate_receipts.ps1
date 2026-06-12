# Generates the synthetic multi-currency test receipts (PNG) from receipts.json.
# Usage: powershell -ExecutionPolicy Bypass -File generate_receipts.ps1
# Re-run after editing receipts.json to refresh the images.

Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$json = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'receipts.json')
$receipts = $json | ConvertFrom-Json

function New-ReceiptImage {
    param($r, [string]$outPath)

    $w = 480
    $h = 200 + ($r.sub.Count * 20) + ($r.items.Count * 26) + 150

    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::White)

    $black = [System.Drawing.Brushes]::Black
    $fHeader = New-Object System.Drawing.Font('Arial', 21, [System.Drawing.FontStyle]::Bold)
    $fSub    = New-Object System.Drawing.Font('Arial', 11)
    $fItem   = New-Object System.Drawing.Font('Arial', 12)
    $fTotal  = New-Object System.Drawing.Font('Arial', 16, [System.Drawing.FontStyle]::Bold)
    $fFoot   = New-Object System.Drawing.Font('Arial', 10, [System.Drawing.FontStyle]::Italic)

    $fmtCenter = New-Object System.Drawing.StringFormat
    $fmtCenter.Alignment = [System.Drawing.StringAlignment]::Center
    $fmtNear = New-Object System.Drawing.StringFormat
    $fmtNear.Alignment = [System.Drawing.StringAlignment]::Near
    $fmtFar = New-Object System.Drawing.StringFormat
    $fmtFar.Alignment = [System.Drawing.StringAlignment]::Far

    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::Gray, 1)
    $pen.DashStyle = [System.Drawing.Drawing2D.DashStyle]::Dash

    $isRtl = [bool]$r.rtl
    $y = 28.0

    $g.DrawString([string]$r.header, $fHeader, $black,
        (New-Object System.Drawing.RectangleF(20, $y, 440, 36)), $fmtCenter)
    $y += 48

    foreach ($s in $r.sub) {
        $g.DrawString([string]$s, $fSub, $black,
            (New-Object System.Drawing.RectangleF(20, $y, 440, 20)), $fmtCenter)
        $y += 20
    }

    $y += 8
    $g.DrawLine($pen, 28, $y, 452, $y)
    $y += 12

    foreach ($it in $r.items) {
        $name = [string]$it[0]
        $price = [string]$it[1]
        if ($isRtl) {
            $g.DrawString($name, $fItem, $black,
                (New-Object System.Drawing.RectangleF(140, $y, 312, 22)), $fmtFar)
            $g.DrawString($price, $fItem, $black,
                (New-Object System.Drawing.RectangleF(28, $y, 110, 22)), $fmtNear)
        } else {
            $g.DrawString($name, $fItem, $black,
                (New-Object System.Drawing.RectangleF(28, $y, 310, 22)), $fmtNear)
            $g.DrawString($price, $fItem, $black,
                (New-Object System.Drawing.RectangleF(340, $y, 112, 22)), $fmtFar)
        }
        $y += 26
    }

    $y += 6
    $g.DrawLine($pen, 28, $y, 452, $y)
    $y += 14

    if ($isRtl) {
        $g.DrawString([string]$r.totalLabel, $fTotal, $black,
            (New-Object System.Drawing.RectangleF(200, $y, 252, 28)), $fmtFar)
        $g.DrawString([string]$r.totalValue, $fTotal, $black,
            (New-Object System.Drawing.RectangleF(28, $y, 160, 28)), $fmtNear)
    } else {
        $g.DrawString([string]$r.totalLabel, $fTotal, $black,
            (New-Object System.Drawing.RectangleF(28, $y, 280, 28)), $fmtNear)
        $g.DrawString([string]$r.totalValue, $fTotal, $black,
            (New-Object System.Drawing.RectangleF(300, $y, 152, 28)), $fmtFar)
    }
    $y += 38

    $g.DrawLine($pen, 28, $y, 452, $y)
    $y += 16

    $g.DrawString([string]$r.footer, $fFoot, $black,
        (New-Object System.Drawing.RectangleF(20, $y, 440, 20)), $fmtCenter)

    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

foreach ($r in $receipts) {
    $out = Join-Path $root ([string]$r.file)
    New-ReceiptImage $r $out
    Write-Output ("Created " + $out)
}
