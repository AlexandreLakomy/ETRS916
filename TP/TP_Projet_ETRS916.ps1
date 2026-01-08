#Import des modules
Import-Module ActiveDirectory

# ===== CONFIGURATION DES LOGS =====
$LogFile = "AD_Sync_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$LogPath = Join-Path $PSScriptRoot $LogFile

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"  # INFO, WARNING, ERROR
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$Level] $Message"
    
    # Affichage console avec couleur selon le niveau
    switch ($Level) {
        "ERROR"   { Write-Host $LogEntry -ForegroundColor Red }
        "WARNING" { Write-Host $LogEntry -ForegroundColor Yellow }
        default   { Write-Host $LogEntry -ForegroundColor Gray }
    }
    
    # Écriture dans le fichier log
    Add-Content -Path $LogPath -Value $LogEntry
}

# ===== DÉBUT DU SCRIPT =====
Write-Log "===== DÉMARRAGE DU SCRIPT ====="

# AD - Variables de connexions
$Username = 'user_AA'
$Domain = 'tdtri.fr'
$Login = "$Username@$Domain"
$Password = ConvertTo-SecureString "AA_ldapRO_01!" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($Login, $Password)
$ControlerDomain = 'WIN-50LAD:3268'

Write-Log "Configuration : Domaine=$Domain, Serveur=$ControlerDomain"

# ===== POINT 1 : Récupération des groupes AD =====
Write-Log "===== POINT 1 : Récupération des groupes AD ====="

try {
    $Groups = Get-ADGroup -Filter * `
        -Server $ControlerDomain `
        -Credential $Cred -ErrorAction Stop
    
    Write-Log "Nombre de groupes récupérés : $($Groups.Count)"
} catch {
    Write-Log "ERREUR lors de la récupération des groupes : $($_.Exception.Message)" "ERROR"
    exit 1
}

# ===== POINT 2 : Récupération des utilisateurs par groupe =====
Write-Log "===== POINT 2 : Récupération des utilisateurs par groupe ====="

$GroupsWithUsers = 0
$TotalUsersFound = 0

foreach ($Group in $Groups) {
    Write-Log "Traitement du groupe : $($Group.Name)"
    
    try {
        $Users = Get-ADUser `
            -LDAPFilter "(memberOf=$($Group.DistinguishedName))" `
            -Server $ControlerDomain `
            -Credential $Cred -ErrorAction Stop
        
        if ($Users) {
            $GroupsWithUsers++
            $UserCount = ($Users | Measure-Object).Count
            $TotalUsersFound += $UserCount
            Write-Log "  -> $UserCount utilisateur(s) trouvé(s)"
        } else {
            Write-Log "  -> Aucun utilisateur" "WARNING"
        }
    } catch {
        Write-Log "  -> ERREUR : $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Résumé : $GroupsWithUsers groupe(s) avec utilisateurs, $TotalUsersFound utilisateur(s) au total"

# ===== POINT 3 : Stockage des utilisateurs avec leurs groupes =====
Write-Log "===== POINT 3 : Stockage des utilisateurs avec leurs groupes ====="

$UserGroups = @{}

foreach ($Group in $Groups) {
    try {
        $Users = Get-ADUser `
            -LDAPFilter "(memberOf=$($Group.DistinguishedName))" `
            -Server $ControlerDomain `
            -Credential $Cred -ErrorAction Stop
        
        if ($Users) {
            foreach ($User in $Users) {
                $Login = $User.SamAccountName
                
                if (-not $UserGroups.ContainsKey($Login)) {
                    $UserGroups[$Login] = @()
                    Write-Log "Nouvel utilisateur détecté : $Login"
                }
                
                $UserGroups[$Login] += $Group.Name
            }
        }
    } catch {
        Write-Log "ERREUR lors du traitement du groupe $($Group.Name) : $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Nombre total d'utilisateurs uniques : $($UserGroups.Count)"

# Affichage détaillé de quelques utilisateurs
Write-Log "Exemple d'utilisateurs (5 premiers) :"
$UserGroups.GetEnumerator() | Select-Object -First 5 | ForEach-Object {
    Write-Log "  User: $($_.Key) -> Groupes: $($_.Value -join ', ')"
}

Write-Log "===== FIN DU SCRIPT ====="
Write-Log "Log sauvegardé dans : $LogPath"