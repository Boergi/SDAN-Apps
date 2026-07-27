# SDAN-App Konformitäts-Checkliste

Diese Checkliste wird verwendet, um neue oder bestehende Apps auf
Konformität mit den SDAN-Konventionen zu prüfen.

## docker-compose.yml

### Kritisch (Muss erfüllt sein)

- [ ] **Kein `ports:` am Web-Container** – der Gateway greift über das
      interne `proxy_net` zu
- [ ] **`proxy_net` als `external: true` deklariert**, Name via
      `${PROXY_NETWORK:-proxy_net}` parametrisierbar
- [ ] **Nur der Web-Container** ist Mitglied im `proxy_net`
- [ ] **Backend-Services** (db, cache, worker) sind **nur** im internen
      Netzwerk (`app_net` / `backend`), niemals im `proxy_net`
- [ ] **Upstream-Alias** am `proxy_net` des Web-Containers definiert
      (`aliases: [<appname>]`)
- [ ] **Keine echten Secrets** als Compose-Defaults – Platzhalter wie
      `OVERWRITE_ME` oder `p4ssw0rd` verwenden

### Warnung (Sollte erfüllt sein)

- [ ] **Restart-Policy** `unless-stopped` an allen Services
- [ ] **Healthcheck** am Web-Container definiert (für `autoheal`)
- [ ] **Volumes** für persistente Daten deklariert
- [ ] **`depends_on`** für Backend-Abhängigkeiten konfiguriert
- [ ] **`container_name`** nicht zwingend, aber hilfreich für
      `gatectl`-Referenzen

### Hinweis (Optional / Empfehlung)

- [ ] YAML-Anker (`&`/`*`) für wiederkehrende Konfigurationen verwendet
      (bei komplexeren Stacks)
- [ ] `autoheal`-Service bei Apps mit kritischen Healthchecks

## .env.example

- [ ] **Alle Variablen** dokumentiert, die in `docker-compose.yml`
      referenziert werden
- [ ] **`PROXY_NETWORK=proxy_net`** enthalten
- [ ] **Secrets** als `OVERWRITE_ME` markiert, mit Hinweis auf
      `openssl rand -hex N`
- [ ] **Kopf-Kommentar** mit Hinweis auf `cp .env.example .env` und
      `bash generate-env.sh`
- [ ] **Keine echten Secrets** in der `.env.example`

## generate-env.sh

- [ ] **`set -euo pipefail`** am Anfang
- [ ] **`openssl`-Verfügbarkeit** prüfen
- [ ] **Vorhandene `.env` erkennen** und Überschreiben bestätigen lassen
- [ ] **Hostname abfragen** (Pflichtfeld, leer nicht erlaubt)
- [ ] **Proxy-Netzwerk abfragen** (Default: `proxy_net`)
- [ ] **Secrets generieren** via `openssl rand -hex N`
      (64 für Secret-Keys, 24 für Passwörter, 32 für mittlere Secrets)
- [ ] **`.env` per Heredoc schreiben** mit allen Werten
- [ ] **Zusammenfassung** mit gekürzten Secrets (`${VAR:0:16}…`) und
      fertigen `gatectl add …`-Befehlen
- [ ] **Ausführbar** (`chmod +x`)

## README.md (App-spezifisch)

- [ ] **Kurzbeschreibung** der App
- [ ] **Verweis auf das SDAN-Gateway**
- [ ] **Voraussetzungen** (Docker, Gateway, `gatectl`, `openssl`)
- [ ] **Schnellstart**: `generate-env.sh` → `docker compose up -d` →
      `gatectl add …` → `gatectl apply`
- [ ] **`gatectl`-Befehle** für die App
- [ ] **Wichtige Hinweise**: Hostname, HTTPS, Secrets, Backup
- [ ] **Weiterführende Links**

## Root-README.md

- [ ] **Neue App in der Tabelle "Verfügbare Apps"** eingetragen
      (App-Name, Beschreibung, Verzeichnis, Upstream-Alias)

## Validierung

- [ ] **`docker compose -f <appname>/docker-compose.yml config -q`**
      erfolgreich (Syntax-Validierung)
- [ ] **`gatectl add …`-Befehl** getestet oder zumindest formuliert