#!/usr/bin/env bash
# Phase B1 :: SSH haerten, MIT WATCHDOG
#
# Nur noch Schluessel, kein Passwort. root bleibt per Schluessel erlaubt
# (prohibit-password), weil Coolify sich selbst per SSH verwaltet.
# Port bleibt 22: ein Port-Wechsel bringt fast nichts und ist die haeufigste
# Aussperr-Ursache bei Anfaengern.
#
# Bei sshd gewinnt der ERSTE Wert einer Direktive. Deshalb heisst das Drop-in
# 00-… und liegt damit vor 50-cloud-init.conf. Nach dem Reload wird mit
# sshd -T hart nachgeprueft, was wirklich gilt.

SSHD_DROPIN="/etc/ssh/sshd_config.d/00-coolify-shield.conf"

ssh_reload() {
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null \
    || systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null
}

phase_ssh() {
  step "Phase 7 · SSH absichern"
  if state_has "phase.ssh" && [ -f "$SSHD_DROPIN" ]; then
    skip "SSH bereits abgesichert"
    return 0
  fi

  # Harte Vorbedingung: ohne hinterlegten Schluessel wird nichts angefasst.
  local keys=0 f
  for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
    [ -f "$f" ] && keys=$(( keys + $(grep -cv '^\s*\(#\|$\)' "$f" 2>/dev/null || echo 0) ))
  done
  if [ "$keys" -eq 0 ]; then
    warn "Kein SSH-Schluessel hinterlegt. SSH wird NICHT umgestellt, sonst sperrst du dich aus."
    next_up "SSH unveraendert gelassen (kein Schluessel)" "Firewall." \
            "Spaeter einen Schluessel hinterlegen und sudo /opt/coolify-shield/install.sh --setup erneut starten."
    return 0
  fi

  say "  Passwort-Login wird abgeschaltet. Nur noch dein Schluessel kommt rein."
  say "  Sicherheitsnetz: Klappt dein Login in 10 Minuten nicht, wird es von selbst"
  say "  rueckgaengig gemacht."
  printf '\n'
  ask_yn "SSH jetzt absichern?" "j" || { skip "Phase uebersprungen"; return 0; }

  # Watchdog VOR der Aenderung scharf machen. Rollback laedt sshd aktiv neu.
  watchdog_arm "ssh" 10 \
    "rm -f $SSHD_DROPIN; sshd -t && (systemctl reload ssh || systemctl reload sshd || systemctl restart ssh || systemctl restart sshd)"

  mkdir -p /etc/ssh/sshd_config.d
  write_file "$SSHD_DROPIN" 644 <<'CONF'
# coolify-shield: nur Schluessel-Login. Erster Wert gewinnt, daher 00-.
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin prohibit-password
PubkeyAuthentication yes
MaxAuthTries 3
X11Forwarding no
CONF

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s sshd -t, systemctl reload ssh, sshd -T nachpruefen\n' "$C_DIM" "$C_RESET"
  else
    if ! sshd -t 2>/dev/null; then
      rm -f "$SSHD_DROPIN"
      watchdog_disarm "ssh"
      die "Die neue SSH-Konfiguration war fehlerhaft und wurde sofort entfernt." "Nichts hat sich geaendert. Ausgabe in der Community posten."
    fi
    ssh_reload || die "SSH-Dienst liess sich nicht neu laden." "Der Rueckfall-Timer raeumt in 10 Minuten auf."
    # Hart nachpruefen, was jetzt wirklich gilt.
    local pw root_login
    pw="$(sshd -T 2>/dev/null | awk '/^passwordauthentication /{print $2}')"
    root_login="$(sshd -T 2>/dev/null | awk '/^permitrootlogin /{print $2}')"
    if [ "$pw" != "no" ] || [ "$root_login" != "prohibit-password" ]; then
      warn "sshd meldet passwordauthentication=$pw, permitrootlogin=$root_login. Etwas anderes ueberstimmt uns."
      warn "Bitte in der Community melden: grep -r PasswordAuthentication /etc/ssh/"
    else
      ok "Passwort-Login aus, root nur per Schluessel"
    fi
  fi

  state_set "phase.ssh" "$(date -Iseconds)"
  laptop_env_set "phase" "ssh"
  laptop_env_set "watchdog" "ssh"
  next_up "SSH nimmt nur noch deinen Schluessel an" \
          "Dein Laptop-Script testet den Login neu und bestaetigt, dann kommt die Firewall." \
          "Nichts. Wenn der Test klappt, entschaerft das Laptop-Script den Timer."
}
