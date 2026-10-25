# Menú Unificado de Depuración In-Game (F3)

Este documento detalla la arquitectura, controles, capas visuales y controladores del sistema de depuración in-game de **Vosque**.

> 💻 **Escena maestra:** `escenas/debug_menu.tscn`  
> 💻 **Fachada principal:** [`scripts/debug_menu/debug_menu.gd`](../../scripts/debug_menu/debug_menu.gd)  
> 🛠️ **Plugins y monitores:** [Plugins de Editor y Monitores](plugins_editor_y_mcp.md)  
> 🧪 **Guías de prueba:** [Protocolos de Prueba](protocolos_de_prueba.md)

---

## 1. Filosofía y Principios de Diseño

1. **Inmediatez y Control Centralizado:** Todas las utilidades de diagnóstico convergen en un único punto de acceso mediante la tecla <kbd>F3</kbd>.
2. **Arquitectura No Invasiva y Desacoplada:** El sistema de debug inspecciona nodos (`personaje`, `escenario`, `enemigo`) mediante verificaciones seguras (`has_method()`, variables condicionales y referencias nulas). Si un componente no está instanciado, se degrada elegantemente sin arrojar excepciones.
3. **Persistencia Trans-Sesión (`DebugConfig` Autoload):** Los ajustes de depuración (toggles visuales, cheats, velocidades calibradas y time_scale) se conservan a través de `/root/DebugConfig` (`scripts/debug_config.gd`), impidiendo que se reinicien al recargar la escena o reiniciar tras un Game Over.
4. **Simulación en Tiempo Real:** Por defecto, abrir la consola de debug no pausa el motor, permitiendo observar cómo reaccionan las físicas y las mutaciones espaciales en vivo.
5. **Cero Sobrecarga en Producción (`Release`):** Todas las rutinas de dibujo vectorial, captura de teclas <kbd>F3</kbd> y telemetría están blindadas bajo `if OS.is_debug_build():`. En compilaciones web de producción para itch.io y Newgrounds, el menú no procesa eventos ni reserva memoria (*zero overhead*).

---

## 2. Mapa de Controles y Estados de Visualización (Ciclo Tri-Estado)

El acceso al menú se gestiona mediante pulsaciones sucesivas de <kbd>F3</kbd>:

```
┌────────────────┐      <F3>      ┌────────────────┐      <F3>      ┌─────────────────────┐
│  1. OCULTO     │  ───────────>  │  2. MINI-HUD   │  ───────────>  │  3. MENÚ COMPLETO   │
│ (Juego Limpio) │  <───────────  │   (Esquina)    │  <───────────  │ (Consola Pestañas)  │
└────────────────┘      <F3>      └────────────────┘      <F3>      └─────────────────────┘
```

| Estado | Descripción | Casos de Uso |
| :--- | :--- | :--- |
| **1. Oculto** | La interfaz está desactivada (`visible = false`). Cero llamadas de dibujo. | Partida arcade estándar, capturas de pantalla, playtesting inmersivo. |
| **2. Mini-HUD** | Widget compacto anclado en la esquina superior derecha. Muestra FPS, consumo de memoria, cuadrante actual, velocidad instantánea y estamina. | Pruebas de rendimiento y locomoción sin obstruir la vista central del juego. |
| **3. Menú Completo** | Panel modular con pestañas interactivas, botones de acción rápida, sliders y controles de diagnóstico visual (`_draw`). | Pruebas de mutación espacial, forzado de estados de IA, análisis de colisiones y cheats. |

> [!TIP]
> Dentro del **Menú Completo**, el selector `[x] Pausar Simulación` permite pausar el árbol del juego (`get_tree().paused = true`) para inspeccionar valores estáticos en un frame determinado.

---

## 3. Arquitectura Modular del Menú (`scripts/debug_menu/`)

El menú se implementa en un `CanvasLayer` con prioridad alta (`layer = 100`) y se desglosa en controladores independientes:

