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
		var cfg = _get_debug_config()
		if cfg != null:
			cfg.modo_actual = int(modo_actual)

@export_group("Nodos de Referencia")
@export var target_character: CharacterBody2D:
	get: return context.target_character if context != null else null
	set(val): if context != null: context.target_character = val
@export var target_enemigo: CharacterBody2D:
	get: return context.target_enemigo if context != null else null
	set(val): if context != null: context.target_enemigo = val
@export var target_camara: Camera2D:
	get: return context.target_camara if context != null else null
	set(val): if context != null: context.target_camara = val
@export var target_camara_dios: Camera2D:
	get: return context.target_camara_dios if context != null else null
	set(val): if context != null: context.target_camara_dios = val
@export var target_escenario: Node2D:
	get: return context.target_escenario if context != null else null
	set(val): if context != null: context.target_escenario = val

# Sub-controladores modulares de lógica
var context: DebugContext
var cheats: DebugCheatsController
var physics: DebugPhysicsController
var scenario: DebugScenarioController
var enemy_ctrl: DebugEnemyController
var system_ctrl: DebugSystemController
var telemetry: DebugTelemetryPresenter
var monitors: DebugCustomMonitors

# Gestores de interfaz y ventanas
var window_manager: DebugWindowManager
var dock_controller: DebugDockController
var external_window: DebugExternalWindow
var esta_desacoplada: bool = false

# Paneles de contenido para cada ventana
var panel_jugador: DebugPlayerPanel
var panel_fisicas: DebugPhysicsPanel
var panel_escenario: DebugScenarioPanel
var panel_enemigo: DebugEnemyPanel
var panel_audio: DebugAudioPanel
var panel_sistema: DebugSystemPanel

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

# Propiedades de ventanas con resolución perezosa (soporta instanciación fuera del árbol en tests)
var _win_jugador: DebugWindow
var win_jugador: DebugWindow:
	get:
		if _win_jugador == null: _win_jugador = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaJugador") as DebugWindow
		return _win_jugador
	set(v): _win_jugador = v

var _win_fisicas: DebugWindow
var win_fisicas: DebugWindow:
	get:
		if _win_fisicas == null: _win_fisicas = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaFisicas") as DebugWindow
		return _win_fisicas
	set(v): _win_fisicas = v

var _win_escenario: DebugWindow
var win_escenario: DebugWindow:
	get:
		if _win_escenario == null: _win_escenario = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaEscenario") as DebugWindow
		return _win_escenario
	set(v): _win_escenario = v

var _win_enemigo: DebugWindow
var win_enemigo: DebugWindow:
	get:
		if _win_enemigo == null: _win_enemigo = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaEnemigo") as DebugWindow
		return _win_enemigo
	set(v): _win_enemigo = v

var _win_audio: DebugWindow
var win_audio: DebugWindow:
	get:
		if _win_audio == null: _win_audio = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaAudio") as DebugWindow
		return _win_audio
	set(v): _win_audio = v

var _win_sistema: DebugWindow
var win_sistema: DebugWindow:
	get:
		if _win_sistema == null: _win_sistema = get_node_or_null("ControlRaiz/ContenedorVentanas/VentanaSistema") as DebugWindow
		return _win_sistema
	set(v): _win_sistema = v

var option_presets: OptionButton:
	get:
		if dock_controller != null and dock_controller.option_presets != null:
			return dock_controller.option_presets
		return get_node_or_null("ControlRaiz/BarraDock/HBoxDock/OptionPresets") as OptionButton

var todas_las_ventanas: Array[DebugWindow]:
	get: return window_manager.todas_las_ventanas if window_manager != null else []


func _init() -> void:
	context = DebugContext.new()
	cheats = DebugCheatsController.new()
	physics = DebugPhysicsController.new()
	scenario = DebugScenarioController.new()
	enemy_ctrl = DebugEnemyController.new()
	system_ctrl = DebugSystemController.new()
	telemetry = DebugTelemetryPresenter.new()
	monitors = DebugCustomMonitors.new()

	window_manager = DebugWindowManager.new()
	dock_controller = DebugDockController.new()

	panel_jugador = DebugPlayerPanel.new()
	panel_fisicas = DebugPhysicsPanel.new()
	panel_escenario = DebugScenarioPanel.new()
	panel_enemigo = DebugEnemyPanel.new()
	panel_audio = DebugAudioPanel.new()
	panel_sistema = DebugSystemPanel.new()


