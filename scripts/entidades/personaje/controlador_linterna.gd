@tool
class_name ControladorLinterna
extends Node2D

## Controlador de linterna frontal desacoplada 360°, halo corporal aditivo y perturbación electromagnética (flicker).

signal monstruo_enfocado(distancia: float, en_rango_critico: bool)
signal flicker_actualizado(energia: float)
signal nota_revelada(nota: Node2D, distancia: float)

@export var config: ConfiguracionIluminacion:
	set(val):
		if config != null and config.changed.is_connected(_on_config_changed):
			config.changed.disconnect(_on_config_changed)
		config = val
		if config != null:
			config.changed.connect(_on_config_changed)
		_aplicar_configuracion()

@export var objetivo_monstruo: Node2D
@export var objetivo_nota: Node2D

@onready var linterna: PointLight2D = get_node_or_null("LinternaFrontal") as PointLight2D
@onready var halo: PointLight2D = get_node_or_null("HaloCorporal") as PointLight2D

var _tiempo_desde_raton: float = 999.0
var _modo_raton_activo: bool = false
var _flicker_t: float = 0.0
var _esta_enfocando_monstruo: bool = false
var _distancia_monstruo_actual: float = INF


func _ready() -> void:
	if linterna == null:
		linterna = get_node_or_null("LinternaFrontal") as PointLight2D
	if halo == null:
		halo = get_node_or_null("HaloCorporal") as PointLight2D

	if config == null:
		if ResourceLoader.exists("res://recursos/iluminacion/config_iluminacion_defecto.tres"):
			config = load("res://recursos/iluminacion/config_iluminacion_defecto.tres") as ConfiguracionIluminacion
		else:
			config = ConfiguracionIluminacion.new()

	_aplicar_configuracion()
	_resolver_objetivo_monstruo()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var mov: float = event.relative.length()
		var umbral: float = config.umbral_movimiento_raton if config != null else 4.0
		if mov >= umbral:
			_tiempo_desde_raton = 0.0
			_modo_raton_activo = true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_tiempo_desde_raton += delta
	var tiempo_inactividad: float = config.tiempo_inactividad_raton if config != null else 1.5
	if _tiempo_desde_raton > tiempo_inactividad:
		_modo_raton_activo = false

	# 1. Orientación desacoplada 360°
	_actualizar_orientacion(delta)

	# 2. Detección analítica de la criatura y perturbación (flicker)
	_procesar_deteccion_y_flicker(delta)

	# 3. Evaluación analítica de notas ocultas dentro del haz
	procesar_revelacion_notas()


func _actualizar_orientacion(delta: float) -> void:
	if _modo_raton_activo:
		var dir_raton: Vector2 = get_global_mouse_position() - global_position
		if dir_raton.length_squared() > 1.0:
			global_rotation = dir_raton.angle()
	else:
		var parent_body := get_parent() as CharacterBody2D
		var dir_objetivo: Vector2 = Vector2.ZERO
		if parent_body != null:
			if parent_body.velocity.length_squared() > 25.0:
				dir_objetivo = parent_body.velocity.normalized()
			elif "_ultima_direccion" in parent_body and parent_body._ultima_direccion != Vector2.ZERO:
				dir_objetivo = parent_body._ultima_direccion.normalized()

		if dir_objetivo != Vector2.ZERO:
			var angulo_obj: float = dir_objetivo.angle()
			var vel_giro: float = config.velocidad_giro_teclado if config != null else 10.0
			global_rotation = rotate_toward(global_rotation, angulo_obj, vel_giro * delta)


## Evalúa analíticamente si un punto global o nodo está dentro del cono de luz.
func evaluar_posicion_en_haz(pos_objetivo: Vector2) -> Dictionary:
	var alcance: float = config.alcance_px if config != null else 700.0
	var apertura: float = config.apertura_grados if config != null else 60.0
	var cos_apertura_mitad: float = cos(deg_to_rad(apertura * 0.5))

	var pos_linterna: Vector2 = global_position if is_inside_tree() else position
	var rot_linterna: float = global_rotation if is_inside_tree() else rotation

	var delta_pos: Vector2 = pos_objetivo - pos_linterna
	var d: float = delta_pos.length()

	if d > alcance:
		return {"en_haz": false, "distancia": d, "en_rango_critico": false}

	var u_frente: Vector2 = Vector2.RIGHT.rotated(rot_linterna)
	var u_hacia: Vector2 = delta_pos / d if d > 0.001 else u_frente
	var dot_prod: float = u_frente.dot(u_hacia)

	if dot_prod >= cos_apertura_mitad:
		var dist_crit: float = config.distancia_estres_px if config != null else 300.0
		return {"en_haz": true, "distancia": d, "en_rango_critico": d < dist_crit}

	return {"en_haz": false, "distancia": d, "en_rango_critico": false}


