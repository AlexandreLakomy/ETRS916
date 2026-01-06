# TD1 – Exercice 5 : Analyse et modification du jeu Space Invaders

## 1 - Récupération du code Space Invaders

Le code du jeu Space Invaders est fourni par l’enseignant.  
Il s’agit d’un script PowerShell utilisant :
- des boucles de jeu
- des variables globales
- des événements clavier
- un rafraîchissement de l’affichage dans la console

Aucune modification ne doit être effectuée avant d’avoir compris la structure du script.

---

## 2 - Mettre plusieurs crédits par défaut

Dans le script, une variable correspond généralement au nombre de crédits ou de vies du joueur.

Exemples de noms possibles :
- `$Lives`
- `$Credits`
- `$PlayerLives`

### Modification attendue
Remplacer l’initialisation par une valeur supérieure à 1.

Exemple :
```powershell
$Lives = 3
```

devient :
```powershell
$Lives = 10
```

Cette modification permet au joueur d'avoir 10 vies avant de recommencer de 0.

## 3 - Permettre de tirer plusieurs tirs d’affilée

Par défaut, le script limite souvent le tir à :

- un projectile à l’écran
- ou un délai entre deux tirs

Cela est généralement géré par :

- une variable booléenne ($CanShoot)
- une condition sur le nombre de projectiles actifs
- un temps d’attente (Start-Sleep)

## Modification possible

Supprimer ou assouplir la condition qui empêche plusieurs tirs simultanés.

Exemple de logique restrictive :
```powershell
if ($ProjectileActive -eq $false) {
    Shoot
}
```
Modification :
Exemple de logique restrictive :
```powershell
Shoot
```
ou autoriser plusieurs projectiles dans une collection (tableau).

## 4 - Rendre le joueur invulnérable

Lorsqu’un ennemi touche le joueur, le script :

- décrémente le nombre de vies
- déclenche une condition de défaite

Cette logique est généralement contenue dans :

- une condition if
- une fonction de collision

### Modification attendue

Neutraliser la perte de vie en :

- supprimant la décrémentation
- ou forçant la valeur des vies à rester constante

Exemple :
```powershell
$Lives--
```
Peut être :
- commenté
- ou supprimé

Ou remplacé par :
```powershell
$Lives = $Lives
```

## 5 - Validation des modifications

Après modification, il est possible de vérifier que :

- le nombre de crédits ne diminue plus
- plusieurs tirs peuvent être effectués sans restriction
- le joueur ne perd plus de vie en cas de collision

Ces modifications doivent être testées directement dans la console PowerShell.