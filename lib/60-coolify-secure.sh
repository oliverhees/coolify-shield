#!/usr/bin/env bash
# Phase S5 :: Coolify selbst absichern (Registrierung aus, 2FA an)
#
# Das kann kein Script klicken. Aber es kann nachsehen, ob es passiert ist:
# beides steht in Coolifys Datenbank.

coolify_reg_disabled() {
  [ "$(coolify_psql 'select is_registration_enabled from instance_settings limit 1;' 2>/dev/null)" = "f" ]
}
coolify_2fa_users() {
  coolify_psql 'select count(*) from users where two_factor_confirmed_at is not null;' 2>/dev/null || echo 0
}

phase_coolify_secure() {
  step "Phase 9 · Coolify absichern"
  if state_has "phase.coolify_secure"; then
    skip "Coolify-Einstellungen bereits geprueft"
    return 0
  fi
  say "  Zwei Klicks, die kein Script fuer dich machen kann. Ich pruefe danach, ob sie sitzen."
  printf '\n'
  printf '  %sDashboard jetzt nur noch ueber den Tunnel:%s  http://%s:8000\n' "$C_BOLD" "$C_RESET" "$WG_SERVER_IP"
  printf '  (Tunnel auf dem Laptop an, dann diese Adresse im Browser)\n\n'
  printf '  1. %sRegistrierung aus:%s  Settings → "Registration Allowed" ausschalten → Save\n' "$C_BOLD" "$C_RESET"
  printf '  2. %sZwei-Faktor an:%s     oben rechts Profil → "Two-factor Authentication" → Enable,\n' "$C_BOLD" "$C_RESET"
  printf '     QR mit einer Authenticator-App scannen, Code eingeben, Wiederherstellungscodes speichern\n\n'

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s wuerde in der Coolify-Datenbank nachsehen\n' "$C_DIM" "$C_RESET"
    state_set "phase.coolify_secure" "$(date -Iseconds)"
    return 0
  fi

  local versuch=0 reg=1 tfa=0
  while [ "$versuch" -lt 3 ]; do
    pause_enter
    coolify_reg_disabled && reg=0 || reg=1
    tfa="$(coolify_2fa_users)"
    [ "$reg" -eq 0 ] && ok "Registrierung ist aus" || warn "Registrierung ist noch an"
    [ "${tfa:-0}" -ge 1 ] 2>/dev/null && ok "Zwei-Faktor ist fuer $tfa Nutzer aktiv" || warn "Zwei-Faktor ist noch bei keinem Nutzer aktiv"
    { [ "$reg" -eq 0 ] && [ "${tfa:-0}" -ge 1 ]; } && break
    versuch=$(( versuch + 1 ))
    [ "$versuch" -lt 3 ] && say "  Bitte nachholen, dann Enter. (Versuch $versuch von 3)"
  done
  if [ "$reg" -ne 0 ] || [ "${tfa:-0}" -lt 1 ]; then
    warn "Ich mache weiter, aber das bleibt offen. Du siehst es im Report."
    state_set "coolify_secure.offen" "1"
  fi
  state_set "phase.coolify_secure" "$(date -Iseconds)"
  laptop_env_set "phase" "coolify_secure"
  next_up "Coolify-Einstellungen geprueft" "Abschlussbericht."
}
