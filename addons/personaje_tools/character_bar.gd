@tool
extends PanelContainer

const PROPIEDADES := ["speed", "acceleration", "friction"]
const PRESETS := {
	"Sigilo": {"speed": 150.0, "acceleration": 800.0, "friction": 1000.0},
	"Normal": {"speed": 800.0, "acceleration": 5000.0, "friction": 5000.0},
	"Sprint": {"speed": 1000.0, "acceleration": 5000.0, "friction": 5000.0},
}
const ICONO_POR_DEFECTO := "res://icon.svg"

## Textura personalizable para el icono del personaje.
@export var icono_personalizado: Texture2D:
	set(val):
		icono_personalizado = val
		_actualizar_icono()

## Valores por preset. Si se deja vacío, se usan los definidos en PRESETS.
@export var presets: Dictionary = {}

var _personaje_actual: CharacterBody2D = null
var _spins: Dictionary = {}

@onready var texture_rect_icon: TextureRect = $HBox/IconContainer/TextureRectIcon
@onready var label_nombre: Label = $HBox/LabelNombre
@onready var spin_speed: SpinBox = $HBox/SpeedBox/SpinSpeed
@onready var spin_accel: SpinBox = $HBox/AccelBox/SpinAccel
@onready var spin_friction: SpinBox = $HBox/FrictionBox/SpinFriction
@onready var preset_box: HBoxContainer = $HBox/PresetBox


func _ready() -> void:
	if presets.is_empty():
		presets = PRESETS.duplicate(true)

	_spins = {
		"speed": spin_speed,
		"acceleration": spin_accel,
		"friction": spin_friction,
	}
	for propiedad: String in _spins:
		(_spins[propiedad] as SpinBox).value_changed.connect(_cambiar_propiedad_con_undo.bind(propiedad))

	for nodo in preset_box.get_children():
		var boton := nodo as Button
		if boton == null:
			continue
		boton.pressed.connect(_aplicar_preset.bind(boton.text))

	_actualizar_icono()


func set_personaje(personaje: CharacterBody2D) -> void:
	_personaje_actual = personaje
	_configurar_spinboxes()
	_sincronizar_desde_personaje()


func _configurar_spinboxes() -> void:
	if _personaje_actual == null:
		return
	for propiedad: String in _spins:
		_aplicar_rango_del_personaje(propiedad, _spins[propiedad] as SpinBox)


func _aplicar_rango_del_personaje(propiedad: String, spin: SpinBox) -> void:
	for info in _personaje_actual.get_property_list():
		if info.name == propiedad and info.hint == PROPERTY_HINT_RANGE:
			_aplicar_hint_range(spin, info.hint_string)
			return


func _aplicar_hint_range(spin: SpinBox, hint: String) -> void:
	var partes := hint.split(",")
	if partes.size() >= 2:
		spin.min_value = partes[0].strip_edges().to_float()
		spin.max_value = partes[1].strip_edges().to_float()
	if partes.size() >= 3:
		spin.step = partes[2].strip_edges().to_float()
	for parte in partes:
		if parte.strip_edges().begins_with("suffix:"):
			spin.suffix = parte.strip_edges().trim_prefix("suffix:")
			break


func _sincronizar_desde_personaje() -> void:
	if _personaje_actual == null:
		return

	label_nombre.text = _personaje_actual.name
	for propiedad: String in _spins:
		if propiedad in _personaje_actual:
			(_spins[propiedad] as SpinBox).set_value_no_signal(_personaje_actual.get(propiedad))
	_actualizar_icono()


func _actualizar_icono() -> void:
	if texture_rect_icon == null:
		return
	texture_rect_icon.texture = _resolver_icono()


func _resolver_icono() -> Texture2D:
	if icono_personalizado != null:
		return icono_personalizado

	if _personaje_actual != null:
		for nodo in _personaje_actual.get_children():
			var sprite := nodo as Sprite2D
			if sprite != null and sprite.texture != null:
				return sprite.texture

	if ResourceLoader.exists(ICONO_POR_DEFECTO):
		return load(ICONO_POR_DEFECTO) as Texture2D
	return null


func _cambiar_propiedad_con_undo(nuevo_valor: float, propiedad: String) -> void:
	if _personaje_actual == null:
		return

	var valor_antiguo: Variant = _personaje_actual.get(propiedad)
	if valor_antiguo == nuevo_valor:
		return

	var undo_redo := EditorInterface.get_editor_undo_redo()
	if undo_redo == null:
		_personaje_actual.set(propiedad, nuevo_valor)
		return

	undo_redo.create_action("Física del personaje: %s" % propiedad, UndoRedo.MERGE_ENDS)
	undo_redo.add_do_property(_personaje_actual, propiedad, nuevo_valor)
	undo_redo.add_undo_property(_personaje_actual, propiedad, valor_antiguo)
	undo_redo.add_do_method(self, "_sincronizar_desde_personaje")
	undo_redo.add_undo_method(self, "_sincronizar_desde_personaje")
	undo_redo.commit_action()


func _aplicar_preset(nombre: String) -> void:
	if _personaje_actual == null:
		return
	if nombre not in presets:
		push_warning("Preset '%s' no definido en la barra de personaje." % nombre)
		return

	var valores: Dictionary = presets[nombre]
	var undo_redo := EditorInterface.get_editor_undo_redo()
	if undo_redo == null:
		for propiedad: String in valores:
			_personaje_actual.set(propiedad, valores[propiedad])
		_sincronizar_desde_personaje()
		return

	undo_redo.create_action("Aplicar preset '%s' al personaje" % nombre)
	for propiedad: String in valores:
		undo_redo.add_do_property(_personaje_actual, propiedad, valores[propiedad])
		undo_redo.add_undo_property(_personaje_actual, propiedad, _personaje_actual.get(propiedad))
	undo_redo.add_do_method(self, "_sincronizar_desde_personaje")
	undo_redo.add_undo_method(self, "_sincronizar_desde_personaje")
	undo_redo.commit_action()
