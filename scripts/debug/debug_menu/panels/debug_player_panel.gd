class_name DebugPlayerPanel
extends RefCounted

## Panel de telemetría y cheats del jugador (VentanaJugador).

var lbl_vel: Label
var lbl_vel_max: Label
var lbl_acel: Label
var lbl_fric: Label
var lbl_estado: Label
var lbl_estamina: Label
var lbl_pos_jugador: Label
var lbl_cuadrante_jugador: Label
var flecha_up: Label
var flecha_down: Label
var flecha_left: Label
var flecha_right: Label
var check_estamina_infinita: CheckBox
var check_god_mode: CheckBox


func vincular_nodos(win: DebugWindow) -> void:
	if win == null:
		return
	var base = "Margin/VBox/Contenido/VBoxJugador/"
	lbl_vel = win.get_node_or_null(base + "GridTelemetria/ValVel") as Label
	lbl_vel_max = win.get_node_or_null(base + "GridTelemetria/ValVelMax") as Label
	lbl_acel = win.get_node_or_null(base + "GridTelemetria/ValAcel") as Label
	lbl_fric = win.get_node_or_null(base + "GridTelemetria/ValFric") as Label
	lbl_estado = win.get_node_or_null(base + "GridTelemetria/ValEstado") as Label
	lbl_estamina = win.get_node_or_null(base + "GridTelemetria/ValEstamina") as Label
	lbl_pos_jugador = win.get_node_or_null(base + "GridTelemetria/ValPosicion") as Label
	lbl_cuadrante_jugador = win.get_node_or_null(base + "GridTelemetria/ValCuadrante") as Label

	flecha_up = win.get_node_or_null(base + "HBoxPad/GridPad/FlechaUp") as Label
	flecha_down = win.get_node_or_null(base + "HBoxPad/GridPad/FlechaDown") as Label
	flecha_left = win.get_node_or_null(base + "HBoxPad/GridPad/FlechaLeft") as Label
	flecha_right = win.get_node_or_null(base + "HBoxPad/GridPad/FlechaRight") as Label

	check_estamina_infinita = win.get_node_or_null(base + "HBoxCheats/CheckEstaminaInfinita") as CheckBox
	check_god_mode = win.get_node_or_null(base + "HBoxCheats/CheckGodMode") as CheckBox


func conectar_eventos(cheats: DebugCheatsController, context: DebugContext, get_cfg: Callable) -> void:
	if check_estamina_infinita != null and not check_estamina_infinita.toggled.is_connected(_on_estamina_toggled.bind(cheats, context, get_cfg)):
		check_estamina_infinita.toggled.connect(_on_estamina_toggled.bind(cheats, context, get_cfg))
	if check_god_mode != null and not check_god_mode.toggled.is_connected(_on_god_mode_toggled.bind(cheats, context, get_cfg)):
		check_god_mode.toggled.connect(_on_god_mode_toggled.bind(cheats, context, get_cfg))


func restaurar_desde_config(cheats: DebugCheatsController, cfg: Node) -> void:
	if cheats != null:
		cheats.restaurar_desde_config(cfg, check_estamina_infinita, check_god_mode)


func actualizar_telemetria(telemetry: DebugTelemetryPresenter, context: DebugContext, vel_actual: float, vel_max: float, acel: float, fric: float, estado_txt: String, estamina_txt: String, pos_jugador: Vector2, cuadrante_jugador: String) -> void:
	if telemetry == null:
		return
	telemetry.actualizar_tab_jugador({
		"lbl_vel": lbl_vel,
		"lbl_vel_max": lbl_vel_max,
		"lbl_acel": lbl_acel,
		"lbl_fric": lbl_fric,
		"lbl_estado": lbl_estado,
		"lbl_estamina": lbl_estamina,
		"lbl_pos_jugador": lbl_pos_jugador,
		"lbl_cuadrante_jugador": lbl_cuadrante_jugador
	}, context.target_character, context, vel_actual, vel_max, acel, fric, estado_txt, estamina_txt, pos_jugador, cuadrante_jugador)

	var dir_input := Input.get_vector("personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo")
	if dir_input == Vector2.ZERO:
		dir_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	telemetry.actualizar_pad_direccional({
		"flecha_up": flecha_up,
		"flecha_down": flecha_down,
		"flecha_left": flecha_left,
		"flecha_right": flecha_right
	}, dir_input)


func _on_estamina_toggled(toggled_on: bool, cheats: DebugCheatsController, context: DebugContext, get_cfg: Callable) -> void:
	if cheats != null:
		cheats.set_estamina_infinita(toggled_on, context.target_character, get_cfg.call())


func _on_god_mode_toggled(toggled_on: bool, cheats: DebugCheatsController, context: DebugContext, get_cfg: Callable) -> void:
	if cheats != null:
		cheats.set_god_mode(toggled_on, context.target_character, get_cfg.call())
