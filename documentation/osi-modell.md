# 📖 Das OSI-Schichtenmodell — Vollständige Erklärung

> Eigene Zusammenfassung für die IHK-Abschlussprüfung Teil 2
> Autor: [Dein Name] — FIS Azubi

---

## Was ist das OSI-Modell?

Das **OSI-Modell** (Open Systems Interconnection) ist ein **Referenzmodell** der ISO, das beschreibt, wie Kommunikation zwischen zwei Systemen in einem Netzwerk in **7 logischen Schichten** abläuft.

> 💡 **Wichtig:** OSI ist ein **theoretisches Modell**, das in der Praxis nicht 1:1 umgesetzt ist. Real verwendet wird das TCP/IP-Modell mit 4 Schichten. Das OSI-Modell hilft aber bei **strukturierter Fehlersuche**.

---

## Die 7 Schichten im Überblick

| # | Name (DE) | Name (EN) | Aufgabe | Beispiele |
|---|---|---|---|---|
| 7 | Anwendungsschicht | Application | Schnittstelle zum Benutzer | HTTP, FTP, SMTP, DNS |
| 6 | Darstellungsschicht | Presentation | Datenformatierung, Verschlüsselung | TLS/SSL, JPEG, ASCII |
| 5 | Sitzungsschicht | Session | Auf-/Abbau von Verbindungen | NetBIOS, RPC |
| 4 | Transportschicht | Transport | Ende-zu-Ende-Übertragung | TCP, UDP |
| 3 | Vermittlungsschicht | Network | Logische Adressierung, Routing | IP, ICMP, Router |
| 2 | Sicherungsschicht | Data Link | Physische Adressierung (MAC) | Ethernet, Switch |
| 1 | Bitübertragungsschicht | Physical | Übertragung von Bits | Kabel, Hub, Funk |

---

## Eselsbrücken zum Auswendiglernen

**Von oben nach unten (7 → 1):**
> **A**lle **D**eutschen **S**chüler **T**rinken **V**iel **S**üßes **B**ier
> (Anwendung – Darstellung – Sitzung – Transport – Vermittlung – Sicherung – Bitübertragung)

**Von unten nach oben (1 → 7) — englisch:**
> **P**lease **D**o **N**ot **T**hrow **S**ausage **P**izza **A**way
> (Physical – Data Link – Network – Transport – Session – Presentation – Application)

---

## Detaillierte Beschreibung jeder Schicht

### Schicht 7 — Anwendungsschicht (Application Layer)

**Aufgabe:** Schnittstelle zwischen Benutzeranwendung und Netzwerk.

**Protokolle:**
- **HTTP / HTTPS** — Webseiten
- **FTP / SFTP** — Dateiübertragung
- **SMTP / IMAP / POP3** — E-Mail
- **DNS** — Namensauflösung
- **DHCP** — IP-Vergabe
- **SSH** — Sichere Remote-Verbindung

**Beispiel:** Du gibst `www.google.de` im Browser ein → der Browser nutzt HTTP/HTTPS auf Schicht 7.

---

### Schicht 6 — Darstellungsschicht (Presentation Layer)

**Aufgabe:** Daten in ein einheitliches Format bringen (Verschlüsselung, Komprimierung, Konvertierung).

**Beispiele:**
- **TLS / SSL** — Verschlüsselung (z. B. https)
- **JPEG, PNG, GIF** — Bildformate
- **ASCII, UTF-8** — Zeichenkodierung
- **MPEG, MP3** — Komprimierung

---

### Schicht 5 — Sitzungsschicht (Session Layer)

**Aufgabe:** Verwaltung von Sitzungen (Sessions) zwischen Anwendungen — Auf- und Abbau, Synchronisation.

**Protokolle:**
- **NetBIOS** — Windows-Netzwerkdienste
- **RPC** — Remote Procedure Call
- **SMB** — Datei- und Druckerfreigaben

---

### Schicht 4 — Transportschicht (Transport Layer)

**Aufgabe:** Zuverlässige Ende-zu-Ende-Übertragung zwischen zwei Hosts. Aufteilung in Segmente, Fehlererkennung.

**Protokolle:**

| Protokoll | Eigenschaften | Einsatz |
|---|---|---|
| **TCP** | Verbindungsorientiert, zuverlässig, langsamer | Web, E-Mail, Datei-Download |
| **UDP** | Verbindungslos, unzuverlässig, schnell | Streaming, DNS, VoIP, Spiele |

