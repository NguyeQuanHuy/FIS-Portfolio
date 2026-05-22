# 🪟 Projekt 02 — Windows Server mit Active Directory

> **Windows Server with Active Directory Setup**
> Aufbau einer kompletten Windows-Domäne mit zentraler Benutzerverwaltung, Gruppenrichtlinien und Dateifreigaben.

![Schwierigkeit](https://img.shields.io/badge/Schwierigkeit-Mittel--Fortgeschritten-orange)
![Status](https://img.shields.io/badge/Status-Abgeschlossen-success)
![Tool](https://img.shields.io/badge/Windows%20Server-2022-0078D6)

---

## 🎯 Ziel des Projekts

Aufbau einer **Active-Directory-Domäne** für ein simuliertes kleines Unternehmen („firma.local") mit:

- 🏢 Zentraler Benutzer- und Computer-Verwaltung
- 📁 Organisationseinheiten (OUs) nach Abteilungen
- 🔐 Sicherheitsgruppen und NTFS-Berechtigungen
- ⚙️ Gruppenrichtlinien (GPO) für automatische Konfiguration
- 💾 Dateifreigaben mit abteilungsspezifischen Rechten

Dieses Setup spiegelt ein typisches KMU-Szenario wider, das in der IHK-Prüfung **Teil 2** häufig abgefragt wird.

---

## 🛠️ Verwendete Tools & Technologien

| Komponente | Version / Rolle |
|---|---|
| Hypervisor | VMware Workstation Pro 17 |
| Server-OS | Windows Server 2022 Standard |
| Client-OS | Windows 11 Pro |
| AD-Tools | ADUC, GPMC, DNS-Manager, Server Manager |
| Hardware (VM) | 4 GB RAM, 2 vCPU, 60 GB HDD (DC) |

---

## 📋 Infrastruktur-Übersicht

```
┌──────────────────────────────────────────────────┐
│              firma.local (Domäne)                │
│                                                  │
│   ┌────────────────┐      ┌──────────────────┐   │
│   │   DC01         │      │   CLIENT01       │   │
│   │   192.168.1.10 │◄────►│   192.168.1.50   │   │
│   │   Windows      │      │   Windows 11 Pro │   │
│   │   Server 2022  │      │                  │   │
│   │                │      │                  │   │
│   │ • AD DS        │      │ • Domänenclient  │   │
│   │ • DNS          │      │                  │   │
│   │ • DHCP         │      │                  │   │
│   │ • File Server  │      │                  │   │
│   └────────────────┘      └──────────────────┘   │
└──────────────────────────────────────────────────┘
```

📷 *Screenshot:* `images/topology.png`

---

## 🏗️ OU-Struktur (Organisationseinheiten)

```
firma.local
│
├── 📂 IT
│   ├── 👤 Users
│   └── 🔒 Groups
│
├── 📂 Buchhaltung
│   ├── 👤 Users
│   └── 🔒 Groups
│
├── 📂 Vertrieb
│   ├── 👤 Users
│   └── 🔒 Groups
│
└── 📂 Server
    └── 💻 Computers
```

---

## 🔧 Vorgehensweise (Schritt für Schritt)

### Schritt 1 — Windows Server vorbereiten

1. VM mit Windows Server 2022 in VMware installiert
2. Statische IP-Konfiguration:
   - **IP:** 192.168.1.10 / 24
   - **Gateway:** 192.168.1.1
   - **DNS:** 127.0.0.1 (Loopback, da DC später selbst DNS-Server)
3. Computernamen geändert auf `DC01`
4. Updates installiert

### Schritt 2 — AD DS-Rolle installieren

Im Server Manager: **Manage → Add Roles and Features → Active Directory Domain Services**

Oder per PowerShell:
```powershell
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
```

### Schritt 3 — Domäne erstellen

```powershell
Install-ADDSForest `
    -DomainName "firma.local" `
    -DomainNetbiosName "FIRMA" `
    -InstallDns `
    -Force
```

Server startet neu — danach ist DC01 ein **Domänencontroller**.

### Schritt 4 — DHCP-Server-Rolle installieren

```powershell
Install-WindowsFeature -Name DHCP -IncludeManagementTools
```

DHCP-Scope erstellen:
- **Scope:** 192.168.1.100 – 192.168.1.200
- **Gateway:** 192.168.1.1
- **DNS:** 192.168.1.10 (DC01)
- **Lease:** 8 Tage

### Schritt 5 — OU-Struktur anlegen

In **Active Directory Users and Computers (ADUC)**:

```powershell
New-ADOrganizationalUnit -Name "IT"           -Path "DC=firma,DC=local"
New-ADOrganizationalUnit -Name "Buchhaltung"  -Path "DC=firma,DC=local"
New-ADOrganizationalUnit -Name "Vertrieb"     -Path "DC=firma,DC=local"
New-ADOrganizationalUnit -Name "Server"       -Path "DC=firma,DC=local"
```

### Schritt 6 — Benutzer und Gruppen erstellen

```powershell
# Beispiel: Buchhaltungs-Mitarbeiter
New-ADUser -Name "Maria Schmidt" `
           -SamAccountName "m.schmidt" `
           -UserPrincipalName "m.schmidt@firma.local" `
           -Path "OU=Buchhaltung,DC=firma,DC=local" `
           -AccountPassword (ConvertTo-SecureString "Start1234!" -AsPlainText -Force) `
           -ChangePasswordAtLogon $true `
           -Enabled $true

# Sicherheitsgruppe für Abteilung
New-ADGroup -Name "GG_Buchhaltung" `
            -GroupScope Global `
            -GroupCategory Security `
            -Path "OU=Buchhaltung,DC=firma,DC=local"

Add-ADGroupMember -Identity "GG_Buchhaltung" -Members "m.schmidt"
```

### Schritt 7 — Gruppenrichtlinien (GPO)

In **Group Policy Management Console**:

1. **Passwortrichtlinie** (Default Domain Policy):
   - Mindestlänge: 10 Zeichen
   - Komplexität: aktiviert
   - Maximales Alter: 90 Tage

2. **Netzlaufwerk-Mapping** (per OU):
   - Buchhaltung → `\\DC01\Buchhaltung` als Laufwerk `B:`

3. **Desktop-Hintergrund** (Branding):
   - Pfad zu Firmenlogo

### Schritt 8 — Dateifreigaben mit NTFS-Rechten

```powershell
# Ordner erstellen
New-Item -Path "C:\Shares\Buchhaltung" -ItemType Directory

# SMB-Freigabe
New-SmbShare -Name "Buchhaltung" `
             -Path "C:\Shares\Buchhaltung" `
             -FullAccess "Administratoren" `
             -ChangeAccess "FIRMA\GG_Buchhaltung"

# NTFS-Berechtigungen
$acl = Get-Acl "C:\Shares\Buchhaltung"
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "FIRMA\GG_Buchhaltung", "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl "C:\Shares\Buchhaltung" $acl
```

### Schritt 9 — Client der Domäne hinzufügen

Auf Windows 11 Client:
```powershell
Add-Computer -DomainName "firma.local" -Credential (Get-Credential) -Restart
```

---

## ✅ Tests & Verifikation

| Test | Erwartung |
|---|---|
| `nltest /dsgetdc:firma.local` | Findet DC01 |
| Anmeldung am Client mit Domänenkonto | ✅ erfolgreich |
| Zugriff auf `\\DC01\Buchhaltung` | ✅ nur für Mitglieder |
| Passwortrichtlinie greift | ✅ schwaches Passwort wird abgelehnt |
| Netzlaufwerk B: erscheint nach Login | ✅ per GPO gemappt |

📷 *Screenshots:* `images/aduc.png`, `images/gpo.png`, `images/client-login.png`

---

## 📚 Was ich gelernt habe

- ✅ **AGDLP-Prinzip:** Accounts → Global Groups → Domain Local Groups → Permissions (Microsoft-Standard für Berechtigungsverwaltung)
- ✅ **NTFS vs. Freigabe-Rechte:** Die restriktivere Berechtigung gewinnt — wichtig für Prüfung!
- ✅ **GPO-Vererbung:** Site → Domain → OU; Reihenfolge beeinflusst, welche Richtlinie wirkt
- ✅ **DNS ist Pflicht für AD:** Ohne funktionierendes DNS keine Domänenanmeldung
- ✅ **PowerShell-Automatisierung** schlägt manuelles Klicken in Skalierung jeder Mal

---

## ⚠️ Stolperfallen & Troubleshooting

| Problem | Ursache | Lösung |
|---|---|---|
| Client findet Domäne nicht | DNS zeigt nicht auf DC | Client-DNS auf DC01-IP setzen |
| Anmeldung dauert ewig | Group Policy hängt | `gpupdate /force` + Eventlog prüfen |
| „Zugriff verweigert" auf Share | NTFS restriktiver als Share | Beide Rechte prüfen, restriktivste gewinnt |
| AD-Replikation fehlt | Nur 1 DC, kein Replikationspartner | Bei Mehr-DC-Setup `repadmin /replsummary` |

---

## 🔗 Weiterführende Ressourcen

- 📖 [Microsoft Docs: AD DS Installation](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/install-active-directory-domain-services--level-100-)
- 📚 [Eigene Doku: Server-Rollen](../../documentation/)
- 🛠️ [PowerShell Skript: User-Massenanlage](../05-ad-automation/)

---

## 📋 IHK-Prüfungsbezug

**Relevante Themen für die Abschlussprüfung Teil 2:**
- Active Directory Domain Services (AD DS)
- DNS-Konzepte und -Konfiguration
- DHCP-Scopes und -Reservierungen
- Gruppenrichtlinien (GPO) und Vererbung
- NTFS- und Freigabe-Berechtigungen
- AGDLP-Berechtigungskonzept

---

[⬅️ Zurück zur Projektübersicht](../../README.md)
