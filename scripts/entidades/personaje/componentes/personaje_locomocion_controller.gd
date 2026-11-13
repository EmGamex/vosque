class_name PersonajeLocomocionController
extends RefCounted

## Subcontrolador de locomoción 8D, máquina de estados y trayectorias de salto/plancha.

var tiempo_aire: float = 0.0
var duracion_aire_actual: float = 0.45
var altura_despegue: float = 0.0
var tiempo_recuperacion: float = 0.0
var ultima_direccion: Vector2 = Vector2.DOWN
var direccion_plancha: Vector2 = Vector2.DOWN
var bloquear_salto_un_frame: bool = false


func procesar_frame(
	personaje: Personaje,
	delta: float,
	estamina_ctrl: PersonajeEstaminaController,
	vista_ctrl: PersonajeVistaController
) -> void:
	var direction: Vector2 = Input.get_vector(
		"personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo"
	)
	var is_moving: bool = direction != Vector2.ZERO
	if is_moving:
		ultima_direccion = direction.normalized()

	var quiere_sprint: bool = (
		Input.is_action_pressed("sprint")
		or (InputMap.has_action("personaje-sprint") and Input.is_action_pressed("personaje-sprint"))
	)
	var quiere_salto: bool = Input.is_action_just_pressed("personaje-salto")
	if bloquear_salto_un_frame:
		bloquear_salto_un_frame = false
		quiere_salto = false

	var estamina_consumida_en_frame: bool = false
	if estamina_ctrl.actualizar_boost_nota(delta):
		vista_ctrl.restaurar_feedback_nota()
	var factor_boost: float = estamina_ctrl.obtener_factor_boost(personaje.note_speed_boost_multiplier)

	match personaje.estado_actual:
		Personaje.Estado.REPOSO, Personaje.Estado.CAMINANDO, Personaje.Estado.SPRINT, Personaje.Estado.FATIGA:
			estamina_consumida_en_frame = _procesar_suelo(
				personaje,
				delta,
				direction,
				is_moving,
				quiere_sprint,
				quiere_salto,
				factor_boost,
				estamina_ctrl,
				vista_ctrl
			)

		Personaje.Estado.SALTO:
			if quiere_salto and not estamina_ctrl.fatigado and estamina_ctrl.puede_pagar(
				personaje.dive_stamina_cost, personaje.sin_gasto_estamina
			):
				iniciar_plancha(personaje, estamina_ctrl, direction)
				estamina_consumida_en_frame = true
			else:
				_procesar_salto(personaje, delta, direction, is_moving, factor_boost, vista_ctrl)

		Personaje.Estado.PLANCHA_AIRE:
			tiempo_aire += delta
			var u_plancha: float = clampf(tiempo_aire / duracion_aire_actual, 0.0, 1.0)
			var factor_restante: float = (1.0 - u_plancha) * altura_despegue
			vista_ctrl.aplicar_elevacion_eje_z(personaje.jump_height, factor_restante)
			if tiempo_aire >= duracion_aire_actual:
				impactar_plancha(personaje, vista_ctrl)

		Personaje.Estado.RECUPERANDOSE:
			tiempo_recuperacion -= delta
			personaje.velocity = personaje.velocity.move_toward(
				Vector2.ZERO, personaje.dive_slide_friction * delta
			)
			if tiempo_recuperacion <= 0.0:
				finalizar_recuperacion(personaje, estamina_ctrl, is_moving)

	if not estamina_consumida_en_frame:
		if estamina_ctrl.procesar_regeneracion(
			delta,
			personaje.max_stamina,
			personaje.stamina_regen_rate,
			personaje.fatigue_recovery_threshold
		):
			personaje.emitir_estamina_cambiada()

	vista_ctrl.actualizar_animacion(
		direction,
		is_moving,
		ultima_direccion,
		personaje.estado_actual == Personaje.Estado.REPOSO
	)
	personaje.move_and_slide()


func iniciar_salto_libre(personaje: Personaje, estamina_ctrl: PersonajeEstaminaController) -> void:
	if estamina_ctrl.consumir_puntual(
		personaje.jump_stamina_cost, personaje.stamina_regen_delay, personaje.sin_gasto_estamina
	):
		personaje.emitir_estamina_cambiada()

	tiempo_aire = 0.0
	duracion_aire_actual = personaje.jump_duration
	altura_despegue = 1.0

	personaje.set_collision_mask_value(2, false)
	personaje.set_collision_mask_value(1, true)
	personaje._cambiar_estado(Personaje.Estado.SALTO)


func finalizar_salto_libre(
	personaje: Personaje,
	estamina_ctrl: PersonajeEstaminaController,
	vista_ctrl: PersonajeVistaController,
	is_moving: bool
) -> void:
	personaje.restaurar_mascara_colision_suelo()
	vista_ctrl.restaurar_visuales_eje_z()
	_transicionar_a_suelo(personaje, estamina_ctrl, is_moving)


