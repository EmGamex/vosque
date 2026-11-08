@tool
class_name ResolutorAtascamiento
extends RefCounted

## Administrador de validación física y desatasco de entidades (especialmente el Enemigo)
## tras las mutaciones espaciales del escenario.

var gestor_sectores: GestorSectores
var ultimo_marcador_desatasco: Vector2 = Vector2.INF


func _init(p_gestor_sectores: GestorSectores = null) -> void:
	gestor_sectores = p_gestor_sectores


func validar_y_reubicar_enemigo(
	enemigo: CharacterBody2D,
	pos_jugador: Vector2
) -> Dictionary:
	var res := {
		"reubicado": false,
		"pos_anterior": Vector2.ZERO,
		"pos_nueva": Vector2.ZERO,
		"sector": ""
	}

	if enemigo == null or not is_instance_valid(enemigo):
		return res

	if enemigo.get("hibernando") == true or enemigo.process_mode == Node.PROCESS_MODE_DISABLED:
		return res

	var pos_enemigo: Vector2 = enemigo.global_position
	var sector_enemigo: String = gestor_sectores.obtener_cuadrante(pos_enemigo) if gestor_sectores != null else ""

	var necesita_reubicacion: bool = verificar_solapamiento_solido(enemigo)

	if necesita_reubicacion:
		var punto_seguro: Vector2 = obtener_punto_seguro_en_sector(sector_enemigo, pos_enemigo, pos_jugador)
		if punto_seguro != pos_enemigo:
			var pos_ant: Vector2 = enemigo.global_position
			enemigo.global_position = punto_seguro
			enemigo.velocity = Vector2.ZERO
			ultimo_marcador_desatasco = punto_seguro

			res["reubicado"] = true
			res["pos_anterior"] = pos_ant
			res["pos_nueva"] = punto_seguro
			res["sector"] = sector_enemigo
			return res
	else:
		ultimo_marcador_desatasco = Vector2.INF

	return res


func verificar_solapamiento_solido(enemigo: CharacterBody2D) -> bool:
	if enemigo == null or not is_instance_valid(enemigo):
		return false

	if enemigo.test_move(enemigo.global_transform, Vector2.ZERO):
		return true

	var world := enemigo.get_world_2d()
	if world != null:
		var space_state := world.direct_space_state
		if space_state != null:
			var params := PhysicsPointQueryParameters2D.new()
			params.position = enemigo.global_position
			params.collision_mask = 3 # Capas 1 (Mundo_Alto) y 2 (Obstaculos_Bajos)
			params.collide_with_bodies = true
			params.collide_with_areas = false
			params.exclude = [enemigo.get_rid()]

			var resultados := space_state.intersect_point(params, 4)
			if not resultados.is_empty():
				return true

	return false


func obtener_punto_seguro_en_sector(
	sector: String,
	pos_referencia: Vector2,
	pos_jugador: Vector2 = Vector2.INF
) -> Vector2:
	if gestor_sectores == null:
		return pos_referencia

	var instancia: Node2D = gestor_sectores.instancias_sectores.get(sector)
	if instancia == null or not is_instance_valid(instancia):
		return pos_referencia

	var marcadores: Array[Node] = instancia.find_children("", "Marker2D", true, false)
	var candidatos_puntos: Array[Vector2] = []

	for m in marcadores:
		if m.is_in_group("puntos_nota"):
			var p: Vector2 = (m as Marker2D).global_position
			if pos_jugador != Vector2.INF and p.distance_to(pos_jugador) < 600.0:
				continue
			candidatos_puntos.append(p)

	if candidatos_puntos.is_empty():
		for m in marcadores:
			if m.is_in_group("puntos_nota"):
				candidatos_puntos.append((m as Marker2D).global_position)

	if candidatos_puntos.is_empty():
		var nodo_sector: Node2D = gestor_sectores.obtener_nodo_sector(sector)
		return nodo_sector.global_position if nodo_sector != null else pos_referencia

	var punto_optimo: Vector2 = candidatos_puntos[0]
	var dist_min: float = pos_referencia.distance_squared_to(punto_optimo)

	for p in candidatos_puntos:
		var d: float = pos_referencia.distance_squared_to(p)
		if d < dist_min:
			dist_min = d
			punto_optimo = p

	return punto_optimo
