extends Control

## Pantalla de Game Over: reintentar o volver al menú.

@onready var _gestor: GestorDeEscenas = get_node_or_null("/root/GestorEscenas") as GestorDeEscenas
@onready var _boton_reintentar: Button = $Layout/Columna/BotonReintentar
@onready var _boton_menu: Button = $Layout/Columna/BotonMenu


func _ready() -> void:
	enfocar()
	if _gestor == null:
		return
	_boton_reintentar.pressed.connect(_on_reintentar_pulsado)
	_boton_menu.pressed.connect(_on_menu_pulsado)


## Da el foco a "Reintentar". El gestor lo llama al mostrar la pantalla.
func enfocar() -> void:
	_boton_reintentar.grab_focus()


func _on_reintentar_pulsado() -> void:
	_gestor.iniciar_partida()


func _on_menu_pulsado() -> void:
	_gestor.volver_al_menu()
