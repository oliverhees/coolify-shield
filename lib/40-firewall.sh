#!/usr/bin/env bash
# Phase B :: Firewall — MIT WATCHDOG
#
# STATUS: STUB. Watchdog-Verdrahtung steht, Regeln fehlen.

phase_firewall() {
  step "Phase B2 · Firewall"

  [ -n "$FIREWALL_TOOL" ] || { warn "Kein bekanntes Firewall-Werkzeug fuer $OS_NAME"; return 0; }
  say "  Werkzeug: $FIREWALL_TOOL"

  # Gewuenschtes Ergebnis:
  #   22/tcp     nur aus dem VPN-Subnetz (oder von SSH_CLIENT_IP, wenn kein VPN)
  #   80,443/tcp offen  (deine Apps + Let's Encrypt)
  #   51820/udp  offen  (WireGuard-Einwahl)
  #   8000,6001,6002/tcp  nur localhost + VPN-Subnetz
  #   alles andere zu

  printf '\n'
  ask_yn "Firewall scharf schalten?" "n" || { skip "Phase B2 uebersprungen"; return 0; }

  watchdog_arm "firewall" 10 \
    "ufw --force disable 2>/dev/null || systemctl stop firewalld 2>/dev/null || true"

  case "$FIREWALL_TOOL" in
    ufw)
      # TODO: ufw default deny incoming / allow outgoing
      # TODO: ufw allow from <SSH-Quelle> to any port 22 proto tcp
      # TODO: ufw allow 80,443/tcp
      # TODO: ufw allow 51820/udp
      # TODO: ufw allow from <VPN-Subnetz> to any port 8000,6001,6002 proto tcp
      # TODO: ufw --force enable
      ;;
    firewalld)
      # TODO: Zone "coolify-vpn" mit source=<VPN-Subnetz>
      # TODO: --permanent Regeln, dann --reload
      ;;
  esac
  warn "STUB: Firewall-Regeln noch nicht implementiert"

  state_set "phase.firewall" "$(date -Iseconds)"
  course_cue "Modul 3 · ab 11:05"
}
