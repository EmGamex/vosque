class_name MenuParticulas
extends RefCounted

## Administrador y configurador reactivo de las partículas del cielo (estrellas y nubes).

var habilitar_estrellas: bool = true
var estrellas_cantidad: int = 55
var estrellas_lifetime: float = 4.5
var estrellas_escala_min: float = 0.35
var estrellas_escala_max: float = 0.95
var estrellas_color: Color = Color.WHITE
var estrellas_factor_parallax: float = 0.08
var estrellas_factor_rotacion: float = 0.06

var habilitar_nubes: bool = true
var nubes_cantidad: int = 10
var nubes_velocidad_x: float = 18.0
var nubes_lifetime: float = 16.0
var nubes_escala_min: float = 2.0
var nubes_escala_max: float = 4.2
var nubes_color: Color = Color(0.75, 0.82, 0.95, 0.16)
var nubes_factor_parallax: float = 0.16
var nubes_factor_rotacion: float = 0.12

var _nodo_raiz: Node
var _particulas_estrellas: CPUParticles2D
var _particulas_nubes: CPUParticles2D


func inicializar(raiz: Node, estrellas: CPUParticles2D, nubes: CPUParticles2D) -> void:
	_nodo_raiz = raiz
	_particulas_estrellas = estrellas
	_particulas_nubes = nubes
	aplicar_todo()


func obtener_particulas_estrellas() -> CPUParticles2D:
	if _particulas_estrellas == null and _nodo_raiz != null and _nodo_raiz.has_node("Fondos/ParticulasEstrellas"):
		_particulas_estrellas = _nodo_raiz.get_node("Fondos/ParticulasEstrellas") as CPUParticles2D
	return _particulas_estrellas


func obtener_particulas_nubes() -> CPUParticles2D:
	if _particulas_nubes == null and _nodo_raiz != null and _nodo_raiz.has_node("Fondos/ParticulasNubes"):
		_particulas_nubes = _nodo_raiz.get_node("Fondos/ParticulasNubes") as CPUParticles2D
	return _particulas_nubes


func aplicar_configuracion_estrellas() -> void:
	var p: CPUParticles2D = obtener_particulas_estrellas()
	if p == null:
		return
	p.emitting = habilitar_estrellas
	p.amount = estrellas_cantidad
	p.lifetime = estrellas_lifetime
	p.scale_amount_min = estrellas_escala_min
	p.scale_amount_max = estrellas_escala_max
	p.color = estrellas_color


func aplicar_configuracion_nubes() -> void:
	var p: CPUParticles2D = obtener_particulas_nubes()
	if p == null:
		return
	p.emitting = habilitar_nubes
	p.amount = nubes_cantidad
	p.lifetime = nubes_lifetime
	p.initial_velocity_min = nubes_velocidad_x * 0.8
	p.initial_velocity_max = nubes_velocidad_x * 1.2
	p.scale_amount_min = nubes_escala_min
	p.scale_amount_max = nubes_escala_max
	p.color = nubes_color


func aplicar_todo() -> void:
	aplicar_configuracion_estrellas()
	aplicar_configuracion_nubes()
