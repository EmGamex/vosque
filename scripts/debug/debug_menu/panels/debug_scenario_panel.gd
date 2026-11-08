class_name DebugScenarioPanel
extends RefCounted

## Panel de control de escenario, cuadrantes, niebla y god view (VentanaEscenario).

signal overlay_modificado

var lbl_escenario_estado: Label
var lbl_escenario_no: Label
var lbl_escenario_ne: Label
var lbl_escenario_so: Label
var lbl_escenario_se: Label
var btn_mutar: Button
var check_desactivar_niebla: CheckBox
var check_god_view: CheckBox
var check_corredores: CheckBox
var check_cuadrantes: CheckBox


func vincular_nodos(win: DebugWindow) -> void:
	if win == null:
		return
	var base = "Margin/VBox/Contenido/VBoxEscenario/"
	lbl_escenario_estado = win.get_node_or_null(base + "LblEstadoEscenario") as Label
	lbl_escenario_no = win.get_node_or_null(base + "GridSectores/ValNO") as Label
	lbl_escenario_ne = win.get_node_or_null(base + "GridSectores/ValNE") as Label
	lbl_escenario_so = win.get_node_or_null(base + "GridSectores/ValSO") as Label
	lbl_escenario_se = win.get_node_or_null(base + "GridSectores/ValSE") as Label
	btn_mutar = win.get_node_or_null(base + "BtnMutar") as Button
	check_desactivar_niebla = win.get_node_or_null(base + "CheckDesactivarNiebla") as CheckBox
	check_god_view = win.get_node_or_null(base + "CheckGodView") as CheckBox
	check_corredores = win.get_node_or_null(base + "CheckCorredores") as CheckBox
	check_cuadrantes = win.get_node_or_null(base + "CheckCuadrantes") as CheckBox


func conectar_eventos(scenario: DebugScenarioController, context: DebugContext, get_cfg: Callable) -> void:
	if btn_mutar != null and not btn_mutar.pressed.is_connected(_on_btn_mutar_pressed.bind(scenario, context)):
		btn_mutar.pressed.connect(_on_btn_mutar_pressed.bind(scenario, context))
	if check_desactivar_niebla != null and not check_desactivar_niebla.toggled.is_connected(_on_check_niebla_toggled.bind(scenario, context, get_cfg)):
		check_desactivar_niebla.toggled.connect(_on_check_niebla_toggled.bind(scenario, context, get_cfg))
	if check_god_view != null and not check_god_view.toggled.is_connected(_on_check_god_view_toggled.bind(scenario, context, get_cfg)):
		check_god_view.toggled.connect(_on_check_god_view_toggled.bind(scenario, context, get_cfg))
	if check_corredores != null and not check_corredores.toggled.is_connected(_on_check_corredores_toggled.bind(scenario, get_cfg)):
		check_corredores.toggled.connect(_on_check_corredores_toggled.bind(scenario, get_cfg))
	if check_cuadrantes != null and not check_cuadrantes.toggled.is_connected(_on_check_cuadrantes_toggled.bind(scenario, get_cfg)):
		check_cuadrantes.toggled.connect(_on_check_cuadrantes_toggled.bind(scenario, get_cfg))


func restaurar_desde_config(scenario: DebugScenarioController, cfg: Node) -> void:
	if scenario != null:
		scenario.restaurar_desde_config(cfg, check_god_view, check_corredores, check_cuadrantes, check_desactivar_niebla)


func actualizar_telemetria(telemetry: DebugTelemetryPresenter, target_escenario: Node2D, cuadrante_jugador: String) -> void:
	if telemetry == null:
		return
	telemetry.actualizar_tab_escenario({
		"lbl_escenario_estado": lbl_escenario_estado,
		"lbl_escenario_no": lbl_escenario_no,
		"lbl_escenario_ne": lbl_escenario_ne,
		"lbl_escenario_so": lbl_escenario_so,
		"lbl_escenario_se": lbl_escenario_se
	}, target_escenario, cuadrante_jugador)


func _on_btn_mutar_pressed(scenario: DebugScenarioController, context: DebugContext) -> void:
	if scenario != null:
		scenario.forzar_mutacion(context.target_escenario)


func _on_check_niebla_toggled(toggled_on: bool, scenario: DebugScenarioController, context: DebugContext, get_cfg: Callable) -> void:
	if scenario != null:
		scenario.set_desactivar_niebla(toggled_on, context, get_cfg.call())


func _on_check_god_view_toggled(toggled_on: bool, scenario: DebugScenarioController, context: DebugContext, get_cfg: Callable) -> void:
	if scenario != null:
		scenario.set_god_view(toggled_on, context, get_cfg.call())


func _on_check_corredores_toggled(toggled_on: bool, scenario: DebugScenarioController, get_cfg: Callable) -> void:
	if scenario != null:
		scenario.set_dibujar_corredores(toggled_on, get_cfg.call())
		emit_signal("overlay_modificado")


func _on_check_cuadrantes_toggled(toggled_on: bool, scenario: DebugScenarioController, get_cfg: Callable) -> void:
	if scenario != null:
		scenario.set_dibujar_cuadrantes(toggled_on, get_cfg.call())
		emit_signal("overlay_modificado")
