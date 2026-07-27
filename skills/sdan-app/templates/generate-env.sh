#!/usr/bin/env bash
#
# generate-env.sh – Erzeugt die .env für <APP_NAME> hinter dem
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
echo "=== <APP_NAME> .env Generator ==="
echo ""

# --- 1. Hostname abfragen ---------------------------------------------------
while true; do
  read -rp "Öffentlicher Hostname (z. B. <APP_NAME>.deinedomain.de): " HOSTNAME
  if [[ -z "$HOSTNAME" ]]; then
    err "Hostname darf nicht leer sein."
  else
    break
  fi
done

# --- 2. Proxy-Netzwerk abfragen ---------------------------------------------
read -rp "Docker-Proxy-Netzwerk (Default: proxy_net): " PROXY_NETWORK
PROXY_NETWORK="${PROXY_NETWORK:-proxy_net}"

# --- 3. Secret Key Base -----------------------------------------------------
echo ""
echo "=== Secret Key Base ==="
echo "WICHTIG: Diesen Wert sicher aufbewahren! Bei Verlust sind Sessions"
echo "und verschlüsselte Datenbankinhalte unlesbar."
read -rp "SECRET_KEY_BASE – leer lassen für Zufallswert (openssl rand -hex 64): " SKB_INPUT
if [[ -z "$SKB_INPUT" ]]; then
  SECRET_KEY_BASE=$(openssl rand -hex 64)
  ok "SECRET_KEY_BASE generiert."
else
  SECRET_KEY_BASE="$SKB_INPUT"
fi

# --- 4. Postgres-Passwort (falls Datenbank genutzt) -------------------------
echo ""
echo "=== Postgres-Datenbank ==="
read -rp "Postgres-Passwort – leer lassen für Zufallswert: " PG_PASS_INPUT
if [[ -z "$PG_PASS_INPUT" ]]; then
  PG_PASS=$(openssl rand -hex 24)
  ok "Postgres-Passwort generiert."
else
  PG_PASS="$PG_PASS_INPUT"
fi

# --- .env schreiben ---------------------------------------------------------
echo ""
info "Schreibe .env …"

cat > "$ENV_FILE" <<ENVEOF
##
# <APP_NAME> – Umgebungsvariablen
# Generiert am $(date) durch generate-env.sh
##

# Image-Tag
TAG=latest

# Öffentlicher Hostname
APP_HOST=${HOSTNAME}

# Proxy-Netzwerk
PROXY_NETWORK=${PROXY_NETWORK}

# Secret Key Base
SECRET_KEY_BASE=${SECRET_KEY_BASE}

# Postgres
POSTGRES_VERSION=17
POSTGRES_PASSWORD=${PG_PASS}
ENVEOF

ok ".env wurde erstellt: ${ENV_FILE}"

# --- Zusammenfassung --------------------------------------------------------
echo ""
echo "========================================"
echo -e "${GREEN}  .env erfolgreich generiert!${NC}"
echo "========================================"
echo ""
echo "  Hostname:              ${HOSTNAME}"
echo "  Proxy-Netzwerk:        ${PROXY_NETWORK}"
echo "  Postgres-Passwort:     ${PG_PASS}"
echo "  SECRET_KEY_BASE:       ${SECRET_KEY_BASE:0:16}… (gekürzt)"
echo ""
echo "Nächste Schritte:"
echo "  1. docker compose up -d"
echo "  2. App im Gateway registrieren:"
echo "     gatectl add <APP_NAME> \"<APP_NAME>\" ${HOSTNAME} http://<APP_NAME>:<APP_PORT>"
echo "     gatectl apply"
echo ""