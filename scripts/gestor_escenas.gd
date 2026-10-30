@tool
class_name GestorDeEscenas
extends Node

## Gestor de escenas: escena principal del juego.
##
## Las pantallas están instanciadas bajo "Contenedor". Solo la activa está
## visible y procesando; el cambio se hace con un fundido a negro y la
## pantalla de juego se recrea desde cero cada vez que se entra en ella.
## Se comunica con las pantallas hijas mediante señales (patrón Signal Up).
## Incorpora arquitectura híbrida de pausa in-game (layer = 50) y salvaguardas.


const RUTA_MENU: String = "res://escenas/menu_inicio.tscn"
const RUTA_JUEGO: String = "res://escenas/maain.tscn"
const RUTA_GAME_OVER: String = "res://escenas/game_over.tscn"

@onready var _contenedor: Node = $Contenedor
@onready var _transicion: TransicionEscenas = $Transicion
@onready var _menu_pausa: MenuPausa = get_node_or_null("MenuPausa") as MenuPausa

## Ruta de escena -> instancia dentro del contenedor.
var _pantallas: Dictionary = {}
var _ruta_actual: String = ""
var _cambiando: bool = false
var _pausado: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_conectar_menu_pausa()
	_registrar_pantallas()
	_activar(RUTA_MENU)


func _conectar_menu_pausa() -> void:
	if _menu_pausa == null:
		_menu_pausa = get_node_or_null("MenuPausa") as MenuPausa
	if _menu_pausa != null:
		if not _menu_pausa.continuar_solicitado.is_connected(reanudar):
			_menu_pausa.continuar_solicitado.connect(reanudar)
		if not _menu_pausa.reiniciar_solicitado.is_connected(iniciar_partida):
			_menu_pausa.reiniciar_solicitado.connect(iniciar_partida)
		if not _menu_pausa.menu_solicitado.is_connected(volver_al_menu):
			_menu_pausa.menu_solicitado.connect(volver_al_menu)
		_menu_pausa.ocultar_inmediato()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if puede_pausar() and not _pausado:
			pausar()


func puede_pausar() -> bool:
	if _ruta_actual != RUTA_JUEGO or _cambiando:
		return false
	var juego: Node = _pantallas.get(RUTA_JUEGO) as Node
	if juego == null or not is_instance_valid(juego):
		return false
	var enemigo: Node = juego.get_node_or_null("Enemigo")
	if enemigo != null and enemigo.get("_capturado") == true:
		return false
	return true


func alternar_pausa() -> void:
	if _pausado:
		reanudar()
	elif puede_pausar():
		pausar()


func pausar() -> void:
	if not puede_pausar() or _pausado:
		return
	_pausado = true
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.paused = true
	if _menu_pausa != null:
		_menu_pausa.mostrar()


func reanudar() -> void:
	if not _pausado:
		return
	_pausado = false
	if _menu_pausa != null:
		_menu_pausa.ocultar()
	var tree: SceneTree = get_tree()
	if tree != null:
		tree.set_deferred("paused", false)


func _limpiar_pausa_forzada() -> void:
	var tree: SceneTree = get_tree()
	var esta_pausado_arbol: bool = tree.paused if tree != null else false
	if _pausado or esta_pausado_arbol:
		_pausado = false
		if _menu_pausa != null:
			_menu_pausa.ocultar_inmediato()
		if tree != null:
			tree.paused = false


func _unhandled_input(evento: InputEvent) -> void:
	if _cambiando:
		return

	if evento.is_action_pressed("pausa") or evento.is_action_pressed("ui_cancel"):
		if _pausado:
			reanudar()
			get_viewport().set_input_as_handled()
		elif _ruta_actual == RUTA_JUEGO:
			alternar_pausa()
			get_viewport().set_input_as_handled()
		elif _ruta_actual != RUTA_MENU:
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
	_limpiar_pausa_forzada()
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
	if pantalla.has_user_signal("jugar_solicitado") or pantalla.has_signal("jugar_solicitado"):
		if not pantalla.is_connected("jugar_solicitado", _on_jugar_solicitado):
			pantalla.connect("jugar_solicitado", _on_jugar_solicitado)

	if pantalla.has_user_signal("reintentar_solicitado") or pantalla.has_signal("reintentar_solicitado"):
		if not pantalla.is_connected("reintentar_solicitado", _on_jugar_solicitado):
			pantalla.connect("reintentar_solicitado", _on_jugar_solicitado)

	if pantalla.has_user_signal("menu_solicitado") or pantalla.has_signal("menu_solicitado"):
		if not pantalla.is_connected("menu_solicitado", _on_menu_solicitado):
			pantalla.connect("menu_solicitado", _on_menu_solicitado)


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
		if activa:
			if ruta == RUTA_JUEGO:
				hijo.process_mode = Node.PROCESS_MODE_PAUSABLE
			else:
				hijo.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			hijo.process_mode = Node.PROCESS_MODE_DISABLED
		_fijar_camaras(hijo, activa)
		_fijar_canvas_layers(hijo, activa)
	_ruta_actual = ruta
	if pantalla.has_method("enfocar"):
		pantalla.call_deferred("enfocar")


## Enciende o apaga CanvasLayers anidados dentro de una pantalla (ej. HUD en Maain).
func _fijar_canvas_layers(raiz: Node, activa: bool) -> void:
	if raiz is CanvasLayer and raiz.name != "Transicion" and raiz.name != "MenuPausa":
		(raiz as CanvasLayer).visible = activa
	for hijo in raiz.get_children():
		_fijar_canvas_layers(hijo, activa)


## Devuelve la instancia de una pantalla, creándola si hace falta.
func _obtener(ruta: String) -> Node:
	var pantalla: Node = _pantallas.get(ruta) as Node
	if pantalla == null or not is_instance_valid(pantalla):
		pantalla = (load(ruta) as PackedScene).instantiate()
		_contenedor.add_child(pantalla)
		_pantallas[ruta] = pantalla
		_conectar_senales_pantalla(pantalla)
	return pantalla


## Saca del árbol y libera la instancia actual (para recrearla limpia).
func _descartar(ruta: String) -> void:
	var pantalla: Node = _pantallas.get(ruta) as Node
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
