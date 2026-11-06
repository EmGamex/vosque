@tool
class_name ConfiguracionMusica
extends Resource

## Recurso de configuración reactivo para volúmenes, clips y estados de GestorMusica.

@export_group("Recurso y Clips Interactivos")
@export var stream_interactivo: AudioStreamInteractive = preload("res://sonido/musica/musica_interactiva.tres"):
	set(val):
		stream_interactivo = val
		emit_changed()
		changed.emit()

@export var nombre_bus: StringName = &"musica":
	set(val):
		nombre_bus = val
		emit_changed()
		changed.emit()

@export var clip_menu_tutorial: StringName = &"menu_tutorial":
	set(val):
		clip_menu_tutorial = val
		emit_changed()
		changed.emit()

@export var clip_supervivencia: StringName = &"supervivencia":
	set(val):
		clip_supervivencia = val
		emit_changed()
		changed.emit()

@export_group("Volúmenes y Suavizado")
@export_range(-40.0, 6.0, 0.5, "suffix:dB") var volumen_base_db: float = -8.0:
	set(val):
		volumen_base_db = val
		emit_changed()
		changed.emit()

@export_range(1.0, 40.0, 0.5, "suffix:dB/s") var velocidad_suavizado_db: float = 12.0:
	set(val):
		velocidad_suavizado_db = val
		emit_changed()
		changed.emit()

@export_group("Pausa y Game Over (Nightmare Decay)")
@export_range(-30.0, 0.0, 0.5, "suffix:dB") var atenuacion_pausa_db: float = -8.0:
	set(val):
		atenuacion_pausa_db = val
		emit_changed()
		changed.emit()

@export_range(0.2, 1.5, 0.05) var pitch_game_over: float = 0.65:
	set(val):
		pitch_game_over = val
		emit_changed()
		changed.emit()
