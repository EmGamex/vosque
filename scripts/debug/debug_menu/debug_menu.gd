@tool
extends CanvasLayer
class_name DebugMenu

## Modos de visualización del sistema de debug
## OCULTO: Solo visible si hay overlays en mundo o ventanas fijadas (📌).
## EDICION (o COMPLETO): Barra Dock abierta + todas las ventanas activas para configurar.
## MINI_HUD: Mantenido por retrocompatibilidad (se comporta como modo edición).
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

# Nodos raíz
@onready var control_raiz: Control = $ControlRaiz
@onready var barra_dock: PanelContainer = get_node_or_null("ControlRaiz/BarraDock") as PanelContainer
@onready var contenedor_ventanas: Control = get_node_or_null("ControlRaiz/ContenedorVentanas") as Control
@onready var overlay_draw: Node2D = $DebugOverlay

# Barra Dock
@onready var btn_dock_jugador: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnDockJugador") as Button
@onready var btn_dock_fisicas: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnDockFisicas") as Button
@onready var btn_dock_escenario: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnDockEscenario") as Button
@onready var btn_dock_enemigo: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnDockEnemigo") as Button
@onready var btn_dock_audio: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnDockAudio") as Button
@onready var btn_dock_sistema: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnDockSistema") as Button
@onready var option_presets: OptionButton = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/OptionPresets") as OptionButton
@onready var btn_ordenar_mosaico: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnOrdenarMosaico") as Button
@onready var check_pausar: CheckBox = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/CheckPausar") as CheckBox
@onready var btn_cerrar_dock: Button = get_node_or_null("ControlRaiz/BarraDock/HBoxDock/BtnCerrarDock") as Button

# Ventanas Modulares
@onready var win_jugador: DebugWindow = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaJugador") as DebugWindow
@onready var win_fisicas: DebugWindow = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaFisicas") as DebugWindow
@onready var win_escenario: DebugWindow = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaEscenario") as DebugWindow
@onready var win_enemigo: DebugWindow = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaEnemigo") as DebugWindow
@onready var win_audio: DebugWindow = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaAudio") as DebugWindow
@onready var win_sistema: DebugWindow = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaSistema") as DebugWindow

# Controles UI - Jugador
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

# Controles UI - Físicas
var check_proporcional: CheckBox
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
var btn_reset_fisicas: Button

# Controles UI - Escenario
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

# Controles UI - Enemigo
var lbl_enemigo_estado: Label
var lbl_enemigo_pos: Label
var lbl_enemigo_dist: Label
var lbl_enemigo_vel: Label
var lbl_enemigo_atascado: Label
var btn_teleport_enemigo: Button
var check_visual_debug: CheckBox

# Controles UI - Audio
var lbl_musica_estado: Label
var lbl_musica_clip: Label
var lbl_musica_volumen: Label
var btn_musica_menu: Button
var btn_musica_supervivencia: Button
var btn_musica_jumpscare: Button
var btn_musica_game_over: Button
var btn_musica_restaurar: Button
var slider_vol_base: HSlider
var val_slider_vol_base: Label
var slider_aten_pausa: HSlider
var val_slider_aten_pausa: Label
var slider_pitch_go: HSlider
var val_slider_pitch_go: Label

# Controles UI - Sistema
var lbl_sys_fps: Label
var lbl_sys_mem: Label
var lbl_sys_timescale: Label
var btn_time_05: Button
var btn_time_10: Button
var btn_time_20: Button
var btn_reload_scene: Button
var val_high_score: Label
var btn_reset_high_score: Button

var todas_las_ventanas: Array[DebugWindow] = []


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

	_vincular_nodos_ui()
	_conectar_eventos_dock()
	_conectar_eventos_ventanas()
	_inicializar_presets_combo()

	if not Engine.is_editor_hint():
		_restaurar_estado_desde_config()

	_actualizar_visibilidad()

	if Engine.is_editor_hint():
		return

	_buscar_nodos_objetivo()
	scenario.inicializar_camaras(context)
	scenario.aplicar_estado_niebla(context)
	monitors.registrar(context)
	_inicializar_controles_musica()
	_inicializar_controles_persistencia()


