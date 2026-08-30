#!/usr/bin/env bash
#
#   coolify-shield · Start auf deinem Laptop (Mac und Linux)
#
#   Ein Befehl, der Rest wird erklaert:
#     curl -fsSL https://raw.githubusercontent.com/oliverhees/coolify-shield/main/start.sh -o start.sh && bash start.sh
#
#   Was dieses Script macht:
#     1. SSH-Schluessel anlegen und sauber in ~/.ssh/config eintragen
#     2. Dich durch die Hetzner-Bestellung fuehren (du klickst, ich sage wo)
#     3. Ersten Login testen
#     4. Den Server-Teil hochladen und dort starten
#     5. Nach jedem riskanten Schritt von aussen pruefen und bestaetigen
#     6. WireGuard auf deinem Laptop einrichten und den Tunnel testen
#
#   Es kann jederzeit abgebrochen und neu gestartet werden. Es merkt sich, wo es war.
#
set -uo pipefail

REPO_TARBALL="https://github.com/oliverhees/coolify-shield/archive/refs/heads/main.tar.gz"
STATE_HOME="$HOME/.coolify-shield"
KEY_DIR="$HOME/.ssh/coolify-shield"
SSH_CONFIG="$HOME/.ssh/config"
SERVER_DIR="/opt/coolify-shield"
EXIT_REBOOT=75

# ---------------------------------------------------------------------------
# Ausgabe
# ---------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_DIM=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
fi
say()  { printf '%s\n' "$*"; }
ok()   { printf '  %s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
err()  { printf '  %s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
skip() { printf '  %s–%s %s\n' "$C_DIM" "$C_RESET" "$*"; }
step() { printf '\n%s%s%s\n%s%s%s\n' "$C_BOLD" "$*" "$C_RESET" "$C_DIM" "$(printf '─%.0s' $(seq 1 ${#1}))" "$C_RESET"; }
die()  { printf '\n%s ABBRUCH %s %s\n' "$C_RED$C_BOLD" "$C_RESET" "$1" >&2; [ -n "${2:-}" ] && printf '  Das hilft: %s\n' "$2" >&2; printf '\n' >&2; exit 1; }

next_up() {
  printf '\n'
  printf '  %s✓ Erledigt:%s      %s\n' "$C_GREEN$C_BOLD" "$C_RESET" "$1"
  printf '  %s▶ Als Naechstes:%s %s\n' "$C_BLUE$C_BOLD" "$C_RESET" "$2"
  [ -n "${3:-}" ] && printf '  %s⏸ Du musst jetzt:%s %s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$3"
  printf '\n'
}
pause_enter() { printf '  %s[Enter] wenn du so weit bist%s ' "$C_BOLD" "$C_RESET"; read -r _ </dev/tty || true; }
ask_value() { local a; read -r -p "  $1 [$2] " a </dev/tty || a=""; printf '%s' "${a:-$2}"; }
ask_yn() {
  local a hint; [ "${2:-n}" = "j" ] && hint="[J/n]" || hint="[j/N]"
  read -r -p "  $1 $hint " a </dev/tty || a=""; a="${a:-${2:-n}}"
  case "${a,,}" in j|ja|y|yes) return 0 ;; *) return 1 ;; esac
}

trap 'printf "\n\n  Abgebrochen. Kein Problem: einfach nochmal starten, ich mache da weiter, wo wir waren.\n\n"; exit 130' INT

# ---------------------------------------------------------------------------
# Zustand (lokal, pro Server)
# ---------------------------------------------------------------------------
mkdir -p "$STATE_HOME"; chmod 700 "$STATE_HOME"
state_file() { printf '%s/%s.env' "$STATE_HOME" "$NAME"; }
state_set() { local f; f="$(state_file)"; touch "$f"; grep -v "^$1=" "$f" > "$f.tmp" 2>/dev/null || true; printf '%s=%s\n' "$1" "$2" >> "$f.tmp"; mv "$f.tmp" "$f"; }
state_get() { sed -n "s/^$1=//p" "$(state_file)" 2>/dev/null | head -n1; }

