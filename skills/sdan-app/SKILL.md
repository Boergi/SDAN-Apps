---
name: sdan-app
description: Neue App zum SDAN-Apps-Repository hinzufügen (docker-compose.yml, .env.example, generate-env.sh, README.md nach SDAN-Konventionen) oder bestehende Apps auf Konformität prüfen. Verwenden, wenn der Nutzer eine App für das Secure Docker App Network erstellen, integrieren, reviewen oder aktualisieren möchte.
---

# SDAN-App – Neue App für das Secure Docker App Network erstellen

Dieser Skill führt durch das Hinzufügen einer neuen App zum SDAN-Apps-Repository
und stellt die Einhaltung aller SDAN-Konventionen sicher. Er kann auch verwendet
werden, um bestehende Apps gegen die Konventionen zu prüfen.

## Grundprinzip der Architektur

- Nur der **öffentliche Web-Container** einer App tritt dem gemeinsamen
  `proxy_net` bei (externes Gateway-Netzwerk).
- **Backend-Services** (Datenbanken, Caches, Worker) bleiben ausschließlich
  auf einem internen `app_net` (bzw. `frontend`/`backend` bei komplexeren Apps).
- Der Gateway übernimmt TLS-Terminierung, SSO, Token-Prüfung und IP-Filter –
  die App implementiert davon nichts selbst.
- **Niemals `ports:` am Web-Container publizieren** – das würde den
  Gateway-Schutz umgehen.

## Workflow: Neue App hinzufügen

### 1. Rahmendaten klären

Vor dem Schreiben der Dateien folgende Informationen vom Nutzer erfragen
(falls nicht bereits bekannt):

- App-Name (Verzeichnisname, kleingeschrieben, z. B. `myapp`)
- Upstream-Alias im `proxy_net` (meist = App-Name, z. B. `myapp`)
- Interner Port des Web-Containers (z. B. `8080`)
- Benötigte Backend-Services (Postgres, Redis, Memcached, Worker, …)
- Persistent zu speichernde Daten (Volumes)
- Besondere Umgebungsvariablen der App (Hostname-Variable, HTTPS-Flag, Secrets)

### 2. Dateien aus den Templates erzeugen

Verzeichnis `<appname>/` anlegen und die vier Standard-Dateien erstellen.
Templates liegen in `templates/`:

```
myapp/
├── README.md              ← templates/README.md
├── docker-compose.yml     ← templates/docker-compose.yml
├── .env.example           ← templates/env.example
└── generate-env.sh        ← templates/generate-env.sh
```

Die Templates enthalten `{{PLATZHALTER}}`, die durch app-spezifische Werte
zu ersetzen sind. `generate-env.sh` muss ausführbar sein
(`chmod +x <appname>/generate-env.sh`).

### 3. Pflichtregeln für docker-compose.yml prüfen

Diese Regeln sind **nicht verhandelbar** – jede App muss sie erfüllen:

| Regel | Vorgabe |
|-------|---------|
| Host-Ports | ❌ Keine `ports:`-Direktive am Web-Container |
| `proxy_net`-Deklaration | `external: true`, Name via `${PROXY_NETWORK:-proxy_net}` |
| Web-Container | Mitglied in `app_net` **und** `proxy_net` (mit `aliases`) |
| Backend-Services | **Nur** `app_net` – niemals `proxy_net` |
| Upstream-Alias | `aliases: [<appname>]` am `proxy_net` des Web-Containers |
| Restart-Policy | `unless-stopped` |
| Healthcheck | Empfohlen am Web-Container (ermöglicht `autoheal`) |
| Env-Defaults | Sensible Defaults als `OVERWRITE_ME` / `p4ssw0rd`, nie echte Secrets |

### 4. .env.example-Konventionen

- Dokumentiert **alle** Variablen, die die Compose-Datei referenziert
- Secrets als `OVERWRITE_ME` markieren, mit Hinweis auf
  `openssl rand -hex 64` (bzw. `-hex 24` für Passwörter)
- `PROXY_NETWORK=proxy_net` immer enthalten
- Kopf-Kommentar: Hinweis auf `cp .env.example .env` und `generate-env.sh`
- `.env` selbst wird **niemals** committet

### 5. generate-env.sh-Konventionen

