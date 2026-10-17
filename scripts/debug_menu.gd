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
@export var target_character: CharacterBody2D
@export var target_enemigo: CharacterBody2D
@export var target_camara: Camera2D
@export var target_camara_dios: Camera2D
@export var target_escenario: Node2D

# Variables internas de Cheats y Diagnóstico
var cheat_estamina_infinita: bool = false
var cheat_god_mode: bool = false
var god_view_activo: bool = false
var camara_zoom_original: Vector2 = Vector2.ONE
var camara_offset_original: Vector2 = Vector2.ZERO

# Dibujo de overlay
var debug_dibujar_cuadrantes: bool = false
var debug_dibujar_corredores: bool = false
var debug_dibujar_vectores_ia: bool = false

# Monitores personalizados en Depurador de Godot
var _monitores_registrados: Array[StringName] = []

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

var _fisicas_desplegadas: bool = false
var _vel_normal_defecto: float = 800.0
var _vel_sprint_defecto: float = 1000.0
var _acel_defecto: float = 5000.0
var _fric_defecto: float = 5000.0
var _dive_vel_defecto: float = 1200.0

var _escalado_proporcional_activo: bool = true
var _actualizando_sliders_en_cadena: bool = false
var _valores_defecto_inicializados: bool = false

@onready var overlay_draw: Node2D = $DebugOverlay

const COLOR_INACTIVO := Color(0.30, 0.34, 0.42, 0.7)
const COLOR_ACTIVO := Color(0.39, 0.71, 0.96, 1.0)
const COLOR_VERDE := Color(0.40, 0.85, 0.45, 1.0)
const COLOR_ROJO := Color(0.95, 0.35, 0.35, 1.0)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not Engine.is_editor_hint():
		_restaurar_estado_desde_config()

	_actualizar_visibilidad()

	if Engine.is_editor_hint():
		return

	_buscar_nodos_objetivo()
	_inicializar_camaras()
	_registrar_monitores_personalizados()


func _restaurar_estado_desde_config() -> void:
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg == null:
		return

	modo_actual = cfg.modo_actual as ModoVisual
	cheat_estamina_infinita = cfg.cheat_estamina_infinita
	cheat_god_mode = cfg.cheat_god_mode
	debug_dibujar_cuadrantes = cfg.debug_dibujar_cuadrantes
	debug_dibujar_corredores = cfg.debug_dibujar_corredores
	debug_dibujar_vectores_ia = cfg.debug_dibujar_vectores_ia
	god_view_activo = cfg.god_view_activo
	_escalado_proporcional_activo = cfg.escalado_proporcional_activo
	Engine.time_scale = cfg.time_scale

	if check_estamina_infinita != null:
		check_estamina_infinita.set_pressed_no_signal(cheat_estamina_infinita)
	if check_god_mode != null:
		check_god_mode.set_pressed_no_signal(cheat_god_mode)
	if check_god_view != null:
		check_god_view.set_pressed_no_signal(god_view_activo)
	if check_corredores != null:
		check_corredores.set_pressed_no_signal(debug_dibujar_corredores)
	if check_cuadrantes != null:
		check_cuadrantes.set_pressed_no_signal(debug_dibujar_cuadrantes)
	if check_visual_debug != null:
		check_visual_debug.set_pressed_no_signal(debug_dibujar_vectores_ia)
	if check_proporcional != null:
		check_proporcional.set_pressed_no_signal(_escalado_proporcional_activo)


func _exit_tree() -> void:
	_limpiar_monitores_personalizados()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			# Ciclo tri-estado: OCULTO -> MINI_HUD -> COMPLETO -> OCULTO
			modo_actual = ((int(modo_actual) + 1) % 3) as ModoVisual
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and modo_actual == ModoVisual.COMPLETO:
			modo_actual = ModoVisual.OCULTO
			get_viewport().set_input_as_handled()


