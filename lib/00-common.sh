#!/usr/bin/env bash
# coolify-shield :: gemeinsame Funktionen
# Wird von install.sh gesourct. Nicht direkt ausfuehren.

# ---------------------------------------------------------------------------
# Pfade & Konstanten
# ---------------------------------------------------------------------------
# shellcheck disable=SC2034  # wird in install.sh im Banner genutzt
SHIELD_VERSION="0.2.0"
LOG_FILE="/var/log/coolify-shield.log"
STATE_DIR="/var/lib/coolify-shield"
BACKUP_DIR="/var/backups/coolify-shield"
WATCHDOG_UNIT_PREFIX="coolify-shield-watchdog"

# Laufzeit-Flags (werden von install.sh gesetzt)
DRY_RUN="${DRY_RUN:-1}"
FORCE="${FORCE:-0}"
ASSUME_YES="${ASSUME_YES:-0}"

# ---------------------------------------------------------------------------
# Ausgabe
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_DIM=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
fi

# Ohne Root ist das Log nicht beschreibbar. Das darf keine Fehlermeldung
# produzieren, sonst sieht der erste Kontakt mit dem Script nach Absturz aus.
log() {
  { [ -w "$LOG_FILE" ] || { [ ! -e "$LOG_FILE" ] && [ -w "$(dirname "$LOG_FILE")" ]; }; } || return 0
  printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE" 2>/dev/null
}

say()  { printf '%s\n' "$*"; log "SAY  $*"; }
ok()   { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; log "OK   $*"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; log "WARN $*"; }
err()  { printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; log "ERR  $*"; }
skip() { printf '  %s–%s %s\n' "$C_DIM" "$C_RESET" "$*"; log "SKIP $*"; }

step() {
  printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET"
  printf '%s%s%s\n' "$C_DIM" "$(printf '─%.0s' $(seq 1 ${#1}))" "$C_RESET"
  log "STEP $*"
}

# Ein einziger klarer Satz, dann Ende. Nie ein Stacktrace.
die() {
  printf '\n%s ABBRUCH %s %s\n\n' "$C_RED$C_BOLD" "$C_RESET" "$1" >&2
  [ -n "${2:-}" ] && printf '  Das hilft: %s\n\n' "$2" >&2
  log "DIE  $1"
  exit 1
}

# Verweis in den Kurs. Der Grund, warum Script und Video im Gleichschritt laufen.
course_cue() {
  [ "${SHIELD_COURSE_CUES:-1}" = "1" ] || return 0
  printf '\n  %s▶ Weiter im Kurs: %s%s\n' "$C_BLUE" "$*" "$C_RESET"
}

# ---------------------------------------------------------------------------
# Fragen (Default = sicherste Antwort, Enter reicht)
# ---------------------------------------------------------------------------
ask_yn() {
  local frage="$1" default="${2:-n}" antwort hint
  [ "$ASSUME_YES" = "1" ] && { ok "$frage -> ja (--yes)"; return 0; }
  [ "$default" = "j" ] && hint="[J/n]" || hint="[j/N]"
  read -r -p "  $frage $hint " antwort </dev/tty || antwort=""
  antwort="${antwort:-$default}"
  case "${antwort,,}" in j|ja|y|yes) return 0 ;; *) return 1 ;; esac
}

ask_value() {
  local frage="$1" default="$2" antwort
  [ "$ASSUME_YES" = "1" ] && { printf '%s' "$default"; return 0; }
  read -r -p "  $frage [$default] " antwort </dev/tty || antwort=""
  printf '%s' "${antwort:-$default}"
}

# ---------------------------------------------------------------------------
# Ausfuehrung: im Dry-Run wird nur gezeigt, nie gemacht
# ---------------------------------------------------------------------------
run() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s %s\n' "$C_DIM" "$C_RESET" "$*"
    log "DRY  $*"
    return 0
  fi
  log "RUN  $*"
  if ! "$@"; then
    local rc=$?
    log "FAIL rc=$rc :: $*"
    die "Ein Befehl ist fehlgeschlagen: $1 (Code $rc)." "Ausgabe oben lesen, Problem beheben, dann einfach erneut starten. Ich mache da weiter, wo wir waren."
  fi
}

# Wie run, aber ein Fehler ist erlaubt (nur Warnung).
run_soft() {
  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s %s\n' "$C_DIM" "$C_RESET" "$*"; log "DRY  $*"; return 0
  fi
  log "RUN  $*"
  "$@" || { warn "Nicht kritisch, aber fehlgeschlagen: $1"; log "SOFTFAIL $*"; return 1; }
}

