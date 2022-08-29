$ErrorActionPreference = 'Stop'

<#

Documentation for silent installation:
https://silentinstallhq.com/postgresql-12-silent-install-how-to-guide/

Page for manual download:
https://www.enterprisedb.com/downloads/postgres-postgresql-downloads
https://sbp.enterprisedb.com/getfile.jsp?fileid=1258170

#>

$softwarePostgreSQL = [PSCustomObject]@{
    DownloadUrl  = 'https://sbp.enterprisedb.com/getfile.jsp?fileid=1258170'
    ExeFile      = '\\fs\Software\PostgreSQL\postgresql-14.5-1-windows-x64.exe'
    Sha256       = 'E91B3AA882A0AF54FDA36043F492252E472C878904E2C3D92E6C799C33E75DEA'
    ComputerName = 'SQLLAB08'
    Credential   = Get-Credential -Message "Account to connect to target server with CredSSP" -UserName "$env:USERDOMAIN\$env:USERNAME"
    Parameters   = @{
        prefix           = 'D:\PostgreSQL\14'
        datadir          = 'D:\PostgreSQL\14\data'
        mode             = 'unattended'
        unattendedmodeui = 'none'
        servicename      = 'postgresql'
        serviceaccount   = 'postgresql'
        servicepassword  = 'start123'
        superpassword    = 'start123'
    }
}


# Download software if needed

if (-not (Test-Path -Path $softwarePostgreSQL.ExeFile)) {
    Invoke-WebRequest -Uri $softwarePostgreSQL.DownloadUrl -UseBasicParsing -OutFile $softwarePostgreSQL.ExeFile
}


# Test for correct cecksum

if ((Get-FileHash -Path $softwarePostgreSQL.ExeFile -Algorithm SHA256).Hash -ne $softwarePostgreSQL.Sha256) {
    throw "Checksum does not match"
}


# Install software
$session = New-PSSession -ComputerName $softwarePostgreSQL.ComputerName -Credential $softwarePostgreSQL.Credential -Authentication Credssp

$argumentList = @( )
foreach ($key in $softwarePostgreSQL.Parameters.Keys) {
    $argumentList += "--$key"
    $argumentList += $softwarePostgreSQL.Parameters.$key
}

$result = Invoke-Program -Session $session -FilePath $softwarePostgreSQL.ExeFile -ArgumentList $argumentList -Verbose

$session | Remove-PSSession


# Test installation

if (-not $result.Successful) {
    $result
    throw "Installation failed"
}

if ((Get-Service -ComputerName $softwarePostgreSQL.ComputerName -Name $softwarePostgreSQL.Parameters.servicename).Count -ne 1) {
    throw "Installation failed"
}


# Setup Firewall

$cimSession = New-CimSession -ComputerName $softwarePostgreSQL.ComputerName

$firewallConfig = @{
    DisplayName = 'PostgreSQL'
    Name        = 'PostgreSQL'
    Group       = 'PostgreSQL'
    Enabled     = 'True'
    Direction   = 'Inbound'
    Protocol    = 'TCP'
    LocalPort   = '5432'
}
$null = New-NetFirewallRule -CimSession $cimSession @firewallConfig

$cimSession | Remove-CimSession


<# Remove PostgreSQL:

$programParams = @{
    ComputerName = $softwarePostgreSQL.ComputerName
    FilePath     = "$($softwarePostgreSQL.Parameters.prefix)\uninstall-postgresql.exe"
    ArgumentList = '--mode', 'unattended', '--unattendedmodeui', 'none'
}

$result = Invoke-Program @programParams
$result

Invoke-Command -ComputerName $softwarePostgreSQL.ComputerName -ScriptBlock { $null = Remove-Item -Path $using:softwarePostgreSQL.Parameters.prefix -Recurse -Force}

Restart-Computer -ComputerName $softwarePostgreSQL.ComputerName

#>
