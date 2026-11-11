# Pantallas y Menús del Juego

Este documento detalla la estética visual, comportamiento cinematográfico, fórmulas de animación y flujos de usuario para el Menú Principal, el Menú de Pausa y la Pantalla de Game Over de **Vosque**.

> 🎮 **Controles y HUD:** [Controles y HUD](controles_y_hud.md)  
> 🏛️ **Arquitectura de orquestación:** [Gestor de Escenas](gestor_de_escenas.md)  
> 🔊 **Audio de Menús:** [Sistema de Audio de los Menús](audio_de_menus.md)

---

## 1. Menú Principal (Linterna Diegética en Primera Persona)

El Menú Principal (`escenas/menu_inicio.tscn` / `scripts/ui/menu_inicio.gd`) es la pieza visual prioritaria y carta de presentación de *Vosque*. En lugar de un menú convencional plano, presenta una **experiencia diegética e inmersiva en primera persona** ambientada en la noche del bosque.

```mermaid
flowchart LR
    subgraph MenuInicio["Menú Principal (Primera Persona)"]
        direction TB
        Fondo["Parallax 3 Planos (Degradado + Montañas)"]
        Arboles["3 Árboles Iluminados por Linterna"]
        UI["Opciones: [OPCIONES] [JUGAR] [CRÉDITOS]"]
    end

    UI -- Seleccionar Jugar --> Fundido["Fundido a Negro (Transición)"]
    Fundido --> Partida["Iniciar Partida (maain.tscn)"]
```

### 1.1. Concepto Visual e Iluminación de Árboles
El jugador observa la oscuridad a través de una linterna sostenida en mano. La vista enfoca a tres árboles que representan las opciones del menú:
1. **Árbol Izquierdo:** `Opciones` (inclinación $+1.2^\circ$, offset $+95\text{ px}$).
2. **Árbol Central:** `Jugar` (inclinación $0.0^\circ$, offset $0\text{ px}$).
3. **Árbol Derecho:** `Créditos` (inclinación $-1.2^\circ$, offset $-95\text{ px}$).

Al navegar entre opciones, la linterna se desplaza y realiza una transición por **Shader de Mezcla Directa (`shaders/crossfade_arboles.gdshader`)** sobre un único nodo `Sprite2D` (`$Arboles/ArbolVisual`). El shader interpola fragmento a fragmento (`mix(textura_anterior, textura_actual, progreso)`):
* **Cero caída de alfa (Alpha Dip):** Como la mezcla se calcula a nivel de fragmento sobre las texturas, las regiones cubiertas por los árboles conservan el 100% de opacidad ($1.0$), impidiendo totalmente que las montañas y degradados del fondo se transparenten.
* **Cero texturas huérfanas o conflictos de Z-Index:** Al no existir múltiples sprites encendiéndose o apagándose por separado, es imposible que una textura de otra opción quede superpuesta por error al navegar rápidamente.
* **Texturas precargadas:** `menu_inicio.gd` gestiona un diccionario constante `TEXTURAS_OPCIONES` que asigna de forma directa las variaciones (`variacion izquierda inicio.png`, `manu seleccion inicio.png`, `variacion derecha inicio.png`) según el árbol enfocado.

### 1.2. Parallax Multicapa Relativo al Editor 2D
El fondo se organiza en tres planos de profundidad bajo el nodo `$Fondos`:
1. **Fondo Degradado (`FondoDegradado`):** Cielo nocturno casi estático en el infinito (factor de parallax $0.08$ en traslación y $0.06$ en rotación).
2. **Montaña 2 (`Montaña2`):** Capa lejana con desplazamiento suave (factor $0.22$ en traslación y $0.18$ en rotación).
3. **Montaña 1 (`Montaña1`):** Capa intermedia que se desliza visiblemente tras los troncos (factor $0.45$ en traslación y $0.35$ en rotación).

