#
#   coolify-shield · Start auf deinem Laptop (Windows 10 und 11)
#
#   Ein Befehl, der Rest wird erklaert:
#     irm https://raw.githubusercontent.com/oliverhees/coolify-shield/main/start.ps1 -OutFile start.ps1; .\start.ps1
#
#   Falls Windows die Ausfuehrung blockiert ("... kann nicht geladen werden"):
#     Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
#   Danach den Befehl oben nochmal.
#
#   Was dieses Script macht:
#     1. SSH-Schluessel anlegen und sauber in %USERPROFILE%\.ssh\config eintragen
#     2. Dich durch die Hetzner-Bestellung fuehren (du klickst, ich sage wo)
#     3. Ersten Login testen
#     4. Den Server-Teil hochladen und dort starten
#     5. Nach jedem riskanten Schritt von aussen pruefen und bestaetigen
#     6. WireGuard auf deinem Laptop einrichten und den Tunnel testen
#
#   Es kann jederzeit abgebrochen und neu gestartet werden. Es merkt sich, wo es war.
#
#   Laeuft mit Windows PowerShell 5.1 und PowerShell 7.
#

$ErrorActionPreference = 'Continue'
$ProgressPreference    = 'SilentlyContinue'

# Damit die Symbole und Umlaute in der Konsole ankommen.
try {
    [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)
} catch {
    # Aeltere Konsolen koennen das nicht. Dann eben ohne, ist nur Kosmetik.
}

$RepoTarball = 'https://github.com/oliverhees/coolify-shield/archive/refs/heads/main.tar.gz'
$StateHome   = Join-Path $HOME '.coolify-shield'
$SshHome     = Join-Path $HOME '.ssh'
$KeyDir      = Join-Path $SshHome 'coolify-shield'
$SshConfig   = Join-Path $SshHome 'config'
$ServerDir   = '/opt/coolify-shield'
$ExitReboot  = 75
$WgExe       = 'C:\Program Files\WireGuard\wireguard.exe'

# Wird in Schritt 1 gesetzt, danach von fast allem benutzt.
$Name = ''

# ---------------------------------------------------------------------------
# Ausgabe
# ---------------------------------------------------------------------------
function Show-Say  { param([string]$Text) Write-Host $Text }
function Show-Ok   { param([string]$Text) Write-Host '  ' -NoNewline; Write-Host ([char]0x2713) -ForegroundColor Green -NoNewline; Write-Host (' ' + $Text) }
function Show-Warn { param([string]$Text) Write-Host '  ' -NoNewline; Write-Host '!' -ForegroundColor Yellow -NoNewline; Write-Host (' ' + $Text) }
function Show-Err  { param([string]$Text) Write-Host '  ' -NoNewline; Write-Host ([char]0x2717) -ForegroundColor Red -NoNewline; Write-Host (' ' + $Text) }
function Show-Skip { param([string]$Text) Write-Host '  ' -NoNewline; Write-Host ([char]0x2013) -ForegroundColor DarkGray -NoNewline; Write-Host (' ' + $Text) }

function Show-Step {
    param([string]$Text)
    Write-Host ''
    Write-Host $Text -ForegroundColor White
    Write-Host (([string][char]0x2500) * $Text.Length) -ForegroundColor DarkGray
}

function Show-NextUp {
    param([string]$Erledigt, [string]$Naechstes, [string]$DuMusst = '')
    Write-Host ''
    Write-Host '  ' -NoNewline
    Write-Host ([string][char]0x2713 + ' Erledigt:') -ForegroundColor Green -NoNewline
    Write-Host ('      ' + $Erledigt)
    Write-Host '  ' -NoNewline
    Write-Host ([string][char]0x25B6 + ' Als Naechstes:') -ForegroundColor Blue -NoNewline
    Write-Host (' ' + $Naechstes)
    if ($DuMusst -ne '') {
        Write-Host '  ' -NoNewline
        Write-Host ([string][char]0x23F8 + ' Du musst jetzt:') -ForegroundColor Yellow -NoNewline
        Write-Host (' ' + $DuMusst)
    }
    Write-Host ''
}

function Stop-WithMessage {
    param([string]$Was, [string]$Hilfe = '')
    Write-Host ''
    Write-Host ' ABBRUCH ' -ForegroundColor Red -NoNewline
    Write-Host (' ' + $Was)
    if ($Hilfe -ne '') { Write-Host ('  Das hilft: ' + $Hilfe) }
    Write-Host ''
    # Geplantes Ende, kein Strg+C. Der finally-Block soll nichts mehr dazusagen.
    $script:Durchgelaufen = $true
    exit 1
}

function Wait-Enter {
    Write-Host '  [Enter] wenn du so weit bist ' -NoNewline
    $null = Read-Host
}

