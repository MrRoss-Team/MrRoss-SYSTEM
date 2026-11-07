# HackBox – system do nauki na TryHackMe

HackBox to obraz ISO oparty na **Kali Linux** (oficjalne skrypty budowania Kali),
przygotowany pod naukę na [TryHackMe](https://tryhackme.com). Uruchamiasz go
w maszynie wirtualnej albo z pendrive'a, łączysz się z VPN jednym kliknięciem
i masz porządek w notatkach z każdego pokoju.

> Projekt nieoficjalny – nie jest powiązany z TryHackMe ani z OffSec (Kali Linux).

## Co jest w środku

| Element | Opis |
|---|---|
| Baza | Kali Linux (rolling), pulpit Xfce, tryb live + instalator |
| Narzędzia | `kali-tools-top10` + narzędzia używane w pokojach THM (lista: [`kali.list.chroot`](config/variant-tryhackme/package-lists/kali.list.chroot)) |
| VPN jednym kliknięciem | ikona **VPN TryHackMe** na pulpicie albo `thm vpn` – sama znajduje najnowszy plik `.ovpn` |
| Panel | u góry ekranu: Twoje IP w VPN i IP maszyny (`10.8.0.5 → 10.10.1.2`), klik = kopiuj; gdy VPN jest wyłączony – klik = połącz |
| Terminal | prompt pokazuje IP VPN i celu, zmienne `$TARGET`, `$IP`, `$VPN_IP` |
| Pokoje | `thm room <nazwa> <IP>` tworzy `~/thm/rooms/<nazwa>/` z szablonem `notes.md` i ustawia cel |
| Firefox | strona startowa TryHackMe + pasek zakładek (THM, CyberChef, ExplainShell, Kali Docs, OWASP) |
| Wygląd | własna tapeta, nazwa hosta `hackbox` |

Logowanie w trybie live: **kali / kali**.

## Budowanie ISO

Budowanie pobiera ok. 3 GB pakietów i potrzebuje **ok. 30 GB wolnego miejsca**
oraz 30–90 minut. Wynik to plik `hackbox-thm-<wersja>-amd64.iso` (ok. 3–4 GB).

### Opcja A: GitHub Actions (nie zajmuje miejsca na Twoim dysku) – zalecana

1. Utwórz na GitHubie nowe repozytorium (może być prywatne) i wyślij do niego ten folder:
   ```bash
   git init && git add . && git commit -m "HackBox"
   ```
   ```bash
   git branch -M main && git remote add origin https://github.com/<login>/hackbox.git && git push -u origin main
   ```
2. Budowanie startuje samo po wypchnięciu (albo ręcznie: **Actions → Zbuduj ISO HackBox → Run workflow**).
   Kolejne budowania uruchamiają się po każdej zmianie w `config/` lub `build.sh`.
3. Po ok. godzinie wejdź w zakładkę **Releases** i pobierz do jednego folderu wszystkie pliki
   `.iso.part00`, `.part01`…, plik `.sha256` i `join-iso.ps1`.
   GitHub nie przyjmuje plików powyżej 2 GB, dlatego ISO jest pocięte.
4. Sklej części w PowerShellu:
   ```powershell
   .\join-iso.ps1
   ```
   Skrypt sprawdza też sumę SHA256.

Wersja z numerem: wypchnij tag, np. `git tag v1.0 && git push --tags`.
W repozytorium publicznym minuty Actions są bez limitu, w prywatnym darmowe konto ma 2000 minut miesięcznie (jedno budowanie to ok. 60–90 minut).

### Opcja B: Windows + Docker Desktop

1. Zainstaluj i uruchom [Docker Desktop](https://www.docker.com/products/docker-desktop/) (backend WSL2).
2. Upewnij się, że dysk z danymi Dockera ma ~30 GB wolnego miejsca
   (Docker Desktop → Settings → Resources → *Disk image location* pozwala przenieść dane na inny dysk).
3. W PowerShellu w tym folderze:
   ```powershell
   .\build.ps1
   ```
   Gotowe ISO trafi do `output\`. Inny katalog: `.\build.ps1 -Output D:\iso`.
   Po budowaniu możesz odzyskać miejsce: `docker volume rm hackbox-work`.

> Uwaga: ten folder leży na OneDrive – ISO w `output\` zacznie się synchronizować z chmurą.
> Lepiej podać `-Output` poza OneDrive.

### Opcja C: Linux

```bash
./build.sh
```

Buduje w kontenerze `kalilinux/kali-rolling` (potrzebny Docker). Na samym Kali można
też bez Dockera: `sudo ./build.sh --native`. Wszystkie opcje: `./build.sh --help`.

## Uruchomienie

**VirtualBox / VMware:** nowa maszyna *Linux → Debian (64-bit)*, min. **4 GB RAM**, 2 CPU,
podłącz ISO jako napęd optyczny i uruchom → *Live system*. Żeby zachować zmiany na stałe,
wybierz w menu startowym *Start installer* i zainstaluj system na dysku wirtualnym (min. 30 GB).

**Pendrive:** zapisz ISO np. programem [Rufus](https://rufus.ie) (tryb *DD Image*) albo
[balenaEtcher](https://etcher.balena.io). Pendrive z trwałym zapisem (persistence):
[instrukcja Kali](https://www.kali.org/docs/usb/usb-persistence/).

## Praca z TryHackMe

```bash
thm vpn                         # połącz (plik .ovpn z tryhackme.com/access)
thm room nazwa-pokoju 10.10.x.x # folder pokoju + notatki + cel
thm status                      # VPN, cel, pokój
thm target 10.10.y.y nazwa.thm  # nowy IP maszyny (np. po restarcie) + wpis w /etc/hosts
thm ip                          # Twoje IP w VPN (gdy zadanie o nie pyta)
thm vpn stop                    # rozłącz
thm extras seclists             # doinstaluj większe pakiety
thm help                        # ściąga
```

Prompt w terminalu wygląda tak:

```
┌──(10.8.0.5→10.10.1.2)─(kali㉿hackbox)-[~/thm/rooms/nazwa-pokoju]
└─$
```

## Dostosowanie

- **Inne pakiety** – edytuj [`config/variant-tryhackme/package-lists/kali.list.chroot`](config/variant-tryhackme/package-lists/kali.list.chroot)
  (nazwy z [kali.org/tools](https://www.kali.org/tools/)). Pełny zestaw narzędzi Kali: dopisz `kali-linux-default`.
- **Pliki w systemie** – wszystko w `config/variant-tryhackme/includes.chroot/` trafia 1:1 do obrazu.
- **Konfiguracja przy budowaniu** – [`hooks/live/hackbox.chroot`](config/variant-tryhackme/hooks/live/hackbox.chroot).
- **Nowsze skrypty Kali** – `./build.sh --kali-ref latest` (domyślnie przypięty sprawdzony commit).

## Struktura projektu

```
build.sh                     budowanie (Linux / GitHub Actions / w kontenerze)
build.ps1                    budowanie na Windows (Docker Desktop)
join-iso.ps1                 sklejanie części ISO z GitHuba
.github/workflows/           automatyczne budowanie w GitHub Actions
config/variant-tryhackme/
  package-lists/             lista pakietów
  hooks/live/                konfiguracja w trakcie budowania
  includes.chroot/           pliki kopiowane do systemu:
    usr/local/bin/thm          polecenie thm
    usr/local/bin/thm-panel    wskaźnik VPN/celu w panelu
    etc/thm/                   integracja z zsh/bash
    usr/share/hackbox/         szablon notatek, zakładki Firefoksa
```
