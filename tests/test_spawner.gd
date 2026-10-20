@tool
class_name TestSpawner
extends McpTestSuite

## Suite de pruebas para el Spawner Espacial de Notas y filtros de seguridad (Issue #10).

func suite_name() -> String:
	return "spawner"


func test_invariante_existencia_nota_unica() -> void:
	var maain := Maain.new()
	var mock_nota := Area2D.new()
	# Simular nota activa
	maain.nota_activa = mock_nota as Nota

	# Intento de instanciación con nota activa
	var segunda_nota = maain.generar_nota()
	assert_true(segunda_nota == null, "Si ya existe una nota activa, generar_nota() debe retornar null")

	mock_nota.free()
	maain.free()


func test_filtro_cuadrante_activo_jugador() -> void:
	# Crear marcadores en NO, NE, SO, SE
	var m_no := Marker2D.new()
	m_no.global_position = Vector2(-1000, -1000) # NO

	var m_ne := Marker2D.new()
	m_ne.global_position = Vector2(1000, -1000) # NE

	var m_so := Marker2D.new()
	m_so.global_position = Vector2(-1000, 1000) # SO

	var m_se := Marker2D.new()
	m_se.global_position = Vector2(1000, 1000) # SE

	var candidatos: Array[Marker2D] = [m_no, m_ne, m_so, m_se]
	var pos_jugador := Vector2(-500, -500) # Jugador en NO
	var cuad_jugador := "NO"

	var validos: Array[Marker2D] = Maain.filtrar_candidatos_espaciales(
		candidatos,
		pos_jugador,
		cuad_jugador,
		Vector2(INF, INF), # Sin monstruo
		Vector2(INF, INF), # Sin desatasco
		600.0,
		800.0
	)

	assert_false(validos.has(m_no), "El marcador en el cuadrante activo del jugador (NO) debe ser excluido")
	assert_true(validos.has(m_ne), "Marcador en NE debe ser válido si cumple distancias")
	assert_true(validos.has(m_so), "Marcador en SO debe ser válido si cumple distancias")
	assert_true(validos.has(m_se), "Marcador en SE debe ser válido si cumple distancias")

	m_no.free()
	m_ne.free()
	m_so.free()
	m_se.free()


func test_filtro_distancia_minima_jugador() -> void:
	var pos_jugador := Vector2(100, 100) # SE
	var cuad_jugador := "SE"

	var m_cerca := Marker2D.new()
	m_cerca.global_position = Vector2(100, 500) # Distancia = 400 (< 600 px), en SE

	var m_lejos := Marker2D.new()
	m_lejos.global_position = Vector2(-800, -800) # Distancia > 600 px, en NO

	var candidatos: Array[Marker2D] = [m_cerca, m_lejos]

	var validos: Array[Marker2D] = Maain.filtrar_candidatos_espaciales(
		candidatos,
		pos_jugador,
		cuad_jugador,
		Vector2(INF, INF),
		Vector2(INF, INF),
		600.0,
		800.0
	)

	assert_false(validos.has(m_cerca), "Marcador a < 600 px del jugador debe ser excluido")
	assert_true(validos.has(m_lejos), "Marcador a >= 600 px del jugador en sector mutado debe ser aceptado")

	m_cerca.free()
	m_lejos.free()


func test_filtro_distancia_minima_monstruo() -> void:
	var pos_jugador := Vector2(-1500, -1500) # NO
	var cuad_jugador := "NO"
	var pos_monstruo := Vector2(1000, 1000) # SE

	var m_cerca_monstruo := Marker2D.new()
	m_cerca_monstruo.global_position = Vector2(1000, 1500) # Distancia = 500 px (< 800 px)

	var m_lejos_monstruo := Marker2D.new()
	m_lejos_monstruo.global_position = Vector2(1000, -1000) # NE, Distancia > 800 px de ambos

	var candidatos: Array[Marker2D] = [m_cerca_monstruo, m_lejos_monstruo]

	var validos: Array[Marker2D] = Maain.filtrar_candidatos_espaciales(
		candidatos,
		pos_jugador,
		cuad_jugador,
		pos_monstruo,
		Vector2(INF, INF),
		600.0,
		800.0
	)

	assert_false(validos.has(m_cerca_monstruo), "Marcador a < 800 px del monstruo debe ser excluido")
	assert_true(validos.has(m_lejos_monstruo), "Marcador a >= 800 px del monstruo debe ser aceptado")

	m_cerca_monstruo.free()
	m_lejos_monstruo.free()