func _actualizar_visibilidad() -> void:
	# CanvasLayer debe estar visible si el menú está activo O si hay overlays visuales activados
	var hay_overlays_activos: bool = debug_dibujar_cuadrantes or debug_dibujar_corredores
	visible = (modo_actual != ModoVisual.OCULTO) or hay_overlays_activos

	if mini_hud != null:
		mini_hud.visible = (modo_actual == ModoVisual.MINI_HUD)
	if panel_consola != null:
		panel_consola.visible = (modo_actual == ModoVisual.COMPLETO)
	if overlay_draw != null:
		overlay_draw.queue_redraw()
	if target_enemigo != null and is_instance_valid(target_enemigo):
		target_enemigo.set("debug_dibujar_rayo", debug_dibujar_vectores_ia)
		target_enemigo.queue_redraw()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	_buscar_nodos_objetivo()

	# Mantener sincronizado el estado del rayo con el enemigo independientemente de si el menú está cerrado
	if target_enemigo != null and is_instance_valid(target_enemigo):
		if target_enemigo.get("debug_dibujar_rayo") != debug_dibujar_vectores_ia:
			target_enemigo.set("debug_dibujar_rayo", debug_dibujar_vectores_ia)

	# Mantener cheats activos sobre el personaje independientemente de si el menú está cerrado
	if target_character != null and is_instance_valid(target_character):
		if "sin_gasto_estamina" in target_character:
			target_character.set("sin_gasto_estamina", cheat_estamina_infinita)
		elif cheat_estamina_infinita:
			if "stamina" in target_character:
				target_character.set("stamina", float(target_character.get("max_stamina")) if "max_stamina" in target_character else 100.0)
				if "fatigado" in target_character:
					target_character.set("fatigado", false)

		if "god_mode" in target_character:
			target_character.set("god_mode", cheat_god_mode)

	# Si hay overlays dibujándose en DebugOverlay, redibujar periódicamente si es necesario
	if (debug_dibujar_cuadrantes or debug_dibujar_corredores) and overlay_draw != null:
		overlay_draw.queue_redraw()

	if modo_actual == ModoVisual.OCULTO:
		return

	_actualizar_telemetria()


func _buscar_nodos_objetivo() -> void:
	var escena_actual: Node = get_tree().current_scene
	if escena_actual == null:
		return

	if target_character == null:
		target_character = _buscar_nodo_por_tipo(escena_actual, "CharacterBody2D", ["personaje", "jugador", "player"])

	if target_enemigo == null:
		target_enemigo = _buscar_nodo_por_tipo(escena_actual, "CharacterBody2D", ["enemigo", "monstruo", "enemy"])

	if target_camara == null:
		if target_character != null:
			target_camara = target_character.get_node_or_null("Camera2D") as Camera2D
		if target_camara == null:
			var encontrada := escena_actual.find_child("CamaraJugador", true, false) as Camera2D
			if encontrada != null:
				target_camara = encontrada
			else:
				var candidate := escena_actual.find_child("Camera2D", true, false) as Camera2D
				if candidate != null and candidate != target_camara_dios and candidate.name != "CamaraDios":
					target_camara = candidate
		if target_camara != null and not god_view_activo:
			camara_zoom_original = target_camara.zoom
			camara_offset_original = target_camara.offset

	if target_camara_dios == null:
		target_camara_dios = escena_actual.find_child("CamaraDios", true, false) as Camera2D
		if target_camara_dios == null:
			target_camara_dios = escena_actual.find_child("CamaraGlobal", true, false) as Camera2D

	if target_escenario == null:
		target_escenario = escena_actual.find_child("Escenario", true, false) as Node2D

	_inicializar_sliders_velocidad()


