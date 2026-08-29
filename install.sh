#!/usr/bin/env bash
#
#   coolify-shield · haertet einen Coolify-Server ab
#
#   Standard ist der Trockenlauf. Es passiert nichts, bis du --apply sagst.
#   Riskante Schritte laufen nur mit Rueckfall-Timer.
#
#   Lies dieses Script, bevor du es ausfuehrst. Es laeuft als root.
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

for modul in 00-common 00-preflight 10-audit 20-basics 30-ssh 40-firewall 50-wireguard 99-report; do
  # shellcheck source=/dev/null
  . "$LIB_DIR/$modul.sh" || { echo "Modul fehlt: $modul.sh" >&2; exit 1; }
done

usage() {
  cat <<'HILFE'

  coolify-shield

  Verwendung:
    sudo ./install.sh                nur zeigen, was passieren wuerde (Standard)
    sudo ./install.sh --apply        Aenderungen wirklich durchfuehren
    sudo ./install.sh --audit        nur pruefen und Report schreiben
    sudo ./install.sh --confirm      Rueckfall-Timer entschaerfen
    sudo ./install.sh --undo         alles zurueckrollen
    sudo ./install.sh --status       Zustand und laufende Timer anzeigen

  Zusaetzlich:
    --phase <name>   nur eine Phase (basics|ssh|firewall|vpn)
    --yes            keine Rueckfragen (nur fuer Wiederholungslaeufe)
    --force          auf ungetesteten Systemen trotzdem starten
    --no-cues        Kurs-Verweise ausblenden

  Wenn du dich ausgesperrt hast: NOTFALL.md

HILFE
}

MODUS="dryrun"
NUR_PHASE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --apply)    MODUS="apply"; DRY_RUN=0 ;;
    --audit)    MODUS="audit" ;;
    --confirm)  MODUS="confirm" ;;
    --undo)     MODUS="undo" ;;
    --status)   MODUS="status" ;;
    --phase)    NUR_PHASE="${2:-}"; shift ;;
    --yes|-y)   ASSUME_YES=1 ;;
    --force)    FORCE=1 ;;
    --no-cues)  SHIELD_COURSE_CUES=0 ;;
    -h|--help)  usage; exit 0 ;;
    *)          echo "Unbekannte Option: $1"; usage; exit 1 ;;
  esac
  shift
done
export DRY_RUN FORCE ASSUME_YES SHIELD_COURSE_CUES

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
    for p in preflight audit basics ssh firewall wireguard; do
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
      printf '\n'
      ok "Alle Aenderungen bestaetigt."
    fi
    ;;

  undo)
    need_root; detect_system; banner
    step "Zuruecknehmen"
    for w in $(watchdog_list); do watchdog_disarm "$w"; done
    # TODO: Backups in umgekehrter Reihenfolge zuruecksperren
    # TODO: ufw/firewalld auf Ausgangszustand
    # TODO: wg-easy-Stack stoppen und entfernen (nach Rueckfrage)
    # TODO: Traefik-Dynamic-Config von coolify-shield entfernen, Traefik neu laden
    warn "STUB: Zuruecknehmen noch nicht implementiert"
    say  "  Solange: Backups liegen unter $BACKUP_DIR"
    ;;

  audit)
    banner; phase_preflight; phase_audit; phase_report
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
      phase_wireguard   # VPN vor der Firewall – sonst sperrt die Firewall den Weg zu
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
