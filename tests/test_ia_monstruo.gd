@tool
class_name TestIaMonstruo
extends McpTestSuite

## Suite de pruebas para el ciclo de vida, hibernación, despertar y escalado del monstruo (Issue #11).

func suite_name() -> String:
	return "ia_monstruo"


func test_hibernacion_inicial_nota_0() -> void:
	var enemigo := Enemigo.new()
	enemigo.add_to_group("modo_test")
	enemigo.hibernar_al_iniciar = true
	enemigo._ready()

	assert_true(enemigo.hibernando, "El monstruo debe registrar estado hibernando = true")
	assert_false(enemigo.visible, "El monstruo debe tener visible = false durante Nota 0")
	assert_eq(enemigo.process_mode, Node.PROCESS_MODE_DISABLED, "El monstruo debe tener process_mode = DISABLED en motor")
	assert_eq(enemigo.global_position, Enemigo.POSICION_HIBERNACION, "El monstruo debe residir en coordenadas fuera de mapa (-99999, -99999)")
	assert_eq(enemigo.speed, 0.0, "En hibernación la velocidad debe ser 0.0")

	enemigo.free()


func test_despertar_nota_1() -> void:
	var enemigo := Enemigo.new()
	enemigo.hibernar()
	assert_true(enemigo.hibernando)

	var signal_detectada := [false]
	var vel_despertar := [0.0]
	enemigo.despertado.connect(func(vel: float):
		signal_detectada[0] = true
		vel_despertar[0] = vel
	)

	enemigo.despertar(500.0)

	assert_false(enemigo.hibernando, "Al despertar, hibernando debe ser false")
	assert_true(enemigo.visible, "Al despertar, visible debe restaurarse a true")
	assert_eq(enemigo.process_mode, Node.PROCESS_MODE_INHERIT, "Al despertar, process_mode debe ser INHERIT")
	assert_eq(enemigo.speed, 500.0, "La velocidad inicial al despertar en Nota 1 debe ser exactamente 500.0 px/s")
	assert_eq(enemigo.acceleration, Enemigo.ACELERACION_CONSTANTE, "La aceleración física debe ser fija en 3500.0 px/s²")
	assert_true(signal_detectada[0], "Debe emitirse la señal despertado")
	assert_eq(vel_despertar[0], 500.0, "La señal despertado debe llevar 500.0")

	enemigo.free()


func test_escalado_cuantitativo_tabla() -> void:
	var enemigo := Enemigo.new()

	var tabla_esperada: Array[float] = [
		0.0,   # Nota 0
		500.0, # Nota 1
		580.0, # Nota 2
		620.0, # Nota 3
		680.0, # Nota 4
		730.0, # Nota 5
		770.0, # Nota 6
		800.0, # Nota 7
		840.0, # Nota 8
		880.0, # Nota 9
		920.0  # Nota 10
	]

	for nota in range(tabla_esperada.size()):
		enemigo.actualizar_dificultad(nota)
		assert_eq(enemigo.speed, tabla_esperada[nota], "Nota %d debe dar velocidad %.1f" % [nota, tabla_esperada[nota]])
		assert_eq(enemigo.acceleration, 3500.0, "Aceleración debe permanecer fija en 3500 px/s²")

	# Notas 11, 15, 20 deben respetar tope estricto en 920.0 px/s
	for nota_alta in [11, 15, 25]:
		enemigo.actualizar_dificultad(nota_alta)
		assert_eq(enemigo.speed, Enemigo.VELOCIDAD_MAXIMA, "Nota %d debe congelarse en el tope 920.0" % nota_alta)

	enemigo.free()


func test_sprint_jugador_supera_tope_monstruo() -> void:
	var personaje := Personaje.new()
	var vel_sprint: float = personaje.sprint_speed
	var tope_monstruo: float = Enemigo.VELOCIDAD_MAXIMA

	assert_eq(vel_sprint, 1000.0, "La velocidad de sprint del jugador debe ser 1000.0 px/s")
	assert_eq(tope_monstruo, 920.0, "La velocidad máxima del monstruo debe ser 920.0 px/s")
	assert_true(vel_sprint > tope_monstruo, "El sprint del jugador debe ser estrictamente superior a la velocidad máxima del monstruo")
	assert_eq(vel_sprint - tope_monstruo, 80.0, "El margen de ventaja en sprint debe ser de exactamente +80 px/s")

	personaje.free()


