# 📖 Subnetting-Guide — Vom Anfänger zum Sicheren Rechner

> Eigene Zusammenfassung für die IHK-Prüfung
> Autor: [Dein Name] — FIS Azubi

---

## 1. Was ist eine IP-Adresse?

Eine **IPv4-Adresse** ist eine 32-Bit-Zahl, dargestellt als 4 Oktette zu je 8 Bit, getrennt durch Punkte.

```
Dezimal:   192   .   168   .     1   .    10
Binär:  11000000 . 10101000 . 00000001 . 00001010
```

Jedes Oktett kann Werte von **0 bis 255** annehmen.

---

## 2. Netzwerk- und Hostanteil

Eine IP-Adresse besteht immer aus zwei Teilen:

- **Netzwerkanteil** (welches Netz?)
- **Hostanteil** (welches Gerät in diesem Netz?)

Die Trennung erfolgt durch die **Subnetzmaske**.

```
IP-Adresse:      192.168.1.10
Subnetzmaske:    255.255.255.0
                 ─────────────────
                 Netzwerk: 192.168.1.0
                 Host:     .10
```

---

## 3. CIDR-Notation

Statt der langen Subnetzmaske gibt es die kurze **CIDR-Notation**:

| Subnetzmaske | CIDR | Hosts (theoretisch) | Hosts (nutzbar) |
|---|---|---|---|
| 255.0.0.0 | /8 | 16.777.216 | 16.777.214 |
| 255.255.0.0 | /16 | 65.536 | 65.534 |
| 255.255.255.0 | /24 | 256 | 254 |
| 255.255.255.128 | /25 | 128 | 126 |
| 255.255.255.192 | /26 | 64 | 62 |
| 255.255.255.224 | /27 | 32 | 30 |
| 255.255.255.240 | /28 | 16 | 14 |
| 255.255.255.248 | /29 | 8 | 6 |
| 255.255.255.252 | /30 | 4 | 2 |

> ⚠️ **Wichtig:** Pro Netz gehen immer **2 Adressen ab** — Netzadresse und Broadcast.

---

## 4. Private vs. öffentliche IP-Adressen

Diese Bereiche sind **privat** (nicht im Internet routbar):

| Klasse | Bereich | CIDR |
|---|---|---|
| A | 10.0.0.0 – 10.255.255.255 | 10.0.0.0/8 |
| B | 172.16.0.0 – 172.31.255.255 | 172.16.0.0/12 |
| C | 192.168.0.0 – 192.168.255.255 | 192.168.0.0/16 |

**Spezialadressen:**
- `127.0.0.1` — Loopback (localhost)
- `169.254.x.x` — APIPA (kein DHCP erreichbar)
- `0.0.0.0` — Default Route / „alles"
- `255.255.255.255` — Broadcast

---

## 5. Subnetting Schritt für Schritt

### Aufgabe: Teile 192.168.1.0/24 in 4 gleich große Subnetze

#### Schritt 1: Wie viele Bits werden für Subnetze gebraucht?
- 4 Subnetze → `2² = 4` → **2 Bits** vom Hostanteil borgen
- Neues Präfix: `/24 + 2 = /26`

#### Schritt 2: Wie viele Hosts pro Subnetz?
- 32 - 26 = 6 Host-Bits → `2⁶ - 2 = 62` nutzbare Hosts pro Subnetz

#### Schritt 3: Subnetze auflisten

Schrittweite (Block size): `256 - 192 = 64`

| Nr | Subnetz | Netzadresse | Erste Host-IP | Letzte Host-IP | Broadcast |
|---|---|---|---|---|---|
| 1 | 192.168.1.0/26 | .0 | .1 | .62 | .63 |
| 2 | 192.168.1.64/26 | .64 | .65 | .126 | .127 |
| 3 | 192.168.1.128/26 | .128 | .129 | .190 | .191 |
| 4 | 192.168.1.192/26 | .192 | .193 | .254 | .255 |

---

## 6. Rechentricks für die Prüfung

### Trick 1 — Block Size (Magic Number)

Die Block Size = `256 - letztes Subnetzmasken-Oktett`.

**Beispiel:** Maske 255.255.255.192 → Block Size = 256 - 192 = **64**.
→ Subnetze starten bei .0, .64, .128, .192.

### Trick 2 — Anzahl Hosts schnell berechnen

`Hosts = 2^(Host-Bits) - 2`

| Host-Bits | Hosts |
|---|---|
| 2 | 2 |
| 3 | 6 |
| 4 | 14 |
| 5 | 30 |
| 6 | 62 |
| 7 | 126 |
| 8 | 254 |

### Trick 3 — Anzahl Subnetze schnell berechnen

`Subnetze = 2^(geliehene Bits)`

---

## 7. Praxisbeispiele

### Beispiel A — Welche IP gehört zu welchem Netz?

Gegeben: IP `192.168.1.130/26`

1. Maske /26 → 255.255.255.192
2. Block Size: 64
3. Netzgrenzen: .0, .64, .128, .192
4. 130 liegt zwischen 128 und 191 → **Netz: 192.168.1.128/26**

### Beispiel B — Können zwei Hosts kommunizieren?

- Host A: `192.168.1.100/26`
- Host B: `192.168.1.200/26`

Host A: Netz = 192.168.1.64/26 (Bereich .64 – .127)
Host B: Netz = 192.168.1.192/26 (Bereich .192 – .255)

→ **Unterschiedliche Netze, brauchen einen Router!**

---

## 8. IPv6 — Kurzüberblick

- **128 Bit** statt 32 Bit
- Geschrieben in 8 Gruppen zu 4 Hex-Zeichen: `2001:0db8:0000:0000:0000:ff00:0042:8329`
- Kürzungsregeln:
  - Führende Nullen weglassen: `2001:db8:0:0:0:ff00:42:8329`
  - Eine Folge von Nullen durch `::` ersetzen (nur einmal): `2001:db8::ff00:42:8329`
- Loopback: `::1`
- Link-Local: `fe80::/10`
- Unique Local (intern): `fc00::/7`

---

## 9. Häufige Prüfungsaufgaben

**Aufgabe 1:** Wie viele Hosts hat ein /27-Netz?
> 2^5 - 2 = **30 Hosts**

**Aufgabe 2:** Welche Subnetzmaske entspricht /22?
> 255.255.252.0

**Aufgabe 3:** Welches Netz hat die IP 10.50.100.200/21?
> /21 → Maske 255.255.248.0, Block Size 8 im 3. Oktett
> 100 / 8 = 12 Rest 4 → 12 × 8 = 96
> **Netz: 10.50.96.0/21**

---

[⬅️ Zurück zur Projektübersicht](../README.md)
