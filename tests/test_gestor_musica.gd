@tool
class_name TestGestorMusica
extends McpTestSuite

## Suite de verificacion para los buses de audio, AudioStreamInteractive (Issue #26)
## y el recurso ConfiguracionMusica con singleton GestorMusica (Issue #27).

func suite_name() -> String:
	return "gestor_musica"


func suite_setup(_ctx: Dictionary = {}) -> void:
	# Asegurar la generacion de recursos nativos via Godot Engine
	var err_layout := ConfiguradorBusesYMusica.configurar_bus_layout(true)
	if err_layout != OK:
		fail_setup("Fallo al configurar bus layout: %s" % err_layout)
		return
	var err_musica := ConfiguradorBusesYMusica.configurar_musica_interactiva()
	if err_musica != OK:
		fail_setup("Fallo al configurar musica interactiva: %s" % err_musica)
		return


func test_layout_cinco_buses() -> void:
	var layout: AudioBusLayout = load("res://default_bus_layout.tres")
	assert_true(layout != null, "El archivo default_bus_layout.tres debe existir y cargar")

	AudioServer.set_bus_layout(layout)
	assert_eq(AudioServer.get_bus_count(), 5, "Deben existir exactamente 5 buses")

	var nombres: Array[StringName] = [&"Master", &"Ambiente", &"sfx", &"Criatura", &"musica"]
	for nombre in nombres:
		var idx := AudioServer.get_bus_index(nombre)
		assert_true(idx >= 0, "Debe existir el bus: %s" % nombre)
		if nombre != &"Master":
			assert_eq(AudioServer.get_bus_send(idx), &"Master", "El bus %s debe enrutar a Master" % nombre)


func test_efectos_en_buses() -> void:
	var idx_musica := AudioServer.get_bus_index(&"musica")
	assert_true(idx_musica >= 0, "El bus 'musica' debe existir")

	var effect_count := AudioServer.get_bus_effect_count(idx_musica)
	assert_true(effect_count >= 1, "El bus 'musica' debe tener al menos un efecto")

	var efecto := AudioServer.get_bus_effect(idx_musica, 0)
	assert_true(efecto is AudioEffectReverb, "El efecto en el slot 0 de 'musica' debe ser AudioEffectReverb")
	assert_false(AudioServer.is_bus_effect_enabled(idx_musica, 0), "El AudioEffectReverb debe estar deshabilitado por defecto")

	var idx_master := AudioServer.get_bus_index(&"Master")
	assert_true(idx_master >= 0, "El bus 'Master' debe existir")
	var lpf_efecto := AudioServer.get_bus_effect(idx_master, 0)
	assert_true(lpf_efecto is AudioEffectLowPassFilter, "El efecto en slot 0 de 'Master' debe ser AudioEffectLowPassFilter")
	assert_false(AudioServer.is_bus_effect_enabled(idx_master, 0), "El AudioEffectLowPassFilter en 'Master' debe estar deshabilitado por defecto")


func test_recurso_musica_interactiva() -> void:
	var res = load("res://sonido/musica/musica_interactiva.tres")
	assert_true(res != null, "musica_interactiva.tres debe existir")
	assert_true(res is AudioStreamInteractive, "El recurso debe ser AudioStreamInteractive")

	var asi: AudioStreamInteractive = res as AudioStreamInteractive
	assert_eq(asi.clip_count, 2, "Debe tener 2 clips configurados")
	assert_eq(asi.initial_clip, 0, "El clip inicial debe ser el 0")

	assert_eq(asi.get_clip_name(0), &"menu_tutorial", "Clip 0 debe llamarse 'menu_tutorial'")
	assert_true(asi.get_clip_stream(0) != null, "Clip 0 debe tener un AudioStream asignado")

	assert_eq(asi.get_clip_name(1), &"supervivencia", "Clip 1 debe llamarse 'supervivencia'")
	assert_true(asi.get_clip_stream(1) != null, "Clip 1 debe tener un AudioStream asignado")