func _vincular_nodos_ui() -> void:
	todas_las_ventanas.clear()
	if win_jugador != null: todas_las_ventanas.append(win_jugador)
	if win_fisicas != null: todas_las_ventanas.append(win_fisicas)
	if win_escenario != null: todas_las_ventanas.append(win_escenario)
	if win_enemigo != null: todas_las_ventanas.append(win_enemigo)
	if win_audio != null: todas_las_ventanas.append(win_audio)
	if win_sistema != null: todas_las_ventanas.append(win_sistema)

	if win_jugador != null:
		lbl_vel = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValVel") as Label
		lbl_vel_max = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValVelMax") as Label
		lbl_acel = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValAcel") as Label
		lbl_fric = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValFric") as Label
		lbl_estado = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValEstado") as Label
		lbl_estamina = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValEstamina") as Label
		lbl_pos_jugador = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValPosicion") as Label
		lbl_cuadrante_jugador = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/GridTelemetria/ValCuadrante") as Label
		flecha_up = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/HBoxPad/GridPad/FlechaUp") as Label
		flecha_down = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/HBoxPad/GridPad/FlechaDown") as Label
		flecha_left = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/HBoxPad/GridPad/FlechaLeft") as Label
		flecha_right = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/HBoxPad/GridPad/FlechaRight") as Label
		check_estamina_infinita = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/HBoxCheats/CheckEstaminaInfinita") as CheckBox
		check_god_mode = win_jugador.get_node_or_null("Margin/VBox/Contenido/VBoxJugador/HBoxCheats/CheckGodMode") as CheckBox

	if win_fisicas != null:
		check_proporcional = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/HBoxOpciones/CheckProporcional") as CheckBox
		btn_reset_fisicas = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/HBoxOpciones/BtnResetFisicas") as Button
		slider_vel_normal = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/SliderVelNormal") as HSlider
		val_slider_vel_normal = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/ValSliderVelNormal") as Label
		slider_vel_sprint = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/SliderVelSprint") as HSlider
		val_slider_vel_sprint = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/ValSliderVelSprint") as Label
		slider_acel = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/SliderAcel") as HSlider
		val_slider_acel = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/ValSliderAcel") as Label
		slider_fric = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/SliderFric") as HSlider
		val_slider_fric = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/ValSliderFric") as Label
		slider_dive_vel = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/SliderDiveVel") as HSlider
		val_slider_dive_vel = win_fisicas.get_node_or_null("Margin/VBox/Contenido/VBoxFisicas/GridVelocidades/ValSliderDiveVel") as Label

	if win_escenario != null:
		lbl_escenario_estado = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/LblEstadoEscenario") as Label
		lbl_escenario_no = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/GridSectores/ValNO") as Label
		lbl_escenario_ne = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/GridSectores/ValNE") as Label
		lbl_escenario_so = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/GridSectores/ValSO") as Label
		lbl_escenario_se = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/GridSectores/ValSE") as Label
		btn_mutar = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/BtnMutar") as Button
		check_desactivar_niebla = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/CheckDesactivarNiebla") as CheckBox
		check_god_view = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/CheckGodView") as CheckBox
		check_corredores = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/CheckCorredores") as CheckBox
		check_cuadrantes = win_escenario.get_node_or_null("Margin/VBox/Contenido/VBoxEscenario/CheckCuadrantes") as CheckBox

	if win_enemigo != null:
		lbl_enemigo_estado = win_enemigo.get_node_or_null("Margin/VBox/Contenido/VBoxEnemigo/GridEnemigo/ValEstadoIA") as Label
		lbl_enemigo_pos = win_enemigo.get_node_or_null("Margin/VBox/Contenido/VBoxEnemigo/GridEnemigo/ValPosEnemigo") as Label
		lbl_enemigo_dist = win_enemigo.get_node_or_null("Margin/VBox/Contenido/VBoxEnemigo/GridEnemigo/ValDistancia") as Label
		lbl_enemigo_vel = win_enemigo.get_node_or_null("Margin/VBox/Contenido/VBoxEnemigo/GridEnemigo/ValVelEnemigo") as Label
		lbl_enemigo_atascado = win_enemigo.get_node_or_null("Margin/VBox/Contenido/VBoxEnemigo/GridEnemigo/ValAtascamiento") as Label
		btn_teleport_enemigo = win_enemigo.get_node_or_null("Margin/VBox/Contenido/VBoxEnemigo/BtnTeleportEnemigo") as Button
		check_visual_debug = win_enemigo.get_node_or_null("Margin/VBox/Contenido/VBoxEnemigo/CheckVisualDebug") as CheckBox

	if win_audio != null:
		lbl_musica_estado = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridMusica/ValEstadoMusica") as Label
		lbl_musica_clip = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridMusica/ValClipMusica") as Label
		lbl_musica_volumen = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridMusica/ValVolumenMusica") as Label
		btn_musica_menu = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/HBoxBotonesMusica/BtnMusicaMenu") as Button
		btn_musica_supervivencia = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/HBoxBotonesMusica/BtnMusicaSupervivencia") as Button
		btn_musica_jumpscare = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/HBoxBotonesMusica/BtnMusicaJumpscare") as Button
		btn_musica_game_over = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/HBoxBotonesMusica/BtnMusicaGameOver") as Button
		btn_musica_restaurar = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/HBoxBotonesMusica/BtnMusicaRestaurar") as Button
		slider_vol_base = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridSlidersMusica/SliderVolBase") as HSlider
		val_slider_vol_base = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridSlidersMusica/ValSliderVolBase") as Label
		slider_aten_pausa = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridSlidersMusica/SliderAtenPausa") as HSlider
		val_slider_aten_pausa = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridSlidersMusica/ValSliderAtenPausa") as Label
		slider_pitch_go = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridSlidersMusica/SliderPitchGO") as HSlider
		val_slider_pitch_go = win_audio.get_node_or_null("Margin/VBox/Contenido/VBoxAudio/GridSlidersMusica/ValSliderPitchGO") as Label

	if win_sistema != null:
		lbl_sys_fps = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/GridSistema/ValFPS") as Label
		lbl_sys_mem = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/GridSistema/ValMemoria") as Label
		lbl_sys_timescale = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/GridSistema/ValTimeScale") as Label
		btn_time_05 = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/HBoxTimeButtons/BtnTime05") as Button
		btn_time_10 = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/HBoxTimeButtons/BtnTime10") as Button
		btn_time_20 = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/HBoxTimeButtons/BtnTime20") as Button
		btn_reload_scene = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/BtnReloadScene") as Button
		val_high_score = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/HBoxPersistencia/ValHighScore") as Label
		btn_reset_high_score = win_sistema.get_node_or_null("Margin/VBox/Contenido/VBoxSistema/BtnResetearHighScore") as Button


