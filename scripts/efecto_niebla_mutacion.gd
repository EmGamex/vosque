@tool
class_name EfectoNieblaMutacion
extends CanvasLayer

## Controlador visual del efecto de niebla oscura durante las mutaciones de escenario.
## Permite ocultar el reemplazo procedural de sectores mediante una transición radial (iris-out / iris-in).

signal ceguera_alcanzada
signal niebla_disipada

@export_group("Depuración y Anulación")
## Desactiva por completo la niebla visual y permite que las mutaciones ocurran instantáneamente.
@export var desactivado: bool = false:
	set(val):
		if desactivado == val:
			return
		desactivado = val
		if desactivado:
			_abortar_y_limpiar()
		else:
			visible = false
			set_process(false)
			if _material_shader != null:
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

@export_range(0.5, 3.5, 0.05) var radio_despejado: float = 2.5:
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
var _animando: bool = false
var _estado_fase: String = "DESPEJADO" # "DESPEJADO", "CERRANDO", "CEGUERA", "ABRIENDO"


func _init() -> void:
	visible = false


func _ready() -> void:
	layer = 15
	visible = false
	set_process(false)

	if color_rect == null:
		color_rect = get_node_or_null("ColorRect") as ColorRect

	if color_rect != null:
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if color_rect.material is ShaderMaterial:
			if not Engine.is_editor_hint():
				_material_shader = color_rect.material.duplicate() as ShaderMaterial
				color_rect.material = _material_shader
			else:
				_material_shader = color_rect.material as ShaderMaterial

			_actualizar_parametros_shader()
			_material_shader.set_shader_parameter("radio_interno", radio_despejado)

	if not Engine.is_editor_hint():
		_resolver_referencia_jugador()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_actualizar_posicion_foco()


func _resolver_referencia_jugador() -> void:
	if not is_inside_tree():
		return

	if objetivo_jugador != null and is_instance_valid(objetivo_jugador):
		return

	# 1. Si está como hijo o hermano directo
	if get_parent() is CharacterBody2D:
		objetivo_jugador = get_parent() as Node2D
		return

	# 2. Si el padre es Escenario, comprobar su objetivo configurado
	var padre := get_parent()
	if padre != null and "objetivo_jugador" in padre and padre.get("objetivo_jugador") != null:
		var cand = padre.get("objetivo_jugador") as Node2D
		if cand != null and is_instance_valid(cand):
			objetivo_jugador = cand
			return

	# 3. Buscar en la escena raíz actual
	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		var candidato := tree.current_scene.find_child("personaje", true, false) as Node2D
		if candidato != null:
			objetivo_jugador = candidato


func _actualizar_posicion_foco() -> void:
	if not is_inside_tree() or _material_shader == null:
		return

	var vp := get_viewport()
	if vp == null:
		return

	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return

	var aspecto: float = vp_size.x / vp_size.y
	_material_shader.set_shader_parameter("aspecto", aspecto)

	if (objetivo_jugador == null or not is_instance_valid(objetivo_jugador)) and not Engine.is_editor_hint():
		_resolver_referencia_jugador()

	if objetivo_jugador != null and is_instance_valid(objetivo_jugador) and objetivo_jugador.is_inside_tree():
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


func _abortar_y_limpiar() -> void:
	var estaba_en_cierre: bool = (_estado_fase == "CERRANDO")
	var estaba_en_apertura: bool = (_estado_fase == "ABRIENDO" or _estado_fase == "CEGUERA")
	
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null

	_animando = false
	_estado_fase = "DESPEJADO"
	visible = false
	set_process(false)

	# Failsafe anti-deadlock: si había corrutinas esperando, desbloquearlas inmediatamente
	if estaba_en_cierre:
		ceguera_alcanzada.emit()
	if estaba_en_apertura:
		niebla_disipada.emit()