# ---------------------------------------------------------------------------
# System
# ---------------------------------------------------------------------------
OS="$(uname -s)"
case "$OS" in
  Darwin) OS="mac" ;;
  Linux)  OS="linux" ;;
  *) die "Dieses Script laeuft auf Mac und Linux." "Auf Windows: PowerShell oeffnen und start.ps1 verwenden (siehe README)." ;;
esac
for t in ssh ssh-keygen scp curl tar; do
  command -v "$t" >/dev/null 2>&1 || die "Das Programm '$t' fehlt auf deinem Rechner." "Auf dem Mac: Xcode-Kommandozeilenwerkzeuge installieren (xcode-select --install). Auf Linux: openssh-client installieren."
done

clipboard() {
  if command -v pbcopy >/dev/null 2>&1; then pbcopy; return 0; fi
  if command -v wl-copy >/dev/null 2>&1; then wl-copy; return 0; fi
  if command -v xclip >/dev/null 2>&1; then xclip -selection clipboard; return 0; fi
  cat >/dev/null; return 1
}

# ssh_ok: kommt man rein? (ohne Rueckfragen, Hostkey beim ersten Mal annehmen)
# Der letzte Fehler landet in SSH_LAST_ERR, damit wir ihn zeigen koennen.
SSH_LAST_ERR=""
ssh_ok() {
  SSH_LAST_ERR="$(ssh -o BatchMode=yes -o ConnectTimeout=8 -o StrictHostKeyChecking=accept-new "$NAME" true 2>&1 >/dev/null)"
}

# Hetzner vergibt IP-Adressen wieder. Ein alter Fingerabdruck in known_hosts
# fuer diese IP gehoert dann zu einem fremden, laengst geloeschten Server.
# Bei einem gerade frisch bestellten Server darf der Eintrag weg.
forget_hostkey() {
  local ip="$1"
  ssh-keygen -F "$ip" >/dev/null 2>&1 || return 0
  ssh-keygen -R "$ip" >/dev/null 2>&1 && skip "Alter Fingerabdruck fuer $ip aus known_hosts entfernt (IP wurde frueher schon mal vergeben)"
}

# wait_ssh <sekunden>: wartet, bis der Server per SSH antwortet
wait_ssh() {
  local max="${1:-180}" t=0
  printf '  Warte auf den Server '
  while [ "$t" -lt "$max" ]; do
    ssh_ok && { printf '\n'; return 0; }
    printf '.'; sleep 5; t=$(( t + 5 ))
  done
  printf '\n'; return 1
}

# Host-Block in ~/.ssh/config schreiben (ersetzt einen bestehenden Block gleichen Namens)
write_ssh_config() {
  local user="$1" host="${2:-}"
  mkdir -p "$HOME/.ssh"; chmod 700 "$HOME/.ssh"
  [ -f "$SSH_CONFIG" ] || { touch "$SSH_CONFIG"; chmod 600 "$SSH_CONFIG"; }
  # bestehenden Block entfernen: von "Host NAME" bis vor den naechsten "Host "
  awk -v name="$NAME" '
    /^Host / { drop = ($2 == name) }
    !drop { print }
  ' "$SSH_CONFIG" > "$SSH_CONFIG.tmp" && mv "$SSH_CONFIG.tmp" "$SSH_CONFIG"
  {
    printf 'Host %s\n' "$NAME"
    [ -n "$host" ] && printf '    HostName %s\n' "$host"
    printf '    User %s\n' "$user"
    printf '    IdentityFile %s/%s\n' "$KEY_DIR" "$NAME"
    printf '    IdentitiesOnly yes\n'
    printf '    ServerAliveInterval 30\n'
  } >> "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"
}

