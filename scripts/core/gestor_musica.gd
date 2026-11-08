@tool
class_name ControladorMusica
extends Node

## Singleton Autoload GestorMusica (res://escenas/gestor_musica.tscn).
## Administra la máquina de estados musicales, transiciones inmediatas con
## AudioStreamInteractive, atenuación aditiva en pausa y efecto Nightmare Decay.

enum EstadoMusical {
	SILENCIO,
	MENU_TUTORIAL,
	SUPERVIVENCIA,
	GAME_OVER
}

# --- Constantes de Configuración por Defecto y API de Godot ---
const PARAM_SWITCH_TO_CLIP: StringName = &"parameters/switch_to_clip"
const BUS_MUSICA_DEFECTO: StringName = &"musica"
const PITCH_NORMAL: float = 1.0
const VOLUMEN_BASE_DEFECTO_DB: float = -8.0
const VELOCIDAD_SUAVIZADO_DEFECTO_DB: float = 12.0

@export var config: ConfiguracionMusica = preload("res://recursos/audio/config_musica_defecto.tres"):
	set(nueva_configuracion):
		if config != null and config.changed.is_connected(_on_config_changed):
			config.changed.disconnect(_on_config_changed)
		config = nueva_configuracion
		if config != null and not config.changed.is_connected(_on_config_changed):
			config.changed.connect(_on_config_changed)
		_aplicar_configuracion_en_vivo()

@onready var reproductor: AudioStreamPlayer = $ReproductorInteractivo

var estado_actual: EstadoMusical = EstadoMusical.SILENCIO
var clip_actual: StringName = &""

var _bus_index: int = -1
var _en_pausa: bool = false
var _volumen_actual_db: float = VOLUMEN_BASE_DEFECTO_DB


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_actualizar_referencias_bus()

	if config != null and not config.changed.is_connected(_on_config_changed):
		config.changed.connect(_on_config_changed)

	_volumen_actual_db = config.volumen_base_db if config != null else VOLUMEN_BASE_DEFECTO_DB
	_aplicar_volumen_bus(_volumen_actual_db)

	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio != null:
		_asegurar_reproductor()
		reproductor_audio.pitch_scale = PITCH_NORMAL


func _process(delta: float) -> void:
	var objetivo := _calcular_volumen_objetivo()
	if not is_equal_approx(_volumen_actual_db, objetivo):
		var velocidad_suavizado: float = config.velocidad_suavizado_db if config != null else VELOCIDAD_SUAVIZADO_DEFECTO_DB
		_volumen_actual_db = move_toward(_volumen_actual_db, objetivo, velocidad_suavizado * delta)
		_aplicar_volumen_bus(_volumen_actual_db)


func reproducir_menu_o_tutorial() -> void:
	var reproductor_audio := _obtener_reproductor()
	var ya_reproduciendo: bool = reproductor_audio.playing if reproductor_audio else false
	print("[DEBUG-MUSICA %d ms] reproducir_menu_o_tutorial() | estado=%s | playing=%s" % [
		Time.get_ticks_msec(), estado_actual, ya_reproduciendo
	])
	if reproductor_audio == null or config == null:
		return

	# Si ya está activo en menú/tutorial y reproduciendo sin pausa, no interrumpir ni reiniciar
	if reproductor_audio.playing and not reproductor_audio.stream_paused and (estado_actual == EstadoMusical.MENU_TUTORIAL or clip_actual == config.clip_menu_tutorial):
		return

	_asegurar_reproductor()
	reproductor_audio.stream_paused = false
	reproductor_audio.pitch_scale = PITCH_NORMAL
	_set_reverb_enabled(false)

	_conmutar_clip(config.clip_menu_tutorial)
	estado_actual = EstadoMusical.MENU_TUTORIAL
	clip_actual = config.clip_menu_tutorial


