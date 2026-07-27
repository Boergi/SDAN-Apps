#!/usr/bin/env bash
#
# generate-env.sh – Erzeugt die .env für Bifrost hinter dem
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
echo "=== Bifrost .env Generator ==="
echo ""

# --- 1. Hostname abfragen ---------------------------------------------------
while true; do
  read -rp "Öffentlicher Hostname (z. B. bifrost.deinedomain.de): " HOSTNAME
  if [[ -z "$HOSTNAME" ]]; then
    err "Hostname darf nicht leer sein."
  else
    break
  fi
done

# --- 2. Proxy-Netzwerk abfragen ---------------------------------------------
read -rp "Docker-Proxy-Netzwerk (Default: proxy_net): " PROXY_NETWORK
PROXY_NETWORK="${PROXY_NETWORK:-proxy_net}"

# --- 3. Log-Level abfragen --------------------------------------------------
read -rp "Log-Level (debug/info/warn/error, Default: info): " LOG_LEVEL
LOG_LEVEL="${LOG_LEVEL:-info}"

# --- 4. Log-Style abfragen --------------------------------------------------
read -rp "Log-Style (json/pretty, Default: json): " LOG_STYLE
LOG_STYLE="${LOG_STYLE:-json}"

# --- 5. API-Keys (optional) -------------------------------------------------
echo ""
echo "=== API-Keys (optional) ==="
echo "Diese Keys werden als Umgebungsvariablen gesetzt, damit sie in der"
echo "config.json per env.REFERENZ genutzt werden können."
read -rp "OpenAI API Key – leer lassen zum Überspringen: " OPENAI_KEY
read -rp "Anthropic API Key – leer lassen zum Überspringen: " ANTHROPIC_KEY

# --- .env schreiben ---------------------------------------------------------
echo ""
info "Schreibe .env …"

cat > "$ENV_FILE" <<ENVEOF
##
# Bifrost – Umgebungsvariablen
# Generiert am $(date) durch generate-env.sh
##

# Image-Tag
TAG=latest

# Öffentlicher Hostname
APP_HOST=${HOSTNAME}

# Proxy-Netzwerk
PROXY_NETWORK=${PROXY_NETWORK}

# Logging
LOG_LEVEL=${LOG_LEVEL}
LOG_STYLE=${LOG_STYLE}

# Daten-Volume-Name
BIFROST_DATA=bifrost_data
ENVEOF

# API-Keys (nur wenn gesetzt)
if [[ -n "$OPENAI_KEY" ]]; then
  cat >> "$ENV_FILE" <<ENVEOF

# OpenAI
OPENAI_API_KEY=${OPENAI_KEY}
ENVEOF
fi

if [[ -n "$ANTHROPIC_KEY" ]]; then
  cat >> "$ENV_FILE" <<ENVEOF

# Anthropic
ANTHROPIC_API_KEY=${ANTHROPIC_KEY}
ENVEOF
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
echo "  Log-Level:             ${LOG_LEVEL}"
echo "  Log-Style:             ${LOG_STYLE}"
echo "  OpenAI Key gesetzt:    $([[ -n "$OPENAI_KEY" ]] && echo "ja" || echo "nein")"
echo "  Anthropic Key gesetzt: $([[ -n "$ANTHROPIC_KEY" ]] && echo "ja" || echo "nein")"
echo ""
echo "Nächste Schritte:"
echo "  1. docker compose up -d"
echo "  2. App im Gateway registrieren:"
echo "     gatectl add bifrost \"Bifrost\" ${HOSTNAME} http://bifrost:8080"
echo "     gatectl apply"
echo "  3. Web-UI öffnen: https://${HOSTNAME}"
echo ""