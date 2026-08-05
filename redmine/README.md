# Redmine 7 hinter dem SDAN-Gateway

Docker-Compose-Stack für [Redmine 7](https://www.redmine.org/), veröffentlicht über das [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network).

## Voraussetzungen

- Docker und Docker Compose (Plugin)
- Laufender SDAN-Gateway mit `proxy_net` (oder eigenem Netzwerknamen)
- `gatectl` und `openssl`

## Schnellstart

1. `bash generate-env.sh` ausführen.
2. Mit `docker compose up -d` starten.
3. Logs mit `docker compose logs -f redmine` prüfen.
4. Im Gateway registrieren: `gatectl add redmine "Redmine 7" redmine.deinedomain.de http://redmine:3000`
5. Mit `gatectl apply` anwenden.

Der erste Start kann wegen der Datenbankinitialisierung einige Minuten dauern. Der Web-Container veröffentlicht keinen Host-Port; Zugriff erfolgt ausschließlich über das Gateway.

## Verwaltung

`gatectl disable redmine`, `gatectl enable redmine`, `gatectl remove redmine`, `gatectl public enable redmine`

## Wichtige Hinweise

- `REDMINE_HOST` muss dem öffentlichen Hostnamen von `gatectl add` entsprechen.
- TLS wird am Gateway terminiert; Redmine läuft intern auf HTTP.
- `REDMINE_SECRET_KEY_BASE` und `POSTGRES_PASSWORD` sicher aufbewahren.
- Die Volumes `redmine_files` und `pgdata` enthalten die persistenten Daten und müssen regelmäßig gesichert werden.

## Links

- [Redmine 7.0.0](https://www.redmine.org/news/)
- [Offizielles Redmine Docker Image](https://hub.docker.com/_/redmine)
- [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)
