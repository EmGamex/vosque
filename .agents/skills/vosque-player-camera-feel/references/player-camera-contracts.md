# Contratos Técnicos: Personaje, Cámara y Game Feel

Referencia detallada de constantes, fórmulas, contratos de API y *gotchas* verificados en el código fuente de **Vosque**.

---

## 1. Propiedades `@export` y Overrides de Escena (`Personaje`)

| Grupo / Propiedad | Default en `personaje.gd` | Override en `personaje.tscn` | Unidad / Rango |
| :--- | :---: | :---: | :--- |
| `speed` | `800.0` | — | `50.0..3000.0 px/s` |
| `sprint_speed` | `1000.0` | — | `50.0..3000.0 px/s` |
| `acceleration` | `5000.0` | — | `0.0..10000.0 px/s²` |
| `friction` | `5000.0` | — | `0.0..10000.0 px/s²` |
| `stop_threshold` | `15.0` | — | `0.0..100.0 px/s` |
| `max_stamina` | `100.0` | — | `10.0..500.0 pts` |
| `sprint_drain_rate` | `25.0` | — | `0.0..100.0 pts/s` |
| `stamina_regen_rate` | `20.0` | **`60.0`** | `0.0..100.0 pts/s` |
| `stamina_regen_delay` | `0.8` | — | `0.0..5.0 s` |
| `fatigue_recovery_threshold` | `30.0` | — | `0.0..100.0 pts` |
| `jump_stamina_cost` | `20.0` | — | `0.0..100.0 pts` |
| `jump_duration` | `0.45` | — | `0.1..2.0 s` |
| `jump_height` | `56.0` | — | `10.0..200.0 px` |
| `shadow_min_scale` | `Vector2(0.6, 0.6)` | — | — |
| `dive_stamina_cost` | `30.0` | — | `0.0..100.0 pts` |
| `dive_speed` | `1200.0` | — | `100.0..3000.0 px/s` |
| `dive_recovery_duration` | `0.6` | — | `0.1..2.0 s` |
| `dive_slide_friction` | `2200.0` | — | `0.0..10000.0 px/s²` |
| `note_stamina_restore_ratio` | `0.5` | — | `0.0..1.0` |
| `note_speed_boost_multiplier` | `1.2` | — | `1.0..2.0` |
| `note_speed_boost_duration` | `1.5` | — | `0.0..5.0 s` |
| `note_no_stamina_drain_duration` | `1.5` | — | `0.0..10.0 s` |
| `note_boost_tint` | `Color(0.75, 1.0, 0.9, 1.0)` | — | — |

* **Señales:** `estamina_cambiada(actual: float, maxima: float, fatigado: bool)`, `estado_cambiado(nuevo_estado: Estado, nombre_estado: String)`.
* **Acciones `InputMap` (`project.godot`):** `personaje-arriba`, `personaje-abajo`, `personaje-izquierda`, `personaje-derecha`, `personaje-salto` (`Espacio`), `sprint` (`Shift`) y soporte opcional si existe `personaje-sprint`.

---

## 2. Fórmulas de Eje Z y Cadena de Animaciones

### Eje Z Simulado
* **Salto Libre (`SALTO`):**
  * $u = \text{clamp}(\_tiempo\_aire / \_duracion\_aire\_actual, 0.0, 1.0)$
  * $\text{factor\_altura} = 4.0 \cdot u \cdot (1.0 - u)$
  * Control aéreo horizontal: `velocity.move_toward(direction * max(speed, velocity.length()), acceleration * 0.5 * delta)`.
* **Plancha en Aire (`PLANCHA_AIRE`):**
  * $\_altura\_despegue = \max(0.2, 4.0 \cdot u_{\text{actual}} \cdot (1.0 - u_{\text{actual}}))$
  * $\_duracion\_aire\_actual = \max(0.2, \text{jump\_duration} \cdot 0.5)$
  * $\text{factor\_restante} = (1.0 - u_{\text{plancha}}) \cdot \_altura\_despegue$
  * Impulso inicial: `velocity = _direccion_plancha * dive_speed`.
* **Sincronización de hijos en `_aplicar_elevacion_eje_z(factor_altura)`:**
  * `Visual.position.y = -jump_height * factor_altura`
  * `IndicadorEstamina.position.y = -60.0 - jump_height * factor_altura`
  * `TutorialCabeza.position.y = -90.0 - jump_height * factor_altura`