> [!NOTE]
> **Preservación del Diseño en Editor (`_capturar_posiciones_iniciales`):**
> Para evitar fragilidad ante ajustes artísticos en Godot, el script captura en `_ready()` las coordenadas iniciales configuradas en la escena (`_pos_inicial_fondos`, `_pos_inicial_degradado`, `_pos_inicial_montana_2`, etc.). En `_process()`, el parallax se suma de manera relativa a esas posiciones base, garantizando que mover nodos con el ratón en el editor 2D se preserve intacto en ejecución sin tocar código.

### 1.3. Oscilación Orgánica (*Sway*) y Desacoplamiento de Tween
Para simular el pulso y la respiración natural de un explorador sosteniendo una linterna en la oscuridad:
* `_process(delta)` calcula oscilaciones sinusoidales armónicas compuestas en $X$, $Y$ y rotación (*sway*).
* La transición entre opciones se anima mediante un `Tween` interpolando las variables intermedias `_offset_base` y `_rotacion_base` (`TRANS_CUBIC`, `EASE_OUT`).
* Ambas transformaciones se suman sin conflicto: `offset_total = _offset_base + sway`, evitando que el `Tween` y el bucle por fotograma sobrescriban la propiedad `position` mutuamente.

### 1.4. Navegación por Teclado/Mando y Feedback Tipográfico
* **Navegación horizontal:** Teclas <kbd>A</kbd>/<kbd>D</kbd>, <kbd>←</kbd>/<kbd>→</kbd> o sticks analógicos recorren cíclicamente el arreglo `ORDEN_OPCIONES = [OPCIONES, JUGAR, CREDITOS]`.
* **Confirmación:** <kbd>Espacio</kbd> o <kbd>Enter</kbd> confirman la opción. Al seleccionar `JUGAR`, el menú activa `_bloqueado = true` para evitar dobles pulsaciones durante el fundido y emite la señal `jugar_solicitado`.
* **Scale Punch tipográfico:** El texto de la opción activa incrementa su escala a $1.08\times$ mediante `Tween` con curva `TRANS_BACK` y opacidad $1.0$, mientras que las opciones inactivas reducen su opacidad a $0.16$ y escala base $1.0$.

### 1.5. Pantalla de Presentación y Paneo Cinemático (`Camera2D` + `AnimationPlayer`)
El menú principal implementa una experiencia cinematográfica previa dividida en lienzos 2D continuos:
* **Zona Superior ($Y \in [-1080, 0]$):** Vista del cielo nocturno y estrellas. Alberga el nodo `$Presentacion` con el logotipo (`Logo`) y el texto parpadeante (`TextoComenzar`: *"PRESIONA ENTER PARA COMENZAR"*), sobre la textura `FondoPresentacion` (`fondo degradado alargado.jpg`).
* **Zona Central / Inferior ($Y \in [0, 1080]$):** Vista a ras de suelo del bosque con las montañas, los 3 árboles y los textos de navegación.
* **Zona Lateral Izquierda ($X \in [-1080, 0]$):** Vista del panel de Opciones/Ajustes (`MenuOpciones`) con paneo de cámara a $x = -540$.
* **Zona Lateral Derecha ($X \in [1080, 2160]$):** Vista del panel de Créditos (`MenuCreditos`) con paneo de cámara a $x = 1620$.

