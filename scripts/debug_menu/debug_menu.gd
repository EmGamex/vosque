@tool
extends CanvasLayer
class_name DebugMenu

## Modos de visualización tri-estado
enum ModoVisual {
	OCULTO = 0,
	MINI_HUD = 1,
	COMPLETO = 2
}

@export var modo_actual: ModoVisual = ModoVisual.OCULTO:
	set(value):
		modo_actual = value
		_actualizar_visibilidad()
		var cfg = get_node_or_null("/root/DebugConfig")
		if cfg != null:
			cfg.modo_actual = int(modo_actual)

@export_group("Nodos de Referencia")
@export var target_character: CharacterBody2D:
	get:
		return context.target_character if context != null else null
	set(val):
		if context != null:
			context.target_character = val
@export var target_enemigo: CharacterBody2D:
	get:
		return context.target_enemigo if context != null else null
	set(val):
		if context != null:
			context.target_enemigo = val
@export var target_camara: Camera2D:
	get:
		return context.target_camara if context != null else null
	set(val):
		if context != null:
			context.target_camara = val
@export var target_camara_dios: Camera2D:
	get:
		return context.target_camara_dios if context != null else null
	set(val):
		if context != null:
			context.target_camara_dios = val
@export var target_escenario: Node2D:
	get:
		return context.target_escenario if context != null else null
	set(val):
		if context != null:
			context.target_escenario = val

# Sub-controladores modulares
var context: DebugContext
var cheats: DebugCheatsController
var physics: DebugPhysicsController
var scenario: DebugScenarioController
var enemy_ctrl: DebugEnemyController
var system_ctrl: DebugSystemController
var telemetry: DebugTelemetryPresenter
var monitors: DebugCustomMonitors

# Acceso rápido a propiedades de estado para compatibilidad con DebugOverlay
var debug_dibujar_cuadrantes: bool:
	get: return scenario.debug_dibujar_cuadrantes if scenario != null else false
	set(v): if scenario != null: scenario.debug_dibujar_cuadrantes = v

var debug_dibujar_corredores: bool:
	get: return scenario.debug_dibujar_corredores if scenario != null else false
	set(v): if scenario != null: scenario.debug_dibujar_corredores = v

var debug_dibujar_vectores_ia: bool:
	get: return enemy_ctrl.debug_dibujar_vectores_ia if enemy_ctrl != null else false
	set(v): if enemy_ctrl != null: enemy_ctrl.debug_dibujar_vectores_ia = v

var cheat_estamina_infinita: bool:
	get: return cheats.cheat_estamina_infinita if cheats != null else false
var cheat_god_mode: bool:
	get: return cheats.cheat_god_mode if cheats != null else false
var god_view_activo: bool:
	get: return scenario.god_view_activo if scenario != null else false

# Nodos de interfaz (asignados en _ready)
@onready var mini_hud: PanelContainer = $ControlRaiz/MiniHUD
@onready var label_mini_fps: Label = $ControlRaiz/MiniHUD/Margin/VBox/LabelMiniFPS
@onready var label_mini_cuadrante: Label = $ControlRaiz/MiniHUD/Margin/VBox/LabelMiniCuadrante
@onready var label_mini_vel: Label = $ControlRaiz/MiniHUD/Margin/VBox/LabelMiniVel
@onready var label_mini_estamina: Label = $ControlRaiz/MiniHUD/Margin/VBox/LabelMiniEstamina

@onready var panel_consola: PanelContainer = $ControlRaiz/PanelConsola
@onready var tab_container: TabContainer = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer
@onready var check_pausar: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/BarraSuperior/CheckPausar
@onready var check_estamina_infinita: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/HBoxCheats/CheckEstaminaInfinita
@onready var check_god_mode: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/HBoxCheats/CheckGodMode
@onready var check_god_view: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/CheckGodView
@onready var check_corredores: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/CheckCorredores
@onready var check_cuadrantes: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/CheckCuadrantes
@onready var check_desactivar_niebla: CheckBox = get_node_or_null("ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/CheckDesactivarNiebla") as CheckBox
@onready var check_visual_debug: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Enemigo/VBox/CheckVisualDebug

# Labels - Pestaña Jugador
@onready var lbl_vel: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValVel
@onready var lbl_vel_max: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValVelMax
@onready var lbl_acel: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValAcel
@onready var lbl_fric: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValFric
@onready var lbl_estado: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValEstado
@onready var lbl_estamina: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValEstamina
@onready var lbl_pos_jugador: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValPosicion
@onready var lbl_cuadrante_jugador: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/GridTelemetria/ValCuadrante

