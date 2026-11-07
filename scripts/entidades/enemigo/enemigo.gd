@tool
class_name Enemigo
extends CharacterBody2D

## Boceto del enemigo perseguidor: sigue al jugador y dispara Game Over al contacto.

signal despertado(velocidad_inicial: float)
signal hibernado
signal jugador_capturado(posicion: Vector2)

# --- Constantes de Configuración y Físicas ---
const POSICION_HIBERNACION: Vector2 = Vector2(-99999.0, -99999.0)
const VELOCIDAD_MAXIMA: float = 920.0
const ACELERACION_CONSTANTE: float = 3500.0
const VELOCIDAD_DESPERTAR_DEFECTO: float = 500.0

const FACTOR_RALENTIZACION_NIEBLA: float = 0.5
const DURACION_RALENTIZACION_OSCURIDAD_DEFECTO: float = 0.4
const MASCARA_COLISION_ENTORNO: int = 1

# Radios de referencia para depuración visual y áreas físicas
const RADIO_COLISION_CUERPO: float = 42.0
const RADIO_AREA_CAPTURA: float = 56.0
const UMBRAL_MOVIMIENTO_MINIMO_SQ: float = 1.0

# --- Constantes de Depuración Visual ---
const INTERVALO_MUESTREO_ESTELA: float = 0.04
const MAX_PUNTOS_ESTELA: int = 45
const UMBRAL_VELOCIDAD_FLECHA_SQ: float = 10.0
const FACTOR_LONGITUD_FLECHA_VELOCIDAD: float = 0.15
const LONGITUD_MIN_FLECHA_VELOCIDAD: float = 20.0
const LONGITUD_MAX_FLECHA_VELOCIDAD: float = 75.0

const VELOCIDADES_MONSTRUO: Array[float] = [
	0.0,   # Nota 0 (Hibernación / Tutorial)
	500.0, # Nota 1 (Materialización y Despertar)
	580.0, # Nota 2
	620.0, # Nota 3
	680.0, # Nota 4
	730.0, # Nota 5
	770.0, # Nota 6
	800.0, # Nota 7 (Punto de inflexión: iguala caminata normal)
	840.0, # Nota 8
	880.0, # Nota 9
	920.0  # Nota 10+ (Tope máximo estricto)
]

@export var objetivo: Node2D
@export var hibernar_al_iniciar: bool = true

@export_group("Físicas de Persecución")
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var speed: float = 500.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var acceleration: float = 3500.0

var hibernando: bool = false
var modulador_velocidad_niebla: float = 1.0
var _capturado: bool = false
var tiene_linea_vision: bool = true
var punto_impacto_local: Vector2 = Vector2.ZERO

var debug_dibujar_rayo: bool:
	get:
		return _depurador_visual.dibujar_activo if _depurador_visual != null else false
	set(val):
		if _depurador_visual != null:
			_depurador_visual.dibujar_activo = val

@onready var _area_captura: Area2D = get_node_or_null("AreaCaptura") as Area2D
@onready var _contenedor_visual: Node2D = get_node_or_null("BocetoVisual") as Node2D
@onready var _raycast_vision: RayCast2D = get_node_or_null("RayCastVision") as RayCast2D
@onready var _depurador_visual: DepuradorVisualEnemigo = get_node_or_null("DepuradorVisualEnemigo") as DepuradorVisualEnemigo


func _ready() -> void:
	add_to_group("monstruo")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if objetivo == null:
		if is_inside_tree():
			objetivo = get_tree().get_first_node_in_group("jugador") as Node2D
		if objetivo == null and get_parent() != null:
			objetivo = get_parent().get_node_or_null("personaje") as Node2D
	if _area_captura != null:
		_area_captura.body_entered.connect(_on_body_entered)
	if _raycast_vision == null:
		_raycast_vision = RayCast2D.new()
		_raycast_vision.name = "RayCastVision"
		_raycast_vision.collision_mask = MASCARA_COLISION_ENTORNO
		_raycast_vision.collide_with_areas = false
		_raycast_vision.collide_with_bodies = true
		add_child(_raycast_vision)

	_raycast_vision.add_exception(self)
	if objetivo != null:
		_raycast_vision.add_exception(objetivo)

	if (not Engine.is_editor_hint() or is_in_group("modo_test")) and hibernar_al_iniciar:
		hibernar()


