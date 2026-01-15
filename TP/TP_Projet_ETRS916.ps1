<# README – TP ETRS916
Ce script PowerShell synchronise automatiquement les droits GitLab à partir des groupes Active Directory.

Fonctionnalités :
- Récupération des groupes et utilisateurs AD
- Association users ↔ départements ↔ rôles (Leads / Users)
- Listing des projets GitLab via l’API
- Attribution automatique des droits (Developer / Maintainer / Reporter)
- Synchronisation complète (ajout, mise à jour, suppression)
- Journalisation détaillée de l’exécution

Auteur : LAKOMY Alexandre - Master 2 - TRI - 2026 #>


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

# ===== CONFIGURATION AD =====
$Username = 'user_AA'
$Domain = 'tdtri.fr'
$Login = "$Username@$Domain"
$Password = ConvertTo-SecureString "AA_ldapRO_01!" -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PSCredential ($Login, $Password)
$ControlerDomain = 'WIN-50LAD:3268'

Write-Log "Configuration AD : Domaine=$Domain, Serveur=$ControlerDomain"

# ===== CONFIGURATION GITLAB =====
$GitLabUrl = "https://192.168.141.217"
$GitLabToken = "glpat-meRPQn6fcouLGBRF-qwV4W86MQp1OjEH.01.0w1w2ux2z"
$GitLabHeaders = @{
    "PRIVATE-TOKEN" = $GitLabToken
}

Write-Log "Configuration GitLab : URL=$GitLabUrl"

