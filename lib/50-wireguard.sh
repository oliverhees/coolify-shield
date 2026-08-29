#!/usr/bin/env bash
# Phase B :: VPN via wg-easy — MIT WATCHDOG
#
# STATUS: STUB. Ablauf steht, Deployment fehlt.
#
# Bewusst wg-easy statt Tailscale: Steuerungsebene bleibt auf dem eigenen
# Server, keine Daten bei einem Drittanbieter. Fuer DSGVO-sensible Nutzer
# der einzige Weg, der ohne Auftragsverarbeitungsvertrag auskommt.

WG_SUBNET_DEFAULT="10.8.0.0/24"
WG_PORT_DEFAULT="51820"

phase_wireguard() {
  step "Phase B3 · VPN einrichten"

  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qi 'wg-easy'; then
    skip "wg-easy laeuft bereits"
    return 0
  fi

  say "  Danach ist das Coolify-Dashboard nur noch ueber VPN erreichbar."
  say "  Auf dem Handy: WireGuard-App, QR-Code scannen, fertig."
  printf '\n'
  ask_yn "VPN einrichten?" "n" || { skip "Phase B3 uebersprungen"; return 0; }

  # shellcheck disable=SC2034  # Stub: wird von der noch fehlenden Implementierung genutzt
  local subnetz port passwort
  # shellcheck disable=SC2034
  subnetz="$(ask_value 'VPN-Subnetz' "$WG_SUBNET_DEFAULT")"
  # shellcheck disable=SC2034
  port="$(ask_value 'WireGuard-Port (UDP)' "$WG_PORT_DEFAULT")"

  # TODO: oeffentliche IP ermitteln (curl ifconfig.me, Fallback: ip route)
  # TODO: Admin-Passwort-Hash erzeugen (bcrypt) statt Klartext
  # TODO: docker compose fuer wg-easy nach /opt/coolify-shield/wg-easy/
  # TODO: hochfahren, Healthcheck abwarten
  # TODO: ersten Client "handy" anlegen, QR-Code direkt im Terminal ausgeben
  # TODO: Subnetz in den Zustand schreiben — Phase 40 braucht es
  # state_set "wireguard.subnetz" "$subnetz"
  warn "STUB: wg-easy-Deployment noch nicht implementiert"

  # Merker: Nach dem VPN kommt der Zwang. Erst wenn der User bestaetigt,
  # dass er per VPN drin ist, darf die Traefik-Allowlist aktiviert werden.
  # TODO: watchdog_arm "traefik-allowlist" 15 "<Allowlist-Datei loeschen + Traefik neu laden>"

  state_set "phase.wireguard" "$(date -Iseconds)"
  course_cue "Modul 4 · komplett"
}
