<div align="center">

**🚧 STATUS: GERÜST v0.1.0 — noch nicht auf Produktivsystemen einsetzen**

# 🛡️ COOLIFY-SHIELD

**Härtet deinen Coolify-Server ab — ohne dass du dich dabei aussperrst.**

[![Lizenz: MIT](https://img.shields.io/badge/Lizenz-MIT-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Ger%C3%BCst%20v0.1.0-orange.svg)](#-status)
[![shellcheck](https://github.com/oliverhees/coolify-shield/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/oliverhees/coolify-shield/actions/workflows/shellcheck.yml)
[![Stack](https://img.shields.io/badge/Stack-Bash%20%2B%20systemd%20%2B%20wg--easy-informational.svg)](#-architektur)
[![DSGVO](https://img.shields.io/badge/VPN-selbst%20gehostet%2C%20kein%20Drittanbieter-black.svg)](#warum-wg-easy-und-nicht-tailscale)
[![Community](https://img.shields.io/badge/Community-AIIANER-black.svg)](https://aiianer.de)

*Ein Befehl. Trockenlauf als Standard. Vor jedem riskanten Schritt ein Rückfall-Timer, der alles von selbst zurückrollt, wenn du nicht mehr reinkommst.*

[**Für Anfänger: hier starten**](ANFAENGER.md) · [Quickstart](#-quickstart) · [Sicherheitsnetz](#️-das-sicherheitsnetz) · [Architektur](#-architektur) · [Ich bin ausgesperrt](NOTFALL.md) · [Entstehung](docs/ENTSTEHUNG.md) · [Lizenz](#-lizenz)

</div>

---

## Inhaltsverzeichnis

- [👉 Noch nie einen Server verwaltet? → ANFAENGER.md](ANFAENGER.md)
- [Warum coolify-shield](#warum-coolify-shield)
- [Was uns unterscheidet](#-was-uns-unterscheidet)
- [Features](#-features)
- [Quickstart](#-quickstart)
- [Befehle](#-befehle)
- [Das Sicherheitsnetz](#️-das-sicherheitsnetz)
  - [Trockenlauf als Standard](#1-trockenlauf-als-standard)
  - [Rückfall-Timer (Watchdog)](#2-rückfall-timer-watchdog)
  - [Preflight-Gate](#3-preflight-gate)
  - [Backups und `--undo`](#4-backups-und---undo)
  - [Idempotenz](#5-idempotenz)
- [Architektur](#-architektur)
- [Ablauf der Phasen](#-ablauf-der-phasen)
- [Was das Script bewusst nicht kann](#-was-das-script-bewusst-nicht-kann)
- [Warum wg-easy und nicht Tailscale](#warum-wg-easy-und-nicht-tailscale)
- [Unterstützte Systeme](#-unterstützte-systeme)
- [Ehrliche Einordnung (bitte lesen)](#️-ehrliche-einordnung-bitte-lesen)
- [Ich habe mich ausgesperrt](#-ich-habe-mich-ausgesperrt)
- [Status](#-status)
- [Roadmap](#️-roadmap)
- [Der Kurs dazu](#-der-kurs-dazu)
- [Mitmachen](#-mitmachen)
- [Das AIIANER-Universum](#-das-aiianer-universum)
- [Lizenz](#-lizenz)
- [Sicherheit](#-sicherheit)
- [Marken](#-marken)

---

## Warum coolify-shield

Wer sich in dein Coolify-Dashboard einloggt, hat **Root auf deinem Server** — im Dashboard steckt ein Terminal. Trotzdem hängen tausende Instanzen mit Passwortlogin und offenen Ports 8000/6001/6002 direkt im Netz.

Die Anleitungen dafür gibt es längst. Das eigentliche Problem ist die **Reihenfolge**: Firewall zu, bevor der SSH-Key läuft — und du stehst vor deinem eigenen Server. Die häufigste Coolify-Katastrophe ist nicht der Hacker, sondern der Admin, der sich selbst ausgesperrt hat.

coolify-shield ist ein Bash-Wizard, der genau das verhindert. Er ist für Leute gebaut, die **keine** Linux-Admins sind: Er fragt im Klartext, die sicherste Antwort ist der Default, Enter drücken reicht. Und bevor er irgendetwas Riskantes tut, macht er einen Timer scharf, der die Änderung von selbst zurücknimmt, falls du nicht bestätigst, dass du noch reinkommst.

## 🏆 Was uns unterscheidet

| | Manuelle Anleitung / Blogpost | Klassisches Hardening-Script | coolify-shield |
| --- | --- | --- | --- |
| **Aussperr-Schutz** | ❌ „Zweites Terminal offen lassen" als Fußnote | ❌ Meist keiner — läuft durch und hofft | ✅ [Rückfall-Timer](#2-rückfall-timer-watchdog) vor jedem riskanten Schritt, rollt nach 10 Minuten automatisch zurück |
| **Erst zeigen, dann machen** | — | ❌ Ändert sofort | ✅ Trockenlauf ist der **Standard**, ohne `--apply` passiert nichts |
| **Coolify-spezifisch** | Unterschiedlich | ❌ Generisches SSH/ufw, kennt 8000/6001/6002 nicht | ✅ Coolify-Ports, Traefik-Dynamic-Config, Web-Terminal-Erkennung, Root-Login via `prohibit-password` (Coolify braucht Root-SSH zu sich selbst) |
| **Läuft im Coolify-Web-Terminal?** | — | ❌ Sperrt die eigene Sitzung aus | ✅ Preflight erkennt das und bricht ab |
| **Rückgängig machen** | ❌ Von Hand | ❌ Selten | ✅ Jede Datei wird vor Änderung mit Zeitstempel gesichert, `--undo` holt alles zurück |
| **Mehrfach ausführbar** | — | ❌ Oft nicht | ✅ Idempotent — erledigte Schritte werden übersprungen |
| **Mehr als Debian/Ubuntu** | Meist nur Ubuntu | Meist nur Ubuntu | ✅ Abstraktion für apt/dnf/zypper/pacman und ufw/firewalld |
| **VPN ohne Drittanbieter** | Meist Tailscale | Meist Tailscale | ✅ wg-easy auf dem eigenen Server, kein Auftragsverarbeitungsvertrag nötig |
| **Support-Fall** | „Was hast du gemacht?" | „Was hast du gemacht?" | ✅ `/var/log/coolify-shield.log` mit jedem Schritt und Zeitstempel + [NOTFALL.md](NOTFALL.md) pro Hoster |

## ✨ Features

- **Ein Befehl, keine Config-Datei.** Das Script fragt, statt zu erwarten. Kein Ansible, keine Control-Machine, kein Inventory.
- **Trockenlauf als Standard.** `sudo ./install.sh` zeigt nur an. Erst `--apply` ändert etwas.
- **Watchdog vor jedem riskanten Schritt.** SSH-Härtung, Firewall, VPN-Zwang — immer mit Rückfall-Timer (systemd-run, Fallback `at`).
- **Preflight-Gate.** Root, Distro-Tier, systemd, Watchdog-Fähigkeit, Docker, laufender Coolify-Container, SSH-Sitzung (nicht Web-Terminal), hinterlegte SSH-Keys, Internet, freier Speicher — alles geprüft, bevor eine Zeile geändert wird.
- **Bestandsaufnahme (`--audit`).** 9 Prüfpunkte, nur lesen: SSH-Passwortlogin, Root-Login, Firewall, Coolify-Ports öffentlich?, Brute-Force-Schutz, Auto-Updates, VPN — plus die drei Punkte, die nur du selbst prüfen kannst.
- **Backups + `--undo`.** Jede angefasste Datei landet mit Zeitstempel unter `/var/backups/coolify-shield/`.
- **Idempotent.** Zustand unter `/var/lib/coolify-shield/`, erledigte Phasen werden übersprungen.
- **Distro-Abstraktion.** Debian-Familie, RHEL-Familie, SUSE, Arch — Paketmanager und Firewall-Werkzeug werden erkannt, nie direkt `apt-get` in den Phasen.
- **HTML-Report mit Ampel und Score.** Grün/Gelb/Rot, plus Restliste der Dinge, die kein Script für dich klicken kann.
- **Kurs-Verweise.** Nach jeder Phase ein Hinweis, wo es im Kurs weitergeht (`--no-cues` blendet sie aus).
- **Ein klarer Satz statt Stacktrace.** Jeder Abbruch sagt, *was* fehlt und *was zu tun ist*.

## 🚀 Quickstart

> **Anfänger?** Lies zuerst [ANFAENGER.md](ANFAENGER.md) — dort wird jeder Schritt und jeder Begriff von Null erklärt.

```bash
# 1. Holen — und lesen. Es läuft als root.
git clone https://github.com/oliverhees/coolify-shield.git
cd coolify-shield
less install.sh

# 2. Rescue-Konsole deines Hosters in einem Browser-Tab öffnen (siehe NOTFALL.md)

# 3. Trockenlauf — es passiert nichts, du siehst nur, was passieren würde
sudo ./install.sh

# 4. Wenn es passt: wirklich ausführen
sudo ./install.sh --apply

# 5. ZWEITES Terminal öffnen, neu einloggen. Klappt es?
sudo ./install.sh --confirm
#    Klappt es nicht: nichts tun. Nach 10 Minuten rollt es sich selbst zurück.
```

> **Kein `curl | bash`.** Bei einem Sicherheitswerkzeug, das als root läuft, wäre das das falsche Signal. Lies es erst, dann führ es aus. Deshalb ist der Code öffentlich.

> **Nicht im Coolify-Web-Terminal ausführen.** Per SSH auf den Server. Das Preflight-Gate bricht sonst ab — mit Absicht, denn Firewall-Änderungen würden deine eigene Sitzung kappen.

## 🧭 Befehle

| Befehl | Was passiert |
| --- | --- |
| `sudo ./install.sh` | Trockenlauf — zeigt nur an (Standard) |
| `sudo ./install.sh --apply` | führt aus |
| `sudo ./install.sh --audit` | prüft und schreibt Report, ändert nichts |
| `sudo ./install.sh --confirm` | bestätigt: „ich komme noch rein" — entschärft alle Rückfall-Timer |
| `sudo ./install.sh --undo` | rollt alles zurück |
| `sudo ./install.sh --status` | Zustand, abgeschlossene Phasen, laufende Timer |
| `--phase <basics\|ssh\|firewall\|vpn>` | nur eine Phase |
| `--yes` | keine Rückfragen (nur für Wiederholungsläufe) |
| `--force` | auf ungetesteten Systemen trotzdem starten |
| `--no-cues` | Kurs-Verweise ausblenden |

## 🛡️ Das Sicherheitsnetz

Fünf Mechanismen, die zusammen dafür sorgen, dass ein Anfänger dieses Script laufen lassen kann, ohne sich den Server kaputtzumachen.

### 1. Trockenlauf als Standard

`DRY_RUN=1` ist der Ausgangszustand. Jeder ändernde Befehl läuft durch einen `run`-Wrapper, der im Trockenlauf nur `[trocken] <befehl>` ausgibt. Erst `--apply` setzt `DRY_RUN=0`.

### 2. Rückfall-Timer (Watchdog)

Das Herzstück — das Muster von `reload in 10` bei Cisco-Switches:

```
Änderung setzen  →  Timer scharf (10 min)  →  du testest im ZWEITEN Terminal
                                                 ├─ klappt  → --confirm entschärft den Timer
                                                 └─ klappt nicht → nichts tun, Timer rollt zurück
```

Umgesetzt mit `systemd-run --on-active`, Fallback auf `at`. Gibt es keinen von beiden, **wird nichts Riskantes geändert** — das Preflight-Gate bricht ab. Der Watchdog wird immer *vor* der Änderung scharf gemacht, nie danach.

### 3. Preflight-Gate

Phase 0 ändert nichts und bricht mit genau einem klaren Satz ab, wenn etwas fehlt:

| Prüfung | Bei Fehlschlag |
| --- | --- |
| Root-Rechte | Abbruch |
| Distro erkannt (Tier 1/2) | Tier 0 nur mit `--force` |
| Watchdog möglich (systemd-run oder `at`) | Abbruch — ohne Timer kein Risiko |
| Docker + laufender `coolify`-Container | Abbruch (`--force` überspringt) |
| Läuft in einer SSH-Sitzung (`$SSH_CONNECTION`) | **Abbruch** — du sitzt im Coolify-Web-Terminal |
| Mindestens ein SSH-Key hinterlegt | Warnung, SSH-Phase wird übersprungen |
| Internet, ≥ 1 GB frei | Warnung |
| Rescue-Konsole offen? (Rückfrage) | Abbruch — zu Recht |

### 4. Backups und `--undo`

`backup_file` sichert jede Datei vor der ersten Änderung nach `/var/backups/coolify-shield/<zeitstempel>_<pfad>`. `--undo` entschärft alle Timer und spielt die Backups zurück (Rückspielen ist im Gerüst noch Stub — die Backups selbst werden bereits angelegt).

### 5. Idempotenz

Jede abgeschlossene Phase schreibt einen Marker nach `/var/lib/coolify-shield/`. Beim nächsten Lauf: „übersprungen — läuft bereits". Wichtig, weil Coolify-Updates die Traefik-Config überschreiben können und das Script dann einfach nochmal laufen muss.

## 🧩 Architektur

```
coolify-shield/
├── install.sh              ← der eine Befehl: Argument-Parsing, Modi, Phasen-Reihenfolge
├── lib/
│   ├── 00-common.sh        Fundament: Logging, Fragen, run/Dry-Run, Backups,
│   │                       Zustand, Distro-Erkennung, pkg_install, WATCHDOG
│   ├── 00-preflight.sh     Phase 0 · Gate — darf das hier überhaupt laufen?
│   ├── 10-audit.sh         Phase 1 · Bestandsaufnahme, nur lesen
│   ├── 20-basics.sh        Phase A · risikofrei (Auto-Updates, CrowdSec, Traefik-Config vorbereiten)
│   ├── 30-ssh.sh           Phase B1 · SSH härten — mit Watchdog
│   ├── 40-firewall.sh      Phase B2 · ufw / firewalld — mit Watchdog
│   ├── 50-wireguard.sh     Phase B3 · wg-easy — mit Watchdog
│   └── 99-report.sh        Phase 9 · HTML-Report mit Score
├── ANFAENGER.md            ← für Einsteiger: alles von Null erklärt
├── NOTFALL.md              ← die wichtigste Datei im Repo
├── docs/ENTSTEHUNG.md      der Chat, aus dem das Projekt hervorging
└── .github/workflows/      shellcheck bei jedem Push
```

**Pfade auf dem Server:**

| Pfad | Inhalt |
| --- | --- |
| `/var/log/coolify-shield.log` | jeder Schritt mit Zeitstempel — im Supportfall: „schick mir die Datei" |
| `/var/lib/coolify-shield/` | Zustand (erledigte Phasen, aktive Watchdogs) |
| `/var/backups/coolify-shield/` | Sicherungen geänderter Dateien |
| `/root/coolify-shield-report.html` | der Report |
| `/data/coolify/proxy/dynamic/shield-*.yaml` | Traefik-Dynamic-Config (geplant) |

## 🔁 Ablauf der Phasen

| Phase | Modul | Risiko | Was passiert |
| --- | --- | --- | --- |
| **0 · Preflight** | `00-preflight.sh` | keins | prüft alles, ändert nichts, bricht ab wenn etwas fehlt |
| **1 · Bestandsaufnahme** | `10-audit.sh` | keins | 9 Prüfpunkte, nur lesen |
| **A · Grundlagen** | `20-basics.sh` | keins | automatische Sicherheitsupdates, CrowdSec/fail2ban, Traefik-Config *vorbereiten*, Logrotation — kann jeder blind laufen lassen |
| **B3 · VPN** | `50-wireguard.sh` | Watchdog | wg-easy als Container, erster Client mit QR-Code fürs Handy |
| **B1 · SSH** | `30-ssh.sh` | Watchdog | `PasswordAuthentication no`, `PermitRootLogin prohibit-password`, `sshd -t` vor `reload` |
| **B2 · Firewall** | `40-firewall.sh` | Watchdog | 22 nur aus VPN, 80/443 offen, 51820/udp offen, 8000/6001/6002 nur localhost+VPN |
| **9 · Report** | `99-report.sh` | keins | HTML mit Ampel, Score und Restliste |

**Die Reihenfolge ist nicht verhandelbar:** VPN läuft *vor* SSH und Firewall. Sonst macht die Firewall den Weg zu, bevor der VPN-Weg existiert — der klassische Aussperr-Fehler.

**Geplantes Zielbild der Firewall:**

| Port | Regel |
| --- | --- |
| 22/tcp | nur aus dem VPN-Subnetz (oder von deiner aktuellen SSH-IP, wenn kein VPN) |
| 80, 443/tcp | von überall — deine Apps + Let's Encrypt |
| 51820/udp | von überall — WireGuard-Einwahl |
| 8000, 6001, 6002/tcp | nur localhost + VPN-Subnetz |
| alles andere | zu |

## 🚫 Was das Script bewusst nicht kann

Drei Dinge stecken in Coolifys eigener Datenbank. Da schreibt ein fremdes Script nicht rein — an der DB eines fremden Servers herumzuschreiben ist bei einem Tool für Hunderte Nutzer ein No-Go:

- **Zwei-Faktor aktivieren** — Profil → Two-factor Authentication → Configure → QR scannen → Validate. Recovery-Codes in den Passwort-Manager, nicht auf den Server und nicht auf dasselbe Handy wie die Authenticator-App.
- **Registrierung abschalten** — Settings → Registration Allowed → aus.
- **Passwort tauschen** — 25+ Zeichen aus dem Manager. Behandle es wie dein Root-Passwort, denn das ist es faktisch.

Der Report listet diese Punkte am Ende als Restliste auf. Das sind 3 Minuten Klickarbeit — und sie killen zusammen mit Phase A schon rund 90 % der Bot-Angriffe.

## Warum wg-easy und nicht Tailscale

wg-easy läuft komplett auf deinem Server. Kein Drittanbieter in der Steuerungsebene, keine Daten bei einem US-Anbieter, kein Auftragsverarbeitungsvertrag nötig. Auf dem Handy: offizielle WireGuard-App, QR-Code scannen, ein Tap zum Verbinden.

Wer Tailscale bevorzugt, aber die Steuerungsebene selbst hosten will: **Headscale** — gleiche Clients, eigener Koordinationsserver. Cloudflare Access hat dasselbe Problem wie Tailscale (US-Anbieter, TLS-Terminierung bei Cloudflare) und fällt für DSGVO-sensible Setups ebenfalls raus.

**Und warum kein Forward-Auth (Authentik/Authelia) vor dem Dashboard?** Coolify generiert seine Traefik-Router selbst, Realtime/Terminal laufen über eigene Router (6001/6002), und beim nächsten Update kann die Anpassung überschrieben werden. Authentik ist großartig für deine *deployten Apps* — für das Dashboard selbst ist VPN der robustere Weg.

## 💻 Unterstützte Systeme

| Tier | Systeme | Verhalten |
| --- | --- | --- |
| **1 — getestet** | Ubuntu 22.04 / 24.04, Debian 12 / 13 | läuft |
| **2 — sollte laufen** | Raspberry Pi OS, Fedora, Rocky, Alma, openSUSE, Arch/Manjaro | läuft mit Warnung |
| **0 — unbekannt** | alles andere | nur mit `--force` |

| Familie | Paketmanager | Firewall |
| --- | --- | --- |
| Debian | `apt` | `ufw` |
| RHEL | `dnf` | `firewalld` |
| SUSE | `zypper` | `firewalld` |
| Arch | `pacman` | `ufw` |

Voraussetzung: systemd (für den Watchdog) — ohne systemd Fallback auf das Paket `at`. Arch bekommt bewusst **keine** automatischen Updates (Rolling Release).

## ⚠️ Ehrliche Einordnung (bitte lesen)

- **Das ist ein Gerüst.** Die Sicherheitsmechanik (Preflight, Watchdog, Backups, Dry-Run, Audit) funktioniert. Die eigentlichen Härtungsschritte in `20-basics`, `30-ssh`, `40-firewall`, `50-wireguard` und der volle Report sind **Stubs** mit der konkreten Umsetzung als TODO-Kommentar. Wer es heute auf einen Produktivserver loslässt, bekommt eine Bestandsaufnahme und Warnungen — aber noch keine Härtung.
- **Docker umgeht ufw.** Docker schreibt eigene iptables-Regeln. Die Host-Firewall schützt den Host, nicht zwangsläufig die von Containern veröffentlichten Ports. Für die Coolify-Ports greift deshalb zusätzlich die Traefik-Allowlist; eine Cloud-Firewall beim Hoster (Hetzner & Co.) bleibt trotzdem sinnvoll.
- **Die Traefik-Allowlist muss an *alle* Dashboard-Router**, auch Realtime/Terminal. Sonst ist die Loginseite dicht, aber das Terminal offen. Genau deshalb wird die Config in Phase A nur *vorbereitet* und erst nach bestätigtem VPN-Zugang scharf geschaltet.
- **Coolify-Updates können die Dynamic-Config überschreiben.** Darum ist das Script idempotent — nach einem Update einfach nochmal laufen lassen.
- **Bestehende SSH-Verbindungen laufen weiter**, auch wenn neue blockiert sind. Wer im *alten* Fenster testet und `--confirm` drückt, ist ausgesperrt. Immer in einem **neuen** Fenster testen — darauf fallen 80 % der Fälle rein.
- **Kein Ersatz für eine Sicherheitsberatung.** Das Script setzt bekannte Basismaßnahmen um. Es macht deinen Server nicht „unangreifbar".

## 🆘 Ich habe mich ausgesperrt

→ **[NOTFALL.md](NOTFALL.md)** — erst 12 Minuten warten (der Watchdog hat es meistens schon gelöst), dann Rescue-Konsole des Hosters: Hetzner Cloud/Robot, Netcup, Contabo, IONOS, Strato, DigitalOcean, Vultr, Linode, Scaleway sind beschrieben. Danach `--undo` oder die manuellen Einzelschritte.

## 🔧 Status

**Gerüst v0.1.0 — Sicherheitsinfrastruktur funktioniert, Härtung ist Stub.**

- [x] `install.sh` — alle Modi (`--apply`, `--audit`, `--confirm`, `--undo`, `--status`, `--phase`, `--yes`, `--force`, `--no-cues`)
- [x] `00-common.sh` — Logging, Fragen mit sicherem Default, `run`-Dry-Run-Wrapper, `backup_file`, Zustandsspeicher, Distro-Erkennung, `pkg_install`, **Watchdog** (systemd-run mit `at`-Fallback)
- [x] `00-preflight.sh` — komplettes Gate inkl. Web-Terminal-Erkennung und SSH-Key-Zählung
- [x] `10-audit.sh` — 9 Prüfpunkte, liest das System vollständig aus
- [x] `99-report.sh` — Score-Berechnung und Restliste (Minimal-HTML)
- [x] `NOTFALL.md` — Rescue-Konsole pro Hoster, manuelle Rückbau-Schritte
- [x] shellcheck sauber (`-S warning`), Syntax geprüft, CI eingerichtet
- [ ] `20-basics.sh` — unattended-upgrades / dnf-automatic, CrowdSec + fail2ban-Fallback, Traefik-Config-Vorbereitung, Logrotation
- [ ] `30-ssh.sh` — Konfigänderung, `sshd -t`, `reload` (nicht `restart`)
- [ ] `40-firewall.sh` — ufw- und firewalld-Zweig
- [ ] `50-wireguard.sh` — wg-easy-Compose, bcrypt-Hash, erster Client mit QR im Terminal, Traefik-Allowlist-Watchdog
- [ ] `--undo` — Backups zurückspielen, Firewall auf Ausgangszustand, wg-easy entfernen, Traefik-Config räumen
- [ ] Report — vollständiges Template (schwarz/rot), Vorher/Nachher, Teilen-Button nur mit Score
- [ ] Live-Test auf Tier-1-Systemen mit echtem Coolify

## 🗺️ Roadmap

1. **`30-ssh.sh` ausbauen** — der Baustein mit der höchsten Aussperr-Gefahr, also der, an dem sich der Watchdog beweisen muss.
2. **`40-firewall.sh`** mit ufw/firewalld-Verzweigung.
3. **`50-wireguard.sh`** — wg-easy-Deployment und Traefik-Allowlist-Aktivierung.
4. **`20-basics.sh`** — CrowdSec-Collections (`sshd`, `traefik`) + Bouncer.
5. **HTML-Report** im AIIANER-Look mit Vorher/Nachher.
6. **`--undo`** vollständig.
7. Live-Tests auf Ubuntu 24.04 / Debian 12 mit Coolify, dann Tier 2.

## 🎓 Der Kurs dazu

Das Script ist öffentlich und bleibt es. Es härtet deinen Server — der Kurs in der [AIIANER-Community](https://aiianer.de) erklärt das **Warum**, plus VPN-Setup Schritt für Schritt, Multi-Server, Backups und Incident-Response. Script und Video laufen im Gleichschritt: nach jeder Phase sagt dir das Script, an welcher Stelle im Kurs es weitergeht.

Wer keinen Kurs braucht, braucht ihn nicht. Der Code ist vollständig hier.

## 🤝 Mitmachen

Pull Requests willkommen — besonders für Systeme aus Tier 2 und für die offenen Phasen. Siehe [CONTRIBUTING.md](CONTRIBUTING.md). `shellcheck -x -S warning install.sh lib/*.sh` muss grün sein, jede Phase muss im Trockenlauf sauber durchlaufen, und jeder riskante Schritt bekommt einen Watchdog. Kein direktes `apt-get` in den Phasen — immer über `pkg_install`.

Wenn du das Script auf einem Tier-2-System erfolgreich getestet hast: Issue mit `--audit`-Ausgabe und `/var/log/coolify-shield.log` — dann rückt das System in Tier 1.

Wie das Projekt entstanden ist und warum die Entscheidungen so gefallen sind: [docs/ENTSTEHUNG.md](docs/ENTSTEHUNG.md).

## 🌍 Das AIIANER-Universum

| | |
| --- | --- |
| 🏠 **Community** | [aiianer.de](https://aiianer.de) — Kurse, Labs, Tutorials, KI-Coaches |
| 📺 **YouTube** | [youtube.com/@aiianer](https://www.youtube.com/@aiianer) — Tools, Tests, Deep-Dives |
| 🛠️ **coolify-server-hardening** | [github.com/oliverhees/coolify-server-hardening](https://github.com/oliverhees/coolify-server-hardening) — One-Shot-Hardening für *frische* Hetzner-Server (der Vorgänger; coolify-shield ist für *laufende* Instanzen) |
| 🔒 **Datenschleuse** | [github.com/oliverhees/datenschleuse](https://github.com/oliverhees/datenschleuse) — DSGVO-Filter für deine KI |
| 🧠 **Lokyy Brain** | [github.com/oliverhees/lokyy-brain](https://github.com/oliverhees/lokyy-brain) — dein Second Brain, selbst gehostet |
| 📡 **Sichtradar** | [sichtradar.de](https://sichtradar.de) — empfiehlt die KI dich oder deine Konkurrenz? |
| 🤖 **Lokyy** | [lokyy.de](https://lokyy.de) — KI-Apps & Werkzeuge |

## 📜 Lizenz

**[MIT](LICENSE)** — frei nutzbar, frei veränderbar, frei weitergebbar. Bei einem Werkzeug, das als root auf fremden Servern läuft, ist maximale Lesbarkeit und maximale Verbreitung wichtiger als Copyleft.

## 🔐 Sicherheit

Sicherheitslücken bitte **nicht** als öffentliches Issue melden. Verantwortungsvolle Meldung: siehe [SECURITY.md](SECURITY.md).

## ™️ Marken

„AIIANER", „Lokyy", „Lokyy Brain", „Datenschleuse" und „Sichtradar" sind Kennzeichen von Oliver Hees aka Aiianer. Die Lizenz des Quellcodes gewährt **keine** Rechte an diesen Namen oder Logos. Forks müssen unter eigenem Namen auftreten.

„Coolify" ist ein Open-Source-Projekt von **coollabs** ([github.com/coollabsio/coolify](https://github.com/coollabsio/coolify)). „wg-easy", „WireGuard", „Traefik" und „CrowdSec" gehören ihren jeweiligen Projekten. coolify-shield ist ein unabhängiges Community-Projekt und steht in keiner offiziellen Verbindung zu coollabs.

---

<div align="center">

Made with 🛡️ für alle, die ihren Coolify-Server nicht offen im Netz hängen lassen wollen · [MIT](LICENSE)

Mit ❤️ und Leidenschaft von **Oliver Hees – Der Aiianer**
Community: **[aiianer.de](https://aiianer.de)**

</div>
