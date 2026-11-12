# Gestor de Ventanas de Depuración In-Game (F3)

Este documento detalla la arquitectura, controles, ventanas modulares y flujo de trabajo del sistema de depuración in-game de **Vosque**.

> 💻 **Escena maestra:** `escenas/debug_menu.tscn`  
> 💻 **Fachada principal:** [`scripts/debug/debug_menu/debug_menu.gd`](../../scripts/debug/debug_menu/debug_menu.gd)  
> 💻 **Ventana base reutilizable:** [`scripts/debug/debug_menu/debug_window.gd`](../../scripts/debug/debug_menu/debug_window.gd) y `escenas/debug/debug_window.tscn`  
> 🛠️ **Sub-escenas de ventanas:** `escenas/debug/ventanas/`  
> 🛠️ **Plugins y monitores:** [Plugins de Editor y Monitores](plugins_editor_y_mcp.md)  
> 🧪 **Guías de prueba:** [Protocolos de Prueba](protocolos_de_prueba.md)

---

## 1. Filosofía y Principios de Diseño

1. **Gestor de Ventanas (Debug Workspace):** En lugar de un panel modal monolítico rígido, la consola de debug opera como un entorno de ventanas flotantes desacopladas que pueden abrirse, minimizarse, cerrarse y arrastrarse libremente por pantalla.
2. **Modo Pin / HUD Interactivo (`📌`):** Cualquier ventana puede fijarse en pantalla. Al volver al Modo Juego, las ventanas fijadas permanecen visibles de forma semitransparente e interactivas, permitiendo monitorear o ajustar valores en tiempo real mientras juegas sin obstruir la visibilidad.
3. **Persistencia Trans-Sesión (`DebugConfig` Autoload):** El estado de cada ventana (`abierta`, `fijada`, `colapsada` y `posicion`), junto con los ajustes de físicas, toggles y cheats, se conserva en `/root/DebugConfig` (`scripts/debug/debug_config.gd`). Al recargar la escena o reiniciar tras un Game Over, el espacio de trabajo se restaura intacto.
4. **Desacoplamiento Estricto por Sub-Escenas:** Cada grupo funcional cuenta con su propia escena empaquetada e independiente (`escenas/debug/ventanas/ventana_debug_*.tscn`), eliminando el acoplamiento frágil de rutas de nodos anidados.
5. **Simulación en Tiempo Real y Cero Sobrecarga en Modo Oculto:** Abrir el dock no pausa el juego salvo que se active explícitamente `Pausar`. Cuando no hay ventanas fijadas ni overlays activos, el `CanvasLayer` completo se apaga, eliminando cualquier coste de renderizado.

---

## 2. Mapa de Controles y Ciclo Bi-Estado (<kbd>F3</kbd>)

El acceso y navegación del menú se gestiona mediante <kbd>F3</kbd>:

```text
┌──────────────────────────────────────────────────┐      <F3>      ┌──────────────────────────────────────────────────┐
│                  MODO JUEGO                      │  ───────────>  │                  MODO EDICIÓN                    │
│ • Barra Dock oculta.                             │  <───────────  │ • Barra Dock superior visible.                   │
│ • Ventanas normales ocultas.                     │      <F3>      │ • Todas las ventanas abiertas visibles (100% α). │
│ • Ventanas con pin (📌) activas (75% α).        │    o <Esc>     │ • Arrastre libre, presets y ordenación mosaico.  │
└──────────────────────────────────────────────────┘                └──────────────────────────────────────────────────┘
```

| Estado | Descripción | Casos de Uso |
| :--- | :--- | :--- |
| **Modo Juego** | El Dock se oculta. Si no hay ventanas fijadas (`📌`) ni overlays activos, el CanvasLayer se apaga. Si hay ventanas fijadas, se muestran atenuadas (75% de opacidad) pero interactivas. | Playtesting continuo, calibración de físicas en movimiento y monitoreo táctico sin pausa. |
| **Modo Edición** | Despliega la barra superior `BarraDock` y muestra todas las ventanas activas con opacidad normal. Permite arrastrar, redimensionar, alternar pines y usar presets. | Configuración del espacio de trabajo, pruebas de mutación, cheats y reorganización. |

