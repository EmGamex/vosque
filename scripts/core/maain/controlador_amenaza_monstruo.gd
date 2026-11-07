@tool
class_name ControladorAmenazaMonstruo
extends RefCounted

## Sub-controlador para la gestión del spawn, despertar y progresión de amenaza del Monstruo.

const DISTANCIA_SEGURA_MONSTRUO_DEFECTO: float = 800.0
const POSICION_FALLBACK_ORIGEN: Vector2 = Vector2(1080.0, 1080.0)
const DISTANCIA_MINIMA_FALLBACK: float = 1000.0


func inicializar_enemigo(enemigo: Enemigo) -> void:
	if enemigo != null and is_instance_valid(enemigo):
		enemigo.hibernar()


func procesar_nota_recolectada(
	notas_recolectadas: int,
	enemigo: Enemigo,
	escenario: Escenario,
	jugador: Node2D,
	distancia_segura: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO
) -> void:
	if enemigo == null or not is_instance_valid(enemigo):
		return

	if notas_recolectadas == 1:
		despertar_monstruo(enemigo, escenario, jugador, distancia_segura)
	else:
		enemigo.actualizar_dificultad(notas_recolectadas)


func despertar_monstruo(
	enemigo: Enemigo,
	escenario: Escenario,
	jugador: Node2D,
	distancia_segura: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO
) -> void:
	if enemigo == null or not is_instance_valid(enemigo):
		return

	var pos_spawn: Vector2 = obtener_posicion_spawn_monstruo(escenario, jugador, distancia_segura)
	enemigo.global_position = pos_spawn
	enemigo.despertar(Enemigo.VELOCIDAD_DESPERTAR_DEFECTO)


func obtener_posicion_spawn_monstruo(
	escenario: Escenario,
	jugador: Node2D,
	distancia_segura: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO
) -> Vector2:
	var pos_jugador: Vector2 = jugador.global_position if (jugador != null and is_instance_valid(jugador)) else Vector2.ZERO
	var candidatos: Array[Marker2D] = []

	if escenario != null and is_instance_valid(escenario):
		var cuadrante_jugador: String = escenario.obtener_cuadrante_jugador(pos_jugador)
		candidatos = escenario.obtener_marcadores_nota_sectores_mutados(cuadrante_jugador)

	return seleccionar_posicion_spawn_monstruo(candidatos, pos_jugador, distancia_segura)


static func seleccionar_posicion_spawn_monstruo(
	candidatos: Array[Marker2D],
	pos_jugador: Vector2,
	distancia_segura: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO
) -> Vector2:
	var validos: Array[Marker2D] = []
	for m in candidatos:
		if m != null and is_instance_valid(m):
			if m.global_position.distance_to(pos_jugador) >= distancia_segura:
				validos.append(m)

	if not validos.is_empty():
		return validos[randi() % validos.size()].global_position

	# Fallback 1: Si ninguno cumple la distancia completa, elegir el más lejano de los candidatos
	var mejor_dist: float = -1.0
	var mejor_pos: Vector2 = Vector2.INF
	for m in candidatos:
		if m != null and is_instance_valid(m):
			var d := m.global_position.distance_to(pos_jugador)
			if d > mejor_dist:
				mejor_dist = d
				mejor_pos = m.global_position
	if mejor_pos != Vector2.INF:
		return mejor_pos

	# Fallback 2: Sin candidatos (ej. pruebas sin subescenas), sector opuesto
	if pos_jugador == Vector2.ZERO:
		return POSICION_FALLBACK_ORIGEN
	return -pos_jugador.normalized() * maxf(distancia_segura, DISTANCIA_MINIMA_FALLBACK)
