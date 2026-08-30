#!/usr/bin/env bash
# Phase S1 :: Updates und Grundpakete (nur im gefuehrten Ablauf --setup)
#
# Risikofrei fuer den Zugang. Kann einen Neustart brauchen: dann wird ein
# Flag gesetzt und mit EXIT_REBOOT beendet. Das Laptop-Script startet den
# Server neu, wartet und ruft --setup erneut auf. Diese Phase ist dann
# schon als erledigt markiert.

phase_updates() {
  step "Phase 1 · Updates und Grundausstattung"
  if state_has "phase.updates"; then
    skip "Updates – bereits erledigt"
    return 0
  fi
  say "  Der Server bekommt alle aktuellen Updates und die Werkzeuge,"
  say "  die wir gleich brauchen. Das dauert ein paar Minuten."
  printf '\n'

  case "$PKG" in
    apt)
      run env DEBIAN_FRONTEND=noninteractive apt-get update -q
      run env DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -q \
        -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold
      pkg_install curl ca-certificates ufw fail2ban unattended-upgrades \
        wireguard-tools qrencode
      ;;
    dnf)
      run dnf upgrade -y -q
      pkg_install curl ca-certificates firewalld fail2ban dnf-automatic wireguard-tools qrencode
      ;;
    *)
      warn "Updates fuer $OS_FAMILY werden nicht automatisch eingespielt."
      ;;
  esac
  ok "Pakete aktuell"

  # Zeit: falsche Uhrzeit bricht spaeter Zertifikate und Logins.
  run_soft timedatectl set-timezone Europe/Berlin
  if have chronyd || have chrony; then
    run_soft systemctl enable --now chrony
  else
    run_soft systemctl enable --now systemd-timesyncd
  fi
  ok "Zeitzone Europe/Berlin, Uhr wird automatisch gestellt"

  # Swap: kleine Server ohne Swap kippen bei Coolify-Builds um.
  if swapon --show 2>/dev/null | grep -q . ; then
    skip "Swap – bereits vorhanden"
  else
    run_soft fallocate -l 2G /swapfile || run dd if=/dev/zero of=/swapfile bs=1M count=2048 status=none
    run chmod 600 /swapfile
    run mkswap /swapfile
    run swapon /swapfile
    if [ "$DRY_RUN" = "1" ]; then
      printf '  %s[trocken]%s /swapfile in /etc/fstab eintragen\n' "$C_DIM" "$C_RESET"
    else
      grep -q '^/swapfile' /etc/fstab || printf '/swapfile none swap sw 0 0\n' >> /etc/fstab
    fi
    ok "2 GB Swap angelegt (Reserve fuer Builds)"
  fi

  state_set "phase.updates" "$(date -Iseconds)"
  laptop_env_set "phase" "updates"

  if [ -f /var/run/reboot-required ] && [ "$DRY_RUN" != "1" ]; then
    state_set "reboot-pending" "$(date -Iseconds)"
    laptop_env_set "reboot" "pending"
    next_up "Updates eingespielt, Grundwerkzeuge installiert" \
            "Der Server startet einmal neu (neuer Kernel). Dein Laptop-Script wartet und macht danach von selbst weiter." \
            "Nichts. Nur warten, etwa eine Minute."
    exit "$EXIT_REBOOT"
  fi

  next_up "Updates eingespielt, Grundwerkzeuge installiert" \
          "Coolify wird installiert."
}