func test_transiciones_metricas_interactivas() -> void:
	var asi: AudioStreamInteractive = load("res://sonido/musica/musica_interactiva.tres")
	assert_true(asi != null, "El recurso debe cargarse")

	# Transicion 0 -> 1 (menu_tutorial a supervivencia)
	assert_true(asi.has_transition(0, 1), "Debe existir transicion de clip 0 a clip 1")
	assert_eq(asi.get_transition_from_time(0, 1), AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BEAT, "From time debe ser NEXT_BEAT")
	assert_eq(asi.get_transition_to_time(0, 1), AudioStreamInteractive.TRANSITION_TO_TIME_START, "To time debe ser START")
	assert_eq(asi.get_transition_fade_mode(0, 1), AudioStreamInteractive.FADE_DISABLED, "Fade mode debe ser FADE_DISABLED")
	assert_true(is_equal_approx(asi.get_transition_fade_beats(0, 1), 0.0), "Fade beats debe ser 0.0")

	# Transicion CLIP_ANY (-1) -> 0 (hacia menu_tutorial)
	assert_true(asi.has_transition(AudioStreamInteractive.CLIP_ANY, 0), "Debe existir transicion comodin hacia clip 0")
	assert_eq(asi.get_transition_from_time(AudioStreamInteractive.CLIP_ANY, 0), AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE, "From time comodin debe ser IMMEDIATE")
	assert_eq(asi.get_transition_to_time(AudioStreamInteractive.CLIP_ANY, 0), AudioStreamInteractive.TRANSITION_TO_TIME_START, "To time comodin debe ser START")
	assert_eq(asi.get_transition_fade_mode(AudioStreamInteractive.CLIP_ANY, 0), AudioStreamInteractive.FADE_DISABLED, "Fade mode comodin debe ser FADE_DISABLED")
	assert_true(is_equal_approx(asi.get_transition_fade_beats(AudioStreamInteractive.CLIP_ANY, 0), 0.0), "Fade beats comodin debe ser 0.0")


# =========================================================================
# Casos de prueba Issue #27: Recurso ConfiguracionMusica y Autoload GestorMusica
# =========================================================================

func test_recurso_configuracion_musica() -> void:
	var config := ConfiguracionMusica.new()
	assert_true(config != null, "ConfiguracionMusica debe instanciarse")
	assert_eq(config.nombre_bus, &"musica", "El bus por defecto debe ser 'musica'")
	assert_eq(config.clip_menu_tutorial, &"menu_tutorial", "Clip menu/tutorial por defecto")
	assert_eq(config.clip_supervivencia, &"supervivencia", "Clip supervivencia por defecto")
	assert_true(is_equal_approx(config.volumen_base_db, -8.0), "Volumen base por defecto debe ser -8.0 dB")
	assert_true(is_equal_approx(config.velocidad_suavizado_db, 12.0), "Velocidad suavizado debe ser 12.0 dB/s")
	assert_true(is_equal_approx(config.atenuacion_pausa_db, -8.0), "Atenuacion de pausa debe ser -8.0 dB")
	assert_true(is_equal_approx(config.pitch_game_over, 0.65), "Pitch de game over debe ser 0.65")

	# Verificación de reactividad (emit_changed)
	var estado := {"signal_emitida": false}
	config.changed.connect(func(): estado["signal_emitida"] = true)
	config.volumen_base_db = -10.0
	assert_true(estado["signal_emitida"], "Modificar una propiedad exportada debe emitir la señal 'changed'")


func test_preset_config_musica_defecto() -> void:
	var preset = load("res://recursos/audio/config_musica_defecto.tres")
	assert_true(preset != null, "config_musica_defecto.tres debe existir")
	assert_true(preset is ConfiguracionMusica, "El preset debe ser de tipo ConfiguracionMusica")

	var config: ConfiguracionMusica = preset as ConfiguracionMusica
	assert_eq(config.nombre_bus, &"musica")
	assert_eq(config.clip_menu_tutorial, &"menu_tutorial")
	assert_eq(config.clip_supervivencia, &"supervivencia")
	assert_true(is_equal_approx(config.volumen_base_db, -8.0))
	assert_true(is_equal_approx(config.atenuacion_pausa_db, -8.0))
	assert_true(is_equal_approx(config.pitch_game_over, 0.65))
	assert_true(config.stream_interactivo != null, "El preset debe tener stream_interactivo cargado")


