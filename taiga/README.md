# Taiga 6.9.0 hinter dem SDAN-Gateway

Dieser Stack verwendet die offizielle Taiga-Docker-Architektur mit Frontend, Backend, Events, geschützten Medien, RabbitMQ und PostgreSQL. Der interne Taiga-Gateway routet Weboberfläche, API, Medien und WebSockets; nur dieser Container wird in das SDAN-`proxy_net` aufgenommen.

## Voraussetzungen

- Docker und Docker Compose
- Laufender SDAN-Gateway mit `proxy_net`
- `gatectl` und `openssl`

## Schnellstart

1. `bash generate-env.sh` ausführen.
2. Mit `docker-compose up -d` starten.
3. Admin-Benutzer anlegen: `docker-compose exec taiga-back python manage.py createsuperuser`
4. Gateway registrieren: `gatectl add taiga "Taiga" taiga.deinedomain.de http://taiga:80`
5. Mit `gatectl apply` anwenden.

Der erste Start kann wegen Migrationen und der Initialisierung von PostgreSQL/RabbitMQ einige Minuten dauern.

## Env-Konfiguration

Die `.env.example` enthält die vollständigen Basisvariablen der offiziellen Taiga-Docker-Konfiguration:

- öffentliche URL und WebSockets: `TAIGA_SCHEME`, `TAIGA_DOMAIN`, `SUBPATH`, `WEBSOCKETS_SCHEME`
- Sicherheit: `SECRET_KEY`
- PostgreSQL: `POSTGRES_USER`, `POSTGRES_PASSWORD`
- RabbitMQ: Benutzer, Passwort, VHost und Erlang-Cookie
- SMTP: Backend, Host, Port, Benutzer, Passwort, Absender und TLS/SSL
- Telemetrie und Ablaufzeit für Attachments
- optionale Registrierung sowie GitHub-, GitLab-, Slack-, Jira- und Trello-Integrationen

Bei der Gateway-Subdomain-Konfiguration bleiben `SUBPATH` leer und `TAIGA_DOMAIN` enthält nur den Hostnamen. Bei aktiviertem SMTP müssen `EMAIL_USE_TLS` und `EMAIL_USE_SSL` gegenseitig exklusiv konfiguriert werden.

## Verwaltung

`gatectl disable taiga`, `gatectl enable taiga`, `gatectl remove taiga`, `gatectl public enable taiga`

## Wichtige Hinweise

- Keine Host-Ports sind veröffentlicht; der Zugriff erfolgt ausschließlich über das SDAN-Gateway.
- `SECRET_KEY`, PostgreSQL-Passwort, RabbitMQ-Passwort und Erlang-Cookie sicher aufbewahren.
- Die Volumes `taiga-db-data`, `taiga-static-data`, `taiga-media-data`, `taiga-async-rabbitmq-data` und `taiga-events-rabbitmq-data` regelmäßig sichern.
- Die optionale öffentliche Registrierung ist standardmäßig deaktiviert. Backend und Frontend benötigen bewusst unterschiedliche Schreibweisen (`False`/`false`, `True`/`true`).

## Weiterführende Links

- [Offizielles Taiga-Docker-Repository](https://github.com/taigaio/taiga-docker)
- [Taiga Docker-Konfiguration](https://docs.taiga.io/setup-production.html#configuration)
- [Taiga Releases](https://github.com/taigaio/taiga-back/releases)
