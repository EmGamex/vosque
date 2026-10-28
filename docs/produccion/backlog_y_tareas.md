# Backlog y Tareas de Producción

Este documento contiene el desglose granular de tareas técnicas, de arte y de diseño para *Vosque*, organizado por módulos funcionales y con criterios de aceptación explícitos basados en el GDD.

---

## Leyenda de Estados
- `[x]` **Completado:** Funcionalidad implementada y validada en motor.
- `[-]` **En Curso:** En proceso de implementación activa.
- `[ ]` **Pendiente:** Especificado en diseño pero pendiente de programación o creación de assets.

---

## 1. Módulo: Personaje y Habilidades
> 📄 **Especificación de referencia:** [`docs/gameplay/personaje_y_habilidades.md`](../gameplay/personaje_y_habilidades.md)  
> 💻 **Archivos clave:** [`scripts/personaje.gd`](../../scripts/personaje.gd), [`escenas/personaje.tscn`](../../escenas/personaje.tscn)

- [x] **Locomoción 8 Direcciones:** Movimiento con vector normalizado, aceleración (`5000 px/s²`), fricción y freno seco (`stop_threshold = 15.0 px/s`).
- [x] **Telemetría F3 y Calibración:** Panel de depuración in-game y plugin de editor contextual [`addons/personaje_tools`](../../addons/personaje_tools).
- [x] **Mecánica de Sprint y Estamina:**
  - [x] Consumo de estamina a $-25\text{ pts/s}$ al sostener `Shift` pasando de $800\text{ px/s}$ a $1000\text{ px/s}$.
  - [x] Retardo de recarga de $0.8\text{ s}$ y regeneración continua a $+20\text{ pts/s}$.
  - [x] Estado de fatiga (bloqueo de sprint hasta recuperar $\ge 30\%$ de estamina).
- [x] **Mecánica de Salto Libre (Despegue en Suelo):**
  - [x] Activación con `Espacio` en suelo consumiendo $-20\text{ pts}$ de estamina.
  - [x] Arco parabólico en contenedor `Visual` local con fórmula $4u(1-u) \times 56\text{ px}$ (duración $0.45\text{ s}$).
  - [x] Desactivación temporal de colisión con Capa 2 (`Obstaculos_Bajos`).
  - [x] Escala reducida de la sombra proyectada en el suelo durante el vuelo (`Vector2(0.6, 0.6)`).
- [x] **Mecánica de Salto de Plancha (*Dive* en el Aire):**
  - [x] Segunda pulsación de `Espacio` en el aire consumiendo $-30\text{ pts}$ de estamina.
  - [x] Impulso horizontal aerodinámico a $1200\text{ px/s}$.
  - [x] Impacto contra el suelo y ventana de inmovilidad/recuperación de $0.6\text{ s}$ con arrastre (`dive_slide_friction = 2200 px/s²`).
- [ ] **Animaciones de Salto y Recuperación en Motor:**
  - [ ] Integrar poses estáticas y recuperación (`jugador_salto_aire`, `jugador_plancha_aire`, `jugador_suelo_recuperacion`) en `_actualizar_animacion()` de [`scripts/personaje.gd`](../../scripts/personaje.gd).
- [ ] **Sistema de Iluminación y Linterna Frontal Desacoplada:**
  - [x] Especificación canónica en [`docs/gameplay/sistema_de_iluminacion.md`](../gameplay/sistema_de_iluminacion.md) con presupuesto WebGL 2.0 (máximo 2 `PointLight2D`).
  - [ ] Recurso serializado `ConfiguracionIluminacion` (`scripts/configuracion_iluminacion.gd` y `.tres`).
  - [ ] `HaloCorporal`: Sprite2D aditivo (`BLEND_MODE_ADD`) centrado en el personaje.
  - [ ] `LinternaFrontal`: PointLight2D con haz cónico procedural ($60^\circ$, $700\text{ px}$) desacoplado en $360^\circ$ (ratón / teclado).
  - [ ] Detección analítica del monstruo (vector `dot` + distancia) y perturbación electromagnética (flicker $\pm 10\%$).
  - [ ] `CanvasModulate` en `Escenario.tscn` con oscurecimiento reactivo por notas.
  - [ ] Controles de calibración en vivo en `DebugMenu.tscn`.