# Labels - Pestaña Escenario
@onready var lbl_escenario_estado: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/LblEstadoEscenario
@onready var lbl_escenario_no: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/GridSectores/ValNO
@onready var lbl_escenario_ne: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/GridSectores/ValNE
@onready var lbl_escenario_so: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/GridSectores/ValSO
@onready var lbl_escenario_se: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Escenario/VBox/GridSectores/ValSE

# Labels - Pestaña Enemigo
@onready var lbl_enemigo_estado: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Enemigo/VBox/GridEnemigo/ValEstadoIA
@onready var lbl_enemigo_pos: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Enemigo/VBox/GridEnemigo/ValPosEnemigo
@onready var lbl_enemigo_dist: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Enemigo/VBox/GridEnemigo/ValDistancia
@onready var lbl_enemigo_vel: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Enemigo/VBox/GridEnemigo/ValVelEnemigo
@onready var lbl_enemigo_atascado: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Enemigo/VBox/GridEnemigo/ValAtascamiento

# Labels - Pestaña Sistema
@onready var lbl_sys_fps: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Sistema/VBox/GridSistema/ValFPS
@onready var lbl_sys_mem: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Sistema/VBox/GridSistema/ValMemoria
@onready var lbl_sys_timescale: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Sistema/VBox/GridSistema/ValTimeScale

# Visualizador de Direcciones
@onready var flecha_up: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/HBoxPad/GridPad/FlechaUp
@onready var flecha_down: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/HBoxPad/GridPad/FlechaDown
@onready var flecha_left: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/HBoxPad/GridPad/FlechaLeft
@onready var flecha_right: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/HBoxPad/GridPad/FlechaRight

# Panel Desplegable de Velocidad y Físicas
@onready var btn_desplegar_fisicas: Button = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/BtnDesplegarFisicas
@onready var panel_desplegable_fisicas: PanelContainer = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas
@onready var check_proporcional: CheckBox = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/HBoxOpciones/CheckProporcional
@onready var slider_vel_normal: HSlider = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/SliderVelNormal
@onready var val_slider_vel_normal: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/ValSliderVelNormal
@onready var slider_vel_sprint: HSlider = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/SliderVelSprint
@onready var val_slider_vel_sprint: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/ValSliderVelSprint
@onready var slider_acel: HSlider = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/SliderAcel
@onready var val_slider_acel: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/ValSliderAcel
@onready var slider_fric: HSlider = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/SliderFric
@onready var val_slider_fric: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/ValSliderFric
@onready var slider_dive_vel: HSlider = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/SliderDiveVel
@onready var val_slider_dive_vel: Label = $ControlRaiz/PanelConsola/Margin/VBox/TabContainer/Jugador/VBox/PanelDesplegableFisicas/MarginFisicas/ContenidoFisicas/GridVelocidades/ValSliderDiveVel

@onready var overlay_draw: Node2D = $DebugOverlay


func _init() -> void:
	context = DebugContext.new()
	cheats = DebugCheatsController.new()
	physics = DebugPhysicsController.new()
	scenario = DebugScenarioController.new()
	enemy_ctrl = DebugEnemyController.new()
	system_ctrl = DebugSystemController.new()
	telemetry = DebugTelemetryPresenter.new()
	monitors = DebugCustomMonitors.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not Engine.is_editor_hint():
		_restaurar_estado_desde_config()

	_actualizar_visibilidad()

	if Engine.is_editor_hint():
		return

	_buscar_nodos_objetivo()
	scenario.inicializar_camaras(context)
	scenario.aplicar_estado_niebla(context)
	monitors.registrar(context)


func _restaurar_estado_desde_config() -> void:
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg == null:
		return

	modo_actual = cfg.modo_actual as ModoVisual
	cheats.restaurar_desde_config(cfg, check_estamina_infinita, check_god_mode)
	scenario.restaurar_desde_config(cfg, check_god_view, check_corredores, check_cuadrantes, check_desactivar_niebla)
	enemy_ctrl.restaurar_desde_config(cfg, check_visual_debug)
	physics.set_proporcional(cfg.escalado_proporcional_activo, cfg)
	if check_proporcional != null:
		check_proporcional.set_pressed_no_signal(physics.escalado_proporcional_activo)
	Engine.time_scale = cfg.time_scale


func _exit_tree() -> void:
	monitors.limpiar()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			modo_actual = ((int(modo_actual) + 1) % 3) as ModoVisual
			get_viewport().set_input_as_handled()
		elif modo_actual == ModoVisual.COMPLETO and (event.keycode == KEY_ESCAPE or event.is_action_pressed("pausa") or event.is_action_pressed("ui_cancel")):
			modo_actual = ModoVisual.OCULTO
			get_viewport().set_input_as_handled()


