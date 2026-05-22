# 🏗️ Projekt 06 — Virtuelles Homelab

> **Virtual Lab Environment with pfSense, Windows Domain & Linux Server**
> Aufbau einer dauerhaften, mehrstufigen Testumgebung für kontinuierliches Lernen.

![Schwierigkeit](https://img.shields.io/badge/Schwierigkeit-Mittel-yellow)
![Status](https://img.shields.io/badge/Status-Aktiv-success)
![VMs](https://img.shields.io/badge/Anzahl%20VMs-4-blue)

---

## 🎯 Ziel des Projekts

Aufbau einer **dauerhaft laufenden Labor-Umgebung** mit mehreren virtuellen Maschinen, die ein realistisches Firmennetzwerk simuliert. Diese Umgebung dient als:

- 🧪 **Spielwiese** für neue Technologien (Cloud, Container, neue Server-Rollen)
- 📚 **Prüfungsvorbereitung** für die IHK-Abschlussprüfung
- 💼 **Demo-Umgebung** für Bewerbungsgespräche
- 🔄 **Wiederholbar**: Snapshots erlauben „Reset auf sauberen Zustand"

> 💡 **Philosophie:** *„Was du nicht im Lab gebrochen und repariert hast, kannst du in Produktion nicht."*

---

## 🛠️ Hardware- und Software-Stack

### Host-System

| Komponente | Empfehlung |
|---|---|
| **CPU** | Intel i5/i7 oder AMD Ryzen 5/7 (VT-x / AMD-V) |
| **RAM** | min. 16 GB (32 GB optimal) |
| **Storage** | SSD mit min. 250 GB frei |
| **OS** | Windows 11 Pro / Ubuntu / macOS |

### Virtualisierung

| Software | Lizenz | Einsatz |
|---|---|---|
| VMware Workstation Pro | Free für Privatnutzung (seit 2024) | Empfohlen |
| Oracle VirtualBox | Open Source | Alternative |
| Microsoft Hyper-V | In Windows Pro enthalten | Native unter Windows |

---

## 📐 Netzwerktopologie

```
        ┌──────────────────────────┐
        │   Host (Internet/WAN)    │
        │   VMnet8 (NAT)           │
        └────────────┬─────────────┘
                     │
              ┌──────┴──────┐
              │  pfSense    │   WAN: VMnet8 (NAT zur echten Welt)
              │  Firewall   │   LAN: VMnet1 (Host-Only, 10.0.10.0/24)
              │  + DHCP     │
              └──────┬──────┘
                     │ LAN
       ┌─────────────┼─────────────┐
       │             │             │
  ┌────┴────┐   ┌────┴────┐   ┌────┴────┐
  │  DC01   │   │  WEB01  │   │  WIN11  │
  │ Win2022 │   │ Ubuntu  │   │ Client  │
  │ AD/DNS  │   │ Apache  │   │         │
  └─────────┘   └─────────┘   └─────────┘
   10.0.10.10   10.0.10.20    10.0.10.50
```

📷 *Diagramm:* `images/topology-detailed.png`

---

## 💻 VM-Inventar

| VM-Name | OS | RAM | vCPU | Disk | IP | Zweck |
|---|---|---|---|---|---|---|
| **pfSense01** | pfSense CE 2.7 | 2 GB | 1 | 20 GB | 10.0.10.1 (LAN) | Firewall, DHCP, Routing |
| **DC01** | Windows Server 2022 | 4 GB | 2 | 60 GB | 10.0.10.10 | AD, DNS, File Server |
| **WEB01** | Ubuntu 22.04 LTS | 2 GB | 2 | 30 GB | 10.0.10.20 | Apache Webserver |
| **WIN11** | Windows 11 Pro | 4 GB | 2 | 50 GB | DHCP | Client-VM |

**Gesamtbedarf:** 12 GB RAM, ~160 GB Storage

---

## 🔧 Vorgehensweise (Schritt für Schritt)

### Phase 1 — Host-Vorbereitung

1. **Virtualisierung im BIOS aktivieren** (VT-x / AMD-V / SVM)
2. **VMware Workstation Pro installieren**
3. **Virtuelle Netzwerke konfigurieren:**
   - `VMnet8` → NAT (für Internet via Host)
   - `VMnet1` → Host-Only (internes Labor-LAN)

### Phase 2 — pfSense als Firewall

#### Installation

1. ISO von pfsense.org herunterladen
2. Neue VM erstellen:
   - **Netzwerke:** 2 Adapter (VMnet8 + VMnet1)
   - **Disk:** 20 GB
3. Installation durchführen → WAN/LAN-Interfaces zuweisen

#### Erstkonfiguration

```
WAN (em0):  DHCP von Host
LAN (em1):  10.0.10.1 / 24
```

Über Web-UI (https://10.0.10.1) von einer Client-VM:
- **DHCP-Server LAN:** Range 10.0.10.100 – 10.0.10.200
- **Firewall-Regeln:** Default „LAN → any"

📷 *Screenshot:* `images/pfsense-dashboard.png`

### Phase 3 — Windows Domain Controller (DC01)

Siehe ausführliche Schritte in [Projekt 02 — Active Directory](../02-active-directory/).

**Wichtig für Homelab-Setup:**
- Statische IP **10.0.10.10**
- DNS-Server auf **127.0.0.1** (Self)
- Im pfSense: DNS Resolver auf DC01 für Domäne `firma.local` weiterleiten

### Phase 4 — Linux-Webserver (WEB01)

Siehe ausführliche Schritte in [Projekt 03 — Linux-Webserver](../03-linux-webserver/).

**Anpassung für Homelab:**
- Statische IP **10.0.10.20**
- DNS auf **10.0.10.10** (DC01) für Namensauflösung
- Optional: WEB01 als Domain-Member mit Kerberos-Authentifizierung (`realm join`)

### Phase 5 — Windows 11 Client

1. ISO installieren, in **VMnet1** anbinden
2. IP über DHCP von pfSense
3. **Der Domäne `firma.local` beitreten:**
   ```powershell
   Add-Computer -DomainName "firma.local" -Restart
   ```

### Phase 6 — Snapshots erstellen

**Goldener Snapshot pro VM:**
```
Snapshot-Name:  "Clean-Base"
Beschreibung:   "Frisch installiert, gepatcht, konfiguriert"
Datum:          [aktuelles Datum]
```

> 💡 **Faustregel:** Vor jeder größeren Änderung einen Snapshot machen. Speicherplatz ist günstiger als Zeit.

📷 *Screenshot:* `images/snapshots.png`

---

## 🎓 Lernfelder im Lab

Was kann ich in diesem Lab praktisch ausprobieren?

### Netzwerk
- [x] VLAN-Trennung (mit zweitem pfSense-Interface)
- [x] Firewall-Regeln und NAT
- [x] DNS-Forwarding und Split-Horizon
- [ ] VPN-Server (OpenVPN auf pfSense)
- [ ] Failover / High Availability

### Windows-Administration
- [x] Active Directory Domain Services
- [x] DNS, DHCP
- [x] Group Policy Objects
- [x] File Services mit NTFS-Berechtigungen
- [ ] Hyper-V als zweite Virtualisierungsebene
- [ ] WSUS (Windows Server Update Services)
- [ ] Failover Clustering

### Linux-Administration
- [x] Webserver (Apache)
- [x] SSH-Härtung, UFW
- [ ] LAMP-Stack mit MariaDB + PHP
- [ ] Reverse Proxy mit nginx
- [ ] Container mit Docker
- [ ] Monitoring mit Prometheus + Grafana

### Sicherheit
- [x] Firewall-Regeln (pfSense)
- [x] Berechtigungskonzepte (NTFS, Linux rwx)
- [ ] IDS/IPS mit Suricata
- [ ] Zentrale Logs mit Graylog
- [ ] Penetrationstests mit Kali Linux

> ✅ = umgesetzt, ⬜ = geplant

---

## 🔄 Snapshot-Strategie

```
Clean-Base       ← Frische Installation
   │
   ├── AD-Setup-Complete
   │      │
   │      └── GPO-Configured
   │
   ├── Apache-Running
   │      │
   │      └── HTTPS-LetsEncrypt
   │
   └── Domain-Joined-Client
          │
          └── User-Profile-Created
```

> ⚠️ **Achtung:** VMware-Snapshots sind **kein Backup**! Sie sind Wiederherstellungs-Punkte für **Experimente**. Echte Daten zusätzlich extern sichern.

---

## ✅ Verifikation des Setups

| Test | Befehl / Aktion | Erwartung |
|---|---|---|
| Internet aus VM | `ping 8.8.8.8` von WIN11 | ✅ Antwort |
| DNS-Auflösung intern | `nslookup dc01.firma.local` | ✅ 10.0.10.10 |
| Domänenbeitritt | Login mit `FIRMA\m.schmidt` an WIN11 | ✅ erfolgreich |
| Webserver erreichbar | Browser → `http://10.0.10.20` | ✅ Apache-Default |
| Firewall blockt | LAN → 10.0.10.20:22 von extern | ❌ blockiert |
| Snapshot-Restore | „Revert to Snapshot" | ✅ < 1 Minute |

---

## 📚 Was ich gelernt habe

- ✅ **Lab-Design beginnt mit dem Diagramm:** Erst zeichnen, dann konfigurieren
- ✅ **pfSense ist mächtiger als jeder Consumer-Router** — und kostenlos
- ✅ **VLAN- und VM-Netzwerke** sind funktional sehr ähnlich, aber logisch verschieden
- ✅ **Ressourcen-Management** ist Pflicht: VMs nur starten, wenn man sie braucht (16 GB RAM ist schneller voll als gedacht)
- ✅ **Snapshots geben Mut zum Experimentieren** — gerade als Azubi unbezahlbar
- ✅ **Dokumentation ist Teil des Labs**, nicht Nachgedanke
- ✅ **Reproduzierbarkeit** schlägt manuelles Klicken → langfristig in Infrastructure-as-Code (Terraform, Ansible) investieren

---

## ⚠️ Stolperfallen & Troubleshooting

| Problem | Ursache | Lösung |
|---|---|---|
| VM startet sehr langsam | Host-RAM überbucht | RAM-Reservierung der VMs prüfen |
| Keine Internetverbindung aus VM | WAN-Interface falsches Netz | pfSense WAN auf VMnet8 (NAT) |
| Client findet Domäne nicht | DNS zeigt nicht auf DC | pfSense DHCP: DNS = 10.0.10.10 |
| Snapshots verbrauchen Platz | viele unkonsolidierte Deltas | Alte Snapshots löschen / „Consolidate" |
| pfSense Web-UI nicht erreichbar | Browser-Sicherheit (HTTPS) | Self-signed Zertifikat akzeptieren |

---

## 🚀 Roadmap & nächste Schritte

- [ ] **2. Domain Controller** (DC02) für AD-Replikation
- [ ] **Backup-Server** mit Veeam Community Edition
- [ ] **Monitoring-Stack** (Zabbix oder LibreNMS)
- [ ] **Kali Linux VM** für IT-Security-Übungen
- [ ] **Migration in Proxmox** als bare-metal Hypervisor
- [ ] **Hybrid-Cloud-Anbindung** an Microsoft Azure via Site-to-Site-VPN

---

## 🔗 Weiterführende Ressourcen

- 📖 [pfSense Documentation](https://docs.netgate.com/pfsense/)
- 📖 [VMware Workstation Docs](https://docs.vmware.com/en/VMware-Workstation-Pro/)
- 📺 [Lawrence Systems YouTube (pfSense Tutorials)](https://www.youtube.com/@LAWRENCESYSTEMS)
- 📚 [Eigene Doku: Subnetting](../../documentation/subnetting-guide.md)

---

## 📋 IHK-Prüfungsbezug

**Relevante Themen für die Abschlussprüfung Teil 2:**
- Virtualisierungstechnologien (Type-1 vs. Type-2 Hypervisor)
- Netzwerksegmentierung
- Firewall-Konzepte (Stateful vs. Stateless)
- Wirtschaftlichkeitsbetrachtung (Virtualisierung vs. Physisch)
- Hochverfügbarkeit (HA) und Disaster Recovery

---

[⬅️ Zurück zur Projektübersicht](../../README.md)
