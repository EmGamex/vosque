@tool
class_name NieblaFocoController
extends RefCounted

## Controlador especializado en la resolución del objetivo jugador y cálculo de coordenadas UV de pantalla.


func resolver_jugador(nodo_raiz: CanvasLayer, objetivo_manual: Node2D) -> Node2D:
	if objetivo_manual != null and is_instance_valid(objetivo_manual):
		return objetivo_manual

	if not nodo_raiz.is_inside_tree():
		return null

	var padre := nodo_raiz.get_parent()
	if padre is CharacterBody2D:
		return padre as Node2D

	if padre != null and "objetivo_jugador" in padre and padre.get("objetivo_jugador") != null:
		var cand = padre.get("objetivo_jugador") as Node2D
		if cand != null and is_instance_valid(cand):
			return cand

	if padre != null:
		var cand_padre := padre.find_child("personaje", true, false) as Node2D
		if cand_padre != null and is_instance_valid(cand_padre):
			return cand_padre

	var tree := nodo_raiz.get_tree()
	if tree != null and tree.current_scene != null:
		var candidato := tree.current_scene.find_child("personaje", true, false) as Node2D
		if candidato != null and is_instance_valid(candidato):
			return candidato

	return null


func calcular_foco_y_aspecto(nodo_raiz: CanvasLayer, objetivo: Node2D, centro_defecto: Vector2, es_editor: bool) -> Dictionary:
	var resultado := {
		"aspecto": 1.0,
		"centro": centro_defecto,
		"valido": false
	}

	if not nodo_raiz.is_inside_tree():
		return resultado

	var vp := nodo_raiz.get_viewport()
	if vp == null:
		return resultado

	var vp_size: Vector2 = vp.get_visible_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		return resultado

	resultado["aspecto"] = vp_size.x / vp_size.y
	resultado["valido"] = true

	if not es_editor and objetivo != null and is_instance_valid(objetivo) and objetivo.is_inside_tree():
		var pos_pantalla: Vector2 = objetivo.get_global_transform_with_canvas().origin
		resultado["centro"] = pos_pantalla / vp_size
	else:
		resultado["centro"] = centro_defecto

	return resultado