function Read-Value {
    param([string]$Frage, [string]$Default = '')
    $antwort = Read-Host ('  ' + $Frage + ' [' + $Default + ']')
    if ($null -eq $antwort) { $antwort = '' }
    $antwort = $antwort.Trim()
    if ($antwort -eq '') { return $Default }
    return $antwort
}

function Read-YesNo {
    param([string]$Frage, [string]$Default = 'n')
    if ($Default -eq 'j') { $hint = '[J/n]' } else { $hint = '[j/N]' }
    $antwort = Read-Host ('  ' + $Frage + ' ' + $hint)
    if ($null -eq $antwort) { $antwort = '' }
    $antwort = $antwort.Trim()
    if ($antwort -eq '') { $antwort = $Default }
    switch ($antwort.ToLower()) {
        'j'   { return $true }
        'ja'  { return $true }
        'y'   { return $true }
        'yes' { return $true }
    }
    return $false
}

# ---------------------------------------------------------------------------
# Zustand (lokal, pro Server)
# ---------------------------------------------------------------------------
function Get-StateFile { return (Join-Path $StateHome ($Name + '.env')) }

function Set-State {
    param([string]$Key, [string]$Value)
    if (-not (Test-Path -LiteralPath $StateHome)) {
        $null = New-Item -ItemType Directory -Path $StateHome -Force
    }
    $datei = Get-StateFile
    $zeilen = @()
    if (Test-Path -LiteralPath $datei) {
        $zeilen = @(Get-Content -LiteralPath $datei -ErrorAction SilentlyContinue |
                    Where-Object { $_ -notmatch ('^' + [regex]::Escape($Key) + '=') })
    }
    $zeilen += ($Key + '=' + $Value)
    Write-TextFileNoBom -Path $datei -Text (($zeilen -join "`n") + "`n")
}

function Get-State {
    param([string]$Key)
    $datei = Get-StateFile
    if (-not (Test-Path -LiteralPath $datei)) { return '' }
    $treffer = @(Get-Content -LiteralPath $datei -ErrorAction SilentlyContinue |
                 Where-Object { $_ -match ('^' + [regex]::Escape($Key) + '=') })
    if ($treffer.Count -eq 0) { return '' }
    $letzte = [string]$treffer[$treffer.Count - 1]
    return $letzte.Substring($Key.Length + 1)
}

# ---------------------------------------------------------------------------
# Dateien schreiben. OpenSSH vertraegt kein BOM, deshalb ueberall ohne.
# ---------------------------------------------------------------------------
function Write-TextFileNoBom {
    param([string]$Path, [string]$Text)
    $ordner = Split-Path -Parent $Path
    if ($ordner -and -not (Test-Path -LiteralPath $ordner)) {
        $null = New-Item -ItemType Directory -Path $ordner -Force
    }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}

# ---------------------------------------------------------------------------
# Externe Programme
#
# Native EXE-Aufrufe mit 2>&1: PowerShell verpackt stderr-Zeilen in
# ErrorRecords. Genau daran trennen wir wieder, ohne dass etwas auf dem
# Bildschirm landet. Das laeuft in 5.1 und in 7 gleich.
# ---------------------------------------------------------------------------
function Invoke-Quiet {
    param([string]$Exe, [string[]]$ArgList)
    $roh = & $Exe @ArgList 2>&1
    $code = $LASTEXITCODE
    $aus = @()
    $fehler = @()
    foreach ($eintrag in @($roh)) {
        if ($eintrag -is [System.Management.Automation.ErrorRecord]) {
            $fehler += [string]$eintrag
        } else {
            $aus += [string]$eintrag
        }
    }
    return New-Object PSObject -Property @{
        Code   = $code
        Out    = $aus
        Err    = $fehler
    }
}

