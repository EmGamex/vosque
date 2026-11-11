@tool
class_name MenuCreditos
extends Control

## Menú de créditos del juego.
## Muestra los roles, autores, herramientas y licencias en un lienzo limpio.
## Emite volver_solicitado al presionar el botón de volver o la acción ui_cancel.

signal volver_solicitado

@onready var boton_volver: Button = $Layout/PanelCreditos/Margen/Columna/BotonVolver

var _activo: bool = false


func _ready() -> void:
	if boton_volver != null and not boton_volver.pressed.is_connected(_on_boton_volver_pressed):
		boton_volver.pressed.connect(_on_boton_volver_pressed)


func activar() -> void:
	_activo = true
	if boton_volver != null:
		boton_volver.grab_focus()


func desactivar() -> void:
	_activo = false
	if boton_volver != null and boton_volver.has_focus():
		boton_volver.release_focus()


func _on_boton_volver_pressed() -> void:
	if not _activo:
		return
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_RETROCEDER)
	volver_solicitado.emit()


func _input(evento: InputEvent) -> void:
	if not _activo:
		return

	if evento.is_action_pressed("ui_cancel"):
		_on_boton_volver_pressed()
		get_viewport().set_input_as_handled()
