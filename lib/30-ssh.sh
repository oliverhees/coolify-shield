#!/usr/bin/env bash
# Phase B :: SSH-Haertung — MIT WATCHDOG
#
# STATUS: STUB. Watchdog-Verdrahtung steht, Aktionen fehlen.

phase_ssh() {
  step "Phase B1 · SSH haerten"

  # Harte Vorbedingung: ohne hinterlegten Key wird hier gar nichts angefasst.
  if [ "$(state_get 'ssh.keys')" = "0" ]; then
    warn "Kein SSH-Key hinterlegt – Phase uebersprungen."
    say  "  Erst einen Key einrichten (Kurs Modul 3), sonst sperrst du dich aus."
    return 0
  fi

  say "  Passwortlogin und Root-Passwortlogin werden abgeschaltet."
  say "  Ein Rueckfall-Timer macht das nach 10 Minuten wieder rueckgaengig,"
  say "  falls du dich nicht mehr einloggen kannst."
  printf '\n'
  ask_yn "Weiter?" "n" || { skip "Phase B1 uebersprungen"; return 0; }

  backup_file /etc/ssh/sshd_config

  # Watchdog VOR der Aenderung scharf machen. Reihenfolge ist nicht optional.
  watchdog_arm "ssh" 10 \
    "cp -a $BACKUP_DIR/\$(ls -t $BACKUP_DIR | grep sshd_config | head -1) /etc/ssh/sshd_config && systemctl reload sshd"

  # TODO: PasswordAuthentication no
  # TODO: PermitRootLogin prohibit-password
  # TODO: KbdInteractiveAuthentication no
  # TODO: sshd -t  (Syntaxpruefung!) vor dem reload — schlaegt sie fehl: sofort zurueck
  # TODO: systemctl reload sshd   (reload, nicht restart – bestehende Sitzung ueberlebt)
  warn "STUB: SSH-Haertung noch nicht implementiert"

  state_set "phase.ssh" "$(date -Iseconds)"
  course_cue "Modul 3 · ab 04:12"
}
