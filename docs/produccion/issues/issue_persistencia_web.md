# [FEAT] Sistema de Persistencia Web y High Score (IndexedDB + LocalStorage Fallback)

## Contexto y Motivación
Actualmente, el progreso y el recuento de notas recolectadas solo reside en memoria durante la partida activa (`Maain.notas_recolectadas`). Al recargar la página web (<kbd>F5</kbd>), sufrir una derrota o volver al menú principal, la puntuación máxima no se almacena en el navegador ni en disco local.

Esta tarea corresponde al hito planificado de la **Semana 6** ([`docs/produccion/roadmap_y_hitos.md`](docs/produccion/roadmap_y_hitos.md#semana-6-08112026--14112026-persistencia-web-ia-steering-y-menús--planificada)) y el **Módulo 10** ([`docs/produccion/backlog_y_tareas.md`](docs/produccion/backlog_y_tareas.md#10-módulo-exportación-web-y-persistencia)), garantizando la retención del jugador tanto en escritorio como en plataformas web con entornos `<iframe>` (*itch.io* y *Newgrounds*).

---

## Documentación de Referencia en el Repositorio
- [Checklist de Exportación Web - Sección 5: Persistencia de Datos](docs/produccion/checklist_exportacion_web.md#5-persistencia-de-datos-en-web-high-score): Especificación de IndexedDB en Godot 4 Web, aislamiento de origen en iframes y fallback canónico con `JavaScriptBridge`.
- [Arquitectura de Partida y Director - Sección 4: Persistencia del High Score](docs/gameplay/arquitectura_de_partida_y_director.md#4-persistencia-del-high-score-en-web-y-desktop): Patrón dual `user://` + `localStorage`.
- [Roadmap y Hitos - Semana 6](docs/produccion/roadmap_y_hitos.md#semana-6-08112026--14112026-persistencia-web-ia-steering-y-menús--planificada): Planificación temporal y entregables del hito.
- [Backlog y Tareas de Producción - Módulos 5 y 10](docs/produccion/backlog_y_tareas.md): Criterios de integración con el Director y exportación web.
- [Pantallas y Menús - Game Over](docs/interfaz_y_audio/pantallas_y_menus.md#17-pantalla-de-game-over-derrota): Visualización de estadísticas de partida vs récord histórico.
- [Menú de Depuración In-Game - Pestaña Sistema](docs/herramientas/menu_debug_ingame.md#44-pestaña-sistema-notas-audio-y-telemetría): Botón de reseteo de High Score para pruebas.
- [Protocolos de Prueba - Persistencia](docs/herramientas/protocolos_de_prueba.md#4-pruebas-de-persistencia-y-guardado): Validación de recarga <kbd>F5</kbd> y retención de datos.

---

## Especificación Técnica y Requerimientos

### 1. Autoload Singleton: `GestorPersistencia` (`scripts/core/gestor_persistencia.gd`)
- Crear y registrar en `project.godot` como Autoload global `/root/GestorPersistencia`.
- **Estrategia Dual de Guardado:**
  1. **Nativo / IndexedDB:** Guardar en `user://highscore.save` usando `FileAccess.open()` y `store_32()`. En Web/WASM, Godot mapea `user://` hacia IndexedDB de forma automática.
  2. **Fallback Web (`localStorage`):** Si `OS.has_feature("web")` está activo, sincronizar además con `JavaScriptBridge.eval("localStorage.setItem('vosque_high_score', '%d');" % record)` y recuperar con `localStorage.getItem('vosque_high_score')` en caso de fallo de lectura de `user://`.
- **API Pública Requerida:**
  - `guardar_high_score(nuevo_score: int) -> bool`: Compara con el récord previo; solo persiste si `nuevo_score > record_actual`. Retorna `true` si es un nuevo récord.
  - `obtener_high_score() -> int`: Devuelve el récord histórico actual (consultando archivo y/o memoria en caché).
  - `es_nuevo_record(puntuacion: int) -> bool`: Consulta rápida booleana.
  - `resetear_high_score() -> void`: Limpia el archivo en `user://` y el item en `localStorage` (para depuración y QA).
- **Señales:**
  - `signal record_actualizado(nuevo_record: int)`

### 2. Integración con el Game Director (`Maain`)
- Archivo: `scripts/core/maain/maain.gd`.
- En `_on_jugador_capturado(_posicion_captura: Vector2)`:
  - Invocar `GestorPersistencia.guardar_high_score(notas_recolectadas)`.

### 3. Visualización en Pantalla de Game Over (`escenas/game_over.tscn`)
- Archivos: `escenas/game_over.tscn`, `scripts/ui/game_over.gd`.
- Presentar las notas recogidas en la partida terminada y el récord histórico obtenido de `GestorPersistencia`.
- Mostrar un feedback visual o banner condicional si se batió el récord en esa partida.

### 4. Integración con Menú de Depuración (`DebugMenu`)
- Archivo: `scripts/debug/debug_menu/debug_system_controller.gd`.
- Añadir en `TabSistema`:
  - Etiqueta o indicador con el High Score actual registrado.
  - Botón `"Resetear High Score"` que llame a `GestorPersistencia.resetear_high_score()`.

### 5. Suite de Pruebas Automatizadas (`tests/test_persistencia.gd`)
- Heredar de `McpTestSuite` (`class_name TestPersistencia extends McpTestSuite`).
- Casos de prueba requeridos:
  - `test_guardado_y_lectura_basica()`: Guardar un valor y verificar que se recupere exactamente.
  - `test_ignorar_puntuacion_menor()`: Comprobar que un puntaje inferior no degrade el récord existente.
  - `test_reseteo()`: Comprobar que `resetear_high_score()` devuelva el récord a 0.
  - `test_tolerancia_archivo_inexistente()`: Si no existe archivo previo, retornar 0 sin errores ni crashes.

---

## Criterios de Aceptación
- [x] `GestorPersistencia` está registrado como Autoload global en `project.godot`.
- [x] El récord se guarda en `user://highscore.save` y (en Web) se replica en `localStorage`.
- [x] Al reiniciar o recargar la pestaña del navegador con <kbd>F5</kbd>, el High Score se mantiene intacto.
- [x] La pantalla de Game Over muestra correctamente el High Score persistido.
- [x] La pestaña de Sistema en el Menú de Debug permite consultar y resetear el récord a 0.
- [x] La suite `tests/test_persistencia.gd` se ejecuta y pasa todos los tests satisfactoriamente.
