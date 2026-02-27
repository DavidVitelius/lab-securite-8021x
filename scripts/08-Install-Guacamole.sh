#!/bin/bash
# =============================================================================
# Script 08 - Installation Apache Guacamole (accès web sécurisé aux VMs)
# Machine cible : Gateway01 (Ubuntu Server 22.04)
# Auteur        : BTS SIO - Lab Sécurité 802.1X
# =============================================================================
# Installe :
#   - Guacamole Server (guacd) + Client Web
#   - Apache2 avec proxy HTTPS
#   - Certificat SSL auto-signé
#   - Connexions RDP préconfigurées pour DC01, RootCA01, SubCA01, Client01
# =============================================================================

set -e

GUAC_VERSION="1.5.4"
GUAC_PASS="Admin@Guac2024!"      # Mot de passe admin Guacamole
DC01_IP="192.168.10.10"
ROOTCA_IP="192.168.10.20"
SUBCA_IP="192.168.10.30"
CLIENT_IP="192.168.10.100"       # À adapter (DHCP)
DOMAIN_USER="LAB\\Administrator"
DOMAIN_PASS="P@ssword123!"

echo "================================================="
echo " [08] Installation Apache Guacamole"
echo "================================================="

# --- Mise à jour système ---
echo "[08] Mise à jour du système..."
apt-get update -qq && apt-get upgrade -y -qq

# --- Dépendances ---
echo "[08] Installation des dépendances..."
apt-get install -y -qq \
  build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev libtool-bin \
  libossp-uuid-dev libavcodec-dev libavformat-dev libavutil-dev libswscale-dev \
  libpango1.0-dev libssh2-1-dev libvncserver-dev libtelnet-dev libssl-dev \
  libvorbis-dev libwebp-dev libfreerdp2-dev freerdp2-x11 \
  tomcat9 tomcat9-admin tomcat9-common \
  apache2 libapache2-mod-proxy-html \
  openssl wget curl

# --- Téléchargement sources Guacamole ---
echo "[08] Téléchargement de Guacamole ${GUAC_VERSION}..."
cd /tmp
wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/source/guacamole-server-${GUAC_VERSION}.tar.gz"
wget -q "https://dlcdn.apache.org/guacamole/${GUAC_VERSION}/binary/guacamole-${GUAC_VERSION}.war"

# --- Compilation guacd ---
echo "[08] Compilation de guacd..."
tar -xzf "guacamole-server-${GUAC_VERSION}.tar.gz"
cd "guacamole-server-${GUAC_VERSION}"
./configure --with-init-dir=/etc/init.d > /dev/null 2>&1
make -j$(nproc) > /dev/null 2>&1
make install > /dev/null 2>&1
ldconfig
systemctl enable guacd
systemctl start guacd

# --- Déploiement client web ---
echo "[08] Déploiement du client web Guacamole..."
mkdir -p /etc/guacamole/{extensions,lib}
cp /tmp/guacamole-${GUAC_VERSION}.war /var/lib/tomcat9/webapps/guacamole.war

# --- Configuration Guacamole ---
echo "[08] Configuration de Guacamole..."
cat > /etc/guacamole/guacamole.properties << EOF
guacd-hostname: localhost
guacd-port:     4822
auth-provider:  net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider
basic-user-mapping: /etc/guacamole/user-mapping.xml
EOF

# --- Mapping utilisateurs et connexions VMs ---
PASS_HASH=$(echo -n "$GUAC_PASS" | md5sum | cut -d' ' -f1)