func _inicializar_sliders_velocidad() -> void:
	if target_character == null or _valores_defecto_inicializados:
		return
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null and cfg.fisicas_personalizadas:
		if "speed" in target_character:
			target_character.set("speed", cfg.vel_normal)
		if "sprint_speed" in target_character:
			target_character.set("sprint_speed", cfg.vel_sprint)
		if "acceleration" in target_character:
			target_character.set("acceleration", cfg.acel)
		if "friction" in target_character:
			target_character.set("friction", cfg.fric)
		if "dive_speed" in target_character:
			target_character.set("dive_speed", cfg.dive_vel)

		if slider_vel_normal != null:
			slider_vel_normal.set_value_no_signal(cfg.vel_normal)
		if val_slider_vel_normal != null:
			val_slider_vel_normal.text = "%.0f px/s" % cfg.vel_normal

		if slider_vel_sprint != null:
			slider_vel_sprint.set_value_no_signal(cfg.vel_sprint)
		if val_slider_vel_sprint != null:
			val_slider_vel_sprint.text = "%.0f px/s" % cfg.vel_sprint

		if slider_acel != null:
			slider_acel.set_value_no_signal(cfg.acel)
		if val_slider_acel != null:
			val_slider_acel.text = "%.0f px/s²" % cfg.acel

		if slider_fric != null:
			slider_fric.set_value_no_signal(cfg.fric)
		if val_slider_fric != null:
			val_slider_fric.text = "%.0f px/s²" % cfg.fric

		if slider_dive_vel != null:
			slider_dive_vel.set_value_no_signal(cfg.dive_vel)
		if val_slider_dive_vel != null:
			val_slider_dive_vel.text = "%.0f px/s" % cfg.dive_vel
	else:
		if "speed" in target_character:
			_vel_normal_defecto = float(target_character.get("speed"))
			if slider_vel_normal != null:
				slider_vel_normal.set_value_no_signal(_vel_normal_defecto)
			if val_slider_vel_normal != null:
				val_slider_vel_normal.text = "%.0f px/s" % _vel_normal_defecto

		if "sprint_speed" in target_character:
			_vel_sprint_defecto = float(target_character.get("sprint_speed"))
			if slider_vel_sprint != null:
				slider_vel_sprint.set_value_no_signal(_vel_sprint_defecto)
			if val_slider_vel_sprint != null:
				val_slider_vel_sprint.text = "%.0f px/s" % _vel_sprint_defecto

		if "acceleration" in target_character:
			_acel_defecto = float(target_character.get("acceleration"))
			if slider_acel != null:
				slider_acel.set_value_no_signal(_acel_defecto)
			if val_slider_acel != null:
				val_slider_acel.text = "%.0f px/s²" % _acel_defecto

		if "friction" in target_character:
			_fric_defecto = float(target_character.get("friction"))
			if slider_fric != null:
				slider_fric.set_value_no_signal(_fric_defecto)
			if val_slider_fric != null:
				val_slider_fric.text = "%.0f px/s²" % _fric_defecto

		if "dive_speed" in target_character:
			_dive_vel_defecto = float(target_character.get("dive_speed"))
			if slider_dive_vel != null:
				slider_dive_vel.set_value_no_signal(_dive_vel_defecto)
			if val_slider_dive_vel != null:
				val_slider_dive_vel.text = "%.0f px/s" % _dive_vel_defecto

	if check_proporcional != null:
		check_proporcional.button_pressed = _escalado_proporcional_activo

	_valores_defecto_inicializados = true


func _inicializar_camaras() -> void:
	if god_view_activo:
		if target_camara_dios != null:
			target_camara_dios.enabled = true
			target_camara_dios.make_current()
			if target_camara != null:
				target_camara.enabled = false
		elif target_camara != null:
			target_camara.zoom = Vector2(0.45, 0.45)
			target_camara.position_smoothing_enabled = false
			target_camara.global_position = Vector2.ZERO
	else:
		if target_camara_dios != null:
			target_camara_dios.enabled = false
		if target_camara != null:
			target_camara.enabled = true
			target_camara.make_current()


