class_name DebugPhysicsPanel
extends RefCounted

## Panel de configuración y ajuste de físicas en tiempo real (VentanaFisicas).

var check_proporcional: CheckBox
var btn_reset_fisicas: Button
var slider_vel_normal: HSlider
var val_slider_vel_normal: Label
var slider_vel_sprint: HSlider
var val_slider_vel_sprint: Label
var slider_acel: HSlider
var val_slider_acel: Label
var slider_fric: HSlider
var val_slider_fric: Label
var slider_dive_vel: HSlider
var val_slider_dive_vel: Label


func vincular_nodos(win: DebugWindow) -> void:
	if win == null:
		return
	var base = "Margin/VBox/Contenido/VBoxFisicas/"
	check_proporcional = win.get_node_or_null(base + "HBoxOpciones/CheckProporcional") as CheckBox
	btn_reset_fisicas = win.get_node_or_null(base + "HBoxOpciones/BtnResetFisicas") as Button

	slider_vel_normal = win.get_node_or_null(base + "GridVelocidades/SliderVelNormal") as HSlider
	val_slider_vel_normal = win.get_node_or_null(base + "GridVelocidades/ValSliderVelNormal") as Label
	slider_vel_sprint = win.get_node_or_null(base + "GridVelocidades/SliderVelSprint") as HSlider
	val_slider_vel_sprint = win.get_node_or_null(base + "GridVelocidades/ValSliderVelSprint") as Label
	slider_acel = win.get_node_or_null(base + "GridVelocidades/SliderAcel") as HSlider
	val_slider_acel = win.get_node_or_null(base + "GridVelocidades/ValSliderAcel") as Label
	slider_fric = win.get_node_or_null(base + "GridVelocidades/SliderFric") as HSlider
	val_slider_fric = win.get_node_or_null(base + "GridVelocidades/ValSliderFric") as Label
	slider_dive_vel = win.get_node_or_null(base + "GridVelocidades/SliderDiveVel") as HSlider
	val_slider_dive_vel = win.get_node_or_null(base + "GridVelocidades/ValSliderDiveVel") as Label


func conectar_eventos(physics: DebugPhysicsController, context: DebugContext, get_cfg: Callable) -> void:
	if check_proporcional != null and not check_proporcional.toggled.is_connected(_on_proporcional_toggled.bind(physics, get_cfg)):
		check_proporcional.toggled.connect(_on_proporcional_toggled.bind(physics, get_cfg))
	if btn_reset_fisicas != null and not btn_reset_fisicas.pressed.is_connected(_on_reset_pressed.bind(physics, context, get_cfg)):
		btn_reset_fisicas.pressed.connect(_on_reset_pressed.bind(physics, context, get_cfg))

	if slider_vel_normal != null and not slider_vel_normal.value_changed.is_connected(_on_vel_normal_changed.bind(physics, context, get_cfg)):
		slider_vel_normal.value_changed.connect(_on_vel_normal_changed.bind(physics, context, get_cfg))
	if slider_vel_sprint != null and not slider_vel_sprint.value_changed.is_connected(_on_vel_sprint_changed.bind(physics, context, get_cfg)):
		slider_vel_sprint.value_changed.connect(_on_vel_sprint_changed.bind(physics, context, get_cfg))
	if slider_acel != null and not slider_acel.value_changed.is_connected(_on_acel_changed.bind(physics, context, get_cfg)):
		slider_acel.value_changed.connect(_on_acel_changed.bind(physics, context, get_cfg))
	if slider_fric != null and not slider_fric.value_changed.is_connected(_on_fric_changed.bind(physics, context, get_cfg)):
		slider_fric.value_changed.connect(_on_fric_changed.bind(physics, context, get_cfg))
	if slider_dive_vel != null and not slider_dive_vel.value_changed.is_connected(_on_dive_vel_changed.bind(physics, context, get_cfg)):
		slider_dive_vel.value_changed.connect(_on_dive_vel_changed.bind(physics, context, get_cfg))


func restaurar_desde_config(physics: DebugPhysicsController, cfg: Node) -> void:
	if cfg == null or physics == null:
		return
	physics.set_proporcional(cfg.escalado_proporcional_activo, cfg)
	if check_proporcional != null:
		check_proporcional.set_pressed_no_signal(physics.escalado_proporcional_activo)


func obtener_ui_fisicas() -> Dictionary:
	return {
		"slider_vel_normal": slider_vel_normal,
		"slider_vel_sprint": slider_vel_sprint,
		"slider_acel": slider_acel,
		"slider_fric": slider_fric,
		"slider_dive_vel": slider_dive_vel,
		"val_slider_vel_normal": val_slider_vel_normal,
		"val_slider_vel_sprint": val_slider_vel_sprint,
		"val_slider_acel": val_slider_acel,
		"val_slider_fric": val_slider_fric,
		"val_slider_dive_vel": val_slider_dive_vel
	}


func _on_proporcional_toggled(toggled_on: bool, physics: DebugPhysicsController, get_cfg: Callable) -> void:
	if physics != null:
		physics.set_proporcional(toggled_on, get_cfg.call())


func _on_reset_pressed(physics: DebugPhysicsController, context: DebugContext, get_cfg: Callable) -> void:
	if physics != null:
		physics.reset_velocidades(context.target_character, get_cfg.call(), obtener_ui_fisicas())


func _on_vel_normal_changed(value: float, physics: DebugPhysicsController, context: DebugContext, get_cfg: Callable) -> void:
	if physics != null:
		physics.on_vel_normal_changed(value, context.target_character, get_cfg.call(), obtener_ui_fisicas())


func _on_vel_sprint_changed(value: float, physics: DebugPhysicsController, context: DebugContext, get_cfg: Callable) -> void:
	if physics != null:
		physics.on_vel_sprint_changed(value, context.target_character, get_cfg.call(), obtener_ui_fisicas())


func _on_acel_changed(value: float, physics: DebugPhysicsController, context: DebugContext, get_cfg: Callable) -> void:
	if physics != null:
		physics.on_acel_changed(value, context.target_character, get_cfg.call(), obtener_ui_fisicas())


func _on_fric_changed(value: float, physics: DebugPhysicsController, context: DebugContext, get_cfg: Callable) -> void:
	if physics != null:
		physics.on_fric_changed(value, context.target_character, get_cfg.call(), obtener_ui_fisicas())


func _on_dive_vel_changed(value: float, physics: DebugPhysicsController, context: DebugContext, get_cfg: Callable) -> void:
	if physics != null:
		physics.on_dive_vel_changed(value, context.target_character, get_cfg.call(), obtener_ui_fisicas())