> [!TIP]
> Dentro del **Modo Edición**, presionar <kbd>Escape</kbd> cierra inmediatamente la barra Dock volviendo a Modo Juego y consume el evento (`set_input_as_handled()`), evitando desplegar accidentalmente el `MenuPausa` del juego.

---

## 3. Arquitectura Modular del Menú

El sistema se estructura en componentes aislados coordinados por `DebugMenu`:

```text
DebugMenu (CanvasLayer, layer=100) [scripts/debug/debug_menu/debug_menu.gd]
├── DebugContext [debug_context.gd] (Resolución segura de targets y cuadrantes)
├── DebugTelemetryPresenter [debug_telemetry_presenter.gd] (Formateo desacoplado de telemetría)
├── DebugCustomMonitors [debug_custom_monitors.gd] (Monitores nativos en Performance)
├── ControlRaiz (Control, full rect)
│   ├── BarraDock (PanelContainer superior)
│   │   ├── Título + Separadores
│   │   ├── Toggles de Ventanas: [🏃 Jugador] [⚙️ Físicas] [🌲 Escenario] [👾 Enemigo] [🎵 Audio] [📊 Sistema]
│   │   ├── OptionPresets (Selector de Presets Rápidos)
│   │   ├── BtnOrdenarMosaico (Reorganiza en cuadrícula en pantalla)
│   │   ├── CheckPausar (Comparte el árbol de pausa de SceneTree)
│   │   └── BtnCerrarDock (✕ [F3])
│   └── ContenedorVentanas (Control, mouse_filter = IGNORE)
│       ├── VentanaJugador (DebugWindow -> ventana_debug_jugador.tscn)
│       ├── VentanaFisicas (DebugWindow -> ventana_debug_fisicas.tscn)
│       ├── VentanaEscenario (DebugWindow -> ventana_debug_escenario.tscn)
│       ├── VentanaEnemigo (DebugWindow -> ventana_debug_enemigo.tscn)
│       ├── VentanaAudio (DebugWindow -> ventana_debug_audio.tscn)
│       └── VentanaSistema (DebugWindow -> ventana_debug_sistema.tscn)
└── DebugOverlay (Node2D) ──> debug_overlay.gd (Dibujo perimetral, cuadrantes y corredores)
```

---

## 4. Componente Base `DebugWindow`

Cada ventana flotante hereda de [`DebugWindow`](../../scripts/debug/debug_menu/debug_window.gd) (`PanelContainer`):
* **Barra de Título:**
  * **Arrastre (*Drag & Drop*):** Al pulsar y arrastrar la barra de título, la ventana se desplaza fluidamente sin salirse de los límites del viewport. Al hacer clic, la ventana se envía al frente (`move_to_front()`).
  * **Botón Fijar (`📌` / `📍`):** Alterna el anclaje trans-estado. Si está fijada, se conservará en pantalla durante el Modo Juego.
  * **Botón Minimizar (`_` / `+`):** Colapsa el contenido de la ventana dejando únicamente visible la barra de título, auto-ajustando su tamaño (`reset_size()`).
  * **Botón Cerrar (`✕`):** Oculta la ventana y actualiza su estado persistente en `DebugConfig`.

---

## 5. Catálogo de Ventanas Especializadas

### 5.1. 🏃 Jugador & Cheats (`ventana_debug_jugador.tscn`)
* **Telemetría de Locomoción:** Velocidad escalar y vectorial, velocidad máxima, aceleración, fricción, estado de la FSM, posición global, cuadrante actual y estamina.
* **Pad Direccional Visual:** Matriz 3x3 que resalta en tiempo real las pulsaciones de movimiento (`personaje-izquierda`, `personaje-derecha`, etc.).
* **Cheats:**
  - `Estamina Infinita`: Previene el vaciado y la fatiga del personaje.
  - `Invencibilidad (God Mode)`: Ignora daño y desactiva la colisión letal con el monstruo.

### 5.2. ⚙️ Calibrador de Físicas (`ventana_debug_fisicas.tscn`)
* **Live Tweaking de Locomoción:**
  - Sliders para velocidad base (`speed`), sprint (`sprint_speed`), aceleración (`acceleration`), fricción (`friction`) y salto/plancha (`dive_speed`).
  - `[x] Escalado Proporcional`: Calibra armónicamente el sprint, aceleración y fricción al modificar la velocidad base.
  - **Restaurar Defecto:** Restablece instantáneamente las constantes de diseño base del personaje.
