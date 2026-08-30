#!/usr/bin/env bash
# Phase S4 :: Eigener Admin-Benutzer statt root
#
# root bleibt per Schluessel erreichbar (prohibit-password), weil Coolify
# sich selbst ueber SSH verwaltet. Fuer dich gibt es ab jetzt einen eigenen
# Benutzer mit sudo. Kein Passwort: Login nur per Schluessel, sudo ohne
# Passwortabfrage. Ein Passwort, das man nie tippt, vergisst man nur.

phase_adminuser() {
  step "Phase 4 · Dein eigener Benutzer"
  if state_has "phase.adminuser"; then
    skip "Benutzer $(state_get adminuser.name) – bereits angelegt"
    return 0
  fi
  say "  Als root zu arbeiten ist wie mit dem Generalschluessel einkaufen gehen."
  say "  Du bekommst einen eigenen Benutzer, der bei Bedarf Chef-Rechte holt (sudo)."
  printf '\n'

  local name
  while :; do
    name="$(ask_value 'Wie soll dein Benutzer heissen?' 'admin')"
    [[ "$name" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] && break
    warn "Nur Kleinbuchstaben, Ziffern, - und _ (Start mit Buchstabe)."
  done

  if id "$name" >/dev/null 2>&1; then
    skip "Benutzer $name existiert schon, Rechte werden nur ergaenzt"
  else
    run useradd -m -s /bin/bash "$name"
  fi
  run usermod -aG sudo "$name"
  getent group docker >/dev/null 2>&1 && run usermod -aG docker "$name"

  write_file "/etc/sudoers.d/coolify-shield-$name" 440 <<SUDO
# coolify-shield: $name darf sudo ohne Passwort (Login ist nur per Schluessel moeglich)
$name ALL=(ALL) NOPASSWD:ALL
SUDO
  if [ "$DRY_RUN" != "1" ] && ! visudo -cf "/etc/sudoers.d/coolify-shield-$name" >/dev/null 2>&1; then
    rm -f "/etc/sudoers.d/coolify-shield-$name"
    die "Die sudo-Regel war fehlerhaft und wurde entfernt." "Bitte nochmal starten."
  fi

  # Schluessel von root uebernehmen, damit derselbe Laptop-Schluessel gilt.
  local home="/home/$name"
  run install -d -m 700 -o "$name" -g "$name" "$home/.ssh"
  if [ -s /root/.ssh/authorized_keys ]; then
    run install -m 600 -o "$name" -g "$name" /root/.ssh/authorized_keys "$home/.ssh/authorized_keys"
    ok "Dein SSH-Schluessel gilt jetzt auch fuer $name"
  else
    warn "root hat keinen SSH-Schluessel hinterlegt. $name kann sich so nicht einloggen."
  fi

  state_set "adminuser.name" "$name"
  state_set "phase.adminuser" "$(date -Iseconds)"
  laptop_env_set "admin_user" "$name"
  laptop_env_set "phase" "adminuser"
  next_up "Benutzer $name mit sudo angelegt, Schluessel uebernommen" \
          "Dein Laptop-Script loggt sich ab jetzt als $name ein. Dann bauen wir den VPN-Tunnel." \
          "Nichts. Das Laptop-Script stellt das selbst um."
}