func _conectar_eventos_dock() -> void:
	if btn_dock_jugador != null and not btn_dock_jugador.pressed.is_connected(_on_btn_dock_jugador_pressed):
		btn_dock_jugador.pressed.connect(_on_btn_dock_jugador_pressed)
	if btn_dock_fisicas != null and not btn_dock_fisicas.pressed.is_connected(_on_btn_dock_fisicas_pressed):
		btn_dock_fisicas.pressed.connect(_on_btn_dock_fisicas_pressed)
	if btn_dock_escenario != null and not btn_dock_escenario.pressed.is_connected(_on_btn_dock_escenario_pressed):
		btn_dock_escenario.pressed.connect(_on_btn_dock_escenario_pressed)
	if btn_dock_enemigo != null and not btn_dock_enemigo.pressed.is_connected(_on_btn_dock_enemigo_pressed):
		btn_dock_enemigo.pressed.connect(_on_btn_dock_enemigo_pressed)
	if btn_dock_audio != null and not btn_dock_audio.pressed.is_connected(_on_btn_dock_audio_pressed):
		btn_dock_audio.pressed.connect(_on_btn_dock_audio_pressed)
	if btn_dock_sistema != null and not btn_dock_sistema.pressed.is_connected(_on_btn_dock_sistema_pressed):
		btn_dock_sistema.pressed.connect(_on_btn_dock_sistema_pressed)
	if btn_ordenar_mosaico != null and not btn_ordenar_mosaico.pressed.is_connected(ordenar_ventanas_en_mosaico):
		btn_ordenar_mosaico.pressed.connect(ordenar_ventanas_en_mosaico)
	if check_pausar != null and not check_pausar.toggled.is_connected(_on_check_pausar_toggled):
		check_pausar.toggled.connect(_on_check_pausar_toggled)
	if btn_cerrar_dock != null and not btn_cerrar_dock.pressed.is_connected(_on_btn_cerrar_dock_pressed):
		btn_cerrar_dock.pressed.connect(_on_btn_cerrar_dock_pressed)


