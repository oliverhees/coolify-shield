#!/usr/bin/env bash
# Phase B3 :: VPN mit reinem WireGuard
#
# Bewusst KEIN wg-easy und kein Tailscale: kein zweites Web-Login, kein
# Drittanbieter. Zwei Client-Configs (Laptop, Handy), fertig. Die Steuerung
# bleibt komplett auf deinem Server.
#
# Ergebnis: Der Server ist im Tunnel unter 10.8.0.1 erreichbar, das
# Dashboard also unter http://10.8.0.1:8000 – von aussen ist 8000 spaeter zu.

phase_wireguard() {
  step "Phase 5 · VPN-Tunnel (WireGuard)"
  if state_has "phase.wireguard" && [ -f /etc/wireguard/wg0.conf ]; then
    skip "WireGuard laeuft bereits (Configs unter $WG_DIR)"
    return 0
  fi
  say "  Was das ist: ein verschluesselter Tunnel zwischen deinem Laptop (und Handy)"
  say "  und dem Server. Nur wer im Tunnel ist, kommt spaeter ans Dashboard."
  say "  Wo es laeuft: auf dem Server selbst. Kein Drittanbieter, kein Konto."
  printf '\n'
  have wg || pkg_install wireguard-tools qrencode

  local ip; ip="$(state_get server.public_ip)"
  [ -n "$ip" ] || { ip="$(public_ip)"; state_set "server.public_ip" "$ip"; }
  [ -n "$ip" ] || die "Oeffentliche IP nicht ermittelbar." "Internetverbindung des Servers pruefen."

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s Schluessel erzeugen, /etc/wireguard/wg0.conf und 2 Client-Configs schreiben, wg0 starten\n' "$C_DIM" "$C_RESET"
    state_set "phase.wireguard" "$(date -Iseconds)"
    next_up "VPN-Tunnel eingerichtet (Trockenlauf)" "SSH wird abgesichert."
    return 0
  fi

  mkdir -p "$WG_DIR" /etc/wireguard; chmod 700 "$WG_DIR" /etc/wireguard
  if [ -f /etc/wireguard/wg0.conf ]; then
    skip "wg0.conf vorhanden, Schluessel bleiben (sonst waeren Handy/Laptop-Configs ungueltig)"
  else
    local spriv spub lpriv lpub hpriv hpub
    spriv="$(wg genkey)"; spub="$(printf '%s' "$spriv" | wg pubkey)"
    lpriv="$(wg genkey)"; lpub="$(printf '%s' "$lpriv" | wg pubkey)"
    hpriv="$(wg genkey)"; hpub="$(printf '%s' "$hpriv" | wg pubkey)"

    umask 077
    cat > /etc/wireguard/wg0.conf <<CONF
# coolify-shield
[Interface]
Address = $WG_SERVER_IP/24
ListenPort = $WG_PORT
PrivateKey = $spriv

[Peer]
# laptop
PublicKey = $lpub
AllowedIPs = 10.8.0.2/32

[Peer]
# handy
PublicKey = $hpub
AllowedIPs = 10.8.0.3/32
CONF
    # Split-Tunnel: nur das VPN-Netz laeuft durch den Tunnel. Alles andere
    # (YouTube, Mail) bleibt wie es ist. NIE die oeffentliche Server-IP in
    # AllowedIPs aufnehmen: dann wuerde der Tunnel seinen eigenen Endpunkt
    # durch sich selbst routen (Schleife, kein Handshake, SSH tot).
    local client
    for client in laptop:10.8.0.2:$lpriv handy:10.8.0.3:$hpriv; do
      IFS=: read -r cname caddr cpriv <<< "$client"
      cat > "$WG_DIR/$cname.conf" <<CONF
[Interface]
PrivateKey = $cpriv
Address = $caddr/24

[Peer]
PublicKey = $spub
Endpoint = $ip:$WG_PORT
AllowedIPs = $WG_SUBNET
PersistentKeepalive = 25
CONF
      chmod 600 "$WG_DIR/$cname.conf"
    done
    umask 022
    log "WG Schluessel und Configs erzeugt"
  fi

  printf 'net.ipv4.ip_forward = 1\n' > /etc/sysctl.d/99-coolify-shield.conf
  sysctl -q -p /etc/sysctl.d/99-coolify-shield.conf
  systemctl enable --now wg-quick@wg0 >/dev/null 2>&1 || systemctl restart wg-quick@wg0 \
    || die "WireGuard liess sich nicht starten." "journalctl -u wg-quick@wg0 zeigt den Grund."
  wg show wg0 >/dev/null 2>&1 || die "wg0 ist nicht aktiv." "journalctl -u wg-quick@wg0 pruefen."
  ok "Tunnel-Server laeuft (UDP $WG_PORT, Tunnel-Adresse $WG_SERVER_IP)"

  printf '\n  %sHandy:%s WireGuard-App installieren (App Store / Play Store), Plus druecken,\n' "$C_BOLD" "$C_RESET"
  printf '  "Aus QR-Code erstellen", diesen Code scannen:\n\n'
  qrencode -t ansiutf8 < "$WG_DIR/handy.conf" 2>/dev/null || warn "qrencode fehlt: Datei $WG_DIR/handy.conf manuell uebertragen"
  printf '\n  (Den Code kannst du spaeter jederzeit wieder anzeigen: sudo qrencode -t ansiutf8 < %s/handy.conf)\n' "$WG_DIR"

  state_set "phase.wireguard" "$(date -Iseconds)"
  laptop_env_set "wg_client_conf" "$WG_DIR/laptop.conf"
  laptop_env_set "wg_server_ip" "$WG_SERVER_IP"
  laptop_env_set "phase" "wireguard"
  next_up "VPN-Tunnel steht, Laptop- und Handy-Zugang erzeugt" \
          "SSH wird abgesichert (nur noch Schluessel, kein Passwort). Mit Rueckfall-Timer." \
          "Handy-QR jetzt oder spaeter scannen. Den Laptop-Tunnel richtet dein Laptop-Script gleich selbst ein."
}
