class_name Enemigo
extends CharacterBody2D

## Boceto del enemigo perseguidor: sigue al jugador y dispara Game Over al contacto.

@export var objetivo: Node2D

@export_group("Físicas de Persecución")
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var speed: float = 500.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var acceleration: float = 3500.0

var _capturado: bool = false
var tiene_linea_vision: bool = true
var punto_impacto_local: Vector2 = Vector2.ZERO
var debug_dibujar_rayo: bool = false
var debug_dibujar_trail: bool = true
var debug_dibujar_radios: bool = true
var debug_dibujar_vector_vel: bool = true

var _trail_puntos: Array[Vector2] = []
var _trail_intervalo: float = 0.04
var _trail_timer: float = 0.0
const MAX_TRAIL_PUNTOS: int = 45

@onready var _gestor: GestorDeEscenas = get_node_or_null("/root/GestorEscenas") as GestorDeEscenas
@onready var _area_captura: Area2D = $AreaCaptura
@onready var _visual: Node2D = $BocetoVisual
@onready var _raycast_vision: RayCast2D = get_node_or_null("RayCastVision") as RayCast2D


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if objetivo == null and get_parent() != null:
		objetivo = get_parent().get_node_or_null("personaje") as Node2D
	if _area_captura != null:
		_area_captura.body_entered.connect(_on_body_entered)
	if _raycast_vision == null:
		_raycast_vision = RayCast2D.new()
		_raycast_vision.name = "RayCastVision"
		_raycast_vision.collision_mask = 1
		_raycast_vision.collide_with_areas = false
		_raycast_vision.collide_with_bodies = true
		add_child(_raycast_vision)

	_raycast_vision.add_exception(self)
	if objetivo != null:
		_raycast_vision.add_exception(objetivo)


func _physics_process(delta: float) -> void:
	if _capturado or objetivo == null or not is_instance_valid(objetivo):
		return

	_actualizar_linea_vision()

	var direccion: Vector2 = global_position.direction_to(objetivo.global_position)
	velocity = velocity.move_toward(direccion * speed, acceleration * delta)
	if velocity.length_squared() > 1.0 and _visual != null:
		_visual.rotation = velocity.angle()

	move_and_slide()
	_comprobar_captura_continua()

	if debug_dibujar_rayo:
		_trail_timer += delta
		if _trail_timer >= _trail_intervalo:
			_trail_timer = 0.0
			_trail_puntos.append(global_position)
			if _trail_puntos.size() > MAX_TRAIL_PUNTOS:
				_trail_puntos.pop_front()
		queue_redraw()
	elif not _trail_puntos.is_empty():
		_trail_puntos.clear()


func _actualizar_linea_vision() -> void:
	if _raycast_vision == null or objetivo == null or not is_instance_valid(objetivo):
		tiene_linea_vision = false
		return

	var target_local: Vector2 = to_local(objetivo.global_position)
	_raycast_vision.target_position = target_local
	_raycast_vision.force_raycast_update()

	if _raycast_vision.is_colliding():
		var col = _raycast_vision.get_collider()
		# Si por alguna razón colisiona con el jugador, significa que el camino hasta él está despejado
		if col == objetivo or col is Personaje:
			tiene_linea_vision = true
			punto_impacto_local = target_local
		else:
			tiene_linea_vision = false
			punto_impacto_local = to_local(_raycast_vision.get_collision_point())
	else:
		tiene_linea_vision = true
		punto_impacto_local = target_local