# Ignorer les erreurs SSL (pour les certificats auto-signés)
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type) {
    $certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback == null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
}
[ServerCertificateValidationCallback]::Ignore()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ===== FONCTIONS GITLAB =====
function Get-GitLabProjects {
    Write-Log "Récupération de la liste des projets GitLab..."
    try {
        $allProjects = @()
        $page = 1
        $perPage = 100
        
        do {
            $uri = "$GitLabUrl/api/v4/projects?page=$page&per_page=$perPage&membership=false"
            $response = Invoke-RestMethod -Uri $uri -Headers $GitLabHeaders -Method Get
            
            if ($response) {
                $allProjects += $response
                Write-Log "  Page $page : $($response.Count) projet(s) récupéré(s)"
                $page++
            }
        } while ($response.Count -eq $perPage)
        
        Write-Log "Total : $($allProjects.Count) projet(s) GitLab récupéré(s)"
        return $allProjects
    } catch {
        Write-Log "ERREUR lors de la récupération des projets : $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Get-GitLabProjectMembers {
    param([int]$ProjectId)
    
    try {
        $uri = "$GitLabUrl/api/v4/projects/$ProjectId/members/all"
        $members = Invoke-RestMethod -Uri $uri -Headers $GitLabHeaders -Method Get
        return $members
    } catch {
        Write-Log "  ERREUR lors de la récupération des membres du projet $ProjectId : $($_.Exception.Message)" "ERROR"
        return @()
    }
}

function Add-GitLabProjectMember {
    param(
        [int]$ProjectId,
        [string]$Username,
        [int]$AccessLevel
    )
    
    try {
        # D'abord on récupère l'ID de l'utilisateur
        $uri = "$GitLabUrl/api/v4/users?username=$Username"
        $user = Invoke-RestMethod -Uri $uri -Headers $GitLabHeaders -Method Get
        
        if (-not $user -or $user.Count -eq 0) {
            Write-Log "  User '$Username' n'existe pas dans GitLab" "WARNING"
            return $false
        }
        
        $userId = $user[0].id
        
        # Ajouter le membre au projet
        $uri = "$GitLabUrl/api/v4/projects/$ProjectId/members"
        $body = @{
            user_id = $userId
            access_level = $AccessLevel
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $uri -Headers $GitLabHeaders -Method Post -Body $body -ContentType "application/json"
        Write-Log "  ✓ User '$Username' ajouté au projet (access_level=$AccessLevel)"
        return $true
    } catch {
        if ($_.Exception.Message -like "*409*") {
            Write-Log "  User '$Username' existe déjà dans le projet" "WARNING"
        } else {
            Write-Log "  ERREUR lors de l'ajout de '$Username' : $($_.Exception.Message)" "ERROR"
        }
        return $false
    }
}

function Update-GitLabProjectMember {
    param(
        [int]$ProjectId,
        [int]$UserId,
        [string]$Username,
        [int]$AccessLevel
    )
    
    try {
        $uri = "$GitLabUrl/api/v4/projects/$ProjectId/members/$UserId"
        $body = @{
            access_level = $AccessLevel
        } | ConvertTo-Json
        
        $response = Invoke-RestMethod -Uri $uri -Headers $GitLabHeaders -Method Put -Body $body -ContentType "application/json"
        Write-Log "  ✓ User '$Username' mis à jour (access_level=$AccessLevel)"
        return $true
    } catch {
        Write-Log "  ERREUR lors de la mise à jour de '$Username' : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-GitLabProjectMember {
    param(
        [int]$ProjectId,
        [int]$UserId,
        [string]$Username
    )
    
    try {
        $uri = "$GitLabUrl/api/v4/projects/$ProjectId/members/$UserId"
        Invoke-RestMethod -Uri $uri -Headers $GitLabHeaders -Method Delete | Out-Null
        Write-Log "  ✓ User '$Username' supprimé du projet"
        return $true
    } catch {
        Write-Log "  ERREUR lors de la suppression de '$Username' : $($_.Exception.Message)" "ERROR"
        return $false
    }
}

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

# ===== POINT 2 & 3 OPTIMISÉS : Récupération des utilisateurs avec leurs groupes =====
Write-Log "===== POINT 2 : Récupération des utilisateurs ====="

try {
    # UNE SEULE requête pour récupérer TOUS les utilisateurs avec leurs groupes
    $AllUsers = Get-ADUser -Filter * `
        -Properties MemberOf, SamAccountName `
        -Server $ControlerDomain `
        -Credential $Cred -ErrorAction Stop
    
    Write-Log "Nombre total d'utilisateurs récupérés : $($AllUsers.Count)"
    
} catch {
    Write-Log "ERREUR lors de la récupération des utilisateurs : $($_.Exception.Message)" "ERROR"
    exit 1
}

# ===== POINT 3 : Stockage des utilisateurs avec leurs groupes =====
Write-Log "===== POINT 3 : Stockage des utilisateurs avec leurs groupes ====="

$UserGroups = @{}
$TotalUsersFound = 0

# Créer un mapping GroupDN -> GroupName. Comme ça on optimise donc plus rapide.
$GroupDNToName = @{}
foreach ($Group in $Groups) {
    $GroupDNToName[$Group.DistinguishedName] = $Group.Name
}

# Filtrer uniquement les groupes pertinents
$RelevantGroups = @('GG_Logistique', 'GG_Finance', 'GG_RH', 'GG_Leads')

foreach ($User in $AllUsers) {
    $Login = $User.SamAccountName
    
    if ($User.MemberOf -and $User.MemberOf.Count -gt 0) {
        # Extraire les noms des groupes depuis les DN
        $GroupNames = $User.MemberOf | ForEach-Object {
            # Utiliser le mapping pour récupérer le nom
            if ($GroupDNToName.ContainsKey($_)) {
                $GroupDNToName[$_]
            }
        } | Where-Object { $_ -in $RelevantGroups }
        
        if ($GroupNames.Count -gt 0) {
            $UserGroups[$Login] = @($GroupNames)
            $TotalUsersFound++
            Write-Log "Nouvel utilisateur détecté : $Login -> Groupes: $($GroupNames -join ', ')"
        }
    }
}

# Compter les groupes qui ont des utilisateurs
$GroupsWithUsersSet = @{}
foreach ($UserGroupList in $UserGroups.Values) {
    foreach ($GroupName in $UserGroupList) {
        $GroupsWithUsersSet[$GroupName] = $true
    }
}
$GroupsWithUsers = $GroupsWithUsersSet.Count

Write-Log "Résumé : $GroupsWithUsers groupe(s) avec utilisateurs, $TotalUsersFound utilisateur(s) au total"
Write-Log "Nombre total d'utilisateurs uniques : $($UserGroups.Count)"

# ===== PARTIE GITLAB =====
Write-Log "===== PARTIE GITLAB : Synchronisation des droits ====="

# Niveaux d'accès GitLab
$AccessLevelDeveloper = 30
$AccessLevelMaintainer = 40
$AccessLevelReporter = 20

# 1. Récupération de tous les projets
Write-Log "===== GITLAB - Étape 1 : Liste des projets ====="
$GitLabProjects = Get-GitLabProjects

if ($GitLabProjects.Count -eq 0) {
    Write-Log "Aucun projet GitLab trouvé. Arrêt du script." "ERROR"
    exit 1
}

# Afficher projets
foreach ($project in $GitLabProjects) {
    Write-Log "Projet trouvé : [$($project.id)] $($project.path_with_namespace)"
}

# 2. Créer un mapping des projets par département (basé sur le namespace/group)
$ProjectsByDepartment = @{
    'Logistique' = @()
    'Finance' = @()
    'RH' = @()
}

foreach ($project in $GitLabProjects) {
    $namespace = $project.namespace.name
    
    if ($namespace -like "*Logistique*") {
        $ProjectsByDepartment['Logistique'] += $project
    } elseif ($namespace -like "*Finance*") {
        $ProjectsByDepartment['Finance'] += $project
    } elseif ($namespace -like "*RH*") {
        $ProjectsByDepartment['RH'] += $project
    }
}

Write-Log "Projets par département :"
foreach ($dept in $ProjectsByDepartment.Keys) {
    Write-Log "  $dept : $($ProjectsByDepartment[$dept].Count) projet(s)"
}

# 3. Synchronisation des droits
Write-Log "===== GITLAB - Étape 2-3-4 : Synchronisation des droits ====="

foreach ($project in $GitLabProjects) {
    Write-Log "---"
    Write-Log "Traitement du projet : [$($project.id)] $($project.name) (namespace: $($project.namespace.name))"
    
    # Déterminer le département du projet
    $projectDepartment = $null
    $namespace = $project.namespace.name
    
    if ($namespace -like "*Logistique*") {
        $projectDepartment = 'Logistique'
    } elseif ($namespace -like "*Finance*") {
        $projectDepartment = 'Finance'
    } elseif ($namespace -like "*RH*") {
        $projectDepartment = 'RH'
    }
    
    if (-not $projectDepartment) {
        Write-Log "  Département inconnu pour ce projet, ignoré" "WARNING"
        continue
    }
    
    Write-Log "  Département détecté : $projectDepartment"
    
    # Récupérer membres actuels du projet
    $currentMembers = Get-GitLabProjectMembers -ProjectId $project.id
    Write-Log "  Membres actuels : $($currentMembers.Count)"
    
    # Créer un hashtable des membres actuels pour comparaison
    $currentMembersMap = @{}
    foreach ($member in $currentMembers) {
        $currentMembersMap[$member.username] = $member
    }
    
    # Définir qui devrait avoir accès et avec quel niveau
    $expectedAccess = @{}
    
    # Parcourir tous les utilisateurs AD
    foreach ($username in $UserGroups.Keys) {
        $userGroupsList = $UserGroups[$username]
        
        $isLead = $userGroupsList -contains 'GG_Leads'
        $userDepartment = $null
        
        # Déterminer le département de l'utilisateur
        if ($userGroupsList -contains 'GG_Logistique') {
            $userDepartment = 'Logistique'
        } elseif ($userGroupsList -contains 'GG_Finance') {
            $userDepartment = 'Finance'
        } elseif ($userGroupsList -contains 'GG_RH') {
            $userDepartment = 'RH'
        }
        
        if (-not $userDepartment) {
            continue
        }
        
        # Déterminer le niveau d'accès approprié
        if ($isLead) {
            if ($userDepartment -eq $projectDepartment) {
                # Lead dans son département : Maintainer
                $expectedAccess[$username] = $AccessLevelMaintainer
            } else {
                # Lead dans un autre département : Reporter
                $expectedAccess[$username] = $AccessLevelReporter
            }
        } else {
            if ($userDepartment -eq $projectDepartment) {
                # User normal dans son département : Developer
                $expectedAccess[$username] = $AccessLevelDeveloper
            }
            # Sinon : pas d'accès
        }
    }
    
    Write-Log "  Accès attendus : $($expectedAccess.Count) utilisateur(s)"
    
    # Synchronisation des droits
    # 1. Ajouter ou mettre à jour les utilisateurs qui devraient avoir accès
    foreach ($username in $expectedAccess.Keys) {
        $expectedLevel = $expectedAccess[$username]
        
        if ($currentMembersMap.ContainsKey($username)) {
            # L'utilisateur existe déjà
            $currentMember = $currentMembersMap[$username]
            
            if ($currentMember.access_level -ne $expectedLevel) {
                # Niveau d'accès différent : mise à jour
                Write-Log "  Mise à jour nécessaire pour '$username' : $($currentMember.access_level) -> $expectedLevel"
                Update-GitLabProjectMember -ProjectId $project.id -UserId $currentMember.id -Username $username -AccessLevel $expectedLevel
            } else {
                Write-Log "  '$username' a déjà le bon niveau d'accès ($expectedLevel)"
            }
        } else {
            # L'utilisateur n'existe pas : ajout
            Write-Log "  Ajout nécessaire pour '$username' (access_level=$expectedLevel)"
            Add-GitLabProjectMember -ProjectId $project.id -Username $username -AccessLevel $expectedLevel
        }
    }
    
    # 2. Supprimer les utilisateurs qui ne devraient plus avoir accès
    foreach ($member in $currentMembers) {
        $username = $member.username
        
        # Ignorer les utilisateurs système ou admin
        if ($username -eq 'root' -or $username -eq 'user') {
            continue
        }
        
        if (-not $expectedAccess.ContainsKey($username)) {
            # Cet utilisateur ne devrait plus avoir accès
            Write-Log "  Suppression nécessaire pour '$username'"
            Remove-GitLabProjectMember -ProjectId $project.id -UserId $member.id -Username $username
        }
    }
}

Write-Log "===== FIN DU SCRIPT ====="
Write-Log "Log sauvegardé dans : $LogPath"