func _ready() -> void:
	if not Engine.is_editor_hint() and not OS.is_debug_build():
		visible = false
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		set_process_unhandled_input(false)
		queue_free()
		return

	process_mode = Node.PROCESS_MODE_ALWAYS

	_inicializar_gestores_y_paneles()

	if not Engine.is_editor_hint():
		_restaurar_estado_desde_config()

	_actualizar_visibilidad()

	if Engine.is_editor_hint():
		return

	_buscar_nodos_objetivo()
	scenario.inicializar_camaras(context)
	scenario.aplicar_estado_niebla(context)
	monitors.registrar(context)
	panel_audio.inicializar_controles_musica(get_tree(), system_ctrl)


func _inicializar_gestores_y_paneles() -> void:
	var lista_ventanas: Array[DebugWindow] = []
	for w in [win_jugador, win_fisicas, win_escenario, win_enemigo, win_audio, win_sistema]:
		if w != null:
			lista_ventanas.append(w)

	window_manager.inicializar(lista_ventanas)
	window_manager.conectar_eventos_ventanas(_on_ventana_estado_modificado)

	dock_controller.vincular_nodos(barra_dock)
	dock_controller.inicializar_presets()
	dock_controller.conectar_eventos(window_manager, system_ctrl, get_tree())
	dock_controller.modo_ocultar_solicitado.connect(func(): modo_actual = ModoVisual.OCULTO)
	dock_controller.ordenar_mosaico_solicitado.connect(ordenar_ventanas_en_mosaico)
	dock_controller.desacoplar_toggled.connect(set_desacoplada)

	external_window = DebugExternalWindow.new()
	external_window.cierre_solicitado.connect(func(): modo_actual = ModoVisual.OCULTO)
	add_child(external_window)

	panel_jugador.vincular_nodos(win_jugador)
	panel_jugador.conectar_eventos(cheats, context, _get_debug_config)

	panel_fisicas.vincular_nodos(win_fisicas)
	panel_fisicas.conectar_eventos(physics, context, _get_debug_config)

	panel_escenario.vincular_nodos(win_escenario)
	panel_escenario.conectar_eventos(scenario, context, _get_debug_config)
	panel_escenario.overlay_modificado.connect(_actualizar_visibilidad)

	panel_enemigo.vincular_nodos(win_enemigo)
	panel_enemigo.conectar_eventos(enemy_ctrl, context, _get_debug_config)

	panel_audio.vincular_nodos(win_audio)
	panel_sistema.vincular_nodos(win_sistema)
	panel_sistema.conectar_eventos(system_ctrl, get_tree(), _get_debug_config)


func _on_ventana_estado_modificado(win_id: String) -> void:
	window_manager.guardar_estado_ventana(win_id, _get_debug_config())


func _restaurar_estado_desde_config() -> void:
	var cfg = _get_debug_config()
	if cfg == null:
		return

	modo_actual = cfg.modo_actual as ModoVisual
	panel_jugador.restaurar_desde_config(cheats, cfg)
	panel_escenario.restaurar_desde_config(scenario, cfg)
	panel_enemigo.restaurar_desde_config(enemy_ctrl, cfg)
	panel_fisicas.restaurar_desde_config(physics, cfg)
	Engine.time_scale = cfg.time_scale

	window_manager.restaurar_desde_config(cfg)

	if external_window != null:
		external_window.inicializar_geometria(cfg)

	if "ventana_desacoplada" in cfg and cfg.ventana_desacoplada and DisplayServer.has_feature(DisplayServer.FEATURE_SUBWINDOWS):
		set_desacoplada(true)


func _exit_tree() -> void:
	monitors.limpiar()


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			if modo_actual == ModoVisual.COMPLETO:
				modo_actual = ModoVisual.OCULTO
			else:
				modo_actual = ModoVisual.COMPLETO
			get_viewport().set_input_as_handled()
		elif modo_actual == ModoVisual.COMPLETO and (event.keycode == KEY_ESCAPE or event.is_action_pressed("pausa") or event.is_action_pressed("ui_cancel")):
			modo_actual = ModoVisual.OCULTO
			get_viewport().set_input_as_handled()


