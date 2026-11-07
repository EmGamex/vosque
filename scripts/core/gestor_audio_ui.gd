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

# Constantes de rutas históricas para compatibilidad
const RUTA_MENU_SELECCIONAR := "res://sonido/sfx/menus/seleccionar_menu_main.wav"
const RUTA_MENU_ACEPTAR := "res://sonido/sfx/menus/aceptar_menu_pincial.wav"
const RUTA_MENU_RETROCEDER := "res://sonido/sfx/menus/retroceder_menu_main.wav"

const RUTA_PAUSA_ABRIR := "res://sonido/sfx/menus/abrir_pausa.wav"
const RUTA_PAUSA_NAVEGAR := "res://sonido/sfx/menus/JA_SE_SYS_CURS_MOVE.wav"
const RUTA_PAUSA_ACEPTAR := "res://sonido/sfx/menus/presionar_pausa.wav"
const RUTA_PAUSA_CERRAR := "res://sonido/sfx/menus/cerrar_pausa_01.wav"

const NOMBRE_BUS := &"sfx"

@export var config: ConfiguracionAudioUI = preload("res://recursos/audio/config_audio_ui_defecto.tres"):
	set(val):
		if config != null and config.changed.is_connected(_on_config_changed):
			config.changed.disconnect(_on_config_changed)
		config = val
		if config != null and not config.changed.is_connected(_on_config_changed):
			config.changed.connect(_on_config_changed)
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


func _asegurar_reproductores() -> void:
	if _player_cursor == null:
		_player_cursor = get_node_or_null("PlayerCursor") as AudioStreamPlayer
	if _player_cursor == null:
		_player_cursor = AudioStreamPlayer.new()
		_player_cursor.name = "PlayerCursor"
		_player_cursor.process_mode = Node.PROCESS_MODE_ALWAYS
		_player_cursor.bus = NOMBRE_BUS
		add_child(_player_cursor)

	if _player_accion == null:
		_player_accion = get_node_or_null("PlayerAccion") as AudioStreamPlayer
	if _player_accion == null:
		_player_accion = AudioStreamPlayer.new()
		_player_accion.name = "PlayerAccion"
		_player_accion.process_mode = Node.PROCESS_MODE_ALWAYS
		_player_accion.bus = NOMBRE_BUS
		add_child(_player_accion)

	if _player_accion_aux == null:
		_player_accion_aux = get_node_or_null("PlayerAccionAux") as AudioStreamPlayer
	if _player_accion_aux == null:
		_player_accion_aux = AudioStreamPlayer.new()
		_player_accion_aux.name = "PlayerAccionAux"
		_player_accion_aux.process_mode = Node.PROCESS_MODE_ALWAYS
		_player_accion_aux.bus = NOMBRE_BUS
		add_child(_player_accion_aux)


func _cargar_streams_desde_config() -> void:
	if config != null:
		_stream_menu_seleccionar = config.stream_menu_seleccionar
		_stream_menu_aceptar = config.stream_menu_aceptar
		_stream_menu_retroceder = config.stream_menu_retroceder
		_stream_pausa_abrir = config.stream_pausa_abrir
		_stream_pausa_navegar = config.stream_pausa_navegar
		_stream_pausa_aceptar = config.stream_pausa_aceptar
		_stream_pausa_cerrar = config.stream_pausa_cerrar
	else:
		_cargar_streams_fallback()


func _cargar_streams_fallback() -> void:
	if ResourceLoader.exists(RUTA_MENU_SELECCIONAR):
		_stream_menu_seleccionar = load(RUTA_MENU_SELECCIONAR)
	if ResourceLoader.exists(RUTA_MENU_ACEPTAR):
		_stream_menu_aceptar = load(RUTA_MENU_ACEPTAR)
	if ResourceLoader.exists(RUTA_MENU_RETROCEDER):
		_stream_menu_retroceder = load(RUTA_MENU_RETROCEDER)

	if ResourceLoader.exists(RUTA_PAUSA_ABRIR):
		_stream_pausa_abrir = load(RUTA_PAUSA_ABRIR)
	if ResourceLoader.exists(RUTA_PAUSA_NAVEGAR):
		_stream_pausa_navegar = load(RUTA_PAUSA_NAVEGAR)
	if ResourceLoader.exists(RUTA_PAUSA_ACEPTAR):
		_stream_pausa_aceptar = load(RUTA_PAUSA_ACEPTAR)
	if ResourceLoader.exists(RUTA_PAUSA_CERRAR):
		_stream_pausa_cerrar = load(RUTA_PAUSA_CERRAR)


func _on_config_changed() -> void:
	_cargar_streams_desde_config()
	_aplicar_configuracion_en_vivo()


func _aplicar_configuracion_en_vivo() -> void:
	_asegurar_reproductores()
	var bus_nombre: StringName = config.nombre_bus if config != null and not config.nombre_bus.is_empty() else NOMBRE_BUS
	var vol_general: float = config.volumen_general_db if config != null else 0.0
	var vol_cursor: float = config.volumen_cursor_db if config != null else 0.0
	var vol_accion: float = config.volumen_accion_db if config != null else 0.0

	if _player_cursor != null:
		_player_cursor.bus = bus_nombre
		_player_cursor.volume_db = vol_general + vol_cursor
	if _player_accion != null:
		_player_accion.bus = bus_nombre
		_player_accion.volume_db = vol_general + vol_accion
	if _player_accion_aux != null:
		_player_accion_aux.bus = bus_nombre
		_player_accion_aux.volume_db = vol_general + vol_accion


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
	if config == null or not config.eventos_extra.has(id_evento):
		return
	var stream: AudioStream = config.eventos_extra[id_evento] as AudioStream
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
	_asegurar_reproductores()
	if stream == null or _player_cursor == null:
		return

	if config != null and config.habilitar_variacion_pitch_cursor:
		_player_cursor.pitch_scale = randf_range(config.pitch_cursor_min, config.pitch_cursor_max)
	else:
		_player_cursor.pitch_scale = 1.0

	_player_cursor.stream = stream
	_player_cursor.play()


func _reproducir_en_accion(stream: AudioStream) -> void:
	_asegurar_reproductores()
	if stream == null or _player_accion == null:
		return

	var pitch_base: float = config.pitch_accion_base if config != null else 1.0

	# Conectamos finished para resetear el flag de acción en curso
	if not _player_accion.finished.is_connected(_on_accion_finished):
		_player_accion.finished.connect(_on_accion_finished)

	# Zero-cutoff: si _player_accion ya está reproduciendo o marcado en curso, usamos canal auxiliar
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
	if Engine.is_editor_hint() or nodo_contexto == null:
		return
	if nodo_contexto.has_node("/root/GestorAudioUI"):
		var gestor = nodo_contexto.get_node("/root/GestorAudioUI")
		if gestor != null and gestor.has_method("reproducir_evento"):
			gestor.reproducir_evento(evento)