---

## 2. Módulo: Escenario y Topología 2x2
> 📄 **Especificación de referencia:** [`docs/gameplay/mapa_y_sectores.md`](../gameplay/mapa_y_sectores.md), [`docs/gameplay/sistema_de_mutacion_y_niebla.md`](../gameplay/sistema_de_mutacion_y_niebla.md)  
> 💻 **Archivos clave:** [`escenas/escenario.tscn`](../../escenas/escenario.tscn), [`scripts/escenario.gd`](../../scripts/escenario.gd)

- [x] **Arena Base y Valla Perimetral:**
  - [x] Estructura fija de $4320 \times 4320\text{ px}$ en coordenadas $[-2160, 2160]$.
  - [x] `VallaPerimetral` en Capa 1 (`Mundo_Alto`) con 4 muros perimetrales fijos de $64\text{ px}$ de grosor.
  - [x] `Camera2D` configurada con límites nativos (`limit_left = -2160`, `limit_top = -2160`, etc.).
- [x] **Contenedores de Cuadrantes (Sectores NO, NE, SO, SE):**
  - [x] Nodos contenedores situados en los centros de cuadrante (`Vector2(±1080, ±1080)`).
  - [x] Corredores de seguridad de $160\text{ px}$ libres de obstáculos en las intersecciones $X=0, Y=0$.
- [x] **Sub-Escenas de Variantes de Sector:**
  - [x] Crear al menos 2 a 3 variantes prefabricadas por cuadrante con distribución variada de árboles, rocas y troncos.
  - [x] Nodos candidatos de aparición de notas (`Marker2D` en grupo `"puntos_nota"`).
- [x] **Algoritmo de Mutación Dinámica y Niebla:**
  - [x] Detección del cuadrante activo del jugador al recoger una nota o forzar mutación.
  - [x] Transición de niebla radial (`EfectoNieblaMutacion`) vía `ejecutar_transicion()` con cero consumo en reposo y blindaje asíncrono.
  - [x] Refactorización de infraestructura de niebla: desacoplamiento con `ConfiguracionNiebla` (`config_niebla_defecto.tres`), integración monotónica continua de fase en shader (`fase_desplazamiento`) y máquina de estados con tokens de cancelación asíncronos (`_token_transicion`).
  - [x] Reemplazo atómico de las sub-escenas de los **3 cuadrantes lejanos** durante la fase de ceguera.
  - [x] Protocolo anti-atascamiento del monstruo con reubicación al punto transitable más próximo y reserva de marcador.

---

## 3. Módulo: Criatura (Monstruo) e IA
> 📄 **Especificación de referencia:** [`docs/gameplay/monstruo_e_ia.md`](../gameplay/monstruo_e_ia.md), [`docs/gameplay/dificultad_y_balance.md`](../gameplay/dificultad_y_balance.md)  
> 💻 **Archivos clave:** [`scripts/enemigo.gd`](../../scripts/enemigo.gd), [`escenas/enemigo.tscn`](../../escenas/enemigo.tscn)

- [x] **Persecución Básica Vectorial:** Movimiento hacia el jugador con `move_and_slide()` y aceleración controlada (`3500 px/s²`).
- [x] **Rotación Continua 360°:** El nodo visual orienta sus garras y cabeza siguiendo el vector instantáneo de velocidad (`velocity.angle()`).
- [x] **Geometría de Detección:** Colisión física sólida ($42\text{ px}$) y `AreaCaptura` letal ($56\text{ px}$) con `RayCastVision`.
- [x] **Hibernación Inicial y Despertar en Nota 1 (process_mode = DISABLED -> Reposicionar y Activar):**
  - [x] En Nota 0 (tutorial), el monstruo no aparece en el mapa para el jugador; en motor reside en hibernación total (`visible = false`, `process_mode = Node.PROCESS_MODE_DISABLED`, fuera de escena).
  - [x] Al recoger la Nota 1, el Game Director reposiciona al monstruo a una distancia segura fuera de pantalla, restaura `visible = true`, `process_mode = Node.PROCESS_MODE_INHERIT` y activa la persecución a $500\text{ px/s}$.
