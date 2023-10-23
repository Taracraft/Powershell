# for Local ussage:
# Use these 2 Commands for Authorisation:
# Enable-PSRemoting -SkipNetworkProfileCheck
# winrm set winrm/config/client '@{TrustedHosts="your IP"}'
#
# for disable:
# Disable-PSRemoting -Force
#
# for Domain use, u dont need the Lines Above
#
#(c) Thomas Faßbender
# Variables
# Administrator-Anmeldeinformationen
$AdminName = "xxx"
$AdminPassword = ConvertTo-SecureString "xxx" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($AdminName, $AdminPassword)

# Verzeichnis zum Speichern der Ergebnisdateien
$AusgabeVerzeichnis = "C:\Ergebnisse"

# Netzwerk-Bereichsrange
$NetzwerkRange = "192.168.178"

############################
#Start des Skriptes        #
#AB HIER NICHT MEHR ÄNDERN!#
############################

# Liste der IP-Adressen im Netzwerk
$IPBereich = 1..254 | ForEach-Object { "$NetzwerkRange.$_" }  # Ersetzen Sie dies durch den IP-Bereich Ihres Netzwerks

# Liste der Registrierungspfade
$Registrierungspfade = @(
    "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",  # 64-Bit-Software
    "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"  # 32-Bit-Software
)

# Ergebnisse sammeln
$Ergebnisse = @()

foreach ($IP in $IPBereich) {
    $ComputerIP = "$IP"
    $ComputerName = $ComputerIP -replace '\.', '_'

    $ComputerErgebnisse = @()  # Array zum Speichern der Ergebnisse für diesen Computer

    foreach ($RegistrierungsPfad in $Registrierungspfade) {
        $AusgabeDatei = Join-Path -Path $AusgabeVerzeichnis -ChildPath "${ComputerName}-Software-$($RegistrierungsPfad.Replace('\', '-')).csv"

        $InvokeCommandScript = {
            param (
                [string]$RegistrierungsPfad
            )

            $Registrierungseinträge = Get-ItemProperty -Path "HKLM:\$RegistrierungsPfad" | Select-Object DisplayName, DisplayVersion
            $Registrierungseinträge
        }

        try {
            $Result = Invoke-Command -ComputerName $ComputerIP -Credential $Credential -ScriptBlock $InvokeCommandScript -ArgumentList $RegistrierungsPfad

            if ($Result) {
                $ComputerErgebnisse += $Result
            }
        } catch {
            $ErrorMessage = $_.Exception.Message
            Write-Host "Fehler beim Verbinden mit ${ComputerIP}: $ErrorMessage"
        }
    }

    # Ergebnisse für diesen Computer speichern
    if ($ComputerErgebnisse.Count -gt 0) {
        $AusgabeDatei = Join-Path -Path $AusgabeVerzeichnis -ChildPath "${ComputerName}-Software.csv"
        $ComputerErgebnisse | Export-Csv -Path $AusgabeDatei -NoTypeInformation
        $Ergebnisse += $AusgabeDatei
    }
}

Write-Host "Scanvorgang abgeschlossen. Ergebnisse finden Sie im Verzeichnis: $AusgabeVerzeichnis"