func _buscar_nodo_por_tipo(nodo_raiz: Node, tipo: String, nombres_clave: Array[String]) -> CharacterBody2D:
	for nombre in nombres_clave:
		var encontrado: Node = nodo_raiz.find_child(nombre, true, false)
		if encontrado != null and encontrado.is_class(tipo):
			return encontrado as CharacterBody2D

	for child in nodo_raiz.get_children():
		if child.is_class(tipo):
			for nombre in nombres_clave:
				if nombre in child.name.to_lower():
					return child as CharacterBody2D
	return null


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

	if target_character != null:
		pos_jugador = target_character.global_position
		cuadrante_jugador = _calcular_cuadrante(pos_jugador)
		var vel_vec: Vector2 = target_character.velocity
		vel_actual = vel_vec.length()
		vel_max = target_character.get("speed") if "speed" in target_character else 0.0
		acel = target_character.get("acceleration") if "acceleration" in target_character else 0.0
		fric = target_character.get("friction") if "friction" in target_character else 0.0

		if target_character.has_method("obtener_nombre_estado"):
			estado_txt = target_character.obtener_nombre_estado()
		elif "estado_actual" in target_character:
			estado_txt = str(target_character.get("estado_actual"))

		if "stamina" in target_character:
			var max_st: float = float(target_character.get("max_stamina")) if "max_stamina" in target_character else 100.0
			estamina_txt = "%.1f / %.1f" % [float(target_character.get("stamina")), max_st]
		elif "estamina" in target_character:
			estamina_txt = "%.1f / 100.0" % float(target_character.get("estamina"))
		elif "estamina_actual" in target_character:
			estamina_txt = "%.1f / 100.0" % float(target_character.get("estamina_actual"))

		# Aplicar cheats si están activos
		if "sin_gasto_estamina" in target_character:
			target_character.set("sin_gasto_estamina", cheat_estamina_infinita)
		elif cheat_estamina_infinita:
			if "stamina" in target_character:
				target_character.set("stamina", float(target_character.get("max_stamina")) if "max_stamina" in target_character else 100.0)
				if "fatigado" in target_character:
					target_character.set("fatigado", false)

		if "god_mode" in target_character:
			target_character.set("god_mode", cheat_god_mode)

		# Actualizar Pad Direccional
		var dir_input: Vector2 = Input.get_vector("personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo")
		if dir_input == Vector2.ZERO:
			dir_input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		_actualizar_flechas_pad(dir_input)

	# 1. Actualizar Mini-HUD
	if mini_hud != null and mini_hud.visible:
		label_mini_fps.text = "FPS: %d (%0.1f MB)" % [fps, mem_mb]
		label_mini_cuadrante.text = "Sector: %s" % cuadrante_jugador
		label_mini_vel.text = "Vel: %.1f px/s" % vel_actual
		label_mini_estamina.text = "Estamina: %s" % estamina_txt

	# 2. Actualizar Menú Completo
	if panel_consola != null and panel_consola.visible:
		# Pestaña Jugador
		lbl_vel.text = "%.1f px/s (X: %.1f, Y: %.1f)" % [vel_actual, target_character.velocity.x if target_character else 0.0, target_character.velocity.y if target_character else 0.0]
		lbl_vel_max.text = "%.1f px/s" % vel_max
		lbl_acel.text = "%.1f px/s²" % acel
		lbl_fric.text = "%.1f px/s²" % fric
		lbl_estado.text = estado_txt
		lbl_estamina.text = estamina_txt
		lbl_pos_jugador.text = "(%.1f, %.1f)" % [pos_jugador.x, pos_jugador.y]
		lbl_cuadrante_jugador.text = "%s (Centro: %s)" % [cuadrante_jugador, _obtener_centro_cuadrante(cuadrante_jugador)]

		# Pestaña Escenario
		if target_escenario != null:
			lbl_escenario_estado.text = "Escenario Activo: Cuadrante Jugador = %s" % cuadrante_jugador
			if "variantes_activas" in target_escenario:
				var vars: Dictionary = target_escenario.get("variantes_activas")
				lbl_escenario_no.text = str(vars.get("NO", "Default"))
				lbl_escenario_ne.text = str(vars.get("NE", "Default"))
				lbl_escenario_so.text = str(vars.get("SO", "Default"))
				lbl_escenario_se.text = str(vars.get("SE", "Default"))
		else:
			lbl_escenario_estado.text = "Escenario: No instanciado (Modo Standalone)"
			lbl_escenario_no.text = "Sector NO [-1080..0, -1080..0]"
			lbl_escenario_ne.text = "Sector NE [0..1080, -1080..0]"
			lbl_escenario_so.text = "Sector SO [-1080..0, 0..1080]"
			lbl_escenario_se.text = "Sector SE [0..1080, 0..1080]"

		# Pestaña Enemigo
		if target_enemigo != null and is_instance_valid(target_enemigo):
			target_enemigo.set("debug_dibujar_rayo", debug_dibujar_vectores_ia)
			var pos_enemigo: Vector2 = target_enemigo.global_position
			var dist: float = pos_jugador.distance_to(pos_enemigo)
			var vel_enemigo: float = target_enemigo.velocity.length()
			lbl_enemigo_pos.text = "(%.1f, %.1f) [%s]" % [pos_enemigo.x, pos_enemigo.y, _calcular_cuadrante(pos_enemigo)]
			lbl_enemigo_dist.text = "%.1f px" % dist
			lbl_enemigo_vel.text = "%.1f px/s" % vel_enemigo

			var vision_txt := ""
			if "tiene_linea_vision" in target_enemigo:
				vision_txt = " (Visión directa)" if target_enemigo.get("tiene_linea_vision") else " (Obstruido)"

			lbl_enemigo_estado.text = ("Persiguiendo objetivo" + vision_txt) if target_enemigo.get("objetivo") != null else "Sin objetivo"
			lbl_enemigo_atascado.text = "Colisión activa" if target_enemigo.is_on_wall() else "Libre / Transitable"
		else:
			lbl_enemigo_estado.text = "No encontrado en escena"
			lbl_enemigo_pos.text = "N/A"
			lbl_enemigo_dist.text = "N/A"
			lbl_enemigo_vel.text = "N/A"
			lbl_enemigo_atascado.text = "N/A"

		# Pestaña Sistema
		lbl_sys_fps.text = "%d FPS" % fps
		lbl_sys_mem.text = "%.2f MB" % mem_mb
		lbl_sys_timescale.text = "%.2fx" % Engine.time_scale

	if overlay_draw != null:
		overlay_draw.queue_redraw()