- [x] **Escalado Cuantitativo de Dificultad:**
  - [x] Implementar la progresión mediante arreglo discreto `VELOCIDADES_MONSTRUO` ($0 \to 500 \to 580 \dots 920\text{ px/s}$).
  - [x] Tope absoluto de $920\text{ px/s}$ para garantizar la maniobrabilidad del jugador durante el sprint ($1000\text{ px/s}$).
- [ ] **Desatasco Tangencial (*Steering*):** Vector de desvío lateral cuando la línea de visión se bloquea contra obstáculos sólidos.
- [ ] **Ojos Reflectantes y Material Emisivo:** Ojos visibles en penumbra antes que la silueta completa penetre en el haz de luz.

---

## 4. Módulo: Coleccionables Arcade (Notas) y Spawner
> 📄 **Especificación de referencia:** [`docs/gameplay/sistema_de_notas_y_spawner.md`](../gameplay/sistema_de_notas_y_spawner.md)  
> 💻 **Archivos clave:** `escenas/nota.tscn`, `scripts/nota.gd`

- [x] **Entidad Nota (`Area2D`):**
  - [x] Solo 1 nota activa en escena en todo momento en Capa 5 (`Interactuables`).
  - [x] Resplandor luminoso orientativo con pulso armónico.
  - [x] Flotación senoidal procedural en `VisualPapel`.
- [x] **Recolección Fluida Estilo Arcade:**
  - [x] Detección por contacto sin bloquear el control ni desplegar textos obstructivos.
  - [x] Partículas de recogida (`CPUParticles2D`) y desactivación diferida de colisión.
  - [x] Emisión de señal `recolectada` coordinada con el Director.
- [x] **Algoritmo del Spawner Espacial (`maain.gd`):**
  - [x] Filtrado de candidatos en los 3 cuadrantes recién mutados.
  - [x] Restricción de distancias mínimas: $\ge 600\text{ px}$ al jugador y $\ge 800\text{ px}$ al monstruo.
  - [x] Exclusión mutua respecto al marcador utilizado para desatascar al enemigo.
  - [x] Fallback robusto al marcador más lejano si todos quedan filtrados.

---

## 5. Módulo: Arquitectura de Partida y Director (Game Director)
> 📄 **Especificación de referencia:** [`docs/gameplay/arquitectura_de_partida_y_director.md`](../gameplay/arquitectura_de_partida_y_director.md)  
> 💻 **Archivos clave:** `scripts/maain.gd`, `escenas/maain.tscn`

- [x] **Orquestador Principal de Partida (`maain.gd`):**
  - [x] Referenciación segura de jugador, monstruo y escenario.
  - [x] Bus centralizado de señales: recolección $\to$ puntuación $\to$ mutación $\to$ nuevo spawn diferido.
- [x] **Progresión y Fin de Partida:**
  - [x] Escalado dinámico de velocidad del enemigo según notas recolectadas (`actualizar_dificultad` y `VELOCIDADES_MONSTRUO` en `enemigo.gd`).
  - [x] Manejo de condición de derrota y salto a Game Over al capturar al jugador (`jugador_capturado` y llamada al gestor).
- [ ] **Persistencia de High Score:**
  - [ ] Guardado en archivo local `user://highscore.save` (IndexedDB en navegador).
  - [ ] Fallback web directo a `JavaScriptBridge` con `localStorage`.

---

## 6. Módulo: Cámara y Game Feel
> 📄 **Especificación de referencia:** [`docs/gameplay/camara_y_game_feel.md`](../gameplay/camara_y_game_feel.md)  
> 💻 **Archivos clave:** [`escenas/camara.tscn`](../../escenas/camara.tscn), `scripts/camara.gd`

- [x] **Configuración Básica de Cámara:** Viewport $1:1$ con centrado y límites perimetrales fijos $[-2160, 2160]$.
- [ ] **Sistema de Sacudida por Trauma (*Camera Shake*):**
  - [ ] Desplazamiento por trauma cuadrático: $\text{Trauma}^2 \times \text{AmplitudMáxima}$.
  - [ ] Tasa de decaimiento lineal a $-1.4\text{ pts/s}$.
  - [ ] Disparadores: impacto de plancha ($+0.35$), proximidad del monstruo en luz ($+0.12/\text{s}$), jumpscare ($+1.0$).

---