func _conectar_eventos_ventanas() -> void:
	for win in todas_las_ventanas:
		if win != null and not win.estado_modificado.is_connected(_on_ventana_estado_modificado):
			win.estado_modificado.connect(_on_ventana_estado_modificado)

	# Cheats
	if check_estamina_infinita != null and not check_estamina_infinita.toggled.is_connected(_on_check_estamina_infinita_toggled):
		check_estamina_infinita.toggled.connect(_on_check_estamina_infinita_toggled)
	if check_god_mode != null and not check_god_mode.toggled.is_connected(_on_check_god_mode_toggled):
		check_god_mode.toggled.connect(_on_check_god_mode_toggled)

	# Físicas
	if check_proporcional != null and not check_proporcional.toggled.is_connected(_on_check_proporcional_toggled):
		check_proporcional.toggled.connect(_on_check_proporcional_toggled)
	if btn_reset_fisicas != null and not btn_reset_fisicas.pressed.is_connected(_on_btn_reset_velocidades_pressed):
		btn_reset_fisicas.pressed.connect(_on_btn_reset_velocidades_pressed)
	if slider_vel_normal != null and not slider_vel_normal.value_changed.is_connected(_on_slider_vel_normal_value_changed):
		slider_vel_normal.value_changed.connect(_on_slider_vel_normal_value_changed)
	if slider_vel_sprint != null and not slider_vel_sprint.value_changed.is_connected(_on_slider_vel_sprint_value_changed):
		slider_vel_sprint.value_changed.connect(_on_slider_vel_sprint_value_changed)
	if slider_acel != null and not slider_acel.value_changed.is_connected(_on_slider_acel_value_changed):
		slider_acel.value_changed.connect(_on_slider_acel_value_changed)
	if slider_fric != null and not slider_fric.value_changed.is_connected(_on_slider_fric_value_changed):
		slider_fric.value_changed.connect(_on_slider_fric_value_changed)
	if slider_dive_vel != null and not slider_dive_vel.value_changed.is_connected(_on_slider_dive_vel_value_changed):
		slider_dive_vel.value_changed.connect(_on_slider_dive_vel_value_changed)

	# Escenario
	if btn_mutar != null and not btn_mutar.pressed.is_connected(_on_btn_forzar_mutacion_pressed):
		btn_mutar.pressed.connect(_on_btn_forzar_mutacion_pressed)
	if check_desactivar_niebla != null and not check_desactivar_niebla.toggled.is_connected(_on_check_desactivar_niebla_toggled):
		check_desactivar_niebla.toggled.connect(_on_check_desactivar_niebla_toggled)
	if check_god_view != null and not check_god_view.toggled.is_connected(_on_check_god_view_toggled):
		check_god_view.toggled.connect(_on_check_god_view_toggled)
	if check_corredores != null and not check_corredores.toggled.is_connected(_on_check_corredores_toggled):
		check_corredores.toggled.connect(_on_check_corredores_toggled)
	if check_cuadrantes != null and not check_cuadrantes.toggled.is_connected(_on_check_cuadrantes_toggled):
		check_cuadrantes.toggled.connect(_on_check_cuadrantes_toggled)

	# Enemigo
	if btn_teleport_enemigo != null and not btn_teleport_enemigo.pressed.is_connected(_on_btn_reubicar_enemigo_pressed):
		btn_teleport_enemigo.pressed.connect(_on_btn_reubicar_enemigo_pressed)
	if check_visual_debug != null and not check_visual_debug.toggled.is_connected(_on_check_visual_debug_enemigo_toggled):
		check_visual_debug.toggled.connect(_on_check_visual_debug_enemigo_toggled)

	# Sistema
	if btn_time_05 != null and not btn_time_05.pressed.is_connected(_on_btn_timescale_05_pressed):
		btn_time_05.pressed.connect(_on_btn_timescale_05_pressed)
	if btn_time_10 != null and not btn_time_10.pressed.is_connected(_on_btn_timescale_10_pressed):
		btn_time_10.pressed.connect(_on_btn_timescale_10_pressed)
	if btn_time_20 != null and not btn_time_20.pressed.is_connected(_on_btn_timescale_20_pressed):
		btn_time_20.pressed.connect(_on_btn_timescale_20_pressed)
	if btn_reload_scene != null and not btn_reload_scene.pressed.is_connected(_on_btn_reiniciar_escena_pressed):
		btn_reload_scene.pressed.connect(_on_btn_reiniciar_escena_pressed)


