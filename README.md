# MrRoss OS – system do nauki na TryHackMe

MrRoss OS to własna dystrybucja Linuksa do nauki na [TryHackMe](https://tryhackme.com),
zbudowana na bazie **Kali Linux** w taki sam sposób, jak Parrot HTB powstał z Parrota:
ta sama sprawdzona baza i narzędzia, ale z własną nazwą, wyglądem i dodatkami pod jedną platformę.
Uruchamiasz go w maszynie wirtualnej albo z pendrive'a, łączysz się z VPN jednym kliknięciem
i masz porządek w notatkach z każdego pokoju.

**Gotowe ISO do pobrania:** zakładka [Releases](https://github.com/MrRoss-Team/MrRoss-SYSTEM/releases)
(pobierz wszystkie pliki `.part*`, `.sha256` i `join-iso.ps1`, potem uruchom `.\join-iso.ps1`).

> Projekt niezależny – nie jest powiązany z TryHackMe ani z OffSec (Kali Linux).
> MrRoss OS jest następcą HackBoxa.

## Co jest w środku

| Element | Opis |
|---|---|
| Baza | Kali Linux (rolling): pakiety, aktualizacje i narzędzia z repozytorium Kali; pulpit Xfce, tryb live + instalator |
| Wygląd | własne logo, menu startowe (BIOS i UEFI), ekran ładowania, ekran logowania, tapeta, motyw `MrRoss-Dark`, ikony `MrRoss`, kolory terminala |
| Tożsamość | `/etc/os-release` = MrRoss OS, nazwa hosta `mrross`, użytkownik live `mrross`, etykieta płyty `MrRoss OS` |
| Narzędzia | `kali-tools-top10` + narzędzia używane w pokojach THM (lista: [`kali.list.chroot`](config/variant-mrross/package-lists/kali.list.chroot)) |
| VPN jednym kliknięciem | ikona **VPN TryHackMe** na pulpicie albo `thm vpn` – sama znajduje najnowszy plik `.ovpn` |
| Panel | u góry ekranu: Twoje IP w VPN i IP maszyny (`10.8.0.5 → 10.10.1.2`), klik = kopiuj; gdy VPN jest wyłączony – klik = połącz |
| Terminal | prompt MrRoss z IP VPN i celu, zmienne `$TARGET`, `$IP`, `$VPN_IP`; `fastfetch` pokazuje logo i dane systemu |
| Pokoje | `thm room <nazwa> <IP>` tworzy `~/thm/rooms/<nazwa>/` z szablonem `notes.md` i ustawia cel |
| Firefox | strona startowa TryHackMe + zakładki (THM, CyberChef, GTFOBins, RevShells, HackTricks, ExplainShell, OWASP) |

Logowanie w trybie live: **mrross / mrross**.

## Budowanie ISO

Budowanie pobiera ok. 3 GB pakietów i potrzebuje **ok. 30 GB wolnego miejsca**
oraz 30–90 minut. Wynik to plik `mrross-os-<wersja>-amd64.iso` (ok. 4 GB).

### Opcja A: GitHub Actions (nie zajmuje miejsca na Twoim dysku) – zalecana

1. Wypchnij zmiany do repozytorium na GitHubie. Budowanie startuje samo po każdej zmianie
   w `config/` lub `build.sh` (albo ręcznie: **Actions → Zbuduj ISO MrRoss OS → Run workflow**).
2. Po ok. 30 minutach wejdź w zakładkę **Releases** i pobierz do jednego folderu wszystkie pliki
   `.iso.part00`, `.part01`…, plik `.sha256` i `join-iso.ps1`.
   GitHub nie przyjmuje plików powyżej 2 GB, dlatego ISO jest pocięte.
3. Sklej części w PowerShellu:
   ```powershell
   .\join-iso.ps1
   ```
   Skrypt sprawdza też sumę SHA256. Skleja części w miejscu (bez kopiowania), więc oprócz pobranych
   plików potrzebuje tylko ~2 GB wolnego miejsca; części usuwa po dopisaniu (zachowasz je opcją `-KeepParts`).
   Przerwane sklejanie wystarczy uruchomić ponownie – skrypt je wznowi.

Wersja z numerem: wypchnij tag, np. `git tag v2.0 && git push --tags`.

### Opcja B: Windows + Docker Desktop

1. Zainstaluj i uruchom [Docker Desktop](https://www.docker.com/products/docker-desktop/) (backend WSL2).
2. Upewnij się, że dysk z danymi Dockera ma ~30 GB wolnego miejsca
   (Docker Desktop → Settings → Resources → *Disk image location* pozwala przenieść dane na inny dysk).
3. W PowerShellu w tym folderze:
   ```powershell
   .\build.ps1
   ```
   Gotowe ISO trafi do `output\`. Inny katalog: `.\build.ps1 -Output D:\iso`.
   Po budowaniu możesz odzyskać miejsce: `docker volume rm mrross-work`.

> Uwaga: jeśli ten folder leży na OneDrive, ISO w `output\` zacznie się synchronizować z chmurą.
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
[balenaEtcher](https://etcher.balena.io). Pendrive z trwałym zapisem (persistence) przygotowuje się
tak samo jak dla Kali: [instrukcja](https://www.kali.org/docs/usb/usb-persistence/).

## Praca z TryHackMe

```bash
thm vpn                         # połącz (plik .ovpn z tryhackme.com/access)
thm room nazwa-pokoju 10.10.x.x # folder pokoju + notatki + cel
thm status                      # VPN, cel, pokój
thm target 10.10.y.y nazwa.thm  # nowy IP maszyny (np. po restarcie) + wpis w /etc/hosts
thm ip                          # Twoje IP w VPN (gdy zadanie o nie pyta)
thm vpn stop                    # rozłącz
thm extras seclists             # doinstaluj większe pakiety
fastfetch                       # logo i informacje o systemie
thm help                        # ściąga
```

Prompt w terminalu wygląda tak:

```
┌──[10.8.0.5→10.10.1.2]─[mrross@mrross]─[~/thm/rooms/nazwa-pokoju]
└─$
```

## Dostosowanie

- **Inne pakiety** – edytuj [`config/variant-mrross/package-lists/kali.list.chroot`](config/variant-mrross/package-lists/kali.list.chroot)
  (nazwy z [kali.org/tools](https://www.kali.org/tools/)). Pełny zestaw narzędzi Kali: dopisz `kali-linux-default`.
- **Grafika** – źródła SVG (logo, tapeta, menu startowe, ekran ładowania) są w
  [`includes.chroot/usr/share/mrross/branding/`](config/variant-mrross/includes.chroot/usr/share/mrross/branding).
  Pliki PNG powstają z nich automatycznie podczas budowania.
- **Pliki w systemie** – wszystko w `config/variant-mrross/includes.chroot/` trafia 1:1 do obrazu.
- **Menu startowe** – `config/variant-mrross/bootloaders/` (GRUB dla UEFI, isolinux dla BIOS).
- **Konfiguracja przy budowaniu** – [`hooks/live/0100-mrross.chroot`](config/variant-mrross/hooks/live/0100-mrross.chroot).
- **Nowsze skrypty Kali** – `./build.sh --kali-ref latest` (domyślnie przypięty sprawdzony commit).

## Struktura projektu

```
build.sh                     budowanie (Linux / GitHub Actions / w kontenerze)
build.ps1                    budowanie na Windows (Docker Desktop)
join-iso.ps1                 sklejanie części ISO z GitHuba
.github/workflows/           automatyczne budowanie w GitHub Actions
config/variant-mrross/
  package-lists/             lista pakietów
  bootloaders/               menu startowe GRUB (UEFI) i isolinux (BIOS)
  includes.binary/           pliki na płycie (wygląd menu BIOS)
  hooks/live/                nadawanie tożsamości MrRoss w trakcie budowania
  includes.chroot/           pliki kopiowane do systemu:
    usr/local/bin/thm          polecenie thm
    usr/local/bin/thm-panel    wskaźnik VPN/celu w panelu
    etc/thm/                   integracja z zsh/bash (prompt MrRoss)
    usr/share/mrross/          grafika, logo fastfetch, szablon notatek, zakładki Firefoksa
    usr/share/plymouth/        ekran ładowania
    usr/lib/live/config/       konto live mrross
```

Motyw `MrRoss-Dark` powstaje z motywu Kali-Red-Dark, a ikony `MrRoss` dziedziczą po Flat Remix.
Oba projekty są na licencji GPL.
