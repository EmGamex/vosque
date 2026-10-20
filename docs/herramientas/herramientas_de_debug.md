# Sistema de Herramientas de Depuración y Diagnóstico (Debug)

Este documento detalla la arquitectura, herramientas, controles y flujos de trabajo del ecosistema de depuración y calibración de **Vosque**. El objetivo es proporcionar al equipo de desarrollo una visibilidad total sobre la simulación física, la mutación procedural del mapa y el comportamiento de la IA sin interrumpir el flujo de juego.

---

## 1. Filosofía y Principios de Diseño

1. **Inmediatez y Control Centralizado:** En lugar de memorizar múltiples teclas de función o abrir interfaces dispersas, todas las utilidades de diagnóstico convergen en un **Menú Unificado de Debug** accesible mediante una única tecla (<kbd>F3</kbd>).
2. **Arquitectura No Invasiva y Desacoplada:** El sistema de debug escucha e inspecciona los nodos del juego (`personaje`, `escenario`, `enemigo`) mediante verificaciones seguras (`has_method()`, variables condicionales y referencias nulas). Si un nodo o componente aún no ha sido implementado o instanciado, la herramienta no provoca errores ni interrupciones (*graceful degradation*).
3. **Persistencia Trans-Sesión (`DebugConfig` Autoload):** Los ajustes de depuración (toggles visuales, cheats, velocidades calibradas y time_scale) se conservan a través de `/root/DebugConfig` (`scripts/debug_config.gd`), impidiendo que se reinicien al recargar la escena, reiniciar la partida o disparar Game Over.
4. **Simulación en Tiempo Real y Diagnóstico Nativo:** Por defecto, abrir la consola de debug no pausa el motor, permitiendo observar cómo reaccionan las físicas, los estados del jugador y las mutaciones del escenario mientras se interactúa con el mundo. Asimismo, se expone telemetría directa al depurador nativo de Godot 4 (`Performance` custom monitors y visor de árbol remoto).
5. **Seguridad en Entornos de Producción:** Las rutinas de dibujo y captura de eventos de debug están condicionadas para ignorarse o suprimirse automáticamente en compilaciones finales de exportación web (`OS.is_debug_build()`).

---

## 2. Mapa de Controles y Estados de Visualización

El acceso al sistema de depuración se gestiona mediante un ciclo **Tri-Estado** controlado por la tecla <kbd>F3</kbd>:

```
┌────────────────┐      <F3>      ┌────────────────┐      <F3>      ┌─────────────────────┐
│  1. OCULTO     │  ───────────>  │  2. MINI-HUD   │  ───────────>  │  3. MENÚ COMPLETO   │
│ (Juego Limpio) │  <───────────  │   (Esquina)    │  <───────────  │ (Consola Pestañas)  │
└────────────────┘      <F3>      └────────────────┘      <F3>      └─────────────────────┘
```

| Estado | Descripción | Casos de Uso |
| :--- | :--- | :--- |
| **1. Oculto** | La interfaz está desactivada (`visible = false`). No genera sobrecarga visual ni consume tiempo de dibujo. | Partida arcade estándar, capturas de pantalla, playtesting de inmersión. |
| **2. Mini-HUD** | Widget compacto anclado en la esquina superior derecha. Muestra FPS, consumo de memoria, cuadrante actual del jugador, velocidad instantánea y estamina. | Pruebas de rendimiento, calibración de locomoción sin obstruir la vista central del juego. |
| **3. Menú Completo** | Panel modular con pestañas interactivas, botones de acción rápida, selectores y controles de diagnóstico visual (`_draw`). | Pruebas de mutación espacial, forzado de estados de IA, análisis de colisiones y cheats de prueba. |

> [!TIP]
> Dentro del **Menú Completo**, existe un selector `[x] Pausar Simulación`. Si se activa, el árbol del juego se pausa (`get_tree().paused = true`), permitiendo inspeccionar valores estáticos exactos en un frame determinado.

---

## 3. Menú Unificado de Debug In-Game (`escenas/debug_menu.tscn`)

La escena maestra del menú de depuración reside en `escenas/debug_menu.tscn` (controlada por la arquitectura modular en `scripts/debug_menu/debug_menu.gd`) y está estructurada en un `CanvasLayer` con prioridad alta (`layer = 100`).

