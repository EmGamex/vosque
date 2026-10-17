# Personaje y Habilidades

Este documento define la identidad, parámetros físicos, mecánicas de movimiento, habilidades y arquitectura técnica en Godot 4 del protagonista de **Vosque**.

---

## 1. Identidad y Perfil de Juego

* **Rol:** Explorador desorientado atrapado en un bosque oscuro y cerrado.
* **Filosofía de Diseño:** Vulnerabilidad total frente a la amenaza. El jugador carece de armas o ataques; su supervivencia depende exclusivamente del posicionamiento espacial, el aprovechamiento de obstáculos (árboles, rocas, troncos), la gestión de su estamina al correr y la lectura de su entorno iluminado.
* **Clase Base en Motor:** `CharacterBody2D` con modo de movimiento flotante (`MOTION_MODE_FLOATING`), optimizado para desplazamientos top-down de 8 direcciones sin gravedad vertical.

---

## 2. Atributos y Parámetros Físicos

El movimiento del personaje está gobernado por un modelo de velocidad con aceleración y fricción continuas (`scripts/personaje.gd`), lo que proporciona un control responsivo pero con peso físico tangible.

### 2.1. Propiedades Exportadas (`@export`)

| Propiedad | Valor Base (Script) | Valor en Escena (`maain.tscn`) | Unidad | Descripción |
| :--- | :--- | :--- | :--- | :--- |
| `speed` | `300.0` | `800.0` | $\text{px/s}$ | Velocidad máxima de desplazamiento estándar al caminar. |
| `acceleration` | `3000.0` | `5000.0` | $\text{px/s}^2$ | Tasa de incremento de velocidad al presionar una dirección. |
| `friction` | `3000.0` | `5000.0` | $\text{px/s}^2$ | Tasa de desaceleración al soltar los controles de dirección. |
| `stop_threshold` | `15.0` | `15.0` | $\text{px/s}$ | Umbral mínimo por debajo del cual la velocidad se fuerza a `Vector2.ZERO` para evitar micro-deslizamientos. |

### 2.2. Presets de Herramienta (`addons/personaje_tools`)

El proyecto cuenta con un plugin de editor dedicado (`character_bar.gd`) que permite calibrar en tiempo real los perfiles de movimiento del personaje mediante tres presets de referencia:

| Preset | `speed` ($\text{px/s}$) | `acceleration` ($\text{px/s}^2$) | `friction` ($\text{px/s}^2$) | Uso / Contexto |
| :--- | :--- | :--- | :--- | :--- |
| **Sigilo** | `150.0` | `800.0` | `1000.0` | Desplazamiento lento o estado de fatiga/cautela. |
| **Normal** | `800.0` | `5000.0` | `5000.0` | Velocidad estándar de exploración durante la partida. |
| **Sprint** | `1000.0` | `5000.0` | `5000.0` | Velocidad máxima al activar la habilidad de carrera. |

### 2.3. Colisión Física
* **Nodo:** `CollisionShape2D`.
* **Forma:** Circular o rectangular compacta centrada en la base/pies del personaje.
* **Propósito:** Evitar que el jugador se atasque en las esquinas de los troncos de árboles o bordes de rocas durante persecuciones a alta velocidad, permitiendo que `move_and_slide()` deslice suavemente al personaje alrededor de los obstáculos.

---

## 3. Catálogo de Habilidades y Mecánicas

### 3.1. Locomoción en 8 Direcciones (Habilidad Base)
* **Funcionamiento:** Lectura vectorial normalizada mediante `Input.get_vector("personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo")`.
* **Normalización Diagonal:** El vector de entrada tiene longitud máxima $1.0$, garantizando que moverse en diagonal no otorgue ventaja de velocidad sobre el movimiento ortogonal.
* **Respuesta:** Gracias a la alta aceleración y fricción (`5000 px/s²`), los cambios de dirección para esquivar al monstruo son casi instantáneos.

### 3.2. Sprint y Barra de Estamina (Habilidad Activa)
* **Propósito:** Permitir al jugador romper la distancia o escapar de emboscadas críticas, especialmente en las fases avanzadas (*Persecución Media* y *Cacería Frenética* con 4+ notas) donde el monstruo iguala o supera la velocidad base de caminata.
* **Mecánica de Consumo:**
  - Al mantener presionada la acción de Sprint mientras el personaje se mueve, la velocidad máxima pasa del valor **Normal** (`800 px/s`) al valor **Sprint** (`1000 px/s`).
  - Consume estamina de forma continua desde una reserva máxima ($100\%$).
