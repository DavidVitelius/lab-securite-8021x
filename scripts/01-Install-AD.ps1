# =============================================================================
# Script 01 - Installation Active Directory Domain Services
# Machine cible : DC01
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================

#Requires -RunAsAdministrator

$DomainName    = 'lab.local'
$DomainNetbios = 'LAB'
$SafeModePassword = (ConvertTo-SecureString 'P@ssword123!' -AsPlainText -Force)

Write-Host '=== [01] Installation du rôle AD DS ===' -ForegroundColor Cyan

# Installation du rôle
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

Write-Host '=== [01] Promotion du contrôleur de domaine ===' -ForegroundColor Cyan

# Création de la forêt AD
Install-ADDSForest `
    -DomainName            $DomainName `
    -DomainNetbiosName     $DomainNetbios `
    -SafeModeAdministratorPassword $SafeModePassword `
    -InstallDns            $true `
    -Force                 $true

Write-Host '=== [01] Redémarrage en cours... ===' -ForegroundColor Yellow
# Le serveur redémarre automatiquement après la promotion
