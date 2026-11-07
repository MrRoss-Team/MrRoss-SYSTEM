<#
.SYNOPSIS
  Buduje obraz ISO HackBox (Kali Linux dla TryHackMe) na Windows przez Docker Desktop.

.DESCRIPTION
  Uruchamia build.sh w kontenerze kalilinux/kali-rolling. Caly proces budowania
  odbywa sie w wolumenie Dockera "hackbox-work" (NIE na OneDrive), a do katalogu
  -Output trafia tylko gotowy plik ISO.

  Wymagania:
    - Docker Desktop (uruchomiony, backend WSL2)
    - ok. 30 GB wolnego miejsca na dysku, na ktorym Docker trzyma dane
      (Docker Desktop -> Settings -> Resources -> Disk image location)
    - 4 GB RAM dla Dockera, szybki internet

.EXAMPLE
  .\build.ps1
  .\build.ps1 -Output D:\iso
  .\build.ps1 -Clean      # usuwa wolumen roboczy (np. po nieudanym budowaniu)
#>
[CmdletBinding()]
param(
    [string]$Output = (Join-Path $PSScriptRoot 'output'),
    [string]$Version = (Get-Date -Format 'yyyy.MM.dd'),
    [string]$HostName = 'hackbox',
    [string]$KaliRef = '',
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$image = 'docker.io/kalilinux/kali-rolling:latest'
$volume = 'hackbox-work'

function Info($msg) { Write-Host "[HackBox] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[HackBox] $msg" -ForegroundColor Yellow }

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Nie znaleziono dockera. Zainstaluj Docker Desktop: https://www.docker.com/products/docker-desktop/'
}

cmd /c "docker info >nul 2>&1"
if ($LASTEXITCODE -ne 0) {
    throw 'Docker Desktop nie dziala. Uruchom go i poczekaj, az ikona w zasobniku pokaze "Engine running".'
}

if ($Clean) {
    Info "Usuwam wolumen roboczy $volume ..."
    cmd /c "docker volume rm $volume >nul 2>&1"
}

# Ostrzezenie o miejscu na dysku C: (domyslna lokalizacja danych Docker Desktop)
$freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
if ($freeGB -lt 30) {
    Warn "Na dysku C: jest tylko $freeGB GB wolnego miejsca. Budowanie potrzebuje ok. 30 GB."
    Warn 'Zwolnij miejsce albo przenies dane Dockera na inny dysk (Settings -> Resources -> Disk image location).'
    Warn 'Alternatywa bez lokalnego miejsca: GitHub Actions (patrz README.md).'
    $answer = Read-Host 'Kontynuowac mimo to? (t/N)'
    if ($answer -notmatch '^[tTyY]') { exit 1 }
}

New-Item -ItemType Directory -Force -Path $Output | Out-Null
$Output = (Resolve-Path $Output).Path
$src = $PSScriptRoot

Info "Zrodla:  $src"
Info "Wynik:   $Output"
Info "Wersja:  $Version"
Info 'Start budowania - to potrwa 30-90 minut...'

$envArgs = @('--env', "VERSION=$Version", '--env', "LIVE_HOSTNAME=$HostName", '--env', 'SRC_DIR=/hackbox')
if ($KaliRef) { $envArgs += @('--env', "KALI_LB_REF=$KaliRef") }

$inner = "tr -d '\r' < /hackbox/build.sh > /tmp/hackbox-build.sh && exec bash /tmp/hackbox-build.sh --native --work-dir /work --output /out"

& docker pull $image
if ($LASTEXITCODE -ne 0) { throw 'Nie udalo sie pobrac obrazu kalilinux/kali-rolling.' }

& docker run --rm --privileged `
    --volume "${src}:/hackbox:ro" `
    --volume "${volume}:/work" `
    --volume "${Output}:/out" `
    @envArgs `
    $image bash -c $inner

if ($LASTEXITCODE -ne 0) {
    throw "Budowanie nie powiodlo sie (kod $LASTEXITCODE). Log: $Output\*.log"
}

Info "Gotowe! Plik ISO jest w: $Output"
Get-ChildItem $Output -Filter 'hackbox-thm-*.iso' | Format-Table Name, @{n = 'GB'; e = { [math]::Round($_.Length / 1GB, 2) } }
Info 'Miejsce zajmuje jeszcze wolumen roboczy. Usuniesz go poleceniem: docker volume rm hackbox-work'
