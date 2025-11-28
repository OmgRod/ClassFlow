param(
  [Parameter(Mandatory=$true)]
  [string]$PfxBase64,
  [Parameter(Mandatory=$true)]
  [string]$PfxPassword,
  [string]$TimestampUrl = 'http://timestamp.digicert.com'
)

$ErrorActionPreference = 'Stop'

# Ensure signtool
$signtool = Get-Command signtool.exe -ErrorAction SilentlyContinue
if (-not $signtool) { throw 'signtool.exe not found in PATH.' }

# Reconstruct PFX
$certDir = Join-Path $PWD 'scripts/certs'
New-Item -ItemType Directory -Force -Path $certDir | Out-Null
$pfxPath = Join-Path $certDir 'signing-cert.pfx'
[IO.File]::WriteAllBytes($pfxPath, [Convert]::FromBase64String($PfxBase64))

# Import cert
$secure = ConvertTo-SecureString $PfxPassword -AsPlainText -Force
$cert = Import-PfxCertificate -FilePath $pfxPath -Password $secure -CertStoreLocation Cert:\CurrentUser\My
if (-not $cert) { throw 'Failed to import PFX certificate.' }
Write-Host "Imported cert thumbprint: $($cert.Thumbprint)"

# Find MSIX
$msix = Get-ChildItem -Recurse -Filter *.msix | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $msix) { throw 'No MSIX file found to sign.' }

# Sign
& $signtool.Path sign /fd sha256 /a /f $pfxPath /p $PfxPassword /tr $TimestampUrl /td sha256 "$($msix.FullName)"
Write-Host "Signed MSIX: $($msix.FullName)"
