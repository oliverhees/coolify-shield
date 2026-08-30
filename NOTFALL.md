# Ich komme nicht mehr auf meinen Server

Ruhig bleiben. Lies das hier zu Ende, bevor du irgendwas anfasst.

> Begriffe unklar (Rescue-Konsole, SSH, Firewall)? Alles erklärt in [ANFAENGER.md](ANFAENGER.md).

---

## Zuerst: Hast du gewartet?

`coolify-shield` setzt vor jeder riskanten Änderung einen Rückfall-Timer. Wenn
du `--confirm` **nicht** ausgeführt hast, macht der Server die Änderung nach
**10 Minuten von selbst rückgängig**.

**Warte also erst 12 Minuten und probier es dann nochmal.** In den allermeisten
Fällen löst sich das Problem hier schon.

---

## Wenn es danach immer noch nicht geht

Du brauchst die Notfall-Konsole deines Hosters. Das ist ein Bildschirm-Zugang,
der komplett am Netzwerk vorbeigeht – Firewall und SSH sind ihm egal.

### Hetzner Cloud
Console → Server auswählen → rechts oben **>_ Console**. Login mit dem
Root-Passwort aus der E-Mail bei Servererstellung. Kein Passwort mehr da?
**Rescue → Root-Passwort zurücksetzen**, dann Server neu starten.

### Hetzner Dedicated (Robot)
Robot → Server → **Rescue** aktivieren → Neustart. Du landest in einem
Linux-Notfallsystem. Deine Platte einhängen mit `mount /dev/sda1 /mnt`.

### Netcup
SCP (Server Control Panel) → **VNC / Konsole**. Root-Passwort steht in deinen
Vertragsunterlagen.

### Contabo
Kundenpanel → **VNC** unter dem jeweiligen Server.

### IONOS
Cloud Panel → Server → **Remote Console**.

### Strato
Serververwaltung → **KVM-Konsole**.

### DigitalOcean / Vultr / Linode / Scaleway
Alle haben eine **Recovery Console** direkt im Dashboard, meist ganz oben in
der Server-Ansicht.

### Hoster nicht dabei?
Such im Support-Bereich nach „VNC", „Konsole", „Recovery" oder „Rescue". Jeder
seriöse Anbieter hat sowas.

---

## Drin? Dann repariere es so

```bash
sudo /opt/coolify-shield/install.sh --undo
```

(Beim Anfänger-Weg liegt das Script unter `/opt/coolify-shield`. Hast du es selbst
geklont, dann in dein Verzeichnis wechseln.)

Wenn das Verzeichnis weg ist, hier die Einzelschritte:

### Firewall wieder öffnen
```bash
ufw disable                    # Debian/Ubuntu
systemctl stop firewalld       # Fedora/Rocky/Alma
```
Die Docker-Regeln für das Dashboard stehen in `/etc/ufw/after.rules` zwischen
`# BEGIN coolify-shield` und `# END coolify-shield`. Nach `ufw disable` sind sie
inaktiv; endgültig weg: den Block löschen.

### SSH-Konfiguration zurückholen
```bash
rm -f /etc/ssh/sshd_config.d/00-coolify-shield.conf
sshd -t && systemctl reload ssh
```
`sshd -t` prüft auf Syntaxfehler. Gibt es einen Fehler aus, lade nicht neu,
sonst startet SSH gar nicht mehr.

### fail2ban hat DICH gesperrt (zu oft falsch eingeloggt)
```bash
fail2ban-client status sshd            # zeigt gesperrte Adressen
fail2ban-client set sshd unbanip <deine-ip>
```
Die Sperre läuft nach einer Stunde von selbst ab.

### VPN-Tunnel kaputt, Dashboard nicht erreichbar
Der Tunnel ist der einzige Weg zum Dashboard. Solange er nicht geht, hilft ein
SSH-Tunnel als Ersatz:
```bash
ssh -L 8000:localhost:8000 <dein-servername>
```
Dann im Browser `http://localhost:8000`. Den Handy-QR-Code neu anzeigen:
```bash
sudo qrencode -t ansiutf8 < /var/lib/coolify-shield/wireguard/handy.conf
```

---

## Was du dem Support schicken solltest

Damit dir jemand helfen kann:

```bash
cat /var/log/coolify-shield.log
```

Da steht jeder Schritt drin, mit Zeitstempel. Schick die Datei in die
Community – damit ist die Hälfte der Fragen schon beantwortet.

---

## Beim nächsten Mal

1. Notfall-Konsole **vorher** öffnen und einmal einloggen.
2. Ein zweites SSH-Fenster offen lassen, während das Script läuft.
3. Erst `./install.sh` (Trockenlauf), dann `--apply`.
4. `--confirm` erst drücken, wenn du dich in einem **neuen** Fenster
   erfolgreich eingeloggt hast. Das alte Fenster zählt nicht – bestehende
   Verbindungen laufen weiter, auch wenn neue blockiert sind. Genau darauf
   fallen die meisten rein.
