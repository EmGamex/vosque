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