func _actualizar_visibilidad() -> void:
	var hay_overlays_activos: bool = scenario.debug_dibujar_cuadrantes or scenario.debug_dibujar_corredores
	visible = (modo_actual != ModoVisual.OCULTO) or hay_overlays_activos

	if mini_hud != null:
		mini_hud.visible = (modo_actual == ModoVisual.MINI_HUD)
	if panel_consola != null:
		panel_consola.visible = (modo_actual == ModoVisual.COMPLETO)
	if overlay_draw != null:
		overlay_draw.queue_redraw()
	if context != null and context.target_enemigo != null and is_instance_valid(context.target_enemigo):
		context.target_enemigo.set("debug_dibujar_rayo", enemy_ctrl.debug_dibujar_vectores_ia)
		context.target_enemigo.queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_buscar_nodos_objetivo()
	enemy_ctrl.sincronizar_en_process(context.target_enemigo)
	cheats.aplicar_en_process(context.target_character)

	if (scenario.debug_dibujar_cuadrantes or scenario.debug_dibujar_corredores) and overlay_draw != null:
		overlay_draw.queue_redraw()

	if modo_actual == ModoVisual.OCULTO:
		return

	_actualizar_telemetria()


func _buscar_nodos_objetivo() -> void:
	var escena_actual: Node = get_tree().current_scene
	context.buscar_nodos(escena_actual, scenario.god_view_activo)
	physics.inicializar_valores(context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())


func _actualizar_telemetria() -> void:
	var fps: int = int(Engine.get_frames_per_second())
	var mem_mb: float = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)

	var pos_jugador: Vector2 = Vector2.ZERO
	var cuadrante_jugador: String = "N/A"
	var vel_actual: float = 0.0
	var vel_max: float = 0.0
	var acel: float = 0.0
	var fric: float = 0.0
	var estamina_txt: String = "N/A"
	var estado_txt: String = "REPOSO"

	if context.target_character != null:
		pos_jugador = context.target_character.global_position
		cuadrante_jugador = context.calcular_cuadrante(pos_jugador)
		var vel_vec: Vector2 = context.target_character.velocity
		vel_actual = vel_vec.length()
		vel_max = context.target_character.get("speed") if "speed" in context.target_character else 0.0
		acel = context.target_character.get("acceleration") if "acceleration" in context.target_character else 0.0
		fric = context.target_character.get("friction") if "friction" in context.target_character else 0.0

		if context.target_character.has_method("obtener_nombre_estado"):
			estado_txt = context.target_character.obtener_nombre_estado()
		elif "estado_actual" in context.target_character:
			estado_txt = str(context.target_character.get("estado_actual"))

		if "stamina" in context.target_character:
			var max_st: float = float(context.target_character.get("max_stamina")) if "max_stamina" in context.target_character else 100.0
			estamina_txt = "%.1f / %.1f" % [float(context.target_character.get("stamina")), max_st]
		elif "estamina" in context.target_character:
			estamina_txt = "%.1f / 100.0" % float(context.target_character.get("estamina"))
		elif "estamina_actual" in context.target_character:
			estamina_txt = "%.1f / 100.0" % float(context.target_character.get("estamina_actual"))

		cheats.aplicar_en_process(context.target_character)

		var dir_input: Vector2 = Input.get_vector("personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo")
		if dir_input == Vector2.ZERO:
			dir_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		telemetry.actualizar_pad_direccional(_obtener_ui_flechas(), dir_input)

	if mini_hud != null and mini_hud.visible:
		telemetry.actualizar_mini_hud({
			"label_mini_fps": label_mini_fps,
			"label_mini_cuadrante": label_mini_cuadrante,
			"label_mini_vel": label_mini_vel,
			"label_mini_estamina": label_mini_estamina
		}, fps, mem_mb, cuadrante_jugador, vel_actual, estamina_txt)

	if panel_consola != null and panel_consola.visible:
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

		telemetry.actualizar_tab_escenario({
			"lbl_escenario_estado": lbl_escenario_estado,
			"lbl_escenario_no": lbl_escenario_no,
			"lbl_escenario_ne": lbl_escenario_ne,
			"lbl_escenario_so": lbl_escenario_so,
			"lbl_escenario_se": lbl_escenario_se
		}, context.target_escenario, cuadrante_jugador)

		telemetry.actualizar_tab_enemigo({
			"lbl_enemigo_estado": lbl_enemigo_estado,
			"lbl_enemigo_pos": lbl_enemigo_pos,
			"lbl_enemigo_dist": lbl_enemigo_dist,
			"lbl_enemigo_vel": lbl_enemigo_vel,
			"lbl_enemigo_atascado": lbl_enemigo_atascado
		}, context.target_enemigo, pos_jugador, context, enemy_ctrl.debug_dibujar_vectores_ia)

		if check_pausar != null:
			check_pausar.set_pressed_no_signal(get_tree().paused)

		telemetry.actualizar_tab_sistema({
			"lbl_sys_fps": lbl_sys_fps,
			"lbl_sys_mem": lbl_sys_mem,
			"lbl_sys_timescale": lbl_sys_timescale
		}, fps, mem_mb)

	if overlay_draw != null:
		overlay_draw.queue_redraw()