Los componentes del menú están desacoplados en la carpeta `scripts/debug_menu/`:
- `debug_menu.gd`: Fachada y orquestador del `CanvasLayer`.
- `debug_context.gd`: Resolución y caché de referencias a nodos diana y cálculo de cuadrantes.
- `debug_cheats_controller.gd`: Gestión de estamina infinita e invencibilidad (`god_mode`).
- `debug_physics_controller.gd`: Live tweaking de velocidades, aceleración y escalado proporcional.
- `debug_scenario_controller.gd`: Gestión de God View (cámara cenital) y mutación forzada de escenario.
- `debug_enemy_controller.gd`: Tácticas de IA, rayo de visión y reubicación de la criatura.
- `debug_system_controller.gd`: TimeScale, pausa y recarga de escena.
- `debug_telemetry_presenter.gd`: Formateo de métricas para MiniHUD, pestañas y pad direccional.
- `debug_custom_monitors.gd`: Monitores de rendimiento personalizados de Godot Engine.
- `debug_overlay.gd`: Dibujo vectorial en coordenadas de mundo (corredores de 160 px y cuadrantes).

```text
DebugMenu (CanvasLayer, layer=100)
├── MiniHUD (PanelContainer en esquina superior derecha)
├── ConsolaPrincipal (PanelContainer modal semi-transparente)
│   ├── Encabezado (Título, FPS, Botón Cerrar, Toggle Pausa)
│   └── TabContainer
│       ├── TabJugador (Telemetría, Pad Direccional, Cheats)
│       ├── TabEscenario (Cuadrantes, Mutación, God View, Corredores 160px)
│       ├── TabEnemigo (Telemetría IA, Anti-Atascamiento, Reubicación)
│       └── TabSistema (TimeScale, Reinicio de Escena, Notas)
└── DebugOverlay (Node2D con dibujo vectorial en espacio de mundo)
```

### 3.1. Pestaña: Jugador y Físicas
Monitorea la máquina de estados del protagonista y sus variables cinemáticas:
* **Lectura en tiempo real:**
  - Velocidad actual escalar y desglosada en componentes vectoriales $(X, Y)$.
  - Velocidad máxima configurada (`speed`), aceleración (`acceleration`) y fricción (`friction`).
  - Estado cinemático reportado (`REPOSO`, `CAMINANDO`, `CORRIENDO`, `SALTANDO`, `PLANCHA`, `AGOTADO`).
  - Estamina actual vs. máxima y porcentaje restante.
* **Pad Direccional Visual:** Matriz de 8 direcciones que resalta en azul claro las entradas recibidas por el `InputServer`.
* **Cheats y Asistencias de Prueba:**
  - `Estamina Infinita`: Evita el vaciado de la barra para probar desplazamientos continuos a $1000\text{ px/s}$.
  - `Invencibilidad (God Mode)`: Ignora la colisión letal con el monstruo.
* **Panel Desplegable de Velocidades y Físicas (*Foldout Live Tweak*):**
  - **Botón Desplegable:** Alterna la visualización del panel (`▶ Ajustes de Velocidad y Físicas (Desplegar)` / `▼ Ajustes de Velocidad y Físicas (Ocultar)`), manteniendo la consola compacta.
  - **Modo Automático Proporcional:** Casilla `[x] Modo Automático: Mantener relación proporcional con velocidad base`. Al variar `speed` (caminar), escala automáticamente sprint, aceleración, fricción y plancha de forma matemática y equilibrada.
  - **Modo Manual:** Al desmarcar la casilla, permite calibrar individualmente cada magnitud.
  - **Sliders con Indicador en Tiempo Real:**
    - Caminar (`speed`): 50 a 3000 px/s (paso 10).
    - Sprint (`sprint_speed`): 50 a 3000 px/s (paso 10).
    - Aceleración (`acceleration`): 100 a 20,000 px/s² (paso 50).
    - Fricción (`friction`): 100 a 20,000 px/s² (paso 50).
    - Plancha (`dive_speed`): 100 a 4000 px/s (paso 50).
  - Botón **"Restablecer Velocidades por Defecto"** para restaurar los valores base del personaje en cualquier momento.

### 3.2. Pestaña: Escenario y Mutación Espacial (Issue #3)
Diseñada específicamente para controlar y verificar la cuadrícula simétrica $2 \times 2$ ($4320 \times 4320\text{ px}$ en total, con cuadrantes de $2160 \times 2160\text{ px}$):
* **Telemetría de Cuadrantes:**
  - Identificación del cuadrante activo del jugador: `NO`, `NE`, `SO` o `SE` según las coordenadas globales respecto al centro `(0, 0)`.
  - Nombre de la sub-escena o variante instanciada en cada uno de los 4 sectores.
