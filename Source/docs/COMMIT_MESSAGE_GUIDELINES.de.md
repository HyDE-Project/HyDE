# Commit Message Richtlinien

<!--
Mehrsprachige COMMIT_MESSAGE_GUIDELINES-Unterstützung
-->

[![en](https://img.shields.io/badge/lang-en-red.svg)](../../COMMIT_MESSAGE_GUIDELINES.md)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](COMMIT_MESSAGE_GUIDELINES.es.md)
[![fr](https://img.shields.io/badge/lang-fr-blue.svg)](/COMMIT_MESSAGE_GUIDELINES.fr.md)


Eine gute Commit-Nachricht sollte beschreibend sein und einen Kontext zu den vorgenommenen Änderungen liefern. Das macht es einfacher, die Änderungen zu verstehen und in Zukunft zu überprüfen.

Hier sind einige Richtlinien für das Schreiben anschaulicher Commit-Nachrichten:

- Beginnen Sie mit einer kurzen Zusammenfassung der Änderungen, die in der Commit-Nachricht vorgenommen wurden.

- Verwenden Sie für die Zusammenfassung den Imperativ, als ob Sie einen Befehl geben würden. Zum Beispiel: „Feature hinzufügen“ statt „Feature hinzugefügt“.

- Geben Sie, wenn nötig, zusätzliche Details in der Commit-Nachricht an. Dies könnte den Grund für die Änderung, die Auswirkungen der Änderung oder alle Abhängigkeiten, die eingeführt oder entfernt wurden, beinhalten.

- Halten Sie die Nachricht innerhalb von 72 Zeichen pro Zeile, um sicherzustellen, dass sie in der Git-Log-Ausgabe leicht zu lesen ist.

Beispiele für gute Commit-Nachrichten:

- „Authentifizierungsfunktion für die Benutzeranmeldung hinzufügen“
- „Fehler beheben, der die Anwendung beim Start zum Absturz bringt“
- „Dokumentation für API-Endpunkte aktualisieren“.

Denken Sie daran, dass das Schreiben von beschreibenden Commit-Nachrichten in Zukunft Zeit und Frustration sparen kann und anderen hilft, die an der Codebasis vorgenommenen Änderungen zu verstehen.

## Commit Message Types

Hier ist eine umfassendere Liste von Commit-Typen, die Sie verwenden können:

"Feat": Hinzufügen eines neuen Features zu dem Projekt

```Markdown
feat: Unterstützung für den Upload mehrerer Bilder hinzufügen
```

`fix`: Behebung eines Fehlers oder Problems im Projekt

```Markdown
beheben: Behebt einen Fehler, der die Anwendung beim Start zum Absturz bringt
```

`docs`: Aktualisieren der Dokumentation im Projekt

```Markdown
docs: Aktualisierung der Dokumentation für API-Endpunkte
```

"Stil": Kosmetische oder stilistische Änderungen am Projekt vornehmen (z. B. Farben ändern oder Code formatieren)

```Markdown
Stil: Farben und Formatierung aktualisieren
```

Refactor": Code-Änderungen, die das Verhalten des Projekts nicht beeinflussen, aber seine Qualität oder Wartbarkeit verbessern

```Markdown
Refaktorieren: Entfernen von unbenutztem Code
```

"Testen": Hinzufügen oder Ändern von Tests für das Projekt

```Markdown
testen: Hinzufügen von Tests für eine neue Funktion
```

"Chore": Änderungen am Projekt vornehmen, die in keine andere Kategorie passen, wie z.B. Aktualisieren von Abhängigkeiten oder Konfigurieren des Build-Systems

```Markdown
Aufgabe: Aktualisieren von Abhängigkeiten
```

`perf`: Verbesserung der Leistung des Projekts

```Markdown
perf: Verbesserung der Leistung der Bildverarbeitung
```

`Sicherheit`: Behandlung von Sicherheitsproblemen im Projekt

```Markdown
Sicherheit: Aktualisieren der Abhängigkeiten, um Sicherheitsprobleme zu beheben
```

Zusammenführen": Zusammenführen von Zweigen im Projekt

```Markdown
Zusammenführen: Zusammenführen des Zweiges 'feature/branch-name' in develop
```

rückgängig machen': Einen vorherigen Commit rückgängig machen

```Markdown
rückgängig machen: Revertiere „Feature hinzufügen“
```

Bauen": Änderungen am Build-System oder an den Abhängigkeiten des Projekts vornehmen

```Markdown
bauen: Abhängigkeiten aktualisieren
```

`ci`: Änderungen am Continuous Integration (CI) System für das Projekt vornehmen

```Markdown
ci: CI-Konfiguration aktualisieren
```

`config`: Änderungen an den Konfigurationsdateien für das Projekt vornehmen

```Markdown
config: Konfigurationsdateien aktualisieren
```

Deploy": Änderungen am Verteilungsprozess für das Projekt vornehmen

```Markdown
Bereitstellen: Verteilungsskripte aktualisieren
```

`init`: Erstellen oder Initialisieren eines neuen Repositorys oder Projekts

```Markdown
init: Projekt initialisieren
```

Verschieben": Verschieben von Dateien oder Verzeichnissen innerhalb des Projekts

```Markdown
verschieben: Dateien in ein neues Verzeichnis verschieben
```

Umbenennen": Umbenennen von Dateien oder Verzeichnissen innerhalb des Projekts

```Markdown
umbenennen: Dateien umbenennen
```

Entfernen": Entfernen von Dateien oder Verzeichnissen aus dem Projekt

```Markdown
entfernen: Dateien entfernen
```

`Update`: Aktualisieren von Code, Abhängigkeiten oder anderen Komponenten des Projekts

```Markdown
update: Code aktualisieren
```

Dies sind nur einige Beispiele, und Sie können auch Ihre eigenen Commit-Typen erstellen. Es ist jedoch wichtig, sie konsequent zu verwenden und klare, beschreibende Commit-Nachrichten zu schreiben, damit andere die Änderungen, die Sie gemacht haben, leicht verstehen können.

**Wichtig:** Wenn Sie vorhaben, einen anderen Commit-Nachrichtentyp als die oben aufgeführten zu verwenden, fügen Sie ihn zu dieser Liste hinzu, damit andere ihn auch verstehen können. Erstellen Sie einen Pull-Request, um ihn zu dieser Datei hinzuzufügen.
