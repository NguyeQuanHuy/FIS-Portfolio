#!/bin/bash
###############################################################################
# Vollstaendiges Server-Backup-Skript
# Strategie: 3-2-1, inkrementell via rsync mit Hardlinks
#
# Autor:  [Dein Name] - FIS Azubi
# Datum:  2026
###############################################################################

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

# Pruefen ob NAS gemountet
if ! mountpoint -q /mnt/nas; then
    log "FEHLER: NAS nicht gemountet"
    send_alert "NAS-Mount fehlt"
    exit 1
fi

# Backup-Ziel vorbereiten
TARGET="$BACKUP_ROOT/$DATE"
mkdir -p "$TARGET"

# Inkrementell mit --link-dest (Hardlinks zu unveraenderten Dateien)
LATEST=$(ls -1t "$BACKUP_ROOT" 2>/dev/null | grep -v "current" | head -1)
LINK_DEST=""
if [ -n "$LATEST" ] && [ -d "$BACKUP_ROOT/$LATEST" ]; then
    LINK_DEST="--link-dest=$BACKUP_ROOT/$LATEST"
    log "Inkrementell zu: $LATEST"
fi

# rsync ausfuehren
rsync -aAXv --delete $LINK_DEST $SOURCE "$TARGET" >> "$LOG" 2>&1
RC=$?

if [ $RC -eq 0 ]; then
    log "Backup erfolgreich: $TARGET"
    rm -f "$BACKUP_ROOT/current"
    ln -s "$TARGET" "$BACKUP_ROOT/current"
else
    log "FEHLER: rsync exit code $RC"
    send_alert "rsync fehlgeschlagen, exit code: $RC"
    exit 2
fi

# Alte Backups loeschen
log "Loesche Backups aelter als $RETENTION_DAYS Tage"
find "$BACKUP_ROOT" -maxdepth 1 -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} \;

# Speicherplatz loggen
DISK_USE=$(df -h /mnt/nas | tail -1)
log "NAS-Auslastung: $DISK_USE"

log "===== Backup abgeschlossen ====="
exit 0
