param(
    [string]$Dir = '.',
    [switch]$KeepParts
)

$ErrorActionPreference = 'Stop'
$Dir = (Resolve-Path $Dir).Path
$parts = @(Get-ChildItem -Path $Dir -Filter '*.iso.part*' | Sort-Object Name)
if ($parts.Count -eq 0) { throw "Nie znaleziono plikow *.iso.part* w $Dir" }

$isoName = $parts[0].Name -replace '\.part\d+$', ''
$isoPath = Join-Path $Dir $isoName
$first = Join-Path $Dir "$isoName.part00"
$drive = Get-PSDrive -Name $isoPath.Substring(0, 1)

if ($KeepParts) {
    if (Test-Path $isoPath) { Remove-Item -LiteralPath $isoPath -Force }
    $need = ($parts | Measure-Object -Property Length -Sum).Sum
    $toAppend = $parts
}
elseif (Test-Path $first) {
    if (Test-Path $isoPath) {
        Write-Host "Usuwam niepelny plik $isoName z poprzedniej proby"
        Remove-Item -LiteralPath $isoPath -Force
    }
    $toAppend = @($parts | Where-Object { $_.FullName -ne $first })
    $need = ($toAppend | Measure-Object -Property Length -Maximum).Maximum
}
else {
    if (-not (Test-Path $isoPath)) { throw "Brak $isoName.part00 i brak $isoName - pobierz czesci ponownie." }
    Write-Host "Wznawiam sklejanie $isoName"
    $toAppend = $parts
    $need = ($toAppend | Measure-Object -Property Length -Maximum).Maximum
}

$need = [int64]$need + 200MB
$free = (Get-PSDrive -Name $drive.Name).Free
if ($free -lt $need) {
    throw ("Za malo miejsca na dysku {0}: potrzeba {1:N1} GB, wolne {2:N1} GB. Zwolnij miejsce i uruchom ponownie." -f $drive.Name, ($need / 1GB), ($free / 1GB))
}

if (-not $KeepParts -and (Test-Path $first)) {
    Write-Host "  = $isoName.part00 -> $isoName"
    Move-Item -LiteralPath $first -Destination $isoPath
}

$mode = if ($KeepParts) { [System.IO.FileMode]::Create } else { [System.IO.FileMode]::Append }
$out = [System.IO.File]::Open($isoPath, $mode, [System.IO.FileAccess]::Write)
try {
    foreach ($p in $toAppend) {
        Write-Host "  + $($p.Name)"
        $before = $out.Length
        $in = [System.IO.File]::OpenRead($p.FullName)
        try {
            $in.CopyTo($out, 4MB)
            $out.Flush()
        }
        catch {
            $out.SetLength($before)
            throw
        }
        finally { $in.Close() }
        if (-not $KeepParts) { Remove-Item -LiteralPath $p.FullName -Force }
    }
}
finally { $out.Close() }

$shaFile = "$isoPath.sha256"
if (Test-Path $shaFile) {
    Write-Host 'Sprawdzam SHA256...'
    $expected = ((Get-Content $shaFile -TotalCount 1) -split '\s+')[0].ToLower()
    $actual = (Get-FileHash -Path $isoPath -Algorithm SHA256).Hash.ToLower()
    if ($expected -eq $actual) {
        Write-Host 'SHA256 OK - plik jest poprawny.' -ForegroundColor Green
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