* *Caso de uso ideal:* Fijar con `📌` en una esquina y correr por el bosque ajustando los sliders en caliente.

### 5.3. 🌲 Escenario & Mutación (`ventana_debug_escenario.tscn`)
* **Telemetría de Sectores:** Variantes procedurales activas en los cuadrantes `NO`, `NE`, `SO` y `SE`.
* **Forzar Mutación:** Ejecuta inmediatamente la mutación procedural sin requerir recoger notas.
* **Toggles de Cámara y Visuales:**
  - `[x] Desactivar Niebla de Mutación`: Permite inspeccionar en claro la transición de variantes.
  - `[x] Cámara Global (God View)`: Conmuta a la `CamaraDios` ($4320 \times 4320$, zoom $0.225\times$).
  - `[x] Mostrar Corredores de Seguridad`: Dibuja las franjas verdes de $160\text{ px}$ en torno a los ejes $X=0, Y=0$.
  - `[x] Mostrar División de Cuadrantes`: Dibuja los ejes cartesianos y etiquetas de sector.

### 5.4. 👾 Monstruo & IA (`ventana_debug_enemigo.tscn`)
* **Telemetría de Persecución:**
  - Estado FSM de caza, posición, distancia euclidiana en píxeles, velocidad del monstruo y diagnóstico de colisión/atascamiento.
* **Acciones Tácticas:**
  - **Reubicar Monstruo a Cuadrante Opuesto:** Teletransporta al enemigo al sector simétrico opuesto al jugador respetando una distancia mínima de $300\text{ px}$.
  - `[x] Línea de Visión / Vector IA (Raycast)`: Conmuta el componente `DepuradorVisualEnemigo` (área de captura letal de $56\text{ px}$, círculo sólido de $42\text{ px}$, vector flecha de velocidad, RayCast con punto de impacto y estela de migas de pan).
  - `[x] Pausar IA del Monstruo`: Detiene únicamente la persecución (`velocity = Vector2.ZERO`) y desactiva la captura letal de la criatura manteniendo activa la simulación del jugador y del entorno; su estado persiste en `DebugConfig.debug_pausar_ia_enemigo` y `ValEstadoIA` muestra `"IA Pausada"`.

### 5.5. 🎵 Audio & Música (`ventana_debug_audio.tscn`)
* **Telemetría Musical (Issue #28):** Estado FSM (`SILENCIO`, `MENU_TUTORIAL`, `SUPERVIVENCIA`, `GAME_OVER`), clip activo y volumen del bus `&"musica"` en `dB`.
* **Conmutación Rápida:** Botones para forzar estados `Menú`, `Supervivencia`, `Jumpscare`, `Game Over` y `Restaurar`.
* **Sliders de Calibración:** Ajuste en caliente de volumen base en `dB`, atenuación por pausa y pitch de Game Over.

### 5.6. 📊 Sistema & Rendimiento (`ventana_debug_sistema.tscn`)
* **Telemetría del Motor:** FPS instantáneos, memoria estática en MB y escala temporal (`time_scale`).
* **Control de Tiempo:** Botones de preajuste `0.5x`, `1.0x` y `2.0x`.
* **Reinicio de Escena:** Recarga limpia de la escena activa restableciendo el estado de pausa.
* **Persistencia y Récord (Issue #35):** Lectura del High Score acumulado y botón para resetearlo en disco y almacenamiento web.

---

## 6. Presets Rápidos y Distribución en Mosaico

Desde el selector `OptionPresets` de la barra superior `BarraDock`, se pueden aplicar configuraciones con un solo clic:
* **Locomoción & Físicas:** Abre la ventana de *Jugador* y deja fijada (`📌`) la ventana de *Físicas*.
* **Caza & Enemigo IA:** Abre la ventana de *Jugador* y fija (`📌`) la ventana de *Monstruo & IA* para playtesting de persecución.
* **Mundo & Mutación:** Fija la ventana de *Escenario* para inspección visual y mutación.
* **Audio & Sistema:** Dispone las ventanas de *Audio* y *Sistema* lado a lado.
* **Cerrar Todas:** Oculta y desancla todas las ventanas para limpiar el espacio de trabajo.
* **Botón "Ordenar":** Reorganiza automáticamente todas las ventanas abiertas en una cuadrícula ordenada de izquierda a derecha sin solapamientos.
