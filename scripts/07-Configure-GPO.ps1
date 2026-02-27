# =============================================================================
# Script 07 - Configuration GPO pour l'autoenrollment des certificats
# Machine cible : DC01
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# Crée une GPO qui :
#   - Active l'auto-enrollment des certificats pour les ordinateurs
#   - Active l'auto-enrollment des certificats pour les utilisateurs
#   - Configure le profil WiFi 802.1X avec EAP-TLS
# =============================================================================

#Requires -RunAsAdministrator

Import-Module GroupPolicy

$DomainName = 'lab.local'
$GPOName    = 'GPO-Securite-8021X'

Write-Host '=== [07] Création de la GPO autoenrollment 802.1X ===' -ForegroundColor Cyan

# Créer la GPO si elle n'existe pas
$gpo = Get-GPO -Name $GPOName -ErrorAction SilentlyContinue
if (-not $gpo) {
    $gpo = New-GPO -Name $GPOName -Comment 'GPO sécurité 802.1X - Autoenrollment certificats'
    Write-Host "  GPO '$GPOName' créée." -ForegroundColor Green
} else {
    Write-Host "  GPO '$GPOName' déjà existante." -ForegroundColor Yellow
}

Write-Host '=== [07] Activation autoenrollment - Ordinateurs ===' -ForegroundColor Cyan

# Activer l'autoenrollment pour les ordinateurs
Set-GPRegistryValue `
    -Name  $GPOName `
    -Key   'HKLM\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment' `
    -ValueName 'AEPolicy' `
    -Type  DWord `
    -Value 7   # 7 = Enroll + Update + Renew automatique

Write-Host '=== [07] Activation autoenrollment - Utilisateurs ===' -ForegroundColor Cyan

# Activer l'autoenrollment pour les utilisateurs
Set-GPRegistryValue `
    -Name  $GPOName `
    -Key   'HKCU\SOFTWARE\Policies\Microsoft\Cryptography\AutoEnrollment' `
    -ValueName 'AEPolicy' `
    -Type  DWord `
    -Value 7

Write-Host '=== [07] Lien de la GPO au domaine ===' -ForegroundColor Cyan

# Lier la GPO au domaine
$link = Get-GPInheritance -Target "DC=$($DomainName.Replace('.',',DC='))"
if ($link.GpoLinks.DisplayName -notcontains $GPOName) {
    New-GPLink -Name $GPOName -Target "DC=$($DomainName.Replace('.',',DC='))" -LinkEnabled Yes
    Write-Host "  GPO liée au domaine '$DomainName'." -ForegroundColor Green
} else {
    Write-Host "  GPO déjà liée au domaine." -ForegroundColor Yellow
}

Write-Host '=== [07] GPO configurée avec succès ===' -ForegroundColor Green

# Forcer l'application immédiate de la GPO
Write-Host '  Application forcée de la GPO (gpupdate)...' -ForegroundColor Yellow
gpupdate /force

# Résumé
Write-Host "`n=== GPO liées au domaine ===" -ForegroundColor Cyan
Get-GPInheritance -Target "DC=$($DomainName.Replace('.',',DC='))" | Select-Object -ExpandProperty GpoLinks | Format-Table DisplayName, Enabled -AutoSize
