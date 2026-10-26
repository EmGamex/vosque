class_name MenuParallax
extends RefCounted

## Administrador del balanceo orgánico de linterna (sway) y parallax multicapa.

var offset_base: Vector2 = Vector2.ZERO
var rotacion_base: float = 0.0
var tiempo: float = 0.0

# Posiciones base capturadas del editor para no sobreescribir la escena
var pos_inicial_fondos: Vector2 = Vector2.ZERO
var pos_inicial_degradado: Vector2 = Vector2.ZERO
var pos_inicial_montana_2: Vector2 = Vector2.ZERO
var pos_inicial_montana_1: Vector2 = Vector2.ZERO
var pos_inicial_arboles_3: Vector2 = Vector2.ZERO
var pos_inicial_arboles_2: Vector2 = Vector2.ZERO
var pos_inicial_estrellas: Vector2 = Vector2.ZERO
var pos_inicial_nubes: Vector2 = Vector2.ZERO
var pos_inicial_arboles: Vector2 = Vector2.ZERO
var pos_inicial_textos: Vector2 = Vector2.ZERO

# Nodos manipulados en parallax
var fondos: Node2D
var fondo_degradado: Sprite2D
var montana_2: Sprite2D
var montana_1: Sprite2D
var arboles_tercera: Sprite2D
var arboles_segunda: Sprite2D
var arboles_nodo: Node2D
var textos_nodo: Control


func inicializar_nodos(
	p_fondos: Node2D,
	p_fondo_degradado: Sprite2D,
	p_montana_2: Sprite2D,
	p_montana_1: Sprite2D,
	p_arboles_tercera: Sprite2D,
	p_arboles_segunda: Sprite2D,
	p_arboles_nodo: Node2D,
	p_textos_nodo: Control
) -> void:
	fondos = p_fondos
	fondo_degradado = p_fondo_degradado
	montana_2 = p_montana_2
	montana_1 = p_montana_1
	arboles_tercera = p_arboles_tercera
	arboles_segunda = p_arboles_segunda
	arboles_nodo = p_arboles_nodo
	textos_nodo = p_textos_nodo


func capturar_posiciones_iniciales(p_estrellas: CPUParticles2D, p_nubes: CPUParticles2D) -> void:
	if fondos != null:
		pos_inicial_fondos = fondos.position
	if fondo_degradado != null:
		pos_inicial_degradado = fondo_degradado.position
	if montana_2 != null:
		pos_inicial_montana_2 = montana_2.position
	if montana_1 != null:
		pos_inicial_montana_1 = montana_1.position
	if arboles_tercera != null:
		pos_inicial_arboles_3 = arboles_tercera.position
	if arboles_segunda != null:
		pos_inicial_arboles_2 = arboles_segunda.position
	if p_estrellas != null:
		pos_inicial_estrellas = p_estrellas.position
	if p_nubes != null:
		pos_inicial_nubes = p_nubes.position
	if arboles_nodo != null:
		pos_inicial_arboles = arboles_nodo.position
	if textos_nodo != null:
		pos_inicial_textos = textos_nodo.position


func procesar_balanceo(
	delta: float,
	p_estrellas: CPUParticles2D,
	p_nubes: CPUParticles2D,
	factor_paral_estrellas: float,
	factor_rot_estrellas: float,
	factor_paral_nubes: float,
	factor_rot_nubes: float
) -> void:
	tiempo += delta

	# Respiración orgánica / Temblor natural de linterna en mano
	var sway_x: float = sin(tiempo * 1.5) * 2.5 + sin(tiempo * 0.7) * 1.0
	var sway_y: float = cos(tiempo * 1.9) * 1.8
	var sway_rot: float = sin(tiempo * 1.2) * deg_to_rad(0.18)

	var offset_total: Vector2 = offset_base + Vector2(sway_x, sway_y)
	var rotacion_total: float = rotacion_base + sway_rot

	# Árboles y textos sincronizados en primer plano (relativos a su posición en el editor)
	if arboles_nodo != null:
		arboles_nodo.position = pos_inicial_arboles + offset_total
		arboles_nodo.rotation = rotacion_total

	if textos_nodo != null:
		textos_nodo.position = pos_inicial_textos + offset_total
		textos_nodo.rotation = rotacion_total

	# Parallax multicapa en los fondos relativo a sus posiciones en el editor
	if fondos != null:
		fondos.position = pos_inicial_fondos

	if fondo_degradado != null:
		fondo_degradado.position = pos_inicial_degradado + (offset_total * MenuConstantes.FACTOR_PARALLAX_DEGRADADO)
		fondo_degradado.rotation = rotacion_total * MenuConstantes.FACTOR_ROTACION_DEGRADADO

	if montana_2 != null:
		montana_2.position = pos_inicial_montana_2 + (offset_total * MenuConstantes.FACTOR_PARALLAX_MONTANA_2)
		montana_2.rotation = rotacion_total * MenuConstantes.FACTOR_ROTACION_MONTANA_2

	if montana_1 != null:
		montana_1.position = pos_inicial_montana_1 + (offset_total * MenuConstantes.FACTOR_PARALLAX_MONTANA_1)
		montana_1.rotation = rotacion_total * MenuConstantes.FACTOR_ROTACION_MONTANA_1

	if arboles_tercera != null:
		arboles_tercera.position = pos_inicial_arboles_3 + (offset_total * MenuConstantes.FACTOR_PARALLAX_ARBOLES_3)
		arboles_tercera.rotation = rotacion_total * MenuConstantes.FACTOR_ROTACION_ARBOLES_3

	if arboles_segunda != null:
		arboles_segunda.position = pos_inicial_arboles_2 + (offset_total * MenuConstantes.FACTOR_PARALLAX_ARBOLES_2)
		arboles_segunda.rotation = rotacion_total * MenuConstantes.FACTOR_ROTACION_ARBOLES_2

	if p_estrellas != null:
		p_estrellas.position = pos_inicial_estrellas + (offset_total * factor_paral_estrellas)
		p_estrellas.rotation = rotacion_total * factor_rot_estrellas

	if p_nubes != null:
		p_nubes.position = pos_inicial_nubes + (offset_total * factor_paral_nubes)
		p_nubes.rotation = rotacion_total * factor_rot_nubes
