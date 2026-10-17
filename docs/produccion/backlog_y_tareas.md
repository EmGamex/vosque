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
- [ ] **Mecánica de Sprint y Estamina:**
  - [ ] Consumo de estamina a $-25\text{ pts/s}$ al sostener `Shift` pasando de $800\text{ px/s}$ a $1000\text{ px/s}$.
  - [ ] Retardo de recarga de $0.8\text{ s}$ y regeneración continua a $+20\text{ pts/s}$.
  - [ ] Estado de fatiga (bloqueo de sprint hasta recuperar $\ge 30\%$ de estamina).
- [ ] **Mecánica de Salto Libre (Despegue en Suelo):**
  - [ ] Activación con `Espacio` en suelo consumiendo $-20\text{ pts}$ de estamina.
  - [ ] Arco parabólico en contenedor `Visual` local (duración $\approx 0.45\text{ s}$).
  - [ ] Desactivación temporal de colisión con Capa 2 (`Obstaculos_Bajos`).
  - [ ] Escala reducida de la sombra proyectada en el suelo durante el vuelo.
- [ ] **Mecánica de Salto de Plancha (*Dive* en el Aire):**
  - [ ] Segunda pulsación de `Espacio` en el aire consumiendo $-30\text{ pts}$ de estamina.
  - [ ] Impulso horizontal aerodinámico a $\approx 1200\text{ px/s}$.
  - [ ] Impacto contra el suelo y ventana de inmovilidad/recuperación de $0.6\text{ s}$ (vulnerabilidad total ante el monstruo).
- [ ] **Linterna Frontal Desacoplada:**
  - [ ] Halo radial permanente centrado en el personaje.
  - [ ] Haz cónico orientable libremente en $360^\circ$ hacia el ratón o alineado automáticamente con la dirección de marcha.

---

## 2. Módulo: Escenario y Topología 2x2
> 📄 **Especificación de referencia:** [`docs/gameplay/mapa_y_sectores.md`](../gameplay/mapa_y_sectores.md)  
> 💻 **Archivos clave:** [`escenas/escenario.tscn`](../../escenas/escenario.tscn), `scripts/escenario.gd`

- [ ] **Arena Base y Valla Perimetral:**
  - [ ] Estructura fija de $2160 \times 2160\text{ px}$ en coordenadas $[-1080, 1080]$.
  - [ ] `VallaPerimetral` en Capa 1 (`Mundo_Alto`) con 4 muros perimetrales fijos de $64\text{ px}$ de grosor.
  - [ ] `Camera2D` configurada con límites nativos (`limit_left = -1080`, `limit_top = -1080`, etc.).
- [ ] **Contenedores de Cuadrantes (Sectores NO, NE, SO, SE):**
  - [ ] Nodos contenedores situados en los centros de cuadrante (`Vector2(±540, ±540)`).
  - [ ] Corredores de seguridad de $160\text{ px}$ libres de obstáculos en las intersecciones $X=0, Y=0$.
- [ ] **Sub-Escenas de Variantes de Sector:**
  - [ ] Crear al menos 2 a 3 variantes prefabricadas por cuadrante con distribución variada de árboles, rocas y troncos.
  - [ ] Nodos candidatos de aparición de notas (`Marker2D` en grupo `"puntos_nota"`).
- [ ] **Algoritmo de Mutación Dinámica:**
  - [ ] Detección del cuadrante activo del jugador al recoger una nota.
  - [ ] Reemplazo aleatorio de las sub-escenas de los **3 cuadrantes lejanos**.
  - [ ] Protocolo anti-atascamiento del monstruo con reubicación al punto transitable más próximo.

---

## 3. Módulo: Criatura (Monstruo) e IA
> 📄 **Especificación de referencia:** [`docs/gameplay/mecanicas_y_entidades.md`](../gameplay/mecanicas_y_entidades.md), [`docs/gameplay/dificultad_y_balance.md`](../gameplay/dificultad_y_balance.md)  
> 💻 **Archivos clave:** [`scripts/enemigo.gd`](../../scripts/enemigo.gd), [`escenas/enemigo.tscn`](../../escenas/enemigo.tscn)

- [x] **Persecución Básica Vectorial:** Movimiento directo hacia el jugador con `move_and_slide()` y deslizamiento en colisiones.
- [x] **Rotación Continua 360°:** El nodo visual orienta sus garras y cabeza siguiendo el vector instantáneo de velocidad (`velocity.angle()`).
- [ ] **Escalado de Fases y Dificultad:**
  - [ ] Fase 1 (*Patrulla Lenta*): Velocidad base al $60\% - 75\%$ de la marcha del jugador (notas 1 a 3).
  - [ ] Fase 2 (*Persecución Media*): Velocidad igualada al $95\% - 100\%$ (notas 4 a 7).
  - [ ] Fase 3 (*Cacería Frenética*): Velocidad superior al $105\% - 115\%$ (notas 8+).
  - [ ] Fórmula acumulativa: $\text{Velocidad}(n) = \text{Velocidad Base} \times (1 + \text{Tasa})^n$.
