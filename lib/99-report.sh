#!/usr/bin/env bash
# Phase 9 :: HTML-Report
#
# STATUS: STUB mit funktionierendem Grundgeruest.
#
# Der Report ist nicht nur Doku, er ist das Marketing-Stueck: Leute posten
# ihren Score in der Community. Er muss also gut aussehen UND ehrlich sein.

REPORT_PATH="/root/coolify-shield-report.html"

phase_report() {
  step "Phase 10 · Report"

  local gruen=0 gelb=0 rot=0 offen=0 zeile
  for zeile in "${AUDIT_ROWS[@]}"; do
    case "$(printf '%s' "$zeile" | cut -d'|' -f3)" in
      gruen) gruen=$((gruen+1)) ;;
      gelb)  gelb=$((gelb+1))  ;;
      rot)   rot=$((rot+1))    ;;
      *)     offen=$((offen+1));;
    esac
  done
  local gesamt=$((gruen+gelb+rot)) score=0
  [ "$gesamt" -gt 0 ] && score=$(( (gruen*100 + gelb*50) / gesamt ))

  # TODO: Vollstaendiges Template mit Aiianer-Look (schwarz/rot), Ampelliste,
  #       Restaufgaben mit direkten Links ins Coolify-Dashboard, Kurs-Verweise.
  # TODO: Zweite Ansicht "vorher/nachher" nach einem zweiten Lauf.
  # TODO: Teilen-Button, der nur den Score exportiert, keine Serverdaten.
  {
    printf '<!doctype html><meta charset="utf-8"><title>Coolify Shield</title>'
    printf '<h1>Sicherheits-Score: %s / 100</h1>' "$score"
    printf '<p>%s ok · %s Warnungen · %s kritisch · %s musst du selbst pruefen</p>' \
      "$gruen" "$gelb" "$rot" "$offen"
    printf '<p>STUB – vollstaendiger Report folgt.</p>'
  } > "$REPORT_PATH"

  ok "Report: $REPORT_PATH"
  printf '\n  Score: %s%s/100%s\n' "$C_BOLD" "$score" "$C_RESET"
  printf '  Herunterladen: scp root@<server>:%s .\n' "$REPORT_PATH"

  if [ "$offen" -gt 0 ]; then
    printf '\n  %sDas kann kein Script fuer dich machen:%s\n' "$C_BOLD" "$C_RESET"
    for zeile in "${AUDIT_ROWS[@]}"; do
      # shellcheck disable=SC2034
      IFS='|' read -r _ titel status text wer <<< "$zeile"
      [ "$wer" = "user" ] && printf '   □ %s: %s\n' "$titel" "$text"
    done
  fi

}