* **Disparador Manual de Mutación:**
  - Botón **"Forzar Mutación de Sectores Lejanos"**: Reemplaza instantáneamente las variantes de los 3 cuadrantes donde el jugador *no* se encuentra, permitiendo validar la lógica de carga procedural sin necesidad de recoger físicamente una nota.
* **Control de Niebla de Transición e Iluminación:**
  - Casilla `[x] Desactivar Niebla`: Anula la cortina visual radial para poder observar en tiempo real la instanciación de las variantes sin oscurecimiento artificial. Incorpora protección anti-bloqueo (*failsafe*), emitiendo de inmediato las señales de sincronización para que ninguna corrutina quede colgada.
  - Casilla `[x] Modo Fullbright (Sin Oscuridad)`: Desactiva temporalmente el nodo `CanvasModulate` o aplica `Viewport.DEBUG_DRAW_UNSHADED` para inspeccionar la totalidad del mapa iluminado al 100% durante el diseño y prueba de sectores en God View.
* **Cámara Cenital Global (God View):**
  - Desancla la `Camera2D` del protagonista y aplica un zoom exterior (`Vector2(0.225, 0.225)`) para encuadrar la totalidad de la arena ($4320 \times 4320\text{ px}$), permitiendo observar la mutación de los 3 cuadrantes en vivo.
* **Capas de Depuración Visual (`_draw` en `DebugOverlay`):**
  - `Mostrar Ejes Divisores`: Dibuja los ejes $X = 0$ e $Y = 0$ y los límites perimetrales.
  - `Mostrar Corredores de Seguridad`: Dibuja las franjas de $160\text{ px}$ ($80\text{ px}$ a cada lado del borde interior de cada cuadrante) en color verde translúcido. Si un obstáculo sólido penetra la franja, se resalta en rojo.
  - `Mostrar Puntos de Nota y Filtros de Spawner`: Diagnóstico espacial de los nodos `Marker2D` del grupo `"puntos_nota"`:
    - **Verde**: Marcadores candidatos válidos para el próximo spawn (cumplen pertenecer a un cuadrante mutado, $\ge 600\text{ px}$ al jugador y $\ge 800\text{ px}$ al monstruo).
    - **Rojo**: Marcadores descartados (sector del jugador o dentro de radios de exclusión).
    - **Ámbar / Cian**: Marcador reservado para el desatasco de la criatura.
    - **Dorado Pulsante**: Ubicación de la nota activa en la escena.

### 3.3. Pestaña: Monstruo y Comportamiento de IA
Herramientas para validar el seguimiento y el protocolo anti-atascamiento:
* **Telemetría de Persecución:**
  - Posición global $(X, Y)$ y cuadrante ocupado por la criatura.
  - Distancia euclidiana respecto al protagonista en píxeles.
  - Estado de visión: `Visión directa` (rayo verde) vs. `Obstruido` (rayo rojo al punto de impacto + línea discontinua).
* **Diagnóstico Anti-Atascamiento:**
  - Indicador de colisión sólida (`is_on_wall()`).
* **Control de Comportamiento y Fases de Dificultad:**
  - Casilla `[x] Congelar IA / Inactivo`: Desactiva la persecución del monstruo (`velocity = Vector2.ZERO`, `AreaCaptura.monitoring = false`) para permitir pruebas libres de movimiento y saltos sin acoso.
  - Selector de Fase / Escalón de Amenaza (Nota 0 a 10+): Permite calibrar en caliente la velocidad del monstruo saltando directamente a cualquier escalón de `VELOCIDADES_MONSTRUO` ($0 \to 500 \to 580 \dots 920\text{ px/s}$) para verificar la jugabilidad en fases tardías sin requerir recolección manual.
* **Visualización Táctica (`[x] Rayo de Visión y Vectores de IA`):**
  - **Estela de Trayectoria (*Breadcrumbs*):** Buffer de los últimos 2 segundos de desplazamiento con degradado alfa para inspeccionar cómo sortea esquinas.
  - **Radio de Captura Letal:** Círculo rojo de $56.0\text{ px}$ correspondiente al `AreaCaptura`.
  - **Radio de Colisión Sólida:** Círculo ámbar de $42.0\text{ px}$ correspondiente al `CollisionShape2D`.
  - **Vector de Velocidad:** Flecha directriz proporcional a la magnitud y dirección de aceleración.
  - **Escalado Adaptativo:** Los trazos y radios se adaptan automáticamente al zoom de la cámara (tanto en vista del jugador como en *God View*).