## 7. Módulo: Interfaz, HUD y Menús
> 📄 **Especificación de referencia:** [`docs/interfaz_y_audio/controles_y_hud.md`](../interfaz_y_audio/controles_y_hud.md), [`docs/interfaz_y_audio/pantallas_y_menus.md`](../interfaz_y_audio/pantallas_y_menus.md), [`docs/interfaz_y_audio/gestor_de_escenas.md`](../interfaz_y_audio/gestor_de_escenas.md)  
> 💻 **Archivos clave:** [`scripts/gestor_escenas.gd`](../../scripts/gestor_escenas.gd), [`scripts/menu_inicio.gd`](../../scripts/menu_inicio.gd), [`scripts/game_over.gd`](../../scripts/game_over.gd)

- [x] **Gestor de Escenas y Fundidos:** Transiciones con velo negro entre Inicio, Partida y Game Over con patrón desacoplado *Call Down, Signal Up*.
- [x] **Menú Principal Diegético (`MenuInicio`):**
  - [x] Composición en primera persona con linterna enfocando 3 árboles (`Opciones`, `Jugar`, `Créditos`) con crossfade de haz de luz.
  - [x] Parallax multicapa en 3 planos (`FondoDegradado`, `Montaña2`, `Montaña1`) respetando las posiciones iniciales diseñadas en el editor 2D.
  - [x] Desacoplamiento de animación: *sway* continuo de pulso/respiración combinado con interpolación `Tween` sin conflicto de propiedades.
  - [x] Navegación cíclica horizontal por teclado/mando con *Scale Punch* tipográfico y bloqueo de confirmación contra doble clic.
  - [x] Arquitectura de señales hacia el orquestador (`jugar_solicitado`, `opciones_solicitado`, `creditos_solicitado`).
  - [x] Suite de pruebas automatizadas [`tests/test_menu_inicio.gd`](../../tests/test_menu_inicio.gd).
- [ ] **Sub-Pantallas del Menú Principal:**
  - [ ] Pantalla de Opciones conectada a la señal `opciones_solicitado` de `MenuInicio`.
  - [ ] Pantalla de Créditos conectada a la señal `creditos_solicitado` de `MenuInicio`.
- [ ] **Tutorial Flotante sobre la Cabeza (`TutorialCabeza`):**
  - [ ] Componente visual flotante a $Y \approx -90\text{ px}$ con fondo traslúcido y badges de teclas.
  - [ ] Secuencia de 3 pasos: WASD (ilumina teclas al pulsar) $\to$ Salto (Espacio) $\to$ Sprint (Shift).
  - [ ] Cierre automático con `Tween` al completar o al recoger la Nota 1.
- [ ] **Barra de Estamina en HUD:** `ProgressBar` nativo con `StyleBoxFlat` delgado ($200 \times 12$ px), color ámbar normal y titileo carmesí en fatiga.
- [ ] **Contador de Notas en HUD:** Icono de nota y texto numérico con `Tween` elástico de recogida ($1.3 \to 1.0$).
- [ ] **Menú de Pausa Superpuesto (`CanvasLayer`, layer=50):**
  - [ ] Congelación de la simulación del nodo de partida (`process_mode = PROCESS_MODE_DISABLED`) sin apagar la cámara ni el gestor de escenas.
  - [ ] Botones estilizados: Continuar, Reiniciar y Menú Principal.
  - [ ] Apertura/cierre instantáneo con tecla `Escape` o `P`.
- [ ] **Pantalla de Game Over:** Sacudida súbita de cámara, destello rojo, ilustración de jumpscare y comparativa de notas recogidas vs High Score.

---

## 8. Módulo: Pipeline Artístico (~30 Assets) y Organización
> 📄 **Especificación de referencia:** [`docs/arte/guia_estilo_y_assets.md`](../arte/guia_estilo_y_assets.md), [`docs/produccion/estructura_del_proyecto.md`](estructura_del_proyecto.md)

- [ ] **Estructura de Directorios de Arte y Fuentes Crudas:**
  - [ ] Crear directorio `assets_raw/` con archivo `.gdignore` para alojar archivos editables de Blender (`.blend`) e Inkscape (`.svg`).
  - [ ] Estructurar destinos en `res://graficos/`: `personaje/`, `criatura/`, `entorno/`, `notas/`, `interfaz/`, `jumpscare/` y `bocetos/`.