# Jede Datei wird vor Aenderung gesichert. Basis fuer --undo.
backup_file() {
  local datei="$1" ziel
  [ -f "$datei" ] || return 0
  ziel="$BACKUP_DIR/$(date '+%Y%m%d-%H%M%S')$(printf '%s' "$datei" | tr '/' '_')"
  run mkdir -p "$BACKUP_DIR"
  run cp -a "$datei" "$ziel"
  log "BAK  $datei -> $ziel"
}

# ---------------------------------------------------------------------------
# Zustand (was ist schon erledigt -> Idempotenz)
# ---------------------------------------------------------------------------
state_set() { [ "$DRY_RUN" = "1" ] && [ "${1#phase.}" != "$1" ] && return 0; mkdir -p "$STATE_DIR"; printf '%s\n' "${2:-1}" > "$STATE_DIR/$1"; }
state_get() { cat "$STATE_DIR/$1" 2>/dev/null || printf ''; }
state_has() { [ -f "$STATE_DIR/$1" ]; }
state_clear() { rm -f "$STATE_DIR/$1"; }

# ---------------------------------------------------------------------------
# System-Erkennung
# Coolify laeuft auf mehr als Debian. Alles hier drueber abstrahieren,
# nie direkt apt-get o.ae. in den Phasen-Modulen aufrufen.
# ---------------------------------------------------------------------------
detect_system() {
  [ -r /etc/os-release ] || die "Kein /etc/os-release gefunden." "Ein unterstuetztes Linux verwenden."
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID="${ID:-unbekannt}"
  OS_VERSION="${VERSION_ID:-?}"
  OS_NAME="${PRETTY_NAME:-$OS_ID $OS_VERSION}"
  OS_LIKE="${ID_LIKE:-}"
  ARCH="$(uname -m)"

  case "$OS_ID" in
    ubuntu|debian|raspbian)            OS_FAMILY="debian" ;;
    fedora|rhel|centos|rocky|almalinux) OS_FAMILY="rhel"  ;;
    opensuse*|sles)                    OS_FAMILY="suse"   ;;
    arch|manjaro|endeavouros)          OS_FAMILY="arch"   ;;
    *)
      case " $OS_LIKE " in
        *debian*) OS_FAMILY="debian" ;;
        *rhel*|*fedora*) OS_FAMILY="rhel" ;;
        *suse*) OS_FAMILY="suse" ;;
        *arch*) OS_FAMILY="arch" ;;
        *) OS_FAMILY="unbekannt" ;;
      esac
      ;;
  esac

  case "$OS_FAMILY" in
    debian) PKG="apt";    FIREWALL_TOOL="ufw" ;;
    rhel)   PKG="dnf";    FIREWALL_TOOL="firewalld" ;;
    suse)   PKG="zypper"; FIREWALL_TOOL="firewalld" ;;
    arch)   PKG="pacman"; FIREWALL_TOOL="ufw" ;;
    *)      PKG="";       FIREWALL_TOOL="" ;;
  esac

  # Tier 1 = getestet, Tier 2 = sollte laufen, unbekannt = nur mit --force
  case "$OS_ID:$OS_VERSION" in
    ubuntu:22.04|ubuntu:24.04|ubuntu:26.04|debian:12|debian:13) SUPPORT_TIER=1 ;;
    *) [ "$OS_FAMILY" = "unbekannt" ] && SUPPORT_TIER=0 || SUPPORT_TIER=2 ;;
  esac

  export OS_ID OS_VERSION OS_NAME OS_FAMILY OS_LIKE ARCH PKG FIREWALL_TOOL SUPPORT_TIER
}

pkg_install() {
  case "$PKG" in
    apt)    run env DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    dnf)    run dnf install -y "$@" ;;
    zypper) run zypper --non-interactive install "$@" ;;
    pacman) run pacman -S --noconfirm "$@" ;;
    *)      warn "Kein bekannter Paketmanager – bitte manuell installieren: $*"; return 1 ;;
  esac
}

have() { command -v "$1" >/dev/null 2>&1; }

