# =============================================================================
# Script KPI - Rapport de sécurité réseau 802.1X
# Machine cible : DC01
# OS            : Windows Server 2022
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# Génère un rapport KPI mesurant l'efficacité de la solution 802.1X :
#   - Nombre de machines avec certificat valide
#   - Nombre d'authentifications réussies / échouées
#   - Taux de couverture 802.1X
#   - Certificats proches d'expiration
# =============================================================================

#Requires -RunAsAdministrator

Import-Module ActiveDirectory

$ReportDate   = Get-Date -Format 'yyyy-MM-dd'
$ReportFile   = "C:\KPI\KPI-Securite-$ReportDate.html"
$DomainName   = 'lab.local'
$ExpiryAlertDays = 30

New-Item -ItemType Directory -Path 'C:\KPI' -Force | Out-Null

Write-Host '=== Génération du rapport KPI Sécurité 802.1X ===' -ForegroundColor Cyan

# --- KPI 1 : Machines du domaine ---
$allComputers = Get-ADComputer -Filter * -Properties Name, OperatingSystem, LastLogonDate
$totalComputers = $allComputers.Count

# --- KPI 2 : Certificats machines valides dans l'AD ---
$certStore = Get-ChildItem -Path 'Cert:\LocalMachine\My' -ErrorAction SilentlyContinue
$validCerts = $certStore | Where-Object {
    $_.NotAfter -gt (Get-Date) -and
    $_.EnhancedKeyUsageList.FriendlyName -contains 'Client Authentication'
}
$totalValidCerts = $validCerts.Count

# --- KPI 3 : Certificats proches d'expiration ---
$expiringCerts = $certStore | Where-Object {
    $_.NotAfter -gt (Get-Date) -and
    $_.NotAfter -lt (Get-Date).AddDays($ExpiryAlertDays)
}
$totalExpiringCerts = $expiringCerts.Count

# --- KPI 4 : Taux de couverture certificats ---
$coverageRate = if ($totalComputers -gt 0) {
    [math]::Round(($totalValidCerts / $totalComputers) * 100, 1)
} else { 0 }

# --- KPI 5 : Logs NPS (succès/échecs 802.1X) ---
$npsLogs = Get-WinEvent -LogName 'Security' -ErrorAction SilentlyContinue |
    Where-Object { $_.Id -in @(6272, 6273) } |  # 6272=succès, 6273=échec
    Select-Object -Last 100

$authSuccess = ($npsLogs | Where-Object { $_.Id -eq 6272 }).Count
$authFailure = ($npsLogs | Where-Object { $_.Id -eq 6273 }).Count
$totalAuth   = $authSuccess + $authFailure
$successRate = if ($totalAuth -gt 0) {
    [math]::Round(($authSuccess / $totalAuth) * 100, 1)
} else { 0 }

# --- Génération rapport HTML ---
$html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>KPI Sécurité 802.1X - $ReportDate</title>
    <style>
        body { font-family: Segoe UI, Arial, sans-serif; margin: 30px; background: #f5f5f5; }
        h1   { color: #003366; border-bottom: 3px solid #0078d4; padding-bottom: 10px; }
        h2   { color: #0078d4; margin-top: 30px; }
        .kpi-grid { display: flex; gap: 20px; flex-wrap: wrap; margin: 20px 0; }
        .kpi-card {
            background: white; border-radius: 8px; padding: 20px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.1); min-width: 180px; text-align: center;
        }
        .kpi-value { font-size: 2.5em; font-weight: bold; color: #0078d4; }
        .kpi-label { color: #666; font-size: 0.9em; margin-top: 5px; }
        .kpi-good  { color: #107c10; }
        .kpi-warn  { color: #d83b01; }
        table { width: 100%; border-collapse: collapse; background: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 6px rgba(0,0,0,0.1); }
        th { background: #0078d4; color: white; padding: 10px; text-align: left; }
        td { padding: 8px 10px; border-bottom: 1px solid #eee; }
        tr:hover { background: #f0f7ff; }
        .footer { margin-top: 40px; color: #888; font-size: 0.85em; }
    </style>
</head>
<body>
    <h1>Rapport KPI — Sécurité Réseau 802.1X</h1>
    <p><strong>Date :</strong> $ReportDate &nbsp;|&nbsp; <strong>Domaine :</strong> $DomainName</p>

    <h2>Indicateurs clés</h2>
    <div class="kpi-grid">
        <div class="kpi-card">
            <div class="kpi-value">$totalComputers</div>
            <div class="kpi-label">Machines dans le domaine</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value kpi-good">$totalValidCerts</div>
            <div class="kpi-label">Certificats valides</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value $(if($coverageRate -ge 80){'kpi-good'}else{'kpi-warn'})">$coverageRate %</div>
            <div class="kpi-label">Taux de couverture 802.1X</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value $(if($totalExpiringCerts -eq 0){'kpi-good'}else{'kpi-warn'})">$totalExpiringCerts</div>
            <div class="kpi-label">Certificats expirant dans $ExpiryAlertDays j.</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value kpi-good">$authSuccess</div>
            <div class="kpi-label">Authentifications réussies</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value kpi-warn">$authFailure</div>
            <div class="kpi-label">Authentifications échouées</div>
        </div>
        <div class="kpi-card">
            <div class="kpi-value $(if($successRate -ge 95){'kpi-good'}else{'kpi-warn'})">$successRate %</div>
            <div class="kpi-label">Taux de succès 802.1X</div>
        </div>
    </div>

    <h2>Certificats proches d'expiration</h2>
    $(if ($expiringCerts.Count -eq 0) {
        '<p style="color: #107c10;">Aucun certificat expirant dans les ' + $ExpiryAlertDays + ' prochains jours.</p>'
    } else {
        '<table><tr><th>Sujet</th><th>Expiration</th><th>Jours restants</th></tr>' +
        ($expiringCerts | ForEach-Object {
            $days = [math]::Round(($_.NotAfter - (Get-Date)).TotalDays)
            "<tr><td>$($_.Subject)</td><td>$($_.NotAfter.ToString('dd/MM/yyyy'))</td><td>$days</td></tr>"
        } | Out-String) +
        '</table>'
    })

    <h2>Machines du domaine</h2>
    <table>
        <tr><th>Nom</th><th>Système</th><th>Dernière connexion</th></tr>
        $($allComputers | ForEach-Object {
            "<tr><td>$($_.Name)</td><td>$($_.OperatingSystem)</td><td>$($_.LastLogonDate)</td></tr>"
        } | Out-String)
    </table>

    <div class="footer">
        Généré automatiquement le $ReportDate — BTS SIO — Lab Sécurité 802.1X
    </div>
</body>
</html>
"@

$html | Out-File -FilePath $ReportFile -Encoding UTF8

Write-Host "`n=== RAPPORT KPI GÉNÉRÉ ===" -ForegroundColor Green
Write-Host "Fichier : $ReportFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Machines dans le domaine  : $totalComputers"
Write-Host "  Certificats valides        : $totalValidCerts"
Write-Host "  Taux de couverture 802.1X  : $coverageRate %"
Write-Host "  Authentifications réussies : $authSuccess"
Write-Host "  Authentifications échouées : $authFailure"
Write-Host "  Taux de succès             : $successRate %"
Write-Host ""

# Ouvrir le rapport dans le navigateur
Start-Process $ReportFile