- [ ] **Protagonista (15 Cuadros en `res://graficos/personaje/`):**
  - [ ] Caminar frente (4 cuadros, $128 \times 128$ px).
  - [ ] Caminar perfil (4 cuadros, $128 \times 128$ px, simetría `flip_h`).
  - [ ] Caminar espalda (4 cuadros, $128 \times 128$ px).
  - [ ] Salto libre en aire (1 cuadro).
  - [ ] Plancha aerodinámica en aire (1 cuadro).
  - [ ] Suelo recuperación boca abajo (1 cuadro).
  - [ ] Sombra elíptica (1 sprite, $64 \times 32$ px).
- [ ] **Criatura (2 a 3 Cuadros):**
  - [ ] Silueta cenital hacia $+X$ con garras (2 a 3 cuadros, $128 \times 128$ px).
  - [ ] Máscara de ojos brillantes (amarillo/rojo).
- [x] **Menú Principal (6 Capas en `res://graficos/menu principal/`):**
  - [x] `fondo degradado.jpg` ($8\%$ parallax).
  - [x] `montaña 2.png` ($22\%$ parallax).
  - [x] `montaña 1.png` ($45\%$ parallax).
  - [x] `manu seleccion inicio.png` (haz de linterna sobre árbol `Jugar`).
  - [x] `variacion izquierda inicio.png` (haz de linterna sobre árbol `Opciones`).
  - [x] `variacion derecha inicio.png` (haz de linterna sobre árbol `Créditos`).
- [ ] **Entorno Modular (6 Piezas):**
  - [ ] Suelo hojarasca tile ($256 \times 256$ px).
  - [ ] Árbol frondoso ($256 \times 256$ px).
  - [ ] Árbol seco ($256 \times 256$ px).
  - [ ] Roca asimétrica ($128 \times 128$ px).
  - [ ] Tronco caído obstáculo bajo ($192 \times 64$ px).
  - [ ] Tramo de valla de estacas ($128 \times 64$ px).
- [ ] **Coleccionables y Pantallas (3 Piezas):**
  - [ ] Nota de papel viejo ($64 \times 64$ px) + Icono HUD ($32 \times 32$ px).
  - [ ] Ilustración jumpscare de impacto Game Over ($512 \times 512$ px).

---

## 9. Módulo: Audio y Feedback Sensorial
> 📄 **Especificación de referencia:** [`docs/interfaz_y_audio/audio_y_feedback.md`](../interfaz_y_audio/audio_y_feedback.md), [`docs/interfaz_y_audio/sistema_de_musica.md`](../interfaz_y_audio/sistema_de_musica.md), [`docs/produccion/estructura_del_proyecto.md`](estructura_del_proyecto.md)

- [ ] **Estructura de Directorios de Audio:**
  - [ ] Crear carpetas temáticas bajo `res://audio/`: `ambiente/`, `criatura/`, `jugador/` e `interfaz/`.
  - [x] Configuración de carpetas de pistas bajo `res://sonido/musica/` con metadatos interactivos de BPM y compases.
- [ ] **Configuración de Buses de Audio (`default_bus_layout.tres`):**
  - [x] Crear estructura de buses: `Master`, `sfx`, `musica`.
  - [ ] Asignar `AudioEffectLowPassFilter` dinámico en `Master` durante estado `FATIGA`.
  - [ ] Asignar `AudioEffectReverb` (inactivo por defecto) en bus `musica` para efecto post-derrota.
- [ ] **Sistema de Música Interactiva (`scripts/gestor_musica.gd`):**
  - [ ] Implementar Singleton Autoload `/root/GestorMusica` con reproductores A y B asignados al bus `musica`.
  - [ ] Continuidad de `Night Crawling` entre Menú Principal y Tutorial sin reinicio.
  - [ ] Crossfade de $2.0\text{ s}$ a `Haunted Boardwalk` al recolectar la Nota 1.
  - [ ] Modulación dinámica de volumen (*audio ducking*) de $-8\text{ dB}$ a $-20\text{ dB}$ ante proximidad de la criatura ($< 800\text{ px}$).
  - [ ] Corte a $0\text{ ms}$ en jumpscare y activación en Game Over de `pitch_scale = 0.65` con reverberación cavernosa.
