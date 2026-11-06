@tool
class_name TestGestorMusica
extends McpTestSuite

## Suite de verificacion para los buses de audio y AudioStreamInteractive (Issue #26).

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
