# Sistema de Herramientas de Depuración y Diagnóstico (Debug)

Este documento sirve como índice central del ecosistema de depuración, diagnóstico y herramientas de **Vosque**.

---

## Índice Modular de Herramientas

| Documento | Enfoque Principal | Audiencia / Caso de Uso |
| :--- | :--- | :--- |
| **[Menú de Depuración In-Game (F3)](menu_debug_ingame.md)** | Menú unificado F3 tri-estado, controladores modularizados (`Jugador`, `Escenario`, `Enemigo`, `Sistema`), overlay vectorial en mundo y persistencia trans-sesión (`DebugConfig`). | Playtesting en caliente, calibración de físicas, cheats y forzado de estados de juego. |
| **[Plugins de Editor, MCP y Monitores](plugins_editor_y_mcp.md)** | Toolbar de personaje (`addons/personaje_tools`), linter de sectores (`addons/escenario_tools`), servidor de automatización MCP (`godot_ai`) y monitores nativos `Performance`. | Desarrollo en el editor de Godot, extensiones contextuales y auditoría de recursos. |
| **[Protocolos de Prueba y Diagnóstico](protocolos_de_prueba.md)** | Guías reproducibles de prueba paso a paso: validación de mutación (Issue #3), desatasco de IA, pruebas de saltos y checklist de exportación Web (HTML5). | QA, validación de hitos y verificación previa a lanzamientos. |