# laptop.env vom Server lesen -> lokale Variablen
read_server_env() {
  local raw=""
  for _ in 1 2 3; do
    raw="$(ssh -o BatchMode=yes -o ConnectTimeout=8 "$NAME" 'sudo cat /var/lib/coolify-shield/laptop.env 2>/dev/null || cat /var/lib/coolify-shield/laptop.env 2>/dev/null' 2>/dev/null || true)"
    [ -n "$raw" ] && break
    sleep 5
  done
  S_PHASE="$(printf '%s\n' "$raw" | sed -n 's/^phase=//p' | tail -n1)"
  S_ADMIN="$(printf '%s\n' "$raw" | sed -n 's/^admin_user=//p' | tail -n1)"
  S_WGCONF="$(printf '%s\n' "$raw" | sed -n 's/^wg_client_conf=//p' | tail -n1)"
  S_WGIP="$(printf '%s\n' "$raw" | sed -n 's/^wg_server_ip=//p' | tail -n1)"
  S_REBOOT="$(printf '%s\n' "$raw" | sed -n 's/^reboot=//p' | tail -n1)"
  S_WATCHDOG="$(printf '%s\n' "$raw" | sed -n 's/^watchdog=//p' | tail -n1)"
}

# Server-Script starten (interaktiv). Gibt den Exit-Code zurueck.
run_server() {
  local sudo_prefix=""
  [ "$(state_get user)" != "root" ] && sudo_prefix="sudo "
  ssh -t -o ConnectTimeout=10 "$NAME" "${sudo_prefix}$SERVER_DIR/install.sh --setup"
}

# ---------------------------------------------------------------------------
# Schritt 5 · WireGuard auf dem Laptop (wird aufgerufen, sobald der Server
# die Firewall scharf hat; danach geht es auf dem Server weiter)
# ---------------------------------------------------------------------------
setup_tunnel() {
  step "Schritt 5 · Dein Tunnel"
  say "  Der Server ist jetzt dicht. Das Dashboard erreichst du nur noch durch den Tunnel."
  say "  Ich richte WireGuard auf diesem Rechner ein und schalte den Tunnel ein."
  printf '\n'
WGCONF="$STATE_HOME/$NAME-laptop.conf"
  if [ -n "$S_WGCONF" ]; then
    ssh -o BatchMode=yes "$NAME" "sudo cat $S_WGCONF" > "$WGCONF" 2>/dev/null && chmod 600 "$WGCONF" \
      && ok "Tunnel-Datei geholt: $WGCONF" || warn "Tunnel-Datei konnte nicht geholt werden"
  fi
  WGIP="${S_WGIP:-10.8.0.1}"
  
  case "$OS" in
    mac)
      if [ -d "/Applications/WireGuard.app" ]; then
        ok "WireGuard-App ist installiert"
      else
        say "  Ich oeffne den App Store mit der WireGuard-App. Bitte installieren."
        open "macappstore://apps.apple.com/app/wireguard/id1451685025" 2>/dev/null || say "  https://apps.apple.com/app/wireguard/id1451685025"
        pause_enter
      fi
      open -a WireGuard 2>/dev/null || true
      next_up "Tunnel-Datei liegt bereit" "Tunnel in der App importieren und einschalten." \
        "In WireGuard: \"Tunnel aus Datei importieren\" → $WGCONF → dann \"Aktivieren\"."
      pause_enter
      ;;
    linux)
      if ! command -v wg >/dev/null 2>&1; then
        say "  Ich installiere WireGuard (fragt nach deinem Passwort)."
        if command -v apt-get >/dev/null 2>&1; then sudo apt-get install -y -q wireguard-tools
        elif command -v dnf >/dev/null 2>&1; then sudo dnf install -y wireguard-tools
        elif command -v pacman >/dev/null 2>&1; then sudo pacman -S --noconfirm wireguard-tools
        else warn "Paketmanager unbekannt, bitte wireguard-tools selbst installieren"; fi
      fi
      if command -v nmcli >/dev/null 2>&1; then
        nmcli connection delete "$NAME-laptop" >/dev/null 2>&1 || true
        cp "$WGCONF" "$STATE_HOME/$NAME-laptop.tmp.conf"
        if sudo nmcli connection import type wireguard file "$WGCONF" >/dev/null 2>&1; then
          sudo nmcli connection modify "$NAME-laptop" connection.autoconnect no >/dev/null 2>&1 || true
          sudo nmcli connection up "$NAME-laptop" >/dev/null 2>&1 && ok "Tunnel an (NetworkManager: $NAME-laptop)"
        else
          warn "nmcli-Import fehlgeschlagen, versuche wg-quick"
          sudo cp "$WGCONF" "/etc/wireguard/$NAME.conf" && sudo wg-quick up "$NAME" && ok "Tunnel an (wg-quick $NAME)"
        fi
        rm -f "$STATE_HOME/$NAME-laptop.tmp.conf"
      else
        sudo cp "$WGCONF" "/etc/wireguard/$NAME.conf" && sudo wg-quick up "$NAME" && ok "Tunnel an (wg-quick $NAME)"
      fi
      ;;
  esac
  
  if curl -s --max-time 6 -o /dev/null "http://$WGIP:8000"; then
    ok "Dashboard durch den Tunnel erreichbar: http://$WGIP:8000"
  else
    warn "Dashboard antwortet nicht durch den Tunnel."
    say  "  Ist der Tunnel wirklich an? (Linux: nmcli connection up $NAME-laptop / Mac: WireGuard-App, Schalter an)"
    say  "  Dann Enter, ich teste nochmal."
    pause_enter
  fi
  if curl -s --max-time 6 -o /dev/null "http://$WGIP:8000"; then
    ssh -o BatchMode=yes "$NAME" "sudo bash -c 'mkdir -p /var/lib/coolify-shield; echo ok > /var/lib/coolify-shield/tunnel.ok'" >/dev/null 2>&1
    state_set tunnel ok
    return 0
  fi
  return 1
}