func _inicializar_presets_combo() -> void:
	if option_presets == null:
		return
	option_presets.clear()
	option_presets.add_item("Presets Rápidos...")
	option_presets.add_item("Locomoción & Físicas")
	option_presets.add_item("Caza & Enemigo IA")
	option_presets.add_item("Mundo & Mutación")
	option_presets.add_item("Audio & Sistema")
	option_presets.add_item("Cerrar Todas")
	if not option_presets.item_selected.is_connected(_on_preset_selected):
		option_presets.item_selected.connect(_on_preset_selected)


func _on_preset_selected(index: int) -> void:
	match index:
		1: # Locomoción
			_cerrar_todas_las_ventanas()
			if win_jugador != null: win_jugador.abierta = true; win_jugador.global_position = Vector2(20, 60)
			if win_fisicas != null: win_fisicas.abierta = true; win_fisicas.fijada = true; win_fisicas.global_position = Vector2(360, 60)
		2: # Caza & IA
			_cerrar_todas_las_ventanas()
			if win_jugador != null: win_jugador.abierta = true; win_jugador.global_position = Vector2(20, 60)
			if win_enemigo != null: win_enemigo.abierta = true; win_enemigo.fijada = true; win_enemigo.global_position = Vector2(360, 60)
		3: # Mundo
			_cerrar_todas_las_ventanas()
			if win_escenario != null: win_escenario.abierta = true; win_escenario.fijada = true; win_escenario.global_position = Vector2(20, 60)
		4: # Audio & Sistema
			_cerrar_todas_las_ventanas()
			if win_audio != null: win_audio.abierta = true; win_audio.global_position = Vector2(20, 60)
			if win_sistema != null: win_sistema.abierta = true; win_sistema.global_position = Vector2(360, 60)
		5: # Cerrar Todas
			_cerrar_todas_las_ventanas()
	option_presets.selected = 0


func _cerrar_todas_las_ventanas() -> void:
	for win in todas_las_ventanas:
		if win != null:
			win.abierta = false
			win.fijada = false


