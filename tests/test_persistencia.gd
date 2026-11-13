@tool
class_name TestPersistencia
extends McpTestSuite

## Suite de pruebas automatizadas para el sistema de persistencia y High Score (Issue #35).

const RUTA_TEST_SAVE: String = "user://test_highscore_suite.save"
const RUTA_TEST_CONFIG: String = "user://test_config_suite.cfg"
const GestorPersistenciaScript: GDScript = preload("res://scripts/core/gestor_persistencia.gd")


func suite_name() -> String:
	return "persistencia"


func _limpiar_archivo_test() -> void:
	if FileAccess.file_exists(RUTA_TEST_SAVE):
		DirAccess.remove_absolute(RUTA_TEST_SAVE)
	if FileAccess.file_exists(RUTA_TEST_CONFIG):
		DirAccess.remove_absolute(RUTA_TEST_CONFIG)


func test_guardado_y_lectura_basica() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = RUTA_TEST_SAVE
	gestor._ready()

	assert_eq(gestor.obtener_high_score(), 0, "Al inicio sin datos el récord debe ser 0")

	var es_nuevo: bool = gestor.guardar_high_score(5)
	assert_true(es_nuevo, "Guardar 5 cuando el récord es 0 debe retornar true")
	assert_eq(gestor.obtener_high_score(), 5, "El récord en memoria debe ser 5")
	assert_eq(gestor.obtener_ultimo_score(), 5, "El último score registrado debe ser 5")
	assert_true(gestor.es_ultimo_score_record(), "La última partida debe figurar como nuevo récord")

	# Simular reinicio / nueva instancia leyendo desde el archivo físico
	var gestor_reinicio: Node = GestorPersistenciaScript.new()
	gestor_reinicio.ruta_guardado = RUTA_TEST_SAVE
	gestor_reinicio._ready()
	assert_eq(gestor_reinicio.obtener_high_score(), 5, "Una nueva instancia debe leer 5 desde el archivo físico")

	gestor.free()
	gestor_reinicio.free()
	_limpiar_archivo_test()


func test_ignorar_puntuacion_menor() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = RUTA_TEST_SAVE
	gestor._ready()

	gestor.guardar_high_score(10)
	assert_eq(gestor.obtener_high_score(), 10, "Récord fijado en 10")

	# Intentar guardar puntaje inferior
	var es_nuevo_menor: bool = gestor.guardar_high_score(4)
	assert_false(es_nuevo_menor, "Puntuación de 4 no debe considerarse nuevo récord")
	assert_eq(gestor.obtener_high_score(), 10, "El récord debe seguir siendo 10")
	assert_eq(gestor.obtener_ultimo_score(), 4, "El último score debe ser 4")
	assert_false(gestor.es_ultimo_score_record(), "La última partida no batió récord")

	# Intentar guardar puntaje igual
	var es_nuevo_igual: bool = gestor.guardar_high_score(10)
	assert_false(es_nuevo_igual, "Puntuación igual no debe ser considerado nuevo récord")
	assert_eq(gestor.obtener_high_score(), 10, "El récord debe seguir siendo 10")

	gestor.free()
	_limpiar_archivo_test()


func test_reseteo() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = RUTA_TEST_SAVE
	gestor._ready()

	gestor.guardar_high_score(8)
	assert_eq(gestor.obtener_high_score(), 8, "Récord fijado en 8")

	gestor.resetear_high_score()
	assert_eq(gestor.obtener_high_score(), 0, "Tras resetear, el récord debe ser 0")
	assert_eq(gestor.obtener_ultimo_score(), 0, "Tras resetear, el último score debe ser 0")
	assert_false(gestor.es_ultimo_score_record(), "Tras resetear, no debe haber marca de récord")
	assert_false(FileAccess.file_exists(RUTA_TEST_SAVE), "El archivo en disco debe haber sido eliminado")

	gestor.free()
	_limpiar_archivo_test()


func test_tolerancia_archivo_inexistente() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = "user://archivo_que_nunca_existio_12345.save"
	gestor._ready()

	assert_eq(gestor.obtener_high_score(), 0, "Debe retornar 0 sin errores si el archivo no existe")
	assert_eq(gestor.recargar_desde_disco(), 0, "Recargar disco inexistente debe retornar 0")

	gestor.free()


func test_senales_y_queries() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = RUTA_TEST_SAVE
	gestor._ready()

	var senal_recibida: Array[int] = []
	gestor.record_actualizado.connect(func(nuevo_record: int): senal_recibida.append(nuevo_record))

	assert_true(gestor.es_nuevo_record(7), "7 debe ser nuevo récord frente a 0")
	gestor.guardar_high_score(7)
	assert_eq(senal_recibida.size(), 1, "Debe haberse emitido señal al registrar nuevo récord")
	assert_eq(senal_recibida[0], 7, "El valor emitido debe ser 7")

	assert_false(gestor.es_nuevo_record(5), "5 no debe ser nuevo récord frente a 7")
	gestor.guardar_high_score(5)
	assert_eq(senal_recibida.size(), 1, "No debe emitirse señal si no se bate el récord")

	gestor.resetear_high_score()
	assert_eq(senal_recibida.size(), 2, "Debe emitirse señal al resetear")
	assert_eq(senal_recibida[1], 0, "El valor emitido al resetear debe ser 0")

	gestor.free()
	_limpiar_archivo_test()


