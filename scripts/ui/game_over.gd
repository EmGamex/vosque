@tool
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
	if has_node("/root/GestorMusica"):
		get_node("/root/GestorMusica").activar_modo_game_over()
	_boton_reintentar.pressed.connect(_on_reintentar_pulsado)
	_boton_menu.pressed.connect(_on_menu_pulsado)


## Da el foco a "Reintentar". El gestor lo llama al mostrar la pantalla.
func enfocar() -> void:
	if has_node("/root/GestorMusica"):
		get_node("/root/GestorMusica").activar_modo_game_over()
	if _boton_reintentar != null:
		_boton_reintentar.grab_focus()


func _on_reintentar_pulsado() -> void:
	if has_node("/root/GestorMusica"):
		var gestor_musica = get_node("/root/GestorMusica")
		gestor_musica.restaurar_parametros_normales()
		gestor_musica.reproducir_menu_o_tutorial()
	reintentar_solicitado.emit()
	if _gestor != null:
		_gestor.iniciar_partida()


func _on_menu_pulsado() -> void:
	if has_node("/root/GestorMusica"):
		var gestor_musica = get_node("/root/GestorMusica")
		gestor_musica.restaurar_parametros_normales()
		gestor_musica.reproducir_menu_o_tutorial()
	menu_solicitado.emit()
	if _gestor != null:
		_gestor.volver_al_menu()