func ordenar_ventanas_en_mosaico() -> void:
	var margen_x: float = 20.0
	var cursor_x: float = margen_x
	var cursor_y: float = 60.0
	var ancho_pantalla = get_viewport().get_visible_rect().size.x

	for win in todas_las_ventanas:
		if win != null and win.abierta:
			if cursor_x + win.size.x > ancho_pantalla and cursor_x > margen_x:
				cursor_x = margen_x
				cursor_y += 320.0
			win.global_position = Vector2(cursor_x, cursor_y)
			cursor_x += win.size.x + 15.0


func _on_ventana_estado_modificado(win_id: String) -> void:
	var cfg = get_node_or_null("/root/DebugConfig")
	if cfg == null:
		return
	for win in todas_las_ventanas:
		if win != null and win.window_id == win_id:
			cfg.guardar_estado_ventana(win_id, win.abierta, win.fijada, win.colapsada, win.global_position)
			break


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

	# Restaurar layout de ventanas
	var posiciones_defecto = {
		"jugador": Vector2(20, 60),
		"fisicas": Vector2(360, 60),
		"escenario": Vector2(20, 360),
		"enemigo": Vector2(400, 360),
		"audio": Vector2(740, 60),
		"sistema": Vector2(740, 360)
	}

	for win in todas_las_ventanas:
		if win != null:
			var pos_def: Vector2 = posiciones_defecto.get(win.window_id, Vector2(20, 60))
			var estado: Dictionary = cfg.obtener_estado_ventana(win.window_id, false, pos_def)
			win.abierta = estado.get("abierta", false)
			win.fijada = estado.get("fijada", false)
			win.colapsada = estado.get("colapsada", false)
			win.global_position = estado.get("posicion", pos_def)


func _exit_tree() -> void:
	monitors.limpiar()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			# Bi-estado inteligente: si estamos en edición pasa a juego; si no, a edición
			if modo_actual == ModoVisual.COMPLETO:
				modo_actual = ModoVisual.OCULTO
			else:
				modo_actual = ModoVisual.COMPLETO
			get_viewport().set_input_as_handled()
		elif modo_actual == ModoVisual.COMPLETO and (event.keycode == KEY_ESCAPE or event.is_action_pressed("pausa") or event.is_action_pressed("ui_cancel")):
			modo_actual = ModoVisual.OCULTO
			get_viewport().set_input_as_handled()


func _actualizar_visibilidad() -> void:
	var hay_overlays_activos: bool = scenario != null and (scenario.debug_dibujar_cuadrantes or scenario.debug_dibujar_corredores)
	var hay_ventanas_fijadas: bool = false
	for win in todas_las_ventanas:
		if win != null and win.abierta and win.fijada:
			hay_ventanas_fijadas = true
			break

	var en_edicion: bool = (modo_actual == ModoVisual.COMPLETO or modo_actual == ModoVisual.MINI_HUD)
	visible = en_edicion or hay_overlays_activos or hay_ventanas_fijadas

	if barra_dock != null:
		barra_dock.visible = en_edicion

	for win in todas_las_ventanas:
		if win != null:
			win.aplicar_modo_juego(not en_edicion)

	if overlay_draw != null:
		overlay_draw.queue_redraw()
	if context != null and context.target_enemigo != null and is_instance_valid(context.target_enemigo):
		context.target_enemigo.set("debug_dibujar_rayo", enemy_ctrl.debug_dibujar_vectores_ia)
		context.target_enemigo.queue_redraw()


