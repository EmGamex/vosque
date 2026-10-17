@tool
extends PanelContainer

const SpinSizing = preload("res://addons/personaje_tools/character_spin_sizing.gd")
const IconoPersonaje = preload("res://addons/personaje_tools/character_icon.gd")

const PROPIEDADES := ["speed", "acceleration", "friction"]
const PRESETS := {
	"Sigilo": {"speed": 150.0, "acceleration": 800.0, "friction": 1000.0},
	"Normal": {"speed": 800.0, "acceleration": 5000.0, "friction": 5000.0},
	"Sprint": {"speed": 1000.0, "acceleration": 5000.0, "friction": 5000.0},
}
const INTERVALO_SYNC := 0.15

@export var icono_personalizado: Texture2D:
	set(val):
		icono_personalizado = val
		_actualizar_icono()

@export var presets: Dictionary = {}

var _personaje_actual: CharacterBody2D = null
var _spins: Dictionary[String, SpinBox] = {}
var _base_spins: Dictionary[String, Dictionary] = {}
var _sincronizando := false
var _t_sync := 0.0

@onready var texture_rect_icon: TextureRect = $HBox/IconContainer/TextureRectIcon
@onready var label_nombre: Label = $HBox/LabelNombre
@onready var spin_speed: SpinBox = $HBox/SpeedBox/SpinSpeed
@onready var spin_accel: SpinBox = $HBox/AccelBox/SpinAccel
@onready var spin_friction: SpinBox = $HBox/FrictionBox/SpinFriction
@onready var preset_box: HBoxContainer = $HBox/PresetBox


func _ready() -> void:
	set_process(false)
	if presets == null or presets.is_empty():
		presets = PRESETS.duplicate(true)

	_spins = {
		"speed": spin_speed,
		"acceleration": spin_accel,
		"friction": spin_friction,
	}
	for propiedad: String in _spins:
		_spins[propiedad].value_changed.connect(_cambiar_propiedad_con_undo.bind(propiedad))
	_asegurar_estado()

	for nodo in preset_box.get_children():
		var boton := nodo as Button
		if boton == null:
			continue
		# El texto del botón puede traducirse o cambiar; la clave del preset se puede fijar aparte con metadata.
		var clave: String = str(boton.get_meta("preset", boton.text))
		if not presets.has(clave):
			push_warning("El botón '%s' no corresponde a ningún preset definido." % boton.name)
		boton.pressed.connect(_aplicar_preset.bind(clave))

	_actualizar_icono()


func _process(delta: float) -> void:
	# El Inspector y el historial (Ctrl+Z) cambian el personaje sin avisar: sondeamos
	# para que la barra nunca muestre valores desincronizados.
	if not is_visible_in_tree() or not _personaje_valido() or _spins == null or _spins.is_empty():
		return
	_t_sync += delta
	if _t_sync < INTERVALO_SYNC:
		return
	_t_sync = 0.0
	for propiedad: String in _spins:
		_sincronizar_spin_si_procede(propiedad, _spins[propiedad])


func _sincronizar_spin_si_procede(propiedad: String, spin: SpinBox) -> void:
	# No pisar lo que el usuario está escribiendo en el control.
	var line := spin.get_line_edit()
	if line != null and line.has_focus():
		return
	var valor: float = _personaje_actual.get(propiedad)
	# Fuera del rango del control ya avisa _avisar_si_fuera_de_rango; aquí no luchamos contra el clamp.
	if valor < spin.min_value or valor > spin.max_value:
		return
	if not is_equal_approx(spin.value, valor):
		spin.set_value_no_signal(valor)


func set_personaje(personaje: CharacterBody2D) -> void:
	# Un script tool puede llamar antes de _ready; esperar evita perder la sincronización inicial.
	if not is_node_ready():
		await ready
	# El nodo pudo liberarse antes de llegar aquí (p. ej. borrado desde el editor).
	_personaje_actual = personaje if is_instance_valid(personaje) else null
	set_process(_personaje_valido())
	_sincronizando = true
	_configurar_spinboxes()
	_sincronizar_desde_personaje()
	_sincronizando = false


## Un nodo borrado en el editor deja de ser válido pero no pasa a null: hay que
## comprobarlo con is_instance_valid para no operar sobre una instancia liberada.
func _personaje_valido() -> bool:
	return is_instance_valid(_personaje_actual)


func _configurar_spinboxes() -> void:
	if not _personaje_valido():
		return

	_asegurar_estado()
	var hints := _hints_de_personaje()
	for propiedad: String in _spins:
		var spin := _spins[propiedad]
		_restaurar_base_spin(propiedad, spin)
		if hints.has(propiedad):
			_aplicar_hint_range(spin, hints[propiedad])
		SpinSizing.ajustar_ancho(spin)
		_avisar_si_fuera_de_rango(propiedad, spin)


## Reconstruye el estado de trabajo si falta: un recargado en caliente del script
## (frecuente en scripts @tool al guardar) puede dejar los miembros de instancia en null.
func _asegurar_estado() -> void:
	if _spins == null or _spins.is_empty():
		_spins = {
			"speed": spin_speed,
			"acceleration": spin_accel,
			"friction": spin_friction,
		}
	if _base_spins == null:
		_base_spins = {}
	if _base_spins.size() != _spins.size():
		for propiedad: String in _spins:
			_base_spins[propiedad] = _capturar_base_spin(_spins[propiedad])


