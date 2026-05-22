# 💾 Projekt 04 — Backup- und Wiederherstellungssystem

> **Backup & Recovery System (3-2-1 Strategy)**
> Implementierung einer professionellen Backup-Strategie für ein kleines Büro nach der 3-2-1-Regel.

![Schwierigkeit](https://img.shields.io/badge/Schwierigkeit-Mittel-yellow)
![Status](https://img.shields.io/badge/Status-Abgeschlossen-success)
![Strategie](https://img.shields.io/badge/Strategie-3--2--1-blue)

---

## 🎯 Ziel des Projekts

Konzeption und Umsetzung einer **vollständigen Backup-Strategie** für ein kleines Unternehmen — von der Planung über die Implementierung bis zum **getesteten Restore**.

### Die 3-2-1-Regel

```
   3 Kopien   →   2 verschiedene Medien   →   1 externe Lagerung
   ────────       ─────────────────────       ─────────────────
   Original       NAS + USB-Platte            Offsite / Cloud
```

> 💡 **Merksatz:** *„Ein Backup ohne erfolgreichen Restore-Test ist KEIN Backup."*

---

## 🛠️ Verwendete Tools & Technologien

| Komponente | Zweck |
|---|---|
| Windows Server Backup | Volumen-Backups auf NAS |
| `rsync` | Inkrementelle Linux-Backups |
| `tar` + `gzip` | Archivierung |
| Externe USB-Festplatte | Wöchentliche Vollsicherung |
| NAS-Freigabe (simuliert) | Tägliches Ziel |
| Bash + Cron / Task Scheduler | Automatisierung |

---

## 📐 Backup-Konzept

### Was wird gesichert?

| Datenquelle | Größe | Priorität | Wiederherstellungszeit |
|---|---|---|---|
| Buchhaltungs-Dateien | ~50 GB | 🔴 Kritisch | < 2 Stunden |
| AD-Datenbank (NTDS.DIT) | ~1 GB | 🔴 Kritisch | < 4 Stunden |
| Apache-Webroot (Linux) | ~5 GB | 🟡 Mittel | < 24 Stunden |
| Benutzer-Profile | ~100 GB | 🟢 Niedrig | Best Effort |

### Backup-Plan

```
Mo Di Mi Do Fr Sa So
─── ─── ─── ─── ─── ─── ───
 I   I   I   I   V   -   -        I = Inkrementell, V = Vollsicherung
[─────── NAS ───────] [USB]       Aufbewahrung NAS: 14 Tage
                                  Aufbewahrung USB: 4 Wochen
```

### RTO / RPO (Service-Level)

| Metrik | Definition | Zielwert |
|---|---|---|
| **RPO** (Recovery Point Objective) | max. Datenverlust | 24 Stunden |
| **RTO** (Recovery Time Objective) | max. Ausfallzeit | 4 Stunden |

---

## 🔧 Vorgehensweise (Schritt für Schritt)

### Teil A — Windows Server Backup auf NAS

#### Schritt 1 — Backup-Feature installieren

```powershell
Install-WindowsFeature -Name Windows-Server-Backup -IncludeManagementTools
```

#### Schritt 2 — NAS-Freigabe einbinden

```powershell
# Anmeldedaten speichern
cmdkey /add:nas01 /user:backupuser /pass:SicheresPasswort

# Test
Test-Path "\\nas01\backups"
```

#### Schritt 3 — Backup-Zeitplan einrichten

```powershell
$Policy = New-WBPolicy
Add-WBSystemState -Policy $Policy
$Volume = Get-WBVolume -VolumePath "C:\Shares\Buchhaltung"
Add-WBVolume -Policy $Policy -Volume $Volume

$Target = New-WBBackupTarget -NetworkPath "\\nas01\backups\DC01"
Add-WBBackupTarget -Policy $Policy -Target $Target

Set-WBSchedule -Policy $Policy -Schedule 02:00
Set-WBPolicy -Policy $Policy
```

### Teil B — Linux-Server-Backup mit rsync

#### Schritt 4 — Backup-Skript erstellen

```bash
sudo nano /usr/local/bin/server-backup.sh
```

```bash
#!/bin/bash
# Vollständiges Server-Backup-Skript
# Strategie: 3-2-1, inkrementell via rsync mit Hardlinks

# === Konfiguration ===
SOURCE="/var/www /etc /home"
BACKUP_ROOT="/mnt/nas/linux-backups"
DATE=$(date +%Y-%m-%d_%H-%M)
LOG="/var/log/server-backup.log"
RETENTION_DAYS=14
EMAIL="admin@firma.local"

# === Funktionen ===
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

send_alert() {
    echo "$1" | mail -s "Backup-FEHLER auf $(hostname)" "$EMAIL"
}

# === Hauptlogik ===
log "===== Backup gestartet ====="

# Prüfen ob NAS gemountet
if ! mountpoint -q /mnt/nas; then
    log "FEHLER: NAS nicht gemountet"
    send_alert "NAS-Mount fehlt"
    exit 1
fi

# Backup-Ziel vorbereiten
TARGET="$BACKUP_ROOT/$DATE"
mkdir -p "$TARGET"

# Inkrementelles Backup mit --link-dest (Hardlinks zu unveränderten Dateien)
LATEST=$(ls -1t "$BACKUP_ROOT" | grep -v "current" | head -1)
LINK_DEST=""
if [ -n "$LATEST" ] && [ -d "$BACKUP_ROOT/$LATEST" ]; then
    LINK_DEST="--link-dest=$BACKUP_ROOT/$LATEST"
    log "Inkrementell zu: $LATEST"
fi

# rsync ausführen
rsync -aAXv --delete $LINK_DEST $SOURCE "$TARGET" >> "$LOG" 2>&1
RC=$?

if [ $RC -eq 0 ]; then
    log "Backup erfolgreich: $TARGET"
    # Symlink 'current' aktualisieren
    rm -f "$BACKUP_ROOT/current"
    ln -s "$TARGET" "$BACKUP_ROOT/current"
else
    log "FEHLER: rsync exit code $RC"
    send_alert "rsync fehlgeschlagen, exit code: $RC"
    exit 2
fi

# Alte Backups löschen
log "Lösche Backups älter als $RETENTION_DAYS Tage"
find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} \;

# Speicherplatz loggen
DISK_USE=$(df -h /mnt/nas | tail -1)
log "NAS-Auslastung: $DISK_USE"

log "===== Backup abgeschlossen ====="
exit 0
```

#### Schritt 5 — Cron-Eintrag

```bash
sudo crontab -e
```

```cron
# Tägliches Backup um 02:30 Uhr
30 2 * * * /usr/local/bin/server-backup.sh
```

### Teil C — Wöchentliche USB-Vollsicherung

```bash
sudo nano /usr/local/bin/usb-fullbackup.sh
```

```bash
#!/bin/bash
USB="/mnt/usb-backup"
WEEK=$(date +%Y-W%V)

if mountpoint -q "$USB"; then
    tar -czf "$USB/full-$WEEK.tar.gz" /etc /var/www /home /var/backups
    echo "[$(date)] USB-Vollbackup: full-$WEEK.tar.gz" >> /var/log/usb-backup.log
else
    echo "[$(date)] USB nicht angeschlossen!" >> /var/log/usb-backup.log
fi
```

Cron (jeden Freitag 18:00):
```cron
0 18 * * 5 /usr/local/bin/usb-fullbackup.sh
```

---

## 🔄 Restore-Test (Pflicht!)

### Test 1 — Einzelne Datei wiederherstellen

```bash
# Datei "absichtlich" löschen
sudo rm /var/www/html/index.html

# Aus letztem Backup wiederherstellen
sudo cp /mnt/nas/linux-backups/current/var/www/html/index.html /var/www/html/

# Verifizieren
curl http://localhost
```

### Test 2 — Komplettes Verzeichnis wiederherstellen

```bash
sudo rsync -aAXv /mnt/nas/linux-backups/current/var/www/ /var/www/
```

### Test 3 — Bare-Metal-Restore (Windows Server)

1. Server in `Windows Recovery Environment` booten
2. "System Image Recovery" wählen
3. NAS-Pfad angeben → letztes Vollbackup
4. Wiederherstellung starten → ca. 45 Minuten für 200 GB

📷 *Screenshots:* `images/restore-test.png`, `images/backup-log.png`

---

## ✅ Verifikation & Reporting

| Metrik | Wert | Status |
|---|---|---|
| Backup-Größe (täglich) | ~2 GB inkrementell | ✅ |
| Backup-Dauer | 12 Minuten | ✅ |
| Restore-Zeit (Einzeldatei) | < 1 Minute | ✅ |
| Restore-Zeit (Volume) | 42 Minuten | ✅ (unter RTO) |
| Datenintegrität nach Restore | SHA-256 Prüfsumme OK | ✅ |
| Aufbewahrung NAS | 14 Tage | ✅ |
| Aufbewahrung USB | 4 Wochen | ✅ |

---

## 📚 Was ich gelernt habe

- ✅ **3-2-1-Regel ist Pflicht, nicht Empfehlung:** Ein einziges Backup-Medium ist kein Backup
- ✅ **Backup-Typen verstehen:**
  - **Vollsicherung:** alle Daten, lange Laufzeit, schneller Restore
  - **Inkrementell:** nur Änderungen seit letztem Backup, schnell, mehrstufiger Restore
  - **Differenziell:** Änderungen seit letzter Vollsicherung, Kompromiss
- ✅ **rsync mit `--link-dest`:** Genial — unveränderte Dateien werden als Hardlinks gespeichert, kein doppelter Speicherbedarf
- ✅ **RTO vs. RPO:** Zwei verschiedene Metriken — Geschäftsanforderungen vor Technik
- ✅ **Restore-Test ist nicht optional:** Erst wenn ein Restore erfolgreich war, ist das Backup-System bewiesen
- ✅ **Monitoring & Alerting:** Stille Backup-Fehler sind die schlimmsten — immer Logs + E-Mail-Alarm

---

## ⚠️ Stolperfallen & Troubleshooting

| Problem | Ursache | Lösung |
|---|---|---|
| Backup wächst unkontrolliert | Retention fehlt | `find -mtime +N -delete` einbauen |
| NAS-Mount geht verloren | Netzwerk-Unterbrechung | `mountpoint -q` Check + auto-remount |
| rsync „operation not permitted" | Falsche Rechte | `-aAX` für ACLs und xattrs verwenden |
| Restore-Test wurde nie gemacht | Zeitmangel | **Quartalsweise einplanen!** |
| Backup auf gleichem Server | Verletzt 3-2-1 | Externes Ziel zwingend |

---

## 🔗 Weiterführende Ressourcen

- 📖 [BSI: Backup-Konzepte](https://www.bsi.bund.de/)
- 📖 [rsync Manual](https://download.samba.org/pub/rsync/rsync.1)
- 📂 [Backup-Skript Source](../../linux-scripts/backup.sh)

---

## 📋 IHK-Prüfungsbezug

**Relevante Themen für die Abschlussprüfung Teil 2:**
- Backup-Strategien (3-2-1, GFS — Grandfather/Father/Son)
- Voll-, inkrementelle und differenzielle Backups
- RTO / RPO definieren und messen
- Datensicherung und DSGVO
- Notfallwiederherstellung (Disaster Recovery)

---

[⬅️ Zurück zur Projektübersicht](../../README.md)
