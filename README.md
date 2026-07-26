# SDAN-Apps – App-Container für das Secure Docker App Network

Dieses Repository enthält Docker-Compose-Stacks für Anwendungen, die über das
[secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network) (SDAN)
veröffentlicht werden. Jede App lebt in einem eigenen Verzeichnis und folgt einem
einheitlichen Muster, das die Integration mit dem SDAN-Gateway vereinfacht.

## Verfügbare Apps

| App | Beschreibung | Verzeichnis | Upstream-Alias |
|-----|-------------|-------------|----------------|
| [OpenProject](https://www.openproject.org/) | Projektmanagement-Software | `openproject/` | `openproject` |

## Voraussetzungen

- **Docker** und **Docker Compose** (Plugin) sind installiert
- Der [SDAN-Gateway](https://github.com/Boergi/secure-docker-app-network) läuft und das
  Docker-Netzwerk `proxy_net` (oder ein benutzerdefinierter Name) existiert
- **`gatectl`** ist installiert (siehe Gateway-Repo: `./scripts/gatectl install`)
- **`openssl`** ist installiert (für die Secret-Generierung)

## Architektur

Nur der öffentlich erreichbare Web-Container einer App tritt dem gemeinsamen
`proxy_net` bei. Backend-Services (Datenbanken, Caches, Worker) bleiben auf einem
isolierten internen Docker-Netzwerk. Der Gateway übernimmt TLS-Terminierung, SSO,
Token-Prüfung und IP-Filter – die App selbst muss keine dieser Aufgaben übernehmen.

**Wichtig:** Der Web-Container darf **keine Host-Ports publizieren** (`ports:`-Direktive).
Andernfalls wäre die App direkt erreichbar und würde den Gateway-Schutz umgehen.

## Standard-Verzeichnisstruktur einer App

Jede App folgt diesem Layout:

```
myapp/
├── README.md              ← App-spezifische Dokumentation
├── docker-compose.yml     ← Docker-Compose-Stack
├── .env.example           ← Vorlage für Umgebungsvariablen
└── generate-env.sh        ← Interaktiver Env-Generator (optional, aber empfohlen)
```

## Neue App hinzufügen – Schritt für Schritt

### 1. App-Verzeichnis anlegen

```bash
mkdir myapp
cd myapp
```

### 2. `docker-compose.yml` erstellen

Die Compose-Datei folgt diesen Konventionen:

```yaml
networks:
  app_net:                          # internes Backend-Netzwerk
    driver: bridge

  proxy_net:                        # externes Gateway-Netzwerk
    external: true
    name: ${PROXY_NETWORK:-proxy_net}

volumes:
  appdata:                          # persistente Daten

services:
  web:                              # öffentlicher Web-Container
    image: myapp/myapp:${TAG:-latest}
    restart: unless-stopped
    networks:
      app_net:
      proxy_net:
        aliases:
          - myapp                   # ← Upstream-Alias für gatectl
    environment:
      APP_HOST: "${APP_HOST:-localhost:8080}"
      # … weitere Variablen
    volumes:
      - appdata:/data
    depends_on:
      - db
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 10s
      timeout: 3s
      retries: 3
      start_period: 30s

  db:                               # Backend – kein proxy_net!
    image: postgres:${POSTGRES_VERSION:-17}
    restart: unless-stopped
    networks:
      - app_net
    volumes:
      - pgdata:/var/lib/postgresql/data
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-p4ssw0rd}
```

**Regeln:**

- **Kein `ports:`** am Web-Container – der Gateway greift über das interne
  `proxy_net` zu
- **Nur der Web-Container** tritt `proxy_net` bei – Backend-Services bleiben
  auf `app_net`
- **`proxy_net`** wird als `external: true` deklariert, der Name über die
  Umgebungsvariable `PROXY_NETWORK` gesteuert (Default: `proxy_net`)
- **Alias** im `proxy_net` definiert den Upstream-Namen für `gatectl add`
- **Healthcheck** ermöglicht `autoheal`-Überwachung (optional)

### 3. `.env.example` anlegen

Die Vorlage dokumentiert alle benötigten Umgebungsvariablen:

```bash
# App-Image-Tag
TAG=latest

# Öffentlicher Hostname
APP_HOST=myapp.deinedomain.de

# Proxy-Netzwerk (muss mit dem Gateway-Netzwerk übereinstimmen)
PROXY_NETWORK=proxy_net

# Secrets (mit openssl rand -hex 64 generieren)
SECRET_KEY_BASE=OVERWRITE_ME

# Datenbank
POSTGRES_PASSWORD=p4ssw0rd
```

**Wichtig:** `.env`-Dateien werden nicht ins Repository committet.
`.env.example` dient als Dokumentation und Vorlage.

### 4. `generate-env.sh` erstellen (optional, empfohlen)

Ein interaktives Skript, das die `.env`-Datei generiert. Es sollte:

- Verfügbarkeit von `openssl` prüfen
- Vor existierender `.env` warnen und um Bestätigung fragen
- Alle notwendigen Werte interaktiv abfragen
- Fehlende Secrets automatisch generieren (`openssl rand -hex 64`)
- Eine Zusammenfassung mit den nächsten Schritten ausgeben

Das Skript aus dem `openproject/`-Verzeichnis dient als Referenz.

### 5. App-spezifische `README.md` schreiben

Die README sollte mindestens enthalten:

- Kurzbeschreibung der App
- Verweis auf das SDAN-Gateway
- Schnellstart-Anleitung (Env generieren, Stack starten, Gateway-Registrierung)
- `gatectl`-Befehle für die App
- Wichtige Hinweise (Hostname, HTTPS, Secrets, Backup)
- Weiterführende Links

### 6. Stack starten

```bash
cd myapp
bash generate-env.sh
docker compose up -d
```

Den Fortschritt via Logs verfolgen:

```bash
docker compose logs -f
```

### 7. App im Gateway registrieren

```bash
# App hinzufügen (Upstream = Alias aus dem proxy_net)
gatectl add myapp "MyApp" myapp.deinedomain.de http://myapp:8080

# Konfiguration anwenden (Caddy neu laden)
gatectl apply

# Status prüfen
gatectl list
```

## Docker-Compose-Konventionen (Zusammenfassung)

| Aspekt | Vorgabe |
|--------|---------|
| Host-Ports publizieren | ❌ Niemals – nur internes Netzwerk |
| Web-Container an `proxy_net` | ✅ Mit `aliases` für den Upstream |
| Backend-Services an `proxy_net` | ❌ Niemals – nur internes `app_net` |
| `proxy_net`-Deklaration | `external: true`, Name via `PROXY_NETWORK` |
| Netzwerk-Trennung | Web = `proxy_net` + `app_net`, Backend = nur `app_net` |
| Healthcheck | Empfohlen (für `autoheal`) |
| Restart-Policy | `unless-stopped` |

## `.env`-Konventionen

| Variable | Zweck | Beispiel |
|----------|-------|----------|
| `PROXY_NETWORK` | Name des externen Gateway-Netzwerks | `proxy_net` |
| `TAG` | Image-Tag der App | `17-slim` |
| `POSTGRES_VERSION` | Postgres-Version (falls verwendet) | `17` |
| `APP_HOST` / `OPENPROJECT_HOST__NAME` | Öffentlicher Hostname | `app.deinedomain.de` |
| `HTTPS` / `OPENPROJECT_HTTPS` | HTTPS-Modus (TLS am Gateway) | `true` |
| `SECRET_KEY_BASE` | Kryptografisches Secret | `openssl rand -hex 64` |
| `POSTGRES_PASSWORD` | Datenbank-Passwort | `openssl rand -hex 24` |

**Wichtig:** Secrets wie `SECRET_KEY_BASE` müssen bei jedem Container-Neustart
identisch sein. Bei Verlust sind Sessions und verschlüsselte Daten unlesbar.

## `generate-env.sh`-Konventionen

Ein gutes Generator-Skript sollte:

1. **Prüfen:** `openssl` verfügbar? Bereits eine `.env` vorhanden? Überschreiben bestätigen?
2. **Abfragen:** Hostname, Proxy-Netzwerk, HTTPS-Modus, Passwörter
3. **Generieren:** Fehlende Secrets mit `openssl rand -hex N` erzeugen
4. **Schreiben:** `.env`-Datei mit allen Werten erstellen
5. **Zusammenfassen:** Generierte Werte (gekürzt) und nächste Schritte ausgeben

Das Skript aus `openproject/generate-env.sh` dient als vollständige Referenz.

## gatectl-Kurzreferenz

### App-Verwaltung

```bash
gatectl add myapp "MyApp" myapp.deinedomain.de http://myapp:8080
gatectl add myapp "MyApp" myapp.deinedomain.de http://myapp:8080 --no-portal
gatectl list
gatectl enable myapp
gatectl disable myapp
gatectl remove myapp
gatectl apply
gatectl apply --rebuild
```

### Zugriffsmodi

```bash
gatectl public enable myapp
gatectl public disable myapp
gatectl public list myapp
```

### Token-Zugang

```bash
gatectl token add myapp "CI deploy"
gatectl token list myapp
gatectl token remove myapp "CI deploy"
```

### Trusted-IP-Bypass

```bash
gatectl trusted-ip add myapp 203.0.113.10
gatectl trusted-ip add myapp 10.0.0.0/8
gatectl trusted-ip list myapp
gatectl trusted-ip remove myapp 203.0.113.10
```

## Backup

Jede App verwendet Docker-Volumes für persistente Daten. Die Volume-Namen sind
in der jeweiligen `docker-compose.yml` und `.env.example` dokumentiert.

Allgemeines Backup-Schema:

```bash
# Volume in ein Archiv packen
docker run --rm -v appdata:/source -v $(pwd)/backup:/target alpine \
  tar czf /target/myapp-$(date +%Y%m%d).tar.gz -C /source .

# Wiederherstellung
docker run --rm -v appdata:/target -v $(pwd)/backup:/source alpine \
  tar xzf /source/myapp-20250101.tar.gz -C /target
```

Die app-spezifische README enthält detaillierte Backup-Anleitungen.

## Weiterführende Links

- [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network) – Gateway-Repository
- [OpenProject Docker-Dokumentation](https://www.openproject.org/docs/installation-and-operations/installation/docker/)
- [Docker Compose Dokumentation](https://docs.docker.com/compose/)