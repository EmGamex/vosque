class_name DebugContext
extends RefCounted

## Contexto y resolución de referencias para el menú de depuración.

var target_character: CharacterBody2D
var target_enemigo: CharacterBody2D
var target_camara: Camera2D
var target_camara_dios: Camera2D
var target_escenario: Node2D
var target_efecto_niebla: EfectoNieblaMutacion
var target_linterna: ControladorLinterna

var camara_zoom_original: Vector2 = Vector2.ONE
var camara_offset_original: Vector2 = Vector2.ZERO


func buscar_nodos(escena_actual: Node, god_view_activo: bool) -> void:
	if escena_actual == null:
		return

	if target_character == null:
		target_character = _buscar_nodo_por_tipo(escena_actual, "CharacterBody2D", ["personaje", "jugador", "player"])

	if target_enemigo == null:
		target_enemigo = _buscar_nodo_por_tipo(escena_actual, "CharacterBody2D", ["enemigo", "monstruo", "enemy"])

	if target_camara == null:
		if target_character != null:
			target_camara = target_character.get_node_or_null("Camera2D") as Camera2D
		if target_camara == null:
			var encontrada := escena_actual.find_child("CamaraJugador", true, false) as Camera2D
			if encontrada != null:
				target_camara = encontrada
			else:
				var candidate := escena_actual.find_child("Camera2D", true, false) as Camera2D
				if candidate != null and candidate != target_camara_dios and candidate.name != "CamaraDios":
					target_camara = candidate
		if target_camara != null and not god_view_activo:
			camara_zoom_original = target_camara.zoom
			camara_offset_original = target_camara.offset

	if target_camara_dios == null:
		target_camara_dios = escena_actual.find_child("CamaraDios", true, false) as Camera2D
		if target_camara_dios == null:
			target_camara_dios = escena_actual.find_child("CamaraGlobal", true, false) as Camera2D

	if target_escenario == null:
		target_escenario = escena_actual.find_child("Escenario", true, false) as Node2D

	if target_efecto_niebla == null or not is_instance_valid(target_efecto_niebla):
		if target_escenario != null:
			target_efecto_niebla = target_escenario.find_child("EfectoNieblaMutacion", true, false) as EfectoNieblaMutacion
		if target_efecto_niebla == null:
			target_efecto_niebla = escena_actual.find_child("EfectoNieblaMutacion", true, false) as EfectoNieblaMutacion

	if target_linterna == null or not is_instance_valid(target_linterna):
		if target_character != null:
			target_linterna = target_character.find_child("PivoteLinterna", true, false) as ControladorLinterna
		if target_linterna == null:
			target_linterna = escena_actual.find_child("PivoteLinterna", true, false) as ControladorLinterna


func _buscar_nodo_por_tipo(nodo_raiz: Node, tipo: String, nombres_clave: Array[String]) -> CharacterBody2D:
	for nombre in nombres_clave:
		var encontrado: Node = nodo_raiz.find_child(nombre, true, false)
		if encontrado != null and encontrado.is_class(tipo):
			return encontrado as CharacterBody2D

	for child in nodo_raiz.get_children():
		if child.is_class(tipo):
			for nombre in nombres_clave:
				if nombre in child.name.to_lower():
					return child as CharacterBody2D
	return null


func calcular_cuadrante(pos: Vector2) -> String:
	var x_str: String = "E" if pos.x >= 0.0 else "O"
	var y_str: String = "S" if pos.y >= 0.0 else "N"
	return y_str + x_str


func obtener_centro_cuadrante(cuad: String) -> String:
	match cuad:
		"NO": return "(-1080, -1080)"
		"NE": return "(1080, -1080)"
		"SO": return "(-1080, 1080)"
		"SE": return "(1080, 1080)"
		_: return "(0, 0)"