func _calcular_cuadrante(pos: Vector2) -> String:
	var x_str: String = "E" if pos.x >= 0.0 else "O"
	var y_str: String = "S" if pos.y >= 0.0 else "N"
	return y_str + x_str


func _obtener_centro_cuadrante(cuad: String) -> String:
	match cuad:
		"NO": return "(-540, -540)"
		"NE": return "(540, -540)"
		"SO": return "(-540, 540)"
		"SE": return "(540, 540)"
		_: return "(0, 0)"


func _actualizar_flechas_pad(dir: Vector2) -> void:
	if flecha_up == null:
		return
	flecha_up.modulate = COLOR_ACTIVO if dir.y < -0.2 else COLOR_INACTIVO
	flecha_down.modulate = COLOR_ACTIVO if dir.y > 0.2 else COLOR_INACTIVO
	flecha_left.modulate = COLOR_ACTIVO if dir.x < -0.2 else COLOR_INACTIVO
	flecha_right.modulate = COLOR_ACTIVO if dir.x > 0.2 else COLOR_INACTIVO


# --- Métodos de Botones y Señales de la UI ---

func _on_boton_cerrar_pressed() -> void:
	modo_actual = ModoVisual.OCULTO


func _on_boton_mini_expandir_pressed() -> void:
	modo_actual = ModoVisual.COMPLETO


func _on_check_pausar_toggled(toggled_on: bool) -> void:
	get_tree().paused = toggled_on


