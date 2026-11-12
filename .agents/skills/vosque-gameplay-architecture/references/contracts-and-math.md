# Contratos de Arquitectura y Fórmulas Matemáticas de Gameplay

Este documento contiene la especificación formal de métodos, fórmulas matemáticas y protocolos de prueba para el bucle principal de **Vosque**.

---

## 1. Contratos de la Fachada y Subcontroladores

### `Maain` (`scripts/core/maain/maain.gd`)
```gdscript
# Señales de dominio emitidas hacia arriba
signal nota_aparecida(posicion: Vector2)
signal nota_recogida(posicion: Vector2, total_recogidas: int)
signal game_over_solicitado

# Invariantes y acceso
func hay_nota_activa() -> bool
func spawn_nota_inicial() -> Nota
func generar_nota() -> Nota
func despertar_monstruo() -> void
func obtener_posicion_spawn_monstruo() -> Vector2

# Handlers internos
func _on_nota_recolectada(pos_nota: Vector2) -> void
func _on_jugador_capturado(posicion_captura: Vector2) -> void
func _on_sectores_mutados(cuadrante_jugador: String, variantes: Dictionary) -> void
```

### `SpawnerNotas` (`scripts/core/maain/spawner_notas.gd`)
```gdscript
const DISTANCIA_SEGURA_JUGADOR_DEFECTO: float = 600.0
const DISTANCIA_SEGURA_MONSTRUO_DEFECTO: float = 800.0
const TOLERANCIA_DESATASCO_SQ: float = 1.0

var nota_activa: Nota = null

func hay_nota_activa() -> bool:
    if nota_activa != null and is_instance_valid(nota_activa):
        if not nota_activa.is_queued_for_deletion() and not nota_activa.esta_recolectada():
            return true
    return false

func generar_nota(
    contenedor: Node2D,
    escena_nota: PackedScene,
    escenario: Escenario,
    jugador: Node2D,
    enemigo: Enemigo,
    distancia_segura_jugador: float = DISTANCIA_SEGURA_JUGADOR_DEFECTO,
    distancia_segura_monstruo: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO,
    callback_recolectada: Callable = Callable()
) -> Nota

static func filtrar_candidatos_espaciales(
    candidatos: Array[Marker2D],
    pos_jugador: Vector2,
    cuadrante_jugador: String,
    pos_monstruo: Vector2,
    pos_desatasco: Vector2,
    dist_min_jugador: float = DISTANCIA_SEGURA_JUGADOR_DEFECTO,
    dist_min_monstruo: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO,
    calculador_cuadrante: Callable = Callable()
) -> Array[Marker2D]

static func elegir_marcador(
    candidatos_validos: Array[Marker2D],
    candidatos_totales: Array[Marker2D],
    pos_jugador: Vector2,
    cuadrante_jugador: String,
    calculador_cuadrante: Callable = Callable()
) -> Marker2D
```

### `ControladorAmenazaMonstruo` (`scripts/core/maain/controlador_amenaza_monstruo.gd`)
```gdscript
const DISTANCIA_SEGURA_MONSTRUO_DEFECTO: float = 800.0
const POSICION_FALLBACK_ORIGEN: Vector2 = Vector2(1080.0, 1080.0)
const DISTANCIA_MINIMA_FALLBACK: float = 1000.0

func inicializar_enemigo(enemigo: Enemigo) -> void
func procesar_nota_recolectada(notas_recolectadas: int, enemigo: Enemigo, escenario: Escenario, jugador: Node2D, distancia_segura: float) -> void
func despertar_monstruo(enemigo: Enemigo, escenario: Escenario, jugador: Node2D, distancia_segura: float) -> void
func obtener_posicion_spawn_monstruo(escenario: Escenario, jugador: Node2D, distancia_segura: float) -> Vector2
static func seleccionar_posicion_spawn_monstruo(candidatos: Array[Marker2D], pos_jugador: Vector2, distancia_segura: float) -> Vector2
```

---

## 2. Lógica Atómica de Nota y Presupuesto WebGL 2.0

