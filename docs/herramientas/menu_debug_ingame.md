# Menú Unificado de Depuración In-Game (F3)

Este documento detalla la arquitectura, controles, capas visuales y controladores del sistema de depuración in-game de **Vosque**.

> 💻 **Escena maestra:** `escenas/debug_menu.tscn`  
> 💻 **Fachada principal:** [`scripts/debug/debug_menu/debug_menu.gd`](../../scripts/debug/debug_menu/debug_menu.gd)  
> 🛠️ **Plugins y monitores:** [Plugins de Editor y Monitores](plugins_editor_y_mcp.md)  
> 🧪 **Guías de prueba:** [Protocolos de Prueba](protocolos_de_prueba.md)

---

## 1. Filosofía y Principios de Diseño

1. **Inmediatez y Control Centralizado:** Todas las utilidades de diagnóstico convergen en un único punto de acceso mediante la tecla <kbd>F3</kbd>.
2. **Arquitectura No Invasiva y Desacoplada:** El sistema de debug inspecciona nodos (`personaje`, `escenario`, `enemigo`) mediante verificaciones seguras (`has_method()`, variables condicionales y referencias nulas). Si un componente no está instanciado, se degrada elegantemente sin arrojar excepciones.
3. **Persistencia Trans-Sesión (`DebugConfig` Autoload):** Los ajustes de depuración (toggles visuales, cheats, velocidades calibradas y time_scale) se conservan a través de `/root/DebugConfig` (`scripts/debug/debug_config.gd`), impidiendo que se reinicien al recargar la escena o reiniciar tras un Game Over.
4. **Simulación en Tiempo Real:** Por defecto, abrir la consola de debug no pausa el motor, permitiendo observar cómo reaccionan las físicas y las mutaciones espaciales en vivo.
5. **Desacoplamiento de Entornos:** Los componentes de debug discriminan la ejecución entre editor y juego activo (`Engine.is_editor_hint()`), mientras que la telemetría pesada y el registro de monitores nativos de `Performance` están blindados bajo `OS.is_debug_build()`. En estado oculto, el menú apaga su visibilidad eliminando cualquier sobrecarga de dibujo.

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
> Dentro del **Menú Completo**, el selector `[x] Pausar Simulación` comparte la misma fuente de verdad que el sistema de pausa in-game (`get_tree().paused = true`), garantizando que la congelación sea coherente. Asimismo, cuando el Menú Completo de debug está abierto, presionar <kbd>Escape</kbd> lo cierra a `ModoVisual.OCULTO` y consume el evento (`set_input_as_handled()`), evitando desplegar accidentalmente el `MenuPausa` del juego.

---

## 3. Arquitectura Modular del Menú (`scripts/debug/debug_menu/`)

El menú se implementa en un `CanvasLayer` con prioridad alta (`layer = 100`) y desacopla la lógica mediante controladores especializados coordinados por `DebugMenu`:

```text
DebugMenu (CanvasLayer, layer=100) [scripts/debug/debug_menu/debug_menu.gd]
├── DebugContext [debug_context.gd] (Resolución de nodos objetivo, fallback de cámaras y cuadrantes)
├── DebugTelemetryPresenter [debug_telemetry_presenter.gd] (Formateo y presentación desacoplada a la UI)
├── DebugCustomMonitors [debug_custom_monitors.gd] (Monitores nativos en depurador Performance de Godot)
├── ControlRaiz (Control que contiene la UI)
│   ├── MiniHUD (PanelContainer en esquina superior derecha)
│   │   └── BtnMiniExpandir (Botón rápido para abrir Menú Completo)
│   └── PanelConsola (PanelContainer modal semi-transparente)
│       ├── BarraSuperior (Título, CheckPausar, BotonCerrar)
│       └── TabContainer
│           ├── Jugador   ──> debug_cheats_controller.gd / debug_physics_controller.gd
│           ├── Escenario ──> debug_scenario_controller.gd
│           ├── Enemigo   ──> debug_enemy_controller.gd (conecta a DepuradorVisualEnemigo)
│           └── Sistema   ──> debug_system_controller.gd
└── DebugOverlay (Node2D) ──> debug_overlay.gd (Dibujo vectorial perimetral y espacial en mundo)
```

---

## 4. Desglose de Pestañas y Controladores

### 4.1. Pestaña Jugador y Físicas
* **Telemetría en Vivo:** Velocidad escalar y vectorial $(X, Y)$, velocidad máxima, aceleración, fricción, estado de la FSM, posición global, cuadrante y coordenadas de su centro, y estamina actual vs. máxima (compatible con esquemas `stamina`/`max_stamina`, `estamina` o `estamina_actual`).
* **Pad Direccional Visual:** Matriz visual que resalta en tiempo real las direcciones recibidas por el mapeo de entrada (`personaje-izquierda`, `personaje-derecha`, etc., con fallback a `ui_*`).
* **Cheats:**
  - `Estamina Infinita`: Activa `sin_gasto_estamina` o recarga continuamente la estamina y elimina la fatiga.
  - `Invencibilidad (God Mode)`: Activa la propiedad `god_mode` en el personaje y desactiva la máscara de colisión contra el monstruo (capa 4).
