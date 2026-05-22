# 🌐 Projekt 01 — Heimnetzwerk mit VLAN-Trennung

> **Home Network with VLAN Segmentation**
> Aufbau eines simulierten Firmennetzwerks mit logischer Trennung von Abteilungen mittels VLANs.

![Schwierigkeit](https://img.shields.io/badge/Schwierigkeit-Mittel-yellow)
![Status](https://img.shields.io/badge/Status-Abgeschlossen-success)
![Tool](https://img.shields.io/badge/Tool-Cisco%20Packet%20Tracer-1BA0D7)

---

## 🎯 Ziel des Projekts

Aufbau eines simulierten Firmennetzwerks für ein kleines Unternehmen mit **drei logisch getrennten Bereichen**:

- 🏢 **Office-VLAN** — Arbeitsplätze der Mitarbeiter
- 👥 **Guest-VLAN** — WLAN-Zugang für Besucher (isoliert vom Office)
- 🖥️ **Server-VLAN** — interne Server (nur aus Office erreichbar)

Das Projekt simuliert eine typische Anforderung im Mittelstand: **Netzwerksicherheit durch Segmentierung** ohne separate physische Geräte.

---

## 🛠️ Verwendete Tools & Technologien

| Tool | Version | Zweck |
|---|---|---|
| Cisco Packet Tracer | 8.2.x | Netzwerksimulation |
| Cisco Catalyst 2960 | (simuliert) | Layer-2 Switch |
| Cisco ISR 4321 | (simuliert) | Router (Inter-VLAN) |
| Cisco IOS | 15.x | Konfigurations-CLI |

---

## 📋 Netzwerktopologie

```
                    [Internet / WAN]
                          │
                    ┌─────┴─────┐
                    │  Router   │  Gi0/0 ← Trunk-Port
                    │  R1       │  (Router-on-a-Stick)
                    └─────┬─────┘
                          │ 802.1Q Trunk
                    ┌─────┴─────┐
                    │  Switch   │
                    │  SW1      │
                    └──┬──┬──┬──┘
                       │  │  │
              ┌────────┘  │  └────────┐
         [VLAN 10]    [VLAN 20]    [VLAN 30]
          Office       Guest        Server
       192.168.10.0  192.168.20.0  192.168.30.0
          /24          /24           /24
```

📷 *Screenshot:* `images/topology.png`

---

## 📐 IP-Adressplanung

| VLAN | Name | Netz | Gateway | DHCP-Range |
|---|---|---|---|---|
| 10 | Office | 192.168.10.0/24 | 192.168.10.1 | .100 – .200 |
| 20 | Guest | 192.168.20.0/24 | 192.168.20.1 | .100 – .200 |
| 30 | Server | 192.168.30.0/24 | 192.168.30.1 | statisch |

---

## 🔧 Vorgehensweise (Schritt für Schritt)

### Schritt 1 — VLANs auf dem Switch anlegen

```cisco
SW1> enable
SW1# configure terminal
SW1(config)# vlan 10
SW1(config-vlan)# name Office
SW1(config-vlan)# exit
SW1(config)# vlan 20
SW1(config-vlan)# name Guest
SW1(config-vlan)# exit
SW1(config)# vlan 30
SW1(config-vlan)# name Server
SW1(config-vlan)# exit
```

### Schritt 2 — Ports den VLANs zuweisen (Access-Ports)

```cisco
SW1(config)# interface range fa0/1 - 10
SW1(config-if-range)# switchport mode access
SW1(config-if-range)# switchport access vlan 10
SW1(config-if-range)# exit

SW1(config)# interface range fa0/11 - 15
SW1(config-if-range)# switchport mode access
SW1(config-if-range)# switchport access vlan 20
SW1(config-if-range)# exit

SW1(config)# interface range fa0/16 - 20
SW1(config-if-range)# switchport mode access
SW1(config-if-range)# switchport access vlan 30
```

### Schritt 3 — Trunk-Port zum Router (802.1Q)

```cisco
SW1(config)# interface gi0/1
SW1(config-if)# switchport mode trunk
SW1(config-if)# switchport trunk allowed vlan 10,20,30
SW1(config-if)# exit
```

### Schritt 4 — Router-on-a-Stick (Sub-Interfaces)

```cisco
R1> enable
R1# configure terminal
R1(config)# interface gi0/0
R1(config-if)# no shutdown
R1(config-if)# exit

R1(config)# interface gi0/0.10
R1(config-subif)# encapsulation dot1Q 10
R1(config-subif)# ip address 192.168.10.1 255.255.255.0
R1(config-subif)# exit

R1(config)# interface gi0/0.20
R1(config-subif)# encapsulation dot1Q 20
R1(config-subif)# ip address 192.168.20.1 255.255.255.0
R1(config-subif)# exit

R1(config)# interface gi0/0.30
R1(config-subif)# encapsulation dot1Q 30
R1(config-subif)# ip address 192.168.30.1 255.255.255.0
```

### Schritt 5 — DHCP-Pools pro VLAN

```cisco
R1(config)# ip dhcp pool OFFICE
R1(dhcp-config)# network 192.168.10.0 255.255.255.0
R1(dhcp-config)# default-router 192.168.10.1
R1(dhcp-config)# dns-server 8.8.8.8
R1(dhcp-config)# exit

R1(config)# ip dhcp excluded-address 192.168.10.1 192.168.10.99
```

### Schritt 6 — ACL: Guest-VLAN darf NICHT ins Office

```cisco
R1(config)# access-list 100 deny ip 192.168.20.0 0.0.0.255 192.168.10.0 0.0.0.255
R1(config)# access-list 100 deny ip 192.168.20.0 0.0.0.255 192.168.30.0 0.0.0.255
R1(config)# access-list 100 permit ip any any

R1(config)# interface gi0/0.20
R1(config-subif)# ip access-group 100 in
```

### Schritt 7 — Konfiguration speichern

```cisco
R1# copy running-config startup-config
SW1# copy running-config startup-config
```

---

## ✅ Tests & Verifikation

| Test | Erwartung | Befehl |
|---|---|---|
| Office-PC → Server | ✅ erfolgreich | `ping 192.168.30.10` |
| Guest-PC → Office | ❌ blockiert | `ping 192.168.10.10` |
| Guest-PC → Internet | ✅ erfolgreich | `ping 8.8.8.8` |
| VLAN-Tabelle | 3 VLANs aktiv | `show vlan brief` |
| Trunk-Status | Gi0/1 = trunking | `show interfaces trunk` |

📷 *Screenshot:* `images/ping-tests.png`

---

## 📚 Was ich gelernt habe

- ✅ **VLAN-Tagging (802.1Q):** Wie Tags in Ethernet-Frames eingefügt werden, um VLANs über einen einzigen physischen Link (Trunk) zu transportieren.
- ✅ **Router-on-a-Stick:** Inter-VLAN-Routing mit nur **einem** physischen Router-Interface durch Sub-Interfaces.
- ✅ **Access Control Lists (ACLs):** Granulare Verkehrsfilterung auf Layer 3 — Reihenfolge der Regeln ist entscheidend (top-down, erste Übereinstimmung gewinnt).
- ✅ **IP-Subnetting in der Praxis:** Saubere Adressplanung mit /24-Subnetzen pro VLAN.
- ✅ **Bedeutung von Dokumentation:** Topologie-Diagramm und IP-Tabelle sind Pflicht, nicht Kür.

---

## ⚠️ Stolperfallen & Troubleshooting

| Problem | Ursache | Lösung |
|---|---|---|
| PC bekommt keine IP per DHCP | `ip helper-address` fehlt bei externem DHCP | Pool direkt auf R1 anlegen |
| Inter-VLAN-Routing geht nicht | Sub-Interface `shutdown` | `no shutdown` auf Hauptinterface |
| Trunk funktioniert nicht | Native VLAN-Mismatch | Beide Seiten gleich konfigurieren |
| ACL blockt zu viel | Implizites `deny all` am Ende | `permit ip any any` als letzte Regel |

---

## 🔗 Weiterführende Links

- 📂 [Packet-Tracer-Datei](./vlan-network.pkt)
- 📖 [Cisco VLAN Konfigurationsanleitung](https://www.cisco.com/c/en/us/td/docs/switches/lan/catalyst2960/software/release/15-0_2_se/configuration/guide/scg2960/swvlan.html)
- 📚 [Eigene Doku: OSI-Modell](../../documentation/osi-modell.md)

---

## 📋 IHK-Prüfungsbezug

**Relevante Themen für die Abschlussprüfung Teil 2:**
- VLAN-Konzepte und Konfiguration
- Inter-VLAN-Routing
- IP-Subnetting und CIDR
- Access Control Lists (ACL)
- Netzwerkdokumentation

---

[⬅️ Zurück zur Projektübersicht](../../README.md)
