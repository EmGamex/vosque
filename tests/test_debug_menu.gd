@tool
class_name TestDebugMenu
extends McpTestSuite

## Suite de pruebas para la arquitectura modular de debug_menu.

class MockCharacter extends CharacterBody2D:
	var speed: float = 800.0
	var sprint_speed: float = 1000.0
	var acceleration: float = 5000.0
	var friction: float = 5000.0
	var dive_speed: float = 1200.0
	var sin_gasto_estamina: bool = false
	var god_mode: bool = false


func suite_name() -> String:
	return "debug_menu"


func test_cuadrantes_calculo() -> void:
	var context := DebugContext.new()
	assert_eq(context.calcular_cuadrante(Vector2(-500.0, -500.0)), "NO", "(-500, -500) debe ser sector NO")
	assert_eq(context.calcular_cuadrante(Vector2(500.0, -500.0)), "NE", "(500, -500) debe ser sector NE")
	assert_eq(context.calcular_cuadrante(Vector2(-500.0, 500.0)), "SO", "(-500, 500) debe ser sector SO")
	assert_eq(context.calcular_cuadrante(Vector2(500.0, 500.0)), "SE", "(500, 500) debe ser sector SE")
	assert_eq(context.obtener_centro_cuadrante("NO"), "(-1080, -1080)", "Centro de NO debe ser (-1080, -1080)")


func test_fisicas_escalado_proporcional() -> void:
	var physics := DebugPhysicsController.new()
	physics.vel_normal_defecto = 800.0
	physics.vel_sprint_defecto = 1000.0
	physics.acel_defecto = 5000.0
	physics.fric_defecto = 5000.0
	physics.dive_vel_defecto = 1200.0
	physics.escalado_proporcional_activo = true

	var dummy_char := MockCharacter.new()

	# Modificamos velocidad normal al doble (1600 px/s)
	physics.on_vel_normal_changed(1600.0, dummy_char, null, {})
	assert_eq(dummy_char.speed, 1600.0, "La velocidad del personaje debe actualizarse")
	assert_eq(dummy_char.sprint_speed, 2000.0, "Sprint speed debe duplicarse proporcionalmente")
	assert_eq(dummy_char.acceleration, 10000.0, "Aceleración debe duplicarse proporcionalmente")
	assert_eq(dummy_char.friction, 10000.0, "Fricción debe duplicarse proporcionalmente")
	assert_eq(dummy_char.dive_speed, 2400.0, "Dive speed debe duplicarse proporcionalmente")

	# Probar reset a valores base
	physics.reset_velocidades(dummy_char, null, {})
	assert_eq(dummy_char.speed, 800.0, "Velocidad reseteada a 800")
	assert_eq(dummy_char.sprint_speed, 1000.0, "Sprint reseteado a 1000")
	assert_eq(dummy_char.acceleration, 5000.0, "Aceleración reseteada a 5000")

	dummy_char.free()


func test_cheats_controller() -> void:
	var cheats := DebugCheatsController.new()
	var dummy_char := MockCharacter.new()

	cheats.set_estamina_infinita(true, dummy_char, null)
	assert_true(cheats.cheat_estamina_infinita, "Cheat estamina infinita debe ser true")
	assert_eq(dummy_char.sin_gasto_estamina, true, "Personaje sin_gasto_estamina debe activarse")

	cheats.set_god_mode(true, dummy_char, null)
	assert_true(cheats.cheat_god_mode, "Cheat god mode debe ser true")
	assert_eq(dummy_char.god_mode, true, "Personaje god_mode debe activarse")

	cheats.set_estamina_infinita(false, dummy_char, null)
	assert_eq(dummy_char.sin_gasto_estamina, false, "Personaje sin_gasto_estamina debe desactivarse")

	dummy_char.free()


func test_debug_menu_instanciacion() -> void:
	var escena_debug: PackedScene = load("res://escenas/debug_menu.tscn")
	assert_true(escena_debug != null, "La escena debug_menu.tscn debe poder cargarse")
	var instancia: DebugMenu = escena_debug.instantiate() as DebugMenu
	assert_true(instancia != null, "La instancia debe ser del tipo DebugMenu")
	assert_true(instancia.context != null, "Sub-controlador context debe inicializarse")
	assert_true(instancia.cheats != null, "Sub-controlador cheats debe inicializarse")
	assert_true(instancia.physics != null, "Sub-controlador physics debe inicializarse")
	assert_true(instancia.scenario != null, "Sub-controlador scenario debe inicializarse")
	assert_true(instancia.enemy_ctrl != null, "Sub-controlador enemy_ctrl debe inicializarse")
	assert_true(instancia.system_ctrl != null, "Sub-controlador system_ctrl debe inicializarse")
	assert_true(instancia.telemetry != null, "Sub-controlador telemetry debe inicializarse")
	assert_true(instancia.monitors != null, "Sub-controlador monitors debe inicializarse")
	instancia.free()


func test_camara_dios_zoom_y_escenario() -> void:
	assert_eq(DebugScenarioController.ZOOM_GOD_VIEW, Vector2(0.225, 0.225), "ZOOM_GOD_VIEW debe ser 0.225 para arena 4320x4320")
	var escena_main: PackedScene = load("res://escenas/maain.tscn")
	assert_true(escena_main != null, "maain.tscn debe cargar")
	var inst: Node2D = escena_main.instantiate() as Node2D
	assert_true(inst != null, "maain debe instanciarse")
	var cam_dios: Camera2D = inst.get_node_or_null("CamaraDios") as Camera2D
	assert_true(cam_dios != null, "Debe existir CamaraDios en maain.tscn")
	assert_eq(cam_dios.zoom, Vector2(0.225, 0.225), "CamaraDios debe tener zoom (0.225, 0.225)")
	inst.free()


func test_desactivar_niebla_en_debug() -> void:
	var escena_debug: PackedScene = load("res://escenas/debug_menu.tscn")
	assert_true(escena_debug != null, "debug_menu.tscn debe cargar")
	var menu: DebugMenu = escena_debug.instantiate() as DebugMenu
	assert_true(menu != null, "DebugMenu debe instanciarse")

	var check_niebla = menu.get_node_or_null("ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/CheckDesactivarNiebla") as CheckBox
	assert_true(check_niebla != null, "Debe existir CheckDesactivarNiebla en la pestaña Escenario")

	# Probar activación y desactivación de la niebla en el scenario controller
	var cfg = load("res://scripts/debug_config.gd").new()
	cfg.niebla_desactivada = false
	menu.scenario.set_desactivar_niebla(true, menu.context, cfg)
	assert_true(menu.scenario.niebla_desactivada, "La niebla debe quedar marcada como desactivada")
	assert_true(cfg.niebla_desactivada, "Debe persistirse en cfg")

	menu.scenario.set_desactivar_niebla(false, menu.context, cfg)
	assert_false(menu.scenario.niebla_desactivada, "La niebla debe quedar habilitada de nuevo")
	assert_false(cfg.niebla_desactivada, "Debe persistirse falso en cfg")

	cfg.free()
	menu.free()