cat > /etc/guacamole/user-mapping.xml << EOF
<user-mapping>

    <authorize username="guacadmin" password="${PASS_HASH}" encoding="md5">

        <!-- DC01 — Contrôleur de domaine -->
        <connection name="DC01 — Contrôleur de domaine">
            <protocol>rdp</protocol>
            <param name="hostname">${DC01_IP}</param>
            <param name="port">3389</param>
            <param name="username">${DOMAIN_USER}</param>
            <param name="password">${DOMAIN_PASS}</param>
            <param name="domain">LAB</param>
            <param name="security">nla</param>
            <param name="ignore-cert">true</param>
            <param name="color-depth">16</param>
            <param name="width">1280</param>
            <param name="height">720</param>
        </connection>

        <!-- RootCA01 — Autorité de certification racine -->
        <connection name="RootCA01 — CA Racine">
            <protocol>rdp</protocol>
            <param name="hostname">${ROOTCA_IP}</param>
            <param name="port">3389</param>
            <param name="username">Administrator</param>
            <param name="password">${DOMAIN_PASS}</param>
            <param name="security">rdp</param>
            <param name="ignore-cert">true</param>
            <param name="color-depth">16</param>
            <param name="width">1280</param>
            <param name="height">720</param>
        </connection>

        <!-- SubCA01 — CA Subordonnée + NPS -->
        <connection name="SubCA01 — CA Subordonnée + NPS">
            <protocol>rdp</protocol>
            <param name="hostname">${SUBCA_IP}</param>
            <param name="port">3389</param>
            <param name="username">${DOMAIN_USER}</param>
            <param name="password">${DOMAIN_PASS}</param>
            <param name="domain">LAB</param>
            <param name="security">nla</param>
            <param name="ignore-cert">true</param>
            <param name="color-depth">16</param>
            <param name="width">1280</param>
            <param name="height">720</param>
        </connection>

        <!-- Client01 — Poste client 802.1X -->
        <connection name="Client01 — Poste client 802.1X">
            <protocol>rdp</protocol>
            <param name="hostname">${CLIENT_IP}</param>
            <param name="port">3389</param>
            <param name="username">${DOMAIN_USER}</param>
            <param name="password">${DOMAIN_PASS}</param>
            <param name="domain">LAB</param>
            <param name="security">nla</param>
            <param name="ignore-cert">true</param>
            <param name="color-depth">16</param>
            <param name="width">1280</param>
            <param name="height">720</param>
        </connection>

    </authorize>

</user-mapping>
EOF

# Lien symlink pour Tomcat
ln -sf /etc/guacamole /usr/share/tomcat9/.guacamole

# --- Certificat SSL auto-signé ---
echo "[08] Génération du certificat SSL..."
mkdir -p /etc/ssl/guacamole
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout /etc/ssl/guacamole/guac.key \
  -out    /etc/ssl/guacamole/guac.crt \
  -subj "/C=GP/ST=Guadeloupe/L=Pointe-a-Pitre/O=Digicel Caribbean/CN=guacamole.lab.local" \
  2>/dev/null

# --- Configuration Apache2 (proxy HTTPS vers Tomcat) ---
echo "[08] Configuration Apache2..."
a2enmod ssl proxy proxy_http proxy_wstunnel headers rewrite

cat > /etc/apache2/sites-available/guacamole.conf << 'EOF'
<VirtualHost *:443>
    ServerName guacamole.lab.local

    SSLEngine on
    SSLCertificateFile    /etc/ssl/guacamole/guac.crt
    SSLCertificateKeyFile /etc/ssl/guacamole/guac.key

    # En-têtes sécurité
    Header always set Strict-Transport-Security "max-age=63072000"
    Header always set X-Frame-Options DENY
    Header always set X-Content-Type-Options nosniff

    # Proxy vers Tomcat / Guacamole
    ProxyPass        /guacamole  http://localhost:8080/guacamole
    ProxyPassReverse /guacamole  http://localhost:8080/guacamole

    # WebSocket (nécessaire pour Guacamole)
    RewriteEngine On
    RewriteCond %{HTTP:Upgrade} websocket [NC]
    RewriteRule /guacamole/(.*) ws://localhost:8080/guacamole/$1 [P,L]

    LogLevel warn
    ErrorLog  ${APACHE_LOG_DIR}/guacamole_error.log
    CustomLog ${APACHE_LOG_DIR}/guacamole_access.log combined
</VirtualHost>

# Redirection HTTP → HTTPS
<VirtualHost *:80>
    RewriteEngine On
    RewriteRule ^(.*)$ https://%{HTTP_HOST}$1 [R=301,L]
</VirtualHost>
EOF

a2ensite guacamole.conf
a2dissite 000-default.conf

# --- Redémarrage des services ---
echo "[08] Redémarrage des services..."
systemctl restart tomcat9
systemctl restart apache2
systemctl restart guacd

echo ""
echo "================================================="
echo " [08] Guacamole installé avec succès !"
echo "================================================="
echo ""
echo " Portail : https://$(hostname -I | awk '{print $1}')/guacamole"
echo " Login   : guacadmin"
echo " MDP     : ${GUAC_PASS}"
echo ""
echo " ⚠️  CHANGER LE MOT DE PASSE À LA PREMIÈRE CONNEXION"
echo "================================================="
