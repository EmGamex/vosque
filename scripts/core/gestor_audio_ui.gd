@tool
class_name ControladorAudioUI
extends Node

## Singleton Autoload GestorAudioUI (res://escenas/gestor_audio_ui.tscn).
## Administra la reproducción de efectos de sonido (SFX) para menús y elementos de interfaz.
## Se ejecuta siempre (PROCESS_MODE_ALWAYS) y envía el audio al bus configurado (por defecto "sfx").

enum EventoUI {
	MENU_SELECCIONAR,
	MENU_ACEPTAR,
	MENU_RETROCEDER,
	PAUSA_ABRIR,
	PAUSA_NAVEGAR,
	PAUSA_ACEPTAR,
	PAUSA_CERRAR,
}

const RUTA_CONFIG_DEFECTO: String = "res://recursos/audio/config_audio_ui_defecto.tres"
const NOMBRE_AUTOLOAD: StringName = &"GestorAudioUI"
const NOMBRE_BUS_DEFECTO: StringName = &"sfx"

const NOMBRE_PLAYER_CURSOR: StringName = &"PlayerCursor"
const NOMBRE_PLAYER_ACCION: StringName = &"PlayerAccion"
const NOMBRE_PLAYER_ACCION_AUX: StringName = &"PlayerAccionAux"

const VOLUMEN_SILENCIO_FALLBACK_DB: float = 0.0
const PITCH_DEFECTO: float = 1.0

@export var config: ConfiguracionAudioUI = preload(RUTA_CONFIG_DEFECTO):
	set(val):
		if config != null and config.changed.is_connected(_on_config_changed):
			config.changed.disconnect(_on_config_changed)
		config = val
		if config != null and not config.changed.is_connected(_on_config_changed):
			config.changed.connect(_on_config_changed)
		_cargar_streams_desde_config()
		_aplicar_configuracion_en_vivo()

@onready var _player_cursor: AudioStreamPlayer = $PlayerCursor
@onready var _player_accion: AudioStreamPlayer = $PlayerAccion
@onready var _player_accion_aux: AudioStreamPlayer = $PlayerAccionAux

# Streams en memoria
var _stream_menu_seleccionar: AudioStream
var _stream_menu_aceptar: AudioStream
var _stream_menu_retroceder: AudioStream
var _stream_pausa_abrir: AudioStream
var _stream_pausa_navegar: AudioStream
var _stream_pausa_aceptar: AudioStream
var _stream_pausa_cerrar: AudioStream

var _accion_en_curso: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_asegurar_reproductores()
	if config != null and not config.changed.is_connected(_on_config_changed):
		config.changed.connect(_on_config_changed)
	_cargar_streams_desde_config()
	_aplicar_configuracion_en_vivo()


func _obtener_config_segura() -> ConfiguracionAudioUI:
	if config == null:
		config = ConfiguracionAudioUI.new()
	return config


func _obtener_o_crear_player(player_ref: AudioStreamPlayer, nombre_nodo: StringName) -> AudioStreamPlayer:
	if player_ref != null:
		return player_ref
	var existente := get_node_or_null(NodePath(nombre_nodo)) as AudioStreamPlayer
	if existente != null:
		return existente
	var nuevo := AudioStreamPlayer.new()
	nuevo.name = nombre_nodo
	nuevo.process_mode = Node.PROCESS_MODE_ALWAYS
	nuevo.bus = _obtener_bus()
	add_child(nuevo)
	return nuevo


func _asegurar_reproductores() -> void:
	_player_cursor = _obtener_o_crear_player(_player_cursor, NOMBRE_PLAYER_CURSOR)
	_player_accion = _obtener_o_crear_player(_player_accion, NOMBRE_PLAYER_ACCION)
	_player_accion_aux = _obtener_o_crear_player(_player_accion_aux, NOMBRE_PLAYER_ACCION_AUX)


func _obtener_bus() -> StringName:
	var cfg := _obtener_config_segura()
	return cfg.nombre_bus if not cfg.nombre_bus.is_empty() else NOMBRE_BUS_DEFECTO


func _cargar_streams_desde_config() -> void:
	var cfg := _obtener_config_segura()
	_stream_menu_seleccionar = cfg.stream_menu_seleccionar
	_stream_menu_aceptar = cfg.stream_menu_aceptar
	_stream_menu_retroceder = cfg.stream_menu_retroceder
	_stream_pausa_abrir = cfg.stream_pausa_abrir
	_stream_pausa_navegar = cfg.stream_pausa_navegar
	_stream_pausa_aceptar = cfg.stream_pausa_aceptar
	_stream_pausa_cerrar = cfg.stream_pausa_cerrar


func _on_config_changed() -> void:
	_cargar_streams_desde_config()
	_aplicar_configuracion_en_vivo()


func _aplicar_configuracion_en_vivo() -> void:
	_asegurar_reproductores()
	var cfg := _obtener_config_segura()
	var bus_nombre := _obtener_bus()
	var vol_general := cfg.volumen_general_db

	_player_cursor.bus = bus_nombre
	_player_cursor.volume_db = vol_general + cfg.volumen_cursor_db

	_player_accion.bus = bus_nombre
	_player_accion.volume_db = vol_general + cfg.volumen_accion_db

	_player_accion_aux.bus = bus_nombre
	_player_accion_aux.volume_db = vol_general + cfg.volumen_accion_db


