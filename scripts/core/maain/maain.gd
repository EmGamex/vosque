@tool
class_name Maain
extends Node2D

## Game Director y orquestador del bucle principal de Vosque.
## Gestiona el ciclo de vida del escenario, la mutación y coordina SpawnerNotas y ControladorAmenazaMonstruo.

signal nota_aparecida(posicion: Vector2)
signal nota_revelada(posicion: Vector2)
signal nota_recogida(posicion: Vector2, total_recogidas: int)
signal game_over_solicitado

const DISTANCIA_SEGURA_JUGADOR_DEFECTO: float = SpawnerNotas.DISTANCIA_SEGURA_JUGADOR_DEFECTO
const DISTANCIA_SEGURA_MONSTRUO_DEFECTO: float = SpawnerNotas.DISTANCIA_SEGURA_MONSTRUO_DEFECTO

@export var escena_nota: PackedScene = preload("res://escenas/nota.tscn")
@export var distancia_segura_jugador: float = DISTANCIA_SEGURA_JUGADOR_DEFECTO
@export var distancia_segura_monstruo: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO

@onready var escenario: Escenario = get_node_or_null("Escenario") as Escenario
@onready var jugador: Node2D = get_node_or_null("personaje") as Node2D
@onready var enemigo: Enemigo = get_node_or_null("Enemigo") as Enemigo
@onready var hud: HUD = get_node_or_null("HUD") as HUD

var spawner_notas: SpawnerNotas = SpawnerNotas.new()
var amenaza_monstruo: ControladorAmenazaMonstruo = ControladorAmenazaMonstruo.new()

var nota_activa: Nota:
	get:
		return spawner_notas.nota_activa
	set(valor):
		spawner_notas.nota_activa = valor

var notas_recolectadas: int = 0
var partida_terminada: bool = false


func _ready() -> void:
	add_to_group("director_juego")
	if Engine.is_editor_hint() and not is_in_group("modo_test"):
		return
	_resolver_referencias()
	_inyectar_dependencias()
	_conectar_senales_escenario()
	_conectar_senales_enemigo()
	if not visibility_changed.is_connected(_on_visibility_changed):
		visibility_changed.connect(_on_visibility_changed)
	_on_visibility_changed()

	if hud != null and is_instance_valid(hud):
		hud.actualizar_contador(notas_recolectadas, false)
		if jugador != null and is_instance_valid(jugador):
			hud.actualizar_posicion_jugador_minimapa(jugador.global_position)

	amenaza_monstruo.inicializar_enemigo(enemigo)

	var musica := _obtener_gestor_musica()
	if musica != null and musica.has_method("reproducir_menu_o_tutorial"):
		musica.reproducir_menu_o_tutorial()

	call_deferred("spawn_nota_inicial")


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or partida_terminada:
		return
	if hud != null and is_instance_valid(hud) and jugador != null and is_instance_valid(jugador):
		hud.actualizar_posicion_jugador_minimapa(jugador.global_position)


func _on_visibility_changed() -> void:
	if hud != null and is_instance_valid(hud):
		hud.visible = is_visible_in_tree()
	if not is_visible_in_tree():
		if escenario != null and is_instance_valid(escenario) and escenario.has_method("abortar_mutacion"):
			escenario.abortar_mutacion()


func _resolver_referencias() -> void:
	if escenario == null:
		escenario = get_node_or_null("Escenario") as Escenario
	if jugador == null:
		jugador = get_node_or_null("personaje") as Node2D
		if jugador == null and is_inside_tree():
			jugador = get_tree().get_first_node_in_group("jugador") as Node2D
	if enemigo == null:
		enemigo = get_node_or_null("Enemigo") as Enemigo
	if hud == null:
		hud = get_node_or_null("HUD") as HUD


func _inyectar_dependencias() -> void:
	if enemigo != null and is_instance_valid(enemigo) and jugador != null:
		if enemigo.objetivo == null:
			enemigo.objetivo = jugador
	if escenario != null and is_instance_valid(escenario):
		if jugador != null and escenario.objetivo_jugador == null:
			escenario.objetivo_jugador = jugador
		if enemigo != null and escenario.objetivo_enemigo == null:
			escenario.objetivo_enemigo = enemigo


func _conectar_senales_escenario() -> void:
	if escenario != null and not escenario.sectores_mutados.is_connected(_on_sectores_mutados):
		escenario.sectores_mutados.connect(_on_sectores_mutados)


func _conectar_senales_enemigo() -> void:
	if enemigo != null and not enemigo.jugador_capturado.is_connected(_on_jugador_capturado):
		enemigo.jugador_capturado.connect(_on_jugador_capturado)


