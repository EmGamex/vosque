class_name Personaje
extends CharacterBody2D

## Máquina de estados del personaje para evasión y control físico en Vosque.
enum Estado {
	REPOSO,
	CAMINANDO,
	SPRINT,
	FATIGA,
	SALTO,
	PLANCHA_AIRE,
	RECUPERANDOSE,
}

signal estamina_cambiada(actual: float, maxima: float, fatigado: bool)
signal estado_cambiado(nuevo_estado: Estado, nombre_estado: String)

@export_group("Físicas de Movimiento")
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var speed: float = 800.0
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var sprint_speed: float = 1000.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var acceleration: float = 5000.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var friction: float = 5000.0
@export_range(0.0, 100.0, 1.0, "suffix:px/s") var stop_threshold: float = 15.0

@export_group("Estamina y Fatiga")
@export_range(10.0, 500.0, 5.0) var max_stamina: float = 100.0
@export_range(0.0, 100.0, 1.0, "suffix:pts/s") var sprint_drain_rate: float = 25.0
@export_range(0.0, 100.0, 1.0, "suffix:pts/s") var stamina_regen_rate: float = 20.0
@export_range(0.0, 5.0, 0.1, "suffix:s") var stamina_regen_delay: float = 0.8
@export_range(0.0, 100.0, 1.0, "suffix:pts") var fatigue_recovery_threshold: float = 30.0

@export_group("Salto y Plancha (Dive)")
@export_range(0.0, 100.0, 1.0, "suffix:pts") var jump_stamina_cost: float = 20.0
@export_range(0.1, 2.0, 0.05, "suffix:s") var jump_duration: float = 0.45
@export_range(10.0, 200.0, 2.0, "suffix:px") var jump_height: float = 56.0
@export var shadow_min_scale: Vector2 = Vector2(0.6, 0.6)
@export_range(0.0, 100.0, 1.0, "suffix:pts") var dive_stamina_cost: float = 30.0
@export_range(100.0, 3000.0, 50.0, "suffix:px/s") var dive_speed: float = 1200.0
@export_range(0.1, 2.0, 0.05, "suffix:s") var dive_recovery_duration: float = 0.6
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var dive_slide_friction: float = 2200.0

var estado_actual: Estado = Estado.REPOSO
var stamina: float = 100.0
var fatigado: bool = false

var _regen_timer: float = 0.0
var _tiempo_aire: float = 0.0
var _duracion_aire_actual: float = 0.45
var _altura_despegue: float = 0.0
var _tiempo_recuperacion: float = 0.0
var _ultima_direccion: Vector2 = Vector2.DOWN
var _direccion_plancha: Vector2 = Vector2.DOWN

@onready var _visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var _sombra: Node2D = get_node_or_null("Sombra") as Node2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	stamina = max_stamina
	_restaurar_mascara_colision_suelo()
	estamina_cambiada.emit(stamina, max_stamina, fatigado)
	estado_cambiado.emit(estado_actual, obtener_nombre_estado())


func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector(
		"personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo"
	)
	var is_moving: bool = direction != Vector2.ZERO
	if is_moving:
		_ultima_direccion = direction.normalized()

	var quiere_sprint: bool = (
		Input.is_action_pressed("sprint")
		or (InputMap.has_action("personaje-sprint") and Input.is_action_pressed("personaje-sprint"))
	)
	var quiere_salto: bool = Input.is_action_just_pressed("personaje-salto")

	var estamina_consumida_en_frame: bool = false

	match estado_actual:
		Estado.REPOSO, Estado.CAMINANDO, Estado.SPRINT, Estado.FATIGA:
			if quiere_salto and not fatigado and stamina >= jump_stamina_cost:
				_iniciar_salto_libre()
				estamina_consumida_en_frame = true
			else:
				var vel_objetivo: float = speed
				if quiere_sprint and is_moving and not fatigado and stamina > 0.0:
					_cambiar_estado(Estado.SPRINT)
					vel_objetivo = sprint_speed
					stamina = max(0.0, stamina - sprint_drain_rate * delta)
					_regen_timer = stamina_regen_delay
					estamina_consumida_en_frame = true
					if stamina <= 0.0:
						stamina = 0.0
						fatigado = true
						_cambiar_estado(Estado.FATIGA)
					estamina_cambiada.emit(stamina, max_stamina, fatigado)
				elif fatigado:
					_cambiar_estado(Estado.FATIGA)
					vel_objetivo = speed
				elif is_moving:
					_cambiar_estado(Estado.CAMINANDO)
					vel_objetivo = speed
				else:
					_cambiar_estado(Estado.REPOSO)
					vel_objetivo = 0.0

				var target: Vector2 = direction * vel_objetivo
				var rate: float = acceleration if is_moving else friction
				velocity = velocity.move_toward(target, rate * delta)
				if not is_moving and velocity.length() < stop_threshold:
					velocity = Vector2.ZERO

				_actualizar_procedural_suelo(direction, delta)

		Estado.SALTO:
			if quiere_salto and not fatigado and stamina >= dive_stamina_cost:
				_iniciar_plancha(direction)
				estamina_consumida_en_frame = true
			else:
				_tiempo_aire += delta
				var u: float = clampf(_tiempo_aire / _duracion_aire_actual, 0.0, 1.0)
				var factor_altura: float = 4.0 * u * (1.0 - u)
				_aplicar_elevacion_eje_z(factor_altura)

				var air_target: Vector2 = direction * max(speed, velocity.length())
				if is_moving:
					velocity = velocity.move_toward(air_target, acceleration * 0.5 * delta)

				if _tiempo_aire >= _duracion_aire_actual:
					_finalizar_salto_libre(is_moving)

		Estado.PLANCHA_AIRE:
			_tiempo_aire += delta
			var u_plancha: float = clampf(_tiempo_aire / _duracion_aire_actual, 0.0, 1.0)
			var factor_restante: float = (1.0 - u_plancha) * _altura_despegue
			_aplicar_elevacion_eje_z(factor_restante)

			if _tiempo_aire >= _duracion_aire_actual:
				_impactar_plancha()

		Estado.RECUPERANDOSE:
			_tiempo_recuperacion -= delta
			velocity = velocity.move_toward(Vector2.ZERO, dive_slide_friction * delta)
			if _tiempo_recuperacion <= 0.0:
				_finalizar_recuperacion(is_moving)

	if not estamina_consumida_en_frame:
		_procesar_regeneracion_estamina(delta)

	move_and_slide()


