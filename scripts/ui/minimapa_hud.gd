@tool
class_name MinimapaHUD
extends Control

## Minimapa esquemático 2x2 para el HUD de Vosque.
## Muestra la posición normalizada del jugador ([-2160, 2160] -> [0, 1])
## y resalta el cuadrante objetivo de la nota activa sin mostrar al monstruo.

const LIMITE_MAPA_PX: float = 2160.0
const ANCHO_MAPA_PX: float = 4320.0
const CUADRANTES_RECT: Dictionary = {
	"NO": Rect2(0.0, 0.0, 0.5, 0.5),
	"NE": Rect2(0.5, 0.0, 0.5, 0.5),
	"SO": Rect2(0.0, 0.5, 0.5, 0.5),
	"SE": Rect2(0.5, 0.5, 0.5, 0.5),
}

@export var color_fondo: Color = Color(0.06, 0.08, 0.12, 0.58)
@export var color_borde: Color = Color(0.55, 0.65, 0.80, 0.40)
@export var color_cuadrante_oculto: Color = Color(0.90, 0.66, 0.24, 1.0)
@export var color_cuadrante_revelado: Color = Color(0.45, 0.92, 0.58, 1.0)
@export var color_jugador: Color = Color(0.92, 0.98, 1.0, 1.0)
@export var radio_jugador_px: float = 3.5

var pos_jugador_norm: Vector2 = Vector2(0.5, 0.5)
var cuadrante_objetivo: String = ""
var nota_revelada: bool = false

var _tiempo_pulso: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(120.0, 120.0)
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not cuadrante_objetivo.is_empty():
		_tiempo_pulso += delta
		queue_redraw()


static func normalizar_posicion_mapa(pos_mundo: Vector2) -> Vector2:
	var nx: float = clampf((pos_mundo.x + LIMITE_MAPA_PX) / ANCHO_MAPA_PX, 0.0, 1.0)
	var ny: float = clampf((pos_mundo.y + LIMITE_MAPA_PX) / ANCHO_MAPA_PX, 0.0, 1.0)
	return Vector2(nx, ny)


func actualizar_posicion_jugador(pos_mundo: Vector2) -> void:
	pos_jugador_norm = normalizar_posicion_mapa(pos_mundo)
	queue_redraw()


func actualizar_objetivo(cuadrante: String, esta_revelada: bool = false) -> void:
	cuadrante_objetivo = cuadrante
	nota_revelada = esta_revelada
	queue_redraw()


func marcar_nota_revelada(esta_revelada: bool = true) -> void:
	nota_revelada = esta_revelada
	queue_redraw()


func limpiar_objetivo() -> void:
	cuadrante_objetivo = ""
	nota_revelada = false
	queue_redraw()


func _draw() -> void:
	var tam: Vector2 = size if size.x > 1.0 and size.y > 1.0 else custom_minimum_size
	var rect_total := Rect2(Vector2.ZERO, tam)

	draw_rect(rect_total, color_fondo, true)

	if CUADRANTES_RECT.has(cuadrante_objetivo):
		var norm_rect: Rect2 = CUADRANTES_RECT[cuadrante_objetivo]
		var quad_rect := Rect2(norm_rect.position * tam, norm_rect.size * tam)
		var pulso: float = (sin(_tiempo_pulso * 3.2) + 1.0) * 0.5
		if nota_revelada:
			var col_fill := color_cuadrante_revelado
			col_fill.a = lerpf(0.28, 0.46, pulso)
			draw_rect(quad_rect, col_fill, true)
			var col_edge := color_cuadrante_revelado
			col_edge.a = 0.85
			draw_rect(quad_rect, col_edge, false, 1.5)
		else:
			var col_fill := color_cuadrante_oculto
			col_fill.a = lerpf(0.16, 0.38, pulso)
			draw_rect(quad_rect, col_fill, true)
			var col_edge := color_cuadrante_oculto
			col_edge.a = 0.60
			draw_rect(quad_rect, col_edge, false, 1.0)

	var mitad := tam * 0.5
	draw_line(Vector2(mitad.x, 0.0), Vector2(mitad.x, tam.y), color_borde, 1.0)
	draw_line(Vector2(0.0, mitad.y), Vector2(tam.x, mitad.y), color_borde, 1.0)
	draw_rect(rect_total, color_borde, false, 1.5)

	var pos_px := Vector2(pos_jugador_norm.x * tam.x, pos_jugador_norm.y * tam.y)
	draw_circle(pos_px, radio_jugador_px + 1.5, Color(0.0, 0.0, 0.0, 0.55))
	draw_circle(pos_px, radio_jugador_px, color_jugador)