```text
DebugMenu (CanvasLayer, layer=100) [scripts/debug_menu/debug_menu.gd]
├── MiniHUD (PanelContainer en esquina superior derecha)
├── ConsolaPrincipal (PanelContainer modal semi-transparente)
│   ├── Encabezado (Título, FPS, Botón Cerrar, Toggle Pausa)
│   └── TabContainer
│       ├── TabJugador   ──> debug_cheats_controller.gd / debug_physics_controller.gd
│       ├── TabEscenario ──> debug_scenario_controller.gd
│       ├── TabEnemigo   ──> debug_enemy_controller.gd
│       └── TabSistema   ──> debug_system_controller.gd
└── DebugOverlay (Node2D) ──> debug_overlay.gd (Dibujo vectorial en mundo)
```

---

## 4. Desglose de Pestañas y Controladores

### 4.1. Pestaña Jugador y Físicas
* **Telemetría en Vivo:** Velocidad escalar y vectorial $(X, Y)$, estado de la FSM, estamina actual vs. máxima.
* **Pad Direccional Visual:** Matriz de 8 direcciones que resalta las entradas recibidas por el `InputServer`.
* **Cheats:**
  - `Estamina Infinita`: Permite pruebas de sprint continuo.
  - `Invencibilidad (God Mode)`: Ignora el contacto letal con el monstruo.
* **Sliders de Live Tweaking:**
  - Control de velocidad base (`speed`), sprint (`sprint_speed`), aceleración, fricción y plancha (`dive_speed`).
  - Modo automático proporcional: escala armónicamente todas las físicas al mover la velocidad base.
  - Botón para restaurar valores predeterminados.

### 4.2. Pestaña Escenario y Mutación
* **Telemetría de Cuadrante:** Indica el cuadrante del jugador (`NO`, `NE`, `SO`, `SE`) y las variantes activas en cada sector.
* **Forzar Mutación:** Botón que muta instantáneamente los 3 cuadrantes lejanos sin requerir la recolección física de una nota.
* **Controles Visuales:**
  - `[x] Desactivar Niebla`: Anula la niebla de transición para inspeccionar la carga de variantes en vivo.
  - `[x] Modo Fullbright`: Desactiva la oscuridad ambiental para inspección global.
  - `[x] Vista Global (God View)`: Desancla la cámara y aplica zoom panorámico exterior $0.225\times$.
* **Capas de Depuración en Mundo (`DebugOverlay`):**
  - Ejes divisores $X=0, Y=0$.
  - Corredores de seguridad de $160\text{ px}$ en verde (rojo si hay invasión).
  - Puntos de nota y filtros del spawner (Verde: válidos, Rojo: descartados, Dorado: nota activa).

### 4.3. Pestaña Monstruo e IA
* **Telemetría de Caza:** Posición, cuadrante, distancia euclidiana al jugador y estado de la línea de visión (`Directa` vs `Obstruida`).
* **Acciones:**
  - `[x] Congelar IA`: Desactiva la persecución para pruebas libres de obstáculos y saltos.
  - Selector de Fase (Nota 0 a 10+): Salto directo a cualquier escalón de velocidad de persecución ($500 \to 920\text{ px/s}$).
  - Botón "Reubicar Monstruo" a un cuadrante seguro.
* **Visualización Táctica:** Muestra en pantalla el `AreaCaptura` ($56\text{ px}$), la colisión física ($42\text{ px}$), el rayo de visión y las estelas de desplazamiento (*breadcrumbs* de los últimos 2 segundos).

### 4.4. Pestaña Sistema, Notas y Persistencia
* **Control de Tiempo (`Engine.time_scale`):** Botones de preajuste a `0.2x` (análisis de saltos en slow motion), `0.5x`, `1.0x` y `2.0x`.
* **Coleccionables:** Contador en tiempo real, botón para simular recolección inmediata y botón para teletransportar al jugador hacia la nota activa.
* **Game Feel y Cámara:** Inyectores manuales de trauma de cámara (`+0.20`, `+0.35`, `+1.00`).
* **Persistencia:** Botón para resetear el récord guardado en disco y `LocalStorage`.
* **Reinicio Rápido:** Recarga atómica de partida mediante `GestorEscenas.iniciar_partida()`.