**TCP-Handshake (3-Wege):**
```
Client                Server
  │── SYN ──────────────►│
  │◄────── SYN-ACK ──────│
  │── ACK ──────────────►│
  │  [Verbindung steht]  │
```

**Wichtige Ports:**
| Port | Dienst |
|---|---|
| 20/21 | FTP |
| 22 | SSH |
| 25 | SMTP |
| 53 | DNS |
| 80 | HTTP |
| 443 | HTTPS |
| 3389 | RDP |

---

### Schicht 3 — Vermittlungsschicht (Network Layer)

**Aufgabe:** Logische Adressierung (IP-Adressen) und Wegfindung (Routing) zwischen verschiedenen Netzen.

**Protokolle:**
- **IPv4 / IPv6** — Adressierung
- **ICMP** — Steuerprotokoll (`ping`, `traceroute`)
- **OSPF, RIP, BGP** — Routing-Protokolle

**Geräte:** **Router**

**Datenformat:** Pakete (Packets)

---

### Schicht 2 — Sicherungsschicht (Data Link Layer)

**Aufgabe:** Physische Adressierung (MAC), Fehlererkennung in einem lokalen Netz.

**Unterschichten:**
- **LLC** (Logical Link Control)
- **MAC** (Media Access Control)

**Protokolle:** Ethernet, WLAN (802.11), PPP

**Geräte:** **Switch, Bridge**

**Datenformat:** Frames

**MAC-Adresse:** 48 Bit, hexadezimal, z. B. `00:1A:2B:3C:4D:5E`
- Erste 24 Bit: Hersteller (OUI)
- Letzte 24 Bit: eindeutig vom Hersteller vergeben

---

### Schicht 1 — Bitübertragungsschicht (Physical Layer)

**Aufgabe:** Übertragung von Rohdaten (0/1) über ein physisches Medium.

**Medien:**
- Kupferkabel (Cat5e, Cat6, Cat6a, Cat7)
- Glasfaser (Singlemode, Multimode)
- Funk (WLAN, Bluetooth)

**Geräte:** Hub, Repeater, Verkabelung

**Datenformat:** Bits

---

## 🔄 Datenfluss durch die Schichten

Wenn du eine Webseite öffnest:

```
Sender (Schicht 7)        Empfänger (Schicht 7)
   │                              ▲
   ▼                              │
   6                              6
   │                              ▲
   ▼                              │
   ...                            ...
   │                              ▲
   ▼                              │
   1  ────────►  Kabel  ────────► 1
```

Bei jedem Übergang nach unten wird ein **Header** hinzugefügt (**Kapselung** / Encapsulation).
Beim Empfänger werden die Header von unten nach oben wieder entfernt (**Entkapselung** / Decapsulation).

---

## 🛠️ Troubleshooting nach OSI

Wenn das Netzwerk nicht funktioniert, **systematisch von unten nach oben** prüfen:

| Schicht | Was prüfen? | Befehle |
|---|---|---|
| 1 | Kabel, LEDs, Stromversorgung | Sichtprüfung |
| 2 | Switch-Port, MAC-Tabelle | `arp -a`, `show mac address-table` |
| 3 | IP-Konfiguration, Routing | `ipconfig`, `ip a`, `ping`, `route print` |
| 4 | Ports, Firewall | `netstat -an`, `telnet ip port` |
| 5-7 | DNS, Anwendung | `nslookup`, Browser-Konsole |

---

## 📋 Häufige Prüfungsfragen

1. **Auf welcher Schicht arbeitet ein Switch?**
   → Schicht 2 (Data Link), Layer-3-Switches auch Schicht 3.

2. **Welche Schicht ist für IP-Routing zuständig?**
   → Schicht 3 (Network / Vermittlung).

3. **Unterschied TCP vs. UDP?**
   → TCP ist verbindungsorientiert und zuverlässig, UDP verbindungslos und schnell.

4. **Was macht die Sicherungsschicht?**
   → Adressierung im lokalen Netz über MAC-Adressen und Fehlererkennung.

5. **Auf welcher Schicht arbeitet HTTPS?**
   → HTTP auf Schicht 7, TLS-Verschlüsselung auf Schicht 6.

---

[⬅️ Zurück zur Projektübersicht](../README.md)
