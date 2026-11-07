[CmdletBinding()]
param(
    [string]$Output = (Join-Path $PSScriptRoot 'output'),
    [string]$Version = (Get-Date -Format 'yyyy.MM.dd'),
    [string]$HostName = 'mrross',
    [string]$KaliRef = '',
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
$image = 'docker.io/kalilinux/kali-rolling:latest'
$volume = 'mrross-work'

function Info($msg) { Write-Host "[MrRoss OS] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[MrRoss OS] $msg" -ForegroundColor Yellow }

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

$envArgs = @('--env', "VERSION=$Version", '--env', "LIVE_HOSTNAME=$HostName", '--env', 'SRC_DIR=/mrross')
if ($KaliRef) { $envArgs += @('--env', "KALI_LB_REF=$KaliRef") }

$inner = "tr -d '\r' < /mrross/build.sh > /tmp/mrross-build.sh && exec bash /tmp/mrross-build.sh --native --work-dir /work --output /out"

& docker pull $image
if ($LASTEXITCODE -ne 0) { throw 'Nie udalo sie pobrac obrazu kalilinux/kali-rolling.' }

& docker run --rm --privileged `
    --volume "${src}:/mrross:ro" `
    --volume "${volume}:/work" `
    --volume "${Output}:/out" `
    @envArgs `
    $image bash -c $inner

if ($LASTEXITCODE -ne 0) {
    throw "Budowanie nie powiodlo sie (kod $LASTEXITCODE). Log: $Output\*.log"
}

Info "Gotowe! Plik ISO jest w: $Output"
Get-ChildItem $Output -Filter 'mrross-os-*.iso' | Format-Table Name, @{n = 'GB'; e = { [math]::Round($_.Length / 1GB, 2) } }
Info 'Miejsce zajmuje jeszcze wolumen roboczy. Usuniesz go poleceniem: docker volume rm mrross-work'