### Fallbacks de `AnimatedSprite2D`
* `REPOSO`: `idle-lado` $\to$ `[idle, lado, idle-arriba]`; `idle-abajo` $\to$ `[idle, idle-arriba, arriba]`; `idle-arriba` $\to$ `[idle, arriba]`.
* Movimiento diagonal (`abs_x > 0.3 && abs_y > 0.3`): `diagonal-abajo` $\to$ `[diagonal-arriba, diagonal, lado]`; `diagonal-arriba` $\to$ `[diagonal, lado]`.
* Movimiento cardinal: `abajo` $\to$ `[idle-abajo, diagonal-abajo, lado]`; `arriba` $\to$ `[idle-arriba, idle]`; `lado` $\to$ `[idle-lado, diagonal-arriba]`.

---

## 3. Contratos de `IndicadorEstamina` y `TutorialCabeza`

### `IndicadorEstamina` (`scripts/ui/indicador_estamina.gd`)
* **Constantes / Exports:** `FRECUENCIA_TITILEO = 16.0`, `radio = 18.0`, `ancho_linea = 3.5`, `umbral_fatiga = 0.30`, `duracion_tween_consumo = 0.20`, `umbral_consumo_brusco = 0.05`, `micro_punch_al_consumir = true`.
* **Comportamiento sin árbol (tests):** Si `not is_inside_tree()`, las transiciones aplican `modulate.a` y `ratio_visual` de forma inmediata sin crear `Tween`.

### `TutorialCabeza` (`scripts/ui/tutorial_cabeza/`)
* **Constantes:** `UMBRAL_MOVIMIENTO_RATON = 30.0`, `TIEMPO_GRACIA_PASO_1 = 0.35`, `tiempo_iluminacion_raton = 0.35`.
* **Señales:** `paso_cambiado(nuevo_paso)`, `tutorial_finalizado(es_fast_path)`, `fast_path_detectado`.
* **Cache de estilos (`TutorialVistaController`):** Usa recursos `StyleBoxFlat` precargados (`res://recursos/ui/tutorial/sb_*.tres`) para evitar asignaciones por frame.

---

## 4. Cámara 2D, Shaders y `personaje_tools`

### Contrato Objetivo de Trauma en `Camera2D`
* `ControladorLinterna._notificar_estres_camara()` llama `cam.call("agregar_trauma", tasa * delta)` (por defecto `tasa_estres_camara = 0.12 pts/s`).
* Si se añade un script a `escenas/camara.tscn`, debe exponer:
  ```gdscript
  func agregar_trauma(cantidad: float) -> void
  ```
  con decaimiento lineal (`decay_rate ≈ 1.4 pts/s`) y desplazamiento cuadrático ($\text{Trauma}^2 \times \text{AmplitudMáxima} \times \text{Ruido}$).

### Shaders
* `shaders/motion_blur_vertical.gdshader`: `screen_texture` (`hint_screen_texture`), `intensidad` (`0.0..0.1`), `direccion` (`vec2(0, 1)`), `muestras` (`3..16`). Cortocircuita a lectura directa si `intensidad <= 0.0001`.
* `shaders/crossfade_arboles.gdshader`: `textura_anterior` (`hint_default_transparent`), `progreso` (`0.0..1.0`). Cortocircuita en los extremos `<= 0.0001` y `>= 0.9999`.

### `addons/personaje_tools/character_bar.gd`
* Presets: `Sigilo` (`150 / 800 / 1000`), `Normal` (`800 / 5000 / 5000`), `Sprint` (`1000 / 5000 / 5000`).
* Reconstrúyase estado interno tras hot-reload `@tool` con `_asegurar_estado()` y respétese `PROPERTY_HINT_RANGE` leído desde `Personaje`.

---

## 5. Registro de Gotchas Actuales en el Repo

1. **`Sombra` anidada bajo `Visual`:** En `escenas/personaje.tscn`, `Sombra` está en `Visual/Sombra`, pero `personaje.gd` busca `get_node_or_null("Sombra")` en la raíz (`null`). Mientras no se mueva a raíz en la escena, la sombra se eleva con `Visual` al saltar.
2. **Offset de `TutorialCabeza`:** La escena fija `Vector2(0, -112)`, pero `_aplicar_elevacion_eje_z()` / `_restaurar_visuales_eje_z()` usan `-90.0`.
3. **`camara.tscn` sin script:** `agregar_trauma` aún no está implementado en `escenas/camara.tscn`; `ControladorLinterna` lo protege con `has_method("agregar_trauma")`.