#### Flujo Cinemático y Control de Estados
1. **Estado `PRESENTACION`:** La `CamaraMenu` inicia en `(540, -540)` reproduciendo en loop la animación `"esperando_inicio"` (respiración suave de opacidad del texto de inicio).
2. **Descenso (`iniciar_descenso()`):** Al pulsar <kbd>Enter</kbd> o <kbd>Espacio</kbd>, pasa a `CINEMATICA_BAJANDO` y ejecuta `"bajar_al_bosque"`, desplazando la `CamaraMenu` verticalmente hasta `(540, 540)` y realizando un crossfade suave de salida (`modulate:a -> 0.0`) de `FondoPresentacion` hacia `FondoDegradado`.
3. **Efecto Motion Blur Vertical y Horizontal (`shaders/motion_blur_vertical.gdshader`):** Un `ColorRect` a pantalla completa anclado a la cámara (`CamaraMenu/EfectoMotionBlur`) aplica un desenfoque direccional sobre `screen_texture`. Su intensidad se modula mediante una curva de campana en el `AnimationPlayer` (pico de `0.035` en bajada/subida y `0.015` en paneos laterales a opciones o créditos), otorgando una sensación vertiginosa de velocidad cinematográfica.
4. **Transición a Opciones y Créditos (`ir_a_opciones` / `ir_a_creditos`):**
   - Hacia la izquierda: `CamaraMenu:position:x` transiciona suavemente mediante curva Bézier de $540$ a $-540$, oculta los textos del menú y despliega `MenuOpciones`.
   - Hacia la derecha: `CamaraMenu:position:x` transiciona con la curva simétrica de $540$ a $1620$, oculta los textos del menú y despliega `MenuCreditos` (`escenas/ui/menu_creditos.tscn`). Para asegurar cobertura continua a la derecha, `FondoDegradado` escala en $X$ a $\ge 1.35$ y las montañas escalan para evitar bordes vacíos.
   - Retorno: `play_backwards` en la animación correspondiente restaura la cámara al centro ($x = 540$) y reactiva el menú principal.
5. **Función Skip Dinámica (`skipear_cinematica()`):** Si el jugador pulsa cualquier botón de acción (<kbd>Enter</kbd>, <kbd>Espacio</kbd>, <kbd>Escape</kbd>) durante el descenso, ascenso o transiciones laterales, el `AnimationPlayer` multiplica su velocidad (`speed_scale = multiplicador_velocidad_skip`, por defecto $4.0\times$), concluyendo la animación de forma ágil y fluida.
5. **Retorno a la Pantalla de Inicio con Escape (`regresar_a_presentacion()`):** Estando en el menú de selección de árboles (`MENU_ACTIVO`), presionar <kbd>Escape</kbd> (`ui_cancel`) activa el estado `CINEMATICA_SUBIENDO` y reproduce la animación en reversa (`play_backwards("bajar_al_bosque")`). La cámara se eleva desde el bosque hacia el cielo con *motion blur*, oculta los textos de opciones, restaura los fondos de presentación y reanuda el bucle de espera (*"PRESIONA ENTER PARA COMENZAR"*).
6. **Reinicio al volver:** Cada vez que el jugador regresa al menú principal (desde el juego o Game Over vía `GestorDeEscenas.volver_al_menu()`), el método `enfocar()` reinicia la vista en la parte superior, permitiendo siempre la aceleración instantánea con doble pulsación.
7. **Ajustes en Inspector:**
   - `habilitar_presentacion` (`bool`): Permite omitir la cinemática e iniciar directamente en los árboles para pruebas rápidas de desarrollo.
   - `multiplicador_velocidad_skip` (`float`): Factor de aceleración al skipear.

### 1.6. Partículas Atmosféricas del Cielo (Estrellas y Nubes)
Para eliminar la monotonía visual del cielo nocturno tanto en espera como en el descenso, el menú incorpora dos sistemas de partículas procedurales (`CPUParticles2D`) ubicados bajo `$Fondos`:

1. **Estrellas Titilantes (`ParticulasEstrellas`):**
   - Textura radial suave `res://recursos/particulas/textura_estrella.tres` con rampa de opacidad `rampa_alpha_estrella.tres` para simular titileo orgánico.
   - Distribución rectangular con `preprocess` activo (aparece completamente poblada desde el inicio sin retraso).
2. **Nubes y Bruma Nocturna (`ParticulasNubes`):**
   - Textura difusa semi-translúcida `res://recursos/particulas/textura_nube.tres` con rampa de entrada y salida gradual `rampa_alpha_nube.tres`.
   - Deriva horizontal suave en eje $X$.
