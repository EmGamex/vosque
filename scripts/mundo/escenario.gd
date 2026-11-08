@tool
class_name Escenario
extends Node2D

## Gestor del escenario principal 2x2 de Vosque con mutación espacial y anti-atascamiento.
## Actúa como fachada orquestadora delegando en subcontroladores especializados:
## GestorSectores, MutadorSectores, ResolutorAtascamiento, GestorIluminacionAmbiental y PrecargaRecursosWeb.

signal sectores_mutados(cuadrante_jugador: String, variantes: Dictionary)
signal enemigo_reubicado(posicion_anterior: Vector2, posicion_nueva: Vector2, sector: String)

const SECTORES: Array[String] = GestorSectores.SECTORES
const RUTAS_VARIANTES_DEFECTO: Array[String] = [
	"res://escenas/sectores/variantes/variante_claro_rocoso.tscn",
	"res://escenas/sectores/variantes/variante_bosque_denso.tscn",
	"res://escenas/sectores/variantes/variante_sendero_troncos.tscn",
]

@export var objetivo_jugador: Node2D
@export var objetivo_enemigo: CharacterBody2D
@export var catalogo_variantes: Array[PackedScene] = []
@export var config_iluminacion: ConfiguracionIluminacion

var gestor_sectores: GestorSectores = GestorSectores.new()
var mutador_sectores: MutadorSectores = MutadorSectores.new()
var resolutor_atascamiento: ResolutorAtascamiento = ResolutorAtascamiento.new()
var gestor_iluminacion: GestorIluminacionAmbiental = GestorIluminacionAmbiental.new()
var precarga_web: PrecargaRecursosWeb = PrecargaRecursosWeb.new()

@onready var _efecto_niebla: EfectoNieblaMutacion = get_node_or_null("EfectoNieblaMutacion") as EfectoNieblaMutacion
@onready var _modulador_ambiental: CanvasModulate = get_node_or_null("CanvasModulate") as CanvasModulate
@onready var _nodo_no: Node2D = get_node_or_null("Sectores/SectorNO") as Node2D
@onready var _nodo_ne: Node2D = get_node_or_null("Sectores/SectorNE") as Node2D
@onready var _nodo_so: Node2D = get_node_or_null("Sectores/SectorSO") as Node2D
@onready var _nodo_se: Node2D = get_node_or_null("Sectores/SectorSE") as Node2D

var variantes_activas: Dictionary:
	get: return gestor_sectores.variantes_activas
	set(v): gestor_sectores.variantes_activas = v

var _instancias_sectores: Dictionary:
	get: return gestor_sectores.instancias_sectores
	set(v): gestor_sectores.instancias_sectores = v

var _mutacion_en_progreso: bool:
	get: return mutador_sectores.mutacion_en_progreso
	set(v): mutador_sectores.mutacion_en_progreso = v

var _mutacion_pendiente: bool:
	get: return mutador_sectores.mutacion_pendiente
	set(v): mutador_sectores.mutacion_pendiente = v

var _swap_ejecutado_en_ciclo: bool:
	get: return mutador_sectores.swap_ejecutado_en_ciclo
	set(v): mutador_sectores.swap_ejecutado_en_ciclo = v

var _tween_fade_sectores: Tween:
	get: return mutador_sectores.tween_fade_sectores
	set(v): mutador_sectores.tween_fade_sectores = v

var ultimo_marcador_desatasco: Vector2:
	get: return resolutor_atascamiento.ultimo_marcador_desatasco
	set(v): resolutor_atascamiento.ultimo_marcador_desatasco = v


func _ready() -> void:
	y_sort_enabled = true
	_inicializar_subcontroladores()
	_resolver_referencias_objetivos()
	_inicializar_catalogo()
	gestor_sectores.inicializar_sectores_por_defecto(catalogo_variantes)
	_inicializar_iluminacion_ambiental()
	if not Engine.is_editor_hint():
		call_deferred("_precalentar_recursos_web")