func _on_check_estamina_infinita_toggled(toggled_on: bool) -> void:
	cheat_estamina_infinita = toggled_on
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.cheat_estamina_infinita = toggled_on
	if target_character != null and "sin_gasto_estamina" in target_character:
		target_character.set("sin_gasto_estamina", toggled_on)


func _on_check_god_mode_toggled(toggled_on: bool) -> void:
	cheat_god_mode = toggled_on
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.cheat_god_mode = toggled_on
	if target_character != null:
		if "god_mode" in target_character:
			target_character.set("god_mode", toggled_on)
		target_character.set_collision_mask_value(4, not toggled_on)


func _on_btn_desplegar_fisicas_pressed() -> void:
	_fisicas_desplegadas = not _fisicas_desplegadas
	if panel_desplegable_fisicas != null:
		panel_desplegable_fisicas.visible = _fisicas_desplegadas
	if btn_desplegar_fisicas != null:
		btn_desplegar_fisicas.text = "▼ Ajustes de Velocidad y Físicas (Ocultar)" if _fisicas_desplegadas else "▶ Ajustes de Velocidad y Físicas (Desplegar)"


func _on_check_proporcional_toggled(toggled_on: bool) -> void:
	_escalado_proporcional_activo = toggled_on
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.escalado_proporcional_activo = toggled_on


func _guardar_fisicas_en_config() -> void:
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.fisicas_personalizadas = true
		cfg.vel_normal = slider_vel_normal.value if slider_vel_normal != null else _vel_normal_defecto
		cfg.vel_sprint = slider_vel_sprint.value if slider_vel_sprint != null else _vel_sprint_defecto
		cfg.acel = slider_acel.value if slider_acel != null else _acel_defecto
		cfg.fric = slider_fric.value if slider_fric != null else _fric_defecto
		cfg.dive_vel = slider_dive_vel.value if slider_dive_vel != null else _dive_vel_defecto


func _on_slider_vel_normal_value_changed(value: float) -> void:
	if val_slider_vel_normal != null:
		val_slider_vel_normal.text = "%.0f px/s" % value
	if target_character != null and "speed" in target_character:
		target_character.set("speed", value)

	if _escalado_proporcional_activo and not _actualizando_sliders_en_cadena and _vel_normal_defecto > 0.0:
		_actualizando_sliders_en_cadena = true
		var ratio: float = value / _vel_normal_defecto

		# Escalar sprint proporcionalmente
		var nuevo_sprint: float = clampf(_vel_sprint_defecto * ratio, 50.0, 4000.0)
		if slider_vel_sprint != null:
			slider_vel_sprint.value = nuevo_sprint
		elif target_character != null and "sprint_speed" in target_character:
			target_character.set("sprint_speed", nuevo_sprint)

		# Escalar aceleración proporcionalmente
		var nueva_acel: float = clampf(_acel_defecto * ratio, 100.0, 20000.0)
		if slider_acel != null:
			slider_acel.value = nueva_acel
		elif target_character != null and "acceleration" in target_character:
			target_character.set("acceleration", nueva_acel)

		# Escalar fricción proporcionalmente
		var nueva_fric: float = clampf(_fric_defecto * ratio, 100.0, 20000.0)
		if slider_fric != null:
			slider_fric.value = nueva_fric
		elif target_character != null and "friction" in target_character:
			target_character.set("friction", nueva_fric)

		# Escalar dive speed proporcionalmente
		var nuevo_dive: float = clampf(_dive_vel_defecto * ratio, 100.0, 4000.0)
		if slider_dive_vel != null:
			slider_dive_vel.value = nuevo_dive
		elif target_character != null and "dive_speed" in target_character:
			target_character.set("dive_speed", nuevo_dive)

		_actualizando_sliders_en_cadena = false

	if not _actualizando_sliders_en_cadena:
		_guardar_fisicas_en_config()