# ---------------------------------------------------------------------------
# Sitzung erkennen: SSH, lokale Konsole oder Coolify-Web-Terminal?
#
# $SSH_CONNECTION reicht NICHT: sudo und "su -" werfen die Variable weg.
# Deshalb laufen wir die Prozesskette hoch und suchen sshd als Vorfahren.
# Die Client-IP holen wir dann von der Socket-Verbindung (ss).
#
# Setzt: SESSION_KIND = ssh | console | unknown
#        SSH_CLIENT_IP = Quell-IP der SSH-Verbindung (leer, wenn unbekannt)
# ---------------------------------------------------------------------------
_strip_port_and_brackets() {
  # "[::ffff:1.2.3.4]:51234" -> "1.2.3.4"  |  "1.2.3.4:51234" -> "1.2.3.4"
  local a="$1"
  a="${a%:*}"                # Port weg (letzter Doppelpunkt)
  a="${a#[}"; a="${a%]}"     # eckige Klammern weg
  a="${a#::ffff:}"           # IPv4-mapped IPv6 -> IPv4
  printf '%s' "$a"
}

detect_session() {
  SESSION_KIND="unknown"
  SSH_CLIENT_IP=""

  # 1) Umgebungsvariable (direkter Login als root oder sudo mit env_keep)
  local env_conn="${SSH_CONNECTION:-${SSH_CLIENT:-}}"
  if [ -n "$env_conn" ]; then
    SESSION_KIND="ssh"
    SSH_CLIENT_IP="$(printf '%s' "$env_conn" | awk '{print $1}')"
  fi

  # 2) Prozesskette: ist sshd ein Vorfahre? (ueberlebt sudo / su)
  local pid=$$ comm ppid sshd_pids="" depth=0
  while [ "$pid" -gt 1 ] && [ "$depth" -lt 30 ]; do
    comm="$(cat "/proc/$pid/comm" 2>/dev/null)" || break
    case "$comm" in
      sshd|sshd-session|sshd-session*) sshd_pids="$sshd_pids $pid" ;;
    esac
    # /proc/<pid>/stat: alles nach der letzten ')' -> Feld 2 = ppid
    ppid="$(sed 's/.*) //' "/proc/$pid/stat" 2>/dev/null | awk '{print $2}')"
    [ -n "$ppid" ] || break
    pid="$ppid"; depth=$(( depth + 1 ))
  done
  if [ -n "$sshd_pids" ]; then
    SESSION_KIND="ssh"
    if [ -z "$SSH_CLIENT_IP" ] && have ss; then
      local p line
      for p in $sshd_pids; do
        line="$(ss -Htnp state established 2>/dev/null | grep -F "pid=$p," | head -n1)"
        [ -n "$line" ] || continue
        # Spalten ohne State: Recv-Q Send-Q Local Peer Process
        SSH_CLIENT_IP="$(_strip_port_and_brackets "$(printf '%s' "$line" | awk '{print $4}')")"
        [ -n "$SSH_CLIENT_IP" ] && break
      done
    fi
    if [ -z "$SSH_CLIENT_IP" ] && have who; then
      # Fallback: who -m zeigt "(1.2.3.4)" am Zeilenende
      SSH_CLIENT_IP="$(who -m 2>/dev/null | sed -n 's/.*(\([^)]*\)).*/\1/p' | head -n1)"
    fi
  fi

  # 3) Keine SSH-Spur: lokale Konsole (Rescue/serial/VNC)? Die kappt keine Firewall.
  if [ "$SESSION_KIND" = "unknown" ]; then
    local t
    t="$(tty 2>/dev/null || true)"
    case "$t" in
      /dev/tty[0-9]*|/dev/ttyS*|/dev/hvc*|/dev/ttyAMA*|/dev/console) SESSION_KIND="console" ;;
    esac
  fi

  export SESSION_KIND SSH_CLIENT_IP
}

