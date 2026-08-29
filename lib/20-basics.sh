#!/usr/bin/env bash
# Phase A :: Grundlagen — risikofrei
#
# STATUS: STUB. Struktur steht, Aktionen fehlen.
#
# Regel fuer diese Phase: Nichts, was den Zugang kappen kann. Diese Phase
# darf ein Anfaenger blind laufen lassen. Kein Watchdog noetig.

phase_basics() {
  step "Phase A · Grundlagen (risikofrei)"
  say "  Hier kann dich nichts aussperren. Alles ohne Netzwerkeingriff."
  printf '\n'

  # --- A1: Sicherheitsupdates automatisieren ------------------------------
  if state_has "basics.autoupdate"; then
    skip "Automatische Updates – laeuft bereits"
  else
    # TODO: debian -> unattended-upgrades + 20auto-upgrades schreiben
    # TODO: rhel   -> dnf-automatic installieren, timer enablen
    # TODO: suse   -> zypper-automatic
    # TODO: arch   -> bewusst nichts (Rolling Release, Auto-Update = schlechte Idee)
    warn "STUB: automatische Updates noch nicht implementiert"
  fi

  # --- A2: Brute-Force-Schutz ---------------------------------------------
  if state_has "basics.crowdsec"; then
    skip "CrowdSec – laeuft bereits"
  else
    # TODO: CrowdSec installieren (Repo-Skript pro OS_FAMILY)
    # TODO: Collections: crowdsecurity/sshd, crowdsecurity/traefik
    # TODO: Bouncer: crowdsec-firewall-bouncer-iptables|nftables
    # TODO: fail2ban als Fallback, wenn CrowdSec-Repo nicht erreichbar
    warn "STUB: Brute-Force-Schutz noch nicht implementiert"
  fi

  # --- A3: Traefik-Config vorbereiten (noch NICHT aktivieren) -------------
  # Datei wird geschrieben, aber ohne Middleware-Verweis an den Routern.
  # Scharf geschaltet wird erst in Phase 40, mit Watchdog.
  # TODO: /data/coolify/proxy/dynamic/shield-allowlist.yaml erzeugen
  # TODO: Subnetz aus Phase 50 (WireGuard) einsetzen
  # ACHTUNG beim spaeteren Aktivieren: Die Middleware muss an ALLE
  # Dashboard-Router, auch die Realtime-/Terminal-Router (6001/6002).
  # Sonst ist die Loginseite dicht, aber das Terminal offen.
  warn "STUB: Traefik-Config-Vorbereitung noch nicht implementiert"

  # --- A4: Logrotation fuer unser eigenes Log -----------------------------
  # TODO: /etc/logrotate.d/coolify-shield

  state_set "phase.basics" "$(date -Iseconds)"
  course_cue "Modul 2 · komplett"
}
