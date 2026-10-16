@tool
extends EditorPlugin

const CharacterBar = preload("res://addons/personaje_tools/character_bar.gd")
const BARRA_ESCENA := preload("res://addons/personaje_tools/character_bar.tscn")

var _barra_instancia: CharacterBar = null


func _enter_tree() -> void:
	_barra_instancia = BARRA_ESCENA.instantiate() as CharacterBar
	add_control_to_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _barra_instancia)
	_barra_instancia.hide()


func _exit_tree() -> void:
	if _barra_instancia == null:
		return
	remove_control_from_container(EditorPlugin.CONTAINER_CANVAS_EDITOR_MENU, _barra_instancia)
	_barra_instancia.queue_free()
	_barra_instancia = null


func _handles(object: Object) -> bool:
	if not (object is CharacterBody2D):
		return false
	for propiedad: String in CharacterBar.PROPIEDADES:
		if propiedad not in object:
			return false
	return true


func _make_visible(visible: bool) -> void:
	if _barra_instancia == null:
		return
	_barra_instancia.visible = visible
	if not visible:
		_barra_instancia.set_personaje(null)


func _edit(object: Object) -> void:
	_barra_instancia.set_personaje(object as CharacterBody2D)
