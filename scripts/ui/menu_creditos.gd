@tool
class_name MenuCreditos
extends Control

## Menú de créditos del juego.
## Muestra los roles, autores, herramientas y licencias en un lienzo limpio.
## Emite volver_solicitado al presionar el botón de volver o la acción ui_cancel.

signal volver_solicitado

@onready var scroll_creditos: ScrollContainer = $Layout/PanelCreditos/Margen/Columna/ScrollCreditos
@onready var boton_volver: Button = $Layout/PanelCreditos/Margen/Columna/BotonVolver

var _activo: bool = false
var _silenciar_audio_ajustes: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if boton_volver != null:
		boton_volver.focus_mode = Control.FOCUS_NONE
		if not boton_volver.pressed.is_connected(_on_boton_volver_pressed):
			boton_volver.pressed.connect(_on_boton_volver_pressed)
		if not boton_volver.focus_entered.is_connected(_on_boton_volver_focus_entered):
			boton_volver.focus_entered.connect(_on_boton_volver_focus_entered)
		if not boton_volver.mouse_entered.is_connected(_on_boton_volver_mouse_entered):
			boton_volver.mouse_entered.connect(_on_boton_volver_mouse_entered)


func activar() -> void:
	_activo = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if scroll_creditos != null:
		scroll_creditos.scroll_vertical = 0
	_silenciar_audio_ajustes = true
	if boton_volver != null:
		boton_volver.focus_mode = Control.FOCUS_ALL
		boton_volver.grab_focus()
	_silenciar_audio_ajustes = false


func desactivar() -> void:
	_activo = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if boton_volver != null:
		if boton_volver.has_focus():
			boton_volver.release_focus()
		boton_volver.focus_mode = Control.FOCUS_NONE


func _on_boton_volver_focus_entered() -> void:
	if _activo and not _silenciar_audio_ajustes:
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_SELECCIONAR)


func _on_boton_volver_mouse_entered() -> void:
	if _activo and boton_volver != null and not boton_volver.has_focus():
		boton_volver.grab_focus()


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
	elif scroll_creditos != null and evento.is_action_pressed("ui_down", true):
		scroll_creditos.scroll_vertical += 48
		get_viewport().set_input_as_handled()
	elif scroll_creditos != null and evento.is_action_pressed("ui_up", true):
		scroll_creditos.scroll_vertical = maxi(0, scroll_creditos.scroll_vertical - 48)
		get_viewport().set_input_as_handled()

