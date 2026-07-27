# gatectl-Kurzreferenz

`gatectl` ist das Verwaltungswerkzeug für den SDAN-Gateway. Es wird im
Gateway-Repository installiert: `./scripts/gatectl install`.

## App-Verwaltung

```bash
# App hinzufügen (Upstream = Alias aus dem proxy_net)
gatectl add <id> "<Anzeigename>" <hostname> http://<alias>:<port>

# App ohne Portal-Eintrag hinzufügen
gatectl add <id> "<Anzeigename>" <hostname> http://<alias>:<port> --no-portal

# Konfiguration anwenden (Caddy neu laden)
gatectl apply

# Vollständiger Neuaufbau der Gateway-Konfiguration
gatectl apply --rebuild

# Status aller Apps prüfen
gatectl list

# App deaktivieren / aktivieren / entfernen
gatectl disable <id>
gatectl enable <id>
gatectl remove <id>
```

## Zugriffsmodi

```bash
# App öffentlich schalten (kein SSO, kein Token)
gatectl public enable <id>
gatectl public disable <id>
gatectl public list <id>
```

## Token-Zugang (für CI/CD, Skripte)

```bash
# Token anlegen
gatectl token add <id> "CI deploy"

# Token auflisten (nur Namen, nicht die Werte)
gatectl token list <id>

# Token entfernen
gatectl token remove <id> "CI deploy"
```

## Trusted-IP-Bypass

```bash
# Einzelne IP oder CIDR-Range erlauben
gatectl trusted-ip add <id> 203.0.113.10
gatectl trusted-ip add <id> 10.0.0.0/8

# Auflisten
gatectl trusted-ip list <id>

# Entfernen
gatectl trusted-ip remove <id> 203.0.113.10
```

## Typischer Workflow für eine neue App

```bash
# 1. App im Gateway registrieren
gatectl add myapp "MyApp" myapp.deinedomain.de http://myapp:8080

# 2. Konfiguration anwenden
gatectl apply

# 3. Status prüfen
gatectl list

# 4. (Optional) Token für CI/CD anlegen
gatectl token add myapp "CI deploy"

# 5. (Optional) Trusted-IP für interne Dienste
gatectl trusted-ip add myapp 10.0.0.0/8
```

## Quellen

- Gateway-Repository: [secure-docker-app-network](https://github.com/Boergi/secure-docker-app-network)
- Installation: `./scripts/gatectl install` (im Gateway-Repo)