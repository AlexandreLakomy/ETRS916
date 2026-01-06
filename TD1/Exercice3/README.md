# TD1 – Exercice 3 : Ouverture des ports WinRM

## 1 - Ouverture des ports avec des commandes PowerShell

Les commandes suivantes permettent de créer les règles de pare-feu nécessaires.  
Ces commandes doivent être exécutées dans une console PowerShell lancée en tant qu’administrateur.

### Ouverture du port 5985 (WinRM HTTP)

```powershell
New-NetFirewallRule `
  -DisplayName "WinRM HTTP 5985" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5985 `
  -Action Allow `
  -RemoteAddress Any `
  -Group "Windows Remote Management"
```

### Ouverture du port 5986 (WinRM HTTPS)

```powershell
New-NetFirewallRule `
  -DisplayName "WinRM HTTPS 5986" `
  -Direction Inbound `
  -Protocol TCP `
  -LocalPort 5986 `
  -Action Allow `
  -RemoteAddress Any `
  -Group "Windows Remote Management"
```

## 2 - Script PowerShell automatisé

Le script suivant permet de créer automatiquement les règles de pare-feu uniquement si elles n’existent pas déjà, afin d’éviter toute duplication.

### Script : Exo3.ps1

```powershell
$Rules = @(
    @{
        Name = "WinRM HTTP 5985"
        Port = 5985
    },
    @{
        Name = "WinRM HTTPS 5986"
        Port = 5986
    }
)

foreach ($rule in $Rules) {

    $existingRule = Get-NetFirewallRule `
        -DisplayName $rule.Name `
        -ErrorAction SilentlyContinue

    if (-not $existingRule) {

        New-NetFirewallRule `
            -DisplayName $rule.Name `
            -Direction Inbound `
            -Protocol TCP `
            -LocalPort $rule.Port `
            -Action Allow `
            -RemoteAddress Any `
            -Group "Windows Remote Management" | Out-Null
    }
}

# Vérification finale
$allOk = $true

foreach ($rule in $Rules) {

    $fwRule = Get-NetFirewallRule `
        -DisplayName $rule.Name `
        -ErrorAction SilentlyContinue

    if (-not $fwRule -or -not $fwRule.Enabled) {
        Write-Host "Rule '$($rule.Name)' is missing or disabled" -ForegroundColor Red
        $allOk = $false
    }
}

if ($allOk) {
    Write-Host "WinRM firewall configuration is correct (ports 5985 and 5986 are open)" -ForegroundColor Green
}
else {
    Write-Host "WinRM firewall configuration is NOT correct" -ForegroundColor Red
}

```

## 3 - Vérification des règles de pare-feu

Après l’exécution des commandes ou du script, il est possible de vérifier la présence des règles avec la commande suivante :

```powershell
Get-NetFirewallRule -Group "Windows Remote Management" |
Select-Object DisplayName, Enabled, Direction
```

Les règles WinRM HTTP 5985 et WinRM HTTPS 5986 doivent apparaître comme activées et en direction entrante.