3. **Parámetros Altamente Configurables (`@tool` en Inspector):**
   - El script actualiza en vivo los emisores en el editor 2D y en tiempo de ejecución:
     - **Subgrupo Estrellas:** `habilitar_estrellas`, `estrellas_cantidad`, `estrellas_lifetime`, `estrellas_escala_min/max`, `estrellas_color`, `estrellas_factor_parallax`.
     - **Subgrupo Nubes y Bruma:** `habilitar_nubes`, `nubes_cantidad`, `nubes_velocidad_x`, `nubes_lifetime`, `nubes_escala_min/max`, `nubes_color`, `nubes_factor_parallax`.
4. **Cinemática Natural:**
   - Al descender la cámara a ras de suelo en el bosque, las estrellas y nubes se desplazan de forma coherente hacia arriba, saliendo del viewport de manera natural.

---

## 2. Menú de Pausa In-Game (`escenas/menu_pausa.tscn` / `scripts/ui/menu_pausa.gd`)

El menú de pausa permite interrumpir temporalmente la sesión de juego sin perder el estado actual ni romper la inmersión visual. Se implementa como una capa de interfaz desacoplada sobre `GestorEscenas` mediante un `CanvasLayer` con prioridad `layer = 50` (situado sobre el `HUD` con `layer = 10` y `EfectoNieblaMutacion` con `layer = 15`, pero por debajo de `Transicion` y `DebugMenu` con `layer = 100`).

### 2.1. Estética y Comportamiento Visual
* **Superposición translúcida:** Un fondo oscuro semitransparente (`ColorRect` en `Color(0, 0, 0, 0.65)`) cubre la pantalla.
* **Fondo congelado:** El bosque, el personaje y la criatura permanecen visibles bajo el velo en la posición exacta donde se pausó, y la `Camera2D` del personaje sigue centrando la vista en el viewport.
* **Congelación total del mundo (`SceneTree.paused = true`):** Se desactivan de manera atómica las físicas (`_physics_process`), el movimiento de personajes, enemigos, tweens del juego, partículas `CPUParticles2D`, audio 2D posicional y todos los `SceneTreeTimer` de notas y mutación de niebla.
* **UI y transiciones inmunes (`PROCESS_MODE_ALWAYS`):** El nodo raíz del menú de pausa opera con `process_mode = PROCESS_MODE_ALWAYS`, permitiendo interactuar con el menú, mover el foco con teclado/mando y procesar clics sin importar que el árbol esté pausado.

### 2.2. Contrato de Señales y Métodos Públicos
Siguiendo el patrón *Signal Up, Call Down*:
* **Señales emitidas:**
  - `signal continuar_solicitado`: El jugador solicita reanudar la partida.
  - `signal reiniciar_solicitado`: El jugador solicita recrear la partida desde cero.
  - `signal menu_solicitado`: El jugador solicita volver al menú principal.
* **Métodos públicos:**
  - `func mostrar() -> void`: Hace visible el menú, reinicia la bandera `_bloqueado = false`, habilita los botones y otorga foco diferido (`call_deferred("grab_focus")`) al botón *"Continuar"*.
  - `func ocultar() -> void`: Libera el foco (`release_focus()`) y oculta la capa.
  - `func ocultar_inmediato() -> void`: Limpieza forzada instantánea usada por `GestorDeEscenas.ir_a()` durante transiciones.

### 2.3. Opciones, Flujo de Interacción y Salvaguardas
* **Navegación con Controles de Movimiento y UI:**
  - El jugador puede navegar verticalmente entre las opciones tanto con el teclado/mando estándar de interfaz (`ui_up`, `ui_down`) como directamente con los controles de movimiento del personaje (<kbd>W</kbd> / <kbd>↑</kbd> para `personaje-arriba` y <kbd>S</kbd> / <kbd>↓</kbd> para `personaje-abajo`).
  - La navegación es cíclica (`posmod`), recorriendo ordenadamente: *"Continuar"* $\leftrightarrow$ *"Reiniciar"* $\leftrightarrow$ *"Menú Principal"*.
  - La opción enfocada puede confirmarse indistintamente con <kbd>Enter</kbd> (`ui_accept`) o con la tecla de salto del juego <kbd>Espacio</kbd> (`personaje-salto`).
