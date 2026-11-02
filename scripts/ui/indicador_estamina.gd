@tool
class_name IndicadorEstamina
extends Node2D

## Indicador circular diegético de estamina para Vosque.
## Renderiza proceduralmente un anillo radial que solo es visible bajo consumo o fatiga.

const FRECUENCIA_TITILEO: float = 16.0

@export_group("Dimensiones")
@export_range(10.0, 40.0, 1.0, "suffix:px") var radio: float = 18.0
@export_range(1.0, 8.0, 0.5, "suffix:px") var ancho_linea: float = 3.5
@export var umbral_fatiga: float = 0.30

@export_group("Colores")
@export var color_fondo: Color = Color(0.12, 0.12, 0.15, 0.45)
@export var color_normal: Color = Color("#E5A93C")
@export var color_fatiga: Color = Color("#D13438")
@export var color_destello: Color = Color(1.0, 0.96, 0.82, 1.0)

@export_group("Animación")
@export_range(0.05, 1.0, 0.05, "suffix:s") var duracion_tween_consumo: float = 0.20
@export_range(0.01, 0.5, 0.01) var umbral_consumo_brusco: float = 0.05
@export var micro_punch_al_consumir: bool = true

var ratio_estamina: float = 1.0
var ratio_visual: float = 1.0:
	set(valor):
		ratio_visual = clampf(valor, 0.0, 1.0)
		queue_redraw()

var esta_fatigado: bool = false
var _en_cierre: bool = false
var _tiempo_acumulado: float = 0.0
var _tween_animacion: Tween = null
var _tween_consumo: Tween = null
var _color_flash_actual: Color = Color.WHITE

func _ready() -> void:
	z_index = 2
	modulate.a = 0.0
	scale = Vector2.ONE
	ratio_visual = 1.0
	ratio_estamina = 1.0
	_conectar_padre()

func _process(delta: float) -> void:
	if esta_fatigado or (ratio_estamina < umbral_fatiga and ratio_estamina < 1.0):
		_tiempo_acumulado += delta
		queue_redraw()

func _conectar_padre() -> void:
	var padre = get_parent()
	if padre != null and padre.has_signal("estamina_cambiada"):
		if not padre.is_connected("estamina_cambiada", Callable(self, "actualizar_estamina")):
			padre.connect("estamina_cambiada", Callable(self, "actualizar_estamina"))

func actualizar_estamina(actual: float, maxima: float, p_fatigado: bool) -> void:
	var nuevo_ratio: float = clampf(actual / maxf(maxima, 0.001), 0.0, 1.0)
	var estamina_completa: bool = nuevo_ratio >= 0.999
	esta_fatigado = p_fatigado

	if estamina_completa:
		if _tween_consumo != null and _tween_consumo.is_valid():
			_tween_consumo.kill()
		ratio_estamina = 1.0
		ratio_visual = 1.0
		if modulate.a > 0.0 and not _en_cierre:
			_ejecutar_animacion_cierre()
		queue_redraw()
		return

	# Si se está consumiendo (< 100%)
	if _en_cierre or modulate.a < 0.99:
		_interrumpir_cierre_y_mostrar()

	var caida: float = ratio_visual - nuevo_ratio
	ratio_estamina = nuevo_ratio

	# Animar con Tween si la caída es brusca (salto, plancha/clavado)
	if caida >= umbral_consumo_brusco:
		_ejecutar_tween_consumo_brusco(nuevo_ratio)
	elif nuevo_ratio >= ratio_visual:
		# En regeneración o aumento, seguir en tiempo real
		if _tween_consumo != null and _tween_consumo.is_valid():
			_tween_consumo.kill()
		ratio_visual = nuevo_ratio
	else:
		# Consumo continuo fino (ej. sprint frame a frame)
		if _tween_consumo == null or not _tween_consumo.is_valid():
			ratio_visual = nuevo_ratio

	queue_redraw()


func _ejecutar_tween_consumo_brusco(nuevo_ratio: float) -> void:
	if _tween_consumo != null and _tween_consumo.is_valid():
		_tween_consumo.kill()

	if is_inside_tree():
		_tween_consumo = create_tween()
		_tween_consumo.tween_property(self, "ratio_visual", nuevo_ratio, duracion_tween_consumo).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if micro_punch_al_consumir:
			_tween_consumo.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), duracion_tween_consumo * 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			_tween_consumo.tween_property(self, "scale", Vector2.ONE, duracion_tween_consumo * 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	else:
		ratio_visual = nuevo_ratio

func _interrumpir_cierre_y_mostrar() -> void:
	_en_cierre = false
	_color_flash_actual = Color.WHITE
	if _tween_animacion != null and _tween_animacion.is_valid():
		_tween_animacion.kill()

	if is_inside_tree():
		_tween_animacion = create_tween().set_parallel(true)
		_tween_animacion.tween_property(self, "modulate:a", 1.0, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_animacion.tween_property(self, "scale", Vector2.ONE, 0.15).from(Vector2(0.8, 0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		modulate.a = 1.0
		scale = Vector2.ONE

func _ejecutar_animacion_cierre() -> void:
	_en_cierre = true
	if _tween_animacion != null and _tween_animacion.is_valid():
		_tween_animacion.kill()

	if not is_inside_tree():
		modulate.a = 0.0
		_en_cierre = false
		return

	# 1. Flash suave y pulso elástico de escala (1.0 -> 1.2 -> 1.0 en 0.2 s)
	_tween_animacion = create_tween()
	_color_flash_actual = color_destello
	
	# Pulso de escala
	_tween_animacion.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween_animacion.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	
	# Restaurar flash
	_tween_animacion.parallel().tween_property(self, "_color_flash_actual", Color.WHITE, 0.2)
	
	# Fade out (alfa a 0.0 en 0.3 s)
	_tween_animacion.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_tween_animacion.tween_callback(func():
		_en_cierre = false
		_color_flash_actual = Color.WHITE
		scale = Vector2.ONE
	)

func _draw() -> void:
	if modulate.a <= 0.001:
		return

	# 1. Anillo de fondo guía
	draw_arc(Vector2.ZERO, radio, 0.0, TAU, 48, color_fondo, ancho_linea, true)

	# 2. Color dinámico (normal o titileo de fatiga)
	var color_activo: Color = color_normal
	if esta_fatigado or ratio_estamina < umbral_fatiga:
		var factor_titileo: float = (sin(_tiempo_acumulado * FRECUENCIA_TITILEO) + 1.0) * 0.5
		color_activo = color_fatiga.lerp(Color(1.0, 0.5, 0.5, 1.0), factor_titileo * 0.6)

	if _en_cierre and _color_flash_actual != Color.WHITE:
		color_activo = color_activo.lerp(_color_flash_actual, 0.7)

	# 3. Anillo de progreso en sentido horario desde las 12 (-PI/2)
	var angulo_inicial: float = -PI * 0.5
	var longitud_angular: float = TAU * ratio_visual
	if longitud_angular > 0.01:
		var puntos: int = max(2, int(48 * ratio_visual))
		draw_arc(Vector2.ZERO, radio, angulo_inicial, angulo_inicial + longitud_angular, puntos, color_activo, ancho_linea, true)
