@tool
class_name IndicadorFueraPantalla
extends Node2D

## Componente modular para proyectar un indicador visual en el borde de la pantalla
## cuando la entidad que lo contiene sale del campo de visión de la cámara.

@export var habilitar: bool = true
@export var textura: Texture2D = preload("res://icon.svg")
@export var rotar_hacia_objetivo: bool = false
@export var margen_pantalla: float = 36.0
@export var escala: Vector2 = Vector2.ONE
@export var color_modulacion: Color = Color.WHITE
@export var duracion_fade: float = 0.2

var _notifier: VisibleOnScreenNotifier2D = null
var _capa_canvas: CanvasLayer = null
var _sprite: Sprite2D = null
var _indicador_visible: bool = false
var _tween_fade: Tween = null
var _padre_enemigo: Enemigo = null


func _ready() -> void:
	if Engine.is_editor_hint():
		return

	_conectar_padre()
	_inicializar_componentes()


func _exit_tree() -> void:
	if _capa_canvas != null and is_instance_valid(_capa_canvas):
		_capa_canvas.queue_free()
		_capa_canvas = null


func _conectar_padre() -> void:
	var padre := get_parent()
	if padre is Enemigo:
		_padre_enemigo = padre
		if not _padre_enemigo.hibernado.is_connected(_on_padre_hibernado):
			_padre_enemigo.hibernado.connect(_on_padre_hibernado)
		if not _padre_enemigo.despertado.is_connected(_on_padre_despertado):
			_padre_enemigo.despertado.connect(_on_padre_despertado)


func _inicializar_componentes() -> void:
	# 1. Asegurar o crear VisibleOnScreenNotifier2D
	_notifier = get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
	if _notifier == null:
		_notifier = VisibleOnScreenNotifier2D.new()
		_notifier.name = "VisibleOnScreenNotifier2D"
		_notifier.rect = Rect2(-60.0, -60.0, 120.0, 120.0)
		add_child(_notifier)

	if not _notifier.screen_entered.is_connected(_on_screen_entered):
		_notifier.screen_entered.connect(_on_screen_entered)
	if not _notifier.screen_exited.is_connected(_on_screen_exited):
		_notifier.screen_exited.connect(_on_screen_exited)

	# 2. Crear CanvasLayer autónomo para renderizar libre de shaders de mundo y cámara
	if _capa_canvas == null:
		_capa_canvas = CanvasLayer.new()
		_capa_canvas.name = "CapaIndicadorFueraPantalla"
		_capa_canvas.layer = 15
		add_child(_capa_canvas)

		_sprite = Sprite2D.new()
		_sprite.name = "SpriteIndicador"
		_sprite.texture = textura
		_sprite.scale = escala
		_sprite.modulate = Color(color_modulacion.r, color_modulacion.g, color_modulacion.b, 0.0)
		_sprite.visible = false
		_capa_canvas.add_child(_sprite)


func _on_screen_entered() -> void:
	_ocultar_fade()


func _on_screen_exited() -> void:
	if _debe_estar_activo():
		_mostrar_fade()


func _on_padre_hibernado() -> void:
	_ocultar_fade(true)


func _on_padre_despertado(_vel: float) -> void:
	if _notifier != null and not _notifier.is_on_screen() and _debe_estar_activo():
		_mostrar_fade()


func _debe_estar_activo() -> bool:
	if not habilitar:
		return false
	var padre := get_parent()
	if padre == null or not is_instance_valid(padre):
		return false
	if _padre_enemigo != null and (_padre_enemigo.hibernando or _padre_enemigo.get("_capturado") == true):
		return false
	if not padre.is_visible_in_tree() or padre.process_mode == Node.PROCESS_MODE_DISABLED:
		return false
	return true


func _mostrar_fade() -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		return
	_indicador_visible = true
	_sprite.visible = true
	if _tween_fade != null and _tween_fade.is_valid():
		_tween_fade.kill()

	_tween_fade = create_tween().set_parallel(true)
	_tween_fade.tween_property(_sprite, "modulate:a", color_modulacion.a, duracion_fade)
	_tween_fade.tween_property(_sprite, "scale", escala, duracion_fade).from(escala * 0.7)


func _ocultar_fade(instantaneo: bool = false) -> void:
	if _sprite == null or not is_instance_valid(_sprite):
		return
	_indicador_visible = false
	if _tween_fade != null and _tween_fade.is_valid():
		_tween_fade.kill()

	if instantaneo or duracion_fade <= 0.0:
		_sprite.modulate.a = 0.0
		_sprite.visible = false
		return

	_tween_fade = create_tween()
	_tween_fade.tween_property(_sprite, "modulate:a", 0.0, duracion_fade)
	_tween_fade.tween_callback(func():
		if not _indicador_visible and _sprite != null:
			_sprite.visible = false
	)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_actualizar_posicion_pantalla()


func _actualizar_posicion_pantalla() -> void:
	if not _debe_estar_activo():
		if _indicador_visible or (_sprite != null and _sprite.visible):
			_ocultar_fade(true)
		return

	var esta_en_pantalla: bool = _notifier != null and _notifier.is_on_screen()
	if esta_en_pantalla:
		if _indicador_visible:
			_ocultar_fade()
		return
	else:
		if not _indicador_visible:
			_mostrar_fade()

	if _sprite == null or not is_instance_valid(_sprite) or not _sprite.visible:
		return

	if _sprite.texture != textura:
		_sprite.texture = textura

	var viewport := get_viewport()
	if viewport == null:
		return

	var camara := viewport.get_camera_2d()
	var rect_vp := viewport.get_visible_rect()
	var centro_vp: Vector2 = rect_vp.size * 0.5

	# Coordenadas en pantalla
	var pos_pantalla: Vector2
	if camara != null:
		pos_pantalla = (global_position - camara.get_screen_center_position()) * camara.zoom + centro_vp
	else:
		pos_pantalla = viewport.get_canvas_transform() * global_position

	var delta_pos: Vector2 = pos_pantalla - centro_vp
	if delta_pos.length_squared() < 0.001:
		delta_pos = Vector2.UP

	var dir: Vector2 = delta_pos.normalized()

	# Intersección rectangular con margen
	var limite_min := Vector2(margen_pantalla, margen_pantalla)
	var limite_max := rect_vp.size - Vector2(margen_pantalla, margen_pantalla)

	var escala_t: float = INF
	if dir.x > 0.0001:
		escala_t = minf(escala_t, (limite_max.x - centro_vp.x) / dir.x)
	elif dir.x < -0.0001:
		escala_t = minf(escala_t, (limite_min.x - centro_vp.x) / dir.x)

	if dir.y > 0.0001:
		escala_t = minf(escala_t, (limite_max.y - centro_vp.y) / dir.y)
	elif dir.y < -0.0001:
		escala_t = minf(escala_t, (limite_min.y - centro_vp.y) / dir.y)

	var pos_borde := centro_vp + dir * escala_t
	pos_borde.x = clampf(pos_borde.x, limite_min.x, limite_max.x)
	pos_borde.y = clampf(pos_borde.y, limite_min.y, limite_max.y)

	_sprite.position = pos_borde

	if rotar_hacia_objetivo:
		_sprite.rotation = dir.angle()
	else:
		_sprite.rotation = 0.0