1. **Continuar:**
   - Cierra la superposición de pausa de inmediato (sin fundido a negro) y restaura la simulación.
   - Recibe el foco automático diferido al abrir el menú de pausa para reanudación instantánea con <kbd>Espacio</kbd>, <kbd>Enter</kbd> o pulsando nuevamente la acción `pausa` (<kbd>Escape</kbd> / <kbd>P</kbd>).
   - **Blindaje Robusto en 3 Capas Anti-Salto Fantasma:** Al pulsar <kbd>Espacio</kbd> en *"Continuar"*, para garantizar que el personaje no interprete el input como `personaje-salto` al reanudarse el juego ni gaste $-20\text{ pts}$ de estamina:
     1. `MenuPausa` y `GestorDeEscenas` liberan proactivamente el buffer del singleton `Input` con `Input.action_release("personaje-salto")` e `Input.action_release("ui_accept")`.
     2. `GestorDeEscenas` invoca `consumir_buffer_salto()` en el personaje y aplica la despausa diferida al final del frame (`set_deferred("paused", false)`).
     3. `Personaje` intercepta la notificación nativa `NOTIFICATION_UNPAUSED` del motor y suprime cualquier lectura de `quiere_salto` durante exactamente su primer fotograma de físicas activo.
   - **Salvaguarda de Linterna:** Al cerrar el menú, se limpia o ignora el movimiento relativo del ratón acumulado durante la pausa para que la linterna frontal no dé un latigazo hacia la posición del botón.
2. **Reiniciar Partida:**
   - Activa `_bloqueado = true` para impedir pulsaciones repetidas, oculta el menú de pausa y emite `reiniciar_solicitado`.
   - `GestorDeEscenas` ejecuta un fundido a negro vía `iniciar_partida()` y recrea la pantalla de juego (`maain.tscn`) desde cero, restableciendo `get_tree().paused = false`.
3. **Menú Principal:**
   - Activa `_bloqueado = true`, oculta el menú de pausa y emite `menu_solicitado`.
   - `GestorDeEscenas` ejecuta un fundido a negro vía `volver_al_menu()`, transicionando a `menu_inicio.tscn` y restableciendo `get_tree().paused = false`.

---

## 3. Pantalla de Game Over (`game_over.gd`)

Aparece tras el contacto mortal con el monstruo y orquesta la experiencia de derrota en dos tiempos mediante un nodo central **`AnimationPlayer`**:

### 3.1. Orquestación Cinemática con `AnimationPlayer`
En lugar de animar propiedades imperativamente por código mediante `Tween` o temporizadores dispersos, [`escenas/game_over.tscn`](../../escenas/game_over.tscn) integra un **`AnimationPlayer`** que garantiza sincronización multicanal determinista sin asignación de memoria en tiempo de ejecución:

```text
GameOver (Control) [scripts/ui/game_over.gd]
├── Fondo (ColorRect negro)
├── Impacto (ColorRect rojo de flash / viñeta)
├── JumpscareSprite (TextureRect con ilustración 512x512)
├── Layout (CenterContainer con Título, Stats y Botones)
├── AudioJumpscare (AudioStreamPlayer en bus "sfx")
└── AnimationPlayer (Línea de tiempo de la secuencia de muerte)
```

#### Línea de Tiempo de la Animación `jumpscare_derrota` (~$1.0\text{ s}$ - $1.2\text{ s}$):
1. **$t = 0.00\text{ s}$ (El Golpe Seco):**
   * **Pista de Audio:** Disparo instantáneo de `AudioJumpscare` en el bus `sfx` (sin latencia de callbacks de script).
   * **Pista Visual (Jumpscare):** `JumpscareSprite` escala súbitamente de `Vector2(0.3, 0.3)` a `Vector2(1.15, 1.15)` con curva elástica rápida (`TRANS_BACK`), acompañada de micro-vibración en posición.
   * **Pista de Flash:** `Impacto.color.a` salta a `0.85` (flash carmesí).
   * **Pista de Llamada a Métodos:** Inyección de sacudida máxima a la cámara (`camara.agregar_trauma(1.0)`).
   * **Pista de UI:** El contenedor `Layout` permanece oculto (`modulate.a = 0.0`).
