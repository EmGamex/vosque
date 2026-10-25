@tool
class_name TestMenuInicio
extends McpTestSuite

## Pruebas unitarias para MenuInicio (arquitectura, navegación por señales y parallax).

func suite_name() -> String:
	return "menu_inicio"


func _crear_instancia_menu() -> Control:
	var escena: PackedScene = load("res://escenas/menu_inicio.tscn")
	var menu: Control = escena.instantiate() as Control
	var script_menu: Script = load("res://scripts/menu_inicio.gd")
	menu.set_script(script_menu)
	return menu


func test_instanciacion_y_nodos_base() -> void:
	var menu: Control = _crear_instancia_menu()
	assert_true(menu != null, "La escena debe instanciarse")

	menu._ready()

	assert_eq(menu.get("_opcion_actual"), 1, "La opción inicial debe ser Jugar (1)")
	assert_false(menu.get("_bloqueado"), "El menú no debe arrancar bloqueado")

	var datos_opciones: Dictionary = menu.get("_datos_opciones")
	assert_true(datos_opciones.has(0), "Debe contener OPCIONES (0)")
	assert_true(datos_opciones.has(1), "Debe contener JUGAR (1)")
	assert_true(datos_opciones.has(2), "Debe contener CREDITOS (2)")

	var arbol_jugar: Sprite2D = datos_opciones[1]["arbol"]
	var arbol_opciones: Sprite2D = datos_opciones[0]["arbol"]
	assert_eq(arbol_jugar.modulate.a, 1.0, "Árbol Jugar debe tener alpha 1.0 al estar seleccionado")
	assert_eq(arbol_opciones.modulate.a, 0.0, "Árbol Opciones debe tener alpha 0.0 al no estar seleccionado")

	menu.free()


func test_navegacion_ciclica() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	# Estado inicial: JUGAR (1)
	assert_eq(menu.get("_opcion_actual"), 1)

	# Navegar a la derecha (+1) -> CREDITOS (2)
	menu._navegar(1)
	assert_eq(menu.get("_opcion_actual"), 2, "Navegar +1 desde JUGAR debe ir a CREDITOS")

	# Navegar a la derecha (+1) cíclico -> OPCIONES (0)
	menu._navegar(1)
	assert_eq(menu.get("_opcion_actual"), 0, "Navegar +1 desde CREDITOS debe ciclar a OPCIONES")

	# Navegar a la izquierda (-1) cíclico -> CREDITOS (2)
	menu._navegar(-1)
	assert_eq(menu.get("_opcion_actual"), 2, "Navegar -1 desde OPCIONES debe ciclar a CREDITOS")

	# Llamar a enfocar() debe restaurar a JUGAR (1)
	menu.enfocar()
	assert_eq(menu.get("_opcion_actual"), 1, "enfocar() debe restablecer la opción a JUGAR")

	menu.free()


func test_senales_de_confirmacion() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	var senales_recibidas: Array[String] = []

	menu.connect("jugar_solicitado", func(): senales_recibidas.append("jugar"))
	menu.connect("opciones_solicitado", func(): senales_recibidas.append("opciones"))
	menu.connect("creditos_solicitado", func(): senales_recibidas.append("creditos"))

	# Confirmar estando en JUGAR (1)
	menu.set("_opcion_actual", 1)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("jugar"), "Debe emitir jugar_solicitado")
	assert_true(menu.get("_bloqueado"), "Confirmar Jugar debe bloquear el menú para evitar doble click")

	# Confirmar OPCIONES (0)
	menu.set("_bloqueado", false)
	menu.set("_opcion_actual", 0)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("opciones"), "Debe emitir opciones_solicitado")

	# Confirmar CREDITOS (2)
	menu.set("_opcion_actual", 2)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("creditos"), "Debe emitir creditos_solicitado")

	menu.free()


func test_parallax_respeta_posiciones_capturadas() -> void:
	var menu: Control = _crear_instancia_menu()

	# Modificamos la posición de un nodo antes de _ready() simulando un cambio en el editor
	var montana: Sprite2D = menu.get_node("Fondos/Montaña1") as Sprite2D
	var posicion_custom: Vector2 = Vector2(-20.0, 310.0)
	montana.position = posicion_custom

	menu._ready()

	# Comprobamos que capturó la posición del editor
	assert_eq(menu.get("_pos_inicial_montana_1"), posicion_custom, "Debe haber capturado la posición inicial del nodo")

	# Corremos un frame de _process
	menu.add_to_group("modo_test")
	menu._process(0.1)

	# La posición actual debe ser la inicial más el delta de parallax (no Vector2(-4, 244) hardcodeado)
	var diferencia: Vector2 = montana.position - posicion_custom
	assert_true(diferencia.length() < 50.0, "El desplazamiento debe estar acotado al parallax alrededor de la posición custom")
	assert_true(montana.position != Vector2(-4.0, 244.0), "No debe haber sido forzado a la constante anterior")

	menu.free()
