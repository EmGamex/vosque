@tool
class_name Maain
extends Node2D

## Game Director y orquestador del bucle principal de Vosque.
## Gestiona el ciclo de vida del escenario, la mutación bajo niebla y el Spawner Espacial de Notas.

signal nota_aparecida(posicion: Vector2)
signal nota_recogida(posicion: Vector2, total_recogidas: int)

const DISTANCIA_SEGURA_JUGADOR_DEFECTO: float = 600.0
const DISTANCIA_SEGURA_MONSTRUO_DEFECTO: float = 800.0

@export var escena_nota: PackedScene = preload("res://escenas/nota.tscn")
@export var distancia_segura_jugador: float = DISTANCIA_SEGURA_JUGADOR_DEFECTO
@export var distancia_segura_monstruo: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO

@onready var escenario: Escenario = get_node_or_null("Escenario") as Escenario
@onready var jugador: Node2D = get_node_or_null("personaje") as Node2D
@onready var enemigo: Enemigo = get_node_or_null("Enemigo") as Enemigo

var nota_activa: Nota = null
var notas_recolectadas: int = 0


func _ready() -> void:
	if Engine.is_editor_hint() and not is_in_group("modo_test"):
		return
	_resolver_referencias()
	_conectar_senales_escenario()
	if enemigo != null and is_instance_valid(enemigo):
		enemigo.hibernar()
	call_deferred("spawn_nota_inicial")


func _resolver_referencias() -> void:
	if escenario == null:
		escenario = get_node_or_null("Escenario") as Escenario
	if jugador == null:
		jugador = get_node_or_null("personaje") as Node2D
		if jugador == null:
			jugador = get_node_or_null("EmGamex") as Node2D
	if enemigo == null:
		enemigo = get_node_or_null("Enemigo") as Enemigo


func _conectar_senales_escenario() -> void:
	if escenario != null and not escenario.sectores_mutados.is_connected(_on_sectores_mutados):
		escenario.sectores_mutados.connect(_on_sectores_mutados)


func hay_nota_activa() -> bool:
	if nota_activa != null and is_instance_valid(nota_activa):
		if not nota_activa.is_queued_for_deletion() and not nota_activa._recolectada:
			return true

	if is_inside_tree():
		var tree := get_tree()
		if tree != null:
			var notas_arbol: Array[Node] = tree.get_nodes_in_group("notas")
			for nodo in notas_arbol:
				if nodo is Nota and is_instance_valid(nodo):
					if not nodo.is_queued_for_deletion() and not nodo._recolectada:
						return true
	return false


func spawn_nota_inicial() -> Nota:
	if hay_nota_activa():
		return nota_activa
	return generar_nota()


func generar_nota() -> Nota:
	# 1. Invariante de Existencia
	if hay_nota_activa():
		return null

	_resolver_referencias()
	if escenario == null or escena_nota == null:
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
	add_child(nueva_nota)

	nota_activa = nueva_nota
	nueva_nota.recolectada.connect(_on_nota_recolectada)
	nueva_nota.tree_exited.connect(func():
		if nota_activa == nueva_nota:
			nota_activa = null
	)

	nota_aparecida.emit(nueva_nota.global_position)
	return nueva_nota


func _on_nota_recolectada(pos_nota: Vector2) -> void:
	nota_activa = null
	notas_recolectadas += 1
	nota_recogida.emit(pos_nota, notas_recolectadas)

	_resolver_referencias()
	if enemigo != null and is_instance_valid(enemigo):
		if notas_recolectadas == 1:
			despertar_monstruo()
		else:
			enemigo.actualizar_dificultad(notas_recolectadas)

	if escenario != null and is_instance_valid(escenario):
		if escenario.has_method("actualizar_iluminacion_ambiental"):
			escenario.actualizar_iluminacion_ambiental(notas_recolectadas)
		# Disparar mutación en frame diferido para evitar alterar estado durante flushing_queries
		escenario.call_deferred("mutar_con_neblina")


func despertar_monstruo() -> void:
	if enemigo == null or not is_instance_valid(enemigo):
		return

	var pos_spawn: Vector2 = obtener_posicion_spawn_monstruo()
	enemigo.global_position = pos_spawn
	enemigo.visible = true
	enemigo.process_mode = Node.PROCESS_MODE_INHERIT
	enemigo.despertar(500.0)


func obtener_posicion_spawn_monstruo() -> Vector2:
	var pos_jugador: Vector2 = jugador.global_position if (jugador != null and is_instance_valid(jugador)) else Vector2.ZERO
	var cuadrante_jugador: String = ""
	var candidatos: Array[Marker2D] = []

	if escenario != null and is_instance_valid(escenario):
		cuadrante_jugador = escenario.obtener_cuadrante_jugador(pos_jugador)
		candidatos = escenario.obtener_marcadores_nota_sectores_mutados(cuadrante_jugador)

	return seleccionar_posicion_spawn_monstruo(candidatos, pos_jugador, distancia_segura_monstruo)


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
		return Vector2(1080.0, 1080.0)
	return -pos_jugador.normalized() * maxf(distancia_segura, 1000.0)


func _on_sectores_mutados(_cuadrante_jugador: String, _variantes: Dictionary) -> void:
	call_deferred("generar_nota")


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

		# Filtro 2: Distancia mínima al Jugador (>= 600 px)
		if p_m.distance_to(pos_jugador) < dist_min_jugador:
			continue

		# Filtro 3: Distancia mínima al Monstruo (>= 800 px)
		if pos_monstruo != Vector2(INF, INF) and p_m.distance_to(pos_monstruo) < dist_min_monstruo:
			continue

		# Filtro 4: Exclusión de Desatasco (p_M != p_desatasco)
		if pos_desatasco != Vector2(INF, INF) and (p_m.is_equal_approx(pos_desatasco) or p_m.distance_squared_to(pos_desatasco) < 1.0):
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