func _inicializar_subcontroladores() -> void:
	if _nodo_no == null:
		_nodo_no = get_node_or_null("Sectores/SectorNO") as Node2D
		_nodo_ne = get_node_or_null("Sectores/SectorNE") as Node2D
		_nodo_so = get_node_or_null("Sectores/SectorSO") as Node2D
		_nodo_se = get_node_or_null("Sectores/SectorSE") as Node2D

	gestor_sectores.inicializar_nodos(_nodo_no, _nodo_ne, _nodo_so, _nodo_se)

	if _efecto_niebla == null:
		_efecto_niebla = get_node_or_null("EfectoNieblaMutacion") as EfectoNieblaMutacion

	mutador_sectores.nodo_raiz = self
	mutador_sectores.gestor_sectores = gestor_sectores
	mutador_sectores.efecto_niebla = _efecto_niebla

	resolutor_atascamiento.gestor_sectores = gestor_sectores


func _precalentar_recursos_web() -> void:
	precarga_web.precalentar_recursos_web(self, catalogo_variantes)


func _inicializar_iluminacion_ambiental() -> void:
	if _modulador_ambiental == null:
		_modulador_ambiental = get_node_or_null("CanvasModulate") as CanvasModulate
	config_iluminacion = gestor_iluminacion.inicializar_iluminacion(_modulador_ambiental, config_iluminacion)


## Modula suavemente la penumbra ambiental (CanvasModulate) conforme se recolectan notas.
func actualizar_iluminacion_ambiental(notas_recolectadas: int, duracion_transicion: float = 1.0) -> void:
	if _modulador_ambiental == null:
		_modulador_ambiental = get_node_or_null("CanvasModulate") as CanvasModulate
	gestor_iluminacion.actualizar_iluminacion_ambiental(self, _modulador_ambiental, config_iluminacion, notas_recolectadas, duracion_transicion)


func _resolver_referencias_objetivos() -> void:
	if objetivo_jugador == null:
		if is_inside_tree():
			objetivo_jugador = get_tree().get_first_node_in_group("jugador") as Node2D
		if objetivo_jugador == null and get_parent() != null:
			objetivo_jugador = get_parent().find_child("personaje", true, false) as Node2D

	if objetivo_enemigo == null and get_parent() != null:
		objetivo_enemigo = get_parent().find_child("Enemigo", true, false) as CharacterBody2D

	if _efecto_niebla == null:
		_efecto_niebla = get_node_or_null("EfectoNieblaMutacion") as EfectoNieblaMutacion
	if _efecto_niebla != null:
		if _efecto_niebla.objetivo_jugador == null:
			_efecto_niebla.objetivo_jugador = objetivo_jugador
		mutador_sectores.efecto_niebla = _efecto_niebla
		_conectar_senales_niebla()


func _conectar_senales_niebla() -> void:
	if _efecto_niebla != null:
		if not _efecto_niebla.oscuridad_iniciada.is_connected(_on_niebla_oscuridad_iniciada):
			_efecto_niebla.oscuridad_iniciada.connect(_on_niebla_oscuridad_iniciada)
		if not _efecto_niebla.oscuridad_terminada.is_connected(_on_niebla_oscuridad_terminada):
			_efecto_niebla.oscuridad_terminada.connect(_on_niebla_oscuridad_terminada)


func _on_niebla_oscuridad_iniciada() -> void:
	if objetivo_enemigo != null and is_instance_valid(objetivo_enemigo) and objetivo_enemigo.has_method("modular_velocidad_niebla"):
		objetivo_enemigo.modular_velocidad_niebla(true)


func _on_niebla_oscuridad_terminada() -> void:
	if objetivo_enemigo != null and is_instance_valid(objetivo_enemigo) and objetivo_enemigo.has_method("modular_velocidad_niebla"):
		objetivo_enemigo.modular_velocidad_niebla(false)


func _inicializar_catalogo() -> void:
	if catalogo_variantes.is_empty():
		for ruta in RUTAS_VARIANTES_DEFECTO:
			if ResourceLoader.exists(ruta):
				var res = load(ruta) as PackedScene
				if res != null:
					catalogo_variantes.append(res)


func _instanciar_sectores_iniciales() -> void:
	gestor_sectores.inicializar_sectores_por_defecto(catalogo_variantes)


func _obtener_nodo_sector(sector: String) -> Node2D:
	if gestor_sectores.nodo_no == null:
		_inicializar_subcontroladores()
	return gestor_sectores.obtener_nodo_sector(sector)


func _instanciar_variante_en_sector(sector: String, escena: PackedScene) -> void:
	gestor_sectores.instanciar_variante_en_sector(sector, escena)


