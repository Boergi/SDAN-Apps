# <APP_NAME> hinter dem secure-docker-app-Network-Gateway

Dieses Verzeichnis enthält die Docker-Compose-Konfiguration für
[<APP_NAME>](https://example.com/) (<APP_BESCHREIBUNG>),
die über das [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)
veröffentlicht wird.

Der `<APP_NAME>`-`web`-Service wird an das gemeinsame `proxy_net` angebunden,
sodass der Gateway-Traffic ohne Host-Port-Publishing weiterleiten kann.

## Voraussetzungen

- Docker und Docker Compose (Plugin) sind installiert
- Der [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)-Gateway
  läuft und das Docker-Netzwerk `proxy_net` (oder ein benutzerdefinierter Name) existiert
- `gatectl` ist installiert (siehe Gateway-Repo: `./scripts/gatectl install`)
- `openssl` ist installiert (für die Secret-Generierung)

## Schnellstart

### 1. Umgebungsvariablen generieren

```bash
cd <APP_NAME>
bash generate-env.sh
```

Das Skript fragt alle notwendigen Werte ab und generiert fehlende Secrets
automatisch. Alternativ kann die `.env` manuell erstellt werden:

```bash
cp .env.example .env
# .env mit eigenen Werten editieren
# Wichtig: SECRET_KEY_BASE mit openssl rand -hex 64 generieren
```

### 2. <APP_NAME> starten

```bash
docker compose up -d
```

Der Fortschritt ist via Logs einsehbar:

```bash
docker compose logs -f
```

### 3. App im Gateway registrieren

```bash
# App hinzufügen (Upstream = Alias aus dem proxy_net)
gatectl add <APP_NAME> "<APP_NAME>" <APP_NAME>.deinedomain.de http://<APP_NAME>:<APP_PORT>

# Konfiguration anwenden (Caddy neu laden)
gatectl apply

# Status prüfen
gatectl list
```

## gatectl-Kommandos (Referenz)

### App-Verwaltung

```bash
# App hinzufügen
gatectl add <APP_NAME> "<APP_NAME>" <APP_NAME>.deinedomain.de http://<APP_NAME>:<APP_PORT>

# App deaktivieren / aktivieren
gatectl disable <APP_NAME>
gatectl enable <APP_NAME>

# App entfernen
gatectl remove <APP_NAME>

# Nach Änderungen immer anwenden
gatectl apply
```

### Zugriffsmodi

```bash
# App öffentlich schalten (kein SSO, kein Token)
gatectl public enable <APP_NAME>
gatectl public disable <APP_NAME>
gatectl public list <APP_NAME>
```

### Token-Zugang (für CI/CD, Skripte)

```bash
# Token anlegen
gatectl token add <APP_NAME> "CI deploy"

# Token auflisten (nur Namen, nicht die Werte)
gatectl token list <APP_NAME>

# Token entfernen
gatectl token remove <APP_NAME> "CI deploy"
```

### Trusted-IP-Bypass

```bash
# Einzelne IP oder CIDR-Range erlauben
gatectl trusted-ip add <APP_NAME> 203.0.113.10
gatectl trusted-ip add <APP_NAME> 10.0.0.0/8

# Auflisten
gatectl trusted-ip list <APP_NAME>

# Entfernen
gatectl trusted-ip remove <APP_NAME> 203.0.113.10
```

## Wichtige Hinweise

### Hostname

`APP_HOST` muss dem öffentlichen Hostnamen entsprechen, unter dem die App
erreichbar ist (z. B. `<APP_NAME>.deinedomain.de`).

### HTTPS

Die TLS-Terminierung erfolgt am secure-docker-app-Network-Gateway.
Die App selbst läuft hinter dem Gateway auf HTTP.

### Secret Key Base

`SECRET_KEY_BASE` ist ein kritisches Secret. Bei Verlust sind bestehende
Sessions und verschlüsselte Datenbankinhalte unlesbar. Der Wert muss bei
jedem Container-Neustart identisch sein.

Generierung: `openssl rand -hex 64`

### Backup

Die Docker-Volumes enthalten alle persistenten Daten. Für ein Backup:

```bash
docker run --rm -v <VOLUME>:/source -v $(pwd)/backup:/target alpine \
  tar czf /target/<APP_NAME>-$(date +%Y%m%d).tar.gz -C /source .
```

Zur Wiederherstellung das Volume leeren und das Archiv zurückspielen.

## Dateistruktur

```
<APP_NAME>/
├── README.md              ← diese Datei
├── docker-compose.yml    ← <APP_NAME>-Stack
├── .env.example          ← Vorlage für Umgebungsvariablen
└── generate-env.sh       ← interaktiver Env-Generator
```

## Weiterführende Links

- [<APP_NAME> Dokumentation](https://example.com/)
- [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)