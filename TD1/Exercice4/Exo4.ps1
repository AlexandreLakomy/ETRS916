$RemoteComputer = "192.168.141.28"

Invoke-Command -ComputerName $RemoteComputer -ScriptBlock {

    $LogDir = "C:\Temp"
    $LogFile = "$LogDir\Exo4.log"

    if (-not (Test-Path $LogDir)) {
        New-Item -Path $LogDir -ItemType Directory | Out-Null
    }

    function Write-Log {
        param ([string]$Message)
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogFile -Value "$timestamp [INFO] $Message"
    }

    Write-Log "Exercice 4 script started"

    $RegPath = "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
    $ValueName = "EnableMulticast"

    if (-not (Test-Path $RegPath)) {
        Write-Log "Registry key does not exist. Creating it."
        New-Item -Path $RegPath -Force | Out-Null
    }
    else {
        Write-Log "Registry key already exists."
    }

    $existingValue = Get-ItemPropertyValue `
        -Path $RegPath `
        -Name $ValueName `
        -ErrorAction SilentlyContinue

    if ($null -eq $existingValue) {
        Write-Log "Registry value does not exist. Creating it."
        New-ItemProperty `
            -Path $RegPath `
            -Name $ValueName `
            -PropertyType DWord `
            -Value 0 `
            -Force | Out-Null
    }
    else {
        Write-Log "Registry value already exists."
    }

    Write-Log "Exercice 4 script finished"
}
