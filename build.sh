#!/usr/bin/env bash
#
# HackBox – budowanie obrazu ISO (Kali Linux + dodatki do nauki na TryHackMe)
#
#   ./build.sh                 # buduje w kontenerze Dockera (zalecane, Linux/GitHub Actions)
#   sudo ./build.sh --native   # buduje bezpośrednio na hoście (tylko Kali Linux)
#   ./build.sh --help
#
# Na Windows użyj build.ps1 (Docker Desktop).
#
# Jak to działa:
#   1. pobiera oficjalne skrypty budowania Kali (live-build-config) w przypiętej wersji,
#   2. dokłada wariant "tryhackme" z katalogu config/variant-tryhackme,
#   3. uruchamia oficjalny build.sh Kali dla tego wariantu,
#   4. kopiuje gotowe ISO do katalogu output/ jako hackbox-thm-<wersja>-amd64.iso.
#
set -Eeuo pipefail

HERE="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SRC_DIR="${SRC_DIR:-$HERE}"

KALI_LB_REPO="${KALI_LB_REPO:-https://gitlab.com/kalilinux/build-scripts/live-build-config.git}"
# Commit sprawdzony podczas tworzenia projektu. "latest" = najnowsza wersja z gałęzi głównej.
KALI_LB_REF="${KALI_LB_REF:-adb2e38941662f105b57134e0155ec468da294ad}"

VARIANT="tryhackme"
LIVE_HOSTNAME="${LIVE_HOSTNAME:-hackbox}"
VERSION="${VERSION:-$( date -u +%Y.%m.%d )}"
OUT_DIR="${OUT_DIR:-$SRC_DIR/output}"
WORK_DIR="${WORK_DIR:-}"
BUILDER_IMAGE="${BUILDER_IMAGE:-docker.io/kalilinux/kali-rolling:latest}"
MODE="docker"

# ---------------------------------------------------------------------------

if [ -t 1 ]; then
  C_G=$'\e[32m' C_Y=$'\e[33m' C_R=$'\e[31m' C_B=$'\e[1m' C_N=$'\e[0m'
else
  C_G='' C_Y='' C_R='' C_B='' C_N=''
fi
info() { printf '%s[HackBox]%s %s\n' "$C_G" "$C_N" "$*"; }
warn() { printf '%s[HackBox]%s %s\n' "$C_Y" "$C_N" "$*" >&2; }
die()  { printf '%s[HackBox] BŁĄD:%s %s\n' "$C_R" "$C_N" "$*" >&2; exit 1; }

usage() {
  cat <<EOF
Użycie: $0 [opcje]

Buduje obraz ISO HackBox (Kali Linux dla TryHackMe).

Opcje:
  -o, --output DIR      katalog na gotowe ISO (domyślnie: ./output)
  -w, --work-dir DIR    katalog roboczy budowania (domyślnie: wolumen Dockera
                        "hackbox-work"; w trybie --native: ./.work)
  -x, --version VER     wersja w nazwie pliku (domyślnie: dzisiejsza data)
  -H, --hostname NAME   nazwa hosta systemu live (domyślnie: hackbox)
      --kali-ref REF    commit skryptów Kali albo "latest"
      --native          buduj bez Dockera (wymaga Kali Linux i roota)
  -h, --help            ta pomoc

Potrzebne: ok. 30 GB wolnego miejsca, 4 GB RAM, szybki internet (pobiera ~3 GB).
EOF
}

need_arg() { [ -n "${2:-}" ] || die "Opcja $1 wymaga wartości."; }

while [ $# -gt 0 ]; do
  case "$1" in
    -o|--output)   need_arg "$1" "${2:-}"; OUT_DIR="$2"; shift ;;
    -w|--work-dir) need_arg "$1" "${2:-}"; WORK_DIR="$2"; shift ;;
    -x|--version)  need_arg "$1" "${2:-}"; VERSION="$2"; shift ;;
    -H|--hostname) need_arg "$1" "${2:-}"; LIVE_HOSTNAME="$2"; shift ;;
    --kali-ref)    need_arg "$1" "${2:-}"; KALI_LB_REF="$2"; shift ;;
    --native)      MODE="native" ;;
    -h|--help)     usage; exit 0 ;;
    *)             usage >&2; die "Nieznana opcja: $1" ;;
  esac
  shift