func _draw() -> void:
	if not debug_dibujar_rayo:
		return

	var cam := get_viewport().get_camera_2d()
	var factor_zoom: float = cam.zoom.x if (cam != null and cam.zoom.x > 0.01) else 1.0
	var grosor_base: float = maxf(2.0, 3.5 / factor_zoom)
	var radio_punto: float = maxf(4.0, 7.0 / factor_zoom)

	# 1. Estela de Trayectoria (Breadcrumbs con degradado alfa)
	if debug_dibujar_trail and _trail_puntos.size() >= 2:
		var total_puntos: int = _trail_puntos.size()
		for i in range(total_puntos - 1):
			var p1: Vector2 = to_local(_trail_puntos[i])
			var p2: Vector2 = to_local(_trail_puntos[i + 1])
			var factor_t: float = float(i + 1) / float(total_puntos)
			var alfa: float = clampf(factor_t * 0.75, 0.08, 0.8)
			var color_tramo := Color(0.95, 0.45 * (1.0 - factor_t), 0.2, alfa)
			var ancho_tramo: float = maxf(1.5, (grosor_base * 0.85) * factor_t)
			draw_line(p1, p2, color_tramo, ancho_tramo)
		var ultimo_p: Vector2 = to_local(_trail_puntos[total_puntos - 1])
		draw_line(ultimo_p, Vector2.ZERO, Color(0.95, 0.2, 0.2, 0.8), grosor_base)

	# 2. Radios Concéntricos: Captura Letal (56px) y Colisión Sólida (42px)
	if debug_dibujar_radios:
		# Radio de captura letal
		var color_captura_fill := Color(0.9, 0.2, 0.2, 0.12)
		var color_captura_borde := Color(0.95, 0.25, 0.25, 0.75)
		draw_circle(Vector2.ZERO, 56.0, color_captura_fill)
		draw_arc(Vector2.ZERO, 56.0, 0.0, TAU, 32, color_captura_borde, maxf(1.5, 2.5 / factor_zoom))

		# Radio de colisión física
		var color_colision_borde := Color(1.0, 0.8, 0.2, 0.6)
		draw_arc(Vector2.ZERO, 42.0, 0.0, TAU, 32, color_colision_borde, maxf(1.0, 2.0 / factor_zoom))

	# 3. Vector de Velocidad Instantánea
	if debug_dibujar_vector_vel and velocity.length_squared() > 10.0:
		var dir_vel: Vector2 = velocity.normalized()
		var long_vel: float = clampf(velocity.length() * 0.15, 20.0, 75.0)
		var fin_vel: Vector2 = dir_vel * long_vel
		var color_vel := Color(0.3, 0.8, 1.0, 0.9)
		draw_line(Vector2.ZERO, fin_vel, color_vel, grosor_base)
		var angulo: float = dir_vel.angle()
		var ala1: Vector2 = fin_vel - Vector2.from_angle(angulo + 0.5) * (8.0 / factor_zoom)
		var ala2: Vector2 = fin_vel - Vector2.from_angle(angulo - 0.5) * (8.0 / factor_zoom)
		draw_line(fin_vel, ala1, color_vel, grosor_base)
		draw_line(fin_vel, ala2, color_vel, grosor_base)

	# 4. Línea de Visión (RayCast hacia el objetivo)
	if objetivo != null and is_instance_valid(objetivo):
		var target_local: Vector2 = to_local(objetivo.global_position)
		if tiene_linea_vision:
			# Línea de visión libre (Verde esmeralda nítido)
			draw_line(Vector2.ZERO, target_local, Color(0.25, 0.95, 0.45, 0.85), grosor_base)
			draw_circle(target_local, radio_punto, Color(0.25, 0.95, 0.45, 0.85))
		else:
			# Línea obstruida: rojo hasta el punto de impacto
			draw_line(Vector2.ZERO, punto_impacto_local, Color(0.95, 0.3, 0.3, 0.9), grosor_base)
			draw_circle(punto_impacto_local, radio_punto, Color(1.0, 0.25, 0.25, 1.0))
			# Línea punteada desde el obstáculo hasta el objetivo
			draw_dashed_line(punto_impacto_local, target_local, Color(0.8, 0.4, 0.4, 0.45), maxf(1.0, 2.0 / factor_zoom), 8.0 / factor_zoom)


func _on_body_entered(body: Node2D) -> void:
	_intentar_capturar(body)


func _intentar_capturar(body: Node2D) -> void:
	if _capturado:
		return
	if body is Personaje or body == objetivo:
		if body.get("god_mode") == true:
			return
		_capturado = true
		velocity = Vector2.ZERO
		if _gestor != null:
			_gestor.ir_a(GestorDeEscenas.RUTA_GAME_OVER)


func _comprobar_captura_continua() -> void:
	if _capturado or _area_captura == null:
		return
	for body in _area_captura.get_overlapping_bodies():
		if body is Personaje or body == objetivo:
			if body.get("god_mode") == true:
				continue
			_capturado = true
			velocity = Vector2.ZERO
			if _gestor != null:
				_gestor.ir_a(GestorDeEscenas.RUTA_GAME_OVER)
			break
