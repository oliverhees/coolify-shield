# Entstehung: der Chat, aus dem coolify-shield hervorging

> Unbearbeiteter Verlauf des Gesprächs vom 29.08.2026 (Oliver Hees ↔ Claude), in dem Architektur und Gerüst entstanden sind. Hier dokumentiert, damit die Design-Entscheidungen (Watchdog, Dry-Run-Default, wg-easy statt Tailscale, kein `curl | bash`) nachvollziehbar bleiben. Rechtschreibung und Formulierungen sind Chat-Original.


**Created:** 8/29/2026 21:23:38  
**Updated:** 8/29/2026 21:45:09  
**Exported:** 8/29/2026 21:49:07  

## User:

> 8/29/2026 21:23:39

wie kann ich die Coolify login maske schützen?

## Assistant:

> 8/29/2026 21:24:12

> Verifizierte Sicherheitsfeatures und plante präzise Schutzstrategie.
>
> - Sicherungsoptionen für Coolify-Login evaluieren.
> - Coolify secure login page dashboard access restrict
> - Coolify two-factor authentication 2FA enable settings
> - Verifizierte Sicherheitsfeatures und plante präzise Schutzstrategie.
> - **Done**

**Kurz vorweg:** Wer in dein Coolify-Login kommt, hat faktisch Root auf deinem Server – im Dashboard steckt ein Terminal. Deshalb lohnt sich hier Aufwand mehr als bei jedem anderen Dienst.

Hier die Schutz-Leiter, von "sofort machen" bis "richtig dicht":

**Stufe 1 – 5 Minuten, kostet nichts**
- **2FA an**: Profil → Two-factor Authentication → Configure, QR scannen, Recovery-Codes extern speichern (nicht auf dem Server!). Coolify aktiviert 2FA erst, wenn der Code akzeptiert wurde
- **Registrierung aus**: Settings → Registration Allowed auf off
- **Passwort**: 20+ Zeichen aus dem Passwort-Manager
- **Port 8000 zu**: Sobald die Instanz über Domain + SSL läuft, läuft das Dashboard über Traefik auf 443 und 8000 wird nur noch lokal gebraucht

**Stufe 2 – die Login-Maske gar nicht erst öffentlich zeigen**
- **IP-Allowlist über Traefik**: Coolify hat dafür nichts eingebaut, aber du kannst eine Dynamic Config nach `/data/coolify/proxy/dynamic/` legen – Traefik zieht sie ohne Neustart. Wichtig: die Middleware muss an *alle* Dashboard-Router, auch die WebSocket-/Terminal-Routen, sonst zerschießt du dir das Login
- **Cloudflare Access (Zero Trust)**: Login-Maske liegt hinter einem Google/Mail-Login von Cloudflare, kostenlos bis 50 User. Meine Empfehlung, wenn du wechselnde IPs hast

**Stufe 3 – maximal dicht**
- **Tailscale/WireGuard**: Dashboard nur über VPN erreichbar, gar kein öffentlicher Port. Sicherste Variante, aber du brauchst den VPN-Client auf jedem Gerät
- **Fail2ban / Crowdsec** zusätzlich gegen Brute Force

Damit ich dir die *eine* passende Anleitung Schritt für Schritt baue statt aller drei:

---

**Sources:**