# Kommt die SSH-Verbindung aus dem eigenen Server (Loopback / Docker-Netz)?
# Dann ist es mit hoher Wahrscheinlichkeit das Coolify-Web-Terminal: Coolify
# verbindet sich aus seinem Container per SSH mit dem Host.
_ip4_to_int() { local IFS=.; set -- $1; echo $(( ($1<<24) + ($2<<16) + ($3<<8) + $4 )); }
ssh_client_is_local() {
  local ip="$1"
  [ -n "$ip" ] || return 1
  case "$ip" in
    127.*|::1|localhost) return 0 ;;
  esac
  case "$ip" in *.*.*.*) ;; *) return 1 ;; esac
  # Subnetze aller Docker-Bridges (docker0, br-*) pruefen
  have ip || return 1
  local cidr net bits ipn netn mask
  ipn="$(_ip4_to_int "$ip")"
  while read -r cidr; do
    [ -n "$cidr" ] || continue
    net="${cidr%/*}"; bits="${cidr#*/}"
    netn="$(_ip4_to_int "$net")"
    mask=$(( bits == 0 ? 0 : (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
    [ $(( ipn & mask )) -eq $(( netn & mask )) ] && return 0
  done < <(ip -4 -o addr show 2>/dev/null | awk '$2 ~ /^(docker[0-9]+|br-)/ {print $4}')
  return 1
}

# ---------------------------------------------------------------------------
# WATCHDOG – das Herzstueck gegen Aussperren
#
# Vor jeder riskanten Aenderung wird ein Rueckfall-Timer scharf gemacht.
# Der User testet in einem ZWEITEN Terminal, ob er noch reinkommt.
# Klappt es  -> install.sh --confirm entschaerft den Timer.
# Klappt es nicht -> nach X Minuten wird automatisch zurueckgerollt.
# ---------------------------------------------------------------------------
watchdog_available() {
  have systemd-run || have at
}

# watchdog_arm <name> <minuten> <befehl...>
watchdog_arm() {
  local name="$1" minuten="$2"; shift 2
  local unit="${WATCHDOG_UNIT_PREFIX}-${name}"

  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s Watchdog "%s" wuerde in %s Minuten ausloesen: %s\n' \
      "$C_DIM" "$C_RESET" "$name" "$minuten" "$*"
    return 0
  fi

  if have systemd-run; then
    systemd-run --unit="$unit" --on-active="${minuten}min" \
      --description="coolify-shield Rueckfall: $name" \
      /bin/bash -c "$*" >/dev/null 2>&1 \
      || die "Watchdog liess sich nicht scharf machen." "Ohne Watchdog wird nichts Riskantes geaendert."
    state_set "watchdog.$name" "systemd:$unit"
  elif have at; then
    local job; job="$(printf '%s\n' "$*" | at now + "$minuten" minutes 2>&1 | awk '/^job/{print $2}')"
    [ -n "$job" ] || die "Watchdog liess sich nicht scharf machen." "Paket 'at' pruefen oder systemd verwenden."
    state_set "watchdog.$name" "at:$job"
  else
    die "Kein Watchdog moeglich (weder systemd-run noch at)." "systemd oder das Paket 'at' installieren."
  fi

  log "WDOG arm $name ${minuten}min :: $*"
  printf '\n  %s⏱  Rueckfall-Timer laeuft.%s In %s Minuten wird "%s" automatisch zurueckgerollt,\n' \
    "$C_YELLOW$C_BOLD" "$C_RESET" "$minuten" "$name"
  printf '     falls bis dahin niemand bestaetigt, dass der Zugang noch klappt.\n'
  if [ "${MODUS:-}" = "setup" ]; then
    printf '     Das macht gleich dein Laptop-Script von selbst: Es testet von aussen und bestaetigt.\n'
    printf '     Du musst nichts tun.\n'
  else
    local script_pfad="${SCRIPT_DIR:-/opt/coolify-shield}/install.sh"
    printf '     Teste JETZT auf deinem Laptop in einem ZWEITEN Terminal:  %sssh <dein-server>%s\n' "$C_BOLD" "$C_RESET"
    printf '     Kommst du rein (Prompt erscheint)? Dann DORT auf dem Server:\n'
    printf '       %ssudo %s --confirm%s\n' "$C_BOLD" "$script_pfad" "$C_RESET"
    printf '     Kommst du NICHT rein (Permission denied / keine Antwort)? Nichts tun.\n'
    printf '     Nach %s Minuten ist alles wieder wie vorher, dann in der Community melden.\n' "$minuten"
  fi
}

watchdog_disarm() {
  local name="$1" eintrag; eintrag="$(state_get "watchdog.$name")"
  [ -n "$eintrag" ] || return 0
  case "$eintrag" in
    systemd:*) systemctl stop "${eintrag#systemd:}.timer" 2>/dev/null || true
               systemctl reset-failed "${eintrag#systemd:}" 2>/dev/null || true ;;
    at:*)      atrm "${eintrag#at:}" 2>/dev/null || true ;;
  esac
  state_clear "watchdog.$name"
  log "WDOG disarm $name"
  ok "Watchdog \"$name\" entschaerft – Aenderung bleibt bestehen."
}

watchdog_list() {
  ls "$STATE_DIR" 2>/dev/null | sed -n 's/^watchdog\.//p'
}

# ---------------------------------------------------------------------------
# Wurzel-Checks
# ---------------------------------------------------------------------------
need_root() {
  [ "$(id -u)" = "0" ] || die "Das Script braucht Root-Rechte." "So starten: sudo ./install.sh"
}

