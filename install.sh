#!/usr/bin/env bash
#
#   coolify-shield · richtet einen Coolify-Server ein und haertet ihn ab
#
#   Anfaenger-Weg:  sudo ./install.sh --setup   (wird vom Laptop-Script gestartet)
#   Bestehender Server, nur haerten: sudo ./install.sh  (Trockenlauf), dann --apply
#
#   Riskante Schritte laufen nur mit Rueckfall-Timer. Es laeuft als root.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for modul in 00-common 00-preflight 05-updates 10-audit 15-coolify 20-basics 25-adminuser 30-ssh 40-firewall 50-wireguard 60-coolify-secure 99-report; do
  # shellcheck source=/dev/null
  . "$LIB_DIR/$modul.sh" || { echo "Modul fehlt: $modul.sh" >&2; exit 1; }
done

usage() {
  cat <<'HILFE'

  coolify-shield

  Der Anfaenger-Weg (macht alles der Reihe nach, sagt immer, was als Naechstes kommt):
    sudo ./install.sh --setup

  Fuer einen Server, auf dem Coolify schon laeuft:
    sudo ./install.sh                nur zeigen, was passieren wuerde (Standard)
    sudo ./install.sh --apply        Aenderungen wirklich durchfuehren
    sudo ./install.sh --audit        nur pruefen und Report schreiben

  Immer:
    sudo ./install.sh --confirm      Rueckfall-Timer entschaerfen ("ich komme noch rein")
    sudo ./install.sh --undo         alles zurueckrollen
    sudo ./install.sh --status       Zustand und laufende Timer anzeigen

  Zusaetzlich:
    --phase <name>   nur eine Phase (basics|ssh|firewall|vpn)
    --yes            keine Rueckfragen (nur fuer Wiederholungslaeufe)
    --force          Preflight-Warnungen uebergehen
    --no-cues        Kurs-Verweise ausblenden

  Wenn du dich ausgesperrt hast: NOTFALL.md

HILFE
}

MODUS="dryrun"
NUR_PHASE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --setup)    MODUS="setup"; DRY_RUN=0 ;;
    --apply)    MODUS="apply"; DRY_RUN=0 ;;
    --audit)    MODUS="audit" ;;
    --confirm)  MODUS="confirm" ;;
    --undo)     MODUS="undo" ;;
    --status)   MODUS="status" ;;
    --phase)    NUR_PHASE="${2:-}"; shift ;;
    --yes|-y)   ASSUME_YES=1 ;;
    --force)    FORCE=1 ;;
    --no-cues)  SHIELD_COURSE_CUES=0 ;;
    --dry-setup) MODUS="setup"; DRY_RUN=1 ;;   # nur fuer Tests
    -h|--help)  usage; exit 0 ;;
    *)          echo "Unbekannte Option: $1"; usage; exit 1 ;;
  esac
  shift
done
export DRY_RUN FORCE ASSUME_YES SHIELD_COURSE_CUES MODUS

mkdir -p "$STATE_DIR" "$BACKUP_DIR" 2>/dev/null || true
touch "$LOG_FILE" 2>/dev/null || true
log "=== Start :: Modus=$MODUS Version=$SHIELD_VERSION ==="

banner() {
  printf '\n%s  coolify-shield%s %s%s%s\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$SHIELD_VERSION" "$C_RESET"
  if [ "$DRY_RUN" = "1" ] && [ "$MODUS" = "dryrun" ]; then
    printf '  %sTrockenlauf – es wird nichts geaendert.%s\n' "$C_DIM" "$C_RESET"
    printf '  %sWenn alles passt: sudo ./install.sh --apply%s\n' "$C_DIM" "$C_RESET"
  fi
  printf '\n'
}

