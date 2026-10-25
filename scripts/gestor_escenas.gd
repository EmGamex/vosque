class_name GestorDeEscenas
extends Node

## Gestor de escenas: escena principal del juego.
##
## Las pantallas están instanciadas bajo "Contenedor". Solo la activa está
## visible y procesando; el cambio se hace con un fundido a negro y la
## pantalla de juego se recrea desde cero cada vez que se entra en ella.
## Se comunica con las pantallas hijas mediante señales (patrón Signal Up).


const RUTA_MENU: String = "res://escenas/menu_inicio.tscn"
const RUTA_JUEGO: String = "res://escenas/maain.tscn"
const RUTA_GAME_OVER: String = "res://escenas/game_over.tscn"

@onready var _contenedor: Node = $Contenedor
@onready var _transicion: TransicionEscenas = $Transicion

## Ruta de escena -> instancia dentro del contenedor.
var _pantallas: Dictionary = {}
var _ruta_actual: String = ""
var _cambiando: bool = false


func _ready() -> void:
	_registrar_pantallas()
	_activar(RUTA_MENU)


func _unhandled_input(evento: InputEvent) -> void:
	if _cambiando:
		return

	if evento.is_action_pressed("ui_cancel"):
		if _ruta_actual != RUTA_MENU:
			volver_al_menu()
			get_viewport().set_input_as_handled()
	elif evento is InputEventKey and evento.pressed and not evento.echo and evento.keycode == KEY_G:
		# Provisional: dispara el Game Over para probar el bucle.
		# Sustituir por la muerte real cuando exista la criatura.
		ir_a(RUTA_GAME_OVER)
		get_viewport().set_input_as_handled()


## Conmuta a la pantalla indicada con fundido de salida y entrada.
## Con reiniciar=true la pantalla se recrea desde cero.
func ir_a(ruta: String, reiniciar: bool = false) -> void:
	if _cambiando or (ruta == _ruta_actual and not reiniciar):
		return
	_cambiando = true
	await _fundir(true)
	if reiniciar:
		_descartar(ruta)
	_activar(ruta)
	await _fundir(false)
	_cambiando = false


## Empieza una partida nueva (recrea la pantalla de juego).
func iniciar_partida() -> void:
	ir_a(RUTA_JUEGO, true)


## Reinicia la pantalla actual desde cero.
func recargar() -> void:
	ir_a(_ruta_actual, true)


## Vuelve al menú de inicio.
func volver_al_menu() -> void:
	ir_a(RUTA_MENU)


func _registrar_pantallas() -> void:
	for hijo in _contenedor.get_children():
		if not hijo.scene_file_path.is_empty():
			_pantallas[hijo.scene_file_path] = hijo
			_conectar_senales_pantalla(hijo)


## Conecta las señales de las pantallas hijas hacia los métodos del orquestador.
func _conectar_senales_pantalla(pantalla: Node) -> void:
	if pantalla.has_signal("jugar_solicitado"):
		var sig_jugar: Signal = pantalla.get("jugar_solicitado")
		if not sig_jugar.is_connected(_on_jugar_solicitado):
			sig_jugar.connect(_on_jugar_solicitado)

	if pantalla.has_signal("reintentar_solicitado"):
		var sig_reintentar: Signal = pantalla.get("reintentar_solicitado")
		if not sig_reintentar.is_connected(_on_jugar_solicitado):
			sig_reintentar.connect(_on_jugar_solicitado)

	if pantalla.has_signal("menu_solicitado"):
		var sig_menu: Signal = pantalla.get("menu_solicitado")
		if not sig_menu.is_connected(_on_menu_solicitado):
			sig_menu.connect(_on_menu_solicitado)


func _on_jugar_solicitado() -> void:
	iniciar_partida()


func _on_menu_solicitado() -> void:
	volver_al_menu()


## Deja activa la pantalla de la ruta dada y aparca el resto.
##
## Aparcar implica: ocultar, dejar de procesar y apagar sus cámaras. En Godot 4
## una Camera2D sigue siendo la cámara activa aunque su nodo esté oculto, y al
## compartir capa con los Control arrastraría al menú y al Game Over.
func _activar(ruta: String) -> void:
	var pantalla: Node = _obtener(ruta)
	for hijo in _contenedor.get_children():
		var activa: bool = hijo == pantalla
		hijo.visible = activa
		hijo.process_mode = Node.PROCESS_MODE_INHERIT if activa else Node.PROCESS_MODE_DISABLED
		_fijar_camaras(hijo, activa)
	_ruta_actual = ruta
	if pantalla.has_method("enfocar"):
		pantalla.call_deferred("enfocar")


## Devuelve la instancia de una pantalla, creándola si hace falta.
func _obtener(ruta: String) -> Node:
	var pantalla: Node = _pantallas.get(ruta)
	if pantalla == null or not is_instance_valid(pantalla):
		pantalla = (load(ruta) as PackedScene).instantiate()
		_contenedor.add_child(pantalla)
		_pantallas[ruta] = pantalla
		_conectar_senales_pantalla(pantalla)
	return pantalla


## Saca del árbol y libera la instancia actual (para recrearla limpia).
func _descartar(ruta: String) -> void:
	var pantalla: Node = _pantallas.get(ruta)
	if pantalla == null or not is_instance_valid(pantalla):
		return
	_pantallas.erase(ruta)
	_contenedor.remove_child(pantalla)
	pantalla.queue_free()


## Enciende o apaga las cámaras de un subárbol.
func _fijar_camaras(raiz: Node, encendidas: bool) -> void:
	if raiz is Camera2D:
		var cam := raiz as Camera2D
		if cam.is_in_group("camaras_debug") or cam.name == "CamaraDios":
			cam.enabled = false
		else:
			cam.enabled = encendidas
	for hijo in raiz.get_children():
		_fijar_camaras(hijo, encendidas)


func _fundir(a_negro: bool) -> void:
	if a_negro:
		await _transicion.cerrar()
	else:
		await _transicion.abrir()
