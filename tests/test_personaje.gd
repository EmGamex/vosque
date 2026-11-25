@tool
class_name TestPersonaje
extends McpTestSuite

## Pruebas unitarias para la mecánica de impulso de estamina y velocidad al recoger nota.

func suite_name() -> String:
	return "personaje"


func test_impulso_nota_restaura_estamina_y_limpia_fatiga() -> void:
	var escena: PackedScene = load("res://escenas/personaje.tscn")
	assert_true(escena != null, "La escena personaje.tscn debe existir")
	var p: Personaje = escena.instantiate() as Personaje
	assert_true(p != null, "Debe instanciarse como Personaje")
	p._ready()

	p.stamina = 10.0
	p.fatigado = true
	p._regen_timer = 0.8
	p._cambiar_estado(Personaje.Estado.FATIGA)

	var emisiones: Array = []
	p.estamina_cambiada.connect(func(actual: float, maxima: float, es_fatigado: bool):
		emisiones.append([actual, maxima, es_fatigado])
	)

	p.aplicar_impulso_nota()

	assert_true(is_equal_approx(p.stamina, 60.0), "Debe restaurar +50% de max_stamina (10 -> 60)")
	assert_false(p.fatigado, "Debe limpiar la fatiga al recoger una nota")
	assert_eq(p._regen_timer, 0.0, "Debe reiniciar _regen_timer a 0.0")
	assert_ne(p.estado_actual, Personaje.Estado.FATIGA, "Debe salir del estado FATIGA")
	assert_eq(emisiones.size(), 1, "Debe emitir estamina_cambiada una vez")

	# Verificar tope en max_stamina
	p.stamina = 80.0
	p.aplicar_impulso_nota()
	assert_true(is_equal_approx(p.stamina, p.max_stamina), "La estamina no debe superar max_stamina")

	p.free()


func test_boost_velocidad_duracion_reinicio_y_expiracion() -> void:
	var escena: PackedScene = load("res://escenas/personaje.tscn")
	var p: Personaje = escena.instantiate() as Personaje
	p._ready()

	p.aplicar_impulso_nota()
	assert_true(is_equal_approx(p._tiempo_boost_nota, p.note_speed_boost_duration), "El timer de boost debe iniciar en 1.5 s")

	# Simular avance de 1.0 s
	p._physics_process_logica(1.0)
	assert_true(is_equal_approx(p._tiempo_boost_nota, 0.5), "Tras 1.0 s debe quedar 0.5 s de boost")

	# Recoger otra nota reinicia el timer (no acumula)
	p.aplicar_impulso_nota()
	assert_true(is_equal_approx(p._tiempo_boost_nota, p.note_speed_boost_duration), "Una segunda nota debe reiniciar el timer a 1.5 s")

	# Expirar completamente
	p._physics_process_logica(1.6)
	assert_eq(p._tiempo_boost_nota, 0.0, "El timer debe llegar a 0.0 al expirar")
	if p._visual != null:
		assert_eq(p._visual.modulate, Color.WHITE, "El tinte visual debe restaurarse a Color.WHITE al expirar")

	p.free()


func test_impulso_nota_en_plancha_y_captura() -> void:
	var escena: PackedScene = load("res://escenas/personaje.tscn")
	var p: Personaje = escena.instantiate() as Personaje
	p._ready()

	p.stamina = 20.0
	p._cambiar_estado(Personaje.Estado.PLANCHA_AIRE)
	p.velocity = Vector2.RIGHT * p.dive_speed
	p._tiempo_aire = 0.0
	p._duracion_aire_actual = 0.5

	p.aplicar_impulso_nota()
	assert_true(is_equal_approx(p.stamina, 70.0), "Debe restaurar estamina incluso en PLANCHA_AIRE")
	assert_true(is_equal_approx(p.velocity.length(), p.dive_speed), "No debe alterar dive_speed durante PLANCHA_AIRE")

	p._physics_process_logica(0.2)
	assert_true(p._tiempo_boost_nota < p.note_speed_boost_duration, "El timer del boost debe correr normalmente en estados bloqueados")

	p.detener_por_captura()
	assert_eq(p._tiempo_boost_nota, 0.0, "detener_por_captura debe limpiar el timer del boost")

	p.free()


