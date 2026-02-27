# Lab Sécurité 802.1X — BTS SIO

Projet de laboratoire pour la mise en place d'une infrastructure PKI et d'une authentification réseau par certificats (802.1X) sur WiFi et Ethernet.

## Objectif

Améliorer la sécurité réseau de l'entreprise en remplaçant l'authentification par mot de passe par une authentification par **certificats numériques** via le protocole **802.1X / EAP-TLS**.

## Architecture du lab

```
[Client Win10/11]
      |
      | 802.1X (EAP-TLS)
      |
[Switch/AP] ---- RADIUS ----> [NPS01 - Serveur NPS/RADIUS]
                                      |
                              vérifie le certificat
                                      |
                              [SubCA01 - CA Subordonnée]
                                      |
                              [RootCA01 - CA Racine]
                                      |
                              [DC01 - Active Directory]
```

## Machines Virtuelles (VMware)

| VM       | Rôle                          | OS                    | RAM  | IP             |
|----------|-------------------------------|-----------------------|------|----------------|
| DC01     | Contrôleur de domaine + DNS   | Windows Server 2022   | 2 GB | 192.168.10.10  |
| RootCA01 | Autorité de certification racine (Standalone) | Windows Server 2022 | 1 GB | 192.168.10.20 |
| SubCA01  | CA Subordonnée + NPS/RADIUS   | Windows Server 2022   | 2 GB | 192.168.10.30  |
| Client01 | Poste client test             | Windows 11            | 2 GB | DHCP           |

## Ordre d'exécution des scripts

```
01-Install-AD.ps1          → Sur DC01
02-Install-PKI-RootCA.ps1  → Sur RootCA01
03-Install-PKI-SubCA.ps1   → Sur SubCA01
04-Configure-Templates.ps1 → Sur SubCA01
05-Install-NPS.ps1         → Sur SubCA01
06-Configure-8021x.ps1     → Sur SubCA01
07-Configure-GPO.ps1       → Sur DC01
kpi/Get-SecurityKPI.ps1    → Sur DC01 (rapport KPI)
```

## Domaine du lab

- Domaine : `lab.local`
- Admin : `Administrator`

## Références

- [AutomatedLab](https://github.com/AutomatedLab/AutomatedLab)
- [Microsoft - Deploy Server Certificates for 802.1X](https://learn.microsoft.com/en-us/windows-server/networking/core-network-guide/cncg/server-certs/deploy-server-certificates-for-802.1x-wired-and-wireless-deployments)
- [Microsoft - NPS Network Policy Server](https://learn.microsoft.com/en-us/windows-server/networking/technologies/nps/nps-top)
