#!/usr/bin/env bash
# Phase B2 :: Firewall, MIT WATCHDOG
#
# Zwei Ebenen, weil Docker die normale ufw-Logik umgeht:
#  1. ufw (Host):  22, 80, 443 offen; WireGuard UDP offen; alles vom Tunnel offen
#  2. DOCKER-USER: Coolify-Ports 8000/6001/6002 nur aus dem Tunnel und aus
#     privaten Netzen. Aus dem Internet: DROP. Matching ueber die Original-
#     Zieladresse (ctorigdstport), weil Docker die Pakete vorher umschreibt.
#     Keine Interface-Bindung: erst private Quellen durchlassen, den Rest sperren.

UFW_AFTER="/etc/ufw/after.rules"
FW_MARK_BEGIN="# BEGIN coolify-shield"
FW_MARK_END="# END coolify-shield"

fw_block_remove() {
  [ -f "$UFW_AFTER" ] || return 0
  sed -i "/^$FW_MARK_BEGIN\$/,/^$FW_MARK_END\$/d" "$UFW_AFTER"
}

fw_block_text() {
  cat <<BLOCK
$FW_MARK_BEGIN
*filter
:DOCKER-USER - [0:0]
:coolify-shield-deny - [0:0]
-A DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j RETURN
-A DOCKER-USER -s $WG_SUBNET -j RETURN
-A DOCKER-USER -s 10.0.0.0/8 -j RETURN
-A DOCKER-USER -s 172.16.0.0/12 -j RETURN
-A DOCKER-USER -s 192.168.0.0/16 -j RETURN
-A DOCKER-USER -s 127.0.0.0/8 -j RETURN
-A DOCKER-USER -p tcp -m conntrack --ctorigdstport 8000 -j coolify-shield-deny
-A DOCKER-USER -p tcp -m conntrack --ctorigdstport 6001 -j coolify-shield-deny
-A DOCKER-USER -p tcp -m conntrack --ctorigdstport 6002 -j coolify-shield-deny
-A DOCKER-USER -j RETURN
-A coolify-shield-deny -m limit --limit 3/min -j LOG --log-prefix "[coolify-shield block] "
-A coolify-shield-deny -j DROP
COMMIT
$FW_MARK_END
BLOCK
}

phase_firewall() {
  step "Phase 8 · Firewall"
  if state_has "phase.firewall" && ufw status 2>/dev/null | grep -qi '^Status: active'; then
    skip "Firewall bereits aktiv"
    return 0
  fi
  [ "$FIREWALL_TOOL" = "ufw" ] || { warn "Nur ufw wird derzeit automatisch eingerichtet ($OS_NAME hat $FIREWALL_TOOL)."; return 0; }
  have ufw || pkg_install ufw

  say "  Offen bleibt: SSH (22), Web (80, 443), der Tunnel (UDP $WG_PORT)."
  say "  Zu geht: das Coolify-Dashboard (8000) und seine Hilfsports aus dem Internet."
  say "  Erreichbar bleibt es aus dem Tunnel: http://$WG_SERVER_IP:8000"
  say "  Sicherheitsnetz: 10-Minuten-Timer, rollt alles zurueck, wenn du nicht bestaetigst."
  printf '\n'
  ask_yn "Firewall jetzt scharf schalten?" "j" || { skip "Phase uebersprungen"; return 0; }

  watchdog_arm "firewall" 10 \
    "ufw --force disable; sed -i '/^$FW_MARK_BEGIN\$/,/^$FW_MARK_END\$/d' $UFW_AFTER; ufw --force reset >/dev/null 2>&1 || true"

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s ufw-Regeln setzen, DOCKER-USER-Block in %s schreiben, ufw enable\n' "$C_DIM" "$C_RESET" "$UFW_AFTER"
    fw_block_text | sed 's/^/      │ /'
  else
    backup_file "$UFW_AFTER"
    ufw --force reset >/dev/null 2>&1
    ufw default deny incoming >/dev/null
    ufw default allow outgoing >/dev/null
    ufw allow 22/tcp comment 'SSH' >/dev/null
    ufw allow 80/tcp comment 'Web' >/dev/null
    ufw allow 443/tcp comment 'Web TLS' >/dev/null
    ufw allow "$WG_PORT/udp" comment 'WireGuard' >/dev/null
    ufw allow in on wg0 comment 'alles aus dem Tunnel' >/dev/null
    ufw allow from 172.16.0.0/12 to any port 22 proto tcp comment 'Coolify verwaltet sich selbst' >/dev/null
    # ufw reset hat after.rules auf den Default zurueckgesetzt; Block sauber anhaengen.
    fw_block_remove
    fw_block_text >> "$UFW_AFTER"
    if ! ufw --force enable >/dev/null 2>&1; then
      fw_block_remove
      ufw --force disable >/dev/null 2>&1
      watchdog_disarm "firewall"
      die "ufw liess sich nicht aktivieren. Alles wurde zurueckgenommen." "Ausgabe in der Community posten."
    fi
    ufw reload >/dev/null 2>&1 || true
    ok "Firewall aktiv"

    # Selbsttest von innen: Dashboard aus dem Tunnel erreichbar?
    if curl -fsS --max-time 4 -o /dev/null "http://$WG_SERVER_IP:8000" 2>/dev/null; then
      ok "Dashboard aus dem Tunnel erreichbar (http://$WG_SERVER_IP:8000)"
    else
      warn "Dashboard antwortet nicht unter http://$WG_SERVER_IP:8000. Laptop-Test zeigt gleich mehr."
    fi
    iptables -S DOCKER-USER 2>/dev/null | grep -q 'ctorigdstport 8000' \
      && ok "Docker-Regel fuer Port 8000 aktiv" \
      || warn "Docker-Regel fuer 8000 nicht in iptables sichtbar (Docker noch nicht gestartet?)"
  fi

  state_set "phase.firewall" "$(date -Iseconds)"
  laptop_env_set "phase" "firewall"
  laptop_env_set "watchdog" "firewall"
  next_up "Firewall aktiv: Dashboard nur noch aus dem Tunnel" \
          "Dein Laptop-Script testet von aussen, ob Port 8000 wirklich zu ist, und bestaetigt." \
          "Nichts. Klappt der Test, entschaerft das Laptop-Script den Timer."
}
