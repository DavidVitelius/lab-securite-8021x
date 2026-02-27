# Architecture — Lab Sécurité 802.1X

## Schéma réseau

```
                        DOMAINE : lab.local
                        Réseau  : 192.168.10.0/24
    ┌──────────────────────────────────────────────────────┐
    │                                                      │
    │   [DC01]               [RootCA01]      [SubCA01]    │
    │   192.168.10.10        192.168.10.20   192.168.10.30│
    │   - Active Directory   - CA Racine     - CA Subord. │
    │   - DNS                  Standalone      Enterprise  │
    │   - DHCP               - Hors ligne    - NPS/RADIUS │
    │   - GPO                  après sign.   - Web Enroll │
    │                                                      │
    └──────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴──────────┐
                    │                    │
              [Switch 802.1X]      [AP WiFi 802.1X]
              192.168.10.1         192.168.10.2
                    │                    │
              ┌─────┘              ┌─────┘
              │                    │
         [Client01]           [Client02]
         Ethernet              WiFi
         Certificat Auto       Certificat Auto
         (EAP-TLS)             (EAP-TLS)
```

## Flux d'authentification 802.1X

```
Client          Switch/AP           NPS (RADIUS)        Active Directory
  │                 │                    │                     │
  │── EAPOL Start ──►                   │                     │
  │                 │── RADIUS Access ──►                     │
  │                 │   Request          │                     │
  │◄─── EAP Req ────│◄── EAP Request ───│                     │
  │                 │                    │                     │
  │── EAP Resp ────►│─── RADIUS ────────►                     │
  │  (Certificat)   │   Access Req       │── Vérifie cert ────►
  │                 │                    │◄─ Compte valide ────│
  │                 │◄── RADIUS ─────────│                     │
  │                 │   Access Accept    │                     │
  │◄── EAP Success ─│                    │                     │
  │                 │                    │                     │
  │    ACCÈS        │                    │                     │
  │    RÉSEAU OK    │                    │                     │
```

## Hiérarchie PKI (Two-Tier)

```
RootCA01 (Standalone - Hors ligne)
│   Durée : 10 ans
│   Clé   : RSA 4096 bits
│
└── SubCA01 (Enterprise - Domain Joined)
        Durée : 5 ans
        Clé   : RSA 2048 bits
        │
        ├── Certificats Serveur NPS
        ├── Certificats Ordinateurs (auto-enrollment GPO)
        └── Certificats Utilisateurs (auto-enrollment GPO)
```

## Composants Windows Server utilisés

| Composant | Rôle | Machine |
|-----------|------|---------|
| AD DS | Active Directory Domain Services | DC01 |
| AD CS - Root CA | Autorité de certification racine | RootCA01 |
| AD CS - Sub CA | Autorité de certification subordonnée | SubCA01 |
| AD CS - Web Enrollment | Inscription web aux certificats | SubCA01 |
| NPS | Network Policy Server (RADIUS) | SubCA01 |
| DNS | Résolution de noms | DC01 |
| DHCP | Attribution d'adresses IP | DC01 |
| Group Policy | GPO autoenrollment certificats | DC01 |

## KPI mesurés

| KPI | Objectif | Description |
|-----|----------|-------------|
| Taux couverture certificats | ≥ 95% | % machines avec certificat valide |
| Taux succès 802.1X | ≥ 99% | % connexions authentifiées avec succès |
| Certificats expirants | 0 | Certificats expirant dans les 30 jours |
| Temps déploiement cert | < 24h | Délai d'auto-enrollment après rejoindre le domaine |
