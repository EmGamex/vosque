@tool
class_name SpawnerNotas
extends RefCounted

## Sub-controlador especializado en la gestión, filtrado espacial e instanciación de Notas.

const DISTANCIA_SEGURA_JUGADOR_DEFECTO: float = 600.0
const DISTANCIA_SEGURA_MONSTRUO_DEFECTO: float = 800.0
const TOLERANCIA_DESATASCO_SQ: float = 1.0

var nota_activa: Nota = null


func hay_nota_activa() -> bool:
	if nota_activa != null and is_instance_valid(nota_activa):
		if not nota_activa.is_queued_for_deletion() and not nota_activa.esta_recolectada():
			return true
	return false


func generar_nota(
	contenedor: Node2D,
	escena_nota: PackedScene,
	escenario: Escenario,
	jugador: Node2D,
	enemigo: Enemigo,
	distancia_segura_jugador: float = DISTANCIA_SEGURA_JUGADOR_DEFECTO,
	distancia_segura_monstruo: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO,
	callback_recolectada: Callable = Callable()
) -> Nota:
	if hay_nota_activa():
		return null

	if escenario == null or escena_nota == null or contenedor == null:
		return null

	var pos_jugador: Vector2 = jugador.global_position if (jugador != null and is_instance_valid(jugador)) else Vector2.ZERO
	var cuadrante_jugador: String = escenario.obtener_cuadrante_jugador(pos_jugador)

	var pos_monstruo: Vector2 = enemigo.global_position if (enemigo != null and is_instance_valid(enemigo)) else Vector2(INF, INF)
	var pos_desatasco: Vector2 = escenario.ultimo_marcador_desatasco

	var candidatos: Array[Marker2D] = escenario.obtener_marcadores_nota_sectores_mutados(cuadrante_jugador)
	if candidatos.is_empty():
		return null

	var candidatos_validos: Array[Marker2D] = filtrar_candidatos_espaciales(
		candidatos,
		pos_jugador,
		cuadrante_jugador,
		pos_monstruo,
		pos_desatasco,
		distancia_segura_jugador,
		distancia_segura_monstruo,
		Callable(escenario, "calcular_cuadrante")
	)

	var marcador_elegido: Marker2D = elegir_marcador(
		candidatos_validos,
		candidatos,
		pos_jugador,
		cuadrante_jugador,
		Callable(escenario, "calcular_cuadrante")
	)

	if marcador_elegido == null:
		return null

	var nueva_nota: Nota = escena_nota.instantiate() as Nota
	nueva_nota.global_position = marcador_elegido.global_position
	nueva_nota.add_to_group("notas")
	contenedor.add_child(nueva_nota)

	nota_activa = nueva_nota

	if callback_recolectada.is_valid():
		nueva_nota.recolectada.connect(callback_recolectada)

	nueva_nota.tree_exited.connect(func():
		if nota_activa == nueva_nota:
			nota_activa = null
	)

	return nueva_nota


static func filtrar_candidatos_espaciales(
	candidatos: Array[Marker2D],
	pos_jugador: Vector2,
	cuadrante_jugador: String,
	pos_monstruo: Vector2,
	pos_desatasco: Vector2,
	dist_min_jugador: float = DISTANCIA_SEGURA_JUGADOR_DEFECTO,
	dist_min_monstruo: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO,
	calculador_cuadrante: Callable = Callable()
) -> Array[Marker2D]:
	var validos: Array[Marker2D] = []

	for m in candidatos:
		if m == null or not is_instance_valid(m):
			continue
		var p_m: Vector2 = m.global_position

		# Filtro 1: Exclusión de cuadrante activo
		var cuad_m: String = ""
		if calculador_cuadrante.is_valid():
			cuad_m = calculador_cuadrante.call(p_m)
		else:
			cuad_m = calcular_cuadrante_estatico(p_m)

		if not cuadrante_jugador.is_empty() and cuad_m == cuadrante_jugador:
			continue

		# Filtro 2: Distancia mínima al Jugador
		if p_m.distance_to(pos_jugador) < dist_min_jugador:
			continue

		# Filtro 3: Distancia mínima al Monstruo
		if pos_monstruo != Vector2(INF, INF) and p_m.distance_to(pos_monstruo) < dist_min_monstruo:
			continue

		# Filtro 4: Exclusión de Desatasco (p_m != pos_desatasco)
		if pos_desatasco != Vector2(INF, INF) and (p_m.is_equal_approx(pos_desatasco) or p_m.distance_squared_to(pos_desatasco) < TOLERANCIA_DESATASCO_SQ):
			continue

		validos.append(m)

	return validos


static func elegir_marcador(
	candidatos_validos: Array[Marker2D],
	candidatos_totales: Array[Marker2D],
	pos_jugador: Vector2,
	cuadrante_jugador: String,
	calculador_cuadrante: Callable = Callable()
) -> Marker2D:
	if not candidatos_validos.is_empty():
		return candidatos_validos[randi() % candidatos_validos.size()]

	# Fallback: Elegir de los sectores mutados el marcador cuya distancia al jugador sea la máxima posible
	var mejor_marcador: Marker2D = null
	var max_dist: float = -1.0

	for m in candidatos_totales:
		if m == null or not is_instance_valid(m):
			continue
		var p_m: Vector2 = m.global_position

		var cuad_m: String = ""
		if calculador_cuadrante.is_valid():
			cuad_m = calculador_cuadrante.call(p_m)
		else:
			cuad_m = calcular_cuadrante_estatico(p_m)

		if not cuadrante_jugador.is_empty() and cuad_m == cuadrante_jugador:
			continue

		var dist: float = p_m.distance_to(pos_jugador)
		if dist > max_dist:
			max_dist = dist
			mejor_marcador = m

	return mejor_marcador


static func calcular_cuadrante_estatico(pos: Vector2) -> String:
	var x_str: String = "E" if pos.x >= 0.0 else "O"
	var y_str: String = "S" if pos.y >= 0.0 else "N"
	return y_str + x_str