func _process(_delta: float) -> void:
	if not visible:
		return

	if not is_instance_valid(context.target_character) or not is_instance_valid(context.target_camara):
		_buscar_nodos_objetivo()

	# Solo actualizar telemetría si las ventanas correspondientes están abiertas
	if win_jugador != null and win_jugador.visible and not win_jugador.colapsada:
		telemetry.actualizar_jugador(context, lbl_vel, lbl_vel_max, lbl_acel, lbl_fric, lbl_estado, lbl_estamina, lbl_pos_jugador, lbl_cuadrante_jugador)
		telemetry.actualizar_pad(flecha_up, flecha_down, flecha_left, flecha_right)

	if win_escenario != null and win_escenario.visible and not win_escenario.colapsada:
		telemetry.actualizar_escenario(context, lbl_escenario_estado, lbl_escenario_no, lbl_escenario_ne, lbl_escenario_so, lbl_escenario_se)

	if win_enemigo != null and win_enemigo.visible and not win_enemigo.colapsada:
		telemetry.actualizar_enemigo(context, lbl_enemigo_estado, lbl_enemigo_pos, lbl_enemigo_dist, lbl_enemigo_vel, lbl_enemigo_atascado)

	if win_audio != null and win_audio.visible and not win_audio.colapsada:
		telemetry.actualizar_audio(get_tree(), lbl_musica_estado, lbl_musica_clip, lbl_musica_volumen)

	if win_sistema != null and win_sistema.visible and not win_sistema.colapsada:
		telemetry.actualizar_sistema(lbl_sys_fps, lbl_sys_mem, lbl_sys_timescale)


func _buscar_nodos_objetivo() -> void:
	var escena_actual: Node = get_tree().current_scene if get_tree() != null else null
	if escena_actual == null:
		escena_actual = get_parent()
	context.buscar_nodos(escena_actual, scenario.god_view_activo)
	physics.inicializar_valores(context.target_character, get_node_or_null("/root/DebugConfig"), _obtener_ui_fisicas())


func _obtener_ui_fisicas() -> Dictionary:
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


# --- Handlers Dock ---

func _on_btn_dock_jugador_pressed() -> void:
	if win_jugador != null: win_jugador.abierta = not win_jugador.abierta

func _on_btn_dock_fisicas_pressed() -> void:
	if win_fisicas != null: win_fisicas.abierta = not win_fisicas.abierta

func _on_btn_dock_escenario_pressed() -> void:
	if win_escenario != null: win_escenario.abierta = not win_escenario.abierta

func _on_btn_dock_enemigo_pressed() -> void:
	if win_enemigo != null: win_enemigo.abierta = not win_enemigo.abierta

func _on_btn_dock_audio_pressed() -> void:
	if win_audio != null: win_audio.abierta = not win_audio.abierta

func _on_btn_dock_sistema_pressed() -> void:
	if win_sistema != null: win_sistema.abierta = not win_sistema.abierta

func _on_btn_cerrar_dock_pressed() -> void:
	modo_actual = ModoVisual.OCULTO


# --- Handlers Controles ---

func _on_check_pausar_toggled(toggled_on: bool) -> void:
	system_ctrl.toggle_pausa(get_tree(), toggled_on)

func _on_check_estamina_infinita_toggled(toggled_on: bool) -> void:
	cheats.set_estamina_infinita(toggled_on, context.target_character, get_node_or_null("/root/DebugConfig"))

func _on_check_god_mode_toggled(toggled_on: bool) -> void:
	cheats.set_god_mode(toggled_on, context.target_character, get_node_or_null("/root/DebugConfig"))

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


# --- Audio y Música (Issue #28) ---

