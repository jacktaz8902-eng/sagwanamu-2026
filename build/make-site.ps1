<#
  명단(build/data.json)을 암호로 암호화해 index.html 을 다시 만듭니다.

    powershell -ExecutionPolicy Bypass -File build\make-site.ps1 -Password 7766

  data.json 은 개인정보가 담겨 있어 저장소에 올리지 않습니다(.gitignore).
  형식: [{ "seq":1, "team":"1조", "region":"01. 수원", "pub":"공립", "lvl":"유",
           "org":"매산유치원", "name":"강기옥", "room":"1", "roomKind":"동일지역·동일조" }, ...]
#>
param(
  [string]$Password = "7766",
  [int]$Iterations = 400000
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent

$body = [System.IO.File]::ReadAllText("$PSScriptRoot\body.html", [System.Text.Encoding]::UTF8)
$json = [System.IO.File]::ReadAllText("$PSScriptRoot\data.json", [System.Text.Encoding]::UTF8)
$plainBytes = [System.Text.Encoding]::UTF8.GetBytes($json)

# --- AES-256-CBC + PBKDF2(SHA-256) ---
$rng  = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$salt = New-Object byte[] 16; $rng.GetBytes($salt)
$kdf  = New-Object System.Security.Cryptography.Rfc2898DeriveBytes(
          $Password, $salt, $Iterations, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
$aes  = [System.Security.Cryptography.Aes]::Create()
$aes.KeySize = 256; $aes.Key = $kdf.GetBytes(32)
$aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
$aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
$aes.GenerateIV()
$ct  = $aes.CreateEncryptor().TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
$sum = ([System.Security.Cryptography.SHA256]::Create().ComputeHash($plainBytes) |
        ForEach-Object { $_.ToString("x2") }) -join ""

$payload = @{
  mode = "enc"; iter = $Iterations
  salt = [Convert]::ToBase64String($salt)
  iv   = [Convert]::ToBase64String($aes.IV)
  ct   = [Convert]::ToBase64String($ct)
  sum  = $sum
} | ConvertTo-Json -Compress

$title = "2026 특수교육지도사 사과나무 연수 · 조/숙소 찾기"
$head = "<!doctype html>`n<html lang=`"ko`">`n<head>`n" +
  "<meta charset=`"utf-8`">`n" +
  "<meta name=`"viewport`" content=`"width=device-width, initial-scale=1, viewport-fit=cover`">`n" +
  "<meta name=`"theme-color`" content=`"#EFF4D2`">`n" +
  "<meta name=`"apple-mobile-web-app-capable`" content=`"yes`">`n" +
  "<meta name=`"apple-mobile-web-app-status-bar-style`" content=`"default`">`n" +
  "<meta name=`"apple-mobile-web-app-title`" content=`"사과나무 연수`">`n" +
  "<meta name=`"format-detection`" content=`"telephone=no`">`n" +
  "<title>$title</title>`n" +
  "<meta name=`"robots`" content=`"noindex, nofollow, noarchive`">`n" +
  "<link rel=`"manifest`" href=`"manifest.webmanifest`">`n" +
  "<link rel=`"icon`" href=`"icon-192.png`" sizes=`"192x192`">`n" +
  "<link rel=`"apple-touch-icon`" href=`"apple-touch-icon.png`">`n" +
  "</head>`n<body>`n"

# -replace 는 정규식이라 payload 의 특수문자가 깨질 수 있어 String.Replace 사용
$filled = $body.Replace('/*__PAYLOAD__*/', $payload)
if ($filled -eq $body) { throw "payload 자리표시자를 찾지 못했습니다" }

[System.IO.File]::WriteAllText("$root\index.html", $head + $filled + "`n</body>`n</html>`n",
  (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("index.html 생성 완료 · {0:N0} bytes · PBKDF2 {1:N0}회" -f (Get-Item "$root\index.html").Length, $Iterations)