func _actualizar_visibilidad() -> void:
	var hay_overlays: bool = scenario != null and (scenario.debug_dibujar_cuadrantes or scenario.debug_dibujar_corredores)
	var en_edicion: bool = (modo_actual == ModoVisual.COMPLETO or modo_actual == ModoVisual.MINI_HUD)

	var visible_interior: bool = window_manager.actualizar_visibilidad(en_edicion, hay_overlays, barra_dock)

	if esta_desacoplada and external_window != null:
		# En modo desacoplado, la ventana externa muestra la UI si estamos en edición o si hay ventanas fijadas
		var hay_fijadas: bool = false
		for win in window_manager.todas_las_ventanas:
			if win != null and win.abierta and win.fijada:
				hay_fijadas = true
				break
		external_window.visible = en_edicion or hay_fijadas
		# El CanvasLayer principal solo debe estar visible si hay overlays de dibujo sobre el juego
		visible = hay_overlays
	else:
		if external_window != null:
			external_window.visible = false
		visible = visible_interior

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

	if not visible:
		return

	_actualizar_telemetria()


func _actualizar_telemetria() -> void:
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

	# Actualizar Ventana Jugador
	if win_jugador != null and win_jugador.visible and not win_jugador.colapsada:
		panel_jugador.actualizar_telemetria(telemetry, context, vel_actual, vel_max, acel, fric, estado_txt, estamina_txt, pos_jugador, cuadrante_jugador)

	# Actualizar Ventana Escenario
	if win_escenario != null and win_escenario.visible and not win_escenario.colapsada:
		panel_escenario.actualizar_telemetria(telemetry, context.target_escenario, cuadrante_jugador)

	# Actualizar Ventana Enemigo
	if win_enemigo != null and win_enemigo.visible and not win_enemigo.colapsada:
		panel_enemigo.actualizar_telemetria(telemetry, context, pos_jugador, enemy_ctrl.debug_dibujar_vectores_ia)

	# Actualizar Ventana Audio y Sistema
	if (win_audio != null and win_audio.visible and not win_audio.colapsada) or (win_sistema != null and win_sistema.visible and not win_sistema.colapsada):
		var fps: int = int(Engine.get_frames_per_second())
		var mem_mb: float = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		var telem_musica: Dictionary = system_ctrl.obtener_telemetria_musica()
		var record_actual: int = system_ctrl.obtener_high_score()
		panel_sistema.actualizar_telemetria(telemetry, fps, mem_mb, telem_musica, record_actual, panel_audio.lbl_musica_estado, panel_audio.lbl_musica_clip, panel_audio.lbl_musica_volumen)


func _buscar_nodos_objetivo() -> void:
	var escena_actual: Node = get_tree().current_scene if get_tree() != null else null
	if escena_actual == null:
		escena_actual = get_parent()
	context.buscar_nodos(escena_actual, scenario.god_view_activo)
	physics.inicializar_valores(context.target_character, _get_debug_config(), panel_fisicas.obtener_ui_fisicas())


func _get_debug_config() -> Node:
	return get_node_or_null("/root/DebugConfig")


# Métodos de delegación para compatibilidad hacia atrás
func set_desacoplada(desacoplar: bool) -> void:
	if desacoplar == esta_desacoplada:
		return
	if desacoplar and not DisplayServer.has_feature(DisplayServer.FEATURE_SUBWINDOWS):
		return

	esta_desacoplada = desacoplar
	var cfg = _get_debug_config()
	if cfg != null:
		cfg.ventana_desacoplada = esta_desacoplada

	dock_controller.actualizar_estado_desacople(esta_desacoplada)

	if control_raiz != null:
		if esta_desacoplada and external_window != null:
			control_raiz.reparent(external_window)
			control_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
		elif not esta_desacoplada:
			control_raiz.reparent(self)
			control_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)

	_actualizar_visibilidad()


func ordenar_ventanas_en_mosaico() -> void:
	var ancho: float = 1280.0
	if esta_desacoplada and external_window != null:
		ancho = float(external_window.size.x)
	elif get_viewport() != null:
		ancho = get_viewport().get_visible_rect().size.x
	window_manager.ordenar_ventanas_en_mosaico(ancho)


func _on_preset_selected(index: int) -> void:
	if window_manager.todas_las_ventanas.is_empty():
		_asegurar_inicializacion_ventanas()
	window_manager.aplicar_preset(index)
	if option_presets != null:
		option_presets.selected = 0


func _asegurar_inicializacion_ventanas() -> void:
	var lista_ventanas: Array[DebugWindow] = []
	for w in [win_jugador, win_fisicas, win_escenario, win_enemigo, win_audio, win_sistema]:
		if w != null:
			lista_ventanas.append(w)
	window_manager.inicializar(lista_ventanas)
