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

	# Configuración cíclica en foco vertical (LinkEmGamex <-> LinkNixu <-> BotonVolver) y bloqueo lateral
	assert_eq(String(panel.boton_volver.focus_neighbor_top), "../ScrollCreditos/ListaSecciones/SecAssets/LinkNixu", "focus_neighbor_top de BotonVolver debe apuntar a LinkNixu")
	assert_eq(String(panel.boton_volver.focus_neighbor_bottom), "../ScrollCreditos/ListaSecciones/SecDesarrollo/LinkEmGamex", "focus_neighbor_bottom de BotonVolver debe apuntar a LinkEmGamex")
	assert_eq(String(panel.boton_volver.focus_neighbor_left), ".", "focus_neighbor_left debe ser cíclico")
	assert_eq(String(panel.boton_volver.focus_neighbor_right), ".", "focus_neighbor_right debe ser cíclico")
	assert_eq(String(panel.link_emgamex.focus_neighbor_top), "../../../../../BotonVolver", "focus_neighbor_top de LinkEmGamex debe apuntar a BotonVolver")
	assert_eq(String(panel.link_emgamex.focus_neighbor_bottom), "../../SecAssets/LinkNixu", "focus_neighbor_bottom de LinkEmGamex debe apuntar a LinkNixu")
	assert_eq(String(panel.link_nixu.focus_neighbor_top), "../../SecDesarrollo/LinkEmGamex", "focus_neighbor_top de LinkNixu debe apuntar a LinkEmGamex")
	assert_eq(String(panel.link_nixu.focus_neighbor_bottom), "../../../../../BotonVolver", "focus_neighbor_bottom de LinkNixu debe apuntar a BotonVolver")

	panel.free()


func test_aislamiento_foco_y_mouse_filter() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_CREDITOS)
	var panel: MenuCreditos = escena.instantiate() as MenuCreditos
	panel._ready()

	# Tras _ready() debe arrancar desactivado
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter debe ignorarse en reposo")
	assert_eq(panel.boton_volver.focus_mode, Control.FOCUS_NONE, "BotonVolver debe tener FOCUS_NONE en reposo")
	assert_eq(panel.link_emgamex.focus_mode, Control.FOCUS_NONE, "LinkEmGamex debe tener FOCUS_NONE en reposo")
	assert_eq(panel.link_nixu.focus_mode, Control.FOCUS_NONE, "LinkNixu debe tener FOCUS_NONE en reposo")

	# Tras activar() debe tener FOCUS_ALL y MOUSE_FILTER_STOP
	panel.activar()
	assert_true(panel.visible, "Debe ser visible tras activar()")
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_STOP, "Mouse filter debe detener eventos tras activar()")
	assert_eq(panel.boton_volver.focus_mode, Control.FOCUS_ALL, "BotonVolver debe tener FOCUS_ALL tras activar()")
	assert_eq(panel.link_emgamex.focus_mode, Control.FOCUS_ALL, "LinkEmGamex debe tener FOCUS_ALL tras activar()")
	assert_eq(panel.link_nixu.focus_mode, Control.FOCUS_ALL, "LinkNixu debe tener FOCUS_ALL tras activar()")

	# Tras desactivar() debe volver a FOCUS_NONE y MOUSE_FILTER_IGNORE
	panel.desactivar()
	assert_eq(panel.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter debe volver a IGNORE tras desactivar()")
	assert_eq(panel.boton_volver.focus_mode, Control.FOCUS_NONE, "BotonVolver debe volver a FOCUS_NONE tras desactivar()")
	assert_eq(panel.link_emgamex.focus_mode, Control.FOCUS_NONE, "LinkEmGamex debe volver a FOCUS_NONE tras desactivar()")
	assert_eq(panel.link_nixu.focus_mode, Control.FOCUS_NONE, "LinkNixu debe volver a FOCUS_NONE tras desactivar()")

	panel.free()


func test_scroll_creditos_sin_foco_y_reinicio_al_activar() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_CREDITOS)
	var panel: MenuCreditos = escena.instantiate() as MenuCreditos
	panel._ready()

	assert_true(panel.scroll_creditos != null, "Debe existir ScrollCreditos")
	assert_eq(panel.scroll_creditos.focus_mode, Control.FOCUS_NONE, "ScrollCreditos no debe robar foco")

	panel.scroll_creditos.scroll_vertical = 120
	panel.activar()
	assert_eq(panel.scroll_creditos.scroll_vertical, 0, "activar() debe reiniciar el scroll al inicio")

	panel.free()


func test_enlaces_externos_abren_urls_correctas() -> void:
	var escena: PackedScene = load(RUTA_ESCENA_CREDITOS)
	var panel: MenuCreditos = escena.instantiate() as MenuCreditos
	panel._ready()

	var urls_abiertas: Array[String] = []
	panel._abridor_url = func(url: String) -> void:
		urls_abiertas.append(url)

	# Inactivo no debe abrir URLs
	panel.link_emgamex.pressed.emit()
	panel.link_nixu.pressed.emit()
	assert_eq(urls_abiertas.size(), 0, "No debe abrir enlaces mientras el menú está inactivo")

	# Activo debe abrir las URLs exactas
	panel.activar()
	panel.link_emgamex.pressed.emit()
	panel.link_nixu.pressed.emit()
	assert_eq(urls_abiertas.size(), 2, "Debe abrir ambos enlaces al presionarlos activo")
	assert_eq(urls_abiertas[0], MenuCreditos.URL_YOUTUBE_EMGAMEX, "Debe abrir el canal de YouTube de EmGamex")
	assert_eq(urls_abiertas[1], MenuCreditos.URL_INSTAGRAM_NIXU, "Debe abrir el Instagram de Nixu")

	panel.free()