- [ ] **Efectos de Jugador:** Pasos sobre hojarasca seca con cadencia según velocidad, sonido de despegue de salto y golpe seco al caer en plancha con jadeo.
- [ ] **Efectos de Criatura:** Radar sonoro mediante `AudioStreamPlayer2D` con atenuación logarítmica ($1400\text{ px}$) y zumbido de estática.
- [ ] **Efectos de Entorno y Notas:** Viento frío continuo de fondo, rasgado seco de nota recogida y golpe orquestal repentino de jumpscare.

---

## 10. Módulo: Exportación Web y Persistencia
> 📄 **Especificación de referencia:** [`docs/produccion/checklist_exportacion_web.md`](checklist_exportacion_web.md)

- [x] **Configuración de Preset Web:**
  - [x] Renderer `gl_compatibility` y `threads = false`.
  - [x] Captura de foco de canvas y anulación de scroll de página en Espacio/Flechas.
- [ ] **Persistencia de High Score:** Guardado de récord histórico mediante `user://` (IndexedDB en navegador) con fallback a `localStorage`.
- [ ] **Validación en Plataformas:** Pruebas de empaquetado `.zip` y ejecución en itch.io y Newgrounds.

---

## 11. Módulo: Herramientas de Depuración y Diagnóstico
> 📄 **Especificación de referencia:** [`docs/herramientas/herramientas_de_debug.md`](../herramientas/herramientas_de_debug.md)  
> 💻 **Archivos clave:** `escenas/debug_menu.tscn`, `scripts/debug_menu/`, `addons/personaje_tools/`

- [x] **Singleton de Persistencia de Debug (`scripts/debug_config.gd`):** Autoload global `/root/DebugConfig` que preserva estado tri-estado, cheats, overlays, God View, niebla y sliders modificados tras reinicio de escena o muerte.
- [x] **Toolbar de Personaje en Editor:** Plugin contextual `addons/personaje_tools` para ajuste de velocidad, aceleración y fricción.
- [x] **Menú Unificado de Debug In-Game (`escenas/debug_menu.tscn`):**
  - [x] Ciclo tri-estado con <kbd>F3</kbd>: Oculto ➔ Mini-HUD ➔ Menú Completo.
  - [x] Mini-HUD con FPS, memoria, cuadrante y velocidad en esquina superior.
  - [x] Pestaña Jugador: telemetría física, pad 8-dir y cheats de prueba (estamina infinita, god mode).
  - [x] Pestaña Escenario (Issue #3): cuadrante activo, forzado manual de mutación, toggle de niebla, vista global (God View) y toggles visuales de corredores ($160\text{ px}$).
  - [x] Pestaña Monstruo: estado de persecución, anti-atascamiento, cálculo de velocidad y botón de reubicación segura.
  - [x] Pestaña Sistema: escala de tiempo (`Engine.time_scale`) y reinicio rápido de escena.
- [x] **Monitores Personalizados Base en Depurador de Godot:** Registro automático en `Performance` de estamina, velocidad de jugador y enemigo, distancia y estado cinemático (`scripts/debug_menu/debug_custom_monitors.gd`).
- [ ] **Ampliación de Herramientas para Semanas 3 y 4:**
  - [ ] Pestaña Escenario: Modo Fullbright (`[x] Sin Oscuridad`) y visualizador avanzado de filtros de spawner en `DebugOverlay` (verde = válido, rojo = excluido, dorado = activa).
  - [ ] Pestaña Monstruo: Casilla de congelación de IA y selector de fase de dificultad escalonada (Nota 0 a 10+).
  - [ ] Pestaña Sistema: Simulador de notas, teletransporte a nota activa, inyector de trauma de cámara (`+0.20`, `+0.35`, `+1.00`), borrado de *High Score* guardado y reinicio directo vía `GestorEscenas.iniciar_partida()`.
  - [ ] Depurador de Godot: Monitores de notas recogidas, trauma y nodos huérfanos, soporte de `Viewport.debug_draw`, bitácora estructurada con `print_rich` y nombrado semántico de variantes en el Árbol Remoto.
- [ ] **Linter de Escenario (`addons/escenario_tools`):** Guías visuales de exclusión ($80\text{ px}$) y validación estática de colisiones en variantes.
