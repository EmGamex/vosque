class_name DebugSystemPanel
extends RefCounted

## Panel de telemetría de rendimiento y utilidades del sistema (VentanaSistema).

var lbl_sys_fps: Label
var lbl_sys_mem: Label
var lbl_sys_timescale: Label
var btn_time_05: Button
var btn_time_10: Button
var btn_time_20: Button
var btn_reload_scene: Button
var val_high_score: Label
var btn_reset_high_score: Button


func vincular_nodos(win: DebugWindow) -> void:
	if win == null:
		return
	var base = "Margin/VBox/Contenido/VBoxSistema/"
	lbl_sys_fps = win.get_node_or_null(base + "GridSistema/ValFPS") as Label
	lbl_sys_mem = win.get_node_or_null(base + "GridSistema/ValMemoria") as Label
	lbl_sys_timescale = win.get_node_or_null(base + "GridSistema/ValTimeScale") as Label

	btn_time_05 = win.get_node_or_null(base + "HBoxTimeButtons/BtnTime05") as Button
	btn_time_10 = win.get_node_or_null(base + "HBoxTimeButtons/BtnTime10") as Button
	btn_time_20 = win.get_node_or_null(base + "HBoxTimeButtons/BtnTime20") as Button
	btn_reload_scene = win.get_node_or_null(base + "BtnReloadScene") as Button

	val_high_score = win.get_node_or_null(base + "HBoxPersistencia/ValHighScore") as Label
	btn_reset_high_score = win.get_node_or_null(base + "BtnResetearHighScore") as Button


func conectar_eventos(system_ctrl: DebugSystemController, tree: SceneTree, get_cfg: Callable) -> void:
	if btn_time_05 != null and not btn_time_05.pressed.is_connected(_set_time_scale.bind(0.5, system_ctrl, get_cfg)):
		btn_time_05.pressed.connect(_set_time_scale.bind(0.5, system_ctrl, get_cfg))
	if btn_time_10 != null and not btn_time_10.pressed.is_connected(_set_time_scale.bind(1.0, system_ctrl, get_cfg)):
		btn_time_10.pressed.connect(_set_time_scale.bind(1.0, system_ctrl, get_cfg))
	if btn_time_20 != null and not btn_time_20.pressed.is_connected(_set_time_scale.bind(2.0, system_ctrl, get_cfg)):
		btn_time_20.pressed.connect(_set_time_scale.bind(2.0, system_ctrl, get_cfg))

	if btn_reload_scene != null and not btn_reload_scene.pressed.is_connected(_on_reload_pressed.bind(system_ctrl, tree)):
		btn_reload_scene.pressed.connect(_on_reload_pressed.bind(system_ctrl, tree))

	if btn_reset_high_score != null and not btn_reset_high_score.pressed.is_connected(_on_reset_high_score_pressed.bind(system_ctrl)):
		btn_reset_high_score.pressed.connect(_on_reset_high_score_pressed.bind(system_ctrl))


func actualizar_telemetria(telemetry: DebugTelemetryPresenter, fps: int, mem_mb: float, telem_musica: Dictionary, record_actual: int, lbl_musica_estado: Label, lbl_musica_clip: Label, lbl_musica_volumen: Label) -> void:
	if telemetry == null:
		return
	telemetry.actualizar_tab_sistema({
		"lbl_sys_fps": lbl_sys_fps,
		"lbl_sys_mem": lbl_sys_mem,
		"lbl_sys_timescale": lbl_sys_timescale,
		"lbl_musica_estado": lbl_musica_estado,
		"lbl_musica_clip": lbl_musica_clip,
		"lbl_musica_volumen": lbl_musica_volumen,
		"val_high_score": val_high_score
	}, fps, mem_mb, telem_musica, record_actual)


func _set_time_scale(scale: float, system_ctrl: DebugSystemController, get_cfg: Callable) -> void:
	if system_ctrl != null:
		system_ctrl.set_time_scale(scale, get_cfg.call())


func _on_reload_pressed(system_ctrl: DebugSystemController, tree: SceneTree) -> void:
	if system_ctrl != null and tree != null:
		system_ctrl.reiniciar_escena(tree)


func _on_reset_high_score_pressed(system_ctrl: DebugSystemController) -> void:
	if system_ctrl != null:
		system_ctrl.resetear_high_score()
		if val_high_score != null:
			val_high_score.text = str(system_ctrl.obtener_high_score())