func _on_slider_vel_sprint_value_changed(value: float) -> void:
	if val_slider_vel_sprint != null:
		val_slider_vel_sprint.text = "%.0f px/s" % value
	if target_character != null and "sprint_speed" in target_character:
		target_character.set("sprint_speed", value)
	if not _actualizando_sliders_en_cadena:
		_guardar_fisicas_en_config()


func _on_slider_acel_value_changed(value: float) -> void:
	if val_slider_acel != null:
		val_slider_acel.text = "%.0f px/s²" % value
	if target_character != null and "acceleration" in target_character:
		target_character.set("acceleration", value)
	if not _actualizando_sliders_en_cadena:
		_guardar_fisicas_en_config()


func _on_slider_fric_value_changed(value: float) -> void:
	if val_slider_fric != null:
		val_slider_fric.text = "%.0f px/s²" % value
	if target_character != null and "friction" in target_character:
		target_character.set("friction", value)
	if not _actualizando_sliders_en_cadena:
		_guardar_fisicas_en_config()


func _on_slider_dive_vel_value_changed(value: float) -> void:
	if val_slider_dive_vel != null:
		val_slider_dive_vel.text = "%.0f px/s" % value
	if target_character != null and "dive_speed" in target_character:
		target_character.set("dive_speed", value)
	if not _actualizando_sliders_en_cadena:
		_guardar_fisicas_en_config()


func _on_btn_reset_velocidades_pressed() -> void:
	_actualizando_sliders_en_cadena = true
	if slider_vel_normal != null:
		slider_vel_normal.value = _vel_normal_defecto
	if slider_vel_sprint != null:
		slider_vel_sprint.value = _vel_sprint_defecto
	if slider_acel != null:
		slider_acel.value = _acel_defecto
	if slider_fric != null:
		slider_fric.value = _fric_defecto
	if slider_dive_vel != null:
		slider_dive_vel.value = _dive_vel_defecto

	if target_character != null:
		if "speed" in target_character: target_character.set("speed", _vel_normal_defecto)
		if "sprint_speed" in target_character: target_character.set("sprint_speed", _vel_sprint_defecto)
		if "acceleration" in target_character: target_character.set("acceleration", _acel_defecto)
		if "friction" in target_character: target_character.set("friction", _fric_defecto)
		if "dive_speed" in target_character: target_character.set("dive_speed", _dive_vel_defecto)

	_actualizando_sliders_en_cadena = false

	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.resetear_velocidades(_vel_normal_defecto, _vel_sprint_defecto, _acel_defecto, _fric_defecto, _dive_vel_defecto)


func _on_check_god_view_toggled(toggled_on: bool) -> void:
	god_view_activo = toggled_on
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.god_view_activo = toggled_on

	# Prioridad 1: Configuración de dos cámaras dedicadas
	if target_camara_dios != null:
		if toggled_on:
			target_camara_dios.enabled = true
			target_camara_dios.make_current()
			if target_camara != null:
				target_camara.enabled = false
		else:
			if target_camara != null:
				target_camara.enabled = true
				target_camara.make_current()
				target_camara.reset_smoothing()
			target_camara_dios.enabled = false
		return

	# Prioridad 2: Fallback mono-cámara seguro
	if target_camara == null:
		return

	if toggled_on:
		target_camara.zoom = Vector2(0.45, 0.45)
		target_camara.position_smoothing_enabled = false
		target_camara.global_position = Vector2.ZERO
	else:
		target_camara.zoom = camara_zoom_original
		target_camara.position_smoothing_enabled = true
		if target_character != null:
			target_camara.global_position = target_character.global_position
		target_camara.reset_smoothing()


func _on_btn_forzar_mutacion_pressed() -> void:
	if target_escenario != null and target_escenario.has_method("mutar_sectores_lejanos"):
		target_escenario.call("mutar_sectores_lejanos")
	elif target_escenario != null and target_escenario.has_method("forzar_mutacion"):
		target_escenario.call("forzar_mutacion")
	else:
		print("[DebugMenu] Forzar mutación invocado (Escenario aún no conectado o método ausente)")