# ===========================================================================
printf '\n%s  coolify-shield%s  %sDein Server. Deine Tuer. Dein Schluessel.%s\n\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
say "  Ich fuehre dich Schritt fuer Schritt. Wenn ich dich brauche, steht da"
say "  \"Du musst jetzt\". Enter ist fast immer die richtige Antwort."
printf '\n'

# ---------------------------------------------------------------------------
# Schritt 1 · Name und Schluessel
# ---------------------------------------------------------------------------
step "Schritt 1 · Dein Schluessel"
say "  Ein SSH-Schluessel ist wie ein Haustuerschluessel fuer den Server: zwei Haelften,"
say "  eine bleibt bei dir (privat), die andere kommt auf den Server (oeffentlich)."
say "  Kein Passwort, nichts zu raten."
printf '\n'
versuche=0
while :; do
  NAME="$(ask_value 'Wie soll dein Server heissen? (kurz, klein, ohne Leerzeichen)' 'coolify')"
  [[ "$NAME" =~ ^[a-z0-9][a-z0-9-]{0,30}$ ]] && break
  warn "Nur Kleinbuchstaben, Ziffern und Bindestrich."
  versuche=$(( versuche + 1 )); [ "$versuche" -ge 10 ] && die "Zehnmal kein gueltiger Name." "Beispiel: coolify oder mein-server"
done
state_set name "$NAME"
[ -n "$(state_get user)" ] || state_set user root

mkdir -p "$KEY_DIR"; chmod 700 "$KEY_DIR"
KEY="$KEY_DIR/$NAME"
if [ -f "$KEY" ]; then
  skip "Schluessel $KEY gibt es schon, ich nehme den"
else
  say "  Du kannst den Schluessel mit einem Passwort schuetzen (empfohlen, wird bei jedem"
  say "  Login gefragt) oder Enter druecken fuer ohne."
  ssh-keygen -t ed25519 -f "$KEY" -C "coolify-shield $NAME" </dev/tty || die "Schluessel konnte nicht erzeugt werden."
  ok "Schluessel erzeugt: $KEY"
fi
write_ssh_config "$(state_get user)" "$(state_get ip)"
ok "Eintrag in ~/.ssh/config: ab jetzt reicht  ssh $NAME"
say "  (Der Eintrag sagt SSH auch, NUR diesen Schluessel zu probieren. Sonst meckert der"
say "   Server irgendwann mit \"Too many authentication failures\".)"

PUBKEY="$(cat "$KEY.pub")"
if printf '%s' "$PUBKEY" | clipboard; then
  ok "Oeffentlicher Schluessel ist in der Zwischenablage"
