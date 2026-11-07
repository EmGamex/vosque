@tool
class_name TestGestorAudioUI
extends McpTestSuite

## Pruebas unitarias para GestorAudioUI y su integración con menús.

func suite_name() -> String:
	return "gestor_audio_ui"


func test_instanciacion_y_reproductores() -> void:
	var script: GDScript = load("res://scripts/core/gestor_audio_ui.gd")
	var gestor: Node = script.new()
	assert_true(gestor != null, "GestorAudioUI debe instanciarse")

	gestor._ready()

	assert_eq(gestor.process_mode, Node.PROCESS_MODE_ALWAYS, "Debe tener PROCESS_MODE_ALWAYS")

	var player_cursor: AudioStreamPlayer = gestor.get_node_or_null("PlayerCursor") as AudioStreamPlayer
	var player_accion: AudioStreamPlayer = gestor.get_node_or_null("PlayerAccion") as AudioStreamPlayer
	var player_accion_aux: AudioStreamPlayer = gestor.get_node_or_null("PlayerAccionAux") as AudioStreamPlayer

	assert_true(player_cursor != null, "Debe existir PlayerCursor")
	assert_true(player_accion != null, "Debe existir PlayerAccion")
	assert_true(player_accion_aux != null, "Debe existir PlayerAccionAux")

	assert_eq(player_cursor.bus, &"sfx", "PlayerCursor debe usar el bus sfx")
	assert_eq(player_accion.bus, &"sfx", "PlayerAccion debe usar el bus sfx")
	assert_eq(player_accion_aux.bus, &"sfx", "PlayerAccionAux debe usar el bus sfx")
	assert_eq(player_cursor.process_mode, Node.PROCESS_MODE_ALWAYS, "PlayerCursor debe ser PROCESS_MODE_ALWAYS")
	assert_eq(player_accion.process_mode, Node.PROCESS_MODE_ALWAYS, "PlayerAccion debe ser PROCESS_MODE_ALWAYS")
	assert_eq(player_accion_aux.process_mode, Node.PROCESS_MODE_ALWAYS, "PlayerAccionAux debe ser PROCESS_MODE_ALWAYS")

	# Probar llamadas a los métodos públicos para asegurar que no lancen errores
	gestor.reproducir_menu_seleccionar()
	assert_true(player_cursor.stream != null, "PlayerCursor debe tener stream asignado para seleccionar")

	gestor.reproducir_menu_aceptar()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para aceptar")

	gestor.reproducir_menu_retroceder()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para retroceder")

	gestor.reproducir_pausa_abrir()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para abrir pausa")

	gestor.reproducir_pausa_navegar()
	assert_true(player_cursor.stream != null, "PlayerCursor debe tener stream asignado para navegar pausa")

	gestor.reproducir_pausa_aceptar()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para aceptar pausa")

	gestor.reproducir_pausa_cerrar()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para cerrar pausa")

	gestor.free()


func test_recurso_configuracion_audio_ui() -> void:
	var cfg := ConfiguracionAudioUI.new()
	assert_true(cfg != null, "ConfiguracionAudioUI debe instanciarse")
	assert_eq(cfg.nombre_bus, &"sfx")
	assert_true(cfg.habilitar_variacion_pitch_cursor)
	assert_true(is_equal_approx(cfg.pitch_cursor_min, 0.96))
	assert_true(is_equal_approx(cfg.pitch_cursor_max, 1.04))
	assert_true(is_equal_approx(cfg.volumen_general_db, 0.0))

	var emitido := {"cambio": false}
	cfg.changed.connect(func(): emitido["cambio"] = true)
	cfg.volumen_general_db = -3.0
	assert_true(emitido["cambio"], "Modificar propiedades debe emitir changed")