func obtener_cuadrante_jugador(pos_global: Vector2) -> String:
	return gestor_sectores.obtener_cuadrante(pos_global)


func calcular_cuadrante(pos_global: Vector2) -> String:
	return gestor_sectores.obtener_cuadrante(pos_global)


func forzar_mutacion() -> void:
	mutar_con_neblina()


func abortar_mutacion() -> void:
	mutador_sectores.abortar_mutacion()
	if objetivo_enemigo != null and is_instance_valid(objetivo_enemigo) and objetivo_enemigo.has_method("modular_velocidad_niebla"):
		objetivo_enemigo.modular_velocidad_niebla(false)


func _restaurar_opacidad_sectores() -> void:
	mutador_sectores.restaurar_opacidad_sectores()


func mutar_con_neblina(
	duracion_cierre: float = -1.0,
	duracion_apertura: float = -1.0,
	pausa_oscuridad: float = -1.0
) -> void:
	_resolver_referencias_objetivos()
	_inicializar_catalogo()
	var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.ZERO

	await mutador_sectores.mutar_con_neblina(
		pos_jug,
		catalogo_variantes,
		Callable(self, "_on_post_swap"),
		duracion_cierre,
		duracion_apertura,
		pausa_oscuridad
	)


func _on_post_swap() -> void:
	validar_y_reubicar_enemigo()
	var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.ZERO
	var cuadrante_activo: String = gestor_sectores.obtener_cuadrante(pos_jug)
	sectores_mutados.emit(cuadrante_activo, gestor_sectores.variantes_activas)


func _ejecutar_mutacion_con_fade(duracion_pausa: float) -> void:
	_inicializar_catalogo()
	var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.ZERO
	mutador_sectores.ejecutar_mutacion_con_fade(duracion_pausa, pos_jug, catalogo_variantes, Callable(self, "_on_post_swap"))


func mutar_sectores_lejanos(sectores_permitidos: Array[String] = []) -> void:
	_inicializar_catalogo()
	_resolver_referencias_objetivos()
	var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.ZERO

	var cuadrante_activo: String = mutador_sectores.mutar_sectores_lejanos(pos_jug, catalogo_variantes, sectores_permitidos)
	validar_y_reubicar_enemigo()
	sectores_mutados.emit(cuadrante_activo, gestor_sectores.variantes_activas)


func mutar_sectores_lejanos_progresivo(sectores_permitidos: Array[String] = []) -> void:
	_inicializar_catalogo()
	_resolver_referencias_objetivos()
	var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.ZERO

	var cuadrante_activo: String = await mutador_sectores.mutar_sectores_lejanos_progresivo(pos_jug, catalogo_variantes, sectores_permitidos)
	validar_y_reubicar_enemigo()
	sectores_mutados.emit(cuadrante_activo, gestor_sectores.variantes_activas)


func validar_y_reubicar_enemigo() -> void:
	var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.INF
	var res: Dictionary = resolutor_atascamiento.validar_y_reubicar_enemigo(objetivo_enemigo, pos_jug)
	if res.get("reubicado", false):
		enemigo_reubicado.emit(res["pos_anterior"], res["pos_nueva"], res["sector"])


func _verificar_solapamiento_solido(enemigo: CharacterBody2D) -> bool:
	return resolutor_atascamiento.verificar_solapamiento_solido(enemigo)


func _obtener_punto_seguro_en_sector(sector: String, pos_referencia: Vector2) -> Vector2:
	var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.INF
	return resolutor_atascamiento.obtener_punto_seguro_en_sector(sector, pos_referencia, pos_jug)


func obtener_marcadores_nota_sectores_mutados(cuadrante_jugador: String = "") -> Array[Marker2D]:
	if cuadrante_jugador.is_empty():
		var pos_jug: Vector2 = objetivo_jugador.global_position if (objetivo_jugador != null and is_instance_valid(objetivo_jugador)) else Vector2.ZERO
		cuadrante_jugador = gestor_sectores.obtener_cuadrante(pos_jug)
	return gestor_sectores.obtener_marcadores_nota_sectores_mutados(cuadrante_jugador)


func obtener_todos_marcadores_nota() -> Array[Marker2D]:
	return gestor_sectores.obtener_todos_marcadores_nota()
