$cert = New-SelfSignedCertificate `
  -Type CodeSigning `
  -Subject "CN=OmgRod" `
  -KeyAlgorithm RSA -KeyLength 3072 `
  -HashAlgorithm SHA256 `
  -KeyExportPolicy Exportable `
  -CertStoreLocation Cert:\CurrentUser\My `
  -NotAfter (Get-Date).AddYears(2)

$pwd = Read-Host "Enter PFX password" -AsSecureString
Export-PfxCertificate `
  -Cert $cert `
  -FilePath "omgrod-code-signing.pfx" `
  -Password $pwd