Jerarquía de nodos de `res://escenas/nota.tscn`:
* `Nota` (`Area2D`, capa de colisión 5: `Interactuables`, máscara 3: `Personaje`).
  * `VisualPapel` (`Sprite2D`): levitación senoidal `sin(_tiempo * 2.5) * 4.0`.
  * `CollisionShape2D` (`CircleShape2D`, radio $32\text{ px}$).
  * `LuzBaliza` (`PointLight2D`): textura radial ámbar (`Color(1.0, 0.95, 0.8, 1.0)`), modulación senoidal en `energy` ($0.65 - 0.95$, angular frequency $3.5\text{ rad/s}$ o $\tau \times 1.5\text{ Hz}$).
  * `ParticulasRecogida` (`CPUParticles2D`, 8 partículas doradas, `one_shot = true`, `lifetime = 0.4`).

```gdscript
# Protocolo estricto de recolección en nota.gd
func recolectar() -> void:
    if _recolectada:
        return
    _recolectada = true

    if _collision_shape != null:
        _collision_shape.set_deferred("disabled", true)
    else:
        set_deferred("monitoring", false)

    recolectada.emit(global_position)

    if _visual_papel != null:
        _visual_papel.visible = false
    if _luz_baliza != null:
        _luz_baliza.visible = false # Apagado sincrónico para liberar pase en WebGL 2.0

    if _particulas_recogida != null:
        _particulas_recogida.emitting = true
        var tiempo_vida: float = maxf(_particulas_recogida.lifetime, 0.4)
        get_tree().create_timer(tiempo_vida).timeout.connect(queue_free)
    else:
        queue_free()
```

---

## 3. Algoritmo de Steering Tangencial de la Criatura

Cuando la criatura impacta un muro o tronco en ángulo cerrado y su avance disminuye:
```gdscript
# Pseudocódigo de desatasco tangencial a ±45°
var velocidad_deseada: float = obtener_velocidad_efectiva()
var dir_objetivo: Vector2 = (posicion_jugador - global_position).normalized()

if is_on_wall() and not tiene_linea_vision:
    var normal_muro: Vector2 = get_wall_normal()
    var tangente_izq: Vector2 = normal_muro.rotated(deg_to_rad(45.0))
    var tangente_der: Vector2 = normal_muro.rotated(deg_to_rad(-45.0))
    
    # Seleccionar la rama que tiene mayor afinidad con la dirección al jugador
    var dir_final: Vector2 = tangente_izq if tangente_izq.dot(dir_objetivo) > tangente_der.dot(dir_objetivo) else tangente_der
    velocity = velocity.move_toward(dir_final * velocidad_deseada, acceleration * delta)
else:
    velocity = velocity.move_toward(dir_objetivo * velocidad_deseada, acceleration * delta)

move_and_slide()
```

---

## 4. Matriz de Comprobación y Tests de Regresión

Al realizar refactorizaciones o agregar características a cualquiera de estos subsistemas, ejecutar y verificar las siguientes suites de pruebas:

1. **`test_nota` (`tests/test_nota.gd`):**
   * Validación de capas de colisión (capa 5, máscara 3).
   * Verificación de la jerarquía de nodos (`VisualPapel`, `CollisionShape2D`, `LuzBaliza`, `ParticulasRecogida`).
   * Animación procedural sin desbordar los límites de energía y flotación.
   * Idempotencia de `recolectar()` y apagado sincrónico de la luz.
2. **`test_spawner` (`tests/test_spawner.gd`):**
   * Invariante de existencia de nota única.
   * Filtro de exclusión del cuadrante activo del jugador.
   * Filtro de distancia mínima al jugador ($\ge 600\text{ px}$).
   * Filtro de distancia mínima al monstruo ($\ge 800\text{ px}$).
   * Exclusión del punto de desatasco.
   * Algoritmo de fallback con distancia máxima en sectores mutados.
3. **`test_ia_monstruo` (`tests/test_ia_monstruo.gd`):**
   * Hibernación inicial en Nota 0 (`process_mode = DISABLED`, invisible, fuera de mapa).
   * Despertar en Nota 1 a $500\text{ px/s}$.
   * Escalado cuantitativo según tabla de calibración hasta $920\text{ px/s}$.
   * Margen de escape del sprint del jugador ($+80\text{ px/s}$).
   * Modulación de velocidad al $50\%$ durante la fase de oscuridad de niebla.
   * Captura y detención limpia del jugador (`detener_por_captura()`).
4. **`test_escenario` (`tests/test_escenario.gd`):**
   * Desatasco del monstruo post-mutación y registro de `ultimo_marcador_desatasco`.
