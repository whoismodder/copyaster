# Detective UI Audit — Copyaster — 15 Abril 2026

## Resumen

4 🔴 críticos · 17 🟠 serios · 16 🟡 menores · 3 🟢 triviales

## Críticos
- P-05: ScrollViewReader IDs no matchean — scroll con teclado roto
- C-08: "Enviado a Notas" se muestra aunque falle
- F-01: isOpaque=true mata el material del selector inline
- A-04: updateSelectorView() destruye la vista entera cada tecla

## Serios (calidad Apple)
- Tipografía hardcoded (.system(size:)) en vez de text styles dinámicos
- Hit targets de 30x30 (Apple HIG: mínimo 44x44)
- Width mismatch: vista pide 300, panel tiene 280
- Padding negativo antipatrón
- Sin accesibilidad (VoiceOver)
- Frame mismatches en Settings y HoverPreview
- Código debug en producción (/tmp logs)

## Detalle completo en el reporte del agente
