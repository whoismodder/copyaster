# Clipboard Managers macOS — Research Abril 2026

## Copyaster vs Competencia

### Comparativa directa

| Feature | Copyaster | Maccy | Paste | CleanClip | Deck |
|---------|-----------|-------|-------|-----------|------|
| **Precio** | Gratis/OSS | Gratis/OSS | $30/año | $10-50 one-time | Gratis/OSS |
| **Stack** | Swift/SwiftUI | Swift/SwiftUI | Swift/AppKit | Swift nativo | Swift/SwiftUI |
| **Stars** | nuevo | 19,392 | N/A | 14 | 967 |
| **Storage** | JSON file | SwiftData (SQLite) | Propio | Propio | SQLite directo |
| **Búsqueda** | Substring simple | 4 modos (exact/fuzzy/regex/mixed) | Full text | Full text | Full text |
| **Hotkey** | Carbon RegisterEventHotKey | sindresorhus/KeyboardShortcuts | Propio | Propio | N/A |
| **Panel** | FloatingPanel (NSPanel) | FloatingPanel (NSPanel) | NSWindow timeline | NSPanel (3 modos) | SwiftUI |
| **Hover preview** | Sí (popover) | Slideout lateral | Hover en timeline | No | No |
| **Paste** | CGEvent Cmd+V | CGEvent Cmd+V | Propio | Propio | Propio |
| **Passwords** | ConcealedType/TransientType | nspasteboard.org + configurable | Sí | Sí | Sí |
| **Max recientes** | 20 | 200 (configurable hasta 999) | Ilimitado | 800 | Configurable |
| **Guardados con título** | ✅ | ❌ (solo pins con alias) | ✅ (pinboards) | ✅ (smart lists) | ✅ (tags) |
| **Apple Notes** | ✅ (osascript) | ❌ | ❌ | ❌ | ❌ |
| **Emoji en título** | ✅ (menú inline) | ❌ | ❌ | ❌ | ❌ |
| **iCloud sync** | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Paste Queue** | ❌ | ✅ (PasteStack v2) | ✅ | ✅ | ❌ |
| **OCR imágenes** | ❌ | ✅ (Vision framework) | ✅ | ❌ | ❌ |
| **Snippets/templates** | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Text transforms** | ❌ | ❌ | ❌ | ❌ | ❌ |
| **App Intents** | ❌ | ✅ (Shortcuts) | ✅ | ❌ | ❌ |
| **Encriptación** | ❌ | ❌ | ❌ | ❌ | ✅ |
| **Distribución** | make build | Homebrew + GitHub | App Store + Setapp | Direct download | GitHub |

---

## Lo que Maccy hace bien y Copyaster no tiene aún

1. **Hotkey con KeyboardShortcuts** (sindresorhus) — más robusto que Carbon directo
2. **SwiftData** en vez de JSON — escala mejor, búsqueda más rápida
3. **4 modos de búsqueda** — fuzzy con Fuse es clave para UX
4. **Configurable** — 6 paneles de settings, todo ajustable
5. **App Intents** — integración con Shortcuts/Siri
6. **OCR** — buscar texto dentro de imágenes copiadas
7. **Pins** — items fijos con hotkeys dedicados (Cmd+1 a Cmd+9)
8. **App de origen** — muestra de qué app viene cada clip
9. **Filtrado por regex y por app** — ignora apps específicas
10. **PasteStack** — paste queue (pegar varios en secuencia)

## Lo que Copyaster tiene y Maccy NO

1. **Guardados con título** — Maccy solo tiene "pins" sin organización real
2. **Emoji labels** — clasificación visual con emojis
3. **Apple Notes** — exportar clips a Notas nativo
4. **Dos capas claras** (Recientes/Guardados) — Maccy mezcla todo
5. **"Listo para pegar"** — feedback visual del clip actual
6. **Hover preview** en menu bar — Maccy no lo hace

## Features trending que NADIE tiene bien

1. **AI categorización** — solo Paste tiene algo básico con Apple Intelligence
2. **Semantic search** — buscar "ese link que copié ayer" por significado
3. **Cross-device sync** que funcione — solo Paste con iCloud, y es limitado
4. **Drag & drop** desde el clipboard manager — Raycast lo acaba de agregar
5. **Script plugins** — solo Deck, pero es rudimentario
6. **Language detection** — PasteBar lo tiene, útil para devs

---

## Arquitectura de Maccy (referencia)

### Cómo registra hotkeys
```
sindresorhus/KeyboardShortcuts → Carbon RegisterEventHotKey interno
Default: Cmd+Shift+C
Configurable via KeyboardShortcuts.Recorder
```

### Cómo hace el panel
```
NSPanel subclass con:
- .nonactivatingPanel, .resizable, .closable, .fullSizeContentView
- isFloatingPanel = true
- level = .statusBar
- collectionBehavior = [.auxiliary, .stationary, .moveToActiveSpace, .fullScreenAuxiliary]
- hidesOnDeactivate = false
- backgroundColor = .clear
- Se cierra en resignKey()
```

### Cómo almacena
```
SwiftData (SQLite) en ~/Library/Application Support/Maccy/Storage.sqlite
Modelos: HistoryItem (app, dates, pin, title, contents[])
         HistoryItemContent (type, value data)
```

### Cómo busca
```
In-memory sobre array de items
4 modos: exact → regexp → fuzzy (Fuse lib, threshold 0.7)
Throttled a 200ms
```

### Cómo pega
```
CGEvent con .combinedSessionState
Simula Cmd+V (keyDown + keyUp)
Detecta paste key real del menú Edit
Deshabilita eventos locales durante paste
```

---

## macOS 16 Tahoe — Impacto

1. **Clipboard History nativa** en Spotlight (Cmd+Space → Cmd+4)
   - Retención: 30min / 8h (default) / 7 días
   - Límite: 16,384 chars, ~20 items
   - GUARDA PASSWORDS en texto plano (vulnerabilidad)
   - No tiene: búsqueda, sync, snippets, categorización

2. **Privacy alerts** para pasteboard access
   - Apps que polleen changeCount disparan alerta
   - Nuevas APIs: `detect` methods (inspeccionar sin leer)
   - Usuario puede Allow/Deny por app
   - Una vez permitido, funciona normal

3. **Oportunidad**: Apple expuso la categoría → más usuarios la descubren → buscan algo mejor

---

## Recomendaciones para Copyaster v1.0

### Prioridad Alta (diferenciadores reales)
1. Migrar storage a SQLite (SwiftData o GRDB) — JSON no escala
2. Agregar fuzzy search (Fuse o similar)
3. Hacer el hotkey configurable (recorder UI)
4. Mostrar app de origen (ícono de la app que copió)
5. Login at launch automático

### Prioridad Media (lo esperado)
6. Settings panel (hotkey, max items, appearance)
7. Paste sin formato (plain text option)
8. Pins con Cmd+1 a Cmd+9
9. Filtrar apps (ignorar password managers)
10. Homebrew formula para distribución

### Prioridad Baja (diferenciación futura)
11. OCR en imágenes (Vision framework)
12. Paste Queue (pegar varios en secuencia)
13. App Intents (Shortcuts/Siri)
14. Drag & drop desde el panel
15. Text transforms (case, encode, format)
