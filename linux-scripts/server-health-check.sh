#!/bin/bash
###############################################################################
# Server-Health-Check
# Prueft CPU, RAM, Disk, kritische Dienste und schreibt Report.
#
# Autor: [Dein Name] - FIS Azubi
###############################################################################

LOG="/var/log/health-check.log"
THRESHOLD_CPU=80
THRESHOLD_MEM=85
THRESHOLD_DISK=90
SERVICES=("apache2" "ssh" "cron")

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

log "===== Health Check gestartet ====="
log "Hostname: $(hostname)"
log "Uptime  : $(uptime -p)"

# --- CPU ---
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
log "CPU-Auslastung: ${CPU}%"
if (( $(echo "$CPU > $THRESHOLD_CPU" | bc -l) )); then
    log "WARNUNG: CPU > ${THRESHOLD_CPU}%"
fi

# --- RAM ---
MEM=$(free | awk '/Mem/ {printf("%.0f", $3/$2 * 100)}')
log "RAM-Auslastung: ${MEM}%"
if [ "$MEM" -gt "$THRESHOLD_MEM" ]; then
    log "WARNUNG: RAM > ${THRESHOLD_MEM}%"
fi

# --- Disk ---
while read -r line; do
    USE=$(echo "$line" | awk '{print $5}' | tr -d '%')
    MOUNT=$(echo "$line" | awk '{print $6}')
    log "Disk $MOUNT : ${USE}%"
    if [ "$USE" -gt "$THRESHOLD_DISK" ]; then
        log "WARNUNG: $MOUNT > ${THRESHOLD_DISK}%"
    fi
done < <(df -h | grep '^/dev/')

# --- Services ---
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        log "Service $svc: OK"
    else
        log "FEHLER: Service $svc laeuft nicht!"
    fi
done

log "===== Health Check abgeschlossen ====="
