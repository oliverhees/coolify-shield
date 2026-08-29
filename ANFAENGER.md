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
6. [Was das Script macht — Schritt für Schritt erklärt](#6-was-das-script-macht--schritt-für-schritt-erklärt)
7. [Der Rückfall-Timer — warum du dich nicht aussperren kannst](#7-der-rückfall-timer--warum-du-dich-nicht-aussperren-kannst)
8. [Was du selbst klicken musst (und warum das Script das nicht kann)](#8-was-du-selbst-klicken-musst-und-warum-das-script-das-nicht-kann)
9. [Der komplette Ablauf — was du wann tippst](#9-der-komplette-ablauf--was-du-wann-tippst)
10. [Was du danach anders machst](#10-was-du-danach-anders-machst)
11. [Häufige Fragen](#11-häufige-fragen)
12. [Glossar](#12-glossar)

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

## 6. Was das Script macht — Schritt für Schritt erklärt

Das Script läuft in **Phasen**. Jede Phase hat einen Namen, und nach jeder Phase sagt dir das Script, an welcher Stelle im Kurs es weitergeht. Hier ist, was in jeder Phase passiert und **warum**.

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

## 7. Der Rückfall-Timer — warum du dich nicht aussperren kannst

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

```
Timer stellen (10 min)  →  Änderung machen  →  du testest im NEUEN Fenster
                                                  ├─ klappt:       --confirm  → Änderung bleibt
                                                  └─ klappt nicht: nichts tun → in 10 min alles zurück
```

### Die eine Sache, auf die 80 % reinfallen

> **Teste immer in einem NEUEN Fenster. Nie im alten.**

Warum? Eine SSH-Verbindung, die schon offen ist, **läuft weiter**, auch wenn neue Verbindungen blockiert sind. Dein altes Fenster funktioniert also immer — auch wenn du dich schon ausgesperrt hast. Wenn du im alten Fenster testest, alles funktioniert, und du `--confirm` drückst — ist der Timer aus, und beim nächsten Login stehst du vor verschlossener Tür.

Also: **Neues Fenster auf. Neu verbinden. Erst dann `--confirm`.**

### Und wenn wirklich alles schiefgeht?

Dann gibt es [NOTFALL.md](NOTFALL.md). Erster Schritt dort: **12 Minuten warten.** Meistens hat der Timer das Problem schon gelöst, bevor du in Panik gerätst. Wenn nicht: Rescue-Konsole beim Hoster, Schritt-für-Schritt-Anleitung steht drin.

---

## 8. Was du selbst klicken musst (und warum das Script das nicht kann)

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

## 9. Der komplette Ablauf — was du wann tippst

Hier der ganze Weg, von Anfang bis Ende. Alle Befehle werden **auf dem Server** getippt, nachdem du dich per SSH verbunden hast.

### Vorbereitung (einmalig, ca. 10 Minuten)

1. **SSH-Key erstellen und hinterlegen.** Wie das geht, zeigt der Kurs (Modul 3). Kurzversion: Auf deinem Laptop `ssh-keygen -t ed25519` tippen, dann den öffentlichen Teil beim Hoster oder auf dem Server hinterlegen. **Teste, dass der Login mit Key funktioniert, bevor du weitermachst.**
2. **Rescue-Konsole finden.** Bei deinem Hoster einloggen, die Konsole (siehe [NOTFALL.md](NOTFALL.md)) einmal öffnen, einmal einloggen. Tab offen lassen.
3. **Per SSH auf den Server.** In deinem Terminal auf dem Laptop, **nicht** im Coolify-Web-Terminal.

### Das Script holen und lesen

```bash
git clone https://github.com/oliverhees/coolify-shield.git
cd coolify-shield
less install.sh
```

`less` zeigt dir die Datei an. Mit den Pfeiltasten scrollen, mit `q` beenden. Du musst nicht alles verstehen — aber du sollst sehen, dass es normale Befehle sind und kein Zauber. **Ein Script, das als Chef auf deinem Server läuft, führst du nie blind aus.**

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

## 10. Was du danach anders machst

Ein paar Dinge ändern sich in deinem Alltag:

- **Ins Coolify-Dashboard kommst du nur noch durch den VPN-Tunnel.** Handy oder Laptop: WireGuard einschalten, dann die Dashboard-Adresse aufrufen. Ohne Tunnel: Seite lädt nicht. Das ist gewollt — das ist der Schutz.
- **SSH nur noch mit Key.** Wenn du einen neuen Laptop hast, brauchst du den Key dort. Passwort funktioniert nicht mehr.
- **Nach einem Coolify-Update das Script nochmal laufen lassen.** Coolify kann bei Updates ein paar Einstellungen überschreiben. Das Script erkennt, was noch passt, und repariert nur, was fehlt. Es macht nichts doppelt.
- **Zweites Gerät für den Tunnel anlegen.** In der wg-easy-Oberfläche kannst du weitere Zugänge anlegen (Laptop, zweites Handy). Zwei Geräte sind besser als eins — falls eins wegkommt.

---

## 11. Häufige Fragen

**Ich habe Angst, dass ich meinen Server kaputtmache.**
Deshalb gibt es den Trockenlauf, den Rückfall-Timer, die Backups und die Rescue-Konsole. Vier Sicherheitsnetze. Wenn du die Reihenfolge einhältst (Key testen → Rescue-Konsole öffnen → Trockenlauf → `--apply` → im **neuen** Fenster testen → `--confirm`), kann faktisch nichts passieren, was sich nicht innerhalb von 10 Minuten von selbst repariert.

**Muss ich wirklich ein VPN? Reicht nicht 2FA?**
2FA schützt den Login. Das VPN versteckt ihn. Beides zusammen ist richtig gut. Nur 2FA ist okay, aber deine Login-Seite hängt weiter offen im Netz, und jede Software hat irgendwann eine Lücke. Wenn die Seite nicht erreichbar ist, kann die Lücke nicht ausgenutzt werden.

**Kann ich das Script mehrmals laufen lassen?**
Ja, beliebig oft. Was erledigt ist, wird übersprungen.

**Was ist, wenn ich Windows habe?**
Das Script läuft auf dem *Server* (Linux). Dein Laptop ist egal. Für SSH auf Windows: Windows Terminal oder PowerShell, beides hat SSH eingebaut.

**Warum kein `curl | bash`, wie bei anderen Tools?**
Weil das „führe aus, ohne hinzusehen" bedeutet. Bei einem Tool, das als Chef auf deinem Server läuft, ist das genau die falsche Gewohnheit. Erst holen, dann lesen, dann ausführen.

**Das Script sagt „Du sitzt nicht in einer SSH-Sitzung".**
Du bist im Coolify-Web-Terminal. Das geht nicht (Abschnitt 5, „Terminal"). Öffne ein Terminal auf deinem Laptop und verbinde dich per SSH.

**Das Script sagt „Kein SSH-Key gefunden".**
Dann wird die SSH-Phase übersprungen, alles andere läuft. Richte einen Key ein (Kurs Modul 3) und lass das Script danach nochmal laufen.

**Was ist mit meinen Apps, die auf dem Server laufen — gehen die kaputt?**
Nein. Die Ports 80 und 443, über die deine Apps erreichbar sind, bleiben offen. Nur die Verwaltungs-Türen werden geschlossen.

**Wo finde ich Hilfe?**
In der [AIIANER-Community](https://aiianer.de). Schick die Datei `/var/log/coolify-shield.log` mit — da steht jeder Schritt drin, und die Hälfte der Fragen ist damit schon beantwortet.

---

## 12. Glossar

| Begriff | Bedeutet |
| --- | --- |
| **Bot** | Automatisches Programm, das ohne Menschen im Internet Adressen abklopft und Passwörter probiert |
| **Brute Force** | „Rohe Gewalt": Passwörter so lange durchprobieren, bis eins passt |
| **CrowdSec / fail2ban** | Programme, die Brute-Force-Versuche erkennen und den Angreifer sperren |
| **Dashboard** | Die Weboberfläche von Coolify |
| **DSGVO** | Datenschutz-Grundverordnung — das EU-Datenschutzgesetz. Relevant, sobald du Daten anderer Menschen verarbeitest |
| **Firewall** | Türsteher, der entscheidet, welche Ports für wen offen sind |
| **Hoster** | Die Firma, bei der du den Server gemietet hast |
| **Idempotent** | Kann beliebig oft laufen, ohne etwas doppelt zu tun oder kaputtzumachen |
| **Key (SSH-Key)** | Kryptografischer Schlüssel für den Login, der sich nicht erraten lässt |
| **Port** | Nummerierte „Tür" am Server, hinter der ein Dienst läuft |
| **Rescue-Konsole** | Notzugang beim Hoster, der am Netzwerk vorbeigeht |
| **Root** | Der Benutzer, der auf dem Server alles darf |
| **Rückfall-Timer / Watchdog** | Timer, der eine Änderung von selbst zurücknimmt, wenn du sie nicht bestätigst |
| **Script** | Textdatei mit Befehlen, die nacheinander ausgeführt werden |
| **SSH** | Verschlüsselte Fernsteuerung für deinen Server |
| **sudo** | „Führe diesen Befehl als Chef aus" |
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
