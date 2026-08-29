# Mitmachen

Danke, dass du hier bist. Ein paar Regeln, damit das Ding für Anfänger sicher bleibt.

## Die unverhandelbaren Regeln

1. **Jeder riskante Schritt bekommt einen Watchdog.** Alles, was SSH, Firewall oder Netzwerkzugang berührt, ruft `watchdog_arm` **vor** der Änderung auf. Kein Watchdog, kein Merge.
2. **Trockenlauf muss sauber durchlaufen.** Jeder ändernde Befehl geht durch `run`. Direktaufrufe von `apt-get`, `ufw`, `systemctl restart` etc. in den Phasen-Modulen sind nicht erlaubt.
3. **Nie direkt `apt-get`.** Pakete über `pkg_install`, Firewall über `$FIREWALL_TOOL`. Coolify läuft auf mehr als Debian.
4. **Ein Satz, kein Stacktrace.** Abbrüche über `die "<was fehlt>" "<was zu tun ist>"`.
5. **Jede angefasste Datei wird gesichert** — `backup_file` vor der ersten Änderung.
6. **Idempotent.** Vor jeder Aktion `state_has` prüfen, danach `state_set`.
7. **Reihenfolge VPN → SSH → Firewall** bleibt. Wer sie ändern will, braucht eine sehr gute Begründung im PR.
8. **Nichts in Coolifys Datenbank schreiben.** 2FA, Registrierung, Passwort bleiben Handarbeit des Nutzers.

## Vor dem PR

```bash
shellcheck -x -S warning install.sh lib/*.sh
for f in install.sh lib/*.sh; do bash -n "$f"; done
```

Beides muss grün sein. Die CI prüft es ebenfalls.

## Einen Stub ausbauen

Die Stubs in `lib/20-basics.sh`, `30-ssh.sh`, `40-firewall.sh`, `50-wireguard.sh` und `99-report.sh` enthalten die geplante Umsetzung als `# TODO:`-Kommentare. Halte dich an die Struktur (Rückfrage → Backup → Watchdog → Aktion → `state_set` → `course_cue`). Bitte einen Stub pro PR.

## Ein neues System nach Tier 1 bringen

Teste auf dem System mit echtem Coolify:

1. `sudo ./install.sh --audit` — Ausgabe in das Issue
2. `sudo ./install.sh` (Trockenlauf) — Ausgabe in das Issue
3. Sobald Phasen implementiert sind: `--apply`, dann `--confirm` aus einem **neuen** Terminal
4. `/var/log/coolify-shield.log` anhängen (IPs schwärzen)

Dann rückt das System in `detect_system` nach Tier 1.

## Sprache

Code-Kommentare, Ausgaben und Doku sind Deutsch — die Zielgruppe ist die DACH-Community. Variablen- und Funktionsnamen dürfen gemischt sein, die bestehenden Konventionen (`phase_*`, `state_*`, `watchdog_*`) beibehalten.

## Sicherheitsprobleme

Nicht als Issue, sondern nach [SECURITY.md](SECURITY.md).
