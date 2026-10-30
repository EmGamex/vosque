@tool
class_name MenuPausa
extends CanvasLayer

## Menú de Pausa In-Game.
## Capa desacoplada (layer = 50) que emite señales hacia el orquestador ("Signal Up").

signal continuar_solicitado
signal reiniciar_solicitado
signal menu_solicitado

@onready var _boton_continuar: Button = $Control/Layout/Columna/BotonContinuar
@onready var _boton_reiniciar: Button = $Control/Layout/Columna/BotonReiniciar
@onready var _boton_menu: Button = $Control/Layout/Columna/BotonMenu

var _bloqueado: bool = false
var _botones: Array[Button] = []
var _indice_foco: int = 0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_botones = []
	for btn in [_boton_continuar, _boton_reiniciar, _boton_menu]:
		if btn != null:
			_botones.append(btn)

	if _boton_continuar != null:
		_boton_continuar.pressed.connect(_on_continuar_pulsado)
	if _boton_reiniciar != null:
		_boton_reiniciar.pressed.connect(_on_reiniciar_pulsado)
	if _boton_menu != null:
		_boton_menu.pressed.connect(_on_menu_pulsado)


func mostrar() -> void:
	_bloqueado = false
	_habilitar_botones(true)
	visible = true
	_indice_foco = 0
	if _boton_continuar != null:
		_boton_continuar.call_deferred("grab_focus")


func ocultar() -> void:
	_liberar_foco()
	visible = false


func ocultar_inmediato() -> void:
	_bloqueado = true
	_habilitar_botones(false)
	_liberar_foco()
	visible = false


func _unhandled_input(evento: InputEvent) -> void:
	if not visible or _bloqueado:
		return

	if evento.is_action_pressed("personaje-arriba"):
		_navegar_vertical(-1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("personaje-abajo"):
		_navegar_vertical(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("personaje-salto"):
		Input.action_release("personaje-salto")
		Input.action_release("ui_accept")
		_activar_boton_actual()
		get_viewport().set_input_as_handled()


func _navegar_vertical(direccion: int) -> void:
	if _botones.is_empty():
		return

	# Si algún botón tiene el foco actualmente por UI de Godot, sincronizamos
	for i in range(_botones.size()):
		if _botones[i].has_focus():
			_indice_foco = i
			break

	_indice_foco = posmod(_indice_foco + direccion, _botones.size())
	_botones[_indice_foco].grab_focus()


func _activar_boton_actual() -> void:
	if _botones.is_empty():
		return

	for i in range(_botones.size()):
		if _botones[i].has_focus():
			_indice_foco = i
			break

	var boton_activo: Button = _botones[_indice_foco]
	if boton_activo != null and not boton_activo.disabled:
		boton_activo.emit_signal("pressed")


func _liberar_foco() -> void:
	for btn in [_boton_continuar, _boton_reiniciar, _boton_menu]:
		if btn != null and btn.has_focus():
			btn.release_focus()


func _habilitar_botones(habilitar: bool) -> void:
	for btn in [_boton_continuar, _boton_reiniciar, _boton_menu]:
		if btn != null:
			btn.disabled = not habilitar


func _on_continuar_pulsado() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	continuar_solicitado.emit()


func _on_reiniciar_pulsado() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	reiniciar_solicitado.emit()


func _on_menu_pulsado() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	menu_solicitado.emit()