func _on_jugador_capturado(_posicion_captura: Vector2) -> void:
	if partida_terminada:
		return
	partida_terminada = true

	var musica := _obtener_gestor_musica()
	if musica != null and musica.has_method("detener_por_jumpscare"):
		musica.detener_por_jumpscare()

	var persistencia := _obtener_gestor_persistencia()
	if persistencia != null and persistencia.has_method("guardar_high_score"):
		persistencia.guardar_high_score(notas_recolectadas)

	if jugador != null and is_instance_valid(jugador):
		if jugador.has_method("detener_por_captura"):
			jugador.detener_por_captura()
		else:
			jugador.set("velocity", Vector2.ZERO)
			jugador.set_physics_process(false)

	game_over_solicitado.emit()


func hay_nota_activa() -> bool:
	return spawner_notas.hay_nota_activa()


func spawn_nota_inicial() -> Nota:
	if hay_nota_activa():
		return nota_activa
	return generar_nota()


func generar_nota() -> Nota:
	if partida_terminada:
		return null

	_resolver_referencias()

	var nueva_nota := spawner_notas.generar_nota(
		self,
		escena_nota,
		escenario,
		jugador,
		enemigo,
		distancia_segura_jugador,
		distancia_segura_monstruo,
		_on_nota_recolectada,
		_on_nota_revelada
	)

	if nueva_nota != null:
		nota_aparecida.emit(nueva_nota.global_position)
		if hud != null and is_instance_valid(hud):
			var cuadrante_nota: String = (
				escenario.calcular_cuadrante(nueva_nota.global_position)
				if (escenario != null and is_instance_valid(escenario))
				else SpawnerNotas.calcular_cuadrante_estatico(nueva_nota.global_position)
			)
			hud.actualizar_minimapa_objetivo(cuadrante_nota, nueva_nota.esta_revelada())

	return nueva_nota


func _on_nota_revelada(pos_nota: Vector2) -> void:
	if partida_terminada:
		return
	nota_revelada.emit(pos_nota)
	if hud != null and is_instance_valid(hud):
		hud.marcar_nota_minimapa_revelada(true)


func _on_nota_recolectada(pos_nota: Vector2) -> void:
	if partida_terminada:
		return

	notas_recolectadas += 1
	nota_recogida.emit(pos_nota, notas_recolectadas)

	if hud != null and is_instance_valid(hud):
		hud.actualizar_contador(notas_recolectadas, true)
		hud.limpiar_minimapa_objetivo()

	amenaza_monstruo.procesar_nota_recolectada(
		notas_recolectadas,
		enemigo,
		escenario,
		jugador,
		distancia_segura_monstruo
	)

	if notas_recolectadas == 1:
		call_deferred("_transicionar_musica_supervivencia_diferida")

	if escenario != null and is_instance_valid(escenario):
		if escenario.has_method("actualizar_iluminacion_ambiental"):
			escenario.actualizar_iluminacion_ambiental(notas_recolectadas)
		escenario.call_deferred("mutar_con_neblina")


func _transicionar_musica_supervivencia_diferida() -> void:
	var musica := _obtener_gestor_musica()
	if musica != null and musica.has_method("transicionar_a_supervivencia"):
		musica.transicionar_a_supervivencia()


func despertar_monstruo() -> void:
	amenaza_monstruo.despertar_monstruo(enemigo, escenario, jugador, distancia_segura_monstruo)


func obtener_posicion_spawn_monstruo() -> Vector2:
	return amenaza_monstruo.obtener_posicion_spawn_monstruo(escenario, jugador, distancia_segura_monstruo)


func _on_sectores_mutados(_cuadrante_jugador: String, _variantes: Dictionary) -> void:
	call_deferred("generar_nota")


func _obtener_gestor_musica() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	if tree.root.has_node("GestorMusica"):
		return tree.root.get_node("GestorMusica")
	return null


func _obtener_gestor_persistencia() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	if tree.root.has_node("GestorPersistencia"):
		return tree.root.get_node("GestorPersistencia")
	return null


# --- Métodos estáticos de compatibilidad delegados ---

static func seleccionar_posicion_spawn_monstruo(
	candidatos: Array[Marker2D],
	pos_jugador: Vector2,
	distancia_segura: float = DISTANCIA_SEGURA_MONSTRUO_DEFECTO
) -> Vector2:
	return ControladorAmenazaMonstruo.seleccionar_posicion_spawn_monstruo(candidatos, pos_jugador, distancia_segura)


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
	return SpawnerNotas.filtrar_candidatos_espaciales(
		candidatos,
		pos_jugador,
		cuadrante_jugador,
		pos_monstruo,
		pos_desatasco,
		dist_min_jugador,
		dist_min_monstruo,
		calculador_cuadrante
	)


static func elegir_marcador(
	candidatos_validos: Array[Marker2D],
	candidatos_totales: Array[Marker2D],
	pos_jugador: Vector2,
	cuadrante_jugador: String,
	calculador_cuadrante: Callable = Callable()
) -> Marker2D:
	return SpawnerNotas.elegir_marcador(
		candidatos_validos,
		candidatos_totales,
		pos_jugador,
		cuadrante_jugador,
		calculador_cuadrante
	)


static func calcular_cuadrante_estatico(pos: Vector2) -> String:
	return SpawnerNotas.calcular_cuadrante_estatico(pos)
