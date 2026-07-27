#!/usr/bin/env bash
#
# generate-env.sh – Erzeugt die .env für Leantime hinter dem
# secure-docker-app-Network-Gateway.
#
# Das Skript fragt alle notwendigen Werte ab, generiert fehlende Secrets
# und schreibt die .env-Datei.
#
# Ausführen: bash generate-env.sh
#

set -euo pipefail

# --- Farben für Ausgaben ----------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()  { echo -e "${CYAN}[INFO]${NC}  $1"; }
ok()    { echo -e "${GREEN}[OK]${NC}    $1"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err()   { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Prüfen, ob openssl verfügbar ist ---------------------------------------
if ! command -v openssl &>/dev/null; then
  err "openssl ist nicht installiert. Bitte installieren: sudo apt install openssl"
  exit 1
fi

# --- Prüfen, ob .env bereits existiert --------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"

if [[ -f "$ENV_FILE" ]]; then
  echo ""
  warn "Es existiert bereits eine .env-Datei in ${SCRIPT_DIR}"
  read -rp "Möchtest du sie überschreiben? (yes/no): " OVERWRITE
  if [[ "$OVERWRITE" != "yes" ]]; then
    echo "Abgebrochen."
    exit 1
  fi
fi

echo ""
echo "=== Leantime .env Generator ==="
echo ""

# --- 1. Hostname abfragen ---------------------------------------------------
while true; do
  read -rp "Öffentlicher Hostname (z. B. leantime.deinedomain.de): " HOSTNAME
  if [[ -z "$HOSTNAME" ]]; then
    err "Hostname darf nicht leer sein."
  else
    break
  fi
done

# --- 2. Proxy-Netzwerk abfragen ---------------------------------------------
read -rp "Docker-Proxy-Netzwerk (Default: proxy_net): " PROXY_NETWORK
PROXY_NETWORK="${PROXY_NETWORK:-proxy_net}"

# --- 3. Site-Name abfragen --------------------------------------------------
read -rp "Site-Name (Default: Leantime): " SITENAME
SITENAME="${SITENAME:-Leantime}"

# --- 4. Sprache abfragen ----------------------------------------------------
read -rp "Sprache (Default: en-US): " LANGUAGE
LANGUAGE="${LANGUAGE:-en-US}"

# --- 5. Zeitzone abfragen ---------------------------------------------------
read -rp "Zeitzone (Default: Europe/Berlin): " TIMEZONE
TIMEZONE="${TIMEZONE:-Europe/Berlin}"

# --- 5b. Trusted-Proxies abfragen -------------------------------------------
read -rp "Trusted-Proxies CIDR (Default: 172.16.0.0/12): " TRUSTED_PROXIES
TRUSTED_PROXIES="${TRUSTED_PROXIES:-172.16.0.0/12}"

# --- 6. Datenbank-Passwörter ------------------------------------------------
echo ""
echo "=== Datenbank ==="
read -rp "Leantime DB-Passwort – leer lassen für Zufallswert: " DB_PASS_INPUT
if [[ -z "$DB_PASS_INPUT" ]]; then
  DB_PASS=$(openssl rand -hex 24)
  ok "Leantime DB-Passwort generiert."
else
  DB_PASS="$DB_PASS_INPUT"
fi

read -rp "MySQL Root-Passwort – leer lassen für Zufallswert: " ROOT_PASS_INPUT
if [[ -z "$ROOT_PASS_INPUT" ]]; then
  ROOT_PASS=$(openssl rand -hex 24)
  ok "MySQL Root-Passwort generiert."
else
  ROOT_PASS="$ROOT_PASS_INPUT"
fi

# --- 7. Session-Password ----------------------------------------------------
echo ""
echo "=== Session-Password ==="
echo "WICHTIG: Diesen Wert sicher aufbewahren! Bei Verlust sind bestehende"
echo "Sessions ungültig."
read -rp "LEAN_SESSION_PASSWORD – leer lassen für Zufallswert (openssl rand -hex 32): " SESSION_INPUT
if [[ -z "$SESSION_INPUT" ]]; then
  SESSION_PASS=$(openssl rand -hex 32)
  ok "LEAN_SESSION_PASSWORD generiert."
else
  SESSION_PASS="$SESSION_INPUT"
fi

# --- 8. E-Mail-Konfiguration (optional) -------------------------------------
echo ""
echo "=== E-Mail-Konfiguration (optional) ==="
read -rp "Möchtest du SMTP konfigurieren? (yes/no, Default: no): " SETUP_MAIL
SMTP_VARS=""
if [[ "$SETUP_MAIL" == "yes" ]]; then
  read -rp "  Absender-E-Mail-Adresse: " EMAIL_RETURN
  read -rp "  SMTP-Server (z. B. smtp.example.com): " SMTP_HOSTS
  read -rp "  SMTP-Port (Default: 587): " SMTP_PORT
  SMTP_PORT="${SMTP_PORT:-587}"
  read -rp "  SMTP-Benutzername: " SMTP_USER
  read -rsp "  SMTP-Passwort: " SMTP_PASS
  echo ""
  read -rp "  SMTP-Security (TLS/SSL/STARTTLS, Default: TLS): " SMTP_SECURE
  SMTP_SECURE="${SMTP_SECURE:-TLS}"
  SMTP_VARS=$(cat <<EOF

# SMTP
LEAN_EMAIL_RETURN=${EMAIL_RETURN}
LEAN_EMAIL_USE_SMTP=true
LEAN_EMAIL_SMTP_HOSTS=${SMTP_HOSTS}
LEAN_EMAIL_SMTP_USERNAME=${SMTP_USER}
LEAN_EMAIL_SMTP_PASSWORD=${SMTP_PASS}
LEAN_EMAIL_SMTP_PORT=${SMTP_PORT}
LEAN_EMAIL_SMTP_SECURE=${SMTP_SECURE}
EOF
)
  ok "SMTP-Konfiguration übernommen."
fi

# --- .env schreiben ---------------------------------------------------------
echo ""
info "Schreibe .env …"

cat > "$ENV_FILE" <<ENVEOF
##
# Leantime – Umgebungsvariablen
# Generiert am $(date) durch generate-env.sh
##

# Image-Tag
TAG=3.4.12

# MySQL-Version
MYSQL_VERSION=8.4

# Öffentlicher Hostname
APP_HOST=${HOSTNAME}

# Proxy-Netzwerk
PROXY_NETWORK=${PROXY_NETWORK}

# Datenbank
LEAN_DB_DATABASE=leantime
LEAN_DB_USER=leantime
LEAN_DB_PASSWORD=${DB_PASS}
MYSQL_ROOT_PASSWORD=${ROOT_PASS}

# Session
LEAN_SESSION_PASSWORD=${SESSION_PASS}

# HTTPS / Reverse-Proxy
LEAN_APP_URL=https://${HOSTNAME}
LEAN_SESSION_SECURE=true
LEAN_HSTS_ENABLED=true
LEAN_TRUSTED_PROXIES=${TRUSTED_PROXIES}

# App-Konfiguration
LEAN_SITENAME=${SITENAME}
LEAN_LANGUAGE=${LANGUAGE}
LEAN_DEFAULT_TIMEZONE=${TIMEZONE}
LEAN_DEBUG=0
ENVEOF

# SMTP (nur wenn konfiguriert)
if [[ -n "$SMTP_VARS" ]]; then
  echo "$SMTP_VARS" >> "$ENV_FILE"
fi

ok ".env wurde erstellt: ${ENV_FILE}"

# --- Zusammenfassung --------------------------------------------------------
echo ""
echo "========================================"
echo -e "${GREEN}  .env erfolgreich generiert!${NC}"
echo "========================================"
echo ""
echo "  Hostname:              ${HOSTNAME}"
echo "  Proxy-Netzwerk:        ${PROXY_NETWORK}"
echo "  Site-Name:             ${SITENAME}"
echo "  Sprache:               ${LANGUAGE}"
echo "  Zeitzone:              ${TIMEZONE}"
echo "  DB-Passwort:           ${DB_PASS}"
echo "  Root-Passwort:         ${ROOT_PASS}"
echo "  Session-Password:      ${SESSION_PASS:0:16}… (gekürzt)"
echo ""
echo "Nächste Schritte:"
echo "  1. docker compose up -d"
echo "  2. App im Gateway registrieren:"
echo "     gatectl add leantime \"Leantime\" ${HOSTNAME} http://leantime:8080"
echo "     gatectl apply"
echo "  3. Web-UI öffnen: https://${HOSTNAME}"
echo ""