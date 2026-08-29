#!/usr/bin/env bash
# Phase 0 :: Preflight-Gate
#
# Regel: Hier wird NICHTS geaendert. Wenn eine Bedingung fehlt, bricht das
# Script mit genau einem klaren Satz ab. Der User soll wissen, was zu tun ist,
# nicht was intern schiefging.

phase_preflight() {
  step "Phase 0 · Preflight"

  # --- Root ---------------------------------------------------------------
  need_root
  ok "Root-Rechte vorhanden"

  # --- System erkennen ----------------------------------------------------
  detect_system
  case "$SUPPORT_TIER" in
    1) ok "System: $OS_NAME ($ARCH) – getestet" ;;
    2) warn "System: $OS_NAME ($ARCH) – nicht getestet, sollte aber laufen" ;;
    0) [ "$FORCE" = "1" ] \
         && warn "System: $OS_NAME – unbekannt, weiter wegen --force" \
         || die "Dieses System kennt das Script nicht: $OS_NAME" \
                "Mit --force trotzdem starten, oder im Kurs die manuelle Anleitung nutzen." ;;
  esac

  # --- systemd ------------------------------------------------------------
  if have systemctl && [ -d /run/systemd/system ]; then
    ok "systemd aktiv"
  else
    warn "Kein systemd – Watchdog faellt auf 'at' zurueck"
  fi

  # --- Watchdog-Faehigkeit ------------------------------------------------
  watchdog_available \
    && ok "Watchdog verfuegbar (Rueckfall-Timer moeglich)" \
    || die "Es gibt keine Moeglichkeit, einen Rueckfall-Timer zu setzen." \
           "Paket 'at' installieren, dann erneut starten."

  # --- Docker & Coolify ---------------------------------------------------
  have docker || die "Docker ist nicht installiert." \
                     "Ohne Coolify-Installation ergibt dieses Script keinen Sinn."
  if docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'coolify'; then
    ok "Coolify-Container laeuft"
    state_set "coolify.gefunden" 1
  else
    if [ "$FORCE" = "1" ]; then
      warn "Kein laufender Coolify-Container gefunden – weiter wegen --force"
    else
      die "Auf diesem Server laeuft kein Coolify." \
          "Erst Coolify installieren, dann dieses Script."
    fi
  fi

  # --- Laeuft das hier im Coolify-Web-Terminal? ---------------------------
  # Wenn ja: Firewall-Aenderungen kappen die eigene Sitzung. Sofort abbrechen.
  if [ -n "${SSH_CONNECTION:-}" ]; then
    SSH_CLIENT_IP="$(printf '%s' "$SSH_CONNECTION" | awk '{print $1}')"
    export SSH_CLIENT_IP
    ok "Du bist per SSH verbunden (von $SSH_CLIENT_IP)"
  else
    die "Du sitzt nicht in einer SSH-Sitzung." \
        "Nicht im Coolify-Web-Terminal ausfuehren – per SSH auf den Server, dann neu starten."
  fi

  # --- SSH-Key hinterlegt? ------------------------------------------------
  # Ohne funktionierenden Key darf Phase 30 spaeter nicht laufen.
  local keys=0
  for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do
    [ -f "$f" ] && keys=$(( keys + $(grep -cv '^\s*\(#\|$\)' "$f" 2>/dev/null || echo 0) ))
  done
  if [ "$keys" -gt 0 ]; then
    ok "$keys SSH-Key(s) hinterlegt"
    state_set "ssh.keys" "$keys"
  else
    warn "Kein SSH-Key gefunden – Phase 3 (SSH-Haertung) wird uebersprungen"
    state_set "ssh.keys" "0"
  fi

  # --- Internet -----------------------------------------------------------
  if curl -fsS --max-time 8 -o /dev/null https://github.com 2>/dev/null; then
    ok "Internetverbindung steht"
  else
    warn "Kein Internet erreichbar – Paketinstallationen werden fehlschlagen"
  fi

  # --- Platz --------------------------------------------------------------
  local frei_mb; frei_mb="$(df -Pm / | awk 'NR==2{print $4}')"
  [ "${frei_mb:-0}" -ge 1024 ] \
    && ok "Freier Speicher: ${frei_mb} MB" \
    || warn "Nur ${frei_mb} MB frei – wird knapp"

  # --- Notfall-Hinweis ----------------------------------------------------
  printf '\n  %sBevor es weitergeht:%s Oeffne die Rescue-Konsole deines Hosters\n' "$C_BOLD" "$C_RESET"
  printf '  in einem Browser-Tab. Steht in NOTFALL.md. Das ist dein Rettungsanker.\n\n'

  if [ "$ASSUME_YES" != "1" ] && [ "$DRY_RUN" != "1" ]; then
    ask_yn "Rescue-Konsole offen und einsatzbereit?" "n" \
      || die "Abgebrochen – zu Recht." "NOTFALL.md lesen, Zugang testen, dann neu starten."
  fi

  state_set "phase.preflight" "$(date -Iseconds)"
  course_cue "Modul 1 · ab 02:30"
}
