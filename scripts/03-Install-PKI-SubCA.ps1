# =============================================================================
# Script 03 - Installation CA Subordonnée (Enterprise Subordinate CA)
# Machine cible : SubCA01  (jointe au domaine lab.local)
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# PRÉ-REQUIS :
#   - DC01 doit être opérationnel
#   - SubCA01 doit être jointe au domaine lab.local
#   - Le certificat Root CA doit être disponible (ex: \\DC01\CertEnroll)
# =============================================================================

#Requires -RunAsAdministrator

$CAName       = 'LAB-SubCA'
$CACommonName = 'LAB Subordinate Certificate Authority'
$RootCACertPath = 'C:\RootCA\LAB-RootCA.crt'   # Chemin du cert Root CA copié manuellement

Write-Host '=== [03] Installation du rôle AD CS (Subordinate CA) ===' -ForegroundColor Cyan

Install-WindowsFeature -Name ADCS-Cert-Authority, ADCS-Web-Enrollment -IncludeManagementTools

Write-Host '=== [03] Configuration de la CA Subordonnée ===' -ForegroundColor Cyan

# Installer la CA subordonnée - génère une CSR à signer par la Root CA
Install-AdcsCertificationAuthority `
    -CAType                    EnterpriseSubordinateCA `
    -CACommonName              $CACommonName `
    -KeyLength                 2048 `
    -HashAlgorithmName         SHA256 `
    -CryptoProviderName        'RSA#Microsoft Software Key Storage Provider' `
    -OutputCertRequestFile     'C:\SubCA.req' `
    -Force

Write-Host '=== [03] Une CSR a été générée : C:\SubCA.req ===' -ForegroundColor Yellow
Write-Host 'ETAPE MANUELLE REQUISE :' -ForegroundColor Red
Write-Host '  1. Copier C:\SubCA.req vers RootCA01' -ForegroundColor Yellow
Write-Host '  2. Sur RootCA01 : certreq -submit -attrib "CertificateTemplate:SubCA" C:\SubCA.req C:\SubCA.crt' -ForegroundColor Yellow
Write-Host '  3. Copier le fichier SubCA.crt signé ici : C:\SubCA.crt' -ForegroundColor Yellow
Write-Host '  4. Relancer ce script avec le paramètre -InstallCert' -ForegroundColor Yellow

# Décommenter après avoir récupéré le certificat signé par la Root CA
# certutil -installcert C:\SubCA.crt
# net start CertSvc

# Publier le cert Root CA dans AD (nécessaire pour les clients)
Write-Host '=== [03] Publication du certificat Root CA dans Active Directory ===' -ForegroundColor Cyan
# certutil -dspublish -f $RootCACertPath RootCA

Write-Host '=== [03] Configuration Web Enrollment ===' -ForegroundColor Cyan
Install-AdcsWebEnrollment -Force

Write-Host '=== [03] CA Subordonnée configurée ===' -ForegroundColor Green