func test_maain_aplica_impulso_nota_desde_nota_1() -> void:
	var maain := Maain.new()
	var p: Personaje = load("res://escenas/personaje.tscn").instantiate() as Personaje
	p._ready()
	p.stamina = 25.0
	p.fatigado = true
	maain.jugador = p
	maain.partida_terminada = false

	maain._on_nota_recolectada(Vector2.ZERO)

	assert_eq(maain.notas_recolectadas, 1, "Debe incrementar notas_recolectadas a 1")
	assert_true(is_equal_approx(p.stamina, 75.0), "Maain debe restaurar estamina del jugador desde Nota 1")
	assert_false(p.fatigado, "Maain debe limpiar fatiga del jugador desde Nota 1")
	assert_true(p._tiempo_boost_nota > 0.0, "Maain debe activar el boost de velocidad desde Nota 1")

	p.free()
	maain.free()


func test_impulso_nota_permite_gastar_acciones_sin_drenar_estamina() -> void:
	var escena: PackedScene = load("res://escenas/personaje.tscn")
	var p: Personaje = escena.instantiate() as Personaje
	p._ready()

	p.stamina = 40.0
	p.aplicar_impulso_nota()
	var estamina_tras_nota: float = p.stamina
	assert_true(p._estamina_ctrl.esta_sin_gasto_activo(p.sin_gasto_estamina), "Debe activar ventana sin gasto de estamina")

	# Salto y plancha durante la ventana no deben consumir estamina ni activar fatiga
	p._iniciar_salto_libre()
	assert_true(is_equal_approx(p.stamina, estamina_tras_nota), "El salto no debe gastar estamina durante la ventana de nota")
	p._locomocion_ctrl.iniciar_plancha(p, p._estamina_ctrl, Vector2.RIGHT)
	assert_true(is_equal_approx(p.stamina, estamina_tras_nota), "La plancha no debe gastar estamina durante la ventana de nota")
	assert_false(p.fatigado, "No debe fatigarse durante la ventana sin gasto")

	# Expirar ventana (1.5 s)
	p._physics_process_logica(1.6)
	assert_false(p._estamina_ctrl.esta_sin_gasto_activo(p.sin_gasto_estamina), "La ventana sin gasto debe expirar tras 1.5 s")

	# Tras expirar, volver a saltar sí consume estamina
	p._cambiar_estado(Personaje.Estado.REPOSO)
	var estamina_antes_salto: float = p.stamina
	p._iniciar_salto_libre()
	assert_true(p.stamina < estamina_antes_salto, "Al expirar la ventana, saltar debe volver a consumir estamina")

	p.free()


func test_nodos_audio_locomocion_configurados() -> void:
	var escena: PackedScene = load("res://escenas/personaje.tscn")
	var p: Personaje = escena.instantiate() as Personaje
	p._ready()

	for nombre in ["AudioPasos", "AudioSalto", "AudioPlancha"]:
		var player: AudioStreamPlayer2D = p.get_node_or_null(nombre) as AudioStreamPlayer2D
		assert_true(player != null, "Debe existir el nodo %s como AudioStreamPlayer2D" % nombre)
		if player != null:
			assert_eq(player.bus, &"sfx", "%s debe enrutar al bus sfx" % nombre)
			assert_true(player.stream != null, "%s debe tener un stream asignado" % nombre)
			assert_true(player.max_polyphony <= 3, "%s debe respetar max_polyphony <= 3 para WebAudio" % nombre)

	p.detener_por_captura()
	assert_eq(p._audio_ctrl._timer_paso, 0.0, "detener_por_captura debe reiniciar el temporizador de pasos")

	p.free()