2. **$t = 0.05\text{ s} \to 0.40\text{ s}$ (Desvanecimiento del Susto):**
   * El flash carmesí se disuelve progresivamente a oscuridad profunda (`Impacto.color.a = 0.0`).
   * `JumpscareSprite` reduce su opacidad (`modulate.a \to 0.0`) o se reubica sutilmente en segundo plano.
3. **$t = 0.50\text{ s} \to 1.00\text{ s}$ (Revelación de Resultados y Nightmare Decay):**
   * **Música Post-Derrota:** El `GestorMusica` reanuda la pista ambiental con efecto *Nightmare Decay* (`pitch_scale = 0.65` + reverberación cavernosa activa en el bus `musica`).
   * **Pista de UI (Entrada de Resultados):** Fundido suave (`modulate.a \to 1.0`) y ligero desplazamiento vertical del contenedor `Layout`.
   * **Foco Inmediato:** Al concluir la animación (`animation_finished`), el script enfoca automáticamente `BotonReintentar`.

### 3.2. Contenido y Feedback de la Pantalla
1. **Arte de Impacto:** Ilustración de jumpscare de alto contraste (`game_over_jumpscare`, $512 \times 512$ px) controlada por la animación.
2. **Efectos en Motor:**
   - Sacudida súbita de pantalla (*Camera Shake*) durante $0.3\text{ s}$ (ver [Cámara y Game Feel](../gameplay/camara_y_game_feel.md)).
   - Flash rojo intenso instantáneo que se disuelve en oscuridad total.
   - **Tratamiento Sonoro Post-Jumpscare:** Silencio instantáneo en el impacto y entrada posterior de la música ralentizada con reverberación en el bus `musica` (ver [Sistema de Música Interactiva](sistema_de_musica.md#34-secuencia-de-muerte-y-efecto-game-over-nightmare-decay)).
3. **Resultados de la Partida:**
   - Páginas recogidas en la sesión actual.
   - Récord histórico (*High Score* persistido en IndexedDB y `LocalStorage` Web).
4. **Acción Rápida:** Botón llamativo de "Reintentar" y soporte nativo para presionar <kbd>Espacio</kbd> o <kbd>Enter</kbd> para reiniciar la partida en menos de 1 segundo tras la revelación.

---

## 4. Estándar de Botones y Navegación de UI

Para garantizar una experiencia consistente, táctil y accesible en todos los menús (`MenuInicio`, `MenuOpciones`, `MenuPausa`, `MenuCreditos`), el proyecto implementa un estándar unificado para botones interactivos tanto a nivel visual (`.tscn`) como de contrato de código (`.gd`).

```mermaid
flowchart TD
    subgraph Entrada ["Interacción del Usuario"]
        TecladoMando["Teclado / Gamepad (ui_up / ui_down)"]
        Raton["Puntero del Ratón (mouse_entered)"]
    end

    subgraph Boton ["Botón de Menú (Button)"]
        Foco["Evento focus_entered"]
        Hover["grab_focus()"]
        Presionar["Evento pressed / ui_cancel"]
    end

    subgraph AudioUI ["ControladorAudioUI (Autoload)"]
        SfxSelect["MENU_SELECCIONAR (Cursor)"]
        SfxRetroceder["MENU_RETROCEDER / MENU_CONFIRMAR"]
    end

    TecladoMando --> Foco
    Raton --> Hover --> Foco
    Foco -- "Si activo y no silenciado" --> SfxSelect
    Presionar --> SfxRetroceder
```

### 4.1. Configuración Visual en Escena (`.tscn`)

Todos los botones principales de menús deben respetar las siguientes propiedades en el árbol de nodos de Godot:

| Propiedad | Valor / Recurso | Propósito |
| :--- | :--- | :--- |
| `custom_minimum_size` | `Vector2(400, 72)` | Área de interacción táctil amplia y altura uniforme entre botones. |
| `size_flags_horizontal` | `0` | Alineado a la izquierda sin estirarse arbitrariamente según el contenedor. |
| `alignment` | `0` (`HORIZONTAL_ALIGNMENT_LEFT`) | Texto alineado a la izquierda para mantener una columna de lectura limpia. |
| `theme_override_fonts/font` | `res://fuentes/raleway_bold.tres` | Variante semibold/bold (peso 700) de Raleway para máxima legibilidad. |
| `theme_override_font_sizes/font_size` | `40` | Jerarquía tipográfica estandarizada para acciones primarias. |
| `theme_override_colors/font_focus_color` | `Color(0.902, 1.0, 0.702, 1)` (`#e6ffb3`) | Tinte verde lima pálido distintivo al recibir el foco de UI. |
| `theme_override_colors/font_hover_color` | `Color(0.902, 1.0, 0.702, 1)` (`#e6ffb3`) | Mismo tono que focus para coherencia visual al interactuar con ratón. |

#### Navegación Cíclica (`focus_neighbor_*`)
- **Botón solitario (ej. `BotonVolver` en `MenuCreditos`):** Para evitar que el foco se pierda en el vacío al navegar con flechas o palanca de mando, se fija cíclicamente a sí mismo:
  ```text
  focus_neighbor_top = NodePath(".")
  focus_neighbor_bottom = NodePath(".")
  ```
- **Listas verticales (ej. `MenuOpciones`, `MenuPausa`):** Cada botón o control enlaza hacia el anterior y posterior, cerrando el ciclo entre el primer y último elemento.

### 4.2. Contrato de Script y Ciclo de Vida (`.gd`)

Todo script de panel o menú interactivo debe adoptar las siguientes prácticas:

1. **Sincronización Ratón-Foco:**
   Al pasar el cursor sobre cualquier botón o control interactivo mientras el menú esté activo, debe otorgarse el foco nativo mediante `grab_focus()`. Esto previene desincronizaciones donde el ratón apunta a un botón pero el teclado acciona otro:
   ```gdscript
   func _on_boton_mouse_entered(btn: Button) -> void:
       if _activo and btn != null and not btn.has_focus():
           btn.grab_focus()
   ```

2. **Supresión de Audio Espurio en Foco Inicial (`_silenciar_audio_ajustes`):**
   Al activar o desplegar una pantalla, forzar programáticamente `grab_focus()` en el botón inicial dispararía el sonido de cursor sin que el jugador haya realizado ninguna acción intencional. Para prevenirlo, se usa una bandera temporal de silenciamiento:
   ```gdscript
   var _silenciar_audio_ajustes: bool = false

   func activar() -> void:
       _activo = true
       _silenciar_audio_ajustes = true
       if boton_volver != null:
           boton_volver.grab_focus()
       _silenciar_audio_ajustes = false

   func _on_boton_focus_entered() -> void:
       if _activo and not _silenciar_audio_ajustes:
           ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_SELECCIONAR)
   ```

3. **Retroalimentación Auditiva y Señalización:**
   Al presionar el botón, se valida el estado activo, se emite el evento correspondiente (`MENU_RETROCEDER` o `MENU_CONFIRMAR`) a través del bus desacoplado y se emite la señal del componente:
   ```gdscript
   func _on_boton_volver_pressed() -> void:
       if not _activo:
           return
       ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_RETROCEDER)
       volver_solicitado.emit()
   ```

4. **Captura Global de Cancelación (`ui_cancel`):**
   El método `_input(evento)` captura <kbd>Escape</kbd> (`ui_cancel`) si el panel está activo, reutilizando el callback del botón de volver y marcando el evento como manejado para evitar fugas:
   ```gdscript
   func _input(evento: InputEvent) -> void:
       if not _activo:
           return
       if evento.is_action_pressed("ui_cancel"):
           _on_boton_volver_pressed()
           get_viewport().set_input_as_handled()
   ```

