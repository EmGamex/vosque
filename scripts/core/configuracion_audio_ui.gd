@tool
class_name ConfiguracionAudioUI
extends Resource

## Recurso de configuración reactivo para streams, volúmenes, pitch y canales de GestorAudioUI.

@export_group("Menú Principal y Pantallas Generales")
@export var stream_menu_seleccionar: AudioStream = preload("res://sonido/sfx/menus/seleccionar_menu_main.wav"):
	set(val):
		stream_menu_seleccionar = val
		emit_changed()
		changed.emit()

@export var stream_menu_aceptar: AudioStream = preload("res://sonido/sfx/menus/aceptar_menu_pincial.wav"):
	set(val):
		stream_menu_aceptar = val
		emit_changed()
		changed.emit()

@export var stream_menu_retroceder: AudioStream = preload("res://sonido/sfx/menus/retroceder_menu_main.wav"):
	set(val):
		stream_menu_retroceder = val
		emit_changed()
		changed.emit()

@export_group("Menú de Pausa")
@export var stream_pausa_abrir: AudioStream = preload("res://sonido/sfx/menus/abrir_pausa.wav"):
	set(val):
		stream_pausa_abrir = val
		emit_changed()
		changed.emit()

@export var stream_pausa_navegar: AudioStream = preload("res://sonido/sfx/menus/JA_SE_SYS_CURS_MOVE.wav"):
	set(val):
		stream_pausa_navegar = val
		emit_changed()
		changed.emit()

@export var stream_pausa_aceptar: AudioStream = preload("res://sonido/sfx/menus/presionar_pausa.wav"):
	set(val):
		stream_pausa_aceptar = val
		emit_changed()
		changed.emit()

@export var stream_pausa_cerrar: AudioStream = preload("res://sonido/sfx/menus/cerrar_pausa_01.wav"):
	set(val):
		stream_pausa_cerrar = val
		emit_changed()
		changed.emit()

@export_group("Mezcla y Bus de Salida")
@export var nombre_bus: StringName = &"sfx":
	set(val):
		nombre_bus = val
		emit_changed()
		changed.emit()

@export_range(-40.0, 6.0, 0.5, "suffix:dB") var volumen_general_db: float = 0.0:
	set(val):
		volumen_general_db = val
		emit_changed()
		changed.emit()

@export_range(-24.0, 6.0, 0.5, "suffix:dB") var volumen_cursor_db: float = 0.0:
	set(val):
		volumen_cursor_db = val
		emit_changed()
		changed.emit()

@export_range(-24.0, 6.0, 0.5, "suffix:dB") var volumen_accion_db: float = 0.0:
	set(val):
		volumen_accion_db = val
		emit_changed()
		changed.emit()

@export_group("Game Feel y Modulación de Tono")
@export var habilitar_variacion_pitch_cursor: bool = true:
	set(val):
		habilitar_variacion_pitch_cursor = val
		emit_changed()
		changed.emit()

@export_range(0.5, 1.5, 0.01) var pitch_cursor_min: float = 0.96:
	set(val):
		pitch_cursor_min = val
		emit_changed()
		changed.emit()

@export_range(0.5, 1.5, 0.01) var pitch_cursor_max: float = 1.04:
	set(val):
		pitch_cursor_max = val
		emit_changed()
		changed.emit()

@export_range(0.5, 1.5, 0.01) var pitch_accion_base: float = 1.0:
	set(val):
		pitch_accion_base = val
		emit_changed()
		changed.emit()

@export_group("Catálogo Extensible")
## Permite registrar eventos adicionales en el Inspector (StringName -> AudioStream) sin tocar código.
@export var eventos_extra: Dictionary = {}:
	set(val):
		eventos_extra = val
		emit_changed()
		changed.emit()
