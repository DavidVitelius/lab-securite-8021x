# =============================================================================
# Script 05 - Installation et configuration NPS (RADIUS)
# Machine cible : SubCA01 (ou serveur NPS dédié)
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# Le NPS (Network Policy Server) est le serveur RADIUS qui :
#   - Reçoit les demandes d'authentification du switch/AP
#   - Vérifie le certificat du client
#   - Autorise ou refuse l'accès au réseau
# =============================================================================

#Requires -RunAsAdministrator

# IPs des équipements réseau (switchs/AP) qui enverront les requêtes RADIUS
$RadiusClients = @(
    @{ Name = 'Switch-Core';   IP = '192.168.10.1';  Secret = 'R@dius$ecret2024!' },
    @{ Name = 'AP-WiFi-01';    IP = '192.168.10.2';  Secret = 'R@dius$ecret2024!' },
    @{ Name = 'AP-WiFi-02';    IP = '192.168.10.3';  Secret = 'R@dius$ecret2024!' }
)

Write-Host '=== [05] Installation du rôle NPS (RADIUS) ===' -ForegroundColor Cyan

Install-WindowsFeature -Name NPAS -IncludeManagementTools

Write-Host '=== [05] Enregistrement du serveur NPS dans Active Directory ===' -ForegroundColor Cyan

# Enregistrer le serveur NPS dans AD (lui donne le droit de lire les propriétés dial-in des comptes)
netsh nps set registered

Write-Host '=== [05] Ajout des clients RADIUS (switchs / points d accès) ===' -ForegroundColor Cyan

foreach ($client in $RadiusClients) {
    $existing = Get-NpsRadiusClient -Name $client.Name -ErrorAction SilentlyContinue
    if (-not $existing) {
        New-NpsRadiusClient `
            -Name              $client.Name `
            -Address           $client.IP `
            -SharedSecret      $client.Secret `
            -AuthAttributeRequired $false
        Write-Host "  Client RADIUS ajouté : $($client.Name) ($($client.IP))" -ForegroundColor Green
    } else {
        Write-Host "  Client RADIUS déjà existant : $($client.Name)" -ForegroundColor Yellow
    }
}

Write-Host '=== [05] Demande du certificat serveur NPS ===' -ForegroundColor Cyan

# Demander un certificat depuis la CA (template RASAndIASServer)
$cert = Get-Certificate `
    -Template   'RASAndIASServer' `
    -CertStoreLocation 'Cert:\LocalMachine\My'

if ($cert) {
    Write-Host "  Certificat NPS obtenu : $($cert.Certificate.Thumbprint)" -ForegroundColor Green
} else {
    Write-Host '  ERREUR : Certificat NPS non obtenu. Vérifier la CA.' -ForegroundColor Red
}

Write-Host '=== [05] NPS installé ===' -ForegroundColor Green
Write-Host 'ETAPE SUIVANTE : Configurer les politiques 802.1X (script 06)' -ForegroundColor Yellow
