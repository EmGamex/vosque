@tool
class_name ControladorMusica
extends Node

## Singleton Autoload GestorMusica (res://escenas/gestor_musica.tscn).
## Administra la máquina de estados musicales, transiciones NEXT_BEAT con
## AudioStreamInteractive, atenuación aditiva en pausa y efecto Nightmare Decay.

enum EstadoMusical {
	SILENCIO,
	MENU_TUTORIAL,
	SUPERVIVENCIA,
	GAME_OVER
}

@export var config: ConfiguracionMusica = preload("res://recursos/audio/config_musica_defecto.tres"):
	set(val):
		if config != null and config.changed.is_connected(_on_config_changed):
			config.changed.disconnect(_on_config_changed)
		config = val
		if config != null and not config.changed.is_connected(_on_config_changed):
			config.changed.connect(_on_config_changed)
		_aplicar_configuracion_en_vivo()

@onready var reproductor: AudioStreamPlayer = $ReproductorInteractivo

var estado_actual: EstadoMusical = EstadoMusical.SILENCIO
var clip_actual: StringName = &""

var _bus_index: int = -1
var _en_pausa: bool = false
var _volumen_actual_db: float = -8.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_actualizar_referencias_bus()

	if config != null and not config.changed.is_connected(_on_config_changed):
		config.changed.connect(_on_config_changed)

	_volumen_actual_db = config.volumen_base_db if config != null else -8.0
	_aplicar_volumen_bus(_volumen_actual_db)

	var rep := _obtener_reproductor()
	if rep != null:
		if config != null and config.stream_interactivo != null:
			rep.stream = config.stream_interactivo
		if config != null and not config.nombre_bus.is_empty():
			rep.bus = config.nombre_bus
		rep.pitch_scale = 1.0


func _process(delta: float) -> void:
	var objetivo := _calcular_volumen_objetivo()
	if not is_equal_approx(_volumen_actual_db, objetivo):
		var vel: float = config.velocidad_suavizado_db if config != null else 12.0
		_volumen_actual_db = move_toward(_volumen_actual_db, objetivo, vel * delta)
		_aplicar_volumen_bus(_volumen_actual_db)


func reproducir_menu_o_tutorial() -> void:
	var rep := _obtener_reproductor()
	if rep == null or config == null:
		return

	# Si ya está activo en menú/tutorial, no interrumpir ni reiniciar
	if rep.playing and estado_actual == EstadoMusical.MENU_TUTORIAL:
		return

	_asegurar_reproductor()
	rep.pitch_scale = 1.0
	_set_reverb_enabled(false)

	_conmutar_clip(config.clip_menu_tutorial)
	estado_actual = EstadoMusical.MENU_TUTORIAL
	clip_actual = config.clip_menu_tutorial


func transicionar_a_supervivencia() -> void:
	var rep := _obtener_reproductor()
	if rep == null or config == null:
		return

	if estado_actual == EstadoMusical.SUPERVIVENCIA:
		return

	_asegurar_reproductor()
	_conmutar_clip(config.clip_supervivencia)
	estado_actual = EstadoMusical.SUPERVIVENCIA
	clip_actual = config.clip_supervivencia


func establecer_pausa(en_pausa: bool) -> void:
	_en_pausa = en_pausa


func detener_por_jumpscare() -> void:
	var rep := _obtener_reproductor()
	if rep != null:
		rep.stop()
	estado_actual = EstadoMusical.SILENCIO
	clip_actual = &""


func activar_modo_game_over() -> void:
	var rep := _obtener_reproductor()
	if rep == null or config == null:
		return

	estado_actual = EstadoMusical.GAME_OVER
	clip_actual = config.clip_supervivencia
	_asegurar_reproductor()
	rep.pitch_scale = config.pitch_game_over
	_set_reverb_enabled(true)
	_conmutar_clip(config.clip_supervivencia)


func restaurar_parametros_normales() -> void:
	_en_pausa = false
	_set_reverb_enabled(false)
	var rep := _obtener_reproductor()
	if rep != null:
		rep.pitch_scale = 1.0
	if config != null:
		_volumen_actual_db = config.volumen_base_db
		_aplicar_volumen_bus(_volumen_actual_db)
		_conmutar_clip(config.clip_menu_tutorial)
		estado_actual = EstadoMusical.MENU_TUTORIAL
		clip_actual = config.clip_menu_tutorial


# --- Getters y Telemetría ---

func get_estado_actual() -> EstadoMusical:
	return estado_actual


func get_volumen_actual_db() -> float:
	return _volumen_actual_db


func is_en_pausa() -> bool:
	return _en_pausa


func get_clip_activo() -> StringName:
	return clip_actual


# --- Métodos Privados y Auxiliares ---

func _calcular_volumen_objetivo() -> float:
	if config == null:
		return -8.0
	var objetivo := config.volumen_base_db
	if _en_pausa:
		objetivo += config.atenuacion_pausa_db
	return objetivo


func _aplicar_volumen_bus(vol_db: float) -> void:
	if _bus_index == -1:
		_actualizar_referencias_bus()
	if _bus_index != -1:
		AudioServer.set_bus_volume_db(_bus_index, vol_db)


func _actualizar_referencias_bus() -> void:
	var nombre := config.nombre_bus if config != null else &"musica"
	_bus_index = AudioServer.get_bus_index(nombre)


func _set_reverb_enabled(enabled: bool) -> void:
	if _bus_index == -1:
		_actualizar_referencias_bus()
	if _bus_index != -1:
		for i in range(AudioServer.get_bus_effect_count(_bus_index)):
			if AudioServer.get_bus_effect(_bus_index, i) is AudioEffectReverb:
				AudioServer.set_bus_effect_enabled(_bus_index, i, enabled)
				break


func _obtener_reproductor() -> AudioStreamPlayer:
	if reproductor != null:
		return reproductor
	reproductor = get_node_or_null("ReproductorInteractivo") as AudioStreamPlayer
	return reproductor


func _asegurar_reproductor() -> void:
	var rep := _obtener_reproductor()
	if rep == null:
		return
	if config != null and config.stream_interactivo != null:
		if rep.stream != config.stream_interactivo:
			rep.stream = config.stream_interactivo
	if config != null and not config.nombre_bus.is_empty():
		if rep.bus != config.nombre_bus:
			rep.bus = config.nombre_bus


func _conmutar_clip(nombre_clip: StringName) -> void:
	var rep := _obtener_reproductor()
	if rep == null:
		return
	if not rep.playing:
		rep.play()
	rep.set(&"parameters/switch_to_clip", nombre_clip)


func _on_config_changed() -> void:
	_aplicar_configuracion_en_vivo()


func _aplicar_configuracion_en_vivo() -> void:
	_actualizar_referencias_bus()
	_asegurar_reproductor()
	var rep := _obtener_reproductor()
	if rep != null and estado_actual == EstadoMusical.GAME_OVER and config != null:
		rep.pitch_scale = config.pitch_game_over
