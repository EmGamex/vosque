@tool
class_name TestIndicadorEstamina
extends McpTestSuite

## Pruebas unitarias para el indicador circular diegético de estamina (Issue #16).

func suite_name() -> String:
	return "indicador_estamina"


func test_instanciacion_y_valores_defecto() -> void:
	var escena: PackedScene = load("res://escenas/ui/indicador_estamina.tscn")
	assert_true(escena != null, "La escena indicador_estamina.tscn debe existir")
	var inst: IndicadorEstamina = escena.instantiate() as IndicadorEstamina
	assert_true(inst != null, "Debe ser de clase IndicadorEstamina")

	inst._ready()
	assert_eq(inst.modulate.a, 0.0, "Al 100% de estamina debe iniciar totalmente invisible")
	assert_eq(inst.ratio_estamina, 1.0, "El ratio inicial debe ser 1.0")
	assert_false(inst.esta_fatigado, "No debe arrancar fatigado")
	assert_eq(inst.z_index, 2, "z_index debe ser 2 para estar sobre el personaje")

	inst.free()


func test_consumo_y_visibilidad() -> void:
	var escena: PackedScene = load("res://escenas/ui/indicador_estamina.tscn")
	var inst: IndicadorEstamina = escena.instantiate() as IndicadorEstamina
	inst._ready()

	# Al consumir (< 100%)
	inst.actualizar_estamina(75.0, 100.0, false)
	assert_true(is_equal_approx(inst.ratio_estamina, 0.75), "El ratio de estamina debe ser 0.75")
	assert_true(inst.modulate.a > 0.0, "El indicador debe ser visible al consumir estamina")
	assert_false(inst.esta_fatigado, "No debe estar en fatiga con 75%")

	inst.free()


func test_estado_fatiga() -> void:
	var escena: PackedScene = load("res://escenas/ui/indicador_estamina.tscn")
	var inst: IndicadorEstamina = escena.instantiate() as IndicadorEstamina
	inst._ready()

	# Caer bajo el umbral de fatiga (< 30%)
	inst.actualizar_estamina(20.0, 100.0, true)
	assert_true(inst.esta_fatigado, "esta_fatigado debe ser true")
	assert_true(inst.ratio_estamina < inst.umbral_fatiga, "ratio debe ser menor a umbral_fatiga")

	# Avance de tiempo para verificar titileo sin excepciones
	inst._process(0.1)
	assert_true(inst._tiempo_acumulado > 0.0, "_tiempo_acumulado debe incrementarse para el titileo")

	inst.free()


func test_recarga_completa() -> void:
	var escena: PackedScene = load("res://escenas/ui/indicador_estamina.tscn")
	var inst: IndicadorEstamina = escena.instantiate() as IndicadorEstamina
	inst._ready()

	# Primero consumimos para que sea visible
	inst.actualizar_estamina(50.0, 100.0, false)
	assert_true(inst.modulate.a > 0.0)

	# Al llegar al 100%
	inst.actualizar_estamina(100.0, 100.0, false)
	assert_eq(inst.ratio_estamina, 1.0, "Ratio debe ser 1.0 al recargar")
	assert_eq(inst.modulate.a, 0.0, "Fuera de árbol debe volver a alpha 0.0")

	inst.free()


func test_integracion_con_personaje() -> void:
	var escena_personaje: PackedScene = load("res://escenas/personaje.tscn")
	var personaje: Personaje = escena_personaje.instantiate() as Personaje

	var indicador: IndicadorEstamina = personaje.get_node_or_null("IndicadorEstamina") as IndicadorEstamina
	assert_true(indicador != null, "Personaje debe tener nodo hijo IndicadorEstamina")
	assert_eq(indicador.position, Vector2(0, -60), "El indicador debe estar ubicado en Vector2(0, -60)")

	indicador._ready()
	personaje._ready()
	# Verificar que el indicador se conectó a estamina_cambiada
	assert_true(personaje.estamina_cambiada.is_connected(Callable(indicador, "actualizar_estamina")), "Indicador debe estar conectado a estamina_cambiada")

	# Simular gasto en personaje
	personaje.stamina = 50.0
	personaje.estamina_cambiada.emit(personaje.stamina, personaje.max_stamina, false)
	assert_true(is_equal_approx(indicador.ratio_estamina, 0.5), "El indicador debe reflejar la estamina del personaje (0.5)")

	# Simular elevación en salto
	personaje._aplicar_elevacion_eje_z(1.0)
	assert_true(is_equal_approx(indicador.position.y, -60.0 - personaje.jump_height), "El indicador debe acompañar la altura del salto en Z")

	personaje._restaurar_visuales_eje_z()
	assert_eq(indicador.position, Vector2(0, -60), "Al restaurar visuales el indicador vuelve a (0, -60)")

	personaje.free()


func test_animacion_tween_consumo_brusco() -> void:
	var escena: PackedScene = load("res://escenas/ui/indicador_estamina.tscn")
	var inst: IndicadorEstamina = escena.instantiate() as IndicadorEstamina
	inst._ready()

	assert_eq(inst.ratio_visual, 1.0, "ratio_visual inicial debe ser 1.0")

	# Simular consumo brusco de salto (-20 pts -> 80%)
	inst.actualizar_estamina(80.0, 100.0, false)
	assert_eq(inst.ratio_estamina, 0.8, "ratio_estamina logico debe ser 0.8")
	# Fuera del arbol se resuelve a 0.8
	assert_eq(inst.ratio_visual, 0.8, "ratio_visual debe reflejar 0.8 fuera de arbol")

	inst.free()
