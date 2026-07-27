# SDAN-Apps – Skills

Dieses Verzeichnis enthält projektbezogene Skills für das SDAN-Apps-Repository.
Die Skill-Dateien liegen hier zentral, damit sie von verschiedenen AI-Coding-Assistents
genutzt werden können.

## Verfügbar Skills

| Skill | Beschreibung |
|-------|-------------|
| [`sdan-app`](sdan-app/SKILL.md) | Neue App zum SDAN-Apps-Repository hinzufügen oder bestehende Apps auf Konformität prüfen |

## Einbindung in verschiedene Tools

Die Skill-Quellen liegen in `skills/<name>/`. Tool-spezifische Verzeichnisse
binden die Skills per Symlink ein:

### Cline

```bash
# Symlink erstellen (bereits eingerichtet)
ln -s ../../skills/sdan-app .cline/skills/sdan-app
```

Cline erkennt den Skill automatisch über `.cline/skills/<name>/SKILL.md`.

### Claude Code

```bash
# Symlink erstellen (bereits eingerichtet)
ln -s ../../skills/sdan-app .claude/skills/sdan-app
```

Claude Code lädt Skills aus `.claude/skills/<name>/SKILL.md`.

### Cursor

Für Cursor gibt es eine Regel-Datei in `.cursor/rules/`, die auf den Skill
verweist:

```
.cursor/rules/sdan-app.mdc
```

Die Regel aktiviert sich bei passenden Dateien (`docker-compose.yml`,
`.env.example`, `generate-env.sh`, `README.md`) und verweist auf die
vollständige Dokumentation in `skills/sdan-app/SKILL.md`.

## Skill-Struktur

```
skills/sdan-app/
├── SKILL.md              ← Hauptanweisung (wird vom Tool geladen)
├── templates/            ← Vorlagen für neue Apps
│   ├── docker-compose.yml
│   ├── env.example
│   ├── generate-env.sh
│   └── README.md
└── reference/            ← Referenzmaterial
    ├── checklist.md      ← Konformitäts-Checkliste
    └── gatectl.md        ← gatectl-Kommando-Referenz
```

## Neuen Skill hinzufügen

1. Skill-Verzeichnis unter `skills/<name>/` anlegen
2. `SKILL.md` mit Frontmatter (`name`, `description`) schreiben
3. Symlinks in `.cline/skills/` und `.claude/skills/` erstellen
4. Bei Cursor: `.cursor/rules/<name>.mdc` anlegen