- [ ] **Ojos Reflectantes y Material Emisivo:** Ojos visibles en penumbra antes que la silueta completa penetre en el haz de luz.
- [ ] **Estela de Sombras:** Emisión de `CPUParticles2D` oscuras al entrar en fase frenética.

---

## 4. Módulo: Coleccionables Arcade (Notas)
> 📄 **Especificación de referencia:** [`docs/gameplay/mecanicas_y_entidades.md`](../gameplay/mecanicas_y_entidades.md)  
> 💻 **Archivos clave:** `escenas/nota.tscn`, `scripts/nota.gd`

- [ ] **Entidad Nota (`Area2D`):**
  - [ ] Solo 1 nota activa en escena en todo momento.
  - [ ] Halo luminoso propio (`PointLight2D`) actuando como baliza en penumbra.
  - [ ] Flotación senoidal procedural suave.
- [ ] **Recolección Fluida Estilo Arcade:**
  - [ ] Detección por contacto sin bloquear el control ni desplegar textos obstructivos.
  - [ ] Disparo de sonido de rasgado seco y brote de 8 micropartículas doradas/blancas.
  - [ ] Notificación al HUD para salto de escala del contador numérico.
  - [ ] Notificación al gestor de escenario para disparar la mutación de los 3 sectores lejanos y spawnear la siguiente nota a $R_{\min} \ge 600\text{ px}$.

---

## 5. Módulo: Interfaz, HUD y Menús
> 📄 **Especificación de referencia:** [`docs/interfaz_y_audio/controles_y_hud.md`](../interfaz_y_audio/controles_y_hud.md)  
> 💻 **Archivos clave:** [`scripts/gestor_escenas.gd`](../../scripts/gestor_escenas.gd), [`scripts/menu_inicio.gd`](../../scripts/menu_inicio.gd), [`scripts/game_over.gd`](../../scripts/game_over.gd)

- [x] **Gestor de Escenas y Fundidos:** Transiciones con velo negro entre Inicio, Partida y Game Over.
- [x] **Flujo Básico de Menús:** Navegación funcional entre pantallas.
- [ ] **Barra de Estamina en HUD:** `ProgressBar` nativo con `StyleBoxFlat` delgado ($200 \times 12$ px), color ámbar normal y titileo carmesí en fatiga.
- [ ] **Contador de Notas en HUD:** Icono de nota y texto numérico con `Tween` elástico de recogida ($1.3 \to 1.0$).
- [ ] **Menú de Pausa Superpuesto (`CanvasLayer`, layer=50):**
  - [ ] Congelación de la simulación del nodo de partida (`process_mode = PROCESS_MODE_DISABLED`) sin apagar la cámara ni el gestor de escenas.
  - [ ] Botones estilizados: Continuar, Reiniciar y Menú Principal.
  - [ ] Apertura/cierre instantáneo con tecla `Escape` o `P`.
- [ ] **Key Art del Menú Principal:** Capas de paralaje reactivas al ratón (fondo bruma, silueta con ojos reflectantes, logotipo "VOSQUE").
- [ ] **Pantalla de Game Over:** Sacudida súbita de cámara, destello rojo, ilustración de jumpscare y comparativa de notas recogidas vs High Score.

---

## 6. Módulo: Pipeline Artístico (~30 Assets)
> 📄 **Especificación de referencia:** [`docs/arte/guia_estilo_y_assets.md`](../arte/guia_estilo_y_assets.md)

- [ ] **Protagonista (15 Cuadros):**
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
- [ ] **Menú Principal (3 Piezas):**
  - [ ] Fondo niebla nocturna ($1080 \times 1080$ px).
  - [ ] Sujeto central con árboles y bestia ($1080 \times 1080$ px con alfa).
  - [ ] Logotipo tipográfico "VOSQUE".
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

## 7. Módulo: Audio y Feedback Sensorial
> 📄 **Especificación de referencia:** [`docs/interfaz_y_audio/audio_y_feedback.md`](../interfaz_y_audio/audio_y_feedback.md)

- [ ] **Efectos de Jugador:** Pasos sobre hojarasca seca con cadencia según velocidad, sonido de despegue de salto y golpe seco al caer en plancha con jadeo.
- [ ] **Efectos de Criatura:** Sonido sordo gutural o estática que incrementa en proximidad.
- [ ] **Efectos de Entorno y Notas:** Viento frío continuo de fondo, rasgado seco de nota recogida y golpe orquestal repentino de jumpscare.

---

## 8. Módulo: Exportación Web y Persistencia
> 📄 **Especificación de referencia:** [`docs/produccion/checklist_exportacion_web.md`](checklist_exportacion_web.md)

- [ ] **Configuración de Preset Web:**
  - [ ] Renderer `gl_compatibility` y `threads = false`.
  - [ ] Captura de foco de canvas y anulación de scroll de página en Espacio/Flechas.
- [ ] **Persistencia de High Score:** Guardado de récord histórico mediante `user://` (IndexedDB en navegador) con fallback a `localStorage`.
- [ ] **Validación en Plataformas:** Pruebas de empaquetado `.zip` y ejecución en itch.io y Newgrounds.
