<#
.SYNOPSIS
    Massenanlage von AD-Benutzern aus einer CSV-Datei.

.DESCRIPTION
    Liest eine CSV-Datei ein und legt für jede Zeile einen neuen AD-Benutzer an.
    Inkl. OU-Zuordnung, Sicherheitsgruppen, Logging und Fehlerbehandlung.

.PARAMETER CsvPath
    Pfad zur CSV-Datei mit Benutzerdaten.

.PARAMETER LogPath
    Pfad für die Logdatei.

.EXAMPLE
    .\create-ad-users.ps1 -CsvPath ".\users.csv"

.NOTES
    Autor:  [Dein Name] - FIS Azubi
    Domain: firma.local
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$CsvPath = ".\users.csv",

    [Parameter(Mandatory = $false)]
    [string]$LogPath = ".\logs\user-creation-$(Get-Date -Format 'yyyyMMdd-HHmm').log"
)

Import-Module ActiveDirectory -ErrorAction Stop

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','SUCCESS','WARNING','ERROR')]
        [string]$Level = 'INFO'
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'SUCCESS' { Write-Host $line -ForegroundColor Green }
        'WARNING' { Write-Host $line -ForegroundColor Yellow }
        'ERROR'   { Write-Host $line -ForegroundColor Red }
        default   { Write-Host $line }
    }

    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function New-RandomPassword {
    param([int]$Length = 12)
    $chars = 'abcdefghijkmnpqrstuvwxyzABCDEFGHIJKLMNPQRSTUVWXYZ23456789!@#$%'
    -join (1..$Length | ForEach-Object { $chars[(Get-Random -Maximum $chars.Length)] })
}

# === Vorbereitung ===
$logDir = Split-Path $LogPath -Parent
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }

Write-Log "===== AD User Creation Script gestartet ====="

if (-not (Test-Path $CsvPath)) {
    Write-Log "CSV-Datei nicht gefunden: $CsvPath" -Level ERROR
    exit 1
}

$Domain   = (Get-ADDomain).DNSRoot
$DomainDN = (Get-ADDomain).DistinguishedName

$Users = Import-Csv -Path $CsvPath -Encoding UTF8
Write-Log "Anzahl Benutzer in CSV: $($Users.Count)"

$Success = 0; $Failed = 0; $Skipped = 0

foreach ($User in $Users) {
    $SamAccountName = "$($User.Vorname.ToLower()).$($User.Nachname.ToLower())"
    $UPN            = "$SamAccountName@$Domain"
    $DisplayName    = "$($User.Vorname) $($User.Nachname)"
    $OUPath         = "OU=$($User.Abteilung),$DomainDN"
    $GroupName      = "GG_$($User.Abteilung)"

    Write-Log "Verarbeite: $DisplayName ($SamAccountName)"

    try {
        Get-ADOrganizationalUnit -Identity $OUPath -ErrorAction Stop | Out-Null
    } catch {
        Write-Log "OU '$OUPath' existiert nicht - User uebersprungen" -Level WARNING
        $Skipped++
        continue
    }

    if (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue) {
        Write-Log "Benutzer '$SamAccountName' existiert bereits - uebersprungen" -Level WARNING
        $Skipped++
        continue
    }

    $InitialPassword = New-RandomPassword -Length 12
    $SecurePass = ConvertTo-SecureString $InitialPassword -AsPlainText -Force

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

        if (Get-ADGroup -Filter "Name -eq '$GroupName'" -ErrorAction SilentlyContinue) {
            Add-ADGroupMember -Identity $GroupName -Members $SamAccountName
            Write-Log "  -> zu Gruppe hinzugefuegt: $GroupName" -Level SUCCESS
        } else {
            Write-Log "  -> Gruppe '$GroupName' nicht gefunden" -Level WARNING
        }

        $Success++
    } catch {
        Write-Log "FEHLER bei '$SamAccountName': $($_.Exception.Message)" -Level ERROR
        $Failed++
    }
}

Write-Log "===== Zusammenfassung ====="
Write-Log "Erfolgreich erstellt : $Success" -Level SUCCESS
Write-Log "Uebersprungen        : $Skipped" -Level WARNING
Write-Log "Fehler              : $Failed" -Level $(if ($Failed -gt 0) {'ERROR'} else {'INFO'})
Write-Log "===== Skript beendet ====="