* **Mecánica de Recuperación y Fatiga:**
  - Al soltar el botón de Sprint (o detenerse), la barra de estamina se regenera gradualmente tras un breve retardo.
  - **Agotamiento (Fatiga):** Si la barra llega a $0\%$, el sprint se desactiva forzosamente y el jugador no podrá volver a correr hasta que la barra recupere un umbral mínimo de seguridad (ej. $25\% - 30\%$), evitando el *spam* de micro-sprints.

### 3.3. Salto Libre y Salto de Plancha (*Dive* en el Aire)
* **Propósito:** Mecánica evasiva y de riesgo/recompensa de alta tensión que permite sortear obstáculos bajos y zafarse de emboscadas in extremis.
* **Fase 1: Salto Libre (Despegue en Suelo):**
  - Se activa pulsando la tecla de salto (`Espacio`) mientras el personaje está en el suelo y posee estamina suficiente ($\ge 20\%$).
  - Consume un $20\%$ de estamina base.
  - **Eje Z Simulado:** En el plano 2D, se simula visualmente la elevación mediante una parábola en el eje vertical local del sprite (`Sprite2D.position.y`), encogiendo sutilmente la sombra en el suelo.
  - **Superación de Obstáculos Bajos:** Durante el vuelo ($\approx 0.45\text{ s}$), el personaje desactiva temporalmente la colisión con obstáculos bajos (como troncos caídos y piedras pequeñas), permitiendo cruzarlos mientras que el monstruo debe rodearlos. Los árboles altos y los límites perimetrales del bosque mantienen su colisión física total en todo momento.
  - Si aterriza sin realizar ninguna maniobra adicional, toca tierra de pie y continúa su marcha sin penalización.
* **Fase 2: Salto de Plancha (*Belly Dive* en el Aire):**
  - Si el jugador vuelve a presionar `Espacio` mientras el personaje está en el aire (y tiene al menos $30\%$ de estamina adicional), se lanza de bruces hacia adelante.
  - **Impulso Extra:** Otorga un fuerte estirón direccional instantáneo hacia adelante alcanzando $\approx 1200\text{ px/s}$, permitiendo ganar 2 metros críticos de distancia respecto a la criatura.
  - Consume un $30\%$ de estamina adicional.
* **Fase 3: Impacto en Suelo y Ventana de Recuperación (*Recovery Window*):**
  - Al impactar el suelo tras la plancha, el personaje cae sobre su estómago/pecho y se desliza levemente por inercia.
  - **Vulnerabilidad Total:** Queda incapacitado para moverse durante $\approx 0.6\text{ s}$ mientras se reincorpora del suelo presa del pánico. Si el monstruo se encuentra demasiado cerca, alcanzará al jugador indefenso, culminando en Game Over.
  - No es posible saltar ni lanzarse en plancha si el personaje está en estado de *Fatiga* (estamina agotada).

### 3.4. Linterna Atmosférica (Mecánica Visual / Pasiva)
* **Comportamiento:** La linterna es un elemento **decorativo y atmosférico siempre activo**. No requiere recarga de baterías ni posee interruptor de apagado manual, manteniendo el foco del jugador en el movimiento y la evasión arcade.
* **Estructura de Iluminación (`PointLight2D`):**
  1. **Halo de Proximidad:** Luz radial tenue alrededor del cuerpo del personaje para asegurar que siempre vea sus pies y los obstáculos inmediatos.
  2. **Haz Direccional:** Cono de luz frontal que proyecta visión a media distancia hacia donde mira el personaje.
* **Sistema de Orientación Híbrido (Ratón + Teclado):**
  - **Prioridad Ratón (Modo Cómodo):** Si se detecta movimiento del cursor en pantalla, la linterna rota suavemente para apuntar hacia `get_global_mouse_position()`, permitiendo explorar visualmente ángulos laterales mientras se camina en otra dirección.
  - **Fallback a Teclado (Modo 100% Teclas):** Si el jugador juega exclusivamente con teclado sin mover el ratón, la linterna se alinea automáticamente con el último vector de dirección de movimiento (`velocity.angle()`), garantizando que el juego sea completamente jugable con una sola mano o sin ratón.

### 3.5. Recolección de Notas (Pasiva / Proximidad)
* **Activación:** Automática al entrar en contacto con el área de una nota (`Area2D`).
* **Efecto Inmediato:** Incrementa el contador de puntuación, dispara el flash visual de 1 segundo sin pausar la acción y notifica al sistema de dificultad para escalar la velocidad del monstruo.