func transicionar_a_supervivencia() -> void:
	print("[DEBUG-MUSICA %d ms] transicionar_a_supervivencia() invocado" % Time.get_ticks_msec())
	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio == null or config == null:
		return

	if estado_actual == EstadoMusical.SUPERVIVENCIA and reproductor_audio.playing and not reproductor_audio.stream_paused:
		return

	_asegurar_reproductor()
	reproductor_audio.stream_paused = false
	_conmutar_clip(config.clip_supervivencia)
	estado_actual = EstadoMusical.SUPERVIVENCIA
	clip_actual = config.clip_supervivencia


func establecer_pausa(en_pausa: bool) -> void:
	_en_pausa = en_pausa


func detener_por_jumpscare() -> void:
	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio != null and not reproductor_audio.stream_paused:
		if reproductor_audio.playing:
			reproductor_audio.stream_paused = true
		else:
			reproductor_audio.stop()

	estado_actual = EstadoMusical.SILENCIO
	clip_actual = &""


func activar_modo_game_over() -> void:
	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio == null or config == null:
		return

	estado_actual = EstadoMusical.GAME_OVER
	_asegurar_reproductor()
	reproductor_audio.pitch_scale = config.pitch_game_over
	_set_reverb_enabled(true)

	if reproductor_audio.stream_paused:
		# Si venía pausado del jumpscare, despausar en seco para continuar
		# exactamente en el compás y segundo donde quedó, sin reiniciar el clip.
		reproductor_audio.stream_paused = false
	elif not reproductor_audio.playing:
		# Fallback: si no estaba reproduciendo, iniciar supervivencia
		clip_actual = config.clip_supervivencia
		reproductor_audio.play()
		reproductor_audio.set(PARAM_SWITCH_TO_CLIP, config.clip_supervivencia)


func restaurar_parametros_normales() -> void:
	_en_pausa = false
	_set_reverb_enabled(false)
	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio != null:
		reproductor_audio.stream_paused = false
		reproductor_audio.pitch_scale = PITCH_NORMAL
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
		return VOLUMEN_BASE_DEFECTO_DB
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
	var nombre_bus := config.nombre_bus if config != null else BUS_MUSICA_DEFECTO
	_bus_index = AudioServer.get_bus_index(nombre_bus)


func _set_reverb_enabled(habilitado: bool) -> void:
	if _bus_index == -1:
		_actualizar_referencias_bus()
	if _bus_index == -1:
		return

	for indice_efecto in AudioServer.get_bus_effect_count(_bus_index):
		if AudioServer.get_bus_effect(_bus_index, indice_efecto) is AudioEffectReverb:
			AudioServer.set_bus_effect_enabled(_bus_index, indice_efecto, habilitado)
			break


func _obtener_reproductor() -> AudioStreamPlayer:
	if reproductor == null:
		reproductor = get_node_or_null("ReproductorInteractivo") as AudioStreamPlayer
	return reproductor


func _asegurar_reproductor() -> void:
	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio == null or config == null:
		return

	if config.stream_interactivo != null and reproductor_audio.stream != config.stream_interactivo:
		reproductor_audio.stream = config.stream_interactivo
	if not config.nombre_bus.is_empty() and reproductor_audio.bus != config.nombre_bus:
		reproductor_audio.bus = config.nombre_bus


func _conmutar_clip(nombre_clip: StringName) -> void:
	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio == null:
		return
	if not reproductor_audio.playing:
		reproductor_audio.play()
	if clip_actual != nombre_clip:
		reproductor_audio.set(PARAM_SWITCH_TO_CLIP, nombre_clip)


func _on_config_changed() -> void:
	_aplicar_configuracion_en_vivo()


func _aplicar_configuracion_en_vivo() -> void:
	_actualizar_referencias_bus()
	_asegurar_reproductor()
	var reproductor_audio := _obtener_reproductor()
	if reproductor_audio != null and estado_actual == EstadoMusical.GAME_OVER and config != null:
		reproductor_audio.pitch_scale = config.pitch_game_over
