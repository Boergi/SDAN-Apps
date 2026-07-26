# OpenProject hinter dem secure-docker-app-Network-Gateway

Dieses Verzeichnis enthält die Docker-Compose-Konfiguration für
[OpenProject](https://www.openproject.org/) (Projektmanagement-Software),
die über das [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)
veröffentlicht wird.

Der OpenProject-`web`-Service wird an das gemeinsame `proxy_net` angebunden,
sodass der Gateway-Traffic ohne Host-Port-Publishing weiterleiten kann.

## Voraussetzungen

- Docker und Docker Compose (Plugin) sind installiert
- Der [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)-Gateway
  läuft und das Docker-Netzwerk `proxy_net` (oder ein benutzerdefinierter Name) existiert
- `openssl` ist installiert (für die Secret-Generierung)

## Schnellstart

### 1. Umgebungsvariablen generieren

```bash
cd openproject
bash generate-env.sh
```

Das Skript fragt alle notwendigen Werte ab und generiert fehlende Secrets
automatisch. Alternativ kann die `.env` manuell erstellt werden:

```bash
cp .env.example .env
# .env mit eigenen Werten editieren
# Wichtig: SECRET_KEY_BASE mit openssl rand -hex 64 generieren
```

### 2. OpenProject starten

```bash
docker compose up -d
```

Der erste Start kann einige Minuten dauern (Datenbank-Initialisierung,
Migrationen, Seed-Daten). Der Fortschritt ist via Logs einsehbar:

```bash
docker compose logs -f
```

Sobald der `seeder`-Container durchgelaufen ist, ist OpenProject bereit.

### 3. App im Gateway registrieren

```bash
# App hinzufügen (Upstream = Alias aus dem proxy_net)
gatectl add openproject "OpenProject" openproject.deinedomain.de http://openproject:8080

# Konfiguration anwenden (Caddy neu laden)
gatectl apply

# Status prüfen
gatectl list
```

## gatectl-Kommandos (Referenz)

### App-Verwaltung

```bash
# App hinzufügen
gatectl add openproject "OpenProject" openproject.deinedomain.de http://openproject:8080

# App deaktivieren / aktivieren
gatectl disable openproject
gatectl enable openproject

# App entfernen
gatectl remove openproject

# Nach Änderungen immer anwenden
gatectl apply
```

### Zugriffsmodi

```bash
# App öffentlich schalten (kein SSO, kein Token)
gatectl public enable openproject
gatectl public disable openproject
gatectl public list openproject
```

### Token-Zugang (für CI/CD, Skripte)

```bash
# Token anlegen
gatectl token add openproject "CI deploy"

# Token auflisten (nur Namen, nicht die Werte)
gatectl token list openproject

# Token entfernen
gatectl token remove openproject "CI deploy"
```

### Trusted-IP-Bypass

```bash
# Einzelne IP oder CIDR-Range erlauben
gatectl trusted-ip add openproject 203.0.113.10
gatectl trusted-ip add openproject 10.0.0.0/8

# Auflisten
gatectl trusted-ip list openproject

# Entfernen
gatectl trusted-ip remove openproject 203.0.113.10
```

## Wichtige Hinweise

### Hostname

`OPENPROJECT_HOST__NAME` muss dem öffentlichen Hostnamen entsprechen,
unter dem OpenProject erreichbar ist (z. B. `openproject.deinedomain.de`).
Andernfalls generiert OpenProject falsche URLs in E-Mails und Formularen.

### HTTPS

Die TLS-Terminierung erfolgt am secure-docker-app-Network-Gateway.
OpenProject selbst läuft hinter dem Gateway auf HTTP. Die Einstellung
`OPENPROJECT_HTTPS=true` sorgt dafür, dass OpenProject korrekte
HTTPS-Links generiert.

### Secret Key Base

`SECRET_KEY_BASE` ist ein kritisches Secret. Bei Verlust sind bestehende
Sessions und verschlüsselte Datenbankinhalte unlesbar. Der Wert muss bei
jedem Container-Neustart identisch sein.

Generierung: `openssl rand -hex 64`

### Kollaboratives Editieren

Für die Echtzeit-Bearbeitung (z. B. gleichzeitiges Editieren von
Work-Packages) wird der `hocuspocus`-Service mitgeliefert. Da der
secure-docker-app-Network-Gateway nur nach Hostname routet (nicht nach
Pfad), funktioniert das Routing von `/hocuspocus*` an den hocuspocus-Service
**nicht** ohne einen vorgeschalteten internen Proxy. Falls dieses Feature
benötigt wird, muss ein interner Caddy (wie im upstream-Compose) ergänzt
werden.

### Backup

Die Docker-Volumes `pgdata` (Datenbank) und `opdata` (Uploads) enthalten
alle persistenten Daten. Für ein Backup:

```bash
docker run --rm -v pgdata:/source -v $(pwd)/backup:/target alpine \
  tar czf /target/openproject-pgdata-$(date +%Y%m%d).tar.gz -C /source .
```

Analog für `opdata`. Zur Wiederherstellung das Volume leeren und das
Archiv zurückspielen.

### autoheal

Der `autoheal`-Container mountet `/var/run/docker.sock` und startet
Container neu, die ihren Healthcheck nicht mehr bestehen. Dies ist ein
Sicherheitshinweis – der Socket-Zugriff ist auf den autoheal-Container
beschränkt.

## Dateistruktur

```
openproject/
├── README.md              ← diese Datei
├── docker-compose.yml    ← OpenProject-Stack
├── .env.example          ← Vorlage für Umgebungsvariablen
└── generate-env.sh       ← interaktiver Env-Generator
```

## Weiterführende Links

- [OpenProject Docker-Dokumentation](https://www.openproject.org/docs/installation-and-operations/installation/docker/)
- [OpenProject Umgebungsvariablen](https://www.openproject.org/docs/installation-and-operations/configuration/environment/)
- [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)