func test_modulacion_velocidad_en_niebla() -> void:
	var enemigo := Enemigo.new()
	enemigo.despertar(800.0) # Nota 7 (800 px/s)

	assert_eq(enemigo.obtener_velocidad_efectiva(), 800.0, "Sin niebla cerrada, velocidad efectiva debe ser 100%")

	enemigo.modular_velocidad_niebla(true)
	assert_eq(enemigo.obtener_velocidad_efectiva(), 400.0, "Bajo oscuridad total, la velocidad debe reducirse al 50% (400 px/s)")

	enemigo.modular_velocidad_niebla(false)
	assert_eq(enemigo.obtener_velocidad_efectiva(), 800.0, "Al disiparse la oscuridad, debe recuperar el 100% (800 px/s)")

	enemigo.free()


func test_algoritmo_seleccion_spawn_seguro() -> void:
	var pos_jugador := Vector2(0, 0)
	var m_cercano := Marker2D.new()
	m_cercano.global_position = Vector2(400, 0) # 400 px (< 800 px)

	var m_lejano := Marker2D.new()
	m_lejano.global_position = Vector2(1200, 0) # 1200 px (>= 800 px)

	var candidatos: Array[Marker2D] = [m_cercano, m_lejano]

	var pos_elegida := Maain.seleccionar_posicion_spawn_monstruo(candidatos, pos_jugador, 800.0)
	assert_eq(pos_elegida, Vector2(1200, 0), "Debe seleccionar el marcador a >= 800 px y descartar el cercano")

	# Probar fallback cuando ninguno cumple distancia completa
	var candidatos_cortos: Array[Marker2D] = [m_cercano]
	var pos_fallback := Maain.seleccionar_posicion_spawn_monstruo(candidatos_cortos, pos_jugador, 800.0)
	assert_eq(pos_fallback, Vector2(400, 0), "Fallback 1 debe elegir el candidato de distancia máxima disponible")

	# Probar fallback sin candidatos (vector opuesto)
	var pos_vacio := Maain.seleccionar_posicion_spawn_monstruo([], Vector2(500, 0), 800.0)
	assert_true(pos_vacio.distance_to(Vector2(500, 0)) >= 800.0, "Fallback sin candidatos debe quedar a >= 800 px del jugador")

	m_cercano.free()
	m_lejano.free()


func test_director_orquestacion_despertar() -> void:
	var maain := Maain.new()
	maain.add_to_group("modo_test")
	var mock_jugador := CharacterBody2D.new()
	mock_jugador.name = "personaje"
	mock_jugador.global_position = Vector2(0, 0)
	maain.add_child(mock_jugador)

	var mock_enemigo := Enemigo.new()
	mock_enemigo.name = "Enemigo"
	maain.add_child(mock_enemigo)

	maain._ready()
	assert_true(mock_enemigo.hibernando, "Al inicio, el Game Director debe forzar hibernación del monstruo")
	assert_eq(mock_enemigo.process_mode, Node.PROCESS_MODE_DISABLED)

	# Simular recolección de Nota 1
	maain._on_nota_recolectada(Vector2(100, 100))
	assert_eq(maain.notas_recolectadas, 1)
	assert_false(mock_enemigo.hibernando, "En Nota 1, el monstruo debe despertar")
	assert_eq(mock_enemigo.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(mock_enemigo.speed, 500.0, "En Nota 1, la velocidad debe ser 500.0")

	# Simular recolección de Nota 2
	maain._on_nota_recolectada(Vector2(200, 200))
	assert_eq(maain.notas_recolectadas, 2)
	assert_eq(mock_enemigo.speed, 580.0, "En Nota 2, la velocidad debe ser 580.0")

	mock_jugador.free()
	mock_enemigo.free()
	maain.free()
