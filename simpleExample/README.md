# simpleExample – Minimaler Nginx-Stack

Zeigt eine statische HTML-Seite hinter dem **Secure Docker App Network (SDAN)**-Gateway an.

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
gatectl add simpleexample "simpleExample" $(grep APP_HOST .env | cut -d= -f2) http://simpleExample-app:80
gatectl apply
```

## Konfiguration

### Environment-Variablen

| Variable | Standard | Beschreibung |
|----------|----------|-------------|
| `APP_HOST` | – | Öffentlicher Hostname |
| `PROXY_NETWORK` | `proxy_net` | SDAN-Gateway-Netzwerk |

## Anpassungen

Die Datei `index.html` kann nach Belieben editiert werden. Nach einer Änderung den Container neu starten:

```bash
docker compose restart
```

## gatectl-Befehle

```bash
# App hinzufügen
gatectl add simpleexample "simpleExample" simpleexample.deinedomain.de http://simpleExample-app:80

# Konfiguration anwenden
gatectl apply

# Status prüfen
gatectl list
```

## Wichtige Hinweise

- **Keine Host-Ports:** Der Container publiziert keine Ports – der Gateway vermittelt über das interne `proxy_net`
- **Read-only-Volume:** Die `index.html` wird als read-only gemountet (`:ro`)
- **Healthcheck:** Der Container wird automatisch überwacht

## Weiterführende Links

- [SDAN-Gateway](https://github.com/Boergi/secure-docker-app-network)
- [nginx-Alpine-Image](https://hub.docker.com/_/nginx)