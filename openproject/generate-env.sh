#!/usr/bin/env bash
#
# generate-env.sh – Erzeugt die .env für OpenProject hinter dem
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
echo "=== OpenProject .env Generator ==="
echo ""

# --- 1. Hostname abfragen ---------------------------------------------------
while true; do
  read -rp "Öffentlicher Hostname (z. B. openproject.deinedomain.de): " HOSTNAME
  if [[ -z "$HOSTNAME" ]]; then
    err "Hostname darf nicht leer sein."
  else
    break
  fi
done

# --- 2. Proxy-Netzwerk abfragen ---------------------------------------------
read -rp "Docker-Proxy-Netzwerk (Default: proxy_net): " PROXY_NETWORK
PROXY_NETWORK="${PROXY_NETWORK:-proxy_net}"

# --- 3. HTTPS-Modus abfragen ------------------------------------------------
read -rp "HTTPS am Gateway terminieren? (true/false, Default: true): " HTTPS_MODE
HTTPS_MODE="${HTTPS_MODE:-true}"

# --- 4. Postgres-Passwort ---------------------------------------------------
echo ""
echo "=== Postgres-Datenbank ==="
read -rp "Postgres-Passwort – leer lassen für Zufallswert: " PG_PASS_INPUT
if [[ -z "$PG_PASS_INPUT" ]]; then
  PG_PASS=$(openssl rand -hex 24)
  ok "Postgres-Passwort generiert."
else
  PG_PASS="$PG_PASS_INPUT"
fi

# --- 5. SECRET_KEY_BASE -----------------------------------------------------
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

# --- 6. Collaborative Server Secret -----------------------------------------
echo ""
echo "=== Kollaboratives Editieren (optional) ==="
echo "Wird für Echtzeit-Bearbeitung (z. B. gleichzeitiges Editieren von"
echo "Work-Packages) benötigt. Kann auch später nachgetragen werden."
read -rp "COLLABORATIVE_SERVER_SECRET – leer lassen für Zufallswert, 'skip' zum Überspringen: " COLLAB_INPUT
if [[ "$COLLAB_INPUT" == "skip" ]]; then
  COLLAB_SECRET=""
  ok "Kollaboratives Editieren übersprungen."
elif [[ -z "$COLLAB_INPUT" ]]; then
  COLLAB_SECRET=$(openssl rand -hex 32)
  ok "COLLABORATIVE_SERVER_SECRET generiert."
else
  COLLAB_SECRET="$COLLAB_INPUT"
fi

# --- 7. E-Mail-Konfiguration (optional) -------------------------------------
echo ""
echo "=== E-Mail-Konfiguration (optional) ==="
read -rp "Möchtest du SMTP konfigurieren? (yes/no, Default: no): " SETUP_MAIL
SMTP_VARS=""
if [[ "$SETUP_MAIL" == "yes" ]]; then
  read -rp "  SMTP-Server (z. B. smtp.example.com): " SMTP_ADDRESS
  read -rp "  SMTP-Port (Default: 587): " SMTP_PORT
  SMTP_PORT="${SMTP_PORT:-587}"
  read -rp "  SMTP-Benutzername: " SMTP_USER
  read -rsp "  SMTP-Passwort: " SMTP_PASS
  echo ""
  read -rp "  SMTP-Absender-Domain (z. B. example.com): " SMTP_DOMAIN
  SMTP_VARS=$(cat <<EOF

# SMTP
OPENPROJECT_EMAIL__DELIVERY__METHOD=smtp
OPENPROJECT_SMTP_ADDRESS=${SMTP_ADDRESS}
OPENPROJECT_SMTP_PORT=${SMTP_PORT}
OPENPROJECT_SMTP_USER_NAME=${SMTP_USER}
OPENPROJECT_SMTP_PASSWORD=${SMTP_PASS}
OPENPROJECT_SMTP_AUTHENTICATION=login
OPENPROJECT_SMTP_ENABLE__STARTTLS__AUTO=true
OPENPROJECT_SMTP_DOMAIN=${SMTP_DOMAIN}
EOF
)
  ok "SMTP-Konfiguration übernommen."
fi

# --- .env schreiben ---------------------------------------------------------
echo ""
info "Schreibe .env …"

cat > "$ENV_FILE" <<ENVEOF
##
# OpenProject – Umgebungsvariablen
# Generiert am $(date) durch generate-env.sh
##

# Image-Tag
TAG=17-slim

# Postgres-Version
POSTGRES_VERSION=17

# Öffentlicher Hostname
OPENPROJECT_HOST__NAME=${HOSTNAME}

# HTTPS (TLS-Terminierung am Gateway)
OPENPROJECT_HTTPS=${HTTPS_MODE}

# Secret Key Base
SECRET_KEY_BASE=${SECRET_KEY_BASE}

# Postgres
POSTGRES_PASSWORD=${PG_PASS}
DATABASE_URL=postgres://postgres:${PG_PASS}@db/openproject?pool=20&encoding=unicode&reconnect=true

# Threads
RAILS_MIN_THREADS=4
RAILS_MAX_THREADS=16

# Proxy-Netzwerk
PROXY_NETWORK=${PROXY_NETWORK}
ENVEOF

# Kollaboratives Editieren (nur wenn nicht übersprungen)
if [[ -n "${COLLAB_SECRET:-}" ]]; then
  cat >> "$ENV_FILE" <<ENVEOF

# Kollaboratives Editieren
COLLABORATIVE_SERVER_SECRET=${COLLAB_SECRET}
COLLABORATIVE_SERVER_URL=wss://${HOSTNAME}/hocuspocus
ENVEOF
fi

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
echo "  HTTPS:                 ${HTTPS_MODE}"
echo "  Proxy-Netzwerk:        ${PROXY_NETWORK}"
echo "  Postgres-Passwort:     ${PG_PASS}"
echo "  SECRET_KEY_BASE:       ${SECRET_KEY_BASE:0:16}… (gekürzt)"
if [[ -n "${COLLAB_SECRET:-}" ]]; then
  echo "  Collab. Secret:        ${COLLAB_SECRET:0:16}… (gekürzt)"
fi
echo ""
echo "Nächste Schritte:"
echo "  1. docker compose up -d"
echo "  2. App im Gateway registrieren:"
echo "     gatectl add openproject \"OpenProject\" ${HOSTNAME} http://openproject:8080"
echo "     gatectl apply"
echo ""