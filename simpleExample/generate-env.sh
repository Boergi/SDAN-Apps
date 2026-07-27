#!/usr/bin/env bash
#
# generate-env.sh – Erzeugt die .env für simpleExample hinter dem
# secure-docker-app-Network-Gateway.
#
# Das Skript fragt alle notwendigen Werte ab und schreibt die .env-Datei.
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
echo "=== simpleExample .env Generator ==="
echo ""

# --- 1. Hostname abfragen ---------------------------------------------------
while true; do
  read -rp "Öffentlicher Hostname (z. B. simpleexample.deinedomain.de): " HOSTNAME
  if [[ -z "$HOSTNAME" ]]; then
    err "Hostname darf nicht leer sein."
  else
    break
  fi
done

# --- 2. Proxy-Netzwerk abfragen ---------------------------------------------
read -rp "Docker-Proxy-Netzwerk (Default: proxy_net): " PROXY_NETWORK
PROXY_NETWORK="${PROXY_NETWORK:-proxy_net}"

# --- .env schreiben ---------------------------------------------------------
echo ""
info "Schreibe .env …"

cat > "$ENV_FILE" <<ENVEOF
##
# simpleExample – Umgebungsvariablen
# Generiert am $(date) durch generate-env.sh
##

# Öffentlicher Hostname
APP_HOST=${HOSTNAME}

# Proxy-Netzwerk
PROXY_NETWORK=${PROXY_NETWORK}
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
echo ""
echo "Nächste Schritte:"
echo "  1. docker compose up -d"
echo "  2. App im Gateway registrieren:"
echo "     gatectl add simpleexample \"simpleExample\" ${HOSTNAME} http://simpleExample-app:80"
echo "     gatectl apply"
echo "  3. Seite öffnen: https://${HOSTNAME}"
echo ""