func test_escena_gestor_musica_estructura() -> void:
	var escena: PackedScene = load("res://escenas/gestor_musica.tscn")
	assert_true(escena != null, "La escena gestor_musica.tscn debe existir")

	var instancia := escena.instantiate()
	assert_true(instancia != null, "La escena debe poder instanciarse")
	assert_true(instancia is ControladorMusica, "La raiz de gestor_musica.tscn debe tener script ControladorMusica")
	assert_eq(instancia.process_mode, Node.PROCESS_MODE_ALWAYS, "process_mode debe ser PROCESS_MODE_ALWAYS")

	var rep: AudioStreamPlayer = instancia.get_node_or_null("ReproductorInteractivo") as AudioStreamPlayer
	assert_true(rep != null, "Debe existir el nodo hijo ReproductorInteractivo")
	assert_eq(rep.bus, &"musica", "ReproductorInteractivo debe estar asignado al bus 'musica'")
	assert_true(rep.stream != null, "ReproductorInteractivo debe tener stream interactivo asignado")

	instancia.free()


func test_autoload_registrado() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GestorMusica"), "GestorMusica debe estar registrado como Autoload")
	var path_autoload: String = ProjectSettings.get_setting("autoload/GestorMusica")
	assert_true(path_autoload.contains("res://escenas/gestor_musica.tscn"), "El Autoload GestorMusica debe apuntar a res://escenas/gestor_musica.tscn")


func test_controlador_musica_maquina_estados_y_metodos() -> void:
	var escena: PackedScene = load("res://escenas/gestor_musica.tscn")
	var gestor: ControladorMusica = escena.instantiate() as ControladorMusica
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(gestor)

	# 1. Menú o Tutorial
	gestor.reproducir_menu_o_tutorial()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)
	assert_eq(gestor.get_clip_activo(), &"menu_tutorial")

	# Llamada no destructiva: debe mantenerse en MENU_TUTORIAL
	gestor.reproducir_menu_o_tutorial()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)

	# 2. Conmutar a Supervivencia
	gestor.transicionar_a_supervivencia()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.SUPERVIVENCIA)
	assert_eq(gestor.get_clip_activo(), &"supervivencia")

	# 3. Pausa y suavizado de atenuación
	gestor.establecer_pausa(true)
	assert_true(gestor.is_en_pausa())
	gestor._process(1.0)
	var vol_en_pausa := gestor.get_volumen_actual_db()
	assert_true(vol_en_pausa <= -8.0, "Durante la pausa el volumen debe atenuarse")

	gestor.establecer_pausa(false)
	assert_false(gestor.is_en_pausa())
	gestor._process(1.0)
	assert_true(gestor.get_volumen_actual_db() >= vol_en_pausa, "Al despausar el volumen debe restituirse gradualmente")

	# 4. Detener por Jumpscare (0 ms instantaneo)
	gestor.detener_por_jumpscare()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.SILENCIO)

	# 5. Activar Game Over (Nightmare Decay)
	gestor.activar_modo_game_over()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.GAME_OVER)
	assert_true(is_equal_approx(gestor.reproductor.pitch_scale, 0.65), "En Game Over el pitch_scale debe ser 0.65")
	var idx_musica := AudioServer.get_bus_index(&"musica")
	assert_true(AudioServer.is_bus_effect_enabled(idx_musica, 0), "En Game Over el Reverb del bus 'musica' debe estar habilitado")

	# 6. Restaurar parámetros normales
	gestor.restaurar_parametros_normales()
	assert_true(is_equal_approx(gestor.reproductor.pitch_scale, 1.0), "Al restaurar, el pitch_scale debe volver a 1.0")
	assert_false(AudioServer.is_bus_effect_enabled(idx_musica, 0), "Al restaurar, el Reverb debe volver a deshabilitarse")
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)

	if tree != null and tree.root != null and gestor.get_parent() == tree.root:
		tree.root.remove_child(gestor)
	gestor.free()


# =========================================================================
# Casos de prueba Issue #28: Conexión de eventos de gameplay, Nightmare Decay
# y controles del Menú Debug (F3)
# =========================================================================

