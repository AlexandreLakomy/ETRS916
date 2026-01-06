# TD1 – Exercice 2 : Modification du registre et journalisation

## 1 - Vérification et création de la clé registre

La clé registre à vérifier est la suivante "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"

Pour vérifier si cette clé existe, nous utilisons la commande :
```powershell
Test-Path "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient"
```

Si la clé n’existe pas, elle est créée avec la commande suivante :
```powershell
New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient" -Force
```

## 2 - Vérification et création de la valeur EnableMulticast

La valeur à vérifier est une valeur de type DWORD nommée EnableMulticast.
Pour vérifier si cette valeur existe dans la clé registre :
```powershell
Get-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient" -Name EnableMulticast
```

Si la valeur n’existe pas, elle est créée avec la valeur 0 :
```powershell
New-ItemProperty `
  -Path "HKLM:\Software\Policies\Microsoft\Windows NT\DNSClient" `
  -Name "EnableMulticast" `
  -PropertyType DWord `
  -Value 0 `
  -Force
```

## 3 - Mise en place de la journalisation (log)

Afin de suivre les actions effectuées par le script, un fichier de log est mis en place.
Chaque action importante (création ou existence de la clé et de la valeur) est enregistrée avec un horodatage et un niveau de log.

Exemple de contenu du fichier de log :
```powershell
2026-01-06 14:15:12 [INFO] Registry key does not exist. Creating it.
2026-01-06 14:15:12 [INFO] Registry value 'EnableMulticast' does not exist. Creating it with value 0.
```