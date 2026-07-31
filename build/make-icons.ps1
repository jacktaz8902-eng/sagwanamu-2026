$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$site = "C:\Users\PC2404\AppData\Local\Temp\claude\C--Users-PC2404\d059fefe-d89c-46ee-92ee-22d689f351d3\scratchpad\site"
New-Item -ItemType Directory -Force $site | Out-Null

function New-Icon([int]$size, [string]$path) {
  $bmp = New-Object System.Drawing.Bitmap($size, $size)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $s = $size / 512.0

  $bg     = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#EFF4D2"))
  $apple  = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#D45840"))
  $leaf   = New-Object System.Drawing.SolidBrush ([System.Drawing.ColorTranslator]::FromHtml("#4E8F33"))
  $stem   = New-Object System.Drawing.Pen ([System.Drawing.ColorTranslator]::FromHtml("#7A5232")), (18 * $s)
  $stem.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $stem.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round

  $g.FillRectangle($bg, 0, 0, $size, $size)

  # 사과 : 원 두 개를 겹쳐 통통한 실루엣
  $g.FillEllipse($apple,  86 * $s, 206 * $s, 236 * $s, 236 * $s)
  $g.FillEllipse($apple, 190 * $s, 206 * $s, 236 * $s, 236 * $s)
  $g.FillEllipse($apple, 138 * $s, 234 * $s, 236 * $s, 220 * $s)
  # 윗부분 홈
  $g.FillEllipse($bg, 222 * $s, 186 * $s, 68 * $s, 58 * $s)

  # 잎 → 줄기 순서로 그려 줄기가 사과 위에 얹히도록
  $st = $g.Save()
  $g.TranslateTransform(286 * $s, 130 * $s)
  $g.RotateTransform(-30)
  $g.FillEllipse($leaf, 0, -32 * $s, 132 * $s, 64 * $s)
  $g.Restore($st)
  $g.DrawLine($stem, 258 * $s, 232 * $s, 282 * $s, 136 * $s)

  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose(); $bmp.Dispose()
  Write-Output ("{0}  {1}x{1}" -f (Split-Path $path -Leaf), $size)
}

New-Icon 192 "$site\icon-192.png"
New-Icon 512 "$site\icon-512.png"
New-Icon 180 "$site\apple-touch-icon.png"