# ==========================================
# API Semántica Unificada (EventoUI)
# ==========================================

func reproducir_evento(evento: EventoUI) -> void:
	match evento:
		EventoUI.MENU_SELECCIONAR:
			reproducir_menu_seleccionar()
		EventoUI.MENU_ACEPTAR:
			reproducir_menu_aceptar()
		EventoUI.MENU_RETROCEDER:
			reproducir_menu_retroceder()
		EventoUI.PAUSA_ABRIR:
			reproducir_pausa_abrir()
		EventoUI.PAUSA_NAVEGAR:
			reproducir_pausa_navegar()
		EventoUI.PAUSA_ACEPTAR:
			reproducir_pausa_aceptar()
		EventoUI.PAUSA_CERRAR:
			reproducir_pausa_cerrar()


func reproducir_extra(id_evento: StringName, es_accion: bool = true) -> void:
	var cfg := _obtener_config_segura()
	if not cfg.eventos_extra.has(id_evento):
		return
	var stream := cfg.eventos_extra[id_evento] as AudioStream
	if stream == null:
		return
	if es_accion:
		_reproducir_en_accion(stream)
	else:
		_reproducir_en_cursor(stream)


## Auto-vinculación declarativa para botones
func vincular_boton(boton: BaseButton, usar_tema_pausa: bool = false) -> void:
	if boton == null:
		return
	var nav_evento := EventoUI.PAUSA_NAVEGAR if usar_tema_pausa else EventoUI.MENU_SELECCIONAR
	var press_evento := EventoUI.PAUSA_ACEPTAR if usar_tema_pausa else EventoUI.MENU_ACEPTAR

	var on_focus = func():
		reproducir_evento(nav_evento)
	var on_pressed = func():
		reproducir_evento(press_evento)

	if not boton.focus_entered.is_connected(on_focus):
		boton.focus_entered.connect(on_focus)
	if not boton.pressed.is_connected(on_pressed):
		boton.pressed.connect(on_pressed)


# ==========================================
# Métodos Públicos Específicos (Compatibilidad)
# ==========================================

func reproducir_menu_seleccionar() -> void:
	_reproducir_en_cursor(_stream_menu_seleccionar)


func reproducir_menu_aceptar() -> void:
	_reproducir_en_accion(_stream_menu_aceptar)


func reproducir_menu_retroceder() -> void:
	_reproducir_en_accion(_stream_menu_retroceder)


func reproducir_pausa_abrir() -> void:
	_reproducir_en_accion(_stream_pausa_abrir)


func reproducir_pausa_navegar() -> void:
	_reproducir_en_cursor(_stream_pausa_navegar)


func reproducir_pausa_aceptar() -> void:
	_reproducir_en_accion(_stream_pausa_aceptar)


func reproducir_pausa_cerrar() -> void:
	_reproducir_en_accion(_stream_pausa_cerrar)


# ==========================================
# Canales Internos de Reproducción
# ==========================================

func _reproducir_en_cursor(stream: AudioStream) -> void:
	if stream == null:
		return
	_asegurar_reproductores()
	var cfg := _obtener_config_segura()
	if cfg.habilitar_variacion_pitch_cursor:
		_player_cursor.pitch_scale = randf_range(cfg.pitch_cursor_min, cfg.pitch_cursor_max)
	else:
		_player_cursor.pitch_scale = PITCH_DEFECTO

	_player_cursor.stream = stream
	_player_cursor.play()


func _reproducir_en_accion(stream: AudioStream) -> void:
	if stream == null:
		return
	_asegurar_reproductores()
	var cfg := _obtener_config_segura()
	var pitch_base: float = cfg.pitch_accion_base

	if not _player_accion.finished.is_connected(_on_accion_finished):
		_player_accion.finished.connect(_on_accion_finished)

	if (_player_accion.playing or _accion_en_curso) and _player_accion_aux != null:
		_player_accion_aux.stream = stream
		_player_accion_aux.pitch_scale = pitch_base
		_player_accion_aux.play()
	else:
		_accion_en_curso = true
		_player_accion.stream = stream
		_player_accion.pitch_scale = pitch_base
		_player_accion.play()


func _on_accion_finished() -> void:
	_accion_en_curso = false


# ==========================================
# Utilidad Estática de Disparo Seguro
# ==========================================

static func emitir_seguro(nodo_contexto: Node, evento: EventoUI) -> void:
	if Engine.is_editor_hint():
		return
	if nodo_contexto == null or not nodo_contexto.is_inside_tree():
		push_warning("[ControladorAudioUI] emitir_seguro() llamado con nodo nulo o fuera del árbol: %s" % str(nodo_contexto))
		return
	var gestor := nodo_contexto.get_tree().root.get_node_or_null(NodePath(NOMBRE_AUTOLOAD)) as ControladorAudioUI
	if gestor != null:
		gestor.reproducir_evento(evento)
	else:
		push_warning("[ControladorAudioUI] Autoload '%s' no existe en /root" % NOMBRE_AUTOLOAD)
