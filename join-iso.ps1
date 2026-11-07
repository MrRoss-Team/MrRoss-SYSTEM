param([string]$Dir = '.')

$ErrorActionPreference = 'Stop'
$Dir = (Resolve-Path $Dir).Path
$parts = @(Get-ChildItem -Path $Dir -Filter '*.iso.part*' | Sort-Object Name)
if ($parts.Count -eq 0) { throw "Nie znaleziono plikow *.iso.part* w $Dir" }

$isoName = $parts[0].Name -replace '\.part\d+$', ''
$isoPath = Join-Path $Dir $isoName
Write-Host "Skladam $($parts.Count) czesci -> $isoName"

$out = [System.IO.File]::Create($isoPath)
try {
    foreach ($p in $parts) {
        Write-Host "  + $($p.Name)"
        $in = [System.IO.File]::OpenRead($p.FullName)
        try { $in.CopyTo($out) } finally { $in.Close() }
    }
}
finally { $out.Close() }

$shaFile = "$isoPath.sha256"
if (Test-Path $shaFile) {
    $expected = ((Get-Content $shaFile -TotalCount 1) -split '\s+')[0].ToLower()
    $actual = (Get-FileHash -Path $isoPath -Algorithm SHA256).Hash.ToLower()
    if ($expected -eq $actual) {
        Write-Host 'SHA256 OK - plik jest poprawny.' -ForegroundColor Green
        Write-Host 'Czesci .part mozesz teraz usunac.'
    }
    else {
        Write-Host "SHA256 NIEZGODNE! oczekiwano $expected, jest $actual" -ForegroundColor Red
        exit 1
    }
}
else {
    Write-Host 'Brak pliku .sha256 - pomijam weryfikacje.' -ForegroundColor Yellow
}
Write-Host "Gotowe: $isoPath"
