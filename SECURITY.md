# Sicherheitslücken melden

coolify-shield läuft als root auf fremden Servern. Eine Lücke hier ist keine Kleinigkeit.

**Bitte nicht als öffentliches Issue melden.**

## So geht es richtig

1. E-Mail an **support@aiianer.de**, Betreff `[coolify-shield] Security`.
2. Beschreibe, was du gefunden hast, auf welchem System (Distro, Version, Coolify-Version) und wie es sich reproduzieren lässt. Ein Auszug aus `/var/log/coolify-shield.log` hilft — bitte vorher IPs und Hostnamen schwärzen.
3. Du bekommst innerhalb von **72 Stunden** eine Antwort. Bis ein Fix veröffentlicht ist, bitten wir um Vertraulichkeit.

## Was als Sicherheitslücke zählt

- Ein Weg, wie das Script den Zugang kappen kann, **ohne** dass vorher ein Watchdog scharf ist
- Ein Preflight-Check, der sich umgehen lässt und dadurch eine riskante Phase ohne Vorbedingung startet
- Unsichere Verarbeitung von Nutzereingaben (Subnetz, Port, Passwort) — Injection in Shell-Befehle, Klartext-Passwörter in Logs oder Zustandsdateien
- Backups oder Zustandsdateien mit zu weiten Berechtigungen
- Alles, was dazu führt, dass am Ende weniger dicht ist als vorher

## Was kein Sicherheitsproblem ist

- Ein Stub, der noch nicht implementiert ist (siehe Status in der README)
- Das Script funktioniert auf einem Tier-0-System nicht

Danke, dass du hinschaust.