func test_debug_system_controller_audio() -> void:
	var escena_gestor: PackedScene = load("res://escenas/gestor_musica.tscn")
	var gestor: ControladorMusica = escena_gestor.instantiate() as ControladorMusica
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(gestor)

	var ctrl := DebugSystemController.new()

	# Probar forzar clips y estados
	ctrl.forzar_musica_menu(gestor)
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)

	ctrl.forzar_musica_supervivencia(gestor)
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.SUPERVIVENCIA)

	ctrl.forzar_corte_jumpscare(gestor)
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.SILENCIO)

	ctrl.forzar_modo_game_over(gestor)
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.GAME_OVER)

	ctrl.restaurar_audio_normal(gestor)
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)

	# Probar telemetría
	var telem := ctrl.obtener_telemetria_musica(gestor)
	assert_eq(telem.get("estado"), "MENU_TUTORIAL")
	assert_eq(telem.get("clip"), "menu_tutorial")

	# Probar sliders de calibración
	var cfg: ConfiguracionMusica = gestor.config
	ctrl.set_volumen_base(-12.0, cfg, gestor)
	assert_true(is_equal_approx(cfg.volumen_base_db, -12.0))

	ctrl.set_atenuacion_pausa(-14.0, cfg, gestor)
	assert_true(is_equal_approx(cfg.atenuacion_pausa_db, -14.0))

	ctrl.set_pitch_game_over(0.55, cfg, gestor)
	assert_true(is_equal_approx(cfg.pitch_game_over, 0.55))

	# Restaurar valores por defecto para no contaminar tests
	ctrl.set_volumen_base(-8.0, cfg, gestor)
	ctrl.set_atenuacion_pausa(-8.0, cfg, gestor)
	ctrl.set_pitch_game_over(0.65, cfg, gestor)

	if tree != null and tree.root != null and gestor.get_parent() == tree.root:
		tree.root.remove_child(gestor)
	gestor.free()


func test_gameplay_senales_e_integracion_audio() -> void:
	var escena_gestor: PackedScene = load("res://escenas/gestor_musica.tscn")
	var gestor: ControladorMusica = escena_gestor.instantiate() as ControladorMusica
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null and tree.root != null:
		tree.root.add_child(gestor)

	# 1. Menú Inicio: invoca reproducir_menu_o_tutorial()
	gestor.detener_por_jumpscare()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.SILENCIO)
	# Simulamos el callback que ejecuta MenuInicio
	gestor.reproducir_menu_o_tutorial()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)
	assert_eq(gestor.get_clip_activo(), &"menu_tutorial")

	# 2. Maain._ready() no-destructivo
	gestor.reproducir_menu_o_tutorial()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)

	# 3. Nota 1 recolectada: transición a supervivencia
	gestor.transicionar_a_supervivencia()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.SUPERVIVENCIA)
	assert_eq(gestor.get_clip_activo(), &"supervivencia")

	# 4. Pausa en GestorDeEscenas: atenuación aditiva
	gestor.establecer_pausa(true)
	assert_true(gestor.is_en_pausa())
	gestor.establecer_pausa(false)
	assert_false(gestor.is_en_pausa())

	# 5. Jumpscare en Enemigo / Maain: corte seco a 0 ms
	gestor.detener_por_jumpscare()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.SILENCIO)

	# 6. Pantalla GameOver: modo Nightmare Decay
	gestor.activar_modo_game_over()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.GAME_OVER)
	assert_true(is_equal_approx(gestor.reproductor.pitch_scale, 0.65))
	var idx_musica := AudioServer.get_bus_index(&"musica")
	assert_true(AudioServer.is_bus_effect_enabled(idx_musica, 0))

	# 7. GameOver Reintentar / Volver al Menú: restaurar_parametros_normales()
	gestor.restaurar_parametros_normales()
	assert_eq(gestor.get_estado_actual(), ControladorMusica.EstadoMusical.MENU_TUTORIAL)
	assert_true(is_equal_approx(gestor.reproductor.pitch_scale, 1.0))
	assert_false(AudioServer.is_bus_effect_enabled(idx_musica, 0))

	if tree != null and tree.root != null and gestor.get_parent() == tree.root:
		tree.root.remove_child(gestor)
	gestor.free()