func _hints_de_personaje() -> Dictionary:
	var hints: Dictionary = {}
	for info in _personaje_actual.get_property_list():
		if info.hint == PROPERTY_HINT_RANGE:
			hints[String(info.name)] = info.hint_string
	return hints


## Los rangos base vienen de la escena: hay que recordarlos para no arrastrarlos de un personaje a otro.
func _capturar_base_spin(spin: SpinBox) -> Dictionary:
	return {
		"min": spin.min_value,
		"max": spin.max_value,
		"step": spin.step,
		"suffix": spin.suffix,
		"ancho": spin.custom_minimum_size.x,
	}


func _restaurar_base_spin(propiedad: String, spin: SpinBox) -> void:
	if not _base_spins.has(propiedad):
		return
	var base: Dictionary = _base_spins[propiedad]
	spin.min_value = base["min"]
	spin.max_value = base["max"]
	spin.step = base["step"]
	spin.suffix = base["suffix"]
	spin.custom_minimum_size.x = base["ancho"]


func _aplicar_hint_range(spin: SpinBox, hint: String) -> void:
	var partes := hint.split(",")
	if partes.size() >= 2:
		var minimo := partes[0].strip_edges()
		var maximo := partes[1].strip_edges()
		if minimo.is_valid_float():
			spin.min_value = minimo.to_float()
		if maximo.is_valid_float():
			spin.max_value = maximo.to_float()
	# El tercer campo puede ser un modificador ("or_greater", "exp"...) en lugar de un paso numérico.
	if partes.size() >= 3 and partes[2].strip_edges().is_valid_float():
		spin.step = partes[2].strip_edges().to_float()
	for parte in partes:
		if parte.strip_edges().begins_with("suffix:"):
			spin.suffix = parte.strip_edges().trim_prefix("suffix:")
			break


func _avisar_si_fuera_de_rango(propiedad: String, spin: SpinBox) -> void:
	if not _personaje_valido() or propiedad not in _personaje_actual:
		return
	var valor: float = _personaje_actual.get(propiedad)
	if valor < spin.min_value or valor > spin.max_value:
		push_warning(
			(
				"El valor de '%s' en '%s' (%s) queda fuera del rango del control (%s a %s)."
				% [propiedad, _personaje_actual.name, valor, spin.min_value, spin.max_value]
			)
		)


func _sincronizar_desde_personaje() -> void:
	if not _personaje_valido():
		return

	label_nombre.text = _personaje_actual.name
	for propiedad: String in _spins:
		if propiedad in _personaje_actual:
			_spins[propiedad].set_value_no_signal(_personaje_actual.get(propiedad))
	_actualizar_icono()


func _actualizar_icono() -> void:
	if texture_rect_icon == null:
		return
	texture_rect_icon.texture = IconoPersonaje.resolver(icono_personalizado, _personaje_actual)


func _cambiar_propiedad_con_undo(nuevo_valor: float, propiedad: String) -> void:
	if _sincronizando or not _personaje_valido():
		return
	if _personaje_actual.get(propiedad) == nuevo_valor:
		return

	_aplicar_con_undo("Física del personaje: %s" % propiedad, {propiedad: nuevo_valor}, true)


func _aplicar_preset(nombre: String) -> void:
	if not _personaje_valido():
		return
	if nombre not in presets:
		push_warning("Preset '%s' no definido en la barra de personaje." % nombre)
		return

	_aplicar_con_undo("Aplicar preset '%s' al personaje" % nombre, presets[nombre])


func _aplicar_con_undo(descripcion: String, cambios: Dictionary, combinar := false) -> void:
	if not _personaje_valido():
		return

	# Ignoramos propiedades que el personaje no tiene para no registrar operaciones inválidas.
	var cambios_validos: Dictionary = {}
	for propiedad in cambios:
		if propiedad in _personaje_actual:
			cambios_validos[propiedad] = cambios[propiedad]
	if cambios_validos.is_empty():
		return

	var undo_redo := EditorInterface.get_editor_undo_redo()
	if undo_redo == null:
		for propiedad in cambios_validos:
			_personaje_actual.set(propiedad, cambios_validos[propiedad])
		_sincronizar_desde_personaje()
		return

	# MERGE_ENDS fusiona ajustes seguidos del mismo control en una sola acción de deshacer.
	undo_redo.create_action(
		descripcion,
		UndoRedo.MERGE_ENDS if combinar else UndoRedo.MERGE_DISABLE,
		_personaje_actual
	)
	for propiedad in cambios_validos:
		undo_redo.add_do_property(_personaje_actual, propiedad, cambios_validos[propiedad])
		undo_redo.add_undo_property(_personaje_actual, propiedad, _personaje_actual.get(propiedad))
	undo_redo.add_do_method(self, "_sincronizar_desde_personaje")
	undo_redo.add_undo_method(self, "_sincronizar_desde_personaje")
	undo_redo.commit_action()
