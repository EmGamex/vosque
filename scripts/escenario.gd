@tool
class_name Escenario
extends Node2D

## Gestor del escenario principal 2x2 de Vosque con mutación espacial y anti-atascamiento.

signal sectores_mutados(cuadrante_jugador: String, variantes: Dictionary)
signal enemigo_reubicado(posicion_anterior: Vector2, posicion_nueva: Vector2, sector: String)

const SECTORES: Array[String] = ["NO", "NE", "SO", "SE"]
const RUTAS_VARIANTES_DEFECTO: Array[String] = [
	"res://escenas/sectores/variantes/variante_claro_rocoso.tscn",
	"res://escenas/sectores/variantes/variante_bosque_denso.tscn",
	"res://escenas/sectores/variantes/variante_sendero_troncos.tscn",
]

@export var objetivo_jugador: Node2D
@export var objetivo_enemigo: CharacterBody2D
@export var catalogo_variantes: Array[PackedScene] = []

var variantes_activas: Dictionary = {
	"NO": "",
	"NE": "",
	"SO": "",
	"SE": ""
}

var _instancias_sectores: Dictionary = {
	"NO": null,
	"NE": null,
	"SO": null,
	"SE": null
}

var _mutacion_en_progreso: bool = false

@onready var _efecto_niebla: EfectoNieblaMutacion = get_node_or_null("EfectoNieblaMutacion") as EfectoNieblaMutacion
@onready var _nodo_no: Node2D = get_node_or_null("Sectores/SectorNO") as Node2D
@onready var _nodo_ne: Node2D = get_node_or_null("Sectores/SectorNE") as Node2D
@onready var _nodo_so: Node2D = get_node_or_null("Sectores/SectorSO") as Node2D
@onready var _nodo_se: Node2D = get_node_or_null("Sectores/SectorSE") as Node2D


func _ready() -> void:
	y_sort_enabled = true
	_resolver_referencias_objetivos()
	_inicializar_catalogo()
	_instanciar_sectores_iniciales()


func _resolver_referencias_objetivos() -> void:
	if objetivo_jugador == null and get_parent() != null:
		objetivo_jugador = get_parent().find_child("personaje", true, false) as Node2D
		if objetivo_jugador == null:
			objetivo_jugador = get_parent().find_child("EmGamex", true, false) as Node2D

	if objetivo_enemigo == null and get_parent() != null:
		objetivo_enemigo = get_parent().find_child("Enemigo", true, false) as CharacterBody2D

	if _efecto_niebla == null:
		_efecto_niebla = get_node_or_null("EfectoNieblaMutacion") as EfectoNieblaMutacion
	if _efecto_niebla != null and _efecto_niebla.objetivo_jugador == null:
		_efecto_niebla.objetivo_jugador = objetivo_jugador


func _inicializar_catalogo() -> void:
	if catalogo_variantes.is_empty():
		for ruta in RUTAS_VARIANTES_DEFECTO:
			if ResourceLoader.exists(ruta):
				var res = load(ruta) as PackedScene
				if res != null:
					catalogo_variantes.append(res)


func _instanciar_sectores_iniciales() -> void:
	if catalogo_variantes.is_empty():
		return

	for i in range(SECTORES.size()):
		var sector: String = SECTORES[i]
		var escena: PackedScene = catalogo_variantes[i % catalogo_variantes.size()]
		_instanciar_variante_en_sector(sector, escena)


func _obtener_nodo_sector(sector: String) -> Node2D:
	if _nodo_no == null:
		_nodo_no = get_node_or_null("Sectores/SectorNO") as Node2D
		_nodo_ne = get_node_or_null("Sectores/SectorNE") as Node2D
		_nodo_so = get_node_or_null("Sectores/SectorSO") as Node2D
		_nodo_se = get_node_or_null("Sectores/SectorSE") as Node2D

	match sector:
		"NO": return _nodo_no
		"NE": return _nodo_ne
		"SO": return _nodo_so
		"SE": return _nodo_se
	return null


func _instanciar_variante_en_sector(sector: String, escena: PackedScene) -> void:
	var nodo_padre: Node2D = _obtener_nodo_sector(sector)
	if nodo_padre == null or escena == null:
		return

	# Limpiar instancia previa
	var anterior = _instancias_sectores.get(sector)
	if anterior != null and is_instance_valid(anterior):
		nodo_padre.remove_child(anterior)
		anterior.queue_free()

	# Instanciar nueva variante
	var nueva_instancia: Node2D = escena.instantiate() as Node2D
	nodo_padre.add_child(nueva_instancia)
	_instancias_sectores[sector] = nueva_instancia

	# Guardar nombre descriptivo de la variante
	var nombre_variante: String = escena.resource_path.get_file().get_basename()
	if nombre_variante.is_empty():
		nombre_variante = nueva_instancia.name
	variantes_activas[sector] = nombre_variante


func obtener_cuadrante_jugador(pos_global: Vector2) -> String:
	var x_str: String = "E" if pos_global.x >= 0.0 else "O"
	var y_str: String = "S" if pos_global.y >= 0.0 else "N"
	return y_str + x_str


