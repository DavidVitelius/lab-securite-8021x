# =============================================================================
# Script 02 - Installation CA Racine (Standalone Root CA)
# Machine cible : RootCA01  (NON jointe au domaine - Workgroup)
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# NOTE : La Root CA doit rester hors domaine (bonne pratique PKI).
#        Elle sera mise hors ligne une fois la SubCA signée.
# =============================================================================

#Requires -RunAsAdministrator

$CAName       = 'LAB-RootCA'
$CACommonName = 'LAB Root Certificate Authority'

Write-Host '=== [02] Installation du rôle AD CS (Root CA) ===' -ForegroundColor Cyan

# Installation du rôle
Install-WindowsFeature -Name ADCS-Cert-Authority -IncludeManagementTools

Write-Host '=== [02] Configuration de la Root CA ===' -ForegroundColor Cyan

# Configuration en tant que CA racine autonome (Standalone)
Install-AdcsCertificationAuthority `
    -CAType                    StandaloneRootCA `
    -CACommonName              $CACommonName `
    -KeyLength                 4096 `
    -HashAlgorithmName         SHA256 `
    -ValidityPeriod            Years `
    -ValidityPeriodUnits       10 `
    -CryptoProviderName        'RSA#Microsoft Software Key Storage Provider' `
    -Force

Write-Host '=== [02] Configuration des extensions CRL ===' -ForegroundColor Cyan

# Configurer la période de publication CRL
certutil -setreg CA\CRLPeriodUnits 52
certutil -setreg CA\CRLPeriod "Weeks"
certutil -setreg CA\CRLDeltaPeriodUnits 0
certutil -setreg CA\CRLDeltaPeriod "Days"

# Redémarrer le service
Restart-Service CertSvc

# Publier la CRL
certutil -CRL

Write-Host '=== [02] Root CA installée avec succès ===' -ForegroundColor Green
Write-Host 'ETAPE SUIVANTE : Copier le certificat Root CA vers SubCA01' -ForegroundColor Yellow
Write-Host "Chemin du cert : C:\Windows\System32\CertSrv\CertEnroll\" -ForegroundColor Yellow
