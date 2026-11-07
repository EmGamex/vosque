@tool
class_name DepuradorVisualEnemigo
extends Node2D

## Componente auxiliar para depuración y visualización de IA, estela y vectores del Enemigo.

const INTERVALO_MUESTREO_ESTELA: float = 0.04
const MAX_PUNTOS_ESTELA: int = 45
const UMBRAL_VELOCIDAD_FLECHA_SQ: float = 10.0
const FACTOR_LONGITUD_FLECHA_VELOCIDAD: float = 0.15
const LONGITUD_MIN_FLECHA_VELOCIDAD: float = 20.0
const LONGITUD_MAX_FLECHA_VELOCIDAD: float = 75.0

var dibujar_activo: bool = false:
	set(val):
		dibujar_activo = val
		if not dibujar_activo:
			_estela_puntos.clear()
		queue_redraw()

var dibujar_estela: bool = true
var dibujar_radios: bool = true
var dibujar_vector_vel: bool = true

var _estela_puntos: Array[Vector2] = []
var _timer_muestreo_estela: float = 0.0
var _enemigo: Enemigo = null


func _ready() -> void:
	_enemigo = get_parent() as Enemigo


func _process(delta: float) -> void:
	if not dibujar_activo or _enemigo == null or not is_instance_valid(_enemigo):
		return
	if _enemigo.hibernando:
		return

	_timer_muestreo_estela += delta
	if _timer_muestreo_estela >= INTERVALO_MUESTREO_ESTELA:
		_timer_muestreo_estela = 0.0
		_estela_puntos.append(_enemigo.global_position)
		if _estela_puntos.size() > MAX_PUNTOS_ESTELA:
			_estela_puntos.pop_front()
	queue_redraw()


func _draw() -> void:
	if not dibujar_activo or _enemigo == null or not is_instance_valid(_enemigo) or _enemigo.hibernando:
		return

	var camara_activa := get_viewport().get_camera_2d()
	var factor_zoom: float = camara_activa.zoom.x if (camara_activa != null and camara_activa.zoom.x > 0.01) else 1.0
	var grosor_base: float = maxf(2.0, 3.5 / factor_zoom)
	var radio_punto: float = maxf(4.0, 7.0 / factor_zoom)

	# 1. Estela de Trayectoria (Breadcrumbs con degradado alfa)
	if dibujar_estela and _estela_puntos.size() >= 2:
		var total_puntos: int = _estela_puntos.size()
		for i in range(total_puntos - 1):
			var p1: Vector2 = to_local(_estela_puntos[i])
			var p2: Vector2 = to_local(_estela_puntos[i + 1])
			var factor_t: float = float(i + 1) / float(total_puntos)
			var alfa: float = clampf(factor_t * 0.75, 0.08, 0.8)
			var color_tramo := Color(0.95, 0.45 * (1.0 - factor_t), 0.2, alfa)
			var ancho_tramo: float = maxf(1.5, (grosor_base * 0.85) * factor_t)
			draw_line(p1, p2, color_tramo, ancho_tramo)
		var ultimo_p: Vector2 = to_local(_estela_puntos[total_puntos - 1])
		draw_line(ultimo_p, Vector2.ZERO, Color(0.95, 0.2, 0.2, 0.8), grosor_base)

	# 2. Radios Concéntricos: Captura Letal y Colisión Sólida
	if dibujar_radios:
		var color_captura_fill := Color(0.9, 0.2, 0.2, 0.12)
		var color_captura_borde := Color(0.95, 0.25, 0.25, 0.75)
		draw_circle(Vector2.ZERO, Enemigo.RADIO_AREA_CAPTURA, color_captura_fill)
		draw_arc(Vector2.ZERO, Enemigo.RADIO_AREA_CAPTURA, 0.0, TAU, 32, color_captura_borde, maxf(1.5, 2.5 / factor_zoom))

		var color_colision_borde := Color(1.0, 0.8, 0.2, 0.6)
		draw_arc(Vector2.ZERO, Enemigo.RADIO_COLISION_CUERPO, 0.0, TAU, 32, color_colision_borde, maxf(1.0, 2.0 / factor_zoom))

	# 3. Vector de Velocidad Instantánea
	if dibujar_vector_vel and _enemigo.velocity.length_squared() > UMBRAL_VELOCIDAD_FLECHA_SQ:
		var direccion_velocidad: Vector2 = _enemigo.velocity.normalized()
		var longitud_flecha: float = clampf(
			_enemigo.velocity.length() * FACTOR_LONGITUD_FLECHA_VELOCIDAD,
			LONGITUD_MIN_FLECHA_VELOCIDAD,
			LONGITUD_MAX_FLECHA_VELOCIDAD
		)
		var fin_vector: Vector2 = direccion_velocidad * longitud_flecha
		var color_vector := Color(0.3, 0.8, 1.0, 0.9)
		draw_line(Vector2.ZERO, fin_vector, color_vector, grosor_base)
		var angulo_flecha: float = direccion_velocidad.angle()
		var ala_izquierda: Vector2 = fin_vector - Vector2.from_angle(angulo_flecha + 0.5) * (8.0 / factor_zoom)
		var ala_derecha: Vector2 = fin_vector - Vector2.from_angle(angulo_flecha - 0.5) * (8.0 / factor_zoom)
		draw_line(fin_vector, ala_izquierda, color_vector, grosor_base)
		draw_line(fin_vector, ala_derecha, color_vector, grosor_base)

	# 4. Línea de Visión (RayCast hacia el objetivo)
	if _enemigo.objetivo != null and is_instance_valid(_enemigo.objetivo):
		var objetivo_local: Vector2 = to_local(_enemigo.objetivo.global_position)
		if _enemigo.tiene_linea_vision:
			draw_line(Vector2.ZERO, objetivo_local, Color(0.25, 0.95, 0.45, 0.85), grosor_base)
			draw_circle(objetivo_local, radio_punto, Color(0.25, 0.95, 0.45, 0.85))
		else:
			draw_line(Vector2.ZERO, _enemigo.punto_impacto_local, Color(0.95, 0.3, 0.3, 0.9), grosor_base)
			draw_circle(_enemigo.punto_impacto_local, radio_punto, Color(1.0, 0.25, 0.25, 1.0))
			draw_dashed_line(
				_enemigo.punto_impacto_local,
				objetivo_local,
				Color(0.8, 0.4, 0.4, 0.45),
				maxf(1.0, 2.0 / factor_zoom),
				8.0 / factor_zoom
			)
