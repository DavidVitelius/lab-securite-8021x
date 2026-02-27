# =============================================================================
# Script 04 - Configuration des Templates de certificats pour 802.1X
# Machine cible : SubCA01
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# Crée les templates nécessaires pour 802.1X EAP-TLS :
#   - Certificat serveur NPS (authentification RADIUS)
#   - Certificat ordinateur (authentification 802.1X machines)
#   - Certificat utilisateur (authentification 802.1X utilisateurs)
# =============================================================================

#Requires -RunAsAdministrator

Import-Module ActiveDirectory

Write-Host '=== [04] Configuration des templates de certificats 802.1X ===' -ForegroundColor Cyan

# --- Template : Certificat Serveur NPS ---
# Basé sur le template "RASAndIASServer" (serveur NPS/RADIUS)
$npsCertTemplate = Get-CATemplate | Where-Object { $_.Name -eq 'RASAndIASServer' }
if ($npsCertTemplate) {
    Write-Host '  Template RASAndIASServer déjà disponible.' -ForegroundColor Green
} else {
    Write-Host '  Ajout du template RASAndIASServer...' -ForegroundColor Yellow
    Add-CATemplate -Name 'RASAndIASServer' -Force
}

# --- Template : Certificat Ordinateur (Computer) ---
$computerTemplate = Get-CATemplate | Where-Object { $_.Name -eq 'Computer' }
if ($computerTemplate) {
    Write-Host '  Template Computer déjà disponible.' -ForegroundColor Green
} else {
    Write-Host '  Ajout du template Computer...' -ForegroundColor Yellow
    Add-CATemplate -Name 'Computer' -Force
}

# --- Template : Certificat Utilisateur (User) ---
$userTemplate = Get-CATemplate | Where-Object { $_.Name -eq 'User' }
if ($userTemplate) {
    Write-Host '  Template User déjà disponible.' -ForegroundColor Green
} else {
    Write-Host '  Ajout du template User...' -ForegroundColor Yellow
    Add-CATemplate -Name 'User' -Force
}

Write-Host '=== [04] Templates configurés ===' -ForegroundColor Green
Write-Host 'ETAPE SUIVANTE : Configurer la GPO d autoenrollment (script 07)' -ForegroundColor Yellow

# Lister tous les templates actifs
Write-Host "`n=== Templates actifs sur la CA ===" -ForegroundColor Cyan
Get-CATemplate | Format-Table -AutoSize