# ---------------------------------------------------------------------------
case "$MODUS" in

  status)
    need_root; detect_system; banner
    say "System : $OS_NAME ($ARCH), Familie $OS_FAMILY, Tier $SUPPORT_TIER"
    say "Log    : $LOG_FILE"
    say "Backups: $BACKUP_DIR"
    printf '\nAbgeschlossene Phasen:\n'
    for p in updates coolify account adminuser wireguard basics ssh firewall coolify_secure; do
      state_has "phase.$p" && ok "$p ($(state_get "phase.$p"))" || skip "$p"
    done
    laufende="$(watchdog_list)"
    if [ -n "$laufende" ]; then
      printf '\n'
      warn "Aktive Rueckfall-Timer: $laufende"
      say  "  Wenn alles laeuft: sudo ./install.sh --confirm"
    fi
    ;;

  confirm)
    need_root; banner
    laufende="$(watchdog_list)"
    if [ -z "$laufende" ]; then
      say "Kein aktiver Rueckfall-Timer. Nichts zu bestaetigen."
    else
      for w in $laufende; do watchdog_disarm "$w"; done
      laptop_env_set "watchdog" ""
      printf '\n'
      ok "Alle Aenderungen bestaetigt."
    fi
    ;;

  undo)
    need_root; detect_system; banner
    step "Zuruecknehmen"
    for w in $(watchdog_list); do watchdog_disarm "$w"; done
    if [ -f "$SSHD_DROPIN" ]; then
      rm -f "$SSHD_DROPIN"; sshd -t && ssh_reload
      state_clear "phase.ssh"; ok "SSH: Passwort-Login wieder erlaubt (wie vorher)"
    fi
    if have ufw && ufw status 2>/dev/null | grep -qi '^Status: active'; then
      ufw --force disable >/dev/null; fw_block_remove
      state_clear "phase.firewall"; ok "Firewall aus, Docker-Regeln entfernt"
    fi
    if [ -f /etc/wireguard/wg0.conf ] && ask_yn "VPN-Tunnel auch entfernen? (Handy/Laptop-Zugang wird ungueltig)" "n"; then
      systemctl disable --now wg-quick@wg0 >/dev/null 2>&1
      rm -f /etc/wireguard/wg0.conf; rm -rf "$WG_DIR"
      state_clear "phase.wireguard"; ok "WireGuard entfernt"
    fi
    say "  Nicht zurueckgenommen (harmlos): Updates, fail2ban, Coolify, dein Benutzer."
    say "  Backups liegen unter $BACKUP_DIR"
    ;;

  audit)
    banner; phase_preflight; phase_audit; phase_report
    ;;

  setup)
    banner
    printf '  %sDer gefuehrte Weg.%s Ich sage dir nach jedem Schritt, was als Naechstes kommt.\n' "$C_BOLD" "$C_RESET"
    printf '  Wenn ich dich brauche, steht da "Du musst jetzt". Sonst: einfach zuschauen.\n'
    phase_preflight
    phase_updates
    phase_coolify
    phase_account
    phase_adminuser
    phase_wireguard
    phase_basics
    # SSH und Firewall haben je einen Rueckfall-Timer. Nach JEDER der beiden
    # geht die Kontrolle zurueck an das Laptop-Script, das von aussen testet
    # und mit --confirm bestaetigt. Deshalb: hier beenden, Laptop ruft erneut.
    if ! state_has "phase.ssh"; then
      phase_ssh
      if state_has "watchdog.ssh"; then laptop_env_set "phase" "ssh"; exit 0; fi
    fi
    if ! state_has "phase.firewall"; then
      phase_firewall
      if state_has "watchdog.firewall"; then laptop_env_set "phase" "firewall"; exit 0; fi
    fi
    phase_audit
    phase_coolify_secure
    phase_report
    laptop_env_set "phase" "done"
    next_up "Alles eingerichtet. Dein Server ist bereit." \
            "Dein Laptop-Script zeigt dir, wie du ab jetzt reinkommst."
    ;;

  dryrun|apply)
    banner
    phase_preflight
    phase_audit

    if [ -n "$NUR_PHASE" ]; then
      case "$NUR_PHASE" in
        basics)   phase_basics ;;
        ssh)      phase_ssh ;;
        firewall) phase_firewall ;;
        vpn)      phase_wireguard ;;
        *)        die "Unbekannte Phase: $NUR_PHASE" "Erlaubt: basics ssh firewall vpn" ;;
      esac
    else
      phase_basics
      phase_wireguard   # VPN vor der Firewall, sonst sperrt die Firewall den Weg zu
      phase_ssh
      phase_firewall
    fi

    phase_report

    if [ "$MODUS" = "dryrun" ]; then
      printf '\n  %sDas war der Trockenlauf.%s Nichts wurde geaendert.\n' "$C_BOLD" "$C_RESET"
      printf '  Wenn es passt: %ssudo ./install.sh --apply%s\n\n' "$C_BOLD" "$C_RESET"
    else
      laufende="$(watchdog_list)"
      if [ -n "$laufende" ]; then
        printf '\n  %sJetzt bist du dran:%s Zweites Terminal auf, Verbindung testen.\n' "$C_YELLOW$C_BOLD" "$C_RESET"
        printf '  Klappt es: %ssudo ./install.sh --confirm%s\n' "$C_BOLD" "$C_RESET"
        printf '  Klappt es nicht: nichts tun. Es rollt sich von selbst zurueck.\n\n'
      fi
    fi
    ;;
esac

log "=== Ende :: Modus=$MODUS ==="
