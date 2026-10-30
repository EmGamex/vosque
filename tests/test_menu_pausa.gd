@tool
class_name TestMenuPausa
extends McpTestSuite

## Pruebas unitarias e integración para MenuPausa y arquitectura de pausa en GestorDeEscenas.

func suite_name() -> String:
	return "menu_pausa"


func _crear_instancia_menu() -> MenuPausa:
	var escena: PackedScene = load("res://escenas/menu_pausa.tscn")
	var menu: MenuPausa = escena.instantiate() as MenuPausa
	return menu


func _crear_instancia_gestor() -> GestorDeEscenas:
	var escena: PackedScene = load("res://escenas/gestor_escenas.tscn")
	var gestor: GestorDeEscenas = escena.instantiate() as GestorDeEscenas
	return gestor


func test_instanciacion_y_nodos_base() -> void:
	var menu: MenuPausa = _crear_instancia_menu()
	assert_true(menu != null, "La escena menu_pausa.tscn debe instanciarse")

	menu._ready()

	assert_eq(menu.layer, 50, "MenuPausa debe operar en layer = 50")
	assert_eq(menu.process_mode, Node.PROCESS_MODE_ALWAYS, "MenuPausa debe tener process_mode = PROCESS_MODE_ALWAYS")
	assert_false(menu.visible, "MenuPausa debe iniciar invisible")

	var control: Control = menu.get_node_or_null("Control") as Control
	assert_true(control != null, "Debe existir Control en MenuPausa")
	assert_eq(control.anchors_preset, 15, "Control debe ser anchors_preset = 15")

	var fondo: ColorRect = menu.get_node_or_null("Control/Fondo") as ColorRect
	assert_true(fondo != null, "Debe existir Fondo (ColorRect)")
	assert_true(fondo.color.a > 0.5, "El fondo debe ser oscuro translúcido")

	var titulo: Label = menu.get_node_or_null("Control/Layout/Columna/Titulo") as Label
	assert_true(titulo != null, "Debe existir el título")
	assert_eq(titulo.text, "PAUSA", "El texto debe ser PAUSA")

	var btn_continuar: Button = menu.get_node_or_null("Control/Layout/Columna/BotonContinuar") as Button
	var btn_reiniciar: Button = menu.get_node_or_null("Control/Layout/Columna/BotonReiniciar") as Button
	var btn_menu: Button = menu.get_node_or_null("Control/Layout/Columna/BotonMenu") as Button

	assert_true(btn_continuar != null, "Debe existir BotonContinuar")
	assert_true(btn_reiniciar != null, "Debe existir BotonReiniciar")
	assert_true(btn_menu != null, "Debe existir BotonMenu")

	menu.free()


func test_mostrar_y_ocultar() -> void:
	var menu: MenuPausa = _crear_instancia_menu()
	menu._ready()

	menu.mostrar()
	assert_true(menu.visible, "mostrar() debe volver visible el menú")
	assert_false(menu.get("_bloqueado"), "mostrar() debe resetear la bandera _bloqueado")

	var btn_continuar: Button = menu.get_node_or_null("Control/Layout/Columna/BotonContinuar") as Button
	assert_false(btn_continuar.disabled, "Los botones no deben estar deshabilitados tras mostrar()")

	menu.ocultar()
	assert_false(menu.visible, "ocultar() debe esconder el menú")

	menu.mostrar()
	menu.ocultar_inmediato()
	assert_false(menu.visible, "ocultar_inmediato() debe esconder el menú")
	assert_true(menu.get("_bloqueado"), "ocultar_inmediato() debe dejar _bloqueado = true")
	assert_true(btn_continuar.disabled, "ocultar_inmediato() debe deshabilitar botones")

	menu.free()


func test_senales_menu_pausa() -> void:
	var menu: MenuPausa = _crear_instancia_menu()
	menu._ready()

	var emitio_continuar: Array = [false]
	var emitio_reiniciar: Array = [false]
	var emitio_menu: Array = [false]

	menu.continuar_solicitado.connect(func(): emitio_continuar[0] = true)
	menu.reiniciar_solicitado.connect(func(): emitio_reiniciar[0] = true)
	menu.menu_solicitado.connect(func(): emitio_menu[0] = true)

	# 1. Probar continuar
	menu.mostrar()
	menu._on_continuar_pulsado()
	assert_true(emitio_continuar[0], "Debe emitirse continuar_solicitado")
	assert_true(menu.get("_bloqueado"), "Debe activarse _bloqueado tras pulsar")

	# Doble pulsación bloqueada
	emitio_continuar[0] = false
	menu._on_continuar_pulsado()
	assert_false(emitio_continuar[0], "No debe emitirse una segunda vez mientras esté bloqueado")

	# 2. Probar reiniciar
	menu.mostrar()
	menu._on_reiniciar_pulsado()
	assert_true(emitio_reiniciar[0], "Debe emitirse reiniciar_solicitado")

	# 3. Probar menu
	menu.mostrar()
	menu._on_menu_pulsado()
	assert_true(emitio_menu[0], "Debe emitirse menu_solicitado")

	menu.free()