else
  warn "Konnte nicht in die Zwischenablage kopieren. Bitte die Zeile unten von Hand markieren."
fi
next_up "Schluessel liegt in $KEY_DIR, SSH-Eintrag \"$NAME\" steht" \
        "Server bei Hetzner bestellen. Ich sage dir, wo du klickst."

# ---------------------------------------------------------------------------
# Schritt 2 · Hetzner
# ---------------------------------------------------------------------------
step "Schritt 2 · Server bestellen (Hetzner)"
if [ -n "$(state_get ip)" ] && ssh_ok; then
  skip "Server $(state_get ip) antwortet schon, Bestellung uebersprungen"
else
  printf '  Dein oeffentlicher Schluessel (eine Zeile, komplett kopieren):\n\n'
  printf '  %s%s%s\n\n' "$C_BOLD" "$PUBKEY" "$C_RESET"
  cat <<ANLEITUNG
  So geht es bei Hetzner (Cloud Console: https://console.hetzner.cloud):

   1. Konto anlegen oder einloggen, ein Projekt oeffnen (oder "Neues Projekt")
   2. Links "Security" → Reiter "SSH Keys" → "SSH-Key hinzufuegen"
      Schluessel von oben einfuegen, Name z. B. "$NAME", speichern
   3. "Server" → "Server hinzufuegen":
        Standort:  egal, z. B. Nuernberg oder Helsinki
        Image:     Ubuntu 24.04
        Typ:       Shared vCPU, mindestens 4 GB RAM
        SSH-Key:   deinen Schluessel "$NAME" ANHAKEN (wichtig, sonst kommst du nicht rein)
        Name:      $NAME
      "Kostenpflichtig bestellen". Nach etwa einer Minute steht die IP-Adresse da.
   4. Einmal die Rescue-Konsole oeffnen: Server anklicken → oben rechts das
      Bildschirm-Symbol ("Console"). Das ist dein Notausgang, falls spaeter mal
      etwas klemmt. Tab offen lassen.

ANLEITUNG
  pause_enter
  versuche=0
  while :; do
    IP="$(ask_value 'IP-Adresse des Servers (steht in der Serverliste)' "$(state_get ip)")"
    [[ "$IP" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] && break
    warn "Das sieht nicht nach einer IPv4-Adresse aus (z. B. 65.21.12.34)."
    versuche=$(( versuche + 1 )); [ "$versuche" -ge 10 ] && die "Zehnmal keine gueltige IP-Adresse." "Bei Hetzner in der Serverliste steht sie in der Spalte IPv4."
  done
  state_set ip "$IP"
  write_ssh_config "$(state_get user)" "$IP"
  forget_hostkey "$IP"
fi
next_up "Server bestellt, Adresse $(state_get ip) eingetragen" \
        "Ich teste, ob dein Schluessel am Server passt."

# ---------------------------------------------------------------------------
# Schritt 3 · Erster Login
# ---------------------------------------------------------------------------
step "Schritt 3 · Erster Login"
versuche=0
until wait_ssh 180; do
  versuche=$(( versuche + 1 )); [ "$versuche" -ge 10 ] && die "Nach zehn Anlaeufen kein Login." "Server bei Hetzner pruefen (laeuft er? Key angehakt?), dann start.sh erneut."
  err "Ich komme nicht auf den Server."
  case "$SSH_LAST_ERR" in
    *"REMOTE HOST IDENTIFICATION HAS CHANGED"*)
      say "  SSH kennt diese IP mit einem anderen Fingerabdruck (die IP hatte frueher einen anderen Server)."
      forget_hostkey "$(state_get ip)"; continue ;;
    *"Permission denied"*)   say "  SSH sagt: Schluessel wird nicht akzeptiert. Wurde der Key beim Bestellen angehakt?" ;;
    *"Connection refused"*)  say "  SSH sagt: Verbindung abgelehnt. Der Server bootet wahrscheinlich noch." ;;
    *"timed out"*|*"No route"*) say "  SSH sagt: keine Antwort. IP pruefen, oder der Server ist noch nicht fertig." ;;
    "") ;;
    *) say "  SSH sagt: $(printf '%s' "$SSH_LAST_ERR" | tail -n1)" ;;
  esac
  say "  Haeufigste Gruende:"
  say "   · Beim Bestellen wurde der SSH-Key nicht angehakt → Server loeschen, neu bestellen (kostet nichts extra)"
  say "   · IP vertippt → gleich nochmal eingeben"
  say "   · Server ist noch nicht fertig → einfach nochmal warten"
  printf '\n'
  antwort="$(ask_value 'Nochmal warten = Enter, oder die richtige IP eintippen' "$(state_get ip)")"
  if [[ "$antwort" =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]] && [ "$antwort" != "$(state_get ip)" ]; then
    state_set ip "$antwort"; write_ssh_config "$(state_get user)" "$antwort"; forget_hostkey "$antwort"
  fi