function Test-Programme {
    $fehlend = @()
    foreach ($prog in @('ssh.exe', 'ssh-keygen.exe', 'scp.exe', 'curl.exe')) {
        if (-not (Get-Command $prog -ErrorAction SilentlyContinue)) { $fehlend += $prog }
    }
    if ($fehlend.Count -gt 0) {
        Stop-WithMessage ('Diese Programme fehlen auf deinem Rechner: ' + ($fehlend -join ', ')) `
            'Einstellungen oeffnen, dann Apps, dann Optionale Features, dann Feature hinzufuegen, dann "OpenSSH-Client" installieren. Danach dieses Fenster schliessen, neu oeffnen und das Script erneut starten.'
    }
}

# Der Vorsatz fuer alles, was auf dem Server Rechte braucht.
function Get-SudoPrefix {
    if ((Get-State 'user') -ne 'root') { return 'sudo ' }
    return ''
}

# ssh_ok: kommt man rein? (ohne Rueckfragen, Hostkey beim ersten Mal annehmen)
function Test-SshLogin {
    $r = Invoke-Quiet 'ssh.exe' @(
        '-o', 'BatchMode=yes',
        '-o', 'ConnectTimeout=8',
        '-o', 'StrictHostKeyChecking=accept-new',
        $Name, 'true'
    )
    return ($r.Code -eq 0)
}

# Wartet, bis der Server per SSH antwortet.
function Wait-Ssh {
    param([int]$MaxSekunden = 180)
    Write-Host '  Warte auf den Server ' -NoNewline
    $t = 0
    while ($t -lt $MaxSekunden) {
        if (Test-SshLogin) { Write-Host ''; return $true }
        Write-Host '.' -NoNewline
        Start-Sleep -Seconds 5
        $t = $t + 5
    }
    Write-Host ''
    return $false
}

# Host-Block in ~/.ssh/config schreiben (ersetzt einen bestehenden Block gleichen Namens)
function Write-SshConfig {
    param([string]$User, [string]$HostAdresse = '')

    if (-not (Test-Path -LiteralPath $SshHome)) {
        $null = New-Item -ItemType Directory -Path $SshHome -Force
    }

    $behalten = @()
    if (Test-Path -LiteralPath $SshConfig) {
        $drop = $false
        foreach ($zeile in @(Get-Content -LiteralPath $SshConfig -ErrorAction SilentlyContinue)) {
            $text = [string]$zeile
            if ($text -match '^\s*Host\s+(\S+)') {
                # Wie im Bash-Script: nur der erste Name hinter "Host" zaehlt.
                $drop = ($matches[1] -ceq $Name)
            }
            if (-not $drop) { $behalten += $text }
        }
    }

    $keyPfad = Join-Path $KeyDir $Name
    if ($keyPfad -match '\s') { $keyEintrag = '"' + $keyPfad + '"' } else { $keyEintrag = $keyPfad }

    $neu = @()
    $neu += ('Host ' + $Name)
    if ($HostAdresse -ne '') { $neu += ('    HostName ' + $HostAdresse) }
    $neu += ('    User ' + $User)
    $neu += ('    IdentityFile ' + $keyEintrag)
    $neu += '    IdentitiesOnly yes'
    $neu += '    ServerAliveInterval 30'

    $alles = @($behalten) + @($neu)
    Write-TextFileNoBom -Path $SshConfig -Text (($alles -join "`n") + "`n")
}

# laptop.env vom Server lesen. Setzt die S_*-Variablen im Skript-Bereich.
function Read-ServerEnv {
    $script:S_Phase    = ''
    $script:S_Admin    = ''
    $script:S_WgConf   = ''
    $script:S_WgIp     = ''
    $script:S_Reboot   = ''
    $script:S_Watchdog = ''
    $script:S_ServerIp = ''

    $befehl = 'sudo cat /var/lib/coolify-shield/laptop.env 2>/dev/null || cat /var/lib/coolify-shield/laptop.env 2>/dev/null'
    $r = Invoke-Quiet 'ssh.exe' @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=8', $Name, $befehl)
    if ($r.Code -ne 0) { return }

    foreach ($zeile in @($r.Out)) {
        $text = ([string]$zeile).Trim()
        if ($text -match '^phase=(.*)$')          { $script:S_Phase    = $matches[1]; continue }
        if ($text -match '^admin_user=(.*)$')     { $script:S_Admin    = $matches[1]; continue }
        if ($text -match '^wg_client_conf=(.*)$') { $script:S_WgConf   = $matches[1]; continue }
        if ($text -match '^wg_server_ip=(.*)$')   { $script:S_WgIp     = $matches[1]; continue }
        if ($text -match '^reboot=(.*)$')         { $script:S_Reboot   = $matches[1]; continue }
        if ($text -match '^watchdog=(.*)$')       { $script:S_Watchdog = $matches[1]; continue }
        if ($text -match '^server_ip=(.*)$')      { $script:S_ServerIp = $matches[1]; continue }
    }
}

# Server-Script starten (interaktiv, stdin und stdout gehen durch). Gibt den Exit-Code zurueck.
function Invoke-ServerSetup {
    $befehl = (Get-SudoPrefix) + $ServerDir + '/install.sh --setup'
    & ssh.exe -t -o ConnectTimeout=10 $Name $befehl
    return $LASTEXITCODE
}

# ===========================================================================
# Wird ganz am Ende auf $true gesetzt. Alles andere gilt als Abbruch
# (Strg+C, geschlossenes Fenster) und bekommt unten eine freundliche Meldung.
$Durchgelaufen = $false

try {

Write-Host ''
Write-Host '  coolify-shield' -ForegroundColor White -NoNewline
Write-Host '  Dein Server. Deine Tuer. Dein Schluessel.' -ForegroundColor DarkGray
Write-Host ''
Show-Say '  Ich fuehre dich Schritt fuer Schritt. Wenn ich dich brauche, steht da'
Show-Say '  "Du musst jetzt". Enter ist fast immer die richtige Antwort.'
Write-Host ''

Test-Programme

# ---------------------------------------------------------------------------
# Schritt 1 · Name und Schluessel
# ---------------------------------------------------------------------------
Show-Step 'Schritt 1 · Dein Schluessel'
Show-Say '  Ein SSH-Schluessel ist wie ein Haustuerschluessel fuer den Server: zwei Haelften,'
Show-Say '  eine bleibt bei dir (privat), die andere kommt auf den Server (oeffentlich).'
Show-Say '  Kein Passwort, nichts zu raten.'
Write-Host ''

# Der Zaehler ist die Notbremse: wenn das Fenster keine Eingabe liefern kann
# (zugeklapptes stdin), soll das Script aufhoeren statt endlos zu fragen.
$Versuche = 0
while ($true) {
    $Versuche = $Versuche + 1
    if ($Versuche -gt 10) {
        Stop-WithMessage 'Ich habe zehnmal nach dem Namen gefragt und keine brauchbare Antwort bekommen.' `
            'PowerShell direkt oeffnen (Startmenue, "PowerShell") und das Script dort mit .\start.ps1 starten.'
    }
    $Name = Read-Value 'Wie soll dein Server heissen? (kurz, klein, ohne Leerzeichen)' 'coolify'
    # -cmatch, nicht -match: PowerShell vergleicht sonst ohne Ruecksicht auf Gross- und Kleinschreibung.
    if ($Name -cmatch '^[a-z0-9][a-z0-9-]{0,30}$') { break }
    Show-Warn 'Nur Kleinbuchstaben, Ziffern und Bindestrich.'
}