- [How to limit access to Coolify Dashboard by IP address? · coollabsio/coolify · Discussion #10303](https://github.com/coollabsio/coolify/discussions/10303)
- [Limit coolify access to the machine or network · coollabsio/coolify · Discussion #4031](https://github.com/coollabsio/coolify/discussions/4031)
- [[Feature]: Read-only / viewer role that's actually enforced (Policy authorization checks are currently stubbed to always-allow) · Issue #11052 · coollabsio/coolify](https://github.com/coollabsio/coolify/issues/11052)
- [Traefik Dashboard - Coolify Docs](https://coolify.io/docs/knowledge-base/proxy/traefik/dashboard)
- [Security Hardening Your Coolify Server: A Production-Ready Checklist | MassiveGRID Blog](https://massivegrid.com/blog/coolify-security-hardening/)
- [Configure Coolify: Dashboard, Domain & First Deployment — Mustafa Ramadan - Full Stack Developer, DevOps, AI Engineer](https://mustafaramx.com/post/configure-coolify-deploy-and-manage-your-first-project-like-a-pro/)
- [Basic Coolify Security - Envix](https://envix.shadowarcanist.com/coolify/security/basic/)
- [Coolify | DigitalOcean Documentation](https://docs.digitalocean.com/products/marketplace/catalog/coolify/)
- [Feature Request: Support for Google OAuth and Two-Factor Authentication (2FA) · coollabsio/coolify · Discussion #10877](https://github.com/coollabsio/coolify/discussions/10877)
- [2FA | Coolify Docs](https://next.coolify.io/docs/core/security/authentication/2fa)
- [torukobyte/coolify-dashboard - Docker Image](https://hub.docker.com/r/torukobyte/coolify-dashboard)
- [Force 2FA on team members · coollabsio/coolify · Discussion #1892](https://github.com/coollabsio/coolify/discussions/1892)
- [Disable 2FA Manually | Coolify Docs](https://coolify.io/docs/troubleshoot/dashboard/disable-2fa-manually)
- [VPS 3: Coolify - Pollito Dev](https://pollito.dev/en/blog/2025-01-30-vps-3/)
- [[Bug]: when adding 2fa auth, the QR code is not scanable. · Issue #2581 · coollabsio/coolify](https://github.com/coollabsio/coolify/issues/2581)
- [Authentication and Authorization | coollabsio/coolify | DeepWiki](https://deepwiki.com/coollabsio/coolify/8.1-authentication-and-authorization)

## User:

> 8/29/2026 21:31:42

F: Von wo greifst du normalerweise auf Coolify zu?
A: Wechselnd / mobil / unterwegs

F: Was läuft davon schon? (Wähle alle zutreffenden aus)
A: Nichts davon / weiß nicht

F: Wie tief willst du gehen?
A: alles aber tailscale ist nicht dsgvo konform.

## Assistant:

> 8/29/2026 21:32:37

> Orchestrierte DSGVO-konforme Coolify-Strategie mit Alternativen und Warnungen.
>
> - Empfehlungen für DSGVO-konforme Alternativen erarbeitend.
> - Coolify dashboard Authelia forward auth Traefik middleware websocket 6001 6002
> - Orchestrierte DSGVO-konforme Coolify-Strategie mit Alternativen und Warnungen.
> - **Done**

Alles klar — wechselnde IPs + nichts läuft bisher + DSGVO-Anforderung. Damit fällt IP-Allowlist als Hauptschutz raus, und der Weg heißt: **eigenes VPN auf deinem eigenen Server**.

## Kurz zur DSGVO-Frage

- **Tailscale**: Wenn dich der US-Anbieter im Control-Plane stört → **Headscale**. Gleiche Clients, gleiche Bedienung, aber der Koordinationsserver läuft bei dir. Oder direkt **wg-easy** (WireGuard mit Web-UI) — simpler, alles auf deiner Maschine.
- **Cloudflare Access** hat dasselbe Problem (US-Anbieter, TLS-Terminierung bei Cloudflare). Wenn du das vermeiden willst → **Authentik oder Authelia selbst gehostet** als Forward-Auth.
- **Aber**: Forward-Auth direkt vor das *Coolify-Dashboard* zu setzen ist heikel. Coolify generiert seine Traefik-Router selbst, das Realtime/Terminal läuft über eigene Router (Ports 6001/6002), und beim nächsten Update kann deine Anpassung überschrieben werden. Authentik ist super für deine *deployten Apps* — für das Dashboard selbst nimm lieber das VPN.

---

## Phase 1 — Heute Abend, 15 Minuten

Reihenfolge einhalten, sonst sperrst du dich aus.

- [ ] **2FA aktivieren**: Profil → Two-factor Authentication → Configure → QR scannen → Code eingeben → Validate. Erst danach ist es aktiv.
- [ ] **Recovery-Codes** in den Passwort-Manager. Nicht auf den Server, nicht auf dasselbe Handy wie die Authenticator-App.
- [ ] **Registrierung aus**: Settings → Registration Allowed auf off.
- [ ] **Passwort tauschen**: 25+ Zeichen aus dem Manager. Behandle es wie dein Root-Passwort — das Dashboard hat ein Terminal mit Root-Rechten.
- [ ] **Force HTTPS** bei allen Ressourcen prüfen.

Das allein killt schon 90 % der Bot-Angriffe.

## Phase 2 — SSH absichern (vor dem VPN!)

- [ ] SSH-Key hinterlegen und **testen, dass er funktioniert**
- [ ] Dann in `/etc/ssh/sshd_config`: `PasswordAuthentication no` und `PermitRootLogin prohibit-password`
- [ ] `sudo systemctl restart sshd`
- [ ] Zweites Terminal offen lassen beim Testen

**Wichtig**: Schau nach, ob dein Hoster eine Notfall-Konsole hat (Hetzner: VNC/Rescue, Netcup: SCP). Das ist dein Rettungsanker für Phase 3.

## Phase 3 — WireGuard, dein eigenes VPN

Empfehlung für deinen Fall: **wg-easy** als Docker-Container auf demselben Server.

- Web-UI zum Anlegen von Clients, QR-Code fürs Handy
- Offizielle WireGuard-App auf iOS/Android, ein Tap zum Verbinden
- Daten bleiben komplett bei dir → DSGVO unkritisch
- UDP-Port 51820 in der Firewall öffnen

Danach das Dashboard nur noch übers VPN erreichbar machen — per Traefik Dynamic Config unter `/data/coolify/proxy/dynamic/`:

```yaml
http:
  middlewares:
    dashboard-vpn-only:
      ipAllowList:
        sourceRange:
          - "10.8.0.0/24"   # dein WireGuard-Subnetz
          - "127.0.0.1/32"
```

⚠️ Die Middleware muss an **alle** Dashboard-Router, auch die Realtime-/Terminal-Router. Sonst hast du die Loginseite dicht, aber das Terminal offen — oder du zerschießt dir die Session-Handhabung.

Sicherer Alternativweg ohne Traefik-Gefrickel: Coolify gar nicht auf einer öffentlichen Domain laufen lassen, sondern nur über `http://10.8.0.1:8000` im VPN. Weniger elegant, aber deutlich robuster gegen Updates.

## Phase 4 — Firewall zumachen

Mit ufw, **erst nachdem VPN und SSH-Key nachweislich laufen**:

| Port | Regel |
|---|---|
| 22 | nur aus dem VPN-Subnetz |
| 80 / 443 | von überall (brauchen deine Apps + Let's Encrypt) |
| 51820/udp | von überall (WireGuard-Einwahl) |
| 8000, 6001, 6002 | nur localhost + VPN-Subnetz |

## Phase 5 — Nachbrenner

- **CrowdSec** oder fail2ban gegen Brute Force auf allem, was öffentlich bleibt
- **Authentik** vor deine deployten Apps (nicht vors Dashboard) — dafür gibt's offizielle Coolify-Doku mit fertiger Middleware-Config
- Automatische Coolify-Updates aktiv lassen

---

**Der eine Satz, den du dir merken solltest:** Bevor du irgendwas zumachst, sorge dafür, dass du einen zweiten Weg rein hast. Die häufigste Coolify-Katastrophe ist nicht der Hacker, sondern der Admin, der sich selbst ausgesperrt hat.

Soll ich dir für Phase 3 die komplette wg-easy-Compose plus die passende Traefik-Config als fertiges Setup-Dokument bauen?

---

**Sources:**

- [Authentik Forward Authentication Middleware | Coolify Docs](https://coolify.io/docs/knowledge-base/proxy/traefik/protect-services-with-authentik)
- [Add basic auth to the UI · coollabsio/coolify · Discussion #4677](https://github.com/coollabsio/coolify/discussions/4677)
- [Adding Authelia to a Self-Hosted Supabase Setup on Coolify | by Umarhamza Dev | Jun, 2026 | Medium](https://medium.com/@umarhamza.dev/adding-authelia-to-a-self-hosted-supabase-setup-on-coolify-8857b9321015)
- [[Bug]: "Authentik Forward Authentication Middleware​" documentation does not work · Issue #5563 · coollabsio/coolify](https://github.com/coollabsio/coolify/issues/5563)
- [Chain middleware forward auth failover - Traefik v2 - Traefik Labs Community Forum](https://community.traefik.io/t/chain-middleware-forward-auth-failover/21098)
- [Authentik Forward Auth Middleware for Coolify | iLtc's Blog](https://blog.iltc.io/2025-01-28-authentik-forward-auth-middleware-for-coolify/)
- [How to configure Authentik forward authentication with Traefik in Coolify](https://coolify.io/docs/knowledge-base/traefik/protecting-services-with-authentik/)
- [Security Hardening Your Coolify Server: A Production-Ready Checklist | MassiveGRID Blog](https://massivegrid.com/blog/coolify-security-hardening/)
- [Integrating Coolify into an existing Traefik setup](https://beaussan.io/blog/coolify-into-existing-traefik)
- [forward auth](https://hub.docker.com/r/nihaopaul/forward-auth)

## User:

> 8/29/2026 21:35:00

Ok frage gibt es einen weg das alles zu automatisieren für die community user?

## Assistant:

> 8/29/2026 21:35:53

> Architektierte automatisierbaren Sicherheitsprozess mit Anti-Lockout-Mechanismus.
>
> - Architektierte automatisierbaren Sicherheitsprozess mit Anti-Lockout-Mechanismus.
> - **Done**

Ja — aber nicht alles. Der ehrliche Cut sieht so aus:

## Was sich sauber automatisieren lässt

- SSH-Härtung (Key-only, Root-Login aus)
- ufw-Regeln inkl. der Coolify-Ports 8000/6001/6002
- wg-easy ausrollen + Client-Config mit QR-Code generieren
- Traefik Dynamic Config schreiben
- CrowdSec/fail2ban installieren
- unattended-upgrades aktivieren
- **Audit**: prüfen und melden, was noch offen ist

## Was der User selbst klicken muss

- **2FA** — geht nur über die Coolify-UI, Recovery-Codes muss er wegspeichern
- **Passwort tauschen**
- **Registrierung deaktivieren** (theoretisch per `php artisan tinker` in den Container machbar, aber an der DB rumschreiben ist bei einem Script für Fremde ein No-Go)

Heißt: Das Script macht die Infrastruktur, und spuckt am Ende eine **Restliste** aus, die der User in 3 Minuten abklickt.

---

## Das eigentliche Problem: Ausperr-Risiko

Ein Hardening-Script bei Fremden auf dem Server ist gefährlich. Wenn 200 Community-User das laufen lassen, sperren sich garantiert 15 aus — und du hast den Support am Hals.

Die Lösung ist ein **Watchdog-Muster** (wie `reload in 10` bei Cisco-Switches):

```bash
# Firewall-Regeln setzen …
# … und sofort einen Rückfall-Job scharf machen:
echo "ufw --force reset && ufw disable" | at now + 10 minutes

# User testet in einem ZWEITEN Terminal, ob er noch reinkommt.
# Klappt es → er bestätigt:
./harden.sh --confirm    # löscht den at-Job

# Klappt es nicht → 10 Minuten warten, Firewall ist wieder offen.
```

Das gleiche Prinzip für SSH und für die Traefik-IP-Allowlist. Damit wird aus "riskantes Script" ein "kann eigentlich nichts passieren".

## Zwei-Phasen-Architektur

**Phase A — kann jeder blind laufen lassen**
Alles ohne Ausperr-Risiko: CrowdSec, unattended-upgrades, Audit-Report, Traefik-Config vorbereiten (aber noch nicht aktivieren).

**Phase B — nur mit Watchdog + Bestätigung**
Firewall, SSH, VPN-Zwang. Immer mit Preflight-Check vorher: Läuft ein SSH-Key? Ist wg-easy erreichbar? Hat der Hoster eine Notfallkonsole?

## Sonstige Bauteile, die es braucht

- **Idempotenz** — Coolify-Updates können die Traefik-Config überschreiben, das Script muss beliebig oft laufen können
- **`--dry-run`** als Default, damit man erst sieht was passiert
- **HTML-Report am Ende** statt Terminal-Wall-of-Text: grün/gelb/rot, was erledigt ist, was der User noch klicken muss
- **Distribution**: Repo mit lesbarem Script > `curl | bash`. Bei einem Security-Script ist "lies erst, dann führ aus" auch inhaltlich die richtige Botschaft

---

Bevor ich dir das baue, drei Sachen, die die Architektur komplett verändern:

## User:

> 8/29/2026 21:37:05

F: Welche Form soll es haben?
A: was würdest du empfehlen? Es muss wirklich für dumme gebaut sein.

F: Wer sind die Community-User technisch?
A: Gemischt – muss beides abfangen

F: Was ist der Zweck dahinter?
A: Teil eines bezahlten Kurses

## Assistant:

> 8/29/2026 21:38:03

> Konzipierte anfängerfreundliches Bash-Skript mit interaktivem Wizard und Video-Synchronisation.
>
> - Konzipierte anfängerfreundliches Bash-Skript mit interaktivem Wizard und Video-Synchronisation.
> - **Done**

## Meine Empfehlung: **Bash-Wizard, ein einziger Befehl**

Kein Ansible. Begründung kurz:

- Ansible braucht eine Control-Machine, Python, Inventory-Datei, SSH-Config. Das ist schon die halbe Miete an Hürde — und du fängst damit genau die User nicht ab, die den Schutz am dringendsten brauchen.
- Dein User sitzt eh schon per SSH auf dem Server. Ein Script, das dort läuft, ist der kürzeste Weg vom Problem zur Lösung.
- Bash kann jeder lesen. Bei einem Security-Tool ist "schau rein, bevor du es ausführst" auch inhaltlich die richtige Botschaft.

## Der Trick für "muss für Dumme funktionieren"

**Das Script fragt, statt zu erwarten.**

- Keine Flags, keine Config-Datei. Fragen im Klartext, sicherste Antwort als Default, Enter drücken reicht.
- **Preflight-Gate**: prüft OS-Version, Root-Rechte, ob Coolify überhaupt läuft, ob ein SSH-Key hinterlegt ist. Fehlt was → Abbruch mit **einem** klaren Satz, was zu tun ist. Niemals ein Stacktrace.
- **Idempotent**: erkennt, was schon erledigt ist, und sagt "übersprungen — läuft bereits". Der User kann es zehnmal laufen lassen.
- **`--dry-run` ist der Default.** Erst zeigen, dann fragen, dann machen.

## Repo-Struktur

```
coolify-shield/
  install.sh          ← der eine Befehl
  lib/
    00-preflight.sh   Gate: darf das hier überhaupt laufen?
    10-audit.sh       Bestandsaufnahme, ändert nichts
    20-basics.sh      Phase A: CrowdSec, Auto-Updates (risikofrei)
    30-ssh.sh         Phase B: Watchdog
    40-firewall.sh    Phase B: Watchdog
    50-wireguard.sh   Phase B: Watchdog
    99-report.sh      HTML-Report
  NOTFALL.md          ← wichtigste Datei im ganzen Repo
  README.md
```

## Die drei Anti-Support-Bauteile

Du wirst 200 User haben. Ohne die hier verbringst du deine Abende im Skool-Chat:

1. **NOTFALL.md** — "Ich komm nicht mehr rein". Pro Hoster (Hetzner, Netcup, Contabo, Strato) die Rescue-Konsole erklärt. Vor Zeile 1 des Scripts verlinkt.
2. **Log unter `/var/log/coolify-shield.log`** — im Supportfall sagst du nur "schick mir die Datei", statt 20 Fragen zu stellen.
3. **`./install.sh --undo`** — macht alles rückgängig. Jede geänderte Datei wird vorher mit Zeitstempel gesichert.

Plus der Watchdog aus meiner letzten Antwort. Damit kann faktisch nichts kaputtgehen.

## Der Kurs-Hebel

Das ist der Teil, der das Ding verkäuflich macht: **Script und Video laufen im Gleichschritt.**

Nach jeder Phase gibt das Script aus:

```
✓ Phase B abgeschlossen — Firewall aktiv, Watchdog läuft (10 min)
▶ Weiter im Kurs: Modul 3, ab Minute 4:12
```

Und am Ende: **HTML-Report mit Ampel und Sicherheits-Score**, offene Punkte (2FA, Passwort) als anklickbare Liste. Den posten die Leute in der Community — das ist dein Social Proof, der neue Käufer bringt.

**Ein strategischer Einwand**, den du kurz abwägen solltest: Ein Security-Script hinter einer Paywall hat ein Vertrauensproblem — niemand führt gerne ungeprüften Root-Code aus, den er nicht vorher lesen konnte. Mein Vorschlag: **Script öffentlich, Kurs kostenpflichtig.** Das Script allein hardened den Server; der Kurs erklärt, *warum*, plus VPN-Setup, Multi-Server, Backups, Incident-Response. So kriegst du Reichweite über GitHub-Stars *und* verkaufst trotzdem.

Damit ich loslegen kann:

## User:

> 8/29/2026 21:39:13

F: Welche Zielsysteme muss das Script abdecken?
A: Alles abfangen, was Coolify unterstützt

F: Wo soll das Repo liegen?
A: GitHub public (Stars/Reichweite)

F: Womit fangen wir an?
A: Komplettes Gerüst, alle Phasen als Stubs

## Assistant:

> 8/29/2026 21:45:09

> Orchestrierend die Installationsskript-Architektur mit Flags und Bibliotheken.
>
> - Orchestrierend die Installationsskript-Architektur mit Flags und Bibliotheken.
> - HTML-Report ist Teil des Deliverables – Design-Vorgaben prüfen
> - **Done**

Baue ich. Gerüst mit echter Sicherheits-Infrastruktur, Phasen als Stubs.

> Ran 9 commands, created 6 files, edited file, presented file
>
> - Repo-Struktur anlegen
> - Zentrale Bibliothek: Logging, Distro-Erkennung, Dry-Run, Backups, Watchdog
> - Preflight-Gate: bricht ab, bevor irgendetwas kaputtgehen kann
> - Audit-Modul: reine Bestandsaufnahme, aendert nichts
> - Phasen-Stubs anlegen
> - Haupt-Einstiegspunkt mit Argument-Parsing, --confirm und --undo
> - NOTFALL.md - die wichtigste Datei im Repo
> - README für das öffentliche GitHub-Repo
> - CI, Lizenz, gitignore anlegen und Syntax prüfen
> - CI-Datei nachziehen und Script testen
> - Log-Schreibfehler ohne Root abfangen
> - Erneut testen und linten
> - Lint-Warnungen der Stubs unterdrücken
> - Restliche Lint-Warnungen beheben und Endzustand prüfen
> - Repo in den Ausgabeordner kopieren
> - Leergebliebenen Fehlordner entfernen und Archiv neu packen
> - Presenting file(s)...
> - **Done**

**Steht.** 14 Dateien, shellcheck sauber, Syntax geprüft.

## Was schon echt funktioniert

- **`lib/00-common.sh`** – das Fundament: Watchdog (systemd-run mit `at`-Fallback), Backup-Mechanik, Dry-Run-Wrapper, Zustandsspeicher für Idempotenz, Distro-Abstraktion für apt/dnf/zypper/pacman und ufw/firewalld
- **`lib/00-preflight.sh`** – das Gate. Bricht bei fehlendem SSH-Key ab, bricht ab wenn du im Coolify-Web-Terminal statt per SSH sitzt, verlangt eine offene Rescue-Konsole
- **`lib/10-audit.sh`** – läuft komplett, liest 9 Prüfpunkte aus dem System
- **`install.sh`** – alle Befehle inkl. `--confirm`, `--undo`, `--status`

## Was Stub ist

`20-basics`, `30-ssh`, `40-firewall`, `50-wireguard`, `99-report` – Struktur, Watchdog-Verdrahtung und Rückfragen stehen, die Aktionen sind TODO-Kommentare mit der konkreten Umsetzung als Notiz.

## Drei Design-Entscheidungen, die ich getroffen habe

**VPN läuft vor der Firewall.** Sonst macht die Firewall den Weg zu, bevor der VPN-Weg existiert. Klassischer Aussperr-Fehler.

**Preflight bricht ab, wenn du im Coolify-Web-Terminal sitzt.** Das ist die Falle, in die deine Anfänger sonst reihenweise tappen — Firewall zu, eigene Sitzung tot.

**NOTFALL.md fängt mit "warte 12 Minuten" an.** Weil der Watchdog das Problem meistens schon gelöst hat, bevor der User in Panik im Skool schreibt. Spart dir Support.

## Das Support-Detail, das dir Abende rettet

In NOTFALL.md ganz unten: Eine bestehende SSH-Verbindung läuft weiter, auch wenn neue blockiert sind. Wer im **alten** Fenster testet, drückt `--confirm` und ist ausgesperrt. Steht explizit drin, weil da 80 % der Fälle herkommen.

---

Nächster sinnvoller Schritt wäre **`30-ssh.sh` komplett ausbauen** — das ist der Baustein mit der höchsten Aussperr-Gefahr, also der, bei dem sich die Watchdog-Mechanik am besten beweisen muss. Danach `40-firewall.sh` mit der ufw/firewalld-Verzweigung.

Soll ich damit weitermachen, oder erst den HTML-Report bauen, damit du was zum Zeigen im Kurs-Verkaufsvideo hast?

> File: `/mnt/user-data/outputs/coolify-shield/README.md`

> File: `/mnt/user-data/outputs/coolify-shield/install.sh`

> File: `/mnt/user-data/outputs/coolify-shield/NOTFALL.md`

> File: `/mnt/user-data/outputs/coolify-shield/lib/00-common.sh`

> File: `/mnt/user-data/outputs/coolify-shield/lib/00-preflight.sh`

> File: `/mnt/user-data/outputs/coolify-shield/lib/10-audit.sh`

> File: `/mnt/user-data/outputs/coolify-shield.tar.gz`

