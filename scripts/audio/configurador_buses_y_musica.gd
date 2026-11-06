@tool
class_name ConfiguradorBusesYMusica
extends RefCounted

## Utilidad de construccion y calibracion de buses de audio y AudioStreamInteractive.

const RUTA_BUS_LAYOUT := "res://default_bus_layout.tres"
const RUTA_MUSICA_INTERACTIVA := "res://sonido/musica/musica_interactiva.tres"
const RUTA_OGG_TUTORIAL := "res://sonido/musica/Pac Man World 2 Soundtrack - Night Crawling - BadBalloon.ogg"
const RUTA_OGG_SUPERVIVENCIA := "res://sonido/musica/Pac Man World 2 Soundtrack - Haunted Boardwalk - BadBalloon.ogg"


static func configurar_bus_layout(incluir_lpf_master: bool = true) -> Error:
	var layout: AudioBusLayout = load(RUTA_BUS_LAYOUT)
	if layout != null:
		AudioServer.set_bus_layout(layout)

	# Asegurar los 5 buses canonicos
	var nombres_esperados: Array[StringName] = [&"Master", &"Ambiente", &"sfx", &"Criatura", &"musica"]
	var volumenes_db: Dictionary = {
		&"Master": 0.0,
		&"Ambiente": -6.0,
		&"sfx": -2.0,
		&"Criatura": 1.0,
		&"musica": -8.0
	}

	for nombre in nombres_esperados:
		if nombre == &"Master":
			continue
		var idx := AudioServer.get_bus_index(nombre)
		if idx == -1:
			AudioServer.add_bus()
			idx = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(idx, nombre)
		AudioServer.set_bus_send(idx, &"Master")
		AudioServer.set_bus_volume_db(idx, volumenes_db.get(nombre, 0.0))

	# Reverb en bus 'musica' en slot 0 deshabilitado
	var idx_musica := AudioServer.get_bus_index(&"musica")
	if idx_musica != -1:
		var tiene_reverb := false
		for i in range(AudioServer.get_bus_effect_count(idx_musica)):
			if AudioServer.get_bus_effect(idx_musica, i) is AudioEffectReverb:
				tiene_reverb = true
				AudioServer.set_bus_effect_enabled(idx_musica, i, false)
				break
		if not tiene_reverb:
			var reverb := AudioEffectReverb.new()
			reverb.resource_name = "ReverbGameOver"
			AudioServer.add_bus_effect(idx_musica, reverb, 0)
			AudioServer.set_bus_effect_enabled(idx_musica, 0, false)

	# LowPassFilter en Master (bypass)
	if incluir_lpf_master:
		var idx_master := AudioServer.get_bus_index(&"Master")
		var tiene_lpf := false
		for i in range(AudioServer.get_bus_effect_count(idx_master)):
			if AudioServer.get_bus_effect(idx_master, i) is AudioEffectLowPassFilter:
				tiene_lpf = true
				AudioServer.set_bus_effect_enabled(idx_master, i, false)
				break
		if not tiene_lpf:
			var lpf := AudioEffectLowPassFilter.new()
			lpf.resource_name = "FiltroFatiga"
			lpf.cutoff_hz = 800.0
			AudioServer.add_bus_effect(idx_master, lpf, 0)
			AudioServer.set_bus_effect_enabled(idx_master, 0, false)

	var nuevo_layout := AudioServer.generate_bus_layout()
	return ResourceSaver.save(nuevo_layout, RUTA_BUS_LAYOUT)


static func configurar_musica_interactiva() -> Error:
	var stream_tutorial: AudioStream = load(RUTA_OGG_TUTORIAL)
	var stream_supervivencia: AudioStream = load(RUTA_OGG_SUPERVIVENCIA)

	if stream_tutorial == null or stream_supervivencia == null:
		push_error("No se pudieron cargar los streams OGG requeridos")
		return ERR_FILE_NOT_FOUND

	var interactivo := AudioStreamInteractive.new()
	interactivo.clip_count = 2
	interactivo.initial_clip = 0

	# Clip 0
	interactivo.set_clip_name(0, &"menu_tutorial")
	interactivo.set_clip_stream(0, stream_tutorial)
	interactivo.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_DISABLED)

	# Clip 1
	interactivo.set_clip_name(1, &"supervivencia")
	interactivo.set_clip_stream(1, stream_supervivencia)
	interactivo.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_DISABLED)

	# Transicion 1: menu_tutorial -> supervivencia (NEXT_BEAT, START, FADE_DISABLED, 0.0)
	interactivo.add_transition(
		0,
		1,
		AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BEAT,
		AudioStreamInteractive.TRANSITION_TO_TIME_START,
		AudioStreamInteractive.FADE_DISABLED,
		0.0
	)

	# Transicion 2: CLIP_ANY -> menu_tutorial (IMMEDIATE, START, FADE_DISABLED, 0.0)
	interactivo.add_transition(
		AudioStreamInteractive.CLIP_ANY,
		0,
		AudioStreamInteractive.TRANSITION_FROM_TIME_IMMEDIATE,
		AudioStreamInteractive.TRANSITION_TO_TIME_START,
		AudioStreamInteractive.FADE_DISABLED,
		0.0
	)

	return ResourceSaver.save(interactivo, RUTA_MUSICA_INTERACTIVA)
