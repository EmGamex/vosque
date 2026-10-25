class_name GameOver
extends Control

## Pantalla de Game Over: reintentar o volver al menú.
## Emite señales hacia el orquestador ("Signal Up") y mantiene fallback si se prueba aislada.

signal reintentar_solicitado
signal menu_solicitado

@onready var _gestor: GestorDeEscenas = get_node_or_null("/root/GestorEscenas") as GestorDeEscenas
@onready var _boton_reintentar: Button = $Layout/Columna/BotonReintentar
@onready var _boton_menu: Button = $Layout/Columna/BotonMenu


func _ready() -> void:
	enfocar()
	_boton_reintentar.pressed.connect(_on_reintentar_pulsado)
	_boton_menu.pressed.connect(_on_menu_pulsado)


## Da el foco a "Reintentar". El gestor lo llama al mostrar la pantalla.
func enfocar() -> void:
	if _boton_reintentar != null:
		_boton_reintentar.grab_focus()


func _on_reintentar_pulsado() -> void:
	reintentar_solicitado.emit()
	if _gestor != null:
		_gestor.iniciar_partida()


func _on_menu_pulsado() -> void:
	menu_solicitado.emit()
	if _gestor != null:
		_gestor.volver_al_menu()
