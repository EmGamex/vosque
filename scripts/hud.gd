@tool
class_name HUD
extends CanvasLayer

## Capa de Interfaz de Usuario en Pantalla (Layer = 10).
## Administra el contador elástico de notas y la respuesta visual ante eventos del Game Director.

@export var formato_contador: String = "x %d"
@export var color_texto: Color = Color.WHITE
@export var color_flash_punch: Color = Color(1.6, 1.5, 1.2, 1.0)

@onready var contenedor_contador: Control = get_node_or_null("MargenSeguridad/ContadorNotas") as Control
@onready var icono_nota: TextureRect = get_node_or_null("MargenSeguridad/ContadorNotas/IconoNota") as TextureRect
@onready var label_notas: Label = get_node_or_null("MargenSeguridad/ContadorNotas/LabelNotas") as Label

var _tween_punch: Tween = null

func _ready() -> void:
	layer = 10
	_resolver_referencias()
	if label_notas != null:
		label_notas.text = formato_contador % 0
		label_notas.add_theme_color_override("font_color", color_texto)

func _resolver_referencias() -> void:
	if contenedor_contador == null:
		contenedor_contador = get_node_or_null("MargenSeguridad/ContadorNotas") as Control
	if icono_nota == null:
		icono_nota = get_node_or_null("MargenSeguridad/ContadorNotas/IconoNota") as TextureRect
	if label_notas == null:
		label_notas = get_node_or_null("MargenSeguridad/ContadorNotas/LabelNotas") as Label

func actualizar_contador(total_notas: int, con_animacion: bool = true) -> void:
	_resolver_referencias()
	if label_notas != null:
		label_notas.text = formato_contador % total_notas

	if not con_animacion or not is_inside_tree() or contenedor_contador == null:
		return

	_ejecutar_scale_punch()

func _ejecutar_scale_punch() -> void:
	if _tween_punch != null and _tween_punch.is_valid():
		_tween_punch.kill()

	# Ajustar punto de pivote centrado verticalmente a la izquierda
	contenedor_contador.pivot_offset = Vector2(0.0, contenedor_contador.size.y * 0.5)

	_tween_punch = create_tween().set_parallel(true)
	_tween_punch.tween_property(contenedor_contador, "scale", Vector2.ONE, 0.25).from(Vector2(1.3, 1.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if label_notas != null:
		_tween_punch.tween_property(label_notas, "modulate", Color.WHITE, 0.2).from(color_flash_punch)