func test_preset_config_audio_ui_defecto() -> void:
	var preset = load("res://recursos/audio/config_audio_ui_defecto.tres")
	assert_true(preset != null, "config_audio_ui_defecto.tres debe existir")
	assert_true(preset is ConfiguracionAudioUI, "El preset debe ser ConfiguracionAudioUI")
	var cfg := preset as ConfiguracionAudioUI
	assert_true(cfg.stream_menu_seleccionar != null)
	assert_true(cfg.stream_menu_aceptar != null)
	assert_true(cfg.stream_menu_retroceder != null)
	assert_true(cfg.stream_pausa_abrir != null)
	assert_true(cfg.stream_pausa_navegar != null)
	assert_true(cfg.stream_pausa_aceptar != null)
	assert_true(cfg.stream_pausa_cerrar != null)


func test_escena_gestor_audio_ui_estructura() -> void:
	var escena: PackedScene = load("res://escenas/gestor_audio_ui.tscn")
	assert_true(escena != null, "gestor_audio_ui.tscn debe existir")

	var instancia := escena.instantiate()
	assert_true(instancia != null, "gestor_audio_ui.tscn debe poder instanciarse")
	assert_true(instancia is ControladorAudioUI, "Raiz debe tener script ControladorAudioUI")
	assert_eq(instancia.process_mode, Node.PROCESS_MODE_ALWAYS)

	var p_cursor := instancia.get_node_or_null("PlayerCursor") as AudioStreamPlayer
	var p_accion := instancia.get_node_or_null("PlayerAccion") as AudioStreamPlayer
	var p_aux := instancia.get_node_or_null("PlayerAccionAux") as AudioStreamPlayer

	assert_true(p_cursor != null, "Debe existir PlayerCursor")
	assert_true(p_accion != null, "Debe existir PlayerAccion")
	assert_true(p_aux != null, "Debe existir PlayerAccionAux")

	assert_eq(p_cursor.bus, &"sfx")
	assert_eq(p_accion.bus, &"sfx")
	assert_eq(p_aux.bus, &"sfx")

	instancia.free()


func test_autoload_registrado() -> void:
	assert_true(ProjectSettings.has_setting("autoload/GestorAudioUI"), "GestorAudioUI debe estar registrado como Autoload")
	var path_autoload: String = ProjectSettings.get_setting("autoload/GestorAudioUI")
	assert_true(path_autoload.contains("res://escenas/gestor_audio_ui.tscn"), "El Autoload GestorAudioUI debe apuntar a res://escenas/gestor_audio_ui.tscn")


func test_pitch_jitter_y_zero_cutoff() -> void:
	var escena: PackedScene = load("res://escenas/gestor_audio_ui.tscn")
	var gestor: ControladorAudioUI = escena.instantiate() as ControladorAudioUI
	gestor._ready()

	# Pitch jitter
	gestor.reproducir_menu_seleccionar()
	var p_cursor := gestor.get_node("PlayerCursor") as AudioStreamPlayer
	assert_true(p_cursor.pitch_scale >= 0.95 and p_cursor.pitch_scale <= 1.05, "Pitch scale debe estar dentro del rango")

	# Zero-cutoff
	var p_aux := gestor.get_node("PlayerAccionAux") as AudioStreamPlayer

	# Disparamos dos acciones seguidas
	gestor.reproducir_pausa_aceptar()
	gestor.reproducir_pausa_cerrar()
	assert_true(p_aux.stream != null, "PlayerAccionAux debe recibir el stream secundario sin cortar el primero")

	gestor.free()


func test_vincular_boton() -> void:
	var escena: PackedScene = load("res://escenas/gestor_audio_ui.tscn")
	var gestor: ControladorAudioUI = escena.instantiate() as ControladorAudioUI
	gestor._ready()

	var btn := Button.new()
	gestor.vincular_boton(btn, false)
	assert_true(btn.focus_entered.is_connected(gestor.reproducir_evento.bind(ControladorAudioUI.EventoUI.MENU_SELECCIONAR)) or btn.focus_entered.get_connections().size() > 0)
	assert_true(btn.pressed.get_connections().size() > 0)

	btn.free()
	gestor.free()
