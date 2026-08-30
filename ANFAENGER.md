# coolify-shield für absolute Anfänger

> Du hast noch nie einen Server verwaltet, weißt nicht genau, was „SSH" oder „Firewall" bedeutet, und hast trotzdem Coolify installiert, weil du deine eigenen Apps oder KI-Tools hosten willst? **Dann ist diese Seite für dich.** Hier wird nichts vorausgesetzt. Alles wird einmal von Null erklärt: warum du das überhaupt brauchst, was das Script macht und wie es funktioniert.
>
> Im Kurs gibt es dazu ein Video. Diese Seite ist die Version zum Nachlesen — du kannst sie neben dem Terminal offen lassen.

---

## Inhaltsverzeichnis

1. [Die Kurzfassung in drei Sätzen](#1-die-kurzfassung-in-drei-sätzen)
2. [Was ist eigentlich ein Server?](#2-was-ist-eigentlich-ein-server)
3. [Was ist Coolify — und warum ist es gefährlich?](#3-was-ist-coolify--und-warum-ist-es-gefährlich)
4. [Wer greift dich überhaupt an?](#4-wer-greift-dich-überhaupt-an)
5. [Die Begriffe, die du brauchst](#5-die-begriffe-die-du-brauchst)
6. [Werkzeugkasten: Terminal und SSH — Schritt für Schritt](#6-werkzeugkasten-terminal-und-ssh--schritt-für-schritt)
7. [Was das Script macht — Schritt für Schritt erklärt](#7-was-das-script-macht--schritt-für-schritt-erklärt)
8. [Der Rückfall-Timer — warum du dich nicht aussperren kannst](#8-der-rückfall-timer--warum-du-dich-nicht-aussperren-kannst)
9. [Was du selbst klicken musst (und warum das Script das nicht kann)](#9-was-du-selbst-klicken-musst-und-warum-das-script-das-nicht-kann)
10. [Der komplette Ablauf — was du wann tippst](#10-der-komplette-ablauf--was-du-wann-tippst)
11. [Was du danach anders machst](#11-was-du-danach-anders-machst)
12. [Häufige Fragen](#12-häufige-fragen)
13. [Glossar](#13-glossar)

---

## 1. Die Kurzfassung in drei Sätzen

1. **Dein Coolify-Login ist die Haustür zu deinem ganzen Server** — wer da reinkommt, kann alles: deine Apps löschen, deine Daten lesen, deinen Server für Angriffe auf andere missbrauchen.
2. **Diese Haustür steht bei den meisten Leuten sperrangelweit offen im Internet**, mit nur einem Passwort davor, und Bots probieren rund um die Uhr Passwörter durch.
3. **coolify-shield schließt die Tür** — und zwar so, dass du dich dabei nicht selbst aussperrst, auch wenn du noch nie einen Server verwaltet hast.

Wenn du nur das behältst, hast du das Wichtigste verstanden. Der Rest erklärt, *warum* das so ist und *wie* das Script das macht.

---

## 2. Was ist eigentlich ein Server?

Ein Server ist **ein Computer, der irgendwo in einem Rechenzentrum steht und Tag und Nacht läuft.** Du hast ihn bei einem Hoster gemietet (Hetzner, Netcup, Contabo, IONOS …). Er hat keinen Bildschirm und keine Tastatur — du steuerst ihn übers Internet.

Der Unterschied zu deinem Laptop: **Dein Server hat eine öffentliche Adresse.** Jeder Mensch und jeder Computer auf der Welt kann ihn ansprechen. Das ist gewollt — sonst könnte ja niemand deine Website oder deine App aufrufen. Aber es bedeutet auch: **Jeder kann an deiner Tür klingeln.** Auch die, die du nicht eingeladen hast.

Ein Server hat viele „Türen". Die heißen **Ports** und sind einfach durchnummeriert. Ein paar Beispiele:

| Port | Wofür |
| --- | --- |
| 80 und 443 | Webseiten (http und https) — die Türen, durch die deine Besucher kommen |
| 22 | SSH — die Tür, durch die **du** den Server verwaltest |
| 8000 | Das Coolify-Dashboard |
| 6001, 6002 | Coolify-Zusatzdienste (Live-Updates im Dashboard, das eingebaute Terminal) |

Jede offene Tür ist eine Möglichkeit reinzukommen. **Sicherheit heißt: Nur die Türen offen lassen, die offen sein müssen — und die anderen zuschließen.**

---

## 3. Was ist Coolify — und warum ist es gefährlich?

Coolify ist ein Programm, das dir das Verwalten deines Servers leicht macht. Du bekommst eine Webseite (das **Dashboard**), auf der du mit ein paar Klicks Apps installierst, Datenbanken anlegst und Domains verbindest. Statt hundert Befehle zu tippen, klickst du. Deshalb ist es so beliebt — und deshalb hast du es wahrscheinlich auch.

**Hier ist das Problem:** Damit Coolify all das für dich tun kann, hat es **die vollen Rechte auf deinem Server.** Das nennt man „Root" — der Chef-Zugang, der alles darf. Und im Coolify-Dashboard ist sogar ein **Terminal** eingebaut, also eine Kommandozeile, über die man direkt Befehle auf dem Server ausführen kann.

Das heißt in Klartext:

> **Wer sich in dein Coolify-Dashboard einloggen kann, hat deinen kompletten Server. Punkt.**

Nicht „kann deine Apps sehen". Nicht „kann was kaputt machen". Sondern: **alles.** Daten kopieren, alles löschen, Schadsoftware installieren, deinen Server benutzen, um andere anzugreifen — und das dann unter deinem Namen und deiner IP-Adresse.

Und das Login zu diesem Dashboard liegt bei den meisten Leuten **öffentlich im Internet**, erreichbar für jeden, geschützt durch genau ein Passwort.

Stell dir vor, dein Haus hätte eine Tür, hinter der der Tresor, alle Dokumente und die Autoschlüssel liegen — und diese Tür stünde an einer belebten Straße, mit einem Zahlenschloss, an dem den ganzen Tag Fremde herumprobieren dürfen. Das ist dein Coolify-Dashboard ohne Schutz.

So sieht das aus — heute, und nachdem das Script durchgelaufen ist:

```mermaid
flowchart TB
    subgraph heute["😱 Heute: alles offen"]
        direction LR
        B1["🤖 Bots aus dem<br/>ganzen Internet"] -->|"Port 8000<br/>Login-Seite"| D1["Coolify-Dashboard<br/>= Root auf dem Server"]
        B1 -->|"Port 22<br/>Passwort raten"| S1["SSH"]
    end
    subgraph danach["🛡️ Nach coolify-shield"]
        direction LR
        B2["🤖 Bots"] -->|"Port 80/443"| W2["deine Apps<br/>(sollen erreichbar sein)"]
        B2 -.->|"Port 8000: existiert nicht mehr"| X2(("❌"))
        B2 -.->|"Port 22: nur mit Key,<br/>nur aus dem Tunnel"| X3(("❌"))
        DU["📱 Du mit<br/>WireGuard-Tunnel"] ==>|"verschlüsselt"| D2["Coolify-Dashboard"]
        DU ==> S2["SSH"]
    end
    style D1 fill:#c62828,color:#fff
    style D2 fill:#2e7d32,color:#fff
    style S2 fill:#2e7d32,color:#fff
```

---

## 4. Wer greift dich überhaupt an?

Eine Frage, die sich fast jeder Anfänger stellt: *„Wer soll denn ausgerechnet mich angreifen? Ich bin doch niemand."*

Die ehrliche Antwort: **Niemand greift *dich* an. Es greifen Programme *alle* an.**

Im Internet laufen ununterbrochen automatische Programme (**Bots**), die einfach jede Adresse durchprobieren, die es gibt. Sie suchen nach offenen Türen. Finden sie eine Login-Seite, probieren sie Passwörter durch — tausende pro Stunde, aus Listen mit Millionen gestohlener Passwörter. Das kostet die Angreifer nichts. Es läuft vollautomatisch, rund um die Uhr.

Ein frischer Server bekommt **innerhalb der ersten Stunde** die ersten Login-Versuche. Innerhalb eines Tages sind es hunderte. Das ist keine Übertreibung — du kannst es nach dem Script in den Logs sehen.

Deine Größe ist egal. Du bist nicht das Ziel — du bist **eine von Millionen Adressen, die automatisch abgeklopft werden.** Und wenn deine Tür die ist, die nachgibt, hast du verloren. Nicht, weil jemand dich wollte, sondern weil du der Einfachste warst.

**Die gute Nachricht:** Diese Bots sind dumm. Sie suchen den leichtesten Weg. Wer seine Tür ordentlich schließt, wird einfach übersprungen. Genau dafür ist das Script da.

---

## 5. Die Begriffe, die du brauchst

Du wirst im Script und im Kurs immer wieder auf ein paar Fachwörter stoßen. Hier sind sie einmal erklärt — nicht technisch korrekt bis ins Letzte, sondern so, dass du weißt, was gemeint ist.

### SSH — deine Fernbedienung für den Server

SSH ist die Art, wie du dich mit deinem Server verbindest, um ihm Befehle zu geben. Du tippst auf deinem Laptop in ein schwarzes Fenster (das **Terminal**), und die Befehle werden auf dem Server ausgeführt. Ohne SSH kannst du deinen Server nicht verwalten.

SSH ist also **deine wichtigste Tür**. Sie muss offen bleiben — aber nur für dich.

Wie du das Terminal öffnest, dich zum ersten Mal verbindest und einen Key anlegst, steht Schritt für Schritt in [Abschnitt 6](#6-werkzeugkasten-terminal-und-ssh--schritt-für-schritt).

### Passwort vs. SSH-Key — Zahlenschloss vs. Sicherheitsschlüssel

Für SSH gibt es zwei Arten, sich auszuweisen:

- **Passwort:** Du tippst ein Wort ein. Kann erraten werden. Bots probieren Millionen davon.
- **SSH-Key:** Ein sehr langer, zufälliger Schlüssel (eine Datei auf deinem Laptop). Kann praktisch nicht erraten werden — es gibt mehr Möglichkeiten als Atome im Universum.

Der Key ist wie ein moderner Autoschlüssel mit Chip: Nur der eine passt, und es gibt keine Möglichkeit, ihn „durchzuprobieren". Deshalb schaltet das Script den Passwort-Login ab und lässt nur noch Keys zu. **Aber:** Das darf nur passieren, wenn dein Key schon funktioniert — sonst sperrst du dich aus. Das Script prüft das, bevor es etwas tut.

### Firewall — der Türsteher

Eine Firewall ist ein Programm, das vor allen Türen (Ports) deines Servers steht und entscheidet: **„Du darfst rein, du nicht."** Ohne Firewall ist jede Tür, hinter der ein Programm läuft, offen für alle.

Das Script stellt die Firewall so ein, dass nur die Türen offen sind, die offen sein müssen — Webseiten für alle, Verwaltung nur für dich.

### VPN — dein geheimer Tunnel

Ein VPN ist ein **privater, verschlüsselter Tunnel** zwischen deinem Gerät (Laptop, Handy) und deinem Server. Wenn du durch den Tunnel kommst, ist es so, als würdest du direkt neben dem Server sitzen.

Der Trick: **Wir machen das Coolify-Dashboard so, dass es nur noch durch den Tunnel erreichbar ist.** Von außen, aus dem normalen Internet, sieht man es gar nicht mehr. Die Bots finden keine Login-Seite, weil es für sie keine gibt. Nur wer durch den Tunnel kommt — also nur du mit deinem Schlüssel — sieht das Dashboard.

Das Script richtet dafür **WireGuard** ein (ein VPN-Programm) mit **wg-easy** (einer einfachen Oberfläche dafür). Auf dem Handy: WireGuard-App installieren, QR-Code scannen, ein Schalter zum Verbinden. Fertig.

### Warum kein Tailscale?

Vielleicht hast du schon von Tailscale gehört — ein sehr beliebtes, sehr einfaches VPN. Es hat einen Haken: Die „Vermittlungsstelle" läuft bei einer Firma in den USA. Für Privatprojekte ist das oft okay. Wenn du aber Kundendaten verarbeitest oder es einfach sauber nach DSGVO haben willst, ist das ein Problem. **wg-easy läuft komplett auf deinem eigenen Server.** Niemand außer dir ist beteiligt.

### Root — der Chef-Zugang

„Root" ist der Benutzer auf einem Linux-Server, der **alles darf**. Alles lesen, alles ändern, alles löschen. Coolify läuft mit Root-Rechten. Das Script auch — es muss ja Systemeinstellungen ändern. Deshalb: **Lies das Script, bevor du es ausführst.** Genau darum ist der Code öffentlich.

### Terminal — das schwarze Fenster

Das Programm, in dem du Befehle tippst. Auf dem Mac heißt es „Terminal", auf Windows nimmst du am besten „Windows Terminal" oder „PowerShell". Von dort aus verbindest du dich per SSH mit dem Server.

**Wichtig:** Coolify hat auch ein Terminal *im Dashboard* eingebaut. **Das darfst du für dieses Script nicht benutzen.** Warum? Weil das Script die Firewall ändert — und damit die Verbindung kappt, über die das Dashboard-Terminal läuft. Du würdest dir selbst den Ast absägen, auf dem du sitzt. Das Script erkennt das und bricht ab.

### Rescue-Konsole — der Notausgang

Jeder Hoster hat eine Möglichkeit, deinen Server zu bedienen, **die am Netzwerk vorbeigeht** — so, als würdest du physisch einen Bildschirm anschließen. Firewall und SSH sind dieser Konsole egal. Sie heißt je nach Hoster „Console", „VNC", „Rescue" oder „Remote Console".

**Das ist dein Rettungsanker.** Bevor das Script etwas Riskantes tut, fragt es dich, ob du diese Konsole offen hast. Sag nur „ja", wenn es stimmt. Wie du sie findest, steht in [NOTFALL.md](NOTFALL.md).

### Bash-Script — das, was du hier ausführst

Ein Script ist eine Textdatei mit Befehlen, die nacheinander ausgeführt werden. Statt dass du 200 Befehle selbst tippst (und dich an einer Stelle vertippst), macht das Script sie in der richtigen Reihenfolge. **Es ist nichts Magisches — du kannst es öffnen und lesen.** Jede Zeile ist ein Befehl, den du auch selbst tippen könntest.

---

## 6. Werkzeugkasten: Terminal und SSH — Schritt für Schritt

> Dieser Abschnitt ist für alle, die noch nie ein Terminal geöffnet oder sich per SSH irgendwo eingeloggt haben. Wenn du das schon kannst, spring zu [Abschnitt 7](#7-was-das-script-macht--schritt-für-schritt-erklärt). Alle anderen: Nimm dir 20 Minuten und mach es einmal mit. Danach kannst du es.

### 6.1 Das Terminal öffnen

Das Terminal ist ein Programm, das schon auf deinem Rechner ist. Du tippst einen Befehl, drückst Enter, der Computer antwortet mit Text. Kein Mausklick, keine Fenster — nur Text. Das wirkt am Anfang fremd, ist aber das Werkzeug, mit dem jeder Server auf der Welt verwaltet wird.

| Dein Rechner | So öffnest du das Terminal |
| --- | --- |
| **Mac** | `Cmd + Leertaste`, „Terminal" tippen, Enter. |
| **Windows 10/11** | Startmenü, „Terminal" oder „PowerShell" tippen, Enter. SSH ist seit Windows 10 eingebaut, du brauchst kein PuTTY mehr. |
| **Linux** | `Strg + Alt + T` oder „Terminal" im Anwendungsmenü. |
| **Handy / Tablet** | Geht (Termius, Blink, JuiceSSH), aber für das Script bitte einen richtigen Rechner. Du brauchst zwei Fenster nebeneinander. |

Du siehst eine Zeile mit deinem Benutzernamen und einem blinkenden Cursor. Das ist die **Eingabeaufforderung** (englisch: *Prompt*). Sie wartet auf dich.

Zum Warmwerden tipp das und drück Enter:

```bash
whoami
```

Der Computer antwortet mit deinem Benutzernamen. Glückwunsch, du hast gerade deinen ersten Befehl ausgeführt. Mehr ist es nicht: tippen, Enter, lesen.

**Vier Dinge, die du über das Terminal wissen musst:**

1. **Kopieren und Einfügen funktioniert anders.** Auf dem Mac wie immer (`Cmd + C` / `Cmd + V`). In Windows Terminal und Linux: `Strg + Shift + C` / `Strg + Shift + V` — oder Rechtsklick. `Strg + C` alleine bricht im Terminal den laufenden Befehl ab!
2. **Groß- und Kleinschreibung zählt.** `Install.sh` und `install.sh` sind zwei verschiedene Dateien.
3. **Beim Passwort-Eintippen siehst du nichts.** Keine Sternchen, keine Punkte. Das ist Absicht. Tippen, Enter — es funktioniert trotzdem.
4. **Wenn du nicht mehr weiterweißt:** `Strg + C` bricht ab. `exit` oder `Strg + D` schließt die Verbindung. Ein neues Fenster öffnen kannst du immer.

### 6.2 Die Adresse deines Servers finden

Dein Server hat eine **IP-Adresse** — vier Zahlen mit Punkten, etwa `203.0.113.42`. Sie steht im Panel deines Hosters (Hetzner: „Server" → dein Server → „IPv4"; Netcup, Contabo, IONOS: in der Serverübersicht). Schreib sie dir raus, du brauchst sie gleich.

Wenn dein Coolify schon über eine Domain läuft (z. B. `coolify.deine-domain.de`), kannst du die auch nehmen — sie zeigt auf dieselbe Adresse.

### 6.3 Der erste Login per SSH

Jetzt verbindest du dich zum ersten Mal. In deinem Terminal:

```bash
ssh root@203.0.113.42
```

Ersetz die Zahlen durch deine IP. `root` ist der Benutzername — bei den meisten frisch gemieteten Servern ist das der Anfangs-Benutzer. Das `@` heißt einfach „bei".

**Beim allerersten Mal kommt eine Frage, die viele erschreckt:**

```
The authenticity of host '203.0.113.42' can't be established.
ED25519 key fingerprint is SHA256:aBcDeF...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Übersetzt: „Ich kenne diesen Server noch nicht. Bist du sicher, dass das der richtige ist?" Dein Rechner merkt sich ab jetzt den „Fingerabdruck" des Servers und warnt dich, falls sich jemand später als dein Server ausgibt. Tipp `yes`, Enter. Diese Frage kommt pro Server nur einmal.

Dann fragt der Server nach dem Passwort (das aus der E-Mail deines Hosters oder das, was du bei der Bestellung festgelegt hast). Tippen — du siehst nichts — Enter.

Wenn es geklappt hat, sieht deine Eingabezeile jetzt anders aus, etwa `root@mein-server:~#`. **Du bist jetzt auf dem Server.** Alles, was du ab jetzt tippst, passiert dort, nicht auf deinem Laptop.

Probier:

```bash
hostname        # zeigt den Namen des Servers
docker ps       # zeigt die laufenden Container – da sollte "coolify" auftauchen
exit            # zurück auf deinen Laptop
```

### 6.4 Einen SSH-Key erzeugen

Bisher hast du dich mit Passwort eingeloggt. Das ist genau das, was die Bots auch versuchen. Jetzt bauen wir den Schlüssel, der nicht zu erraten ist.

**Auf deinem Laptop** (nicht auf dem Server — erst `exit`, falls du noch drauf bist):

```bash
ssh-keygen -t ed25519 -C "mein-laptop"
```

`ed25519` ist der moderne Schlüsseltyp. `-C "mein-laptop"` ist nur ein Kommentar, damit du den Key später wiedererkennst.

Es kommen drei Fragen:

1. **„Enter file in which to save the key"** — Enter drücken, der Vorschlag ist gut.
2. **„Enter passphrase"** — eine Passphrase ist ein Passwort *für den Schlüssel selbst*. Wenn jemand deinen Laptop klaut, kann er den Key ohne Passphrase sofort benutzen. Für deinen persönlichen Key: Passphrase setzen, gern einen ganzen Satz. Tippen, Enter, nochmal tippen, Enter.
3. Fertig. Du siehst ein kleines Zufallsbild aus Zeichen — das ist normal.

Jetzt liegen in deinem Benutzerordner unter `.ssh/` zwei Dateien:

| Datei | Was das ist | Regel |
| --- | --- | --- |
| `id_ed25519` | dein **privater** Schlüssel | **Niemals** weitergeben, nirgendwo hochladen, nicht in Chats einfügen. Bleibt auf deinem Laptop. |
| `id_ed25519.pub` | dein **öffentlicher** Schlüssel | Darf jeder sehen. Der kommt auf den Server. |

Der Trick dahinter: Der Server kennt nur den öffentlichen Teil. Damit kann er prüfen, ob du den privaten Teil hast — aber er kann daraus den privaten Teil nicht berechnen. Deshalb ist es egal, wenn der öffentliche Key irgendwo herumliegt.

Den öffentlichen Teil zeigst du dir so an:

```bash
cat ~/.ssh/id_ed25519.pub
```

Das ist eine einzige lange Zeile, die mit `ssh-ed25519 AAAA…` beginnt und mit `mein-laptop` endet. **Die ganze Zeile** ist dein öffentlicher Key. Kopier sie komplett (mit dem `ssh-ed25519` am Anfang und dem Kommentar am Ende).

### 6.5 Den Key auf den Server bringen

Drei Wege, vom einfachsten zum universellsten. Einer reicht.

**Weg A — mit einem Befehl (Mac / Linux):**

```bash
ssh-copy-id root@203.0.113.42
```

Fragt einmal nach dem Server-Passwort, kopiert den öffentlichen Key an die richtige Stelle. Fertig.

**Weg B — im Hoster-Panel:** Hetzner, Netcup und andere haben unter „SSH-Keys" oder „Sicherheit" ein Feld, in das du deinen öffentlichen Key einfügst. Das gilt dann meist nur für **neue** Server — für einen laufenden Server nimm A oder C.

**Weg C — von Hand (funktioniert überall, auch Windows):**

Einloggen wie in 6.3, dann auf dem Server:

```bash
mkdir -p ~/.ssh
nano ~/.ssh/authorized_keys
```

`nano` ist ein kleiner Texteditor im Terminal. Deine kopierte Key-Zeile einfügen (Rechtsklick oder `Strg + Shift + V`), dann `Strg + O` (speichern), Enter, `Strg + X` (beenden). Zum Schluss die Rechte setzen — SSH ist da pingelig:

```bash
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys
```

Die Datei `authorized_keys` ist einfach eine Liste: eine Zeile pro erlaubtem Schlüssel. Zweiter Laptop? Zweite Zeile.

### 6.6 Testen — der wichtigste Schritt

Neues Terminal-Fenster auf deinem Laptop, dann:

```bash
ssh root@203.0.113.42
```

Wenn du jetzt **nur nach der Passphrase deines Keys** gefragt wirst (oder gar nicht, falls du keine gesetzt hast) — und nicht mehr nach dem Server-Passwort — dann funktioniert dein Key. **Erst jetzt** darf das Script später den Passwort-Login abschalten. Das Preflight-Gate prüft das übrigens auch: Findet es keinen Key in `authorized_keys`, lässt es SSH in Ruhe.

Fragt er weiterhin nach dem Server-Passwort? Dann hat der Key nicht geklappt. Meistens: Zeile nicht komplett kopiert, oder die Rechte aus Weg C fehlen. Kein Drama — der Passwort-Login ist ja noch da. Nochmal 6.5.

### 6.7 Es dir leichter machen: die SSH-Config

Statt jedes Mal `ssh root@203.0.113.42` zu tippen, gibst du deinem Server einen Namen. Auf dem Laptop:

```bash
nano ~/.ssh/config
```

Reinschreiben:

```
Host coolify
    HostName 203.0.113.42
    User root
    IdentityFile ~/.ssh/id_ed25519
```

Speichern (`Strg + O`, Enter, `Strg + X`). Ab jetzt reicht:

```bash
ssh coolify
```

Das ist keine Kosmetik. Wenn dein Server nach dem Script nur noch durch den VPN-Tunnel erreichbar ist, trägst du hier einfach die Tunnel-Adresse ein und der Rest bleibt gleich.

### 6.8 `sudo` — „mach das als Chef"

Auf dem Server gibt es Befehle, die nur der Chef (Root) ausführen darf: Firewall ändern, Programme installieren, Systemdateien anfassen. Wenn du als `root` eingeloggt bist, darfst du das sowieso. Wenn du als normaler Benutzer eingeloggt bist, stellst du `sudo` davor:

```bash
sudo ./install.sh
```

Das heißt: „Führe `./install.sh` mit Chef-Rechten aus." Das `./` davor bedeutet „die Datei hier in diesem Ordner". Beides zusammen: „Starte die Datei install.sh aus diesem Ordner als Chef."

Falls du als `root` eingeloggt bist, schadet das `sudo` nicht — es ist dann einfach überflüssig.

### 6.9 Zwei Fenster — deine Lebensversicherung

Der Rückfall-Timer aus [Abschnitt 8](#8-der-rückfall-timer--warum-du-dich-nicht-aussperren-kannst) funktioniert nur, wenn du in einem **neuen** Fenster testest. Deshalb hier die Gewohnheit, die du dir angewöhnen solltest, bevor du irgendwas am Server änderst:

1. **Fenster 1:** eingeloggt, hier läuft das Script.
2. **Fenster 2:** leer, bereit. Sobald das Script „Teste JETZT" sagt: hier `ssh coolify` tippen.

Klappt der Login in Fenster 2 → zurück in Fenster 1, `--confirm`. Klappt er nicht → nichts tun, warten.

Warum das alte Fenster nicht zählt: Eine bestehende Verbindung ist wie jemand, der schon im Haus ist. Wenn du die Tür abschließt, bleibt er drin. Ob die Tür für *neue* Besucher aufgeht, siehst du nur, wenn jemand von außen klingelt — das ist Fenster 2.

### 6.10 Fehlermeldungen, die du sehen wirst — und was sie bedeuten

| Meldung | Bedeutet | Was tun |
| --- | --- | --- |
| `Connection refused` | Der Server antwortet, aber die SSH-Tür (Port 22) ist zu. | Firewall? Falscher Port? Nach dem Script: bist du im VPN-Tunnel? |
| `Connection timed out` | Keine Antwort. | IP falsch? Server aus? Firewall blockt komplett? → Rescue-Konsole, [NOTFALL.md](NOTFALL.md). |
| `Permission denied (publickey)` | Der Server will nur noch Keys, deiner passt nicht. | Key nicht hinterlegt oder falscher Key. Mit `ssh -i ~/.ssh/id_ed25519 …` den richtigen erzwingen. |
| `Permission denied, please try again` | Passwort falsch. | Nochmal. Beim Tippen siehst du nichts — das ist normal. |
| `Too many authentication failures` | Dein Rechner hat zu viele Keys angeboten. | `ssh -o IdentitiesOnly=yes -i ~/.ssh/id_ed25519 root@…` |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | Der Fingerabdruck passt nicht mehr zum gespeicherten. | Nach einer Neuinstallation des Servers normal. Sonst: stutzig werden. Die angegebene Zeile aus `~/.ssh/known_hosts` löschen. |
| `command not found` | Tippfehler oder Programm nicht installiert. | Befehl nochmal genau abtippen. Groß/Klein beachten. |
| `Permission denied` bei einem Befehl | Dir fehlen Chef-Rechte. | `sudo` davor. |
| `No such file or directory` | Die Datei ist nicht in diesem Ordner. | `pwd` zeigt, wo du bist; `ls` zeigt, was hier liegt; `cd coolify-shield` wechselt in den Ordner. |

### 6.11 Was da sonst noch auf dem Server läuft

Ein paar Namen, die dir im Script begegnen. Du musst sie nicht bedienen können — nur wissen, was sie sind.

**Docker und Container.** Docker verpackt jedes Programm in eine eigene abgeschlossene Kiste, den *Container*. Coolify läuft in einem Container, deine Apps laufen in Containern, das VPN wird ein Container. Vorteil: Sie kommen sich nicht in die Quere, und man kann sie einzeln starten, stoppen, löschen. `docker ps` zeigt, welche gerade laufen.

**Traefik.** Der Verteiler. Wenn ein Besucher `deine-app.de` aufruft, kommt die Anfrage an Port 80 oder 443 an — und Traefik schaut, welcher Container dafür zuständig ist, und reicht sie weiter. Coolify steuert Traefik für dich. Das Script legt Traefik später eine Regel hin: „Das Dashboard nur aus dem Tunnel ausliefern."

**wg-easy.** Das VPN-Programm als Container, mit einer kleinen Weboberfläche, auf der du Geräte anlegst und QR-Codes bekommst.

**systemd.** Der Dienst-Manager von Linux. Er startet Programme beim Hochfahren und — wichtig für uns — er kann **Timer** stellen. Der Rückfall-Timer ist ein systemd-Timer.

**ufw / firewalld.** Die Firewall-Programme. Welches dein Server hat, hängt vom Linux ab; das Script erkennt es.

**Logs.** Protokolldateien, in die Programme reinschreiben, was sie tun. Das Script schreibt nach `/var/log/coolify-shield.log`. Anschauen: `cat /var/log/coolify-shield.log` (alles) oder `tail -20 /var/log/coolify-shield.log` (die letzten 20 Zeilen).

### 6.12 Die zehn Befehle, die du wirklich brauchst

| Befehl | Macht |
| --- | --- |
| `ssh coolify` | verbinden |
| `exit` | Verbindung beenden |
| `pwd` | „Wo bin ich?" — zeigt den aktuellen Ordner |
| `ls` | „Was liegt hier?" — Dateien im Ordner |
| `cd coolify-shield` | in einen Ordner wechseln (`cd ..` = einen zurück) |
| `cat datei` | Datei anzeigen |
| `less datei` | Datei blätterbar anzeigen (`q` zum Beenden) |
| `nano datei` | Datei bearbeiten (`Strg + O` speichern, `Strg + X` raus) |
| `sudo befehl` | als Chef ausführen |
| `docker ps` | laufende Container zeigen |

Mehr brauchst du für coolify-shield nicht. Alles andere macht das Script.

---

## 7. Was das Script macht — Schritt für Schritt erklärt

Das Script läuft in **Phasen**. Jede Phase hat einen Namen, und nach jeder Phase sagt dir das Script, an welcher Stelle im Kurs es weitergeht. Hier ist, was in jeder Phase passiert und **warum**.

```mermaid
flowchart TD
    P0["Phase 0 · Preflight<br/><i>Darf ich hier loslegen?</i>"] --> P1["Phase 1 · Bestandsaufnahme<br/><i>Wie schlimm ist es?</i>"]
    P1 --> PA["Phase A · Grundlagen<br/>Auto-Updates · Brute-Force-Schutz"]
    PA --> B3["Phase B3 · VPN-Tunnel bauen<br/>⏱ mit Rückfall-Timer"]
    B3 --> B1["Phase B1 · SSH härten<br/>⏱ mit Rückfall-Timer"]
    B1 --> B2["Phase B2 · Firewall zu<br/>⏱ mit Rückfall-Timer"]
    B2 --> P9["Phase 9 · Report<br/>Score 0–100 + Restliste"]
    P9 --> DU["👆 Du: 2FA · Registrierung aus · Passwort"]
    style P0 fill:#455a64,color:#fff
    style P1 fill:#455a64,color:#fff
    style PA fill:#2e7d32,color:#fff
    style B3 fill:#ef6c00,color:#fff
    style B1 fill:#ef6c00,color:#fff
    style B2 fill:#ef6c00,color:#fff
    style P9 fill:#1565c0,color:#fff
```

### Phase 0 · Preflight — „Darf ich hier überhaupt loslegen?"

**Was passiert:** Das Script schaut sich um, **ändert aber nichts.** Es prüft:

- Bist du Root? (Sonst kann es nichts ändern.)
- Welches Linux läuft hier? (Ubuntu, Debian, Fedora … — das Script muss wissen, welche Befehle es benutzen darf.)
- Läuft Coolify überhaupt? (Sonst ergibt das Script keinen Sinn.)
- Bist du **per SSH** verbunden oder sitzt du im Coolify-Web-Terminal? (Im Web-Terminal: sofortiger Abbruch — siehe oben.)
- Ist ein SSH-Key hinterlegt? (Wenn nicht, wird der Passwort-Login später **nicht** abgeschaltet — sonst kämst du nie wieder rein.)
- Kann das Script einen Rückfall-Timer setzen? (Wenn nicht, macht es **nichts Riskantes**. Kein Netz, kein Sprung.)
- Hast du die Rescue-Konsole offen? (Es fragt dich. Antworte ehrlich.)

**Warum:** Fast jeder Server-Unfall passiert, weil jemand eine Änderung gemacht hat, für die die Voraussetzung fehlte. Das Script weigert sich einfach, in so einer Situation weiterzumachen. Wenn es abbricht, sagt es dir **in einem Satz**, was fehlt und was du tun sollst. Kein Fehlercode, kein Kauderwelsch.

### Phase 1 · Bestandsaufnahme — „Wie schlimm ist es gerade?"

**Was passiert:** Das Script prüft neun Dinge und zeigt dir eine Ampel:

- 🟢 Grün: passt
- 🟡 Gelb: sollte man machen
- 🔴 Rot: gefährlich, dringend

Geprüft wird zum Beispiel: Ist der Passwort-Login per SSH noch an? Läuft eine Firewall? Sind die Coolify-Türen (8000, 6001, 6002) von außen erreichbar? Gibt es Schutz gegen Passwort-Rateversuche? Werden Sicherheitsupdates automatisch eingespielt?

**Warum:** Damit du siehst, wo du stehst — und nachher, was sich verbessert hat. Und weil ein Script, das nur liest, nichts kaputtmachen kann. Diese Phase kannst du beliebig oft laufen lassen (`sudo ./install.sh --audit`).

### Phase A · Grundlagen — „Die Sachen, bei denen nichts schiefgehen kann"

**Was passiert:** Drei Dinge, die deinen Zugang **nicht** berühren und dich deshalb nicht aussperren können:

1. **Automatische Sicherheitsupdates.** Dein Server installiert Sicherheits-Patches nachts von selbst. Du musst nicht daran denken.
2. **Schutz gegen Passwort-Rateversuche (CrowdSec oder fail2ban).** Ein Programm beobachtet, wer sich falsch einloggen will. Wer es zu oft versucht, wird gesperrt. Die Bots aus Abschnitt 4 laufen damit ins Leere.
3. **Vorbereitung der Dashboard-Sperre.** Die Regel „Dashboard nur über VPN" wird schon geschrieben — aber **noch nicht eingeschaltet.** Das passiert erst, wenn der VPN-Tunnel nachweislich steht.

**Warum zuerst:** Weil es risikofrei ist. Selbst wenn du nach dieser Phase abbrichst, ist dein Server schon deutlich sicherer — und du hast nichts riskiert.

### Phase B3 · VPN — „Den geheimen Tunnel bauen"

**Was passiert:** Das Script installiert wg-easy (dein VPN), legt den ersten Zugang für dein Handy an und zeigt dir **direkt im Terminal einen QR-Code**. Den scannst du mit der WireGuard-App auf dem Handy. Ab dann kannst du mit einem Fingertipp „in den Tunnel" und bist damit quasi *im* Server-Netz.

**Warum vor der Firewall:** Das ist der wichtigste Punkt in der ganzen Reihenfolge. Wenn wir *erst* die Türen schließen und *dann* den Tunnel bauen wollen — haben wir keinen Weg mehr rein, um den Tunnel zu bauen. **Erst den Notausgang bauen, dann die Haustür abschließen.** Immer.

```mermaid
flowchart LR
    subgraph falsch["❌ Falsche Reihenfolge"]
        direction LR
        F1["Firewall zu"] --> F2["VPN bauen wollen"] --> F3["… kein Weg mehr rein.<br/>Ausgesperrt."]
    end
    subgraph richtig["✅ coolify-shield"]
        direction LR
        R1["VPN-Tunnel bauen"] --> R2["testen: komme ich<br/>durch den Tunnel?"] --> R3["erst dann:<br/>Firewall zu"]
    end
    style F3 fill:#c62828,color:#fff
    style R3 fill:#2e7d32,color:#fff
```

### Phase B1 · SSH härten — „Nur noch mit Schlüssel, nicht mehr mit Passwort"

**Was passiert:** Das Script ändert die SSH-Einstellungen so, dass:

- Passwort-Login **aus** ist (nur noch SSH-Keys)
- Root sich nicht mehr mit Passwort einloggen kann (nur noch mit Key — ganz abschalten geht nicht, Coolify braucht das für sich selbst)

Vorher wird die Einstellungsdatei gesichert. Danach wird geprüft, ob die Datei noch gültig ist. Erst dann wird SSH neu geladen — und zwar so, dass deine bestehende Verbindung **nicht** abbricht.

**Warum:** Der Passwort-Login ist die Tür, an der die Bots Tag und Nacht rütteln. Ohne Passwort-Login gibt es nichts zu rütteln.

**Mit Rückfall-Timer!** Siehe Abschnitt 7. Wenn du dich danach nicht mehr einloggen kannst, macht der Server es nach 10 Minuten von selbst rückgängig.

### Phase B2 · Firewall — „Alle Türen zu, außer denen, die offen sein müssen"

**Was passiert:** Der Türsteher bekommt seine Liste:

| Tür | Wer darf rein |
| --- | --- |
| Webseiten (80, 443) | alle — sonst sieht niemand deine Apps |
| VPN-Einwahl (51820) | alle — sonst kommst du nicht in den Tunnel |
| SSH (22) | nur aus dem Tunnel |
| Coolify-Dashboard (8000, 6001, 6002) | nur aus dem Tunnel |
| alles andere | niemand |

**Warum:** Damit das Coolify-Dashboard, das eigentliche Ziel, **aus dem Internet verschwindet.** Die Bots sehen: Port 80, Port 443, sonst nichts. Die Login-Seite, die sie suchen, existiert für sie nicht mehr.

**Mit Rückfall-Timer!** Auch hier: 10 Minuten. Wenn du dich ausgesperrt hast, geht die Firewall von selbst wieder auf.

### Phase 9 · Report — „Wie gut steht dein Server jetzt?"

**Was passiert:** Das Script schreibt eine HTML-Datei mit Ampel und einem **Sicherheits-Score von 0 bis 100**, plus einer Liste der Dinge, die du noch selbst im Dashboard klicken musst (Abschnitt 8).

**Warum:** Damit du ein Ergebnis in der Hand hast — und damit du beim nächsten Lauf siehst, was sich geändert hat.

---

## 8. Der Rückfall-Timer — warum du dich nicht aussperren kannst

Das ist der Teil, der coolify-shield von jeder Anleitung und jedem anderen Script unterscheidet. Bitte lies ihn ganz.

### Das Problem

Wenn du eine Firewall einschaltest oder den Passwort-Login abschaltest, kann Folgendes passieren: Du hast einen Fehler gemacht (Key nicht richtig hinterlegt, Tippfehler, falscher Port) — und **kommst nicht mehr auf deinen Server.** Die Tür ist zu und du stehst davor. Das ist die **häufigste Katastrophe** bei Coolify. Nicht Hacker. Sondern Admins, die sich selbst ausgesperrt haben.

### Die Lösung: Die Uhr läuft

Das Script benutzt einen Trick, den Netzwerk-Profis seit Jahrzehnten benutzen, wenn sie an Geräten arbeiten, die hunderte Kilometer entfernt stehen:

1. **Bevor** die riskante Änderung gemacht wird, stellt das Script einen **Timer auf 10 Minuten**. Der Timer hat einen Auftrag: „Wenn ich ablaufe, mache die Änderung rückgängig."
2. **Dann** wird die Änderung gemacht.
3. **Du** öffnest ein **zweites, neues** Terminal-Fenster und versuchst, dich neu einzuloggen.
4. **Klappt es?** Dann tippst du `sudo ./install.sh --confirm`. Das sagt dem Timer: „Alles gut, du kannst dich abschalten." Die Änderung bleibt.
5. **Klappt es nicht?** Dann tust du **gar nichts.** Du wartest. Nach 10 Minuten läuft der Timer ab, der Server macht die Änderung von selbst rückgängig, und du kommst wieder rein. Als wäre nichts gewesen.

```mermaid
flowchart TD
    A["⏱ Rückfall-Timer stellen<br/>10 Minuten"] --> B["Änderung durchführen<br/>z. B. Passwort-Login aus"]
    B --> C{"Du testest im<br/><b>NEUEN</b> Terminal-Fenster:<br/>komme ich noch rein?"}
    C -->|"✅ ja"| D["sudo ./install.sh --confirm"]
    D --> E["Timer aus.<br/>Änderung bleibt."]
    C -->|"❌ nein"| F["Nichts tun. Warten."]
    F --> G["Nach 10 Minuten:<br/>Server macht die Änderung<br/><b>von selbst rückgängig</b>"]
    G --> H["Du kommst wieder rein.<br/>Als wäre nichts gewesen."]
    style E fill:#2e7d32,color:#fff
    style H fill:#2e7d32,color:#fff
    style C fill:#f9a825,color:#000
```

### Die eine Sache, auf die 80 % reinfallen

> **Teste immer in einem NEUEN Fenster. Nie im alten.**

Warum? Eine SSH-Verbindung, die schon offen ist, **läuft weiter**, auch wenn neue Verbindungen blockiert sind. Dein altes Fenster funktioniert also immer — auch wenn du dich schon ausgesperrt hast. Wenn du im alten Fenster testest, alles funktioniert, und du `--confirm` drückst — ist der Timer aus, und beim nächsten Login stehst du vor verschlossener Tür.

Also: **Neues Fenster auf. Neu verbinden. Erst dann `--confirm`.**

### Und wenn wirklich alles schiefgeht?

Dann gibt es [NOTFALL.md](NOTFALL.md). Erster Schritt dort: **12 Minuten warten.** Meistens hat der Timer das Problem schon gelöst, bevor du in Panik gerätst. Wenn nicht: Rescue-Konsole beim Hoster, Schritt-für-Schritt-Anleitung steht drin.

---

## 9. Was du selbst klicken musst (und warum das Script das nicht kann)

Drei Dinge kann das Script **nicht** für dich erledigen. Nicht, weil es technisch unmöglich wäre — sondern weil es dafür in Coolifys interne Datenbank schreiben müsste. Und ein Script, das hunderte Leute auf ihren Servern laufen lassen, hat in einer fremden Datenbank **nichts zu suchen.** Wenn da etwas schiefgeht, ist dein Coolify kaputt. Das Risiko gehen wir nicht ein.

Deshalb: **3 Minuten Klickarbeit für dich.** Der Report listet sie dir am Ende auf.

### 1. Zwei-Faktor-Authentifizierung (2FA) einschalten

**Was es ist:** Zusätzlich zum Passwort brauchst du beim Login einen 6-stelligen Code, den eine App auf deinem Handy alle 30 Sekunden neu erzeugt. Selbst wenn jemand dein Passwort hat, kommt er ohne dein Handy nicht rein.

**Wie:** Im Coolify-Dashboard: **Profil → Two-factor Authentication → Configure.** QR-Code mit einer Authenticator-App scannen (z. B. Aegis, 2FAS, Google Authenticator, Microsoft Authenticator). Den Code eingeben, **Validate** klicken. Erst dann ist es aktiv.

**Ganz wichtig:** Du bekommst **Recovery-Codes** angezeigt. Das sind Notfall-Codes für den Fall, dass dein Handy weg ist. Speichere sie im Passwort-Manager. **Nicht** auf dem Server. **Nicht** auf demselben Handy wie die App. Wenn du diese Codes verlierst und dein Handy verlierst, bist du aus deinem eigenen Coolify ausgesperrt.

### 2. Registrierung abschalten

**Was es ist:** Coolify erlaubt am Anfang, dass sich beliebige Leute einen Account anlegen. Das ist für dich sinnlos und gefährlich.

**Wie:** **Settings → Registration Allowed → aus.**

### 3. Passwort tauschen

**Was es ist:** Wenn dein Coolify-Passwort kürzer als 20 Zeichen ist oder du es dir merken kannst, ist es zu schwach.

**Wie:** Passwort-Manager aufmachen (Bitwarden, 1Password, KeePass …), ein Passwort mit **25 oder mehr Zeichen** generieren lassen, in Coolify unter Profil ändern. Du musst es dir nicht merken — der Manager macht das.

**Warum so lang:** Dein Coolify-Passwort *ist* dein Root-Passwort. Behandle es so.

---

## 10. Der komplette Ablauf — was du wann tippst

Hier der ganze Weg, von Anfang bis Ende. Alle Befehle werden **auf dem Server** getippt, nachdem du dich per SSH verbunden hast.

### Vorbereitung (einmalig, ca. 10 Minuten)

1. **SSH-Key erstellen und hinterlegen.** Schritt für Schritt in [Abschnitt 6.4 bis 6.6](#64-einen-ssh-key-erzeugen), im Kurs in Modul 3. **Teste, dass der Login mit Key funktioniert, bevor du weitermachst.**
2. **Rescue-Konsole finden.** Bei deinem Hoster einloggen, die Konsole (siehe [NOTFALL.md](NOTFALL.md)) einmal öffnen, einmal einloggen. Tab offen lassen.
3. **Per SSH auf den Server.** In deinem Terminal auf dem Laptop, **nicht** im Coolify-Web-Terminal.

### Das Script holen

```bash
git clone https://github.com/oliverhees/coolify-shield.git
cd coolify-shield
```

Damit liegt das Script jetzt auf deinem Server. Mehr passiert in diesem Schritt nicht.

### Trockenlauf — nur schauen

```bash
sudo ./install.sh
```

`sudo` heißt „mach das als Chef". Ohne weitere Angabe macht das Script einen **Trockenlauf**: Es zeigt dir alles, was es tun *würde*, tut aber **nichts.** Jede Zeile, die mit `[trocken]` beginnt, ist ein Befehl, der nur angezeigt wurde. Lies die Ausgabe. Wenn etwas komisch aussieht: Frag in der Community, bevor du weitermachst.

### Wirklich ausführen

```bash
sudo ./install.sh --apply
```

Jetzt passiert es. Das Script stellt dir Fragen. **Die sicherste Antwort ist immer der Vorschlag in eckigen Klammern** — wenn du unsicher bist, drück einfach Enter. Vor jedem riskanten Schritt fragt es dich noch mal.

### Der Moment mit dem Timer

Wenn das Script sagt:

```
⏱  Watchdog scharf. In 10 Minuten wird "ssh" automatisch zurückgerollt.
   Teste JETZT in einem zweiten Terminal, ob du noch reinkommst.
```

dann:

1. **Neues** Terminal-Fenster auf deinem Laptop öffnen
2. Neu per SSH verbinden (bei der VPN-Phase: vorher den Tunnel auf dem Handy oder Laptop einschalten)
3. Klappt es → zurück ins erste Fenster, `sudo ./install.sh --confirm`
4. Klappt es nicht → **nichts tun**, 10 Minuten warten, dann nochmal versuchen

### Danach

```bash
sudo ./install.sh --status
```

zeigt dir, was erledigt ist. Der Report liegt unter `/root/coolify-shield-report.html`. Und dann: die drei Klicks aus Abschnitt 8.

### Wenn du alles rückgängig machen willst

```bash
sudo ./install.sh --undo
```

---

## 11. Was du danach anders machst

Ein paar Dinge ändern sich in deinem Alltag:

- **Ins Coolify-Dashboard kommst du nur noch durch den VPN-Tunnel.** Handy oder Laptop: WireGuard einschalten, dann die Dashboard-Adresse aufrufen. Ohne Tunnel: Seite lädt nicht. Das ist gewollt — das ist der Schutz.
- **SSH nur noch mit Key.** Wenn du einen neuen Laptop hast, brauchst du den Key dort. Passwort funktioniert nicht mehr.
- **Nach einem Coolify-Update das Script nochmal laufen lassen.** Coolify kann bei Updates ein paar Einstellungen überschreiben. Das Script erkennt, was noch passt, und repariert nur, was fehlt. Es macht nichts doppelt.
- **Zweites Gerät für den Tunnel anlegen.** In der wg-easy-Oberfläche kannst du weitere Zugänge anlegen (Laptop, zweites Handy). Zwei Geräte sind besser als eins — falls eins wegkommt.

---

## 12. Häufige Fragen

**Ich habe Angst, dass ich meinen Server kaputtmache.**
Deshalb gibt es den Trockenlauf, den Rückfall-Timer, die Backups und die Rescue-Konsole. Fünf Sicherheitsnetze. Wenn du die Reihenfolge einhältst (Key testen → Rescue-Konsole öffnen → Trockenlauf → `--apply` → im **neuen** Fenster testen → `--confirm`), kann faktisch nichts passieren, was sich nicht innerhalb von 10 Minuten von selbst repariert.

```mermaid
flowchart TD
    subgraph netz["Fünf Sicherheitsnetze — jedes fängt, was das vorherige durchlässt"]
        direction TB
        S1["1 · Trockenlauf als Standard<br/>ohne --apply passiert nichts"]
        S2["2 · Preflight-Gate<br/>fehlt eine Voraussetzung → Abbruch, bevor etwas geändert wird"]
        S3["3 · Rückfall-Timer<br/>riskante Änderung rollt nach 10 min von selbst zurück"]
        S4["4 · Backups + --undo<br/>jede Datei vorher gesichert"]
        S5["5 · Rescue-Konsole des Hosters<br/>geht am Netzwerk vorbei — NOTFALL.md"]
        S1 --> S2 --> S3 --> S4 --> S5
    end
    style S1 fill:#e3f2fd,color:#000
    style S2 fill:#bbdefb,color:#000
    style S3 fill:#90caf9,color:#000
    style S4 fill:#64b5f6,color:#000
    style S5 fill:#1e88e5,color:#fff
```

**Muss ich wirklich ein VPN? Reicht nicht 2FA?**
2FA schützt den Login. Das VPN versteckt ihn. Beides zusammen ist richtig gut. Nur 2FA ist okay, aber deine Login-Seite hängt weiter offen im Netz, und jede Software hat irgendwann eine Lücke. Wenn die Seite nicht erreichbar ist, kann die Lücke nicht ausgenutzt werden.

**Kann ich das Script mehrmals laufen lassen?**
Ja, beliebig oft. Was erledigt ist, wird übersprungen.

**Was ist, wenn ich Windows habe?**
Das Script läuft auf dem *Server* (Linux). Dein Laptop ist egal. Für SSH auf Windows: Windows Terminal oder PowerShell, beides hat SSH eingebaut.

**Das Script sagt „Das sieht nach dem Coolify-Web-Terminal aus".**
Du bist im Coolify-Web-Terminal. Das geht nicht (Abschnitt 5, „Terminal"). Öffne ein Terminal auf deinem Laptop und verbinde dich per SSH.

**Das Script sagt „Ich kann nicht erkennen, wie du mit dem Server verbunden bist".**
Kommt selten vor (z. B. in manchen Container- oder Hoster-Konsolen). Wenn du sicher bist, dass du per SSH von deinem Laptop verbunden bist: `sudo ./install.sh --force`.

**Das Script sagt „Kein SSH-Key gefunden".**
Dann wird die SSH-Phase übersprungen, alles andere läuft. Richte einen Key ein (Kurs Modul 3) und lass das Script danach nochmal laufen.

**Was ist mit meinen Apps, die auf dem Server laufen — gehen die kaputt?**
Nein. Die Ports 80 und 443, über die deine Apps erreichbar sind, bleiben offen. Nur die Verwaltungs-Türen werden geschlossen.

**Wo finde ich Hilfe?**
In der [AIIANER-Community](https://aiianer.de). Schick die Datei `/var/log/coolify-shield.log` mit — da steht jeder Schritt drin, und die Hälfte der Fragen ist damit schon beantwortet.

---

## 13. Glossar

| Begriff | Bedeutet |
| --- | --- |
| **authorized_keys** | Die Liste auf dem Server, in der die erlaubten öffentlichen Schlüssel stehen — eine Zeile pro Schlüssel |
| **Bot** | Automatisches Programm, das ohne Menschen im Internet Adressen abklopft und Passwörter probiert |
| **Brute Force** | „Rohe Gewalt": Passwörter so lange durchprobieren, bis eins passt |
| **Container** | Abgeschlossene „Kiste" für ein Programm (Docker). Coolify, deine Apps und das VPN laufen je in einem |
| **CrowdSec / fail2ban** | Programme, die Brute-Force-Versuche erkennen und den Angreifer sperren |
| **Dashboard** | Die Weboberfläche von Coolify |
| **DSGVO** | Datenschutz-Grundverordnung — das EU-Datenschutzgesetz. Relevant, sobald du Daten anderer Menschen verarbeitest |
| **Firewall** | Türsteher, der entscheidet, welche Ports für wen offen sind |
| **Hoster** | Die Firma, bei der du den Server gemietet hast |
| **IP-Adresse** | Die Nummer, unter der dein Server im Internet erreichbar ist, z. B. `203.0.113.42` |
| **Idempotent** | Kann beliebig oft laufen, ohne etwas doppelt zu tun oder kaputtzumachen |
| **Key (SSH-Key)** | Kryptografischer Schlüssel für den Login, der sich nicht erraten lässt |
| **Passphrase** | Passwort für deinen privaten SSH-Key. Schützt den Key, falls dein Laptop wegkommt |
| **Öffentlicher / privater Schlüssel** | Das Schlüsselpaar hinter SSH: der öffentliche kommt auf den Server, der private bleibt bei dir und wird nie weitergegeben |
| **Port** | Nummerierte „Tür" am Server, hinter der ein Dienst läuft |
| **Prompt** | Die Eingabezeile im Terminal, die auf deinen Befehl wartet |
| **Rescue-Konsole** | Notzugang beim Hoster, der am Netzwerk vorbeigeht |
| **Root** | Der Benutzer, der auf dem Server alles darf |
| **Rückfall-Timer / Watchdog** | Timer, der eine Änderung von selbst zurücknimmt, wenn du sie nicht bestätigst |
| **Script** | Textdatei mit Befehlen, die nacheinander ausgeführt werden |
| **SSH** | Verschlüsselte Fernsteuerung für deinen Server |
| **sudo** | „Führe diesen Befehl als Chef aus" |
| **systemd** | Dienst-Manager von Linux; stellt unter anderem den Rückfall-Timer |
| **Terminal** | Das Fenster, in dem du Befehle tippst |
| **Traefik** | Der „Verteiler" in Coolify, der eingehende Web-Anfragen an die richtige App weiterreicht |
| **Trockenlauf (Dry-Run)** | Zeigt, was passieren würde, tut aber nichts |
| **Tunnel / VPN** | Verschlüsselte Privatverbindung zwischen deinem Gerät und dem Server |
| **wg-easy** | Einfache Oberfläche für WireGuard, läuft auf deinem Server |
| **WireGuard** | Das VPN-Programm, das coolify-shield einrichtet |
| **2FA** | Zwei-Faktor-Authentifizierung: Passwort plus Code vom Handy |

---

<div align="center">

Fragen? → [AIIANER-Community](https://aiianer.de) · Ausgesperrt? → [NOTFALL.md](NOTFALL.md) · Technische Details? → [README.md](README.md)

</div>