# ---------------------------------------------------------------------------
# Gefuehrter Ablauf (--setup): Ansagen, Zustand fuer den Laptop, Helfer
# ---------------------------------------------------------------------------
EXIT_REBOOT=75                       # "Server startet neu, komm wieder" (Laptop-Script wertet das aus)
LAPTOP_ENV="$STATE_DIR/laptop.env"   # Das liest das Laptop-Script nach jedem Lauf
WG_SUBNET="10.8.0.0/24"
WG_SERVER_IP="10.8.0.1"
WG_PORT="51820"
WG_DIR="$STATE_DIR/wireguard"
PRIVATE_NETS="127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"

# Der feste Block am Ende jeder Phase. Drei Zeilen, immer gleich aufgebaut.
# next_up "<erledigt>" "<als naechstes>" ["<du musst jetzt>"]
next_up() {
  printf '\n'
  printf '  %s✓ Erledigt:%s      %s\n' "$C_GREEN$C_BOLD" "$C_RESET" "$1"
  printf '  %s▶ Als Naechstes:%s %s\n' "$C_BLUE$C_BOLD" "$C_RESET" "$2"
  [ -n "${3:-}" ] && printf '  %s⏸ Du musst jetzt:%s %s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$3"
  printf '\n'
  log "NEXT erledigt=$1 | naechstes=$2 | du=${3:-}"
}

# Pause: wartet auf Enter. Im --yes-Modus wird nicht gewartet.
pause_enter() {
  [ "$ASSUME_YES" = "1" ] && return 0
  printf '  %s[Enter] wenn du so weit bist%s ' "$C_BOLD" "$C_RESET"
  read -r _ </dev/tty || true
}

# Zustand fuer das Laptop-Script: einfache key=value-Zeilen.
laptop_env_set() {
  [ "$DRY_RUN" = "1" ] && return 0
  mkdir -p "$STATE_DIR"
  touch "$LAPTOP_ENV"
  grep -v "^$1=" "$LAPTOP_ENV" > "$LAPTOP_ENV.tmp" 2>/dev/null || true
  printf '%s=%s\n' "$1" "$2" >> "$LAPTOP_ENV.tmp"
  mv "$LAPTOP_ENV.tmp" "$LAPTOP_ENV"
  chmod 600 "$LAPTOP_ENV"
}

# Oeffentliche IPv4 des Servers (ohne Internet-Abfrage, wenn moeglich)
public_ip() {
  local ip
  ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1)}' | head -n1)"
  case "$ip" in
    10.*|172.1[6-9].*|172.2[0-9].*|172.3[01].*|192.168.*|"") ip="$(curl -4 -fsS --max-time 5 https://ifconfig.me 2>/dev/null || true)" ;;
  esac
  printf '%s' "$ip"
}

# Wartet, bis eine URL antwortet. wait_http <url> <sekunden>
wait_http() {
  local url="$1" max="${2:-300}" t=0
  while [ "$t" -lt "$max" ]; do
    curl -fsS --max-time 3 -o /dev/null "$url" 2>/dev/null && return 0
    printf '.'; sleep 5; t=$(( t + 5 ))
  done
  printf '\n'; return 1
}

# Coolify-Datenbank lesen (nur SELECT). Zugangsdaten aus Coolifys eigener .env.
coolify_psql() {
  local envf="/data/coolify/source/.env" user db
  [ -r "$envf" ] || return 1
  user="$(sed -n 's/^DB_USERNAME=//p' "$envf" | tr -d '"' | head -n1)"
  db="$(sed -n 's/^DB_DATABASE=//p' "$envf" | tr -d '"' | head -n1)"
  docker exec coolify-db psql -U "${user:-coolify}" -d "${db:-coolify}" -tA -c "$1" 2>/dev/null
}

coolify_running() { docker ps --format '{{.Names}}' 2>/dev/null | grep -qx 'coolify'; }

# Zeilen in eine Datei schreiben, im Trockenlauf nur anzeigen.
# write_file <pfad> <modus>  (Inhalt via stdin)
write_file() {
  local pfad="$1" modus="${2:-644}" inhalt
  inhalt="$(cat)"
  if [ "$DRY_RUN" = "1" ]; then
    printf '  %s[trocken]%s schreibe %s (%s):\n' "$C_DIM" "$C_RESET" "$pfad" "$modus"
    printf '%s\n' "$inhalt" | sed 's/^/      │ /'
    return 0
  fi
  backup_file "$pfad"
  mkdir -p "$(dirname "$pfad")"
  printf '%s\n' "$inhalt" > "$pfad"
  chmod "$modus" "$pfad"
  log "FILE $pfad ($modus)"
}
