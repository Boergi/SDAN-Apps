# Bifrost – AI API Gateway

[Bifrost](https://docs.getbifrost.ai) ist ein hochperformanter AI API Gateway,
der 20+ AI-Provider (OpenAI, Anthropic, Bedrock uvm.) über eine einheitliche
OpenAI-kompatible API vereint.

Dieser Stack ist für das **Secure Docker App Network (SDAN)** konfiguriert.

## Voraussetzungen

- Der [SDAN-Gateway](https://github.com/Boergi/secure-docker-app-network) läuft
- `gatectl` ist installiert

## Schnellstart

```bash
# 1. .env generieren
bash generate-env.sh

# 2. Stack starten
docker compose up -d

# 3. Im Gateway registrieren
gatectl add bifrost "Bifrost" $(grep APP_HOST .env | cut -d= -f2) http://bifrost:8080
gatectl apply
```

## Konfiguration

### Environment-Variablen

| Variable | Standard | Beschreibung |
|----------|----------|-------------|
| `TAG` | `latest` | Image-Tag |
| `APP_HOST` | – | Öffentlicher Hostname |
| `PROXY_NETWORK` | `proxy_net` | SDAN-Gateway-Netzwerk |
| `LOG_LEVEL` | `info` | Log-Level (debug, info, warn, error) |
| `LOG_STYLE` | `json` | Log-Format (json, pretty) |
| `BIFROST_DATA` | `bifrost_data` | Docker-Volume-Name |

### Deklarative Konfiguration (config.json)

Für eine deklarative Konfiguration eine `config.json` im Volume-Verzeichnis
ablegen. Standardmäßig wird das Volume unter `/app/data` gemountet.

```bash
# config.json erstellen (z. B. im Container)
docker exec -it bifrost sh -c 'cat > /app/data/config.json <<'"'"'EOF'"'"'
{
  "$schema": "https://www.getbifrost.ai/schema",
  "providers": {
    "openai": {
      "keys": [
        {
          "name": "openai-key-1",
          "value": "env.OPENAI_API_KEY",
          "models": ["gpt-4o-mini", "gpt-4o"],
          "weight": 1.0
        }
      ]
    }
  }
}
EOF'
```

Alternativ direkt auf dem Host (Volume-Pfad prüfen):

```bash
# Volume-Pfad finden
docker volume inspect bifrost_bifrost_data --format '{{.Mountpoint}}'
```

### API-Keys via Web-UI

Nach dem Start ist das Web-UI unter `https://<deine-domain>` erreichbar.
Dort können API-Keys bequem über die Oberfläche hinzugefügt werden.

## API testen

```bash
curl -X POST https://<deine-domain>/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "openai/gpt-4o-mini",
    "messages": [{"role": "user", "content": "Hello, Bifrost!"}]
  }'
```

## gatectl-Befehle

```bash
# App hinzufügen
gatectl add bifrost "Bifrost" bifrost.deinedomain.de http://bifrost:8080

# Konfiguration anwenden
gatectl apply

# Status prüfen
gatectl list
```

## Wichtige Hinweise

- **Keine Host-Ports:** Der Web-Container publiziert keine Ports – der Gateway
  vermittelt über das interne `proxy_net`
- **Healthcheck:** Der Container wird automatisch überwacht
- **Persistente Daten:** Konfiguration und Logs werden im Volume `bifrost_data` gespeichert

## Weiterführende Links

- [Bifrost Dokumentation](https://docs.getbifrost.ai)
- [SDAN-Gateway](https://github.com/Boergi/secure-docker-app-network)
- [Bifrost GitHub](https://github.com/maximhq/bifrost)