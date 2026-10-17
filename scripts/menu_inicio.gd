extends Control

## Menú de inicio: conecta los botones al gestor de escenas.

@onready var _gestor: GestorDeEscenas = get_node_or_null("/root/GestorEscenas") as GestorDeEscenas
@onready var _boton_jugar: Button = $Layout/Columna/BotonJugar
@onready var _boton_salir: Button = $Layout/Columna/BotonSalir


func _ready() -> void:
	_boton_salir.pressed.connect(_on_salir_pulsado)
	enfocar()
	if _gestor == null:
		# Sin gestor (p. ej. esta escena sola con F6): los botones quedan inertes.
		return
	_boton_jugar.pressed.connect(_on_jugar_pulsado)


## Da el foco al primer botón. El gestor lo llama al mostrar la pantalla.
func enfocar() -> void:
	_boton_jugar.grab_focus()


func _on_jugar_pulsado() -> void:
	_gestor.iniciar_partida()


func _on_salir_pulsado() -> void:
	get_tree().quit()
