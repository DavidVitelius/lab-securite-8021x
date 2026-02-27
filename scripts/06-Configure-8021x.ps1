# =============================================================================
# Script 06 - Configuration des politiques réseau 802.1X sur NPS
# Machine cible : SubCA01 (serveur NPS)
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# Crée 2 politiques NPS :
#   - 802.1X Ethernet  : authentification par certificat sur ports câblés
#   - 802.1X WiFi      : authentification par certificat sur WiFi
# =============================================================================

#Requires -RunAsAdministrator

Write-Host '=== [06] Configuration des politiques réseau NPS pour 802.1X ===' -ForegroundColor Cyan

# --- Politique : 802.1X Ethernet (câblé) ---
Write-Host '  Création politique 802.1X Ethernet...' -ForegroundColor Yellow

$ethernetPolicy = Get-NpsNetworkPolicy -Name '802.1X-Ethernet' -ErrorAction SilentlyContinue
if (-not $ethernetPolicy) {
    New-NpsNetworkPolicy `
        -Name                  '802.1X-Ethernet' `
        -ProcessingOrder       10 `
        -Enabled               $true `
        -ConditionString       'NAS-Port-Type=Ethernet' `
        -AuthenticationTypes   'EAP' `
        -EapConfig             '<EapConfig><EapType Id="13" xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><EapType><CredentialsSource><CertificateStore/></CredentialsSource></EapType></EapType></EapConfig>'
    Write-Host '  Politique 802.1X-Ethernet créée.' -ForegroundColor Green
} else {
    Write-Host '  Politique 802.1X-Ethernet déjà existante.' -ForegroundColor Yellow
}

# --- Politique : 802.1X WiFi ---
Write-Host '  Création politique 802.1X WiFi...' -ForegroundColor Yellow

$wifiPolicy = Get-NpsNetworkPolicy -Name '802.1X-WiFi' -ErrorAction SilentlyContinue
if (-not $wifiPolicy) {
    New-NpsNetworkPolicy `
        -Name                  '802.1X-WiFi' `
        -ProcessingOrder       20 `
        -Enabled               $true `
        -ConditionString       'NAS-Port-Type=Wireless-IEEE-802.11' `
        -AuthenticationTypes   'EAP' `
        -EapConfig             '<EapConfig><EapType Id="13" xmlns="http://www.microsoft.com/provisioning/EapHostConfig"><EapType><CredentialsSource><CertificateStore/></CredentialsSource></EapType></EapType></EapConfig>'
    Write-Host '  Politique 802.1X-WiFi créée.' -ForegroundColor Green
} else {
    Write-Host '  Politique 802.1X-WiFi déjà existante.' -ForegroundColor Yellow
}

# --- Politique de requête de connexion ---
Write-Host '  Configuration de la politique de requête de connexion...' -ForegroundColor Yellow

$connectionPolicy = Get-NpsConnectionRequestPolicy -Name '802.1X-Connection-Request' -ErrorAction SilentlyContinue
if (-not $connectionPolicy) {
    New-NpsConnectionRequestPolicy `
        -Name             '802.1X-Connection-Request' `
        -ProcessingOrder  10 `
        -Enabled          $true
    Write-Host '  Politique de connexion créée.' -ForegroundColor Green
}

Write-Host '=== [06] Politiques 802.1X configurées ===' -ForegroundColor Green

# Afficher un résumé des politiques actives
Write-Host "`n=== Politiques réseau NPS actives ===" -ForegroundColor Cyan
Get-NpsNetworkPolicy | Format-Table Name, ProcessingOrder, Enabled -AutoSize
