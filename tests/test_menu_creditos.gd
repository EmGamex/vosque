@tool
class_name TestMenuCreditos
extends McpTestSuite

## Pruebas automatizadas para el Menú de Créditos (instanciación, foco y eventos de retorno).

const RUTA_ESCENA_CREDITOS: String = "res://escenas/ui/menu_creditos.tscn"


func suite_name() -> String:
	return "menu_creditos"


func test_instanciacion_y_foco_inicial() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_CREDITOS)
	assert_true(escena != null, "La escena de menu_creditos debe existir y cargarse")
	var panel: MenuCreditos = escena.instantiate() as MenuCreditos
	assert_true(panel != null, "La escena debe instanciarse como MenuCreditos")

	panel._ready()
	panel.activar()
	assert_true(panel._activo, "El menú debe estar activo tras llamar activar()")
	assert_true(panel.boton_volver != null, "Debe existir boton_volver")

	panel.desactivar()
	assert_false(panel._activo, "El menú debe desactivarse tras llamar desactivar()")

	panel.free()


func test_emision_volver_solicitado() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_CREDITOS)
	var panel: MenuCreditos = escena.instantiate() as MenuCreditos
	panel._ready()
	panel.activar()

	var senal_recibida: Array = [false]
	panel.volver_solicitado.connect(func(): senal_recibida[0] = true)

	panel._on_boton_volver_pressed()
	assert_true(senal_recibida[0], "Presionar botón volver debe emitir volver_solicitado")

	panel.free()


func test_navegacion_y_eventos_boton_volver() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_CREDITOS)
	var panel: MenuCreditos = escena.instantiate() as MenuCreditos
	panel._ready()
	assert_true(panel.boton_volver != null, "BotonVolver debe existir")

	# Simular hover / mouse_entered
	panel.activar()
	panel._on_boton_volver_mouse_entered()
	panel._on_boton_volver_focus_entered()

	# Configuración cíclica en foco (4 direcciones bloqueadas a sí mismo)
	assert_eq(String(panel.boton_volver.focus_neighbor_top), ".", "focus_neighbor_top debe ser cíclico")
	assert_eq(String(panel.boton_volver.focus_neighbor_bottom), ".", "focus_neighbor_bottom debe ser cíclico")
	assert_eq(String(panel.boton_volver.focus_neighbor_left), ".", "focus_neighbor_left debe ser cíclico")
	assert_eq(String(panel.boton_volver.focus_neighbor_right), ".", "focus_neighbor_right debe ser cíclico")

	panel.free()


func test_aislamiento_foco_y_mouse_filter() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_CREDITOS)
	var panel: MenuCreditos = escena.instantiate() as MenuCreditos
	panel._ready()

	# Tras _ready() debe arrancar desactivado
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter debe ignorarse en reposo")
	assert_eq(panel.boton_volver.focus_mode, Control.FOCUS_NONE, "BotonVolver debe tener FOCUS_NONE en reposo")

	# Tras activar() debe tener FOCUS_ALL y MOUSE_FILTER_STOP
	panel.activar()
	assert_true(panel.visible, "Debe ser visible tras activar()")
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_STOP, "Mouse filter debe detener eventos tras activar()")
	assert_eq(panel.boton_volver.focus_mode, Control.FOCUS_ALL, "BotonVolver debe tener FOCUS_ALL tras activar()")

	# Tras desactivar() debe volver a FOCUS_NONE y MOUSE_FILTER_IGNORE
	panel.desactivar()
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter debe volver a IGNORE tras desactivar()")
	assert_eq(panel.boton_volver.focus_mode, Control.FOCUS_NONE, "BotonVolver debe volver a FOCUS_NONE tras desactivar()")

	panel.free()

