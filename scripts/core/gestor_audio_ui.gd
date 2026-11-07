extends Node

## Autoload GestorAudioUI
## Administra la reproducción de efectos de sonido (SFX) para menús y elementos de interfaz.
## Se ejecuta siempre (PROCESS_MODE_ALWAYS) y envía el audio al bus "sfx".

const RUTA_MENU_SELECCIONAR := "res://sonido/sfx/menus/seleccionar_menu_main.wav"
const RUTA_MENU_ACEPTAR := "res://sonido/sfx/menus/aceptar_menu_pincial.wav"
const RUTA_MENU_RETROCEDER := "res://sonido/sfx/menus/retroceder_menu_main.wav"

const RUTA_PAUSA_ABRIR := "res://sonido/sfx/menus/abrir_pausa.wav"
const RUTA_PAUSA_NAVEGAR := "res://sonido/sfx/menus/JA_SE_SYS_CURS_MOVE.wav"
const RUTA_PAUSA_ACEPTAR := "res://sonido/sfx/menus/presionar_pausa.wav"
const RUTA_PAUSA_CERRAR := "res://sonido/sfx/menus/cerrar_pausa_01.wav"

const NOMBRE_BUS := &"sfx"

var _stream_menu_seleccionar: AudioStream
var _stream_menu_aceptar: AudioStream
var _stream_menu_retroceder: AudioStream

var _stream_pausa_abrir: AudioStream
var _stream_pausa_navegar: AudioStream
var _stream_pausa_aceptar: AudioStream
var _stream_pausa_cerrar: AudioStream

var _player_cursor: AudioStreamPlayer
var _player_accion: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cargar_streams()
	_crear_reproductores()


func _cargar_streams() -> void:
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


func _crear_reproductores() -> void:
	_player_cursor = AudioStreamPlayer.new()
	_player_cursor.name = "PlayerCursor"
	_player_cursor.process_mode = Node.PROCESS_MODE_ALWAYS
	_player_cursor.bus = NOMBRE_BUS
	add_child(_player_cursor)

	_player_accion = AudioStreamPlayer.new()
	_player_accion.name = "PlayerAccion"
	_player_accion.process_mode = Node.PROCESS_MODE_ALWAYS
	_player_accion.bus = NOMBRE_BUS
	add_child(_player_accion)


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


func _reproducir_en_cursor(stream: AudioStream) -> void:
	if stream == null or _player_cursor == null:
		return
	_player_cursor.stream = stream
	_player_cursor.play()


func _reproducir_en_accion(stream: AudioStream) -> void:
	if stream == null or _player_accion == null:
		return
	_player_accion.stream = stream
	_player_accion.play()