func test_gestor_puede_pausar() -> void:
	var gestor: GestorDeEscenas = _crear_instancia_gestor()
	gestor._ready()

	# En menú principal no debe poder pausar
	assert_false(gestor.puede_pausar(), "No debe poder pausar en RUTA_MENU")

	# Simular cambio a RUTA_JUEGO sin instancia activa en _pantallas
	gestor.set("_ruta_actual", "res://escenas/inexistente.tscn")
	assert_false(gestor.puede_pausar(), "No debe pausar si la ruta no es RUTA_JUEGO")

	# Activar juego
	gestor._activar(GestorDeEscenas.RUTA_JUEGO)
	assert_true(gestor.puede_pausar(), "Debe poder pausar en RUTA_JUEGO activa")

	# Si está cambiando (fundido en curso), no debe pausar
	gestor.set("_cambiando", true)
	assert_false(gestor.puede_pausar(), "No debe pausar si _cambiando es true")
	gestor.set("_cambiando", false)

	# Si enemigo capturó al jugador, no debe pausar
	var contenedor: Node = gestor.get_node_or_null("Contenedor")
	var maain_nodo: Node = contenedor.get_node_or_null("Maain")
	if maain_nodo != null:
		var enemigo: Node = maain_nodo.get_node_or_null("Enemigo")
		if enemigo != null:
			enemigo.set("_capturado", true)
			assert_false(gestor.puede_pausar(), "No debe pausar si enemigo capturó al jugador")
			enemigo.set("_capturado", false)

	gestor.free()


func test_gestor_pausar_y_reanudar() -> void:
	var gestor: GestorDeEscenas = _crear_instancia_gestor()
	gestor._ready()
	gestor._activar(GestorDeEscenas.RUTA_JUEGO)

	var menu_pausa: MenuPausa = gestor.get_node_or_null("MenuPausa") as MenuPausa
	assert_true(menu_pausa != null, "GestorDeEscenas debe tener un nodo MenuPausa hijo")

	# Pausar
	gestor.pausar()
	assert_true(gestor.get("_pausado"), "_pausado debe ser true")
	assert_true(menu_pausa.visible, "MenuPausa debe ser visible")

	# Reanudar
	gestor.reanudar()
	assert_false(gestor.get("_pausado"), "_pausado debe ser false")
	assert_false(menu_pausa.visible, "MenuPausa debe quedar oculto")

	gestor.free()


func test_limpieza_pausa_en_transicion() -> void:
	var gestor: GestorDeEscenas = _crear_instancia_gestor()
	gestor._ready()
	gestor._activar(GestorDeEscenas.RUTA_JUEGO)

	var menu_pausa: MenuPausa = gestor.get_node_or_null("MenuPausa") as MenuPausa

	gestor.pausar()
	assert_true(gestor.get("_pausado"))
	assert_true(menu_pausa.visible)

	gestor._limpiar_pausa_forzada()
	assert_false(gestor.get("_pausado"), "_pausado debe restaurarse a false")
	assert_false(menu_pausa.visible, "MenuPausa debe quedar oculto tras limpieza forzada")

	gestor.free()


func test_subarbol_juego_pausable() -> void:
	var gestor: GestorDeEscenas = _crear_instancia_gestor()
	gestor._ready()

	var contenedor: Node = gestor.get_node_or_null("Contenedor")
	var maain_nodo: Node = contenedor.get_node_or_null("Maain")

	# 1. En Menú: Maain desactivado
	gestor._activar(GestorDeEscenas.RUTA_MENU)
	assert_eq(maain_nodo.process_mode, Node.PROCESS_MODE_DISABLED)

	# 2. En Juego: Maain pasa a PROCESS_MODE_PAUSABLE
	gestor._activar(GestorDeEscenas.RUTA_JUEGO)
	assert_eq(maain_nodo.process_mode, Node.PROCESS_MODE_PAUSABLE, "Maain debe ser PROCESS_MODE_PAUSABLE durante la partida")

	gestor.free()
