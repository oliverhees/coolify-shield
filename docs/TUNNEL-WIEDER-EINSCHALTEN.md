# Tunnel wieder einschalten

Du hast den Tunnel einmal eingerichtet, dann wochenlang nicht gebraucht, und jetzt willst du wieder ins Coolify-Dashboard. Du musst nichts neu einrichten. Die Tunnel-Datei ist noch da, du schaltest den Tunnel nur ein.

Deine Datei liegt auf dem Laptop hier (falls du sie noch mal brauchst):

| System | Pfad |
|--------|------|
| Windows | `C:\Users\<du>\.coolify-shield\<name>-laptop.conf` |
| Mac / Linux | `~/.coolify-shield/<name>-laptop.conf` |

Das Dashboard erreichst du bei eingeschaltetem Tunnel immer unter **`http://10.8.0.1:8000`**.

---

## Windows

1. Startmenü, **WireGuard** eintippen, App öffnen. Läuft sie schon, sitzt sie unten rechts im Infobereich (Drachen-Symbol).
2. Links deinen Tunnel anklicken (`<name>-laptop`).
3. **Aktivieren** klicken. Der Status springt auf „Aktiv“.
4. Browser: `http://10.8.0.1:8000`

Ausschalten: derselbe Knopf, jetzt heißt er **Deaktivieren**.

Steht der Tunnel nicht in der Liste: unten links **Tunnel importieren** → die `.conf`-Datei von oben auswählen → Aktivieren. Die App braucht dafür einmal Administrator-Rechte.

## Mac

1. **WireGuard** öffnen (Launchpad oder Spotlight). Danach sitzt ein kleines Symbol oben in der Menüleiste.
2. Menüleisten-Symbol anklicken → deinen Tunnel auswählen. Oder im App-Fenster den Tunnel markieren und **Aktivieren** klicken.
3. Browser: `http://10.8.0.1:8000`

Der Tunnel taucht auch in den **Systemeinstellungen → VPN** auf, dort geht der Schalter genauso.

Steht der Tunnel nicht in der Liste: **Tunnel aus Datei importieren** → `.conf`-Datei auswählen. macOS fragt einmal, ob WireGuard VPN-Konfigurationen hinzufügen darf: **Erlauben**.

## Linux

Das Start-Script legt den Tunnel im NetworkManager an. Klappt das auf deinem System nicht, nimmt es `wg-quick`. Welcher Weg bei dir gilt, siehst du so:

```bash
nmcli connection show | grep laptop    # Treffer? Dann NetworkManager
sudo ls /etc/wireguard                 # <name>.conf? Dann wg-quick
```

**NetworkManager, mit der Maus:** Einstellungen → Netzwerk → VPN → `<name>-laptop` einschalten. Je nach Desktop geht das auch direkt über das Netzwerk-Symbol oben im Panel.

**NetworkManager, im Terminal:**

```bash
nmcli connection up <name>-laptop      # einschalten
nmcli connection down <name>-laptop    # ausschalten
```

**wg-quick:** Die Datei heißt wie dein Server, also zum Beispiel `/etc/wireguard/meinserver.conf`. Dann:

```bash
sudo wg-quick up meinserver            # einschalten
sudo wg-quick down meinserver          # ausschalten
```

Nimm einen der beiden Wege, nicht beide gleichzeitig. Sonst streiten sich zwei Tunnel um dieselben Adressen.

## Handy

WireGuard-App öffnen, Schalter neben dem Tunnel antippen. Fertig.

---

## Läuft er wirklich?

Die WireGuard-App zeigt bei eingeschaltetem Tunnel den Wert **„Letzter Handshake“** (englisch „Latest handshake“). Linux: `sudo wg show`.

- **Da steht eine Zeit von vor ein paar Sekunden:** Der Tunnel steht. Der Laptop meldet sich alle 25 Sekunden beim Server.
- **Das Feld fehlt oder bleibt leer:** Der Server antwortet nicht. Siehe unten.

## Wenn es nach langer Pause nicht mehr klappt

| Was du siehst | Woran es liegt | Was du tust |
|---------------|----------------|-------------|
| Kein Handshake | Server aus, gelöscht oder hat eine neue IP | Hetzner Console prüfen. Neue IP? In der `.conf` die Zeile `Endpoint = <ip>:51820` anpassen und neu importieren |
| Kein Handshake, Server läuft | Hetzner-Firewall lässt UDP 51820 nicht durch | Server → Firewalls → Regel eingehend, UDP, 51820 ergänzen |
| Kein Handshake, alles richtig | WireGuard auf dem Server gestoppt | `ssh <name>` und dann `sudo systemctl restart wg-quick@wg0` |
| Handshake da, Dashboard lädt nicht | Coolify selbst hängt | `ssh <name>` und dann `sudo docker ps`, notfalls Server neu starten |
| Handshake da, aber sporadisch weg | Anderes VPN (Tailscale, Firmen-VPN) oder dein Heimnetz nutzt auch `10.8.0.x` | Anderes VPN kurz ausschalten und testen |

Du kommst immer noch per SSH auf den Server, auch ohne Tunnel. Port 22 bleibt absichtlich offen, damit dich ein kaputter Tunnel nie aussperrt.