done
ok "Login klappt: ssh $NAME"
next_up "Du kommst per Schluessel auf den Server" \
        "Ich lade den Server-Teil hoch und starte ihn. Ab jetzt redet der Server mit dir."

# ---------------------------------------------------------------------------
# Schritt 4 · Server-Teil hochladen und starten (Schleife bis fertig)
# ---------------------------------------------------------------------------
step "Schritt 4 · Einrichtung auf dem Server"
upload_server_part() {
  local sudo_prefix=""; [ "$(state_get user)" != "root" ] && sudo_prefix="sudo "
  ssh -o BatchMode=yes "$NAME" "${sudo_prefix}bash -c 'set -e; mkdir -p $SERVER_DIR; curl -fsSL $REPO_TARBALL | tar xz -C $SERVER_DIR --strip-components=1; chmod +x $SERVER_DIR/install.sh'" \
    || die "Der Server-Teil liess sich nicht hochladen." "Hat der Server Internet? Nochmal starten."
}
upload_server_part
ok "Server-Teil liegt unter $SERVER_DIR"
ssh -o BatchMode=yes "$NAME" "sudo bash -c 'mkdir -p /var/lib/coolify-shield; grep -q ^driver= /var/lib/coolify-shield/laptop.env 2>/dev/null || echo driver=laptop >> /var/lib/coolify-shield/laptop.env'" >/dev/null 2>&1