func calcular_cuadrante(pos_global: Vector2) -> String:
	return obtener_cuadrante_jugador(pos_global)


func forzar_mutacion() -> void:
	mutar_con_neblina()


func mutar_con_neblina(
	duracion_cierre: float = -1.0,
	duracion_apertura: float = -1.0,
	pausa_oscuridad: float = -1.0
) -> void:
	if _mutacion_en_progreso:
		return
	_mutacion_en_progreso = true

	if _efecto_niebla == null:
		_efecto_niebla = get_node_or_null("EfectoNieblaMutacion") as EfectoNieblaMutacion

	if _efecto_niebla != null:
		var t_cierre: float = duracion_cierre if duracion_cierre >= 0.0 else _efecto_niebla.duracion_cierre
		var t_apertura: float = duracion_apertura if duracion_apertura >= 0.0 else _efecto_niebla.duracion_apertura
		var t_pausa: float = pausa_oscuridad if pausa_oscuridad >= 0.0 else _efecto_niebla.pausa_oscuridad

		_efecto_niebla.cubrir(t_cierre)
		await _efecto_niebla.ceguera_alcanzada
		mutar_sectores_lejanos()
		if t_pausa > 0.0:
			var tree = get_tree()
			if tree != null:
				await tree.create_timer(t_pausa).timeout
		_efecto_niebla.despejar(t_apertura)
		await _efecto_niebla.niebla_disipada
	else:
		mutar_sectores_lejanos()

	_mutacion_en_progreso = false


func mutar_sectores_lejanos() -> void:
	_inicializar_catalogo()
	if catalogo_variantes.is_empty():
		return

	_resolver_referencias_objetivos()

	var pos_jugador: Vector2 = objetivo_jugador.global_position if objetivo_jugador != null else Vector2.ZERO
	var cuadrante_activo: String = obtener_cuadrante_jugador(pos_jugador)

	for sector in SECTORES:
		if sector == cuadrante_activo:
			continue # El sector donde está el jugador NO muta

		# Seleccionar una variante aleatoria distinta a la actual si hay opciones disponibles
		var variante_actual_nombre: String = variantes_activas.get(sector, "")
		var candidatos: Array[PackedScene] = []
		for var_scene in catalogo_variantes:
			if var_scene.resource_path.get_file().get_basename() != variante_actual_nombre:
				candidatos.append(var_scene)

		var elegida: PackedScene
		if not candidatos.is_empty():
			elegida = candidatos[randi() % candidatos.size()]
		else:
			elegida = catalogo_variantes[randi() % catalogo_variantes.size()]

		_instanciar_variante_en_sector(sector, elegida)

	validar_y_reubicar_enemigo()
	sectores_mutados.emit(cuadrante_activo, variantes_activas)


func validar_y_reubicar_enemigo() -> void:
	if objetivo_enemigo == null or not is_instance_valid(objetivo_enemigo):
		return

	var pos_enemigo: Vector2 = objetivo_enemigo.global_position
	var sector_enemigo: String = calcular_cuadrante(pos_enemigo)

	# Comprobar si el enemigo está solapando con obstáculos sólidos
	var necesita_reubicacion: bool = _verificar_solapamiento_solido(objetivo_enemigo)

	if necesita_reubicacion:
		var punto_seguro: Vector2 = _obtener_punto_seguro_en_sector(sector_enemigo, pos_enemigo)
		if punto_seguro != pos_enemigo:
			var pos_anterior: Vector2 = objetivo_enemigo.global_position
			objetivo_enemigo.global_position = punto_seguro
			objetivo_enemigo.velocity = Vector2.ZERO
			enemigo_reubicado.emit(pos_anterior, punto_seguro, sector_enemigo)


func _verificar_solapamiento_solido(enemigo: CharacterBody2D) -> bool:
	# 1. Comprobación física directa mediante test_move
	if enemigo.test_move(enemigo.global_transform, Vector2.ZERO):
		return true

	# 2. Comprobación geométrica en el sector activo mediante consulta de espacio físico
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


func _obtener_punto_seguro_en_sector(sector: String, pos_referencia: Vector2) -> Vector2:
	var instancia: Node2D = _instancias_sectores.get(sector)
	if instancia == null or not is_instance_valid(instancia):
		return pos_referencia

	var marcadores: Array[Node] = instancia.find_children("", "Marker2D", true, false)
	var candidatos_puntos: Array[Vector2] = []

	for m in marcadores:
		if m.is_in_group("puntos_nota"):
			candidatos_puntos.append((m as Marker2D).global_position)

	if candidatos_puntos.is_empty():
		# Fallback al centro del sector si no hay marcadores
		var nodo_sector: Node2D = _obtener_nodo_sector(sector)
		return nodo_sector.global_position if nodo_sector != null else pos_referencia

	# Seleccionar el marcador más cercano a la posición donde estaba el enemigo
	var punto_optimo: Vector2 = candidatos_puntos[0]
	var dist_min: float = pos_referencia.distance_squared_to(punto_optimo)

	for p in candidatos_puntos:
		var d: float = pos_referencia.distance_squared_to(p)
		if d < dist_min:
			dist_min = d
			punto_optimo = p

	return punto_optimo