if (-not (Test-Path -LiteralPath $StateHome)) {
    $null = New-Item -ItemType Directory -Path $StateHome -Force
}
Set-State 'name' $Name
if ((Get-State 'user') -eq '') { Set-State 'user' 'root' }

if (-not (Test-Path -LiteralPath $KeyDir)) {
    $null = New-Item -ItemType Directory -Path $KeyDir -Force
}
$KeyPfad = Join-Path $KeyDir $Name

if (Test-Path -LiteralPath $KeyPfad) {
    Show-Skip ('Schluessel ' + $KeyPfad + ' gibt es schon, ich nehme den')
} else {
    Show-Say '  Du kannst den Schluessel mit einem Passwort schuetzen (empfohlen, wird bei jedem'
    Show-Say '  Login gefragt) oder Enter druecken fuer ohne.'
    & ssh-keygen.exe -t ed25519 -f $KeyPfad -C ('coolify-shield ' + $Name)
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $KeyPfad)) {
        Stop-WithMessage 'Schluessel konnte nicht erzeugt werden.' `
            'Pruefe, ob du in den Ordner schreiben darfst, und starte das Script erneut.'
    }
    Show-Ok ('Schluessel erzeugt: ' + $KeyPfad)
}

Write-SshConfig (Get-State 'user') (Get-State 'ip')
Show-Ok ('Eintrag in ' + $SshConfig + ': ab jetzt reicht  ssh ' + $Name)
Show-Say '  (Der Eintrag sagt SSH auch, NUR diesen Schluessel zu probieren. Sonst meckert der'
Show-Say '   Server irgendwann mit "Too many authentication failures".)'

$PubKeyPfad = $KeyPfad + '.pub'
if (-not (Test-Path -LiteralPath $PubKeyPfad)) {
    Stop-WithMessage ('Der oeffentliche Schluessel fehlt: ' + $PubKeyPfad) `
        ('Loesche ' + $KeyPfad + ' und starte das Script erneut, dann wird er neu erzeugt.')
}
$PubKey = (Get-Content -LiteralPath $PubKeyPfad -ErrorAction SilentlyContinue | Select-Object -First 1)
if ($null -eq $PubKey) { $PubKey = '' }
$PubKey = ([string]$PubKey).Trim()
if ($PubKey -eq '') {
    Stop-WithMessage ('Der oeffentliche Schluessel ist leer: ' + $PubKeyPfad) `
        ('Loesche ' + $KeyPfad + ' und ' + $PubKeyPfad + ', dann das Script erneut starten.')
}

$KopiertOk = $false
if (Get-Command 'Set-Clipboard' -ErrorAction SilentlyContinue) {
    Set-Clipboard -Value $PubKey
    if ($?) { $KopiertOk = $true }
}
if (-not $KopiertOk -and (Get-Command 'clip.exe' -ErrorAction SilentlyContinue)) {
    $PubKey | clip.exe
    if ($LASTEXITCODE -eq 0) { $KopiertOk = $true }
}
if ($KopiertOk) {
    Show-Ok 'Oeffentlicher Schluessel ist in der Zwischenablage'
} else {
    Show-Warn 'Konnte nicht in die Zwischenablage kopieren. Bitte die Zeile unten von Hand markieren.'
}

Show-NextUp ('Schluessel liegt in ' + $KeyDir + ', SSH-Eintrag "' + $Name + '" steht') `
            'Server bei Hetzner bestellen. Ich sage dir, wo du klickst.'

# ---------------------------------------------------------------------------
# Schritt 2 · Hetzner
# ---------------------------------------------------------------------------
Show-Step 'Schritt 2 · Server bestellen (Hetzner)'
if ((Get-State 'ip') -ne '' -and (Test-SshLogin)) {
    Show-Skip ('Server ' + (Get-State 'ip') + ' antwortet schon, Bestellung uebersprungen')
} else {
    Write-Host '  Dein oeffentlicher Schluessel (eine Zeile, komplett kopieren):'
    Write-Host ''
    Write-Host ('  ' + $PubKey) -ForegroundColor White
    Write-Host ''
    $anleitung = @"
  So geht es bei Hetzner (Cloud Console: https://console.hetzner.cloud):

   1. Konto anlegen oder einloggen, ein Projekt oeffnen (oder "Neues Projekt")
   2. Links "Security" -> Reiter "SSH Keys" -> "SSH-Key hinzufuegen"
      Schluessel von oben einfuegen, Name z. B. "$Name", speichern
   3. "Server" -> "Server hinzufuegen":
        Standort:  egal, z. B. Nuernberg oder Helsinki
        Image:     Ubuntu 24.04
        Typ:       Shared vCPU, mindestens 4 GB RAM
        SSH-Key:   deinen Schluessel "$Name" ANHAKEN (wichtig, sonst kommst du nicht rein)
        Name:      $Name
      "Kostenpflichtig bestellen". Nach etwa einer Minute steht die IP-Adresse da.
   4. Einmal die Rescue-Konsole oeffnen: Server anklicken -> oben rechts das
      Bildschirm-Symbol ("Console"). Das ist dein Notausgang, falls spaeter mal
      etwas klemmt. Tab offen lassen.
"@
    Write-Host $anleitung
    Write-Host ''
    Wait-Enter
    $Versuche = 0
    while ($true) {
        $Versuche = $Versuche + 1
        if ($Versuche -gt 10) {
            Stop-WithMessage 'Ich habe zehnmal nach der IP-Adresse gefragt und keine brauchbare Antwort bekommen.' `
                'Die IP steht bei Hetzner in der Serverliste und sieht so aus: 65.21.12.34. Danach das Script erneut starten.'
        }
        $Ip = Read-Value 'IP-Adresse des Servers (steht in der Serverliste)' (Get-State 'ip')
        if ($Ip -match '^[0-9]{1,3}(\.[0-9]{1,3}){3}$') { break }
        Show-Warn 'Das sieht nicht nach einer IPv4-Adresse aus (z. B. 65.21.12.34).'
    }
    Set-State 'ip' $Ip
    Write-SshConfig (Get-State 'user') $Ip
}
Show-NextUp ('Server bestellt, Adresse ' + (Get-State 'ip') + ' eingetragen') `
            'Ich teste, ob dein Schluessel am Server passt.'

# ---------------------------------------------------------------------------
# Schritt 3 · Erster Login
# ---------------------------------------------------------------------------
Show-Step 'Schritt 3 · Erster Login'
$LoginVersuche = 0
while (-not (Wait-Ssh 180)) {
    $LoginVersuche = $LoginVersuche + 1
    if ($LoginVersuche -gt 10) {
        Stop-WithMessage 'Ich komme auch nach einer halben Stunde nicht auf den Server.' `
            'Bei Hetzner pruefen, ob der Server laeuft und ob dein SSH-Key beim Bestellen angehakt war. Notfalls Server loeschen und neu bestellen, das kostet nichts extra.'
    }
    Show-Err 'Ich komme nicht auf den Server.'
    Show-Say '  Haeufigste Gruende:'
    Show-Say '   · Beim Bestellen wurde der SSH-Key nicht angehakt -> Server loeschen, neu bestellen (kostet nichts extra)'
    Show-Say '   · IP vertippt -> gleich nochmal eingeben'
    Show-Say '   · Server ist noch nicht fertig -> einfach nochmal warten'
    Write-Host ''
    if (Read-YesNo 'IP neu eingeben?' 'n') {
        $Ip = Read-Value 'IP-Adresse' (Get-State 'ip')
        Set-State 'ip' $Ip
        Write-SshConfig (Get-State 'user') $Ip
    }
}
Show-Ok ('Login klappt: ssh ' + $Name)
Show-NextUp 'Du kommst per Schluessel auf den Server' `
            'Ich lade den Server-Teil hoch und starte ihn. Ab jetzt redet der Server mit dir.'

# ---------------------------------------------------------------------------
# Schritt 4 · Server-Teil hochladen und starten (Schleife bis fertig)
# ---------------------------------------------------------------------------
Show-Step 'Schritt 4 · Einrichtung auf dem Server'

# Wichtig: In diesem String stehen NUR einfache Anfuehrungszeichen. Doppelte
# wuerden beim Weiterreichen an ssh.exe zerbrechen. PowerShell uebergibt den
# String als EIN Argument, die Remote-Shell sieht ihn genau so, wie er hier steht.
$UploadBefehl = (Get-SudoPrefix) + 'bash -c ' + "'" +
    'set -e; mkdir -p ' + $ServerDir + '; ' +
    'curl -fsSL ' + $RepoTarball + ' | tar xz -C ' + $ServerDir + ' --strip-components=1; ' +
    'chmod +x ' + $ServerDir + '/install.sh' + "'"

$r = Invoke-Quiet 'ssh.exe' @('-o', 'BatchMode=yes', $Name, $UploadBefehl)
if ($r.Code -ne 0) {
    foreach ($z in @($r.Err)) { if (([string]$z).Trim() -ne '') { Show-Say ('    ' + $z) } }
    Stop-WithMessage 'Der Server-Teil liess sich nicht hochladen.' 'Hat der Server Internet? Nochmal starten.'
}
Show-Ok ('Server-Teil liegt unter ' + $ServerDir)

$Runde = 0
while ($true) {
    $Runde = $Runde + 1
    if ($Runde -gt 20) {
        Stop-WithMessage 'Zu viele Durchlaeufe. Irgendetwas haengt.' 'Ausgabe oben in der Community posten.'
    }

    Write-Host ''
    Write-Host '  ---- Server-Ausgabe ----' -ForegroundColor DarkGray
    $rc = Invoke-ServerSetup
    Write-Host '  ---- Ende Server-Ausgabe ----' -ForegroundColor DarkGray
    Write-Host ''
    if ($null -eq $rc) { $rc = 0 }

    Read-ServerEnv

    # Reboot noetig?
    if ($rc -eq $ExitReboot -or $S_Reboot -eq 'pending') {
        Show-Say '  Der Server startet neu. Das dauert etwa eine Minute.'
        $rebootBefehl = 'sudo rm -f /var/lib/coolify-shield/reboot-pending; ' +
                        'sudo sed -i ' + "'" + '/^reboot=/d' + "'" + ' /var/lib/coolify-shield/laptop.env; ' +
                        'sudo systemd-run --on-active=2s /sbin/reboot'
        $null = Invoke-Quiet 'ssh.exe' @('-o', 'BatchMode=yes', $Name, $rebootBefehl)
        Start-Sleep -Seconds 20
        if (-not (Wait-Ssh 300)) {
            Stop-WithMessage 'Der Server ist nach dem Neustart nicht erreichbar.' `
                'Bei Hetzner in der Serverliste nachsehen, ob er laeuft. Dann start.ps1 erneut.'
        }
        continue
    }

    # Neuer Admin-Benutzer bekannt? Dann ab jetzt als dieser einloggen.
    if ($S_Admin -ne '' -and (Get-State 'user') -cne $S_Admin) {
        Write-SshConfig $S_Admin (Get-State 'ip')
        if (Test-SshLogin) {
            Set-State 'user' $S_Admin
            Show-Ok ('Ab jetzt loggst du dich als ' + $S_Admin + ' ein: ssh ' + $Name)
        } else {
            Write-SshConfig 'root' (Get-State 'ip')
            Show-Warn ('Login als ' + $S_Admin + ' klappt noch nicht, ich bleibe bei root.')
        }
    }

    # Rueckfall-Timer aktiv? Dann von aussen testen und bestaetigen.
    if ($S_Watchdog -ne '') {
        Show-Step 'Pruefung von aussen (Timer laeuft)'
        $Fehl = 0
        $ServerIp = Get-State 'ip'
        if ($ServerIp -eq '' -and $S_ServerIp -ne '') { $ServerIp = $S_ServerIp }

        if ($S_Watchdog -eq 'ssh') {
            if (Test-SshLogin) {
                Show-Ok 'Login per Schluessel klappt'
            } else {
                Show-Err 'Login klappt NICHT'; $Fehl = 1
            }
            $ohneKey = Invoke-Quiet 'ssh.exe' @(
                '-o', 'BatchMode=yes',
                '-o', 'PubkeyAuthentication=no',
                '-o', 'ConnectTimeout=8',
                $Name, 'true'
            )
            if ($ohneKey.Code -eq 0) {
                Show-Err 'Login OHNE Schluessel klappt noch (sollte nicht)'; $Fehl = 1
            } else {
                Show-Ok 'Ohne Schluessel kommt niemand rein'
            }
        }
        elseif ($S_Watchdog -eq 'firewall') {
            if (Test-SshLogin) {
                Show-Ok 'SSH geht weiterhin'
            } else {
                Show-Err 'SSH geht NICHT mehr'; $Fehl = 1
            }
            if ($ServerIp -eq '') {
                Show-Err 'Ich kenne die IP des Servers nicht, kann den Port nicht pruefen'
                $Fehl = 1
            } else {
                $url = 'http://' + $ServerIp + ':8000'
                $v4 = Invoke-Quiet 'curl.exe' @('-4', '-s', '--max-time', '5', '-o', 'NUL', $url)
                if ($v4.Code -eq 0) {
                    Show-Err 'Port 8000 ist von aussen noch offen'; $Fehl = 1
                } else {
                    Show-Ok 'Port 8000 ist von aussen zu (IPv4)'
                }
                $v6 = Invoke-Quiet 'curl.exe' @('-6', '-s', '--max-time', '5', '-o', 'NUL', $url)
                if ($v6.Code -eq 0) {
                    Show-Err 'Port 8000 ist ueber IPv6 noch offen'; $Fehl = 1
                } else {
                    Show-Ok 'Port 8000 ist von aussen zu (IPv6 oder kein IPv6)'
                }
            }
        }
        else {
            Show-Warn ('Unbekannter Rueckfall-Timer "' + $S_Watchdog + '". Ich bestaetige sicherheitshalber nicht.')
            $Fehl = 1
        }

        if ($Fehl -eq 0) {
            $confirmBefehl = 'sudo ' + $ServerDir + '/install.sh --confirm'
            $c = Invoke-Quiet 'ssh.exe' @('-o', 'BatchMode=yes', $Name, $confirmBefehl)
            if ($c.Code -eq 0) {
                Show-Ok 'Bestaetigt, Rueckfall-Timer entschaerft'
            } else {
                Show-Warn 'Konnte nicht bestaetigen. Der Timer rollt in 10 Minuten zurueck; einfach start.ps1 erneut.'
            }
        } else {
            Show-Warn 'Ich bestaetige NICHT. Der Server nimmt die Aenderung in 10 Minuten von selbst zurueck.'
            Show-Say  '  Danach start.ps1 erneut starten, dann versuchen wir es nochmal.'
            $Durchgelaufen = $true
            exit 1
        }
        continue
    }

    if ($S_Phase -eq 'done') { break }

    if ($rc -ne 0) {
        Show-Warn ('Der Server-Teil ist mit Fehler beendet (Code ' + $rc + '). Siehe Ausgabe oben.')
        if (-not (Read-YesNo 'Nochmal versuchen?' 'j')) { $Durchgelaufen = $true; exit 1 }
    }
}

Show-NextUp 'Server ist eingerichtet und abgesichert' `
            'WireGuard auf deinem Laptop, damit du ans Dashboard kommst.'

# ---------------------------------------------------------------------------
# Schritt 5 · WireGuard auf dem Laptop
# ---------------------------------------------------------------------------
Show-Step 'Schritt 5 · Dein Tunnel'

$WgConfPfad = Join-Path $StateHome ($Name + '-laptop.conf')
$WgConfOk = $false
if ($S_WgConf -ne '') {
    $wg = Invoke-Quiet 'ssh.exe' @('-o', 'BatchMode=yes', $Name, ('sudo cat ' + $S_WgConf))
    $inhalt = (@($wg.Out) -join "`n")
    if ($wg.Code -eq 0 -and $inhalt -match '\[Interface\]') {
        Write-TextFileNoBom -Path $WgConfPfad -Text ($inhalt.TrimEnd() + "`n")
        $WgConfOk = $true
        Show-Ok ('Tunnel-Datei geholt: ' + $WgConfPfad)
    } else {
        Show-Warn 'Tunnel-Datei konnte nicht geholt werden'
    }
} else {
    Show-Warn 'Der Server hat keine Tunnel-Datei gemeldet'
}

$WgIp = $S_WgIp
if ($WgIp -eq '') { $WgIp = '10.8.0.1' }

# WireGuard installieren, falls noetig
if (Test-Path -LiteralPath $WgExe) {
    Show-Ok 'WireGuard ist installiert'
} else {
    if (Get-Command 'winget' -ErrorAction SilentlyContinue) {
        Show-Say '  Ich installiere WireGuard ueber winget. Das dauert einen Moment.'
        & winget install --id WireGuard.WireGuard -e --accept-package-agreements --accept-source-agreements
        if (-not (Test-Path -LiteralPath $WgExe)) {
            Show-Warn 'winget hat WireGuard nicht an der erwarteten Stelle installiert.'
        } else {
            Show-Ok 'WireGuard installiert'
        }
    } else {
        Show-Warn 'winget gibt es auf diesem Rechner nicht.'
    }
    if (-not (Test-Path -LiteralPath $WgExe)) {
        Show-Say '  Bitte WireGuard von Hand installieren: https://www.wireguard.com/install/'
        Show-Say '  Danach hier weiter.'
        Wait-Enter
    }
}

# Tunnel importieren. Das braucht Administrator-Rechte.
$TunnelAn = $false
if ($WgConfOk -and (Test-Path -LiteralPath $WgExe)) {
    $identitaet = [Security.Principal.WindowsIdentity]::GetCurrent()
    $prinzipal  = New-Object Security.Principal.WindowsPrincipal($identitaet)
    $istAdmin   = $prinzipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($istAdmin) {
        & $WgExe '/installtunnelservice' $WgConfPfad
        if ($LASTEXITCODE -eq 0) { $TunnelAn = $true }
    } else {
        Show-Say '  Fuer den Tunnel braucht Windows einmal Administrator-Rechte.'
        Show-Say '  Es kommt gleich ein Fenster mit der Frage "Zulassen?". Bitte auf Ja klicken.'
        # -Verb RunAs braucht -ArgumentList. Der Pfad kann Leerzeichen enthalten,
        # deshalb wird er hier selbst in Anfuehrungszeichen gesetzt.
        $argumente = @('/installtunnelservice', ('"' + $WgConfPfad + '"'))
        $proc = Start-Process -FilePath $WgExe -ArgumentList $argumente -Verb RunAs -Wait -PassThru
        if ($null -ne $proc -and $proc.ExitCode -eq 0) { $TunnelAn = $true }
    }

    if ($TunnelAn) {
        Show-Ok ('Tunnel eingerichtet und eingeschaltet (' + $Name + '-laptop)')
    } else {
        Show-Warn 'Der Tunnel liess sich nicht automatisch einschalten.'
        Show-Say  '  So geht es von Hand: WireGuard oeffnen, dann "Tunnel importieren",'
        Show-Say  ('  dann diese Datei waehlen: ' + $WgConfPfad)
        Show-Say  '  Danach auf "Aktivieren" klicken.'
        Wait-Enter
    }
} elseif (-not $WgConfOk) {
    Show-Warn 'Ohne Tunnel-Datei kann ich den Tunnel nicht einrichten.'
    Show-Say  '  Starte start.ps1 spaeter noch einmal, dann hole ich sie erneut vom Server.'
} else {
    # Datei ist da, WireGuard fehlt. Der Weg von Hand bleibt offen.
    Show-Warn 'WireGuard ist nicht installiert, deshalb kann ich den Tunnel nicht einschalten.'
    Show-Say  '  So geht es, sobald WireGuard da ist: WireGuard oeffnen, dann "Tunnel importieren",'
    Show-Say  ('  dann diese Datei waehlen: ' + $WgConfPfad)
    Show-Say  '  Danach auf "Aktivieren" klicken.'
}

$Dashboard = 'http://' + $WgIp + ':8000'
$test = Invoke-Quiet 'curl.exe' @('-s', '--max-time', '6', '-o', 'NUL', $Dashboard)
if ($test.Code -eq 0) {
    Show-Ok ('Dashboard durch den Tunnel erreichbar: ' + $Dashboard)
} else {
    Show-Warn 'Dashboard antwortet nicht durch den Tunnel. Ist der Tunnel wirklich an?'
    Show-Say  ('  Dann nochmal: curl.exe ' + $Dashboard)
}

# ---------------------------------------------------------------------------
# Fertig
# ---------------------------------------------------------------------------
Show-Step 'Fertig'
Write-Host ''
Write-Host '  So kommst du ab jetzt rein:' -ForegroundColor White
Write-Host ''
$abschluss = @"
   Dashboard:  Tunnel einschalten, dann  $Dashboard
   Handy:      WireGuard-App, QR-Code vom Server gescannt, Tunnel an, dieselbe Adresse
   Server:     ssh $Name        (Benutzer $(Get-State 'user'), Schluessel in $KeyDir)
   Chef sein:  sudo <befehl>    (ohne Passwort)

  Von aussen ist das Dashboard zu. Ohne Tunnel: nichts. Genau so soll es sein.

  Ausgesperrt? NOTFALL.md im Repo, oder die Rescue-Konsole bei Hetzner.
  Nochmal pruefen, wie es dem Server geht:  ssh $Name sudo $ServerDir/install.sh --status
"@
Write-Host $abschluss
Write-Host ''

$Durchgelaufen = $true

}
finally {
    # Strg+C oder Fenster zu: das soll nicht nach Absturz aussehen.
    if (-not $Durchgelaufen) {
        Write-Host ''
        Write-Host ''
        Write-Host '  Abgebrochen. Kein Problem: einfach nochmal starten, ich mache da weiter, wo wir waren.'
        Write-Host ''
    }
}