func _iniciar_salto_libre() -> void:
	stamina = max(0.0, stamina - jump_stamina_cost)
	_regen_timer = stamina_regen_delay
	if stamina <= 0.0:
		stamina = 0.0
		fatigado = true
	estamina_cambiada.emit(stamina, max_stamina, fatigado)

	_tiempo_aire = 0.0
	_duracion_aire_actual = jump_duration
	_altura_despegue = 1.0

	set_collision_mask_value(2, false)
	set_collision_mask_value(1, true)
	_cambiar_estado(Estado.SALTO)


func _finalizar_salto_libre(is_moving: bool) -> void:
	_restaurar_mascara_colision_suelo()
	_restaurar_visuales_eje_z()

	if fatigado:
		_cambiar_estado(Estado.FATIGA)
	elif is_moving:
		_cambiar_estado(Estado.CAMINANDO)
	else:
		_cambiar_estado(Estado.REPOSO)


func _iniciar_plancha(direccion_actual: Vector2) -> void:
	stamina = max(0.0, stamina - dive_stamina_cost)
	_regen_timer = stamina_regen_delay
	if stamina <= 0.0:
		stamina = 0.0
		fatigado = true
	estamina_cambiada.emit(stamina, max_stamina, fatigado)

	if direccion_actual != Vector2.ZERO:
		_direccion_plancha = direccion_actual.normalized()
	elif velocity.length() > stop_threshold:
		_direccion_plancha = velocity.normalized()
	else:
		_direccion_plancha = _ultima_direccion

	velocity = _direccion_plancha * dive_speed

	var u_actual: float = clampf(_tiempo_aire / _duracion_aire_actual, 0.0, 1.0)
	_altura_despegue = max(0.2, 4.0 * u_actual * (1.0 - u_actual))
	_tiempo_aire = 0.0
	_duracion_aire_actual = max(0.2, jump_duration * 0.5)

	set_collision_mask_value(2, false)
	set_collision_mask_value(1, true)
	_cambiar_estado(Estado.PLANCHA_AIRE)


func _impactar_plancha() -> void:
	_restaurar_mascara_colision_suelo()
	_restaurar_visuales_eje_z()
	_tiempo_recuperacion = dive_recovery_duration
	_cambiar_estado(Estado.RECUPERANDOSE)


func _finalizar_recuperacion(is_moving: bool) -> void:
	if fatigado:
		_cambiar_estado(Estado.FATIGA)
	elif is_moving:
		_cambiar_estado(Estado.CAMINANDO)
	else:
		_cambiar_estado(Estado.REPOSO)


func _procesar_regeneracion_estamina(delta: float) -> void:
	if _regen_timer > 0.0:
		_regen_timer -= delta
		return

	if stamina < max_stamina:
		stamina = min(max_stamina, stamina + stamina_regen_rate * delta)
		if fatigado and stamina >= fatigue_recovery_threshold:
			fatigado = false
		estamina_cambiada.emit(stamina, max_stamina, fatigado)


func _aplicar_elevacion_eje_z(factor_altura: float) -> void:
	if _visual != null:
		_visual.position.y = -jump_height * factor_altura
	if _sombra != null:
		_sombra.scale = Vector2.ONE.lerp(shadow_min_scale, factor_altura)


func _restaurar_visuales_eje_z() -> void:
	if _visual != null:
		_visual.position = Vector2.ZERO
		_visual.rotation = 0.0
	if _sombra != null:
		_sombra.scale = Vector2.ONE


func _actualizar_procedural_suelo(direction: Vector2, _delta: float) -> void:
	if _visual == null:
		return
	_visual.position = Vector2.ZERO
	if estado_actual == Estado.SPRINT and direction.x != 0.0:
		_visual.rotation = deg_to_rad(5.0 * signf(direction.x))
	else:
		_visual.rotation = 0.0


func _restaurar_mascara_colision_suelo() -> void:
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)


func _cambiar_estado(nuevo_estado: Estado) -> void:
	if estado_actual == nuevo_estado:
		return
	estado_actual = nuevo_estado
	estado_cambiado.emit(estado_actual, obtener_nombre_estado())


func obtener_nombre_estado() -> String:
	match estado_actual:
		Estado.REPOSO:
			return "REPOSO"
		Estado.CAMINANDO:
			return "CAMINANDO"
		Estado.SPRINT:
			return "SPRINT"
		Estado.FATIGA:
			return "FATIGA"
		Estado.SALTO:
			return "SALTO"
		Estado.PLANCHA_AIRE:
			return "PLANCHA_AIRE"
		Estado.RECUPERANDOSE:
			return "RECUPERANDOSE"
	return "DESCONOCIDO"