func _procesar_deteccion_y_flicker(delta: float) -> void:
	if linterna == null:
		linterna = get_node_or_null("LinternaFrontal") as PointLight2D
	if linterna == null:
		return

	_resolver_objetivo_monstruo()

	var energia_nominal: float = config.energia_base if config != null else 1.2
	_esta_enfocando_monstruo = false
	_distancia_monstruo_actual = INF

	if objetivo_monstruo != null and is_instance_valid(objetivo_monstruo) and objetivo_monstruo.visible:
		var pos_monstruo: Vector2 = objetivo_monstruo.global_position if objetivo_monstruo.is_inside_tree() else objetivo_monstruo.position
		var resultado := evaluar_posicion_en_haz(pos_monstruo)
		if resultado["en_haz"]:
			_esta_enfocando_monstruo = true
			_distancia_monstruo_actual = resultado["distancia"]
			monstruo_enfocado.emit(resultado["distancia"], resultado["en_rango_critico"])

			if resultado["en_rango_critico"]:
				_notificar_estres_camara(delta)

	var forzar_flicker: bool = config.flicker_forzado_debug if config != null else false
	if _esta_enfocando_monstruo or forzar_flicker:
		var freq: float = config.frecuencia_flicker if config != null else 24.0
		var intensidad: float = config.intensidad_flicker if config != null else 0.10
		_flicker_t += delta * freq
		# Ruido estocástico pseudo-armónico entre -1.0 y 1.0
		var ruido: float = (
			sin(_flicker_t * 1.7) * 0.5
			+ cos(_flicker_t * 2.3) * 0.3
			+ sin(_flicker_t * 5.1) * 0.2
		)
		var energia_flicker: float = energia_nominal * (1.0 + ruido * intensidad)
		linterna.energy = energia_flicker
		flicker_actualizado.emit(energia_flicker)
	else:
		linterna.energy = energia_nominal
		flicker_actualizado.emit(energia_nominal)


func _notificar_estres_camara(delta: float) -> void:
	var viewport := get_viewport()
	if viewport != null:
		var cam := viewport.get_camera_2d()
		if cam != null and cam.has_method("agregar_trauma"):
			var tasa: float = config.tasa_estres_camara if config != null else 0.12
			cam.call("agregar_trauma", tasa * delta)


## Evalúa analíticamente si alguna nota oculta se encuentra dentro del haz y la revela.
func procesar_revelacion_notas() -> void:
	var candidatos: Array[Node2D] = []
	if objetivo_nota != null and is_instance_valid(objetivo_nota):
		candidatos.append(objetivo_nota)
	if is_inside_tree():
		var tree := get_tree()
		if tree != null:
			for n in tree.get_nodes_in_group("notas"):
				if n is Node2D and is_instance_valid(n) and not candidatos.has(n):
					candidatos.append(n as Node2D)

	for nota in candidatos:
		if nota.has_method("esta_revelada") and nota.call("esta_revelada"):
			continue
		if nota.has_method("esta_recolectada") and nota.call("esta_recolectada"):
			continue
		var pos_nota: Vector2 = nota.global_position if nota.is_inside_tree() else nota.position
		var resultado := evaluar_posicion_en_haz(pos_nota)
		if resultado.get("en_haz", false) and nota.has_method("revelar"):
			nota.call("revelar")
			nota_revelada.emit(nota, resultado.get("distancia", 0.0))


func _resolver_objetivo_monstruo() -> void:
	if objetivo_monstruo != null and is_instance_valid(objetivo_monstruo):
		return

	if not is_inside_tree():
		return

	var tree := get_tree()
	if tree != null:
		var en_grupo: Array[Node] = tree.get_nodes_in_group("monstruo")
		if not en_grupo.is_empty() and en_grupo[0] is Node2D:
			objetivo_monstruo = en_grupo[0] as Node2D
			return

		if tree.root != null:
			var candidato: Node = tree.root.find_child("Enemigo", true, false)
			if candidato != null and candidato is Node2D:
				objetivo_monstruo = candidato as Node2D


const TEXTURA_CANONICA_PATH := "res://recursos/iluminacion/textura_luz_cono.png"

var _textura_cache: Texture2D = null
var _apertura_cache: float = 60.0
var _suavizado_cache: float = 0.25


func _aplicar_configuracion() -> void:
	if config == null:
		return

	if linterna != null:
		linterna.color = config.color_linterna
		linterna.energy = config.energia_base
		linterna.blend_mode = PointLight2D.BLEND_MODE_ADD
		linterna.shadow_enabled = false
		linterna.range_layer_min = 0
		linterna.range_layer_max = 0
		linterna.offset = Vector2(256.0, 0.0)
		linterna.texture_scale = config.alcance_px / 512.0

		var es_config_por_defecto: bool = (
			is_equal_approx(config.apertura_grados, 60.0)
			and is_equal_approx(config.suavizado_borde, 0.25)
		)

		if es_config_por_defecto:
			if linterna.texture == null and ResourceLoader.exists(TEXTURA_CANONICA_PATH):
				linterna.texture = load(TEXTURA_CANONICA_PATH)
			_textura_cache = linterna.texture
			_apertura_cache = 60.0
			_suavizado_cache = 0.25
		else:
			if (
				_textura_cache == null
				or not is_equal_approx(_apertura_cache, config.apertura_grados)
				or not is_equal_approx(_suavizado_cache, config.suavizado_borde)
			):
				_apertura_cache = config.apertura_grados
				_suavizado_cache = config.suavizado_borde
				_textura_cache = GeneradorLuzCono.generar_textura_cono(
					config.alcance_px,
					config.apertura_grados,
					config.suavizado_borde,
					512
				)
				linterna.texture = _textura_cache
			elif linterna.texture != _textura_cache:
				linterna.texture = _textura_cache

	if halo != null:
		halo.color = config.color_halo
		halo.energy = config.energia_halo
		halo.blend_mode = PointLight2D.BLEND_MODE_ADD
		halo.shadow_enabled = false
		halo.range_layer_min = 0
		halo.range_layer_max = 0
		# Radio efectivo: textura de 256x256 tiene radio 128px
		var escala_halo: float = config.radio_halo_px / 128.0
		halo.texture_scale = escala_halo


func _on_config_changed() -> void:
	_aplicar_configuracion()
