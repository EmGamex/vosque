class_name Personaje
extends CharacterBody2D

# Configuraciones del movimiento
@export_group("Físicas de Movimiento")
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var speed: float = 300.0
@export_range(100.0, 10000.0, 50.0, "suffix:px/s²") var acceleration: float = 1200.0
@export_range(100.0, 10000.0, 50.0, "suffix:px/s²") var friction: float = 1500.0


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo")
	
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
