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

@onready var _rectangulo_velo: ColorRect = $Velo
@onready var _reproductor_animacion: AnimationPlayer = $Anim

var _transicion_en_progreso: bool = false


func _ready() -> void:
	if _rectangulo_velo == null:
		_rectangulo_velo = get_node_or_null("Velo") as ColorRect
	if _reproductor_animacion == null:
		_reproductor_animacion = get_node_or_null("Anim") as AnimationPlayer

	bloquear_input(false)
	_actualizar_relacion_aspecto()
	_actualizar_parametros_shader()

	if _reproductor_animacion != null:
		_reproductor_animacion.speed_scale = velocidad_reproduccion
		if not _reproductor_animacion.animation_finished.is_connected(_on_animation_finished):
			_reproductor_animacion.animation_finished.connect(_on_animation_finished)

	if _rectangulo_velo != null and not _rectangulo_velo.resized.is_connected(_on_velo_redimensionado):
		_rectangulo_velo.resized.connect(_on_velo_redimensionado)


## Cierra la transición (hacia pantalla negra / viñeta cerrada).
## centro_uv_objetivo permite enfocar el círculo en una posición normalizada (0.0 a 1.0).
func cerrar(nombre_animacion: StringName = &"", centro_uv_objetivo: Vector2 = Vector2(-1, -1)) -> void:
	var animacion_a_ejecutar: StringName = nombre_animacion if not nombre_animacion.is_empty() else animacion_cerrar_defecto
	if centro_uv_objetivo.x >= 0.0 and centro_uv_objetivo.y >= 0.0:
		centro = centro_uv_objetivo
	else:
		centro = Vector2(0.5, 0.5)

	bloquear_input(true)
	_transicion_en_progreso = true
	_reproductor_animacion.play(animacion_a_ejecutar)
	await _reproductor_animacion.animation_finished


## Abre la transición (revela la nueva escena desde el centro).
func abrir(nombre_animacion: StringName = &"", centro_uv_objetivo: Vector2 = Vector2(-1, -1)) -> void:
	var animacion_a_ejecutar: StringName = nombre_animacion if not nombre_animacion.is_empty() else animacion_abrir_defecto
	if centro_uv_objetivo.x >= 0.0 and centro_uv_objetivo.y >= 0.0:
		centro = centro_uv_objetivo

	_transicion_en_progreso = true
	_reproductor_animacion.play(animacion_a_ejecutar)
	await _reproductor_animacion.animation_finished
	bloquear_input(false)


func bloquear_input(debe_bloquear: bool) -> void:
	if _rectangulo_velo != null:
		_rectangulo_velo.mouse_filter = Control.MOUSE_FILTER_STOP if debe_bloquear else Control.MOUSE_FILTER_IGNORE


func esta_en_transicion() -> bool:
	return _transicion_en_progreso


func _set_progreso(nuevo_progreso: float) -> void:
	progreso = clampf(nuevo_progreso, 0.0, 1.0)
	_actualizar_parametros_shader()


func _set_centro(nuevo_centro: Vector2) -> void:
	centro = nuevo_centro
	_actualizar_parametros_shader()


func _actualizar_parametros_shader() -> void:
	if _rectangulo_velo == null:
		_rectangulo_velo = get_node_or_null("Velo") as ColorRect
	if _rectangulo_velo != null and _rectangulo_velo.material is ShaderMaterial:
		var material_shader := _rectangulo_velo.material as ShaderMaterial
		material_shader.set_shader_parameter("progress", progreso)
		material_shader.set_shader_parameter("center", centro)


func _actualizar_relacion_aspecto() -> void:
	if _rectangulo_velo == null:
		_rectangulo_velo = get_node_or_null("Velo") as ColorRect
	if _rectangulo_velo != null and _rectangulo_velo.material is ShaderMaterial:
		var tamano_pantalla := _rectangulo_velo.size
		var aspecto: float = 1.0
		if tamano_pantalla.x > 0.0 and tamano_pantalla.y > 0.0:
			aspecto = tamano_pantalla.x / tamano_pantalla.y
		(_rectangulo_velo.material as ShaderMaterial).set_shader_parameter("aspect_ratio", aspecto)


func _on_velo_redimensionado() -> void:
	_actualizar_relacion_aspecto()


func _on_animation_finished(nombre_animacion: StringName) -> void:
	_transicion_en_progreso = false
	if nombre_animacion.ends_with("cerrar") or nombre_animacion.ends_with("salida"):
		salida_completada.emit()
	else:
		entrada_completada.emit()