func _obtener_ui_fisicas() -> Dictionary:
	return {
		"check_proporcional": check_proporcional,
		"slider_vel_normal": slider_vel_normal,
		"val_slider_vel_normal": val_slider_vel_normal,
		"slider_vel_sprint": slider_vel_sprint,
		"val_slider_vel_sprint": val_slider_vel_sprint,
		"slider_acel": slider_acel,
		"val_slider_acel": val_slider_acel,
		"slider_fric": slider_fric,
		"val_slider_fric": val_slider_fric,
		"slider_dive_vel": slider_dive_vel,
		"val_slider_dive_vel": val_slider_dive_vel
	}


func _obtener_ui_flechas() -> Dictionary:
	return {
		"flecha_up": flecha_up,
		"flecha_down": flecha_down,
		"flecha_left": flecha_left,
		"flecha_right": flecha_right
	}


# --- Delegación de Señales de la UI ---

func _on_boton_cerrar_pressed() -> void:
	modo_actual = ModoVisual.OCULTO

func _on_boton_mini_expandir_pressed() -> void:
	modo_actual = ModoVisual.COMPLETO

func _on_check_pausar_toggled(toggled_on: bool) -> void:
	system_ctrl.toggle_pausa(get_tree(), toggled_on)

func _on_check_estamina_infinita_toggled(toggled_on: bool) -> void:
	cheats.set_estamina_infinita(toggled_on, context.target_character, get_node_or_null("/root/DebugConfig"))

func _on_check_god_mode_toggled(toggled_on: bool) -> void:
	cheats.set_god_mode(toggled_on, context.target_character, get_node_or_null("/root/DebugConfig"))

func _on_btn_desplegar_fisicas_pressed() -> void:
	physics.toggle_desplegar(btn_desplegar_fisicas, panel_desplegable_fisicas)

func _on_check_proporcional_toggled(toggled_on: bool) -> void:
	physics.set_proporcional(toggled_on, get_node_or_null("/root/DebugConfig"))

func _on_slider_vel_normal_value_changed(value: float) -> void:
	physics.on_vel_normal_changed(value, context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())

func _on_slider_vel_sprint_value_changed(value: float) -> void:
	physics.on_vel_sprint_changed(value, context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())

func _on_slider_acel_value_changed(value: float) -> void:
	physics.on_acel_changed(value, context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())

func _on_slider_fric_value_changed(value: float) -> void:
	physics.on_fric_changed(value, context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())

func _on_slider_dive_vel_value_changed(value: float) -> void:
	physics.on_dive_vel_changed(value, context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())

func _on_btn_reset_velocidades_pressed() -> void:
	physics.reset_velocidades(context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())

func _on_check_god_view_toggled(toggled_on: bool) -> void:
	scenario.set_god_view(toggled_on, context, get_node_or_null("/root/DebugConfig"))

func _on_btn_forzar_mutacion_pressed() -> void:
	scenario.forzar_mutacion(context.target_escenario)

func _on_check_corredores_toggled(toggled_on: bool) -> void:
	scenario.set_dibujar_corredores(toggled_on, get_node_or_null("/root/DebugConfig"))
	_actualizar_visibilidad()

func _on_check_cuadrantes_toggled(toggled_on: bool) -> void:
	scenario.set_dibujar_cuadrantes(toggled_on, get_node_or_null("/root/DebugConfig"))
	_actualizar_visibilidad()

func _on_check_desactivar_niebla_toggled(toggled_on: bool) -> void:
	scenario.set_desactivar_niebla(toggled_on, context, get_node_or_null("/root/DebugConfig"))

func _on_check_visual_debug_enemigo_toggled(toggled_on: bool) -> void:
	enemy_ctrl.set_visual_debug(toggled_on, context.target_enemigo, get_node_or_null("/root/DebugConfig"))

func _on_btn_reubicar_enemigo_pressed() -> void:
	enemy_ctrl.reubicar_enemigo(context.target_enemigo, context.target_character)

func _on_btn_timescale_05_pressed() -> void:
	system_ctrl.set_time_scale(0.5, get_node_or_null("/root/DebugConfig"))

func _on_btn_timescale_10_pressed() -> void:
	system_ctrl.set_time_scale(1.0, get_node_or_null("/root/DebugConfig"))

func _on_btn_timescale_20_pressed() -> void:
	system_ctrl.set_time_scale(2.0, get_node_or_null("/root/DebugConfig"))

func _on_btn_reiniciar_escena_pressed() -> void:
	system_ctrl.reiniciar_escena(get_tree())