* **Panel Desplegable de Live Tweaking (`BtnDesplegarFisicas`):**
  - Panel plegable con controles deslizantes para calibrar en caliente la velocidad base (`speed`), sprint (`sprint_speed`), aceleración (`acceleration`), fricción (`friction`) y salto/plancha (`dive_speed`).
  - `[x] Escalado Proporcional`: Al mover la velocidad normal, ajusta armónicamente y en cadena el sprint, la aceleración, la fricción y la plancha manteniendo las proporciones de diseño.
  - Botón para restaurar los valores predeterminados originales del personaje o de la configuración persistida.

### 4.2. Pestaña Escenario y Mutación
* **Telemetría de Cuadrante:** Indica el estado del escenario, el cuadrante activo del jugador (`NO`, `NE`, `SO`, `SE`) y la variante procedural activa en cada uno de los cuatro sectores. En modo standalone sin escenario instanciado, muestra los rangos de coordenadas de cada cuadrante.
* **Forzar Mutación:** Botón que ejecuta inmediatamente `mutar_con_neblina()` o `mutar_sectores_lejanos()` sin requerir la recolección física de una nota.
* **Controles Visuales y de Cámara:**
  - `[x] Desactivar Niebla de Mutación`: Modifica `target_efecto_niebla.desactivado` en caliente para inspeccionar visualmente la carga y reemplazo de variantes de fondo.
  - `[x] Cámara Global (God View - 4320x4320)`: Desancla la cámara del jugador conmutando a la `CamaraDios` dedicada (zoom $0.225\times$) presente en `maain.tscn` (o adaptando el zoom y smoothing de `target_camara` en escenas aisladas).
  - Persistencia y soporte en backend para control de parpadeo (`flicker_forzado`) en `ControladorLinterna`.
* **Capas de Depuración en Mundo (`DebugOverlay`):**
  - Ejes cartesianos divisores $X=0, Y=0$ y marco perimetral de la arena ($4320\times 4320$) con etiquetas identificadoras de cada sector.
  - Corredores de seguridad de $160\text{ px}$ ($80\text{ px}$ a cada lado de los ejes divisores) renderizados en franjas verdes translúcidas con bordes marcados.
  - Puntos de nota registrados en el grupo `"puntos_nota"` dibujados con círculos y arcos dorados cuya escala se adapta automáticamente al nivel de zoom de la cámara.

### 4.3. Pestaña Monstruo e IA
* **Telemetría de Caza:**
  - Estado del comportamiento (`Persiguiendo objetivo` con sufijo de visión vs `Sin objetivo` o `No encontrado`).
  - Posición global y cuadrante actual del enemigo.
  - Distancia euclidiana en píxeles al jugador.
  - Velocidad escalar instantánea en $\text{px/s}$.
  - Diagnóstico de anti-atascamiento: reporta `Colisión activa` (si `is_on_wall()` es verdadero) o `Libre / Transitable`.
* **Acciones:**
  - Botón **"Reubicar Monstruo a Cuadrante Opuesto"**: Teletransporta instantáneamente al monstruo hacia el cuadrante simétrico opuesto a la posición actual del jugador, garantizando una distancia de seguridad mínima de $300\text{ px}$.
  - `[x] Línea de Visión / Vector IA (Raycast)`: Conmuta `debug_dibujar_rayo` en el monstruo, activando en tiempo real el componente táctico [`DepuradorVisualEnemigo`](../../scripts/entidades/enemigo/depurador_visual_enemigo.gd):
    - Círculo de área de captura letal (`Enemigo.RADIO_AREA_CAPTURA` = $56\text{ px}$).
    - Arco de colisión física sólida (`Enemigo.RADIO_COLISION_CUERPO` = $42\text{ px}$).
    - Vector flecha de velocidad instantánea escalado según la magnitud de movimiento.
    - RayCast de línea de visión hacia el jugador (verde si la visión es directa, rojo con punto de impacto si está obstruida).
    - Estela de trayectoria con degradado alfa (*breadcrumbs* dinámicos de las últimas 45 muestras de posición).

### 4.4. Pestaña Sistema, Audio y Persistencia
* **Rendimiento y Control de Tiempo:**
  - Telemetría en vivo de tasa de refresco (`FPS`) y consumo de memoria estática en megabytes (`MB`).
  - Indicador de escala temporal (`Engine.time_scale`).
  - Botones de preajuste de velocidad de simulación: `0.5x`, `1.0x` y `2.0x`.
  - Botón **"Reiniciar Escena"**: Recarga atómica de la escena actual (`get_tree().reload_current_scene()`) asegurando restablecer `paused = false`.
* **Audio y Música Interactiva (Issue #28):**
  - Telemetría en tiempo real: estado FSM (`SILENCIO`, `MENU_TUTORIAL`, `SUPERVIVENCIA`, `GAME_OVER`), clip interactivo activo y volumen del bus `&"musica"` en `dB` (con indicador de atenuación si el juego está en pausa).
  - Botones de conmutación directa: `Menú/Tutorial`, `Supervivencia (NEXT_BEAT)`, `Jumpscare (0 ms)`, `Game Over` y `Restaurar Parámetros` para recuperar los niveles base.
  - Sliders de live-tweaking vinculados a `ConfiguracionMusica`: ajuste de volumen base en `dB`, atenuación por pausa en `dB` y factor de pitch en Game Over.
* **Persistencia y Récord (Issue #35):**
  - Lectura en vivo del High Score (máximo de notas) desde `GestorPersistencia`.
  - Botón **"Resetear High Score"**: Borra el récord acumulado tanto en disco (`user://progreso.json`) como en la API de persistencia web (`LocalStorage`).
