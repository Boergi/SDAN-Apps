#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
ok() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

command -v openssl &>/dev/null || { err "openssl ist nicht installiert."; exit 1; }
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ENV_FILE="${SCRIPT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
  warn "Es existiert bereits eine .env-Datei."
  read -rp "Möchtest du sie überschreiben? (yes/no): " overwrite
  [[ "$overwrite" == yes ]] || { echo "Abgebrochen."; exit 1; }
fi

echo "=== Taiga 6.9.0 .env Generator ==="
while true; do
  read -rp "Öffentlicher Taiga-Hostname (z. B. taiga.example.com): " TAIGA_DOMAIN
  [[ -n "$TAIGA_DOMAIN" ]] && break
  err "Hostname darf nicht leer sein."
done
read -rp "Proxy-Netzwerk (Default: proxy_net): " PROXY_NETWORK; PROXY_NETWORK="${PROXY_NETWORK:-proxy_net}"
read -rp "Postgres-Passwort – leer lassen für Zufallswert: " PG_INPUT
POSTGRES_PASSWORD="${PG_INPUT:-$(openssl rand -hex 24)}"
read -rp "RabbitMQ-Passwort – leer lassen für Zufallswert: " RMQ_INPUT
RABBITMQ_PASS="${RMQ_INPUT:-$(openssl rand -hex 24)}"
read -rp "RabbitMQ Erlang Cookie – leer lassen für Zufallswert: " COOKIE_INPUT
RABBITMQ_ERLANG_COOKIE="${COOKIE_INPUT:-$(openssl rand -hex 32)}"
read -rp "Taiga Secret Key – leer lassen für Zufallswert: " SECRET_INPUT
SECRET_KEY="${SECRET_INPUT:-$(openssl rand -hex 64)}"
read -rp "SMTP konfigurieren? (yes/no, Default: no): " SMTP_CHOICE

EMAIL_BACKEND=console; EMAIL_HOST=smtp.example.com; EMAIL_PORT=587; EMAIL_HOST_USER=; EMAIL_HOST_PASSWORD=OVERWRITE_ME; EMAIL_DEFAULT_FROM="taiga@${TAIGA_DOMAIN}"; EMAIL_USE_TLS=True; EMAIL_USE_SSL=False
if [[ "$SMTP_CHOICE" == yes ]]; then
  EMAIL_BACKEND=smtp
  read -rp "SMTP-Host: " EMAIL_HOST
  read -rp "SMTP-Port (Default: 587): " EMAIL_PORT; EMAIL_PORT="${EMAIL_PORT:-587}"
  read -rp "SMTP-Benutzer: " EMAIL_HOST_USER
  read -rsp "SMTP-Passwort: " EMAIL_HOST_PASSWORD; echo
  read -rp "Absender (Default: taiga@${TAIGA_DOMAIN}): " EMAIL_DEFAULT_FROM; EMAIL_DEFAULT_FROM="${EMAIL_DEFAULT_FROM:-taiga@${TAIGA_DOMAIN}}"
fi

cat > "$ENV_FILE" <<ENVEOF
## Taiga 6.9.0 – generiert am $(date)
TAG=6.9.0
POSTGRES_VERSION=12.3
PROXY_NETWORK=${PROXY_NETWORK}
TAIGA_SCHEME=https
TAIGA_DOMAIN=${TAIGA_DOMAIN}
SUBPATH=
WEBSOCKETS_SCHEME=wss
SECRET_KEY=${SECRET_KEY}
POSTGRES_USER=taiga
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
RABBITMQ_USER=taiga
RABBITMQ_PASS=${RABBITMQ_PASS}
RABBITMQ_VHOST=taiga
RABBITMQ_ERLANG_COOKIE=${RABBITMQ_ERLANG_COOKIE}
EMAIL_BACKEND=${EMAIL_BACKEND}
EMAIL_HOST=${EMAIL_HOST}
EMAIL_PORT=${EMAIL_PORT}
EMAIL_HOST_USER=${EMAIL_HOST_USER}
EMAIL_HOST_PASSWORD=${EMAIL_HOST_PASSWORD}
EMAIL_DEFAULT_FROM=${EMAIL_DEFAULT_FROM}
EMAIL_USE_TLS=${EMAIL_USE_TLS}
EMAIL_USE_SSL=${EMAIL_USE_SSL}
ENABLE_TELEMETRY=False
ATTACHMENTS_MAX_AGE=360
PUBLIC_REGISTER_ENABLED=False
PUBLIC_REGISTER_ENABLED_FRONT=false
ENVEOF

ok ".env wurde erstellt: ${ENV_FILE}"
echo "Nächste Schritte:"
echo "  1. docker-compose up -d"
echo "  2. docker-compose exec taiga-back python manage.py createsuperuser"
echo "  3. gatectl add taiga \"Taiga\" ${TAIGA_DOMAIN} http://taiga:80"
echo "  4. gatectl apply"
echo "  Secret Key: ${SECRET_KEY:0:16}… (gekürzt)"
