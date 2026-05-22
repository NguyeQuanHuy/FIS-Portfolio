# ⚙️ Projekt 05 — PowerShell-Automatisierung: AD-Benutzer aus CSV

> **Automation Script for AD User Creation from CSV**
> Massenanlage von Active-Directory-Benutzern mit Fehlerbehandlung, Logging und OU-Zuordnung.

![Schwierigkeit](https://img.shields.io/badge/Schwierigkeit-Fortgeschritten-red)
![Status](https://img.shields.io/badge/Status-Abgeschlossen-success)
![Sprache](https://img.shields.io/badge/PowerShell-7.x-5391FE)

---

## 🎯 Ziel des Projekts

Automatisierte **Massenanlage von Benutzern** im Active Directory aus einer **CSV-Datei** — typisches Szenario: Onboarding einer ganzen Abteilung, Wechsel eines Schuljahrgangs, Migration von einem System ins andere.

### Warum Automatisierung?

| Manuell (ADUC-Klicks) | Mit Skript |
|---|---|
| ⏱️ ~2 Minuten pro User | ⏱️ ~2 Sekunden pro User |
| ❌ Tippfehler häufig | ✅ Konsistent |
| 📝 Manuelles Logging | 📝 Automatisches Logging |
| 🔄 Nicht reproduzierbar | 🔄 Jederzeit wiederholbar |

> Bei 50 neuen Mitarbeitern: **100 Minuten → 2 Minuten**. Das ist der Kern moderner IT-Administration.

---

## 🛠️ Verwendete Tools & Technologien

| Tool | Version / Modul |
|---|---|
| PowerShell | 7.x (oder Windows PowerShell 5.1) |
| ActiveDirectory-Modul | RSAT Active Directory |
| CSV-Editor | Excel / VS Code |
| IDE | Visual Studio Code mit PowerShell-Extension |
| Versionskontrolle | Git |

---

## 📋 CSV-Vorlage

Datei: `users.csv`

```csv
Vorname,Nachname,Abteilung,Position,EMail,Telefon
Maria,Schmidt,Buchhaltung,Buchhalterin,m.schmidt@firma.local,+49301234500
Tom,Mueller,IT,Systemadmin,t.mueller@firma.local,+49301234501
Lisa,Weber,Vertrieb,Sales Manager,l.weber@firma.local,+49301234502
Anna,Becker,IT,Helpdesk,a.becker@firma.local,+49301234503
Paul,Schulz,Vertrieb,Außendienst,p.schulz@firma.local,+49301234504
```

---

## 💻 Das Skript

Datei: `create-ad-users.ps1`

```powershell
<#
.SYNOPSIS
    Massenanlage von AD-Benutzern aus einer CSV-Datei

.DESCRIPTION
    Liest eine CSV-Datei ein und legt für jede Zeile einen neuen AD-Benutzer an.
    Inkl. OU-Zuordnung, Sicherheitsgruppen, Logging und Fehlerbehandlung.

.PARAMETER CsvPath
    Pfad zur CSV-Datei mit Benutzerdaten

.PARAMETER LogPath
    Pfad für die Logdatei

.EXAMPLE
    .\create-ad-users.ps1 -CsvPath ".\users.csv"

.NOTES
    Autor:  [Dein Name] - FIS Azubi
    Datum:  2026
    Domain: firma.local
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$CsvPath = ".\users.csv",

    [Parameter(Mandatory=$false)]
    [string]$LogPath = ".\logs\user-creation-$(Get-Date -Format 'yyyyMMdd-HHmm').log"
)

# === Module laden ===
Import-Module ActiveDirectory -ErrorAction Stop

# === Logging-Funktion ===
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    # Konsole farblich
    switch ($Level) {
        'SUCCESS' { Write-Host $line -ForegroundColor Green }
        'WARNING' { Write-Host $line -ForegroundColor Yellow }
        'ERROR'   { Write-Host $line -ForegroundColor Red }
        default   { Write-Host $line }
    }

    # In Datei schreiben
    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

# === Sicheres Passwort generieren ===
function New-RandomPassword {
    param([int]$Length = 12)
    $chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ23456789!@#$%'
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# === Vorbereitung ===
$logDir = Split-Path $LogPath -Parent
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

Write-Log "===== AD User Creation Script gestartet ====="
Write-Log "CSV-Datei: $CsvPath"
Write-Log "Log-Datei: $LogPath"

if (-not (Test-Path $CsvPath)) {
    Write-Log "CSV-Datei nicht gefunden: $CsvPath" -Level ERROR
    exit 1
}

# === Domain-Info ===
$Domain = (Get-ADDomain).DNSRoot
$DomainDN = (Get-ADDomain).DistinguishedName
Write-Log "Domäne: $Domain"

# === CSV einlesen ===
$Users = Import-Csv -Path $CsvPath -Encoding UTF8
Write-Log "Anzahl Benutzer in CSV: $($Users.Count)"

# === Zähler ===
$Success = 0
$Failed  = 0
$Skipped = 0

# === Hauptschleife ===
foreach ($User in $Users) {
    $SamAccountName = "$($User.Vorname.ToLower()).$($User.Nachname.ToLower())"
    $UPN            = "$SamAccountName@$Domain"
    $DisplayName    = "$($User.Vorname) $($User.Nachname)"
    $OUPath         = "OU=$($User.Abteilung),$DomainDN"
    $GroupName      = "GG_$($User.Abteilung)"

    Write-Log "Verarbeite: $DisplayName ($SamAccountName)"

    # Prüfen ob OU existiert
    try {
        Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction Stop | Out-Null
    } catch {
        Write-Log "OU '$OUPath' existiert nicht — User übersprungen" -Level WARNING
        $Skipped++
        continue
    }

    # Prüfen ob User bereits existiert
    if (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue) {
        Write-Log "Benutzer '$SamAccountName' existiert bereits — übersprungen" -Level WARNING
        $Skipped++
        continue
    }

    # Passwort generieren
    $InitialPassword = New-RandomPassword -Length 12
    $SecurePass = ConvertTo-SecureString $InitialPassword -AsPlainText -Force

    # User anlegen
    try {
        New-ADUser `
            -Name              $DisplayName `
            -GivenName         $User.Vorname `
            -Surname           $User.Nachname `
            -DisplayName       $DisplayName `
            -SamAccountName    $SamAccountName `
            -UserPrincipalName $UPN `
            -EmailAddress      $User.EMail `
            -OfficePhone       $User.Telefon `
            -Title             $User.Position `
            -Department        $User.Abteilung `
            -Path              $OUPath `
            -AccountPassword   $SecurePass `
            -ChangePasswordAtLogon $true `
            -Enabled           $true `
            -ErrorAction       Stop

        Write-Log "Benutzer erstellt: $SamAccountName | Passwort: $InitialPassword" -Level SUCCESS

        # Gruppe zuweisen (falls existiert)
        if (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue) {
            Add-ADGroupMember -Identity $GroupName -Members $SamAccountName
            Write-Log "  → zu Gruppe hinzugefügt: $GroupName" -Level SUCCESS
        } else {
            Write-Log "  → Gruppe '$GroupName' nicht gefunden" -Level WARNING
        }

        $Success++

    } catch {
        Write-Log "FEHLER bei '$SamAccountName': $($_.Exception.Message)" -Level ERROR
        $Failed++
    }
}

# === Zusammenfassung ===
Write-Log "===== Zusammenfassung ====="
Write-Log "Erfolgreich erstellt : $Success" -Level SUCCESS
Write-Log "Übersprungen        : $Skipped" -Level WARNING
Write-Log "Fehler              : $Failed" -Level $(if ($Failed -gt 0) {'ERROR'} else {'INFO'})
Write-Log "===== Skript beendet ====="

# Export der erstellten User mit Initialpasswort (für Übergabe an Mitarbeiter)
if ($Success -gt 0) {
    $ExportPath = ".\logs\new-users-credentials-$(Get-Date -Format 'yyyyMMdd-HHmm').csv"
    Write-Log "Tipp: Initialpasswörter aus dem Log extrahieren und sicher übergeben."
}
```

---

## 🔧 Verwendung

### Vorbereitung

1. **Skript & CSV** in einen Ordner legen, z. B. `C:\Scripts\AD-Bulk\`
2. **PowerShell als Administrator** starten
3. **Execution Policy** prüfen:
   ```powershell
   Get-ExecutionPolicy
   # Falls "Restricted":
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

### Ausführung

```powershell
# Standardaufruf
.\create-ad-users.ps1

# Mit eigenem CSV-Pfad
.\create-ad-users.ps1 -CsvPath "C:\Daten\neue-mitarbeiter.csv"

# Mit ausführlichem Output
.\create-ad-users.ps1 -Verbose
```

### Beispiel-Ausgabe

```
[2026-05-23 10:00:01] [INFO] ===== AD User Creation Script gestartet =====
[2026-05-23 10:00:01] [INFO] CSV-Datei: .\users.csv
[2026-05-23 10:00:01] [INFO] Anzahl Benutzer in CSV: 5
[2026-05-23 10:00:02] [INFO] Verarbeite: Maria Schmidt (maria.schmidt)
[2026-05-23 10:00:02] [SUCCESS] Benutzer erstellt: maria.schmidt | Passwort: Kx9!mP2qR4tZ
[2026-05-23 10:00:02] [SUCCESS]   → zu Gruppe hinzugefügt: GG_Buchhaltung
[2026-05-23 10:00:03] [INFO] Verarbeite: Tom Mueller (tom.mueller)
[2026-05-23 10:00:03] [WARNING] Benutzer 'tom.mueller' existiert bereits — übersprungen
...
[2026-05-23 10:00:08] [INFO] ===== Zusammenfassung =====
[2026-05-23 10:00:08] [SUCCESS] Erfolgreich erstellt : 4
[2026-05-23 10:00:08] [WARNING] Übersprungen        : 1
[2026-05-23 10:00:08] [INFO] Fehler              : 0
```

---

## ✅ Verifikation in AD

```powershell
# Alle neu erstellten User der letzten Stunde anzeigen
Get-ADUser -Filter * -Properties WhenCreated |
    Where-Object { $_.WhenCreated -gt (Get-Date).AddHours(-1) } |
    Select-Object Name, SamAccountName, Department |
    Format-Table -AutoSize

# Gruppenmitgliedschaft prüfen
Get-ADGroupMember -Identity "GG_Buchhaltung" | Select-Object Name, SamAccountName
```

📷 *Screenshot:* `images/script-output.png`, `images/aduc-after-import.png`

---

## 📚 Was ich gelernt habe

- ✅ **PowerShell ist die Sprache der Windows-Admins** — fast jede ADUC-Aktion ist auch ein Cmdlet
- ✅ **Try-Catch ist Pflicht in Produktion** — sonst stoppt das ganze Skript beim ersten Fehler
- ✅ **Logging-Funktionen wiederverwenden** statt überall `Write-Host` zu streuen
- ✅ **Idempotenz:** Skript so bauen, dass mehrfaches Ausführen nichts kaputt macht (Existenz-Check)
- ✅ **Sichere Passwortgenerierung** — kein Standardpasswort wie „Welcome123!", lieber random + ChangeAtLogon
- ✅ **Parameter mit `[CmdletBinding()]`** machen Skripte wie native Cmdlets nutzbar
- ✅ **Code Review per Git:** Versionierte Skripte sind Gold wert

---

## ⚠️ Stolperfallen & Troubleshooting

| Problem | Ursache | Lösung |
|---|---|---|
| `ActiveDirectory module not found` | RSAT fehlt | `Install-WindowsCapability -Name Rsat.ActiveDirectory.DS-LDS.Tools` |
| Umlaute kaputt im CSV | falsche Kodierung | CSV als **UTF-8 mit BOM** speichern |
| User wird angelegt, aber deaktiviert | `-Enabled $true` vergessen | Parameter prüfen |
| Skript bricht ab bei erstem Fehler | kein try-catch | Fehler-Handling einbauen |
| Passwort entspricht nicht Policy | zu kurz / zu einfach | `New-RandomPassword -Length 12` mit Sonderzeichen |
| OU existiert nicht | falsch geschrieben | Vorab `Get-ADOrganizationalUnit` prüfen |

---

## 🚀 Mögliche Erweiterungen

- 📧 **E-Mail an HR senden** mit Initialpasswörtern (verschlüsselt!)
- 📅 **Geplante Ausführung** über Task Scheduler
- 🌐 **Web-Frontend** für HR mit Formular → CSV → Skript
- 🔐 **Passwörter in Passwort-Tresor schreiben** statt im Log
- 📊 **HTML-Report** statt reinem Text-Log

---

## 🔗 Weiterführende Ressourcen

- 📖 [Microsoft Learn: AD PowerShell](https://learn.microsoft.com/en-us/powershell/module/activedirectory/)
- 📖 [PowerShell Best Practices](https://github.com/PoshCode/PowerShellPracticeAndStyle)
- 📂 [Skript Source](../../powershell-scripts/create-ad-users.ps1)

---

## 📋 IHK-Prüfungsbezug

**Relevante Themen für die Abschlussprüfung Teil 2:**
- Automatisierung wiederkehrender Aufgaben
- PowerShell als Administrations-Werkzeug
- Active-Directory-Strukturen
- Fehlerbehandlung und Logging
- Datenschutz: Umgang mit Initialpasswörtern (DSGVO)

---

[⬅️ Zurück zur Projektübersicht](../../README.md)
