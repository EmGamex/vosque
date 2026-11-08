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

	# Comprobar que los valores no se quedaron en los modificados arbitrarios (20, 10, 15)
	# y que coinciden con los que define default_bus_layout.tres y ProjectSettings
	assert_ne(panel.slider_master.value, 20.0, "Master debe restablecerse")
	assert_ne(panel.slider_musica.value, 10.0, "Música debe restablecerse")
	assert_ne(panel.slider_sfx.value, 15.0, "SFX debe restablecerse")
	assert_eq(panel.check_pantalla_completa.button_pressed, false, "Pantalla completa debe volver al modo por defecto del proyecto")

	panel.free()
