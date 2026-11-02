@tool
class_name TransicionEscenas
extends CanvasLayer

## Controlador mediador de la transición visual.
## Expone la propiedad nativa 'progreso' (0.0 = abierto, 1.0 = negro) para ser animada
## de manera limpia y segura por el AnimationPlayer sin tocar directamente el shader.

signal salida_completada
signal entrada_completada

## Progreso de cierre del iris: 0.0 = totalmente abierto / visible; 1.0 = totalmente cerrado a negro.
@export_range(0.0, 1.0) var progreso: float = 0.0:
	set = _set_progreso

## Coordenada normalizada UV (0.0 a 1.0) donde converge el centro del círculo de la viñeta.
@export var centro: Vector2 = Vector2(0.5, 0.5):
	set = _set_centro

@export var animacion_cerrar_defecto: StringName = &"iris_cerrar"
@export var animacion_abrir_defecto: StringName = &"iris_abrir"
@export var velocidad_reproduccion: float = 1.0

@onready var _velo: ColorRect = $Velo
@onready var _animador: AnimationPlayer = $Anim

var _en_transicion: bool = false


func _ready() -> void:
	if _velo == null:
		_velo = get_node_or_null("Velo") as ColorRect
	if _animador == null:
		_animador = get_node_or_null("Anim") as AnimationPlayer

	bloquear_input(false)
	_actualizar_aspecto()
	_actualizar_shader()

	if _animador != null:
		_animador.speed_scale = velocidad_reproduccion
		if not _animador.animation_finished.is_connected(_on_animation_finished):
			_animador.animation_finished.connect(_on_animation_finished)

	if _velo != null and not _velo.resized.is_connected(_on_velo_redimensionado):
		_velo.resized.connect(_on_velo_redimensionado)


## Cierra la transición (hacia pantalla negra / viñeta cerrada).
## centro_objetivo permite enfocar el círculo en una posición normalizada (0.0 a 1.0).
func cerrar(nombre_animacion: StringName = &"", centro_objetivo: Vector2 = Vector2(-1, -1)) -> void:
	var animacion: StringName = nombre_animacion if not nombre_animacion.is_empty() else animacion_cerrar_defecto
	if centro_objetivo.x >= 0.0 and centro_objetivo.y >= 0.0:
		centro = centro_objetivo
	else:
		centro = Vector2(0.5, 0.5)

	bloquear_input(true)
	_en_transicion = true
	_animador.play(animacion)
	await _animador.animation_finished


## Abre la transición (revela la nueva escena desde el centro).
func abrir(nombre_animacion: StringName = &"", centro_objetivo: Vector2 = Vector2(-1, -1)) -> void:
	var animacion: StringName = nombre_animacion if not nombre_animacion.is_empty() else animacion_abrir_defecto
	if centro_objetivo.x >= 0.0 and centro_objetivo.y >= 0.0:
		centro = centro_objetivo

	_en_transicion = true
	_animador.play(animacion)
	await _animador.animation_finished
	bloquear_input(false)


func bloquear_input(bloquear: bool) -> void:
	if _velo != null:
		_velo.mouse_filter = Control.MOUSE_FILTER_STOP if bloquear else Control.MOUSE_FILTER_IGNORE


func esta_en_transicion() -> bool:
	return _en_transicion


func _set_progreso(nuevo_progreso: float) -> void:
	progreso = clampf(nuevo_progreso, 0.0, 1.0)
	_actualizar_shader()


func _set_centro(nuevo_centro: Vector2) -> void:
	centro = nuevo_centro
	_actualizar_shader()


func _actualizar_shader() -> void:
	if _velo == null:
		_velo = get_node_or_null("Velo") as ColorRect
	if _velo != null and _velo.material is ShaderMaterial:
		var mat := _velo.material as ShaderMaterial
		mat.set_shader_parameter("progress", progreso)
		mat.set_shader_parameter("center", centro)


func _actualizar_aspecto() -> void:
	if _velo == null:
		_velo = get_node_or_null("Velo") as ColorRect
	if _velo != null and _velo.material is ShaderMaterial:
		var tamano := _velo.size
		var aspecto: float = 1.0
		if tamano.x > 0.0 and tamano.y > 0.0:
			aspecto = tamano.x / tamano.y
		(_velo.material as ShaderMaterial).set_shader_parameter("aspect_ratio", aspecto)


func _on_velo_redimensionado() -> void:
	_actualizar_aspecto()


func _on_animation_finished(nombre_animacion: StringName) -> void:
	_en_transicion = false
	if nombre_animacion.ends_with("cerrar") or nombre_animacion.ends_with("salida"):
		salida_completada.emit()
	else:
		entrada_completada.emit()
