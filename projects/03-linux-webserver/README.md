# 🐧 Projekt 03 — Linux-Webserver mit SSH-Härtung

> **Linux Web Server with SSH and Permission Management**
> Aufbau eines Ubuntu-Servers als Webserver mit sicherer Fernwartung und Backup-Automatisierung.

![Schwierigkeit](https://img.shields.io/badge/Schwierigkeit-Mittel-yellow)
![Status](https://img.shields.io/badge/Status-Abgeschlossen-success)
![OS](https://img.shields.io/badge/Ubuntu-22.04%20LTS-E95420)

---

## 🎯 Ziel des Projekts

Aufbau eines **Linux-Webservers** mit folgenden Eigenschaften:

- 🌐 Apache2 als Webserver
- 🔐 Gehärteter SSH-Zugang (Key-Auth, kein Root-Login)
- 🛡️ UFW-Firewall mit minimalen offenen Ports
- 👥 Saubere Benutzer- und Rechte-Verwaltung
- 💾 Automatisches tägliches Backup per Cron

Ziel: Ein **produktionsreifer Webserver**, der grundlegende Sicherheits-Best-Practices umsetzt.

---

## 🛠️ Verwendete Tools & Technologien

| Komponente | Version |
|---|---|
| OS | Ubuntu Server 22.04 LTS |
| Webserver | Apache2 2.4 |
| SSH-Server | OpenSSH 8.9 |
| Firewall | UFW (Uncomplicated Firewall) |
| Hypervisor | VirtualBox 7 |
| SSH-Client | PuTTY / Windows Terminal |

---

## 🔧 Vorgehensweise (Schritt für Schritt)

### Schritt 1 — System aktualisieren

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y net-tools curl wget vim
```

### Schritt 2 — Statische IP über Netplan

```bash
sudo vim /etc/netplan/00-installer-config.yaml
```

```yaml
network:
  version: 2
  ethernets:
    enp0s3:
      dhcp4: no
      addresses: [192.168.1.50/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
```

```bash
sudo netplan apply
ip a    # Prüfen
```

### Schritt 3 — Apache2 installieren

```bash
sudo apt install -y apache2
sudo systemctl enable apache2
sudo systemctl start apache2
sudo systemctl status apache2
```

Test-Webseite anlegen:
```bash
sudo nano /var/www/html/index.html
```

```html
<!DOCTYPE html>
<html>
<head><title>FIS Lab Server</title></head>
<body>
  <h1>Willkommen auf meinem Linux-Webserver!</h1>
  <p>Konfiguriert von [Dein Name] — Azubi FIS</p>
</body>
</html>
```

### Schritt 4 — SSH-Härtung

#### 4a) SSH-Schlüsselpaar erzeugen (auf Client)

```bash
ssh-keygen -t ed25519 -C "huy-fis-portfolio"
```

#### 4b) Public Key auf Server kopieren

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub huy@192.168.1.50
```

#### 4c) SSH-Server härten

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
sudo nano /etc/ssh/sshd_config
```

Änderungen:
```
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
AllowUsers huy
LoginGraceTime 30
```

```bash
sudo systemctl restart ssh
```

> ⚠️ **Wichtig:** Vor dem Restart **immer** eine zweite SSH-Session offen halten, falls die Konfiguration einen Fehler hat!

### Schritt 5 — UFW-Firewall einrichten

```bash
# Standardregeln: alles eingehend blockieren, ausgehend erlauben
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Erlaubte Ports
sudo ufw allow 2222/tcp comment 'SSH (custom port)'
sudo ufw allow 80/tcp   comment 'HTTP'
sudo ufw allow 443/tcp  comment 'HTTPS'

# Firewall aktivieren
sudo ufw enable
sudo ufw status verbose
```

Erwartete Ausgabe:
```
Status: active
To             Action      From
--             ------      ----
2222/tcp       ALLOW       Anywhere
80/tcp         ALLOW       Anywhere
443/tcp        ALLOW       Anywhere
```

### Schritt 6 — Benutzer- und Rechte-Verwaltung

```bash
# Gruppen erstellen
sudo groupadd webadmin
sudo groupadd webuser

# Benutzer erstellen
sudo useradd -m -s /bin/bash -G webadmin tom
sudo useradd -m -s /bin/bash -G webuser  lisa

# Passwörter setzen
sudo passwd tom
sudo passwd lisa

# Verzeichnisrechte für Webroot
sudo chown -R root:webadmin /var/www/html
sudo chmod -R 775 /var/www/html
sudo find /var/www/html -type d -exec chmod g+s {} \;
```

Damit gilt:
- **webadmin** → kann Webseite bearbeiten
- **webuser** → kann nur lesen
- **Andere** → kein Zugriff

### Schritt 7 — Automatisches Backup-Skript

```bash
sudo nano /usr/local/bin/backup-web.sh
```

```bash
#!/bin/bash
# Backup-Skript für Webserver
# Autor: [Dein Name] — FIS Azubi

BACKUP_DIR="/var/backups/web"
SOURCE_DIR="/var/www/html"
DATE=$(date +%Y-%m-%d_%H-%M)
LOG_FILE="/var/log/backup-web.log"
RETENTION_DAYS=7

# Backup-Verzeichnis anlegen falls nicht vorhanden
mkdir -p "$BACKUP_DIR"

# Backup mit tar erstellen
echo "[$(date)] Backup gestartet" >> "$LOG_FILE"
tar -czf "$BACKUP_DIR/web-$DATE.tar.gz" "$SOURCE_DIR" 2>> "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo "[$(date)] Backup erfolgreich: web-$DATE.tar.gz" >> "$LOG_FILE"
else
    echo "[$(date)] FEHLER beim Backup!" >> "$LOG_FILE"
    exit 1
fi

# Alte Backups löschen (älter als RETENTION_DAYS)
find "$BACKUP_DIR" -name "web-*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "[$(date)] Backup abgeschlossen" >> "$LOG_FILE"
```

Ausführbar machen und testen:
```bash
sudo chmod +x /usr/local/bin/backup-web.sh
sudo /usr/local/bin/backup-web.sh
ls -lh /var/backups/web/
cat /var/log/backup-web.log
```

### Schritt 8 — Cron-Job einrichten

```bash
sudo crontab -e
```

```cron
# Backup jeden Tag um 02:00 Uhr
0 2 * * * /usr/local/bin/backup-web.sh
```

Verifizieren:
```bash
sudo crontab -l
sudo systemctl status cron
```

---

## ✅ Tests & Verifikation

| Test | Befehl | Erwartung |
|---|---|---|
| Webserver läuft | `curl http://192.168.1.50` | HTML der Test-Seite |
| SSH auf Standard-Port blockiert | `ssh huy@192.168.1.50` | Connection refused |
| SSH auf 2222 funktioniert | `ssh -p 2222 huy@192.168.1.50` | Login mit Key |
| Root-Login blockiert | `ssh -p 2222 root@192.168.1.50` | Permission denied |
| Firewall aktiv | `sudo ufw status` | Active, 3 Regeln |
| Backup-Skript läuft | `sudo /usr/local/bin/backup-web.sh` | tar.gz in /var/backups/web/ |

📷 *Screenshots:* `images/apache-default.png`, `images/ufw-status.png`, `images/backup-output.png`

---

## 📚 Was ich gelernt habe

- ✅ **Linux-Berechtigungssystem (rwx):** Owner / Group / Other — und wie SUID/GUID-Bits funktionieren
- ✅ **SSH-Härtung:** Key-Auth ist sicherer als Passwörter; nicht-Standard-Port reduziert Brute-Force-Angriffe
- ✅ **UFW-Prinzip:** Default-Deny → nur explizit erlauben (Whitelisting statt Blacklisting)
- ✅ **Cron-Syntax:** `Minute Stunde Tag Monat Wochentag` — Reihenfolge zählt
- ✅ **Defensive Konfiguration:** Backup der `sshd_config` BEVOR man editiert, zweite Session offen halten
- ✅ **Logging als Pflicht:** Ohne Logs ist Debugging unmöglich

---

## ⚠️ Stolperfallen & Troubleshooting

| Problem | Ursache | Lösung |
|---|---|---|
| SSH nach Restart nicht erreichbar | UFW blockt neuen Port | `sudo ufw allow 2222/tcp` VOR `systemctl restart ssh` |
| Netplan-Änderung greift nicht | YAML-Fehler (Einrückung!) | `sudo netplan try` zum Testen |
| Apache 403 Forbidden | NTFS-ähnliche Rechte falsch | `chmod 755` auf Verzeichnisse, `644` auf Dateien |
| Cron-Job läuft nicht | PATH unvollständig | Absolute Pfade im Skript nutzen |
| Festplatte voll durch Backups | Retention fehlt | `find ... -mtime +N -delete` einbauen |

---

## 🔗 Weiterführende Ressourcen

- 📖 [Ubuntu Server Guide](https://ubuntu.com/server/docs)
- 📖 [Apache HTTP Server Docs](https://httpd.apache.org/docs/2.4/)
- 🔐 [Mozilla SSH Best Practices](https://infosec.mozilla.org/guidelines/openssh)
- 📂 [Backup-Skript Source](../../linux-scripts/backup.sh)

---

## 📋 IHK-Prüfungsbezug

**Relevante Themen für die Abschlussprüfung Teil 2:**
- Linux-Dateisystem und Berechtigungen
- SSH und sichere Fernadministration
- Firewall-Konzepte (iptables/nftables/ufw)
- Webserver-Konfiguration
- Automatisierung mit Cron/Bash
- Backup-Strategien

---

[⬅️ Zurück zur Projektübersicht](../../README.md)