func iniciar_plancha(
	personaje: Personaje,
	estamina_ctrl: PersonajeEstaminaController,
	direccion_actual: Vector2
) -> void:
	if estamina_ctrl.consumir_puntual(
		personaje.dive_stamina_cost, personaje.stamina_regen_delay, personaje.sin_gasto_estamina
	):
		personaje.emitir_estamina_cambiada()

	if direccion_actual != Vector2.ZERO:
		direccion_plancha = direccion_actual.normalized()
	elif personaje.velocity.length() > personaje.stop_threshold:
		direccion_plancha = personaje.velocity.normalized()
	else:
		direccion_plancha = ultima_direccion

	personaje.velocity = direccion_plancha * personaje.dive_speed

	var u_actual: float = clampf(tiempo_aire / duracion_aire_actual, 0.0, 1.0)
	altura_despegue = maxf(0.2, 4.0 * u_actual * (1.0 - u_actual))
	tiempo_aire = 0.0
	duracion_aire_actual = maxf(0.2, personaje.jump_duration * 0.5)

	personaje.set_collision_mask_value(2, false)
	personaje.set_collision_mask_value(1, true)
	personaje._cambiar_estado(Personaje.Estado.PLANCHA_AIRE)


func impactar_plancha(personaje: Personaje, vista_ctrl: PersonajeVistaController) -> void:
	personaje.restaurar_mascara_colision_suelo()
	vista_ctrl.restaurar_visuales_eje_z()
	tiempo_recuperacion = personaje.dive_recovery_duration
	personaje._cambiar_estado(Personaje.Estado.RECUPERANDOSE)


func finalizar_recuperacion(
	personaje: Personaje,
	estamina_ctrl: PersonajeEstaminaController,
	is_moving: bool
) -> void:
	_transicionar_a_suelo(personaje, estamina_ctrl, is_moving)


func _procesar_suelo(
	personaje: Personaje,
	delta: float,
	direction: Vector2,
	is_moving: bool,
	quiere_sprint: bool,
	quiere_salto: bool,
	factor_boost: float,
	estamina_ctrl: PersonajeEstaminaController,
	vista_ctrl: PersonajeVistaController
) -> bool:
	if quiere_salto and not estamina_ctrl.fatigado and estamina_ctrl.puede_pagar(
		personaje.jump_stamina_cost, personaje.sin_gasto_estamina
	):
		iniciar_salto_libre(personaje, estamina_ctrl)
		return true

	var estamina_consumida: bool = false
	var vel_objetivo: float = personaje.speed * factor_boost

	if quiere_sprint and is_moving and not estamina_ctrl.fatigado and (
		personaje.sin_gasto_estamina or estamina_ctrl.stamina > 0.0
	):
		personaje._cambiar_estado(Personaje.Estado.SPRINT)
		vel_objetivo = personaje.sprint_speed * factor_boost
		if estamina_ctrl.drenar_continuo(
			personaje.sprint_drain_rate, delta, personaje.stamina_regen_delay, personaje.sin_gasto_estamina
		):
			estamina_consumida = true
			if estamina_ctrl.fatigado:
				personaje._cambiar_estado(Personaje.Estado.FATIGA)
			personaje.emitir_estamina_cambiada()
	elif estamina_ctrl.fatigado:
		personaje._cambiar_estado(Personaje.Estado.FATIGA)
		vel_objetivo = personaje.speed
	elif is_moving:
		personaje._cambiar_estado(Personaje.Estado.CAMINANDO)
		vel_objetivo = personaje.speed
	else:
		personaje._cambiar_estado(Personaje.Estado.REPOSO)
		vel_objetivo = 0.0

	var target: Vector2 = direction * vel_objetivo
	var rate: float = personaje.acceleration if is_moving else personaje.friction
	personaje.velocity = personaje.velocity.move_toward(target, rate * delta)
	if not is_moving and personaje.velocity.length() < personaje.stop_threshold:
		personaje.velocity = Vector2.ZERO

	vista_ctrl.actualizar_procedural_suelo(
		personaje.estado_actual == Personaje.Estado.SPRINT, direction
	)
	return estamina_consumida


func _procesar_salto(
	personaje: Personaje,
	delta: float,
	direction: Vector2,
	is_moving: bool,
	factor_boost: float,
	vista_ctrl: PersonajeVistaController
) -> void:
	tiempo_aire += delta
	var u: float = clampf(tiempo_aire / duracion_aire_actual, 0.0, 1.0)
	var factor_altura: float = 4.0 * u * (1.0 - u)
	vista_ctrl.aplicar_elevacion_eje_z(personaje.jump_height, factor_altura)

	var air_target: Vector2 = direction * maxf(
		personaje.speed * factor_boost, personaje.velocity.length()
	)
	if is_moving:
		personaje.velocity = personaje.velocity.move_toward(
			air_target, personaje.acceleration * 0.5 * delta
		)

	if tiempo_aire >= duracion_aire_actual:
		finalizar_salto_libre(personaje, personaje._estamina_ctrl, vista_ctrl, is_moving)


func _transicionar_a_suelo(
	personaje: Personaje,
	estamina_ctrl: PersonajeEstaminaController,
	is_moving: bool
) -> void:
	if estamina_ctrl.fatigado:
		personaje._cambiar_estado(Personaje.Estado.FATIGA)
	elif is_moving:
		personaje._cambiar_estado(Personaje.Estado.CAMINANDO)
	else:
		personaje._cambiar_estado(Personaje.Estado.REPOSO)
