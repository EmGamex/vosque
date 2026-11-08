@tool
class_name GestorSectores
extends RefCounted

## Gestor de topología y ciclo de vida de los sectores 2x2 (NO, NE, SO, SE).
## Administra instancias, asignación de variantes y búsqueda de marcadores de nota.

const SECTORES: Array[String] = ["NO", "NE", "SO", "SE"]

var variantes_activas: Dictionary = {
	"NO": "",
	"NE": "",
	"SO": "",
	"SE": ""
}

var instancias_sectores: Dictionary = {
	"NO": null,
	"NE": null,
	"SO": null,
	"SE": null
}

var nodo_no: Node2D
var nodo_ne: Node2D
var nodo_so: Node2D
var nodo_se: Node2D


func inicializar_nodos(no: Node2D, ne: Node2D, so: Node2D, se: Node2D) -> void:
	nodo_no = no
	nodo_ne = ne
	nodo_so = so
	nodo_se = se


func obtener_nodo_sector(sector: String) -> Node2D:
	match sector:
		"NO": return nodo_no
		"NE": return nodo_ne
		"SO": return nodo_so
		"SE": return nodo_se
	return null


func instanciar_variante_en_sector(sector: String, escena: PackedScene) -> Node2D:
	var nodo_padre: Node2D = obtener_nodo_sector(sector)
	if nodo_padre == null or escena == null:
		return null

	var anterior = instancias_sectores.get(sector)
	if anterior != null and is_instance_valid(anterior):
		nodo_padre.remove_child(anterior)
		anterior.queue_free()

	var nueva_instancia: Node2D = escena.instantiate() as Node2D
	nodo_padre.add_child(nueva_instancia)
	instancias_sectores[sector] = nueva_instancia

	var nombre_variante: String = escena.resource_path.get_file().get_basename()
	if nombre_variante.is_empty():
		nombre_variante = nueva_instancia.name
	variantes_activas[sector] = nombre_variante

	return nueva_instancia


func inicializar_sectores_por_defecto(catalogo: Array[PackedScene]) -> void:
	if catalogo.is_empty():
		return

	for i in range(SECTORES.size()):
		var sector: String = SECTORES[i]
		var escena: PackedScene = catalogo[i % catalogo.size()]
		instanciar_variante_en_sector(sector, escena)


func obtener_cuadrante(pos_global: Vector2) -> String:
	var x_str: String = "E" if pos_global.x >= 0.0 else "O"
	var y_str: String = "S" if pos_global.y >= 0.0 else "N"
	return y_str + x_str


func obtener_marcadores_nota_sectores_mutados(cuadrante_excluido: String = "") -> Array[Marker2D]:
	var resultado: Array[Marker2D] = []
	for sector in SECTORES:
		if not cuadrante_excluido.is_empty() and sector == cuadrante_excluido:
			continue
		var instancia: Node2D = instancias_sectores.get(sector)
		if instancia != null and is_instance_valid(instancia):
			for child in instancia.find_children("", "Marker2D", true, false):
				if child.is_in_group("puntos_nota") and child is Marker2D:
					resultado.append(child as Marker2D)
	return resultado


func obtener_todos_marcadores_nota() -> Array[Marker2D]:
	return obtener_marcadores_nota_sectores_mutados("")
