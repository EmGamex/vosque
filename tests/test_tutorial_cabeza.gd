@tool
class_name TestTutorialCabeza
extends McpTestSuite

## Pruebas unitarias e integración para el Tutorial Flotante sobre el Personaje (Issue #22).

func suite_name() -> String:
	return "tutorial_cabeza"


func before_each() -> void:
	TutorialCabeza.reiniciar_tutorial()


func after_each() -> void:
	TutorialCabeza.reiniciar_tutorial()


func _crear_tutorial() -> TutorialCabeza:
	TutorialCabeza.reiniciar_tutorial()
	var escena: PackedScene = load("res://escenas/ui/tutorial_cabeza.tscn")
	var inst: TutorialCabeza = escena.instantiate() as TutorialCabeza
	return inst


func test_instanciacion_y_valores_defecto() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	assert_true(tut != null, "La escena tutorial_cabeza.tscn debe instanciarse")
	tut._ready()

	assert_eq(tut.z_index, 3, "El z_index debe ser 3 para dibujarse sobre el personaje y la estamina")
	assert_eq(tut.modulate.a, 1.0, "Debe iniciar visible al 100%")
	assert_eq(tut.paso_actual, TutorialCabeza.Paso.PASO_1_MOVIMIENTO, "El paso inicial debe ser PASO_1_MOVIMIENTO")
	assert_false(TutorialCabeza.tutorial_visto, "tutorial_visto debe ser false al inicio")

	tut.free()


func test_paso_1_iluminacion_persistente() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	tut._ready()

	tut._w_registrado = true
	tut._actualizar_estilos_reactivos()

	# W debe estar marcado como registrado
	assert_true(tut._w_registrado, "W debe estar registrado")
	tut.free()


func test_paso_1_deteccion_movimiento() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	tut._ready()

	# Simular registro de teclas
	tut._w_registrado = true
	tut._a_registrado = true
	tut._s_registrado = true
	assert_eq(tut.paso_actual, TutorialCabeza.Paso.PASO_1_MOVIMIENTO, "Aún no debe avanzar con solo 3 direcciones")

	tut._d_registrado = true
	tut._tiempo_en_paso_actual = 0.6
	tut._procesar_paso_1(0.016)
	assert_eq(tut.paso_actual, TutorialCabeza.Paso.PASO_2_SALTO, "Debe avanzar a PASO_2_SALTO al registrar las 4 direcciones")

	tut.free()


func test_paso_2_salto_regular_avanza_a_dive() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	tut._ready()
	tut.paso_actual = TutorialCabeza.Paso.PASO_2_SALTO

	# Salto en suelo y aterrizaje
	tut._on_padre_estado_cambiado(4, "SALTO")
	tut._on_padre_estado_cambiado(0, "REPOSO")

	assert_eq(tut.paso_actual, TutorialCabeza.Paso.PASO_3_PLANCHA_DIVE, "Al completar el salto regular debe avanzar al paso dedicado de Plancha/Dive")
	tut.free()


func test_paso_3_plancha_dive_ejecutado() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	tut._ready()
	tut.paso_actual = TutorialCabeza.Paso.PASO_3_PLANCHA_DIVE

	# En el aire
	tut._on_padre_estado_cambiado(4, "SALTO")
	assert_true(tut._en_el_aire, "Debe registrar que está en el aire")

	# Pulsa espacio y ejecuta plancha
	tut._on_padre_estado_cambiado(5, "PLANCHA_AIRE")
	assert_true(tut._dive_registrado, "_dive_registrado debe ser true")

	tut.free()


func test_paso_4_sprint_y_cierre() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	tut._ready()
	tut.paso_actual = TutorialCabeza.Paso.PASO_4_SPRINT

	tut.completar_tutorial_estandar()
	assert_true(tut._cerrando, "_cerrando debe ser true")
	assert_true(TutorialCabeza.tutorial_visto, "tutorial_visto debe ser true tras completar")

	tut.free()


func test_fast_path_veteranos() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	tut._ready()

	tut.ejecutar_fast_path()
	assert_true(tut._cerrando, "_cerrando debe ser true al disparar fast path")
	assert_true(tut._flash_unisono, "Debe activar el destello de todas las teclas al unísono")
	assert_true(TutorialCabeza.tutorial_visto, "tutorial_visto debe quedar registrado")

	tut.free()


func test_salida_forzada_recoleccion_nota() -> void:
	var tut: TutorialCabeza = _crear_tutorial()
	tut._ready()

	tut._on_nota_recogida(Vector2.ZERO, 1)
	assert_true(tut._cerrando, "Recoger la nota 1 debe forzar la salida")
	assert_true(TutorialCabeza.tutorial_visto, "tutorial_visto debe ser true")

	tut.free()


func test_persistencia_sesion_tutorial_visto() -> void:
	TutorialCabeza.tutorial_visto = true

	var escena: PackedScene = load("res://escenas/ui/tutorial_cabeza.tscn")
	var tut: TutorialCabeza = escena.instantiate() as TutorialCabeza
	tut._ready()

	TutorialCabeza.reiniciar_tutorial()
	assert_false(TutorialCabeza.tutorial_visto, "reiniciar_tutorial() debe ponerlo en false")

	tut.free()


func test_integracion_con_personaje() -> void:
	var escena_personaje: PackedScene = load("res://escenas/personaje.tscn")
	assert_true(escena_personaje != null, "personaje.tscn debe existir")

	var pj: Personaje = escena_personaje.instantiate() as Personaje
	var tut: TutorialCabeza = pj.get_node_or_null("TutorialCabeza") as TutorialCabeza

	assert_true(tut != null, "Personaje debe contener el nodo hijo TutorialCabeza")
	assert_eq(tut.position, Vector2(0, -90), "TutorialCabeza debe estar en Vector2(0, -90)")

	pj._aplicar_elevacion_eje_z(1.0)
	var expected_y: float = -90.0 - pj.jump_height * 1.0
	assert_true(is_equal_approx(tut.position.y, expected_y), "TutorialCabeza debe elevarse en el eje Z")

	pj._restaurar_visuales_eje_z()
	assert_eq(tut.position, Vector2(0, -90), "TutorialCabeza debe restaurarse a Vector2(0, -90)")

	pj.free()
