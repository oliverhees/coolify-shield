#!/usr/bin/env bash
# Phase A :: Grundlagen, risikofrei
#
# Nichts hier kann den Zugang kappen. Kein Watchdog noetig.

phase_basics() {
  step "Phase 6 · Grundschutz (risikofrei)"
  say "  Automatische Sicherheitsupdates und ein Tuersteher gegen Passwort-Rateversuche."
  printf '\n'

  # --- A1: Sicherheitsupdates automatisch --------------------------------
  case "$PKG" in
    apt)
      write_file /etc/apt/apt.conf.d/20auto-upgrades 644 <<'CONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
CONF
      run systemctl enable --now unattended-upgrades
      ok "Sicherheitsupdates laufen ab jetzt automatisch"
      ;;
    dnf)
      run systemctl enable --now dnf-automatic.timer
      ok "Sicherheitsupdates laufen ab jetzt automatisch"
      ;;
    pacman) skip "Arch: keine automatischen Updates (Rolling Release)" ;;
    *)      warn "Automatische Updates fuer $OS_FAMILY nicht eingerichtet" ;;
  esac

  # --- A2: Brute-Force-Schutz ---------------------------------------------
  # ignoreip ist Pflicht: Coolify verbindet sich aus seinem Container per SSH
  # mit dem Host. Wuerde fail2ban das Docker-Netz sperren, bricht Coolify.
  have fail2ban-server || pkg_install fail2ban
  write_file /etc/fail2ban/jail.d/coolify-shield.local 644 <<CONF
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd
ignoreip = $PRIVATE_NETS $WG_SUBNET

[sshd]
enabled = true
CONF
  run systemctl enable --now fail2ban
  run systemctl restart fail2ban
  ok "fail2ban sperrt IPs nach 5 Fehlversuchen fuer eine Stunde"

  # --- A3: Logrotation fuer unser Log -------------------------------------
  write_file /etc/logrotate.d/coolify-shield 644 <<'CONF'
/var/log/coolify-shield.log {
    weekly
    rotate 8
    compress
    missingok
    notifempty
}
CONF

  state_set "phase.basics" "$(date -Iseconds)"
  laptop_env_set "phase" "basics"
  next_up "Automatische Updates und Brute-Force-Schutz aktiv" \
          "SSH wird auf Schluessel-Login umgestellt. Mit Rueckfall-Timer, falls etwas klemmt."
}