func hibernar() -> void:
	hibernando = true
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	global_position = POSICION_HIBERNACION
	velocity = Vector2.ZERO
	speed = VELOCIDADES_MONSTRUO[0]
	acceleration = ACELERACION_CONSTANTE
	hibernado.emit()


func despertar(velocidad_inicial: float = VELOCIDAD_DESPERTAR_DEFECTO) -> void:
	hibernando = false
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	speed = velocidad_inicial
	acceleration = ACELERACION_CONSTANTE
	velocity = Vector2.ZERO
	despertado.emit(velocidad_inicial)


func actualizar_dificultad(notas_recogidas: int) -> void:
	speed = obtener_velocidad_por_nota(notas_recogidas)
	acceleration = ACELERACION_CONSTANTE


static func obtener_velocidad_por_nota(notas: int) -> float:
	if notas <= 0:
		return VELOCIDADES_MONSTRUO[0]
	if notas >= VELOCIDADES_MONSTRUO.size():
		return VELOCIDADES_MONSTRUO[VELOCIDADES_MONSTRUO.size() - 1]
	return VELOCIDADES_MONSTRUO[notas]


func modular_velocidad_niebla(activa: bool) -> void:
	modulador_velocidad_niebla = FACTOR_RALENTIZACION_NIEBLA if activa else 1.0


func reducir_velocidad_oscuridad(duracion: float = DURACION_RALENTIZACION_OSCURIDAD_DEFECTO) -> void:
	modular_velocidad_niebla(true)
	var tree := get_tree()
	if tree != null and duracion > 0.0:
		var timer := tree.create_timer(duracion)
		timer.timeout.connect(func(): modular_velocidad_niebla(false))


func obtener_velocidad_efectiva() -> float:
	return speed * modulador_velocidad_niebla


func _physics_process(delta: float) -> void:
	if hibernando or _capturado or objetivo == null or not is_instance_valid(objetivo):
		return

	_actualizar_linea_vision()

	var velocidad_deseada: float = obtener_velocidad_efectiva()
	var direccion: Vector2 = global_position.direction_to(objetivo.global_position)
	velocity = velocity.move_toward(direccion * velocidad_deseada, acceleration * delta)
	if velocity.length_squared() > UMBRAL_MOVIMIENTO_MINIMO_SQ and _contenedor_visual != null:
		_contenedor_visual.rotation = velocity.angle()

	move_and_slide()
	_comprobar_captura_continua()


func _actualizar_linea_vision() -> void:
	if _raycast_vision == null or objetivo == null or not is_instance_valid(objetivo):
		tiene_linea_vision = false
		return

	var posicion_objetivo_local: Vector2 = to_local(objetivo.global_position)
	_raycast_vision.target_position = posicion_objetivo_local
	_raycast_vision.force_raycast_update()

	if _raycast_vision.is_colliding():
		var colisionador = _raycast_vision.get_collider()
		# Si colisiona con el jugador, el camino hacia él está despejado
		if colisionador == objetivo or colisionador is Personaje:
			tiene_linea_vision = true
			punto_impacto_local = posicion_objetivo_local
		else:
			tiene_linea_vision = false
			punto_impacto_local = to_local(_raycast_vision.get_collision_point())
	else:
		tiene_linea_vision = true
		punto_impacto_local = posicion_objetivo_local


func _on_body_entered(body: Node2D) -> void:
	_intentar_capturar(body)


func _intentar_capturar(body: Node2D) -> void:
	if _capturado or hibernando:
		return
	if body is Personaje or body == objetivo:
		if body.get("god_mode") == true:
			return
		_capturado = true
		velocity = Vector2.ZERO
		if has_node("/root/GestorMusica"):
			get_node("/root/GestorMusica").detener_por_jumpscare()
		jugador_capturado.emit(global_position)


func _comprobar_captura_continua() -> void:
	if _capturado or hibernando or _area_captura == null:
		return
	for body in _area_captura.get_overlapping_bodies():
		if body is Personaje or body == objetivo:
			if body.get("god_mode") == true:
				continue
			_capturado = true
			velocity = Vector2.ZERO
			if has_node("/root/GestorMusica"):
				get_node("/root/GestorMusica").detener_por_jumpscare()
			jugador_capturado.emit(global_position)
			break
