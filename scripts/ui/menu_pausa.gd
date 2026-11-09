@tool
class_name MenuPausa
extends CanvasLayer

## Menú de Pausa In-Game.
## Capa desacoplada (layer = 50) que emite señales hacia el orquestador ("Signal Up").

signal continuar_solicitado
signal reiniciar_solicitado
signal menu_solicitado

const LAYER_CANVAS: int = 50

@onready var _boton_continuar: Button = $Control/Layout/Columna/BotonContinuar
@onready var _boton_reiniciar: Button = $Control/Layout/Columna/BotonReiniciar
@onready var _boton_menu: Button = $Control/Layout/Columna/BotonMenu

var _bloqueado: bool = false
var _botones: Array[Button] = []
var _indice_foco: int = 0
var _silenciar_foco_inicial: bool = false


func _ready() -> void:
	layer = LAYER_CANVAS
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_botones = []
	for btn in [_boton_continuar, _boton_reiniciar, _boton_menu]:
		if btn != null:
			_botones.append(btn)

	for i in range(_botones.size()):
		var btn: Button = _botones[i]
		btn.focus_entered.connect(_on_boton_enfocado.bind(i))
		btn.mouse_entered.connect(_on_boton_mouse_entered.bind(btn))

	if _boton_continuar != null:
		_boton_continuar.pressed.connect(_on_continuar_pulsado)
	if _boton_reiniciar != null:
		_boton_reiniciar.pressed.connect(_on_reiniciar_pulsado)
	if _boton_menu != null:
		_boton_menu.pressed.connect(_on_menu_pulsado)


func _on_boton_enfocado(idx: int) -> void:
	_indice_foco = idx
	if _silenciar_foco_inicial:
		_silenciar_foco_inicial = false
		return
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_NAVEGAR)


func _on_boton_mouse_entered(btn: Button) -> void:
	if visible and not _bloqueado and btn != null and not btn.has_focus():
		btn.grab_focus()


func mostrar() -> void:
	_bloqueado = false
	_habilitar_botones(true)
	visible = true
	_indice_foco = 0
	_silenciar_foco_inicial = true
	if _boton_continuar != null:
		_boton_continuar.call_deferred("grab_focus")


func ocultar() -> void:
	_silenciar_foco_inicial = false
	_liberar_foco()
	visible = false


func ocultar_inmediato() -> void:
	_silenciar_foco_inicial = false
	_bloqueado = true
	_habilitar_botones(false)
	_liberar_foco()
	visible = false


## Navegación vertical programática (usada por tests y como fallback directo).
func _navegar_vertical(direccion: int) -> void:
	if _botones.is_empty():
		return

	_indice_foco = posmod(_indice_foco + direccion, _botones.size())
	_botones[_indice_foco].grab_focus()


func _activar_boton_actual() -> void:
	if _botones.is_empty():
		return

	if _indice_foco >= 0 and _indice_foco < _botones.size():
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
	Input.action_release("personaje-salto")
	Input.action_release("ui_accept")
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_ACEPTAR)
	reiniciar_solicitado.emit()


func _on_menu_pulsado() -> void:
	if _bloqueado:
		return
	_bloqueado = true
	Input.action_release("personaje-salto")
	Input.action_release("ui_accept")
	ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_ACEPTAR)
	menu_solicitado.emit()
