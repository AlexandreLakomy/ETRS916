# TD1 – Exercice 4 : Exécution distante via WinRM et ScriptBlock

## Objectif
L’objectif de cet exercice est d’exécuter à distance, via WinRM, le script de l’exercice 2 permettant de configurer une clé du registre Windows.

Le script doit :
- Utiliser WinRM
- Employer un ScriptBlock
- Modifier le registre sur une machine distante
- Fonctionner avec des droits administrateur

---

## Prérequis

Avant d’exécuter le script, les conditions suivantes doivent être remplies :

- WinRM activé sur la machine distante
- Les ports 5985 (HTTP) ou 5986 (HTTPS) doivent être ouverts (Exercice 3)
- L’utilisateur doit disposer des droits administrateur sur la machine distante

Activation de WinRM sur la machine distante :
```powershell
Enable-PSRemoting -Force
```

## 1 - Principe de fonctionnement

PowerShell permet d’exécuter des commandes à distance grâce à la commande Invoke-Command.
Le code à exécuter est placé dans un ScriptBlock, qui sera envoyé et exécuté sur la machine distante.

## 2 - Script PowerShell d’exécution distante
### Script : Exo4.ps1

```powershell
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
```

## 3 - Vérification de l’exécution distante

Sur la machine distante, il est possible de vérifier le fichier de log :

```powershell
notepad C:\Temp\Exo2.log
```

Clé de registre :
```powershell
Get-ItemProperty "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
```

Sur la machine distante, nous faisons :
```powershell
notepad C:\Temp\Exo4.log
```

Nous obtenons :
```powershell
[INFO] Registry key already exists.
[INFO] Registry value 'EnableMulticast' already exists.
[INFO] Exercice 4 script started
[INFO] Registry key already exists.
[INFO] Registry value already exists.
[INFO] Exercice 4 script finished
```