* **Acciones Rápidas:**
  - Botón **"Reubicar Monstruo"**: Teletransporta a la criatura al cuadrante opuesto (o distancia segura).

### 3.4. Pestaña: Sistema, Notas, Game Feel y Persistencia
* **Control de Tiempo (`Engine.time_scale`):**
  - Botones de preajuste: `0.2x` (cámara súper lenta para analizar saltos parabólicos sobre obstáculos bajos de Capa 2), `0.5x`, `1.0x` (velocidad normal) y `2.0x` (prueba de estrés).
* **Gestión de Notas Coleccionables y Spawner:**
  - Contador numérico de notas recogidas sincronizado con el HUD.
  - Botón **"Simular Recogida de Nota"**: Incrementa el contador, dispara la señal de progresión de dificultad y desencadena la mutación del escenario.
  - Botón **"Teletransportar a Nota Activa"**: Mueve al jugador a la posición del coleccionable activo para probar instantáneamente la recolección, SFX y feedback visual.
* **Calibrador de Trauma de Cámara (Game Feel):**
  - Inyectores manuales de estrés para evaluar sacudidas y decaimiento cuadrático:
    - Botón `+0.20 Trauma` (Vibración leve).
    - Botón `+0.35 Trauma` (Impacto de plancha / *Dive*).
    - Botón `+1.00 Trauma` (Sacudida máxima de Jumpscare / Muerte).
* **Gestión de Persistencia (High Score):**
  - Botón **"Resetear High Score Guardado"**: Borra el récord histórico almacenado en `user://highscore.save` y en `localStorage` (Web) para realizar pruebas limpias de primera partida.
* **Acciones de Sesión y Reinicio Rápido:**
  - Botón **"Reiniciar Partida"**: Si la raíz del proyecto es `GestorEscenas`, invoca de forma segura `GestorEscenas.iniciar_partida()` para recrear la pantalla de juego limpia directamente sin expulsar al usuario al menú de inicio. En escenas aisladas, ejecuta `get_tree().reload_current_scene()`.

---

## 4. Herramientas de Editor (Plugins de Godot)

Además de las herramientas in-game, el proyecto cuenta con plugins contextuales para el editor de Godot en `addons/`:

### 4.1. Toolbar de Personaje (`addons/personaje_tools`)
* Se activa automáticamente en el menú superior del viewport 2D (`CONTAINER_CANVAS_EDITOR_MENU`) cuando se selecciona un nodo `CharacterBody2D` que contenga las propiedades cinemáticas de *Vosque*.
* Permite ajustar de forma visual mediante *SpinBoxes* la velocidad máxima, aceleración y fricción con persistencia directa en la escena.

### 4.2. Linter y Guías de Nivel de Escenario (`addons/escenario_tools` - Planificado)
Diseñado para la creación de variantes de sector en `escenas/sectores/variantes/`:
* **Dibujo de Guías de Corredores:** Traza automáticamente en el editor el marco de variante de $2160 \times 2160\text{ px}$ y las zonas de exclusión de $80\text{ px}$ interiores.
* **Validador Estático de Variante:**
  - Confirma que ningún `StaticBody2D` esté colocado en los corredores de borde.
  - Comprueba que los obstáculos usen las capas correctas: Capa 1 para obstáculos altos y Capa 2 para obstáculos bajos.
  - Verifica que existan entre 2 y 4 nodos `Marker2D` en el grupo `"puntos_nota"`.

### 4.3. Servidor de Automatización (`addons/godot_ai`)
* Servidor MCP integrado que permite consultar la jerarquía de nodos, inspeccionar propiedades, capturar pantallas del editor y validar sintaxis de GDScript en caliente.

### 4.4. Monitores Personalizados del Depurador de Godot (`Performance`)
* Se integran automáticamente al arrancar el juego en modo desarrollo (`OS.is_debug_build()`) bajo la categoría `Vosque/` a través de [`scripts/debug_menu/debug_custom_monitors.gd`](../../scripts/debug_menu/debug_custom_monitors.gd).
* Visibles en el panel inferior del editor de Godot: **Depurador > Monitores**:
  - `Vosque/Estamina Jugador`: Monitoreo en tiempo real del gasto y recuperación de estamina ($0.0 - 100.0$).
  - `Vosque/Velocidad Jugador`: Magnitud escalar instantánea de la velocidad del personaje en $\text{px/s}$.
  - `Vosque/Velocidad Enemigo`: Velocidad instantánea de persecución de la criatura.
  - `Vosque/Distancia Monstruo`: Distancia euclidiana en píxeles entre el jugador y el monstruo.
  - `Vosque/Estado Jugador`: Identificador numérico del estado cinemático (`REPOSO: 0`, `CAMINANDO: 1`, `SPRINT: 2`, `FATIGA: 3`, `SALTO: 4`, `PLANCHA: 5`, `RECUPERACIÓN: 6`).
  - `Vosque/Notas Recogidas`: Conteo histórico de páginas recogidas para correlacionar con los picos de velocidad de la IA.
  - `Vosque/Trauma Camara`: Nivel de estrés cuadrático de la `Camera2D` ($0.0 - 1.0$) y su decaimiento lineal.
  - `Vosque/Nodos Huerfanos`: Seguimiento de `Performance.OBJECT_ORPHAN_NODE_COUNT` para garantizar que la destrucción e instanciación de cuadrantes no provoque fugas de memoria (*memory leaks*).

