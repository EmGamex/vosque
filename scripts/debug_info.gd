@tool
extends CanvasLayer

## Nodo objetivo del cual leer las estadísticas (si no se asigna, busca automáticamente al personaje)
@export var target_character: CharacterBody2D

## Controla si la interfaz de depuración es visible tanto en el editor como en el juego
@export var debug_visible: bool = false:
	set(value):
		debug_visible = value
		_update_visibility()

@onready var label_velocidad: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelVelocidad
@onready var label_vel_max: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelVelMax
@onready var label_aceleracion: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelAceleracion
@onready var label_friccion: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelFriccion
@onready var label_direccion: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelDireccion
@onready var label_fps: Label = $PanelContainer/MarginContainer/VBoxContainer/LabelFPS
@onready var panel_container: PanelContainer = $PanelContainer
@onready var panel_direccion: PanelContainer = $PanelContainerDireccion
@onready var flecha_up: Label = $PanelContainerDireccion/MarginContainerDir/VBoxContainerDir/GridContainerDir/FlechaUp
@onready var flecha_down: Label = $PanelContainerDireccion/MarginContainerDir/VBoxContainerDir/GridContainerDir/FlechaDown
@onready var flecha_left: Label = $PanelContainerDireccion/MarginContainerDir/VBoxContainerDir/GridContainerDir/FlechaLeft
@onready var flecha_right: Label = $PanelContainerDireccion/MarginContainerDir/VBoxContainerDir/GridContainerDir/FlechaRight

const COLOR_INACTIVO: Color = Color(0.55, 0.60, 0.70, 0.6)
const COLOR_ACTIVO: Color = Color(0.40, 0.85, 1.0, 1.0)


func _ready() -> void:
	_update_visibility()
	
	if Engine.is_editor_hint():
		return
		
	# Si no se asignó un personaje en el inspector, lo buscamos en la escena
	if target_character == null:
		target_character = _find_character(get_tree().current_scene)


func _update_visibility() -> void:
	# CanvasLayer tiene propiedad visible directamente
	visible = debug_visible
	if panel_container != null:
		panel_container.visible = debug_visible
	if panel_direccion != null:
		panel_direccion.visible = debug_visible


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
		
	# Permite alternar la visibilidad del debug con la tecla F3
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F3:
			debug_visible = not debug_visible


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or not visible:
		return

	label_fps.text = "FPS: %d" % Engine.get_frames_per_second()
	
	if target_character == null:
		target_character = _find_character(get_tree().current_scene)
		if target_character == null:
			label_velocidad.text = "Personaje: No encontrado"
			return

	# Lectura de variables del script del personaje
	var current_vel: Vector2 = target_character.velocity
	var vel_len: float = current_vel.length()
	var spd: float = target_character.get("speed") if "speed" in target_character else 0.0
	var accel: float = target_character.get("acceleration") if "acceleration" in target_character else 0.0
	var fric: float = target_character.get("friction") if "friction" in target_character else 0.0
	
	var dir: Vector2 = Input.get_vector("personaje-izquierda", "personaje-derecha", "personaje-arriba", "personaje-abajo")
	if dir == Vector2.ZERO:
		dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	label_velocidad.text = "Velocidad actual: %.1f px/s (X: %.1f, Y: %.1f)" % [vel_len, current_vel.x, current_vel.y]
	label_vel_max.text = "Velocidad máxima: %.1f px/s" % spd
	label_aceleracion.text = "Aceleración: %.1f px/s²" % accel
	label_friccion.text = "Fricción: %.1f px/s²" % fric
	label_direccion.text = "Input dirección: (X: %.2f, Y: %.2f)" % [dir.x, dir.y]

	_actualizar_flechas(dir)


func _actualizar_flechas(dir: Vector2) -> void:
	if flecha_up == null:
		return
	flecha_up.modulate = COLOR_ACTIVO if dir.y < -0.2 else COLOR_INACTIVO
	flecha_down.modulate = COLOR_ACTIVO if dir.y > 0.2 else COLOR_INACTIVO
	flecha_left.modulate = COLOR_ACTIVO if dir.x < -0.2 else COLOR_INACTIVO
	flecha_right.modulate = COLOR_ACTIVO if dir.x > 0.2 else COLOR_INACTIVO


func _find_character(node: Node) -> CharacterBody2D:
	if node is CharacterBody2D:
		return node
	for child in node.get_children():
		var found := _find_character(child)
		if found != null:
			return found
	return null
