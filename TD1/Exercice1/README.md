# TD1 – Exercice 1 : Gestion des processus

## 1 - Lister tous les PID de la machine
Pour lister tous les PID de la machine, nous pouvons utiliser la commande suivante :
```powershell
Get-Process
```
Nous obtenons tout les PID avec les données suivantes :
Handles - NPM(K) - PM(K) - WS(K) - CPU(s) - Id - SI - ProcessName

C'est possible de filtrer en faisant la commande suivante :
```powershell
Get-Process | Select-Object Name, Id
```
Nous obtenons tous les PID avec les données suivantes :
Name - Id

## 2 - Lister uniquement un process donné
Ici, nous listons tout les PID, filtrés avec un nom qui commence par notepad, avec toutes les données :
```powershell
Get-Process -Name notepad
```
Ici, nous listons tout les PID, filtrés avec un nom qui commence par notepad, avec les données filtrés par Name et Id :
```powershell
Get-Process -Name notepad | Select-Object Name, Id
```

## 3 - Tuer un process donné
Pour tuer un process donné, ici notepad, nous utilisons la commande suivante :
```powershell
Stop-Process -Name notepad -Force
```
