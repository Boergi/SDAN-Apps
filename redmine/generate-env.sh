#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
ok() { echo -e "${GREEN}[OK]${NC}    $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

if ! command -v openssl &>/dev/null; then err "openssl ist nicht installiert."; exit 1; fi
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
  warn "Es existiert bereits eine .env-Datei."
  read -rp "Möchtest du sie überschreiben? (yes/no): " overwrite
  [[ "$overwrite" == "yes" ]] || { echo "Abgebrochen."; exit 1; }
fi

echo "=== Redmine 7 .env Generator ==="
while true; do
  read -rp "Öffentlicher Hostname (z. B. redmine.deinedomain.de): " REDMINE_HOST
  [[ -n "$REDMINE_HOST" ]] && break
  err "Hostname darf nicht leer sein."
done
read -rp "Docker-Proxy-Netzwerk (Default: proxy_net): " PROXY_NETWORK
PROXY_NETWORK="${PROXY_NETWORK:-proxy_net}"
read -rp "Postgres-Passwort – leer lassen für Zufallswert: " PG_PASS_INPUT
POSTGRES_PASSWORD="${PG_PASS_INPUT:-$(openssl rand -hex 24)}"
read -rp "REDMINE_SECRET_KEY_BASE – leer lassen für Zufallswert: " SECRET_INPUT
REDMINE_SECRET_KEY_BASE="${SECRET_INPUT:-$(openssl rand -hex 64)}"

cat > "$ENV_FILE" <<ENVEOF
## Redmine 7 – generiert am $(date)
TAG=7.0.0-alpine3.24
POSTGRES_VERSION=17
REDMINE_HOST=${REDMINE_HOST}
REDMINE_SECRET_KEY_BASE=${REDMINE_SECRET_KEY_BASE}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
REDMINE_RELATIVE_URL_ROOT=
PROXY_NETWORK=${PROXY_NETWORK}
ENVEOF

ok ".env wurde erstellt: ${ENV_FILE}"
echo "Nächste Schritte:"
echo "  1. docker compose up -d"
echo "  2. gatectl add redmine \"Redmine 7\" ${REDMINE_HOST} http://redmine:3000"
echo "  3. gatectl apply"
echo "  Secret Key Base: ${REDMINE_SECRET_KEY_BASE:0:16}… (gekürzt)"