func test_rebote_correr_eleva_visual_sin_alterar_colisiones_ni_ui() -> void:
	var escena: PackedScene = load("res://escenas/personaje.tscn")
	var p: Personaje = escena.instantiate() as Personaje
	p._ready()

	p._cambiar_estado(Personaje.Estado.CAMINANDO)
	p.velocity = Vector2.RIGHT * p.speed
	var max_offset_caminar: float = 0.0
	for i in 20:
		p._vista_ctrl.actualizar_procedural_suelo(
			false,
			Vector2.RIGHT,
			0.016,
			Personaje.Estado.CAMINANDO,
			p.speed,
			p.stop_threshold,
			p.speed,
			p.step_interval_base,
			p.run_bob_enabled,
			p.run_bob_height,
			p.sprint_bob_height,
			p.run_bob_shadow_scale,
			p.run_bob_return_speed
		)
		max_offset_caminar = maxf(max_offset_caminar, -p._visual.position.y)

	assert_true(max_offset_caminar > 0.0, "El rebote al caminar debe elevar Visual en Y")
	assert_true(max_offset_caminar <= p.run_bob_height + 0.001, "El rebote al caminar no debe superar run_bob_height")
	assert_true(p.get_collision_mask_value(2), "El rebote al correr no debe desactivar la máscara de Capa 2")
	if p._vista_ctrl.indicador_estamina != null:
		assert_true(is_equal_approx(p._vista_ctrl.indicador_estamina.position.y, -60.0), "IndicadorEstamina debe permanecer fijo durante el trote")

	p._vista_ctrl.resetear_rebote_carrera()
	p._cambiar_estado(Personaje.Estado.SPRINT)
	var max_offset_sprint: float = 0.0
	for i in 20:
		p._vista_ctrl.actualizar_procedural_suelo(
			true,
			Vector2.RIGHT,
			0.016,
			Personaje.Estado.SPRINT,
			p.sprint_speed,
			p.stop_threshold,
			p.speed,
			p.step_interval_base,
			p.run_bob_enabled,
			p.run_bob_height,
			p.sprint_bob_height,
			p.run_bob_shadow_scale,
			p.run_bob_return_speed
		)
		max_offset_sprint = maxf(max_offset_sprint, -p._visual.position.y)

	assert_true(max_offset_sprint > max_offset_caminar, "El rebote en sprint debe ser mayor que al caminar")
	assert_true(max_offset_sprint <= p.sprint_bob_height + 0.001, "El rebote en sprint no debe superar sprint_bob_height")

	p.free()


func test_rebote_correr_retorna_a_cero_en_reposo_salto_y_captura() -> void:
	var escena: PackedScene = load("res://escenas/personaje.tscn")
	var p: Personaje = escena.instantiate() as Personaje
	p._ready()

	p._vista_ctrl.actualizar_procedural_suelo(
		false,
		Vector2.RIGHT,
		0.1,
		Personaje.Estado.CAMINANDO,
		p.speed,
		p.stop_threshold,
		p.speed,
		p.step_interval_base,
		p.run_bob_enabled,
		p.run_bob_height,
		p.sprint_bob_height,
		p.run_bob_shadow_scale,
		p.run_bob_return_speed
	)
	assert_true(p._visual.position.y < 0.0, "Debe haber desplazamiento negativo en Y al correr")

	for i in 30:
		p._vista_ctrl.actualizar_procedural_suelo(
			false,
			Vector2.ZERO,
			0.05,
			Personaje.Estado.REPOSO,
			0.0,
			p.stop_threshold,
			p.speed,
			p.step_interval_base,
			p.run_bob_enabled,
			p.run_bob_height,
			p.sprint_bob_height,
			p.run_bob_shadow_scale,
			p.run_bob_return_speed
		)
	assert_eq(p._visual.position, Vector2.ZERO, "Al frenar a REPOSO el rebote debe volver a Vector2.ZERO")

	p._vista_ctrl.actualizar_procedural_suelo(
		true,
		Vector2.RIGHT,
		0.1,
		Personaje.Estado.SPRINT,
		p.sprint_speed,
		p.stop_threshold,
		p.speed,
		p.step_interval_base
	)
	p.detener_por_captura()
	assert_eq(p._visual.position, Vector2.ZERO, "detener_por_captura debe restaurar Visual a Vector2.ZERO")
	assert_eq(p._vista_ctrl._offset_rebote_actual, 0.0, "detener_por_captura debe limpiar _offset_rebote_actual")

	p.free()
