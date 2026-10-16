class_name Personaje
extends CharacterBody2D

@export_group("Físicas de Movimiento")
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var speed: float = 300.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var acceleration: float = 3000.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var friction: float = 3000.0
@export_range(0.0, 100.0, 1.0, "suffix:px/s") var stop_threshold: float = 15.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo")
	var is_moving: bool = direction != Vector2.ZERO
	var target: Vector2 = direction * speed
	var rate: float = acceleration if is_moving else friction

	velocity = velocity.move_toward(target, rate * delta)
	if not is_moving and velocity.length() < stop_threshold:
		velocity = Vector2.ZERO

	move_and_slide()
