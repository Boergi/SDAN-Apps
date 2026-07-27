# Leantime hinter dem secure-docker-app-Network-Gateway

Dieses Verzeichnis enthält die Docker-Compose-Konfiguration für
[Leantime](https://leantime.io/) (Projektmanagement- und
Ideenmanagement-Software), die über das
[secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)
veröffentlicht wird.

Der Leantime-`web`-Service wird an das gemeinsame `proxy_net` angebunden,
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
cd leantime
bash generate-env.sh
```

Das Skript fragt alle notwendigen Werte ab und generiert fehlende Secrets
automatisch. Alternativ kann die `.env` manuell erstellt werden:

```bash
cp .env.example .env
# .env mit eigenen Werten editieren
# Wichtig: LEAN_SESSION_PASSWORD mit openssl rand -hex 32 generieren
```

### 2. Leantime starten

```bash
docker compose up -d
```

Der erste Start kann einige Minuten dauern (Datenbank-Initialisierung,
Migrationen). Der Fortschritt ist via Logs einsehbar:

```bash
docker compose logs -f
```

### 3. App im Gateway registrieren

```bash
# App hinzufügen (Upstream = Alias aus dem proxy_net)
gatectl add leantime "Leantime" leantime.deinedomain.de http://leantime:8080

# Konfiguration anwenden (Caddy neu laden)
gatectl apply

# Status prüfen
gatectl list
```

## gatectl-Kommandos (Referenz)

### App-Verwaltung

```bash
# App hinzufügen
gatectl add leantime "Leantime" leantime.deinedomain.de http://leantime:8080

# App deaktivieren / aktivieren
gatectl disable leantime
gatectl enable leantime

# App entfernen
gatectl remove leantime

# Nach Änderungen immer anwenden
gatectl apply
```

### Zugriffsmodi

```bash
# App öffentlich schalten (kein SSO, kein Token)
gatectl public enable leantime
gatectl public disable leantime
gatectl public list leantime
```

### Token-Zugang (für CI/CD, Skripte)

```bash
# Token anlegen
gatectl token add leantime "CI deploy"

# Token auflisten (nur Namen, nicht die Werte)
gatectl token list leantime

# Token entfernen
gatectl token remove leantime "CI deploy"
```

### Trusted-IP-Bypass

```bash
# Einzelne IP oder CIDR-Range erlauben
gatectl trusted-ip add leantime 203.0.113.10
gatectl trusted-ip add leantime 10.0.0.0/8

# Auflisten
gatectl trusted-ip list leantime

# Entfernen
gatectl trusted-ip remove leantime 203.0.113.10
```

## Wichtige Hinweise

### Hostname

`APP_HOST` muss dem öffentlichen Hostnamen entsprechen, unter dem Leantime
erreichbar ist (z. B. `leantime.deinedomain.de`).

### HTTPS

Die TLS-Terminierung erfolgt am secure-docker-app-Network-Gateway.
Leantime selbst läuft hinter dem Gateway auf HTTP.

### Session-Password

`LEAN_SESSION_PASSWORD` ist ein kritisches Secret. Bei Verlust sind
bestehende Sessions ungültig. Der Wert muss bei jedem Container-Neustart
identisch sein.

Generierung: `openssl rand -hex 32`

### Backup

Die Docker-Volumes `db_data` (Datenbank), `userfiles` und
`public_userfiles` (Uploads) enthalten alle persistenten Daten. Für ein
Backup:

```bash
docker run --rm -v leantime_db_data:/source -v $(pwd)/backup:/target alpine \
  tar czf /target/leantime-db-$(date +%Y%m%d).tar.gz -C /source .
```

Analog für `userfiles` und `public_userfiles`. Zur Wiederherstellung das
Volume leeren und das Archiv zurückspielen.

## Dateistruktur

```
leantime/
├── README.md              ← diese Datei
├── docker-compose.yml    ← Leantime-Stack
├── .env.example          ← Vorlage für Umgebungsvariablen
└── generate-env.sh       ← interaktiver Env-Generator
```

## Weiterführende Links

- [Leantime Website](https://leantime.io/)
- [Leantime Docker-Dokumentation](https://github.com/Leantime/leantime/tree/master/.docker)
- [Leantime Umgebungsvariablen](https://github.com/Leantime/leantime/blob/master/config/sample.env)
- [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)