Das Skript folgt einem festen Ablauf (Referenz: `openproject/generate-env.sh`):

1. **Prüfen:** `openssl` verfügbar? Bereits `.env` vorhanden?
   → Überschreiben nur nach expliziter `yes`-Bestätigung
2. **Abfragen:** Hostname (Pflicht, leer nicht erlaubt), Proxy-Netzwerk
   (Default: `proxy_net`), weitere app-spezifische Werte
3. **Generieren:** Fehlende Secrets via `openssl rand -hex N`
   (64 für Secret-Keys, 24 für Passwörter, 32 für mittlere Secrets)
4. **Schreiben:** `.env` per Heredoc mit allen Werten
5. **Zusammenfassen:** Werte ausgeben (Secrets gekürzt: `${VAR:0:16}…`)
   und nächste Schritte inkl. fertigem `gatectl add …`-Befehl anzeigen

Stil: `set -euo pipefail`, farbige Helper (`info`/`ok`/`warn`/`err`),
deutsche Ausgaben, interaktive `read -rp`-Abfragen.

### 6. App-README.md-Konventionen

Mindestinhalt (Referenz: `openproject/README.md`):

- Kurzbeschreibung der App + Verweis auf das SDAN-Gateway
- Voraussetzungen (Docker, laufender Gateway, `gatectl`, `openssl`)
- Schnellstart: `bash generate-env.sh` → `docker compose up -d` →
  `gatectl add <appname> "<Anzeigename>" <host> http://<alias>:<port>` →
  `gatectl apply`
- `gatectl`-Befehle für die App
- Wichtige Hinweise: Hostname-Konfiguration, HTTPS am Gateway, Secrets,
  Backup (Volumes), ggf. autoheal
- Weiterführende Links

### 7. Root-README.md aktualisieren

Die Tabelle „Verfügbare Apps" in der Root-`README.md` um die neue App
ergänzen:

```markdown
| [AppName](https://…) | Kurzbeschreibung | `appname/` | `appname` |
```

### 8. Abschluss-Validierung

Vor dem Fertigstellen immer:

- `docker compose -f <appname>/docker-compose.yml config -q` ausführen
  (Syntax-Validierung; benötigt ggf. eine temporäre `.env` oder funktioniert
  dank Defaults ohne)
- Gegen die Checkliste in `reference/checklist.md` prüfen
- Dem Nutzer die fertigen `gatectl`-Befehle zum Registrieren ausgeben

## Workflow: Bestehende App prüfen (Review)

Bei einem Review-Auftrag die App-Dateien lesen und gegen
`reference/checklist.md` prüfen. Befunde nach Schweregrad ordnen:

- **Kritisch:** `ports:` publiziert, Backend im `proxy_net`, fehlender
  Upstream-Alias, echte Secrets als Compose-Defaults
- **Warnung:** Fehlender Healthcheck, fehlende Restart-Policy, `proxy_net`
  nicht parametrisierbar, `.env.example` unvollständig
- **Hinweis:** Fehlendes `generate-env.sh`, README-Lücken, fehlender
  Root-README-Eintrag

## gatectl-Kurzreferenz

```bash
# App registrieren (Upstream = Alias aus dem proxy_net)
gatectl add <id> "<Name>" <hostname> http://<alias>:<port>
gatectl apply                      # Konfiguration anwenden (Caddy reload)
gatectl list                       # Status prüfen

# Zugriff
gatectl public enable <id>         # Ohne SSO/Token öffentlich
gatectl token add <id> "CI deploy" # Token-Zugang
gatectl trusted-ip add <id> <ip>   # IP-Bypass

# Verwaltung
gatectl disable <id> / enable <id> / remove <id>
gatectl apply --rebuild            # Vollständiger Neuaufbau
```

Vollständige Referenz: `reference/gatectl.md`

## Backup-Schema (für README-Hinweise)

```bash
# Sichern
docker run --rm -v <volume>:/source -v $(pwd)/backup:/target alpine \
  tar czf /target/<appname>-$(date +%Y%m%d).tar.gz -C /source .

# Wiederherstellen
docker run --rm -v <volume>:/target -v $(pwd)/backup:/source alpine \
  tar xzf /source/<appname>-<datum>.tar.gz -C /target
```
