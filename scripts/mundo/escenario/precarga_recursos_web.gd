@tool
class_name PrecargaRecursosWeb
extends RefCounted

## Utilidad de precalentamiento (warmup) de shaders WebGL fuera de pantalla
## para evitar tirones (shader compilation stuttering) en exportaciones HTML5.


func precalentar_recursos_web(nodo_padre: Node2D, catalogo: Array[PackedScene]) -> void:
	if nodo_padre == null or not nodo_padre.is_inside_tree() or catalogo.is_empty():
		return

	var contenedor_warmup := Node2D.new()
	contenedor_warmup.name = "WarmupSectores"
	contenedor_warmup.visible = false
	contenedor_warmup.process_mode = Node.PROCESS_MODE_DISABLED
	nodo_padre.add_child(contenedor_warmup)

	for variante in catalogo:
		if variante != null:
			var inst := variante.instantiate() as Node2D
			if inst != null:
				contenedor_warmup.add_child(inst)

	var arbol := nodo_padre.get_tree()
	if arbol != null:
		await arbol.process_frame
	if is_instance_valid(contenedor_warmup):
		contenedor_warmup.queue_free()
