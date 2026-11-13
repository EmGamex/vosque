# Contratos del Mundo, Shaders, Iluminación y TileSets

Este documento detalla las firmas de métodos, parámetros de shaders, recursos `@tool` y contratos de `TileSet` para el subsistema de mundo, mutación e iluminación de **Vosque**.

---

## 1. Contratos de Escenario y Mutación

### `Escenario` (`scripts/mundo/escenario.gd`)
```gdscript
signal sectores_mutados(cuadrante_jugador: String, variantes: Dictionary)
signal enemigo_reubicado(posicion_anterior: Vector2, posicion_nueva: Vector2, sector: String)

func obtener_cuadrante_jugador(pos_global: Vector2) -> String
func mutar_con_neblina(duracion_cierre: float = -1.0, duracion_apertura: float = -1.0, pausa_oscuridad: float = -1.0) -> void
func mutar_sectores_lejanos(sectores_permitidos: Array[String] = []) -> void
func mutar_sectores_lejanos_progresivo(sectores_permitidos: Array[String] = []) -> void
func abortar_mutacion() -> void
func validar_y_reubicar_enemigo() -> void
func actualizar_iluminacion_ambiental(notas_recolectadas: int, duracion_transicion: float = 1.0) -> void
func obtener_marcadores_nota_sectores_mutados(cuadrante_jugador: String = "") -> Array[Marker2D]
func obtener_todos_marcadores_nota() -> Array[Marker2D]
```

### `ResolutorAtascamiento` (`scripts/mundo/escenario/resolutor_atascamiento.gd`)
```gdscript
var ultimo_marcador_desatasco: Vector2 = Vector2.INF

func validar_y_reubicar_enemigo(enemigo: CharacterBody2D, pos_jugador: Vector2) -> Dictionary
func verificar_solapamiento_solido(enemigo: CharacterBody2D) -> bool
func obtener_punto_seguro_en_sector(sector: String, pos_referencia: Vector2, pos_jugador: Vector2 = Vector2.INF) -> Vector2
```

---

## 2. Niebla Geométrica y `niebla_mutacion.gdshader`

### `EfectoNieblaMutacion` (`scripts/mundo/efecto_niebla/efecto_niebla_mutacion.gd`)
```gdscript
signal ceguera_alcanzada
signal niebla_disipada
signal oscuridad_iniciada
signal oscuridad_terminada

enum Fase { DESPEJADO, CERRANDO, CEGUERA, ABRIENDO }

func cubrir(duracion: float = -1.0) -> void
func despejar(duracion: float = -1.0) -> void
func abortar_inmediato() -> void
func ejecutar_transicion(accion_en_ceguera: Callable = Callable(), t_cierre: float = -1.0, t_apertura: float = -1.0, t_pausa: float = -1.0) -> void
```

### Uniforms de `shaders/niebla_mutacion.gdshader`
| Uniform | Tipo | Valor Defecto | Propósito |
| :--- | :--- | :--- | :--- |
| `cantidad_filas` | `int` (`2..20`) | `8` | Número de bandas horizontales de cápsulas SDF. |
| `radio_capsula` | `float` | `0.035` | Grosor de cada cápsula. |
| `largo_capsula` | `float` | `0.55` | Longitud base de cada cápsula. |
| `espaciado_x` | `float` | `1.0` | Repetición periódica horizontal. |
| `variacion_filas` | `float` | `0.35` | Variación pseudoaleatoria por fila (`hash11`). |
| `fase_desplazamiento` | `float` | `0.0` | Fase monotónica acumulada desde GDScript. |
| `densidad_global` | `float` (`0..1`) | `0.0` | Opacidad maestra (`<= 0.001` corta el fragmento). |
| `radio_interno` | `float` (`0..3.5`) | `2.0` | Radio del halo despejado alrededor del jugador. |
| `suavizado` | `float` | `0.25` | Difuminado del borde del halo (`smoothstep`). |
| `centro` | `vec2` | `(0.5, 0.5)` | Posición UV del jugador en pantalla. |
| `aspecto` | `float` | `1.0` | Relación `ancho / alto` del viewport. |

---

## 3. Iluminación 2D y `GeneradorLuzCono`

### `ConfiguracionIluminacion` (`scripts/mundo/configuracion_iluminacion.gd`)
* Recurso `@tool` reactivo (emite `emit_changed()` y `changed.emit()` en cada setter).
* `calcular_color_ambiente(notas: int) -> Color`: interpola `color_ambiente_inicial` (`0.40, 0.45, 0.60, 1.0`) hacia `color_ambiente_final` (`0.18, 0.22, 0.32, 1.0`) hasta `max_notas_ambiente = 8`.

### `ControladorLinterna` (`scripts/entidades/personaje/controlador_linterna.gd`)
```gdscript
signal monstruo_enfocado(distancia: float, en_rango_critico: bool)
signal flicker_actualizado(energia: float)
signal nota_revelada(nota: Node2D, distancia: float)

func evaluar_posicion_en_haz(pos_objetivo: Vector2) -> Dictionary
# Retorna: { "en_haz": bool, "distancia": float, "en_rango_critico": bool }
func procesar_revelacion_notas() -> void
```
* **Textura canónica:** `res://recursos/iluminacion/textura_luz_cono.png` (`512x512`). Solo regenera proceduralmente con `GeneradorLuzCono.generar_textura_cono()` si `apertura_grados != 60.0` o `suavizado_borde != 0.25`.

---

## 4. Contratos de `TileSet`

1. **Suelo (`res://recursos/tileset_suelo.tres` y `res://recursos/tilesets/tileset_suelo.tres`):**
   * Debe conservar la fuente `0` original.
   * Fuente `1`: `TileSetAtlasSource` con `texture_region_size = Vector2i(64, 64)` y exactamente 4 tiles (`2x2`).
   * Probabilidades de pintado: `1.0` en `(0, 0)` y `(1, 1)`; `0.3` en `(1, 0)` y `(0, 1)`.
2. **Obstáculos (`res://recursos/tilesets/tileset_obstaculos.tres`):**
   * Contiene un `TileSetScenesCollectionSource` con al menos 5 escenas registradas: `arbol.tscn`, `roca.tscn`, `tronco_bajo.tscn`, `arbol_alto.tscn` y `roca_2.tscn`.
   * El `TileMapLayer` que lo use debe tener `y_sort_enabled = true`.

---

## 5. Matriz de Verificación

1. **`test_escenario` (`tests/test_escenario.gd`):** Valla perimetral (`4320x4320`), límites de cámara, corredores `[-960, 960]`, mutación excluyendo al jugador, desatasco del monstruo y tweens de fade.
2. **`test_niebla` (`tests/test_niebla.gd`):** Reactividad de `ConfiguracionNiebla`, clonación de `ShaderMaterial`, cálculo UV de foco, tokens de transición y ciclo completo de señales.
3. **`test_iluminacion` (`tests/test_iluminacion.gd`):** Interpolación de `CanvasModulate`, textura de cono, presupuesto máximo de 3 `PointLight2D`, detección analítica, flicker y revelación de notas.
4. **`test_tileset_suelo` (`tests/test_tileset_suelo.gd`):** Fuentes `0` y `1`, rejilla `2x2` de `64x64` y probabilidades de tile.
