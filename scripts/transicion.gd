@tool
class_name TransicionEscenas
extends CanvasLayer

## Controlador mediador de la transición visual.
## Expone la propiedad nativa 'progreso' (0.0 = abierto, 1.0 = negro) para ser animada
## de manera limpia y segura por el AnimationPlayer sin tocar directamente el shader.

signal salida_completada
signal entrada_completada

## 0.0 = totalmente abierto / visible; 1.0 = totalmente cerrado a negro.
@export_range(0.0, 1.0) var progreso: float = 0.0:
	set = _set_progreso

@export var centro: Vector2 = Vector2(0.5, 0.5):
	set = _set_centro

@export var animacion_cerrar_defecto: StringName = &"iris_cerrar"
@export var animacion_abrir_defecto: StringName = &"iris_abrir"
@export var velocidad_reproduccion: float = 1.0

@onready var _velo: ColorRect = $Velo
@onready var _anim: AnimationPlayer = $Anim

var _en_transicion: bool = false


func _ready() -> void:
	if _velo == null:
		_velo = get_node_or_null("Velo") as ColorRect
	if _anim == null:
		_anim = get_node_or_null("Anim") as AnimationPlayer

	bloquear_input(false)
	_actualizar_aspect_ratio()
	_actualizar_shader()

	if _anim != null:
		_anim.speed_scale = velocidad_reproduccion
		if not _anim.animation_finished.is_connected(_on_animation_finished):
			_anim.animation_finished.connect(_on_animation_finished)

	if _velo != null and not _velo.resized.is_connected(_on_velo_resized):
		_velo.resized.connect(_on_velo_resized)


## Cierra la transición (hacia pantalla negra / viñeta cerrada).
## centro_uv permite enfocar el círculo en una posición normalizada (0.0 a 1.0).
func cerrar(nombre_anim: StringName = &"", centro_uv: Vector2 = Vector2(-1, -1)) -> void:
	var anim_a_reproducir: StringName = nombre_anim if not nombre_anim.is_empty() else animacion_cerrar_defecto
	if centro_uv.x >= 0.0 and centro_uv.y >= 0.0:
		centro = centro_uv
	else:
		centro = Vector2(0.5, 0.5)

	bloquear_input(true)
	_en_transicion = true
	_anim.play(anim_a_reproducir)
	await _anim.animation_finished


## Abre la transición (revela la nueva escena desde el centro).
func abrir(nombre_anim: StringName = &"", centro_uv: Vector2 = Vector2(-1, -1)) -> void:
	var anim_a_reproducir: StringName = nombre_anim if not nombre_anim.is_empty() else animacion_abrir_defecto
	if centro_uv.x >= 0.0 and centro_uv.y >= 0.0:
		centro = centro_uv

	_en_transicion = true
	_anim.play(anim_a_reproducir)
	await _anim.animation_finished
	bloquear_input(false)


func bloquear_input(bloquear: bool) -> void:
	if _velo != null:
		_velo.mouse_filter = Control.MOUSE_FILTER_STOP if bloquear else Control.MOUSE_FILTER_IGNORE


func esta_en_transicion() -> bool:
	return _en_transicion


func _set_progreso(val: float) -> void:
	progreso = clampf(val, 0.0, 1.0)
	_actualizar_shader()


func _set_centro(val: Vector2) -> void:
	centro = val
	_actualizar_shader()


func _actualizar_shader() -> void:
	if _velo == null:
		_velo = get_node_or_null("Velo") as ColorRect
	if _velo != null and _velo.material is ShaderMaterial:
		var mat := _velo.material as ShaderMaterial
		mat.set_shader_parameter("progress", progreso)
		mat.set_shader_parameter("center", centro)


func _actualizar_aspect_ratio() -> void:
	if _velo == null:
		_velo = get_node_or_null("Velo") as ColorRect
	if _velo != null and _velo.material is ShaderMaterial:
		var s := _velo.size
		var ratio: float = 1.0
		if s.x > 0.0 and s.y > 0.0:
			ratio = s.x / s.y
		(_velo.material as ShaderMaterial).set_shader_parameter("aspect_ratio", ratio)


func _on_velo_resized() -> void:
	_actualizar_aspect_ratio()


func _on_animation_finished(anim_name: StringName) -> void:
	_en_transicion = false
	if anim_name.ends_with("cerrar") or anim_name.ends_with("salida"):
		salida_completada.emit()
	else:
		entrada_completada.emit()
