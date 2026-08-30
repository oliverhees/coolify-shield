#!/usr/bin/env bash
# Phase S2 :: Coolify installieren   +   Phase S3 :: Account anlegen
#
# Der Account kommt SOFORT nach der Installation, nicht am Ende:
# Der erste registrierte Nutzer ist der Admin. Solange niemand registriert
# ist, kann das jeder aus dem Internet tun.

COOLIFY_INSTALLER="https://cdn.coollabs.io/coolify/install.sh"

phase_coolify() {
  step "Phase 2 · Coolify installieren"
  if coolify_running; then
    skip "Coolify laeuft bereits"
    state_has "phase.coolify" || state_set "phase.coolify" "$(date -Iseconds)"
    return 0
  fi
  say "  Coolify wird mit dem offiziellen Installer eingerichtet."
  say "  Docker kommt dabei automatisch mit. Dauer: 3 bis 5 Minuten."
  printf '\n'

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s curl -fsSL %s | bash\n' "$C_DIM" "$C_RESET" "$COOLIFY_INSTALLER"
  else
    if ! curl -fsSL "$COOLIFY_INSTALLER" | bash; then
      die "Der Coolify-Installer ist abgebrochen." \
          "Einfach nochmal starten. Bleibt es dabei: Ausgabe oben in der Community posten."
    fi
    printf '  Warte, bis Coolify antwortet '
    if ! wait_http "http://127.0.0.1:8000" 300; then
      die "Coolify antwortet nach 5 Minuten nicht auf Port 8000." \
          "docker logs coolify zeigt, was los ist. Ausgabe in der Community posten."
    fi
    printf '\n'
  fi
  ok "Coolify laeuft"
  state_set "phase.coolify" "$(date -Iseconds)"
  laptop_env_set "phase" "coolify"
  next_up "Coolify ist installiert und antwortet" \
          "Du legst deinen Coolify-Account an. Das muss jetzt sofort passieren."
}

phase_account() {
  step "Phase 3 · Dein Coolify-Account"
  if state_has "phase.account"; then
    skip "Account – bereits angelegt"
    return 0
  fi
  local ip; ip="$(public_ip)"
  laptop_env_set "server_ip" "$ip"

  say "  Warum jetzt und nicht spaeter: Der ERSTE Account in Coolify ist der Chef."
  say "  Solange der nicht existiert, koennte ihn jeder aus dem Internet anlegen."
  printf '\n'
  printf '  %sOeffne im Browser:%s  http://%s:8000\n' "$C_BOLD" "$C_RESET" "$ip"
  printf '  Klicke auf %sRegister%s, gib Name, E-Mail und ein langes Passwort ein\n' "$C_BOLD" "$C_RESET"
  printf '  (am besten aus dem Passwort-Manager, 25+ Zeichen).\n'
  printf '  Wenn du das Dashboard siehst, bist du fertig. Die Einrichtungs-\n'
  printf '  Fragen dort kannst du erst mal ueberspringen.\n\n'

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s wuerde warten, bis in Coolify ein Nutzer existiert\n' "$C_DIM" "$C_RESET"
  else
    local n
    while :; do
      pause_enter
      n="$(coolify_psql 'select count(*) from users;' || echo 0)"
      if [ "${n:-0}" -ge 1 ] 2>/dev/null; then
        ok "Account gefunden ($n Nutzer in Coolify)"
        break
      fi
      warn "In Coolify ist noch kein Nutzer angelegt. Bitte erst registrieren, dann Enter."
    done
  fi
  state_set "phase.account" "$(date -Iseconds)"
  laptop_env_set "phase" "account"
  next_up "Dein Coolify-Account existiert, du bist der Admin" \
          "Der Server bekommt einen eigenen Benutzer fuer dich, damit du nicht als root arbeitest."
}