done

[[ "$VERSION" =~ ^[A-Za-z0-9._-]+$ ]] || die "Wersja może zawierać tylko litery, cyfry, '.', '_' i '-'."
[[ "$LIVE_HOSTNAME" =~ ^[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?$ ]] || die "Niepoprawna nazwa hosta: $LIVE_HOSTNAME"
[ -d "$SRC_DIR/config/variant-$VARIANT" ] || die "Brak katalogu $SRC_DIR/config/variant-$VARIANT"

# ---------------------------------------------------------------------------
# Tryb Docker: uruchamia ten sam skrypt w kontenerze Kali z opcją --native
# ---------------------------------------------------------------------------

run_docker() {
  case "$( uname -s )" in
    MINGW*|MSYS*|CYGWIN*) die "Na Windows uruchom build.ps1 w PowerShellu (wymaga Docker Desktop)." ;;
  esac
  command -v docker >/dev/null 2>&1 || die "Nie znaleziono dockera. Zainstaluj Docker albo użyj --native na Kali."

  local docker=(docker)
  if ! docker info >/dev/null 2>&1; then
    if [ "$( id -u )" -ne 0 ] && command -v sudo >/dev/null 2>&1; then
      docker=(sudo docker)
    else
      die "Docker nie działa (docker info zwraca błąd)."
    fi
  fi

  mkdir -p "$OUT_DIR"
  OUT_DIR="$( cd "$OUT_DIR" && pwd )"

  # Katalog roboczy: nazwany wolumen Dockera albo ścieżka bezwzględna
  local work="${WORK_DIR:-hackbox-work}"
  if [[ "$work" == */* ]]; then
    mkdir -p "$work"
    work="$( cd "$work" && pwd )"
  fi

  info "Obraz budujący: $BUILDER_IMAGE"
  info "Katalog roboczy: $work"
  info "Wynik: $OUT_DIR"
  "${docker[@]}" pull "$BUILDER_IMAGE"

  # --privileged: live-build montuje /proc, /sys, /dev i używa chroot
  "${docker[@]}" run --rm --privileged \
    --volume "$SRC_DIR:/hackbox:ro" \
    --volume "$work:/work" \
    --volume "$OUT_DIR:/out" \
    --env SRC_DIR=/hackbox \
    --env VERSION="$VERSION" \
    --env LIVE_HOSTNAME="$LIVE_HOSTNAME" \
    --env KALI_LB_REPO="$KALI_LB_REPO" \
    --env KALI_LB_REF="$KALI_LB_REF" \
    --env HOST_UID="${SUDO_UID:-$( id -u )}" \
    --env HOST_GID="${SUDO_GID:-$( id -g )}" \
    "$BUILDER_IMAGE" \
    bash -c "tr -d '\r' < /hackbox/build.sh > /tmp/hackbox-build.sh && exec bash /tmp/hackbox-build.sh --native --work-dir /work --output /out"
}

# ---------------------------------------------------------------------------
# Tryb natywny: właściwe budowanie (w kontenerze albo na Kali)
# ---------------------------------------------------------------------------

safe_umount() {
  # Odmontuj wszystko, co zostało pod katalogiem roboczym po przerwanym budowaniu
  local base="$1" m
  [ -d "$base" ] || return 0
  awk -v b="$base/" 'index($2, b) == 1 { print $2 }' /proc/mounts | sort -r | while read -r m; do
    umount -lf "$m" 2>/dev/null || true
  done
}

install_deps() {
  if command -v lb >/dev/null 2>&1 && command -v git >/dev/null 2>&1 && command -v wget >/dev/null 2>&1; then
    return 0
  fi
  grep -qi '^ID=kali' /etc/os-release 2>/dev/null \
    || warn "To nie jest Kali – skrypty Kali wymagają live-build z repozytorium Kali. Najprościej użyć trybu Docker."
  info "Instaluję narzędzia do budowania (live-build, git)..."
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends \
    apt-utils ca-certificates git live-build wget xz-utils
}

fetch_kali_config() {
  local dst="$1"
  if [ -d "$dst/.git" ]; then
    if [ "$KALI_LB_REF" = "latest" ]; then
      info "Aktualizuję skrypty Kali (latest)..."
      git -C "$dst" fetch -q origin
      git -C "$dst" reset -q --hard origin/HEAD
      return 0
    elif [ "$( git -C "$dst" rev-parse HEAD 2>/dev/null )" = "$KALI_LB_REF" ]; then
      info "Skrypty Kali już pobrane ($KALI_LB_REF)."
      git -C "$dst" checkout -q -- .
      return 0
    fi
  fi
  info "Pobieram skrypty budowania Kali..."
  rm -rf --one-file-system "$dst"
  git clone -q "$KALI_LB_REPO" "$dst"
  if [ "$KALI_LB_REF" != "latest" ]; then
    git -C "$dst" checkout -q "$KALI_LB_REF"
  fi
}

apply_overlay() {
  local dst="$1" v
  v="$dst/kali-config/variant-$VARIANT"
  info "Dodaję wariant '$VARIANT'..."
  rm -rf "$v"
  mkdir -p "$v"
  cp -R "$SRC_DIR/config/variant-$VARIANT/." "$v/"

  # Pliki mogły przejść przez Windows – usuń końce linii CRLF z plików tekstowych
  grep -rIl $'\r' "$v" 2>/dev/null | while IFS= read -r f; do sed -i 's/\r$//' "$f"; done

  # Właściciel i uprawnienia (live-build kopiuje je 1:1 do systemu)
  chown -R root:root "$v"
  find "$v" -type d -exec chmod 0755 {} +
  find "$v" -type f -exec chmod 0644 {} +
  [ -d "$v/hooks" ] && find "$v/hooks" -type f -exec chmod 0755 {} +
  [ -d "$v/includes.chroot/usr/local/bin" ] && find "$v/includes.chroot/usr/local/bin" -type f -exec chmod 0755 {} +
  return 0
}

run_native() {
  [ "$( id -u )" -eq 0 ] || die "Tryb --native wymaga uprawnień roota (sudo)."
  WORK_DIR="${WORK_DIR:-$SRC_DIR/.work}"
  mkdir -p "$WORK_DIR" "$OUT_DIR"
  WORK_DIR="$( cd "$WORK_DIR" && pwd )"
  OUT_DIR="$( cd "$OUT_DIR" && pwd )"

  local kali="$WORK_DIR/kali-live" kout="$WORK_DIR/out"

  safe_umount "$WORK_DIR"
  install_deps
  fetch_kali_config "$kali"
  apply_overlay "$kali"

  rm -rf "$kout"
  mkdir -p "$kout"

  info "Start budowania (to potrwa 30–90 minut)..."
  ( cd "$kali" && ./build.sh \
      --variant "$VARIANT" \
      --hostname "$LIVE_HOSTNAME" \
      --version "$VERSION" \
      --output "$kout" )

  local iso name
  iso="$( find "$kout" -maxdepth 1 -type f -name '*.iso' | head -n 1 )"
  [ -n "$iso" ] || die "Budowanie zakończone, ale nie znaleziono pliku ISO w $kout"
  name="hackbox-thm-${VERSION}-amd64.iso"

  info "Kopiuję ISO do $OUT_DIR/$name ..."
  cp -f "$iso" "$OUT_DIR/$name"
  [ -f "$iso.log" ] && cp -f "$iso.log" "$OUT_DIR/$name.log"
  ( cd "$OUT_DIR" && sha256sum "$name" > "$name.sha256" )
  rm -f "$iso"

  if [ -n "${HOST_UID:-}" ] && [ -n "${HOST_GID:-}" ]; then
    chown "$HOST_UID:$HOST_GID" "$OUT_DIR/$name"* 2>/dev/null || true
  fi

  info "${C_B}Gotowe:${C_N} $OUT_DIR/$name ($( du -h "$OUT_DIR/$name" | cut -f1 ))"
  info "SHA256: $( cut -d' ' -f1 "$OUT_DIR/$name.sha256" )"
}

case "$MODE" in
  docker) run_docker ;;
  native) run_native ;;
esac