### 4.5. Modos de Renderizado y Colisiones en Caliente (`Viewport` & `SceneTree`)
* Acceso directo desde la pestaña Sistema o atajos internos para auditar el rendimiento y físicas sin reiniciar el proyecto:
  - **Formas de Colisión Visibles en Caliente:** Alterna dinámicamente las formas físicas del motor para comprobar la desactivación de la Capa 2 (`Obstaculos_Bajos`) durante el vuelo del salto libre.
  - **Overdraw & Unshaded (`Viewport.debug_draw`):**
    - `DEBUG_DRAW_UNSHADED`: Ignora la iluminación 2D (`CanvasModulate` y `PointLight2D`) para revisar geometría pura.
    - `DEBUG_DRAW_OVERDRAW`: Muestra el solapamiento de capas transparentes para auditar el impacto de la niebla y partículas en navegadores web.

### 4.6. Bitácora de Decisiones Estructurada en Consola (`print_rich` BBCode)
Para diagnosticar eventos que ocurren en milisegundos bajo la niebla sin saturar la consola:
* Registro coloreado de mutación:
  ```text
  [MUTACIÓN] Cuadrante Jugador: NO | Variantes instanciadas: NE(bosque_denso), SO(claro_rocoso), SE(sendero_troncos)
  [ANTI-ATASCO] Monstruo solapado en SO -> Reubicado a Marker2D seguro (distancia a jugador: 950 px)
  [SPAWNER] Candidatos: 9 | Descartados: 5 (<600px jug / <800px mon) | Nota activa instanciada en SE/MarkerNota1
  ```

### 4.7. Nomenclatura Limpia en el Árbol Remoto (`Depurador > Escena > Remoto`)
* Al mutar variantes en [`escenario.gd`](../../scripts/escenario.gd), el nodo recién instanciado se nombra semánticamente (`nueva_instancia.name = "Activa_" + nombre_variante`).
* **Beneficio:** Al inspeccionar el árbol en vivo en la pestaña **Remoto** de Godot, se visualiza de inmediato qué variante compone cada cuadrante (ej. `SectorNO/Activa_variante_claro_rocoso`) evitando identificadores anónimos de motor (`@Node2D@2`).

---

## 5. Protocolo de Pruebas y Validación para la Issue #3

Para verificar que la infraestructura del escenario y la mutación espacial funcionan según las especificaciones técnicas:

1. **Iniciar la escena de prueba** (`escenas/maain.tscn`).
2. **Abrir la consola de depuración** presionando <kbd>F3</kbd> dos veces (hasta acceder al Menú Completo).
3. **Seleccionar la pestaña "Escenario":**
   - Activar la casilla `[x] Mostrar Corredores de Seguridad (160 px)` y verificar visualmente que las fronteras $X=0, Y=0$ permanezcan despejadas.
   - Activar `[x] Vista Global (God View)` para visualizar los cuatro cuadrantes simultáneamente.
   - Presionar reiteradamente el botón **"Forzar Mutación de Sectores Lejanos"**:
     - Confirmar que el cuadrante donde se encuentra el jugador **nunca** es reemplazado.
     - Confirmar que los otros 3 cuadrantes cambian aleatoriamente de sub-escena sin generar tirones ni errores de referencia en el registro de salida.
4. **Validación del Protocolo Anti-Atascamiento:**
   - Cambiar a la pestaña "Enemigo".
   - Presionar "Forzar Mutación" mientras el monstruo está en uno de los 3 cuadrantes que cambian.
   - Verificar que si el nuevo diseño genera una colisión sobre el enemigo, el sistema lo reubique de inmediato al `Marker2D` seguro más cercano.