func _inicializar_controles_musica() -> void:
	if btn_musica_menu != null and not btn_musica_menu.pressed.is_connected(_on_btn_musica_menu_pressed):
		btn_musica_menu.pressed.connect(_on_btn_musica_menu_pressed)
	if btn_musica_supervivencia != null and not btn_musica_supervivencia.pressed.is_connected(_on_btn_musica_supervivencia_pressed):
		btn_musica_supervivencia.pressed.connect(_on_btn_musica_supervivencia_pressed)
	if btn_musica_jumpscare != null and not btn_musica_jumpscare.pressed.is_connected(_on_btn_musica_jumpscare_pressed):
		btn_musica_jumpscare.pressed.connect(_on_btn_musica_jumpscare_pressed)
	if btn_musica_game_over != null and not btn_musica_game_over.pressed.is_connected(_on_btn_musica_game_over_pressed):
		btn_musica_game_over.pressed.connect(_on_btn_musica_game_over_pressed)
	if btn_musica_restaurar != null and not btn_musica_restaurar.pressed.is_connected(_on_btn_musica_restaurar_pressed):
		btn_musica_restaurar.pressed.connect(_on_btn_musica_restaurar_pressed)

	var tree := get_tree()
	var gm: Node = tree.root.get_node_or_null("GestorMusica") if (tree != null and tree.root != null) else null
	var cfg_musica: ConfiguracionMusica = gm.config if (gm != null and "config" in gm and gm.config is ConfiguracionMusica) else null

	if cfg_musica != null:
		if slider_vol_base != null:
			slider_vol_base.set_value_no_signal(cfg_musica.volumen_base_db)
			if val_slider_vol_base != null: val_slider_vol_base.text = "%.1f dB" % cfg_musica.volumen_base_db
		if slider_aten_pausa != null:
			slider_aten_pausa.set_value_no_signal(cfg_musica.atenuacion_pausa_db)
			if val_slider_aten_pausa != null: val_slider_aten_pausa.text = "%.1f dB" % cfg_musica.atenuacion_pausa_db
		if slider_pitch_go != null:
			slider_pitch_go.set_value_no_signal(cfg_musica.pitch_game_over)
			if val_slider_pitch_go != null: val_slider_pitch_go.text = "%.2fx" % cfg_musica.pitch_game_over

	if slider_vol_base != null and not slider_vol_base.value_changed.is_connected(_on_slider_vol_base_value_changed):
		slider_vol_base.value_changed.connect(_on_slider_vol_base_value_changed)
	if slider_aten_pausa != null and not slider_aten_pausa.value_changed.is_connected(_on_slider_aten_pausa_value_changed):
		slider_aten_pausa.value_changed.connect(_on_slider_aten_pausa_value_changed)
	if slider_pitch_go != null and not slider_pitch_go.value_changed.is_connected(_on_slider_pitch_go_value_changed):
		slider_pitch_go.value_changed.connect(_on_slider_pitch_go_value_changed)


func _on_btn_musica_menu_pressed() -> void:
	system_ctrl.forzar_musica_menu()

func _on_btn_musica_supervivencia_pressed() -> void:
	system_ctrl.forzar_musica_supervivencia()

func _on_btn_musica_jumpscare_pressed() -> void:
	system_ctrl.forzar_corte_jumpscare()

func _on_btn_musica_game_over_pressed() -> void:
	system_ctrl.forzar_modo_game_over()

func _on_btn_musica_restaurar_pressed() -> void:
	system_ctrl.restaurar_audio_normal()

func _on_slider_vol_base_value_changed(val: float) -> void:
	system_ctrl.set_volumen_base(val)
	if val_slider_vol_base != null:
		val_slider_vol_base.text = "%.1f dB" % val

func _on_slider_aten_pausa_value_changed(val: float) -> void:
	system_ctrl.set_atenuacion_pausa(val)
	if val_slider_aten_pausa != null:
		val_slider_aten_pausa.text = "%.1f dB" % val

func _on_slider_pitch_go_value_changed(val: float) -> void:
	system_ctrl.set_pitch_game_over(val)
	if val_slider_pitch_go != null:
		val_slider_pitch_go.text = "%.2fx" % val


# --- Persistencia High Score (Issue #35) ---

func _inicializar_controles_persistencia() -> void:
	if btn_reset_high_score != null and not btn_reset_high_score.pressed.is_connected(_on_btn_reset_high_score_pressed):
		btn_reset_high_score.pressed.connect(_on_btn_reset_high_score_pressed)

func _on_btn_reset_high_score_pressed() -> void:
	system_ctrl.resetear_high_score()
	if val_high_score != null:
		val_high_score.text = str(system_ctrl.obtener_high_score())
