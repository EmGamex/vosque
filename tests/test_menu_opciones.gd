@tool
class_name TestMenuOpciones
extends McpTestSuite

## Pruebas automatizadas para el Mockup del Menú de Opciones (navegación y controles).

const RUTA_ESCENA_OPCIONES: String = "res://escenas/ui/menu_opciones.tscn"


func suite_name() -> String:
	return "menu_opciones"


func test_instanciacion_y_foco_inicial() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_OPCIONES)
	assert_true(escena != null, "La escena de menu_opciones debe existir y cargarse")
	var panel: MenuOpciones = escena.instantiate() as MenuOpciones
	assert_true(panel != null, "La escena debe instanciarse como MenuOpciones")

	panel._ready()
	panel.activar()
	assert_true(panel._activo, "El menú debe estar activo tras llamar activar()")
	assert_eq(panel.get("_indice_foco"), 0, "El índice inicial de foco debe ser 0 (SliderMaster)")

	panel.free()


func test_navegacion_vertical_foco() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_OPCIONES)
	var panel: MenuOpciones = escena.instantiate() as MenuOpciones
	panel._ready()
	panel.activar()

	assert_eq(panel.get("_indice_foco"), 0)

	# Bajar a Música
	panel._navegar_foco(1)
	assert_eq(panel.get("_indice_foco"), 1, "Debe pasar al índice 1 (SliderMusica)")

	# Bajar a SFX
	panel._navegar_foco(1)
	assert_eq(panel.get("_indice_foco"), 2, "Debe pasar al índice 2 (SliderSFX)")

	# Bajar a Pantalla Completa
	panel._navegar_foco(1)
	assert_eq(panel.get("_indice_foco"), 3, "Debe pasar al índice 3 (CheckPantalla)")

	# Bajar a Botón Restablecer
	panel._navegar_foco(1)
	assert_eq(panel.get("_indice_foco"), 4, "Debe pasar al índice 4 (BotonRestablecer)")

	# Bajar a Botón Volver
	panel._navegar_foco(1)
	assert_eq(panel.get("_indice_foco"), 5, "Debe pasar al índice 5 (BotonVolver)")

	# Ciclar hacia abajo vuelve a Master
	panel._navegar_foco(1)
	assert_eq(panel.get("_indice_foco"), 0, "Debe ciclar al índice 0 (SliderMaster)")

	panel.free()


func test_modificar_valores_horizontalmente() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_OPCIONES)
	var panel: MenuOpciones = escena.instantiate() as MenuOpciones
	panel._ready()
	panel.activar()

	# Modificar SliderMaster
	panel.slider_master.value = 50.0
	panel._modificar_control_actual(1)
	assert_eq(panel.slider_master.value, 55.0, "Derecha debe incrementar slider en 5.0")

	# Ir a Checkbox y alternar
	panel._navegar_foco(3) # A check_pantalla_completa
	panel.check_pantalla_completa.button_pressed = false
	panel._modificar_control_actual(1)
	assert_true(panel.check_pantalla_completa.button_pressed, "Horizontal debe alternar CheckBox")

	panel.free()


func test_emision_volver_solicitado() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_OPCIONES)
	var panel: MenuOpciones = escena.instantiate() as MenuOpciones
	panel._ready()
	panel.activar()

	var senal_recibida: Array = [false]
	panel.volver_solicitado.connect(func(): senal_recibida[0] = true)

	panel._on_boton_volver_pressed()
	assert_true(senal_recibida[0], "Presionar botón volver debe emitir volver_solicitado")

	panel.free()


func test_restablecer_valores_por_defecto() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_OPCIONES)
	var panel: MenuOpciones = escena.instantiate() as MenuOpciones
	panel._ready()
	panel.activar()

	# Alterar valores
	panel.slider_master.value = 20.0
	panel.slider_musica.value = 10.0
	panel.slider_sfx.value = 15.0
	panel.check_pantalla_completa.button_pressed = true

	# Ejecutar restablecer
	panel.restablecer_valores_por_defecto()

	# Comprobar que los valores vuelven al default_bus_layout.tres (~100% Master, ~40% Música, ~80% SFX)
	assert_true(is_equal_approx(panel.slider_master.value, 100.0), "Master debe restablecerse a 100%")
	assert_ne(panel.slider_musica.value, 10.0, "Música debe restablecerse desde 10%")
	assert_ne(panel.slider_sfx.value, 15.0, "SFX debe restablecerse desde 15%")
	assert_eq(panel.check_pantalla_completa.button_pressed, false, "Pantalla completa debe volver al modo por defecto del proyecto")

	panel.free()


func test_aislamiento_foco_y_mouse_filter() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_OPCIONES)
	var panel: MenuOpciones = escena.instantiate() as MenuOpciones
	panel._ready()

	# Tras _ready(), todos los controles deben tener FOCUS_NONE y mouse_filter IGNORE
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter debe ser IGNORE en reposo")
	var elementos: Array[Control] = panel.get("_elementos_foco")
	for elem in elementos:
		assert_eq(elem.focus_mode, Control.FOCUS_NONE, "Elementos de foco deben ser FOCUS_NONE en reposo")

	# Tras activar(), deben recuperar FOCUS_ALL y mouse_filter STOP
	panel.activar()
	assert_true(panel.visible, "Debe ser visible tras activar()")
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_STOP, "Mouse filter debe ser STOP tras activar()")
	for elem in elementos:
		assert_eq(elem.focus_mode, Control.FOCUS_ALL, "Elementos de foco deben recuperar FOCUS_ALL tras activar()")

	# Tras desactivar(), deben volver a FOCUS_NONE
	panel.desactivar()
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter debe volver a IGNORE tras desactivar()")
	for elem in elementos:
		assert_eq(elem.focus_mode, Control.FOCUS_NONE, "Elementos de foco deben volver a FOCUS_NONE tras desactivar()")

	# Verificar bloqueo lateral en controles no sliders
	assert_eq(String(panel.slider_sfx.focus_neighbor_bottom), "../../FilaPantalla/CheckPantalla", "SliderSFX debe apuntar a CheckPantalla abajo")
	assert_eq(String(panel.check_pantalla_completa.focus_neighbor_top), "../../FilaSFX/SliderSFX", "CheckPantalla debe apuntar a SliderSFX arriba")
	assert_eq(String(panel.check_pantalla_completa.focus_neighbor_left), ".", "CheckPantalla debe bloquear izquierda")
	assert_eq(String(panel.check_pantalla_completa.focus_neighbor_right), ".", "CheckPantalla debe bloquear derecha")
	assert_eq(String(panel.boton_restablecer.focus_neighbor_left), ".", "BotonRestablecer debe bloquear izquierda")
	assert_eq(String(panel.boton_restablecer.focus_neighbor_right), ".", "BotonRestablecer debe bloquear derecha")
	assert_eq(String(panel.boton_volver.focus_neighbor_left), ".", "BotonVolver debe bloquear izquierda")
	assert_eq(String(panel.boton_volver.focus_neighbor_right), ".", "BotonVolver debe bloquear derecha")

	panel.free()