runde=0
while :; do
  runde=$(( runde + 1 )); [ "$runde" -gt 20 ] && die "Zu viele Durchlaeufe. Irgendetwas haengt." "Ausgabe oben in der Community posten."
  printf '\n  %s──── Server-Ausgabe ────%s\n' "$C_DIM" "$C_RESET"
  run_server; rc=$?
  printf '  %s──── Ende Server-Ausgabe ────%s\n\n' "$C_DIM" "$C_RESET"
  read_server_env

  # Reboot noetig?
  if [ "$rc" -eq "$EXIT_REBOOT" ] || [ "$S_REBOOT" = "pending" ]; then
    say "  Der Server startet neu. Das dauert etwa eine Minute."
    ssh -o BatchMode=yes "$NAME" 'sudo rm -f /var/lib/coolify-shield/reboot-pending; sudo sed -i "/^reboot=/d" /var/lib/coolify-shield/laptop.env; sudo systemd-run --on-active=2s /sbin/reboot' >/dev/null 2>&1 || true
    sleep 20
    wait_ssh 300 || die "Der Server ist nach dem Neustart nicht erreichbar." "Bei Hetzner in der Serverliste nachsehen, ob er laeuft. Dann start.sh erneut."
    continue
  fi

  # Neuer Admin-Benutzer bekannt? Dann ab jetzt als dieser einloggen.
  if [ -n "$S_ADMIN" ] && [ "$(state_get user)" != "$S_ADMIN" ]; then
    write_ssh_config "$S_ADMIN" "$(state_get ip)"
    if ssh_ok; then
      state_set user "$S_ADMIN"
      ok "Ab jetzt loggst du dich als $S_ADMIN ein: ssh $NAME"
    else
      write_ssh_config "root" "$(state_get ip)"
      warn "Login als $S_ADMIN klappt noch nicht, ich bleibe bei root."
    fi
  fi

  # Rueckfall-Timer aktiv? Dann von aussen testen und bestaetigen.
  if [ -n "$S_WATCHDOG" ] && [ "$(state_get confirmed)" != "$S_WATCHDOG" ]; then
    step "Pruefung von aussen (Timer laeuft)"
    fehl=0
    case "$S_WATCHDOG" in
      ssh)
        ssh_ok && ok "Login per Schluessel klappt" || { err "Login klappt NICHT"; fehl=1; }
        if ssh -o BatchMode=yes -o PubkeyAuthentication=no -o ConnectTimeout=8 "$NAME" true 2>/dev/null; then
          err "Login OHNE Schluessel klappt noch (sollte nicht)"; fehl=1
        else
          ok "Ohne Schluessel kommt niemand rein"
        fi
        ;;
      firewall)
        ssh_ok && ok "SSH geht weiterhin" || { err "SSH geht NICHT mehr"; fehl=1; }
        if curl -4 -s --max-time 5 -o /dev/null "http://$(state_get ip):8000" 2>/dev/null; then
          err "Port 8000 ist von aussen noch offen"; fehl=1
        else
          ok "Port 8000 ist von aussen zu (IPv4)"
        fi
        if curl -6 -s --max-time 5 -o /dev/null "http://$(state_get ip):8000" 2>/dev/null; then
          err "Port 8000 ist ueber IPv6 noch offen"; fehl=1
        else
          ok "Port 8000 ist von aussen zu (IPv6 oder kein IPv6)"
        fi
        ;;
    esac
    if [ "$fehl" -eq 0 ]; then
      if ssh -o BatchMode=yes "$NAME" "sudo $SERVER_DIR/install.sh --confirm" >/dev/null 2>&1; then
        ok "Bestaetigt, Rueckfall-Timer entschaerft"; state_set confirmed "$S_WATCHDOG"
      else
        warn "Konnte nicht bestaetigen. Der Timer rollt in 10 Minuten zurueck; einfach start.sh erneut."
      fi
    else
      warn "Ich bestaetige NICHT. Der Server nimmt die Aenderung in 10 Minuten von selbst zurueck."
      say  "  Danach start.sh erneut starten, dann versuchen wir es nochmal."
      exit 1
    fi
    continue
  fi

  if [ "$S_PHASE" = "tunnel" ]; then
    until setup_tunnel; do
      ask_yn "Tunnel nochmal versuchen?" "j" || { warn "Ohne Tunnel kommst du nicht ans Dashboard. Spaeter: bash start.sh erneut."; exit 1; }
    done
    continue
  fi
  [ "$S_PHASE" = "done" ] && break
  if [ "$rc" -ne 0 ]; then
    warn "Der Server-Teil ist mit Fehler beendet (Code $rc). Siehe Ausgabe oben."
    ask_yn "Nochmal versuchen?" "j" || exit 1
  fi
done
[ "$(state_get tunnel)" = "ok" ] || setup_tunnel || warn "Tunnel-Test nicht bestanden, siehe oben."


# ---------------------------------------------------------------------------
# Fertig
# ---------------------------------------------------------------------------
step "Fertig"
cat <<FERTIG

  $(printf '%s' "$C_BOLD")So kommst du ab jetzt rein:$(printf '%s' "$C_RESET")

   Dashboard:  Tunnel einschalten, dann  http://$WGIP:8000
   Handy:      WireGuard-App, QR-Code vom Server gescannt → Tunnel an → dieselbe Adresse
   Server:     ssh $NAME        (Benutzer $(state_get user), Schluessel in $KEY_DIR)
   Chef sein:  sudo <befehl>    (ohne Passwort)

  Von aussen ist das Dashboard zu. Ohne Tunnel: nichts. Genau so soll es sein.

  Ausgesperrt? NOTFALL.md im Repo, oder die Rescue-Konsole bei Hetzner.
  Nochmal pruefen, wie es dem Server geht:  ssh $NAME sudo $SERVER_DIR/install.sh --status

FERTIG