---

## 4. Máquina de Estados del Personaje (FSM)

```mermaid
stateDiagram-v2
    [*] --> Reposo: Inicio de Partida
    
    Reposo --> Caminando: Input Dirección != 0
    Caminando --> Reposo: Velocidad < stop_threshold
    
    Caminando --> Sprint: Input Sprint + Estamina > 0
    Sprint --> Caminando: Suelta Sprint
    Sprint --> Fatiga: Estamina == 0
    
    Fatiga --> Caminando: Estamina >= Umbral Mínimo (30%)
    Fatiga --> Reposo: Input Dirección == 0
    
    Reposo --> Salto: Input Salto + Estamina >= 20%
    Caminando --> Salto: Input Salto + Estamina >= 20%
    Sprint --> Salto: Input Salto (Mayor Inercia)
    
    Salto --> AterrizajePie: Fin de Arco en Aire (Sin Plancha)
    AterrizajePie --> Caminando: Input Dirección
    AterrizajePie --> Reposo: Sin Input
    
    Salto --> PlanchaAire: Input Salto en Aire + Estamina >= 30%
    PlanchaAire --> CaidaSuelo: Impacto en Suelo
    CaidaSuelo --> Recuperandose: Deslizamiento y Vulnerabilidad (0.6s)
    Recuperandose --> Reposo: Se Incorpora (Sin Input)
    Recuperandose --> Caminando: Se Incorpora (Con Input)
    
    Reposo --> Atrapado: Contacto con Monstruo
    Caminando --> Atrapado: Contacto con Monstruo
    Sprint --> Atrapado: Contacto con Monstruo
    Fatiga --> Atrapado: Contacto con Monstruo
    Salto --> Atrapado: Contacto con Monstruo
    PlanchaAire --> Atrapado: Contacto con Monstruo
    Recuperandose --> Atrapado: Contacto con Monstruo
    
    Atrapado --> [*]: Transición a Game Over
```

---

## 5. Arquitectura Técnica en Godot 4

### 5.1. Jerarquía de Escena (`escenas/personaje.tscn`)

```text
Personaje (CharacterBody2D) [scripts/personaje.gd]
├── Sprite2D / AnimatedSprite2D     # Representación visual del protagonista
├── CollisionShape2D                # Colisión física en los pies
├── PointLight2D                    # Iluminación de la linterna
├── Camera2D                        # Cámara principal (instanciada en escena principal)
└── AudioPasos (AudioStreamPlayer2D)# Reproductor de sonidos de pisadas
```

### 5.2. Mapa de Entradas (`InputMap` en `project.godot`)

| Acción en `InputMap` | Teclas / Entradas | Estado Actual | Función |
| :--- | :--- | :--- | :--- |
| `personaje-arriba` | `W` / `Flecha Arriba` | Implementado | Movimiento vertical hacia arriba ($-Y$) |
| `personaje-abajo` | `S` / `Flecha Abajo` | Implementado | Movimiento vertical hacia abajo ($+Y$) |
| `personaje-izquierda` | `A` / `Flecha Izquierda` | Implementado | Movimiento horizontal a la izquierda ($-X$) |
| `personaje-derecha` | `D` / `Flecha Derecha` | Implementado | Movimiento horizontal a la derecha ($+X$) |
| `personaje-salto` | `Espacio` | Implementado | Salto Libre (en suelo) / Salto de Plancha (*Dive*, en el aire) |
| `personaje-sprint` | `Shift` (o `Espacio` sostenido) | Configurado (`Shift` recomendado) | Carrera continua consumiendo la barra de estamina |
| *Movimiento de Ratón* | `InputEventMouseMotion` | Opcional / Híbrido | Orientación libre del haz de la linterna |

### 5.3. Integración con Sistemas de Depuración y Editor
* **Panel de Telemetría (`scripts/debug_info.gd`):** Al presionar `F3` en ejecución, el HUD de depuración inspecciona en tiempo real al nodo `Personaje`, mostrando velocidad instantánea, velocidad máxima, aceleración, fricción, vector de dirección y cruceta visual de inputs activos.
* **Barra Contextual (`addons/personaje_tools`):** Al seleccionar cualquier `CharacterBody2D` que implemente `speed`, `acceleration` y `friction` en el editor 2D de Godot, se despliega una barra superior con `SpinBox` sincronizados con soporte de `UndoRedo` y botones de presets rápidos (`Sigilo`, `Normal`, `Sprint`).
