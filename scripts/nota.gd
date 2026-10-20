@tool
class_name Nota
extends Area2D

## Entidad coleccionable Nota con baliza luminosa y recolección arcade fluida.

signal recolectada(posicion_global: Vector2)

const ENERGIA_BASE: float = 0.8
const AMPLITUD_PULSO: float = 0.15
const FRECUENCIA_HZ: float = 1.5
const FRECUENCIA_ANGULAR: float = TAU * FRECUENCIA_HZ # ~9.42478 rad/s
const AMPLITUD_FLOTACION: float = 4.0
const VELOCIDAD_FLOTACION: float = 2.5

var _tiempo: float = 0.0
var _recolectada: bool = false

@onready var _visual_papel: Sprite2D = get_node_or_null("VisualPapel") as Sprite2D
@onready var _collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
@onready var _luz_baliza: PointLight2D = get_node_or_null("LuzBaliza") as PointLight2D
@onready var _particulas_recogida: CPUParticles2D = get_node_or_null("ParticulasRecogida") as CPUParticles2D


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _recolectada:
		return
	_tiempo += delta
	if _visual_papel != null:
		_visual_papel.position.y = sin(_tiempo * VELOCIDAD_FLOTACION) * AMPLITUD_FLOTACION
	if _luz_baliza != null:
		_luz_baliza.energy = ENERGIA_BASE + sin(_tiempo * FRECUENCIA_ANGULAR) * AMPLITUD_PULSO


func recolectar() -> void:
	if _recolectada:
		return
	_recolectada = true

	if _collision_shape != null:
		_collision_shape.set_deferred("disabled", true)
	else:
		set_deferred("monitoring", false)

	recolectada.emit(global_position)

	if _visual_papel != null:
		_visual_papel.visible = false
	if _luz_baliza != null:
		_luz_baliza.visible = false

	if _particulas_recogida != null:
		_particulas_recogida.emitting = true
		var tiempo_vida: float = maxf(_particulas_recogida.lifetime, 0.4)
		var arbol := get_tree()
		if arbol != null:
			arbol.create_timer(tiempo_vida).timeout.connect(queue_free)
		else:
			queue_free()
	else:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if _recolectada:
		return
	if _es_jugador(body):
		recolectar()


func _es_jugador(body: Node2D) -> bool:
	if body == null:
		return false
	if body is Personaje:
		return true
	if body.name.to_lower() == "personaje" or body.name == "EmGamex":
		return true
	if body.is_in_group("jugador"):
		return true
	return false