## Cubre la pantalla cerrando el círculo oscuro alrededor del objetivo.
func cubrir(duracion: float = -1.0) -> void:
	if desactivado:
		_estado_fase = "CEGUERA"
		ceguera_alcanzada.emit.call_deferred()
		return

	_animando = true
	_estado_fase = "CERRANDO"
	visible = true
	set_process(true)

	var t: float = duracion if duracion >= 0.0 else duracion_cierre
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_actualizar_parametros_shader()
	if _material_shader == null:
		_animando = false
		_estado_fase = "CEGUERA"
		ceguera_alcanzada.emit()
		return

	# Iniciar desde el radio actual para evitar saltos si se reanuda a mitad de camino
	var radio_inicial: float = radio_despejado
	var radio_param = _material_shader.get_shader_parameter("radio_interno")
	if radio_param is float and radio_param > radio_cerrado:
		radio_inicial = radio_param

	_tween = create_tween()
	_tween.set_trans(tipo_transicion)
	_tween.set_ease(tipo_ease_cierre)
	_tween.tween_method(
		func(val: float):
			if _material_shader != null:
				_material_shader.set_shader_parameter("radio_interno", val),
		radio_inicial,
		radio_cerrado,
		t
	)
	_tween.tween_callback(func():
		_animando = false
		_estado_fase = "CEGUERA"
		if _material_shader != null:
			_material_shader.set_shader_parameter("radio_interno", radio_cerrado)
		ceguera_alcanzada.emit()
	)


## Despeja la pantalla abriendo el círculo oscuro. Al finalizar, apaga el procesamiento y la visibilidad.
func despejar(duracion: float = -1.0) -> void:
	if desactivado:
		_animando = false
		_estado_fase = "DESPEJADO"
		visible = false
		set_process(false)
		niebla_disipada.emit.call_deferred()
		return

	var t: float = duracion if duracion >= 0.0 else duracion_apertura
	if _tween != null and _tween.is_valid():
		_tween.kill()

	_animando = true
	_estado_fase = "ABRIENDO"
	visible = true
	set_process(true)

	_actualizar_parametros_shader()
	if _material_shader == null:
		_animando = false
		_estado_fase = "DESPEJADO"
		visible = false
		set_process(false)
		niebla_disipada.emit()
		return

	var radio_inicial: float = radio_cerrado
	var radio_param = _material_shader.get_shader_parameter("radio_interno")
	if radio_param is float and radio_param < radio_despejado:
		radio_inicial = radio_param

	_tween = create_tween()
	_tween.set_trans(tipo_transicion)
	_tween.set_ease(tipo_ease_apertura)
	_tween.tween_method(
		func(val: float):
			if _material_shader != null:
				_material_shader.set_shader_parameter("radio_interno", val),
		radio_inicial,
		radio_despejado,
		t
	)
	_tween.tween_callback(func():
		_animando = false
		_estado_fase = "DESPEJADO"
		if _material_shader != null:
			_material_shader.set_shader_parameter("radio_interno", radio_despejado)
		# En reposo se oculta y detiene el process para 0% de costo en runtime
		visible = false
		set_process(false)
		niebla_disipada.emit()
	)


## Ejecuta el ciclo completo de mutación con protección asíncrona: cierre -> acción en oscuridad -> pausa -> apertura.
func ejecutar_transicion(
	accion_en_ceguera: Callable = Callable(),
	t_cierre: float = -1.0,
	t_apertura: float = -1.0,
	t_pausa: float = -1.0
) -> void:
	if desactivado:
		# Bypass instantáneo para modo de depuración: muta de inmediato sin tweens ni espera de corrutinas
		_animando = false
		_estado_fase = "DESPEJADO"
		visible = false
		set_process(false)
		if _material_shader != null:
			_material_shader.set_shader_parameter("radio_interno", radio_despejado)

		if accion_en_ceguera.is_valid():
			accion_en_ceguera.call()

		ceguera_alcanzada.emit.call_deferred()
		niebla_disipada.emit.call_deferred()
		return

	var dur_cierre: float = t_cierre if t_cierre >= 0.0 else duracion_cierre
	var dur_apertura: float = t_apertura if t_apertura >= 0.0 else duracion_apertura
	var dur_pausa: float = t_pausa if t_pausa >= 0.0 else pausa_oscuridad

	cubrir(dur_cierre)
	await ceguera_alcanzada

	if accion_en_ceguera.is_valid():
		accion_en_ceguera.call()

	if dur_pausa > 0.0 and not desactivado:
		var tree := get_tree()
		if tree != null:
			await tree.create_timer(dur_pausa).timeout

	despejar(dur_apertura)
	await niebla_disipada
