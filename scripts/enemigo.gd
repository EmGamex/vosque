class_name Enemigo
extends CharacterBody2D

## Boceto del enemigo perseguidor: sigue al jugador y dispara Game Over al contacto.

@export var objetivo: Node2D

@export_group("Físicas de Persecución")
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var speed: float = 500.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var acceleration: float = 3500.0

var _capturado: bool = false

@onready var _gestor: GestorDeEscenas = get_node_or_null("/root/GestorEscenas") as GestorDeEscenas
@onready var _area_captura: Area2D = $AreaCaptura
@onready var _visual: Node2D = $BocetoVisual


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if objetivo == null and get_parent() != null:
		objetivo = get_parent().get_node_or_null("personaje") as Node2D
	if _area_captura != null:
		_area_captura.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if _capturado or objetivo == null or not is_instance_valid(objetivo):
		return

	var direccion: Vector2 = global_position.direction_to(objetivo.global_position)
	velocity = velocity.move_toward(direccion * speed, acceleration * delta)
	if velocity.length_squared() > 1.0 and _visual != null:
		_visual.rotation = velocity.angle()

	move_and_slide()


func _on_body_entered(body: Node2D) -> void:
	if _capturado:
		return
	if body is Personaje or body == objetivo:
		_capturado = true
		velocity = Vector2.ZERO
		if _gestor != null:
			_gestor.ir_a(GestorDeEscenas.RUTA_GAME_OVER)
