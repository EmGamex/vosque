@tool
class_name Nota
extends Area2D

## Entidad coleccionable Nota con baliza luminosa y recolección arcade fluida.

signal revelada(posicion_global: Vector2)
signal recolectada(posicion_global: Vector2)

const ENERGIA_BASE: float = 0.8
const AMPLITUD_PULSO: float = 0.15
const FRECUENCIA_HZ: float = 1.5
const FRECUENCIA_ANGULAR: float = TAU * FRECUENCIA_HZ # ~9.42478 rad/s
const AMPLITUD_FLOTACION: float = 4.0
const VELOCIDAD_FLOTACION: float = 2.5
const DURACION_FADE_REVELACION: float = 0.25

@export var sfx_recoleccion: AudioStream = preload("res://sonido/sfx/gameplay/recolectar-nota.wav")

var _tiempo: float = 0.0
var _revelada: bool = false
var _recolectada: bool = false
var _tween_revelacion: Tween = null

@onready var _visual_papel: Sprite2D = get_node_or_null("VisualPapel") as Sprite2D
@onready var _collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var _luz_baliza: PointLight2D = get_node_or_null("LuzBaliza") as PointLight2D
@onready var _particulas_recogida: CPUParticles2D = get_node_or_null("ParticulasRecogida") as CPUParticles2D
@onready var _sfx_revelacion: AudioStreamPlayer2D = get_node_or_null("SfxRevelacion") as AudioStreamPlayer2D
@onready var _sfx_recoleccion: AudioStreamPlayer2D = get_node_or_null("SfxRecoleccion") as AudioStreamPlayer2D


func esta_revelada() -> bool:
	return _revelada


func esta_recolectada() -> bool:
	return _recolectada


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	var es_escena_editada: bool = Engine.is_editor_hint() and is_inside_tree() and get_tree() != null and get_tree().edited_scene_root == self
	if not es_escena_editada:
		_aplicar_estado_oculto_inicial()
		if _particulas_recogida != null:
			# Calentar el buffer de partículas para evitar microtirones al emitir
			_particulas_recogida.emitting = false
			_particulas_recogida.restart()


func _aplicar_estado_oculto_inicial() -> void:
	_revelada = false
	if _visual_papel != null:
		_visual_papel.visible = false
		_visual_papel.modulate.a = 0.0
	if _luz_baliza != null:
		_luz_baliza.visible = false


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if _visual_papel != null:
			_visual_papel.position.y = 0.0
		if _luz_baliza != null:
			_luz_baliza.energy = ENERGIA_BASE
		return
	if not _revelada or _recolectada:
		return
	_tiempo += delta
	if _visual_papel != null:
		_visual_papel.position.y = sin(_tiempo * VELOCIDAD_FLOTACION) * AMPLITUD_FLOTACION
	if _luz_baliza != null:
		_luz_baliza.energy = ENERGIA_BASE + sin(_tiempo * FRECUENCIA_ANGULAR) * AMPLITUD_PULSO


func revelar() -> void:
	if _revelada or _recolectada:
		return
	_revelada = true

	if _visual_papel != null:
		_visual_papel.visible = true
		if is_inside_tree():
			_visual_papel.modulate.a = 0.0
			if _tween_revelacion != null and _tween_revelacion.is_valid():
				_tween_revelacion.kill()
			_tween_revelacion = create_tween()
			_tween_revelacion.tween_property(_visual_papel, "modulate:a", 1.0, DURACION_FADE_REVELACION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		else:
			_visual_papel.modulate.a = 1.0

	if _luz_baliza != null:
		_luz_baliza.energy = ENERGIA_BASE
		_luz_baliza.visible = true

	if _sfx_revelacion != null and _sfx_revelacion.stream != null and is_inside_tree():
		_sfx_revelacion.play()

	revelada.emit(global_position)


func recolectar() -> void:
	if not _revelada or _recolectada:
		return
	_recolectada = true
	if _tween_revelacion != null and _tween_revelacion.is_valid():
		_tween_revelacion.kill()

	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", true)
	else:
		set_deferred("monitoring", false)

	recolectada.emit(global_position)

	if _visual_papel != null:
		_visual_papel.visible = false
	if _luz_baliza != null:
		_luz_baliza.visible = false

	var duracion_sfx: float = 0.0
	if _sfx_recoleccion != null:
		if sfx_recoleccion != null:
			_sfx_recoleccion.stream = sfx_recoleccion
		if _sfx_recoleccion.stream != null and is_inside_tree():
			_sfx_recoleccion.pitch_scale = randf_range(0.96, 1.04)
			_sfx_recoleccion.play()
			duracion_sfx = _sfx_recoleccion.stream.get_length() / maxf(_sfx_recoleccion.pitch_scale, 0.01)

	var tiempo_espera: float = duracion_sfx
	if _particulas_recogida != null:
		_particulas_recogida.emitting = true
		tiempo_espera = maxf(tiempo_espera, maxf(_particulas_recogida.lifetime, 0.4))

	if tiempo_espera > 0.0 and is_inside_tree():
		var arbol := get_tree()
		if arbol != null:
			arbol.create_timer(tiempo_espera).timeout.connect(queue_free)
		else:
			queue_free()
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if not _revelada or _recolectada:
		return
	if _es_jugador(body):
		recolectar()


func _es_jugador(body: Node2D) -> bool:
	if body == null:
		return false
	if body is Personaje:
		return true
	if body.is_in_group("jugador"):
		return true
	if body.name.to_lower() == "personaje":
		return true
	return false
