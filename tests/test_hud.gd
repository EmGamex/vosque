@tool
class_name TestHud
extends McpTestSuite

## Pruebas unitarias para la capa HUD y el contador elástico de notas (Issue #16).

func suite_name() -> String:
	return "hud"


func test_instanciacion_y_jerarquia() -> void:
	var escena_hud: PackedScene = load("res://escenas/hud.tscn")
	assert_true(escena_hud != null, "La escena hud.tscn debe existir y cargarse")
	var hud: HUD = escena_hud.instantiate() as HUD
	assert_true(hud != null, "HUD debe ser de clase HUD")
	assert_eq(hud.layer, 10, "El CanvasLayer debe tener layer = 10")

	var margen: MarginContainer = hud.get_node_or_null("MargenSeguridad") as MarginContainer
	assert_true(margen != null, "Debe existir nodo MargenSeguridad")
	assert_eq(margen.anchors_preset, 15, "MargenSeguridad debe estar anclado a pantalla completa (15)")
	assert_eq(margen.mouse_filter, Control.MOUSE_FILTER_IGNORE, "MargenSeguridad no debe capturar clics")

	var contador: HBoxContainer = hud.get_node_or_null("MargenSeguridad/ContadorNotas") as HBoxContainer
	assert_true(contador != null, "Debe existir nodo ContadorNotas")

	var icono: TextureRect = contador.get_node_or_null("IconoNota") as TextureRect
	assert_true(icono != null, "Debe existir nodo IconoNota")
	assert_true(icono.texture != null, "IconoNota debe tener textura asignada")

	var label: Label = contador.get_node_or_null("LabelNotas") as Label
	assert_true(label != null, "Debe existir nodo LabelNotas")
	assert_eq(label.text, "x 0", "El texto inicial debe ser 'x 0'")

	hud.free()


func test_actualizacion_contador() -> void:
	var escena_hud: PackedScene = load("res://escenas/hud.tscn")
	var hud: HUD = escena_hud.instantiate() as HUD
	hud._ready()

	hud.actualizar_contador(3, false)
	assert_eq(hud.label_notas.text, "x 3", "El contador debe actualizarse a 'x 3'")

	hud.actualizar_contador(10, false)
	assert_eq(hud.label_notas.text, "x 10", "El contador debe actualizarse a 'x 10'")

	# Actualización con animación (sin fallo fuera de árbol)
	hud.actualizar_contador(11, true)
	assert_eq(hud.label_notas.text, "x 11", "El contador debe actualizarse a 'x 11' con animacion solicitada")

	hud.free()


func test_integracion_maain_hud() -> void:
	var escena_maain: PackedScene = load("res://escenas/maain.tscn")
	var maain: Maain = escena_maain.instantiate() as Maain

	var hud_nodo: HUD = maain.get_node_or_null("HUD") as HUD
	assert_true(hud_nodo != null, "La escena maain.tscn debe contener la instancia de HUD")

	hud_nodo._ready()
	maain._resolver_referencias()
	assert_true(maain.hud != null, "Maain debe resolver la referencia a HUD")

	# Simular recolección
	maain._on_nota_recolectada(Vector2(100, 100))
	assert_eq(maain.notas_recolectadas, 1, "notas_recolectadas debe ser 1")
	assert_eq(hud_nodo.label_notas.text, "x 1", "El HUD debe reflejar 1 nota recogida")

	maain.free()


func test_visibilidad_segun_pantalla_gestor() -> void:
	var escena_gestor: PackedScene = load("res://escenas/gestor_escenas.tscn")
	var gestor: GestorDeEscenas = escena_gestor.instantiate() as GestorDeEscenas
	gestor._ready()

	var contenedor: Node = gestor.get_node_or_null("Contenedor")
	assert_true(contenedor != null, "Debe existir Contenedor en GestorDeEscenas")

	var maain_nodo: Maain = contenedor.get_node_or_null("Maain") as Maain
	assert_true(maain_nodo != null, "Debe existir Maain en Contenedor")
	var hud_nodo: HUD = maain_nodo.get_node_or_null("HUD") as HUD
	assert_true(hud_nodo != null, "Debe existir HUD dentro de Maain")

	# 1. En Inicio (menú principal activo): Maain inactivo y HUD oculto
	gestor._activar(GestorDeEscenas.RUTA_MENU)
	assert_false(maain_nodo.visible, "Maain debe estar invisible en el menú de inicio")
	assert_false(hud_nodo.visible, "El HUD debe estar oculto en el menú de inicio")

	# 2. Al iniciar partida (Maain activo): Maain activo y HUD visible
	gestor._activar(GestorDeEscenas.RUTA_JUEGO)
	assert_true(maain_nodo.visible, "Maain debe estar visible durante la partida")
	assert_true(hud_nodo.visible, "El HUD debe ser visible durante la partida")

	# 3. Al ir a Game Over: Maain inactivo y HUD oculto
	gestor._activar(GestorDeEscenas.RUTA_GAME_OVER)
	assert_false(maain_nodo.visible, "Maain debe estar invisible en Game Over")
	assert_false(hud_nodo.visible, "El HUD debe estar oculto en Game Over")

	gestor.free()
