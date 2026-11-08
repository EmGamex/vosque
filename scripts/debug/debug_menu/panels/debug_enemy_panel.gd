class_name DebugEnemyPanel
extends RefCounted

## Panel de telemetría y control de IA enemiga (VentanaEnemigo).

var lbl_enemigo_estado: Label
var lbl_enemigo_pos: Label
var lbl_enemigo_dist: Label
var lbl_enemigo_vel: Label
var lbl_enemigo_atascado: Label
var btn_teleport_enemigo: Button
var check_visual_debug: CheckBox


func vincular_nodos(win: DebugWindow) -> void:
	if win == null:
		return
	var base = "Margin/VBox/Contenido/VBoxEnemigo/"
	lbl_enemigo_estado = win.get_node_or_null(base + "GridEnemigo/ValEstadoIA") as Label
	lbl_enemigo_pos = win.get_node_or_null(base + "GridEnemigo/ValPosEnemigo") as Label
	lbl_enemigo_dist = win.get_node_or_null(base + "GridEnemigo/ValDistancia") as Label
	lbl_enemigo_vel = win.get_node_or_null(base + "GridEnemigo/ValVelEnemigo") as Label
	lbl_enemigo_atascado = win.get_node_or_null(base + "GridEnemigo/ValAtascamiento") as Label
	btn_teleport_enemigo = win.get_node_or_null(base + "BtnTeleportEnemigo") as Button
	check_visual_debug = win.get_node_or_null(base + "CheckVisualDebug") as CheckBox


func conectar_eventos(enemy_ctrl: DebugEnemyController, context: DebugContext, get_cfg: Callable) -> void:
	if btn_teleport_enemigo != null and not btn_teleport_enemigo.pressed.is_connected(_on_btn_teleport_pressed.bind(enemy_ctrl, context)):
		btn_teleport_enemigo.pressed.connect(_on_btn_teleport_pressed.bind(enemy_ctrl, context))
	if check_visual_debug != null and not check_visual_debug.toggled.is_connected(_on_check_visual_debug_toggled.bind(enemy_ctrl, context, get_cfg)):
		check_visual_debug.toggled.connect(_on_check_visual_debug_toggled.bind(enemy_ctrl, context, get_cfg))


func restaurar_desde_config(enemy_ctrl: DebugEnemyController, cfg: Node) -> void:
	if enemy_ctrl != null:
		enemy_ctrl.restaurar_desde_config(cfg, check_visual_debug)


func actualizar_telemetria(telemetry: DebugTelemetryPresenter, context: DebugContext, pos_jugador: Vector2, dibujar_vectores_ia: bool) -> void:
	if telemetry == null:
		return
	telemetry.actualizar_tab_enemigo({
		"lbl_enemigo_estado": lbl_enemigo_estado,
		"lbl_enemigo_pos": lbl_enemigo_pos,
		"lbl_enemigo_dist": lbl_enemigo_dist,
		"lbl_enemigo_vel": lbl_enemigo_vel,
		"lbl_enemigo_atascado": lbl_enemigo_atascado
	}, context.target_enemigo, pos_jugador, context, dibujar_vectores_ia)


func _on_btn_teleport_pressed(enemy_ctrl: DebugEnemyController, context: DebugContext) -> void:
	if enemy_ctrl != null:
		enemy_ctrl.reubicar_enemigo(context.target_enemigo, context.target_character)


func _on_check_visual_debug_toggled(toggled_on: bool, enemy_ctrl: DebugEnemyController, context: DebugContext, get_cfg: Callable) -> void:
	if enemy_ctrl != null:
		enemy_ctrl.set_visual_debug(toggled_on, context.target_enemigo, get_cfg.call())