func test_integracion_game_over_y_director() -> void:
	_limpiar_archivo_test()
	var escena_go: PackedScene = load("res://escenas/game_over.tscn")
	assert_true(escena_go != null, "La escena game_over.tscn debe existir")

	var go: GameOver = escena_go.instantiate() as GameOver
	assert_true(go != null, "GameOver debe instanciarse")

	# Probar presentación de estadísticas
	go.actualizar_estadisticas(3, 8, false)
	assert_eq(go._label_paginas.text, "Páginas: 3", "Etiqueta de páginas debe mostrar 'Páginas: 3'")
	assert_eq(go._label_record.text, "Récord: 8", "Etiqueta de récord debe mostrar 'Récord: 8'")
	assert_false(go._label_nuevo_record.visible, "Banner de nuevo récord debe estar oculto")

	go.actualizar_estadisticas(9, 9, true)
	assert_eq(go._label_paginas.text, "Páginas: 9", "Etiqueta de páginas debe mostrar 'Páginas: 9'")
	assert_eq(go._label_record.text, "Récord: 9", "Etiqueta de récord debe mostrar 'Récord: 9'")
	assert_true(go._label_nuevo_record.visible, "Banner de nuevo récord debe ser visible si es nuevo récord")

	go.free()
	_limpiar_archivo_test()


func test_integracion_debug_system_controller() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = RUTA_TEST_SAVE
	gestor._ready()
	gestor.guardar_high_score(15)

	var ctrl := DebugSystemController.new()
	assert_eq(ctrl.obtener_high_score(gestor), 15, "DebugSystemController debe leer 15")

	ctrl.resetear_high_score(gestor)
	assert_eq(ctrl.obtener_high_score(gestor), 0, "DebugSystemController debe resetear a 0")

	gestor.free()
	_limpiar_archivo_test()


func test_persistencia_configuracion_audio() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = RUTA_TEST_SAVE
	gestor.ruta_config = RUTA_TEST_CONFIG
	gestor._ready()

	# Guardar valores de configuración
	gestor.guardar_configuracion_audio(75.0, 60.0, 85.0, true)

	# Instancia nueva para comprobar lectura física
	var gestor_reinicio: Node = GestorPersistenciaScript.new()
	gestor_reinicio.ruta_guardado = RUTA_TEST_SAVE
	gestor_reinicio.ruta_config = RUTA_TEST_CONFIG
	var cfg: Dictionary = gestor_reinicio.cargar_configuracion_audio()

	assert_eq(cfg.get("master"), 75.0, "Volumen master guardado debe ser 75%")
	assert_eq(cfg.get("musica"), 60.0, "Volumen musica guardado debe ser 60%")
	assert_eq(cfg.get("sfx"), 85.0, "Volumen sfx guardado debe ser 85%")
	assert_eq(cfg.get("pantalla_completa"), true, "Pantalla completa guardada debe ser true")
	assert_eq(cfg.get("usar_audio_usuario"), true, "usar_audio_usuario debe ser true")

	gestor.free()
	gestor_reinicio.free()
	_limpiar_archivo_test()


func test_persistencia_dual_predeterminado_vs_usuario() -> void:
	_limpiar_archivo_test()
	var gestor: Node = GestorPersistenciaScript.new()
	gestor.ruta_guardado = RUTA_TEST_SAVE
	gestor.ruta_config = RUTA_TEST_CONFIG
	gestor._ready()

	# 1. Por defecto sin archivo debe estar en modo predeterminado (porcentajes reales de default_bus_layout.tres)
	assert_false(gestor.esta_usando_audio_usuario(), "Sin archivo debe usar audio predeterminado")
	var pred: Dictionary = gestor.obtener_configuracion_predeterminada()
	assert_true(is_equal_approx(float(pred["master"]), 100.0), "Master predeterminado debe ser ~100%")
	assert_true(absf(float(pred["musica"]) - 40.0) < 1.0, "Música predeterminada debe ser ~40%")
	assert_true(absf(float(pred["sfx"]) - 80.0) < 1.0, "SFX predeterminado debe ser ~80%")

	# 2. Guardar perfil de usuario al 50% en música
	gestor.guardar_configuracion_audio(100.0, 50.0, 100.0, false, true)
	assert_true(gestor.esta_usando_audio_usuario(), "Debe activar usar_audio_usuario")

	# 3. Volver a predeterminado conservando el perfil de usuario en disco
	gestor.restablecer_audio_predeterminado(true)
	assert_false(gestor.esta_usando_audio_usuario(), "Debe volver al modo predeterminado")
	var cfg_conservada: Dictionary = gestor.cargar_configuracion_audio()
	assert_eq(cfg_conservada.get("musica"), 50.0, "El perfil del usuario en disco debe conservar el 50%")

	# 4. Reactivar modo usuario recupera el 50%
	gestor.alternar_modo_audio_usuario(true)
	assert_true(gestor.esta_usando_audio_usuario(), "Debe reactivar el modo usuario")

	gestor.free()
	_limpiar_archivo_test()
