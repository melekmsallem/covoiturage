param(
  [string]$OutDir = "out"
)

if (-not (Get-Command mmdc -ErrorAction SilentlyContinue)) {
  Write-Host "Mermaid CLI not found. Install with: npm i -g @mermaid-js/mermaid-cli" -ForegroundColor Yellow
  exit 1
}

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$mmdFiles = @(
  'passenger_use_case.mmd',
  'driver_use_case.mmd',
  'admin_use_case.mmd'
)

foreach ($file in $mmdFiles) {
  if (Test-Path $file) {
    $outFile = Join-Path $OutDir ($file -replace '\.mmd$', '.svg')
    Write-Host "Rendering $file -> $outFile"
    mmdc -i $file -o $outFile | Out-Host
  } else {
    Write-Host "Skipping missing file: $file" -ForegroundColor Yellow
  }
}

Write-Host "Done. SVGs in '$OutDir'." -ForegroundColor Green
