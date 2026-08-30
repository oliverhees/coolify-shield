#!/usr/bin/env bash
# Phase 1 :: Audit
#
# Nur lesen, nie schreiben. Fuellt AUDIT_ROWS fuer den HTML-Report.
# Format je Zeile:  id|titel|status|klartext|wer_behebt_das
#   status: gruen | gelb | rot | unbekannt
#   wer:    script  (Phase B kann das)  |  user (muss geklickt werden)

AUDIT_ROWS=()

audit_add() { AUDIT_ROWS+=("$1|$2|$3|$4|$5"); }

audit_print() {
  local status="$3"
  case "$status" in
    gruen) ok   "$2 – $4" ;;
    gelb)  warn "$2 – $4" ;;
    rot)   err  "$2 – $4" ;;
    *)     skip "$2 – $4" ;;
  esac
}

phase_audit() {
  step "Bestandsaufnahme"
  say "  Es wird nichts geaendert. Nur geschaut, wie es steht."
  printf '\n'

  # --- SSH: Passwort-Login ------------------------------------------------
  local pw_auth
  pw_auth="$(sshd -T 2>/dev/null | awk '/^passwordauthentication /{print $2}')"
  case "$pw_auth" in
    no)  audit_add ssh_password "SSH-Passwortlogin" gruen "deaktiviert" script ;;
    yes) audit_add ssh_password "SSH-Passwortlogin" rot   "aktiv – Bots probieren das rund um die Uhr" script ;;
    *)   audit_add ssh_password "SSH-Passwortlogin" unbekannt "nicht auslesbar" script ;;
  esac

  # --- SSH: Root-Login ----------------------------------------------------
  local root_login
  root_login="$(sshd -T 2>/dev/null | awk '/^permitrootlogin /{print $2}')"
  case "$root_login" in
    no|prohibit-password) audit_add ssh_root "Root-Login per SSH" gruen "abgesichert" script ;;
    yes)                  audit_add ssh_root "Root-Login per SSH" rot "mit Passwort erlaubt" script ;;
    *)                    audit_add ssh_root "Root-Login per SSH" unbekannt "nicht auslesbar" script ;;
  esac

  # --- Firewall -----------------------------------------------------------
  if have ufw && ufw status 2>/dev/null | grep -qi '^Status: active'; then
    audit_add firewall "Firewall" gruen "ufw aktiv" script
  elif have firewall-cmd && firewall-cmd --state 2>/dev/null | grep -qi running; then
    audit_add firewall "Firewall" gruen "firewalld aktiv" script
  else
    audit_add firewall "Firewall" rot "keine aktive Firewall gefunden" script
  fi

  # --- Coolify-Ports oeffentlich? -----------------------------------------
  local offen=""
  for p in 8000 6001 6002; do
    ss -Hltn "sport = :$p" 2>/dev/null | grep -q '0\.0\.0\.0\|\[::\]' && offen="$offen $p"
  done
  if [ -n "$offen" ] && iptables -S DOCKER-USER 2>/dev/null | grep -q 'ctorigdstport 8000'; then
    audit_add coolify_ports "Coolify-Ports" gruen "nur aus dem Tunnel erreichbar (Docker-Regel aktiv)" script
  elif [ -n "$offen" ]; then
    audit_add coolify_ports "Coolify-Ports" rot "oeffentlich erreichbar:$offen" script
  else
    audit_add coolify_ports "Coolify-Ports" gruen "nicht oeffentlich gebunden" script
  fi

  # --- Brute-Force-Schutz -------------------------------------------------
  if systemctl is-active --quiet crowdsec 2>/dev/null; then
    audit_add bruteforce "Brute-Force-Schutz" gruen "CrowdSec laeuft" script
  elif systemctl is-active --quiet fail2ban 2>/dev/null; then
    audit_add bruteforce "Brute-Force-Schutz" gruen "fail2ban laeuft" script
  else
    audit_add bruteforce "Brute-Force-Schutz" gelb "nichts installiert" script
  fi

  # --- Automatische Updates -----------------------------------------------
  if systemctl is-enabled --quiet unattended-upgrades 2>/dev/null \
     || systemctl is-enabled --quiet dnf-automatic.timer 2>/dev/null; then
    audit_add autoupdate "Sicherheitsupdates" gruen "automatisch" script
  else
    audit_add autoupdate "Sicherheitsupdates" gelb "nur manuell" script
  fi

  # --- VPN ----------------------------------------------------------------
  if wg show wg0 >/dev/null 2>&1; then
    audit_add vpn "VPN-Zugang" gruen "WireGuard wg0 aktiv" script
  elif docker ps --format '{{.Names}}' 2>/dev/null | grep -qi 'wg-easy'; then
    audit_add vpn "VPN-Zugang" gruen "wg-easy laeuft" script
  else
    audit_add vpn "VPN-Zugang" gelb "kein VPN – Dashboard haengt am offenen Netz" script
  fi

  # --- Was das Script NICHT pruefen kann ----------------------------------
  # 2FA und Passwortstaerke stecken in Coolifys Datenbank. Da schreibt ein
  # Fremdscript nicht rein und liest auch nichts raus. Bleibt Handarbeit.
  # Seit --setup: Beides steht in Coolifys Datenbank und wird gelesen (nur SELECT).
  local tfa reg
  tfa="$(coolify_psql 'select count(*) from users where two_factor_confirmed_at is not null;' 2>/dev/null || true)"
  reg="$(coolify_psql 'select is_registration_enabled from instance_settings limit 1;' 2>/dev/null || true)"
  if [ -n "$tfa" ] && [ "$tfa" -ge 1 ] 2>/dev/null; then
    audit_add coolify_2fa "Zwei-Faktor in Coolify" gruen "aktiv bei $tfa Nutzer(n)" user
  elif [ -n "$tfa" ]; then
    audit_add coolify_2fa "Zwei-Faktor in Coolify" rot "bei keinem Nutzer aktiv – Profil → Two-factor Authentication" user
  else
    audit_add coolify_2fa "Zwei-Faktor in Coolify" unbekannt \
      "nicht auslesbar – Profil → Two-factor Authentication" user
  fi
  case "$reg" in
    f) audit_add coolify_reg "Registrierung" gruen "geschlossen" user ;;
    t) audit_add coolify_reg "Registrierung" rot "offen – Settings → Registration Allowed ausschalten" user ;;
    *) audit_add coolify_reg "Registrierung offen?" unbekannt \
         "nicht auslesbar – Settings → Registration Allowed" user ;;
  esac
  audit_add coolify_pw "Passwortstaerke" unbekannt \
    "25+ Zeichen aus dem Passwort-Manager" user

  # --- Ausgabe ------------------------------------------------------------
  local zeile
  for zeile in "${AUDIT_ROWS[@]}"; do
    IFS='|' read -r id titel status text wer <<< "$zeile"
    audit_print "$id" "$titel" "$status" "$text" "$wer"
  done

  local rote; rote="$(printf '%s\n' "${AUDIT_ROWS[@]}" | awk -F'|' '$3=="rot"' | wc -l)"
  printf '\n  %s offene Baustellen mit hoher Prioritaet.\n' "$rote"
  state_set "phase.audit" "$(date -Iseconds)"
}