func test_filtro_exclusion_desatasco() -> void:
	var pos_jugador := Vector2(-1500, -1500) # NO
	var cuad_jugador := "NO"
	var pos_monstruo := Vector2(0, 0)
	var pos_desatasco := Vector2(1200, 1200) # Marcador en SE

	var m_desatasco := Marker2D.new()
	m_desatasco.global_position = pos_desatasco

	var m_libre := Marker2D.new()
	m_libre.global_position = Vector2(1200, -1200) # NE

	var candidatos: Array[Marker2D] = [m_desatasco, m_libre]

	var validos: Array[Marker2D] = Maain.filtrar_candidatos_espaciales(
		candidatos,
		pos_jugador,
		cuad_jugador,
		pos_monstruo,
		pos_desatasco,
		600.0,
		800.0
	)

	assert_false(validos.has(m_desatasco), "Marcador reservado para desatasco del enemigo debe ser excluido")
	assert_true(validos.has(m_libre), "Marcador libre no reservado debe ser aceptado")

	m_desatasco.free()
	m_libre.free()


func test_mecanismo_fallback_distancia_maxima() -> void:
	var pos_jugador := Vector2(100, 100) # SE
	var cuad_jugador := "SE"
	var pos_monstruo := Vector2(500, 500)

	# Marcadores en sectores mutados (NE, SO) pero ninguno supera 600 px del jugador o 800 px del monstruo
	var m_cercano := Marker2D.new()
	m_cercano.global_position = Vector2(250, -100) # NE, d ≈ 250 px

	var m_medio := Marker2D.new()
	m_medio.global_position = Vector2(400, -200) # NE, d ≈ 424 px

	var m_mas_lejano := Marker2D.new()
	m_mas_lejano.global_position = Vector2(-200, 450) # SO, d ≈ 460 px

	# Marcador en el sector del jugador (no debe ser elegido ni en fallback)
	var m_en_sector_jugador := Marker2D.new()
	m_en_sector_jugador.global_position = Vector2(1000, 1000) # SE, d ≈ 1272 px pero en SE!

	var candidatos: Array[Marker2D] = [m_cercano, m_medio, m_mas_lejano, m_en_sector_jugador]

	var validos: Array[Marker2D] = Maain.filtrar_candidatos_espaciales(
		candidatos,
		pos_jugador,
		cuad_jugador,
		pos_monstruo,
		Vector2(INF, INF),
		600.0,
		800.0
	)

	assert_eq(validos.size(), 0, "No debe haber candidatos válidos que cumplan todas las restricciones")

	# Ejecutar selección con fallback
	var elegido: Marker2D = Maain.elegir_marcador(
		validos,
		candidatos,
		pos_jugador,
		cuad_jugador
	)

	assert_true(elegido != null, "El fallback debe encontrar un marcador de los sectores mutados")
	assert_eq(elegido, m_mas_lejano, "El fallback debe seleccionar el marcador con distancia máxima al jugador entre los sectores mutados")
	assert_ne(elegido, m_en_sector_jugador, "El fallback jamás debe seleccionar un marcador del sector activo del jugador")

	m_cercano.free()
	m_medio.free()
	m_mas_lejano.free()
	m_en_sector_jugador.free()


func test_integracion_maain_spawn_y_recoleccion() -> void:
	var escena_maain: PackedScene = load("res://escenas/maain.tscn")
	assert_true(escena_maain != null, "La escena maain.tscn debe poder cargarse")

	var inst_maain: Maain = escena_maain.instantiate() as Maain
	assert_true(inst_maain != null, "La instancia debe ser de tipo Maain")

	# Agregamos temporalmente a la raíz para inicializar _ready
	var root := Node2D.new()
	root.add_child(inst_maain)
	inst_maain._ready()
	if inst_maain.escenario != null:
		inst_maain.escenario._ready()

	# Simular spawn de nota
	var nota_generada: Nota = inst_maain.generar_nota()
	assert_true(nota_generada != null, "generar_nota() debe devolver una instancia de Nota")
	assert_true(inst_maain.hay_nota_activa(), "hay_nota_activa() debe ser true tras el spawn")
	assert_eq(inst_maain.nota_activa, nota_generada, "nota_activa debe apuntar a la nota creada")

	# Segundo intento debe fallar por el invariante
	var segunda := inst_maain.generar_nota()
	assert_true(segunda == null, "No debe instanciar segunda nota")

	# Simular recolección
	var senal_emitida: Array = []
	inst_maain.nota_recogida.connect(func(pos, total): senal_emitida.append(total))

	nota_generada.recolectar()
	assert_eq(senal_emitida.size(), 1, "Al recolectar la nota se debe emitir nota_recogida en Maain")
	assert_eq(inst_maain.notas_recolectadas, 1, "notas_recolectadas debe incrementarse a 1")
	assert_false(inst_maain.hay_nota_activa(), "Tras la recolección, hay_nota_activa() debe ser false")

	root.free()
