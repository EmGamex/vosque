@tool
class_name MenuCreditos
extends Control

## Menú de créditos del juego.
## Muestra los roles, autores, herramientas y licencias en un lienzo limpio.
## Emite volver_solicitado al presionar el botón de volver o la acción ui_cancel.

signal volver_solicitado

const URL_YOUTUBE_EMGAMEX: String = "https://www.youtube.com/channel/UC5Qk2IHT1Bs49gBx4MjAmbw"
const URL_INSTAGRAM_NIXU: String = "https://www.instagram.com/nixu_dg/"

@onready var scroll_creditos: ScrollContainer = $Layout/PanelCreditos/Margen/Columna/ScrollCreditos
@onready var boton_volver: Button = $Layout/PanelCreditos/Margen/Columna/BotonVolver
@onready var link_emgamex: LinkButton = $Layout/PanelCreditos/Margen/Columna/ScrollCreditos/ListaSecciones/SecDesarrollo/LinkEmGamex
@onready var link_nixu: LinkButton = $Layout/PanelCreditos/Margen/Columna/ScrollCreditos/ListaSecciones/SecAssets/LinkNixu

var _activo: bool = false
var _silenciar_audio_ajustes: bool = false
var _abridor_url: Callable = OS.shell_open


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_conectar_control_navegable(boton_volver)
	if boton_volver != null and not boton_volver.pressed.is_connected(_on_boton_volver_pressed):
		boton_volver.pressed.connect(_on_boton_volver_pressed)
	_configurar_enlace(link_emgamex, URL_YOUTUBE_EMGAMEX)
	_configurar_enlace(link_nixu, URL_INSTAGRAM_NIXU)


func _controles_navegables() -> Array[BaseButton]:
	return [link_emgamex, link_nixu, boton_volver]


func _conectar_control_navegable(control: BaseButton) -> void:
	if control == null:
		return
	control.focus_mode = Control.FOCUS_NONE
	if not control.focus_entered.is_connected(_on_control_focus_entered):
		control.focus_entered.connect(_on_control_focus_entered)
	if not control.mouse_entered.is_connected(_on_control_mouse_entered.bind(control)):
		control.mouse_entered.connect(_on_control_mouse_entered.bind(control))


func _configurar_enlace(enlace: LinkButton, url: String) -> void:
	if enlace == null:
		return
	_conectar_control_navegable(enlace)
	var callback := _on_enlace_pressed.bind(url)
	if not enlace.pressed.is_connected(callback):
		enlace.pressed.connect(callback)


func activar() -> void:
	_activo = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	if scroll_creditos != null:
		scroll_creditos.scroll_vertical = 0
	_silenciar_audio_ajustes = true
	for control in _controles_navegables():
		if control != null:
			control.focus_mode = Control.FOCUS_ALL
	if boton_volver != null:
		boton_volver.grab_focus()
	_silenciar_audio_ajustes = false


func desactivar() -> void:
	_activo = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for control in _controles_navegables():
		if control != null:
			if control.has_focus():
				control.release_focus()
			control.focus_mode = Control.FOCUS_NONE


func _on_control_focus_entered() -> void:
	if _activo and not _silenciar_audio_ajustes:
		ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_SELECCIONAR)


func _on_control_mouse_entered(control: BaseButton) -> void:
	if _activo and control != null and not control.has_focus():
		control.grab_focus()


func _on_boton_volver_mouse_entered() -> void:
	_on_control_mouse_entered(boton_volver)


func _on_boton_volver_focus_entered() -> void:
	_on_control_focus_entered()


func _on_enlace_pressed(url: String) -> void:
	if not _activo:
		return
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.MENU_ACEPTAR)
	if _abridor_url.is_valid():
		_abridor_url.call(url)


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

