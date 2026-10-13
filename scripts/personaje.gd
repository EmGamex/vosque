extends CharacterBody2D

## Velocidad máxima de movimiento (ajustable en el inspector)
@export var speed: float = 300.0

## Tasa de aceleración al presionar una dirección
@export var acceleration: float = 1200.0

## Fricción/desaceleración al soltar las teclas
@export var friction: float = 1500.0


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = velocity.move_toward(direction * speed, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	move_and_slide()