func _on_check_corredores_toggled(toggled_on: bool) -> void:
	debug_dibujar_corredores = toggled_on
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.debug_dibujar_corredores = toggled_on
	_actualizar_visibilidad()


func _on_check_cuadrantes_toggled(toggled_on: bool) -> void:
	debug_dibujar_cuadrantes = toggled_on
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.debug_dibujar_cuadrantes = toggled_on
	_actualizar_visibilidad()


func _on_check_visual_debug_enemigo_toggled(toggled_on: bool) -> void:
	debug_dibujar_vectores_ia = toggled_on
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.debug_dibujar_vectores_ia = toggled_on
	if target_enemigo != null and is_instance_valid(target_enemigo):
		target_enemigo.set("debug_dibujar_rayo", toggled_on)
		target_enemigo.queue_redraw()


func _on_btn_reubicar_enemigo_pressed() -> void:
	if target_enemigo == null or target_character == null:
		return
	# Reubicar al cuadrante opuesto
	var pos_p: Vector2 = target_character.global_position
	var nueva_pos: Vector2 = Vector2(-pos_p.x, -pos_p.y)
	if nueva_pos.length() < 300.0:
		nueva_pos = Vector2(600.0, 600.0)
	target_enemigo.global_position = nueva_pos


func _on_btn_timescale_05_pressed() -> void:
	Engine.time_scale = 0.5
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.time_scale = 0.5


func _on_btn_timescale_10_pressed() -> void:
	Engine.time_scale = 1.0
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.time_scale = 1.0


func _on_btn_timescale_20_pressed() -> void:
	Engine.time_scale = 2.0
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg != null:
		cfg.time_scale = 2.0


func _on_btn_reiniciar_escena_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# --- Monitores Personalizados para el Depurador de Godot (Performance) ---

func _registrar_monitores_personalizados() -> void:
	if not OS.is_debug_build() or Engine.is_editor_hint():
		return

	_limpiar_monitores_personalizados()

	_agregar_monitor("Vosque/Estamina Jugador", _monitor_estamina_jugador)
	_agregar_monitor("Vosque/Velocidad Jugador", _monitor_velocidad_jugador)
	_agregar_monitor("Vosque/Velocidad Enemigo", _monitor_velocidad_enemigo)
	_agregar_monitor("Vosque/Distancia Monstruo", _monitor_distancia_monstruo)
	_agregar_monitor("Vosque/Estado Jugador", _monitor_estado_jugador)


func _agregar_monitor(nombre: StringName, callable: Callable) -> void:
	if not Performance.has_custom_monitor(nombre):
		Performance.add_custom_monitor(nombre, callable)
		_monitores_registrados.append(nombre)


func _limpiar_monitores_personalizados() -> void:
	for id in _monitores_registrados:
		if Performance.has_custom_monitor(id):
			Performance.remove_custom_monitor(id)
	_monitores_registrados.clear()


func _monitor_estamina_jugador() -> float:
	if target_character != null and is_instance_valid(target_character):
		if "stamina" in target_character:
			return float(target_character.get("stamina"))
	return 0.0


func _monitor_velocidad_jugador() -> float:
	if target_character != null and is_instance_valid(target_character):
		return target_character.velocity.length()
	return 0.0


func _monitor_velocidad_enemigo() -> float:
	if target_enemigo != null and is_instance_valid(target_enemigo):
		return target_enemigo.velocity.length()
	return 0.0


func _monitor_distancia_monstruo() -> float:
	if target_character != null and is_instance_valid(target_character) and target_enemigo != null and is_instance_valid(target_enemigo):
		return target_character.global_position.distance_to(target_enemigo.global_position)
	return 0.0


func _monitor_estado_jugador() -> int:
	if target_character != null and is_instance_valid(target_character):
		if "estado_actual" in target_character:
			return int(target_character.get("estado_actual"))
	return 0

