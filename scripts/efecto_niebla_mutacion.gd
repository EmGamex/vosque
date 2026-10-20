@tool
class_name EfectoNieblaMutacion
extends CanvasLayer

## Controlador visual del efecto de niebla oscura durante las mutaciones de escenario.

signal ceguera_alcanzada
signal niebla_disipada

@export_group("Depuración y Anulación")
## Desactiva por completo la niebla visual y permite que las mutaciones ocurran instantáneamente.
@export var desactivado: bool = false:
	set(val):
		desactivado = val
		visible = not desactivado
		if not desactivado and _material_shader != null:
			_material_shader.set_shader_parameter("radio_interno", radio_despejado)

@export_group("Objetivo de Enfoque")
## Nodo al que la niebla sigue dinámicamente en pantalla (incluso cuando la cámara se detiene por límites).
@export var objetivo_jugador: Node2D

@export_group("Tiempos de Transición")
@export_range(0.1, 10.0, 0.1, "suffix:s") var duracion_cierre: float = 1.3
@export_range(0.0, 5.0, 0.1, "suffix:s") var pausa_oscuridad: float = 0.4
@export_range(0.1, 10.0, 0.1, "suffix:s") var duracion_apertura: float = 1.3

@export_group("Curvas de Animación")
@export var tipo_transicion: Tween.TransitionType = Tween.TRANS_SINE
@export var tipo_ease_cierre: Tween.EaseType = Tween.EASE_IN
@export var tipo_ease_apertura: Tween.EaseType = Tween.EASE_OUT

@export_group("Apariencia de Niebla")
@export var color_niebla: Color = Color(0.04, 0.05, 0.08, 1.0):
	set(val):
		color_niebla = val
		_actualizar_parametros_shader()

@export_range(0.01, 1.0, 0.01) var difuminado_borde: float = 0.45:
	set(val):
		difuminado_borde = val
		_actualizar_parametros_shader()

@export_range(0.5, 2.5, 0.05) var radio_despejado: float = 1.3:
	set(val):
		radio_despejado = val
		_actualizar_parametros_shader()

@export_range(0.0, 0.5, 0.01) var radio_cerrado: float = 0.05:
	set(val):
		radio_cerrado = val
		_actualizar_parametros_shader()

@export var centro_pantalla: Vector2 = Vector2(0.5, 0.5):
	set(val):
		centro_pantalla = val
		_actualizar_parametros_shader()

@onready var color_rect: ColorRect = get_node_or_null("ColorRect") as ColorRect

var _material_shader: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	layer = 15
	visible = not desactivado
	if color_rect == null:
		color_rect = get_node_or_null("ColorRect") as ColorRect

	if color_rect != null:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if color_rect.material is ShaderMaterial:
			# Duplicar material en ejecución para que la animación sea local
			if not Engine.is_editor_hint():
				_material_shader = color_rect.material.duplicate() as ShaderMaterial
				color_rect.material = _material_shader
			else:
				_material_shader = color_rect.material as ShaderMaterial
			_actualizar_parametros_shader()
			_material_shader.set_shader_parameter("radio_interno", radio_despejado)

	_resolver_referencia_jugador()


func _process(_delta: float) -> void:
	_actualizar_posicion_foco()


func _resolver_referencia_jugador() -> void:
	if objetivo_jugador != null and is_instance_valid(objetivo_jugador):
		return

	# 1. Si está como hijo del personaje
	if get_parent() is CharacterBody2D or (get_parent() != null and get_parent().name == "personaje"):
		objetivo_jugador = get_parent() as Node2D
		return

	# 2. Si está en Escenario, buscar hermano o ancestro
	if get_parent() != null and get_parent().get_parent() != null:
		var candidato = get_parent().get_parent().find_child("personaje", true, false) as Node2D
		if candidato != null:
			objetivo_jugador = candidato
			return

	# 3. Buscar en la escena actual
	var tree = get_tree()
	if tree != null and tree.current_scene != null:
		var candidato = tree.current_scene.find_child("personaje", true, false) as Node2D
		if candidato != null:
			objetivo_jugador = candidato


func _actualizar_posicion_foco() -> void:
	if _material_shader == null:
		return

	var vp := get_viewport()
	if vp == null:
		return

	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	var aspecto: float = vp_size.x / vp_size.y
	_material_shader.set_shader_parameter("aspecto", aspecto)

	if objetivo_jugador == null or not is_instance_valid(objetivo_jugador):
		_resolver_referencia_jugador()

	if objetivo_jugador != null and is_instance_valid(objetivo_jugador) and objetivo_jugador.is_inside_tree():
		# get_global_transform_with_canvas().origin devuelve la posición exacta en píxeles dentro de la pantalla
		var pos_pantalla: Vector2 = objetivo_jugador.get_global_transform_with_canvas().origin
		var uv_foco: Vector2 = pos_pantalla / vp_size
		_material_shader.set_shader_parameter("centro", uv_foco)
	else:
		_material_shader.set_shader_parameter("centro", centro_pantalla)


func _actualizar_parametros_shader() -> void:
	if _material_shader == null and color_rect != null and color_rect.material is ShaderMaterial:
		_material_shader = color_rect.material as ShaderMaterial

	if _material_shader != null:
		_material_shader.set_shader_parameter("color_niebla", color_niebla)
		_material_shader.set_shader_parameter("suavizado", difuminado_borde)
		_actualizar_posicion_foco()


func cubrir(duracion: float = -1.0) -> void:
	if desactivado:
		ceguera_alcanzada.emit()
		return

	var t: float = duracion if duracion >= 0.0 else duracion_cierre
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_actualizar_parametros_shader()
	if _material_shader == null:
		ceguera_alcanzada.emit()
		return

	_tween = create_tween()
	_tween.set_trans(tipo_transicion)
	_tween.set_ease(tipo_ease_cierre)
	_tween.tween_method(
		func(val: float): _material_shader.set_shader_parameter("radio_interno", val),
		radio_despejado,
		radio_cerrado,
		t
	)
	_tween.tween_callback(func(): ceguera_alcanzada.emit())


func despejar(duracion: float = -1.0) -> void:
	if desactivado:
		niebla_disipada.emit()
		return

	var t: float = duracion if duracion >= 0.0 else duracion_apertura
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_actualizar_parametros_shader()
	if _material_shader == null:
		niebla_disipada.emit()
		return

	_tween = create_tween()
	_tween.set_trans(tipo_transicion)
	_tween.set_ease(tipo_ease_apertura)
	_tween.tween_method(
		func(val: float): _material_shader.set_shader_parameter("radio_interno", val),
		radio_cerrado,
		radio_despejado,
		t
	)
	_tween.tween_callback(func(): niebla_disipada.emit())
