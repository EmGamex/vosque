@tool
extends PanelContainer
class_name DebugWindow

## Componente base reutilizable para ventanas flotantes del DebugWindowManager.
## Proporciona arrastre (drag & drop), colapsado (_), fijado en pantalla (📌)
## y modo interactivo semitransparente cuando el juego está activo.

signal visibilidad_cambiada(window_id: String, abierta: bool)
signal estado_modificado(window_id: String)

@export var window_id: String = ""
@export var window_title: String = "Ventana Debug":
	set(val):
		window_title = val
		if lbl_titulo != null:
			lbl_titulo.text = val

@export var abierta: bool = false:
	set(val):
		abierta = val
		visible = abierta
		emit_signal("visibilidad_cambiada", window_id, abierta)

@export var fijada: bool = false:
	set(val):
		fijada = val
		_actualizar_boton_fijar()
		emit_signal("estado_modificado", window_id)

@export var colapsada: bool = false:
	set(val):
		colapsada = val
		_actualizar_colapsado()
		emit_signal("estado_modificado", window_id)

var arrastrando: bool = false
var offset_arrastre: Vector2 = Vector2.ZERO

@onready var barra_titulo: HBoxContainer = $Margin/VBox/BarraTitulo
@onready var lbl_titulo: Label = $Margin/VBox/BarraTitulo/LblTitulo
@onready var btn_fijar: Button = $Margin/VBox/BarraTitulo/BtnFijar
@onready var btn_colapsar: Button = $Margin/VBox/BarraTitulo/BtnColapsar
@onready var btn_cerrar: Button = $Margin/VBox/BarraTitulo/BtnCerrar
@onready var contenedor_contenido: Container = $Margin/VBox/Contenido


func _ready() -> void:
	if lbl_titulo != null:
		lbl_titulo.text = window_title
	if btn_fijar != null and not btn_fijar.pressed.is_connected(_on_btn_fijar_pressed):
		btn_fijar.pressed.connect(_on_btn_fijar_pressed)
	if btn_colapsar != null and not btn_colapsar.pressed.is_connected(_on_btn_colapsar_pressed):
		btn_colapsar.pressed.connect(_on_btn_colapsar_pressed)
	if btn_cerrar != null and not btn_cerrar.pressed.is_connected(_on_btn_cerrar_pressed):
		btn_cerrar.pressed.connect(_on_btn_cerrar_pressed)
	
	_actualizar_boton_fijar()
	_actualizar_colapsado()
	visible = abierta


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Elevar al frente cuando se interactúa
				move_to_front()
				# Si el clic fue en la barra de título, iniciar arrastre
				if barra_titulo != null:
					var rect_barra = barra_titulo.get_global_rect()
					if rect_barra.has_point(event.global_position):
						arrastrando = true
						offset_arrastre = global_position - event.global_position
						accept_event()
			else:
				if arrastrando:
					arrastrando = false
					emit_signal("estado_modificado", window_id)
					accept_event()
	elif event is InputEventMouseMotion and arrastrando:
		var nueva_pos = event.global_position + offset_arrastre
		_aplicar_posicion_segura(nueva_pos)
		accept_event()


func _aplicar_posicion_segura(pos: Vector2) -> void:
	var viewport_rect = get_viewport_rect()
	var tam = size
	# Limitar para no perder la ventana fuera de la pantalla
	var x_clamped = clampf(pos.x, 0.0, maxf(0.0, viewport_rect.size.x - tam.x))
	var y_clamped = clampf(pos.y, 0.0, maxf(0.0, viewport_rect.size.y - 30.0))
	global_position = Vector2(x_clamped, y_clamped)


func _on_btn_fijar_pressed() -> void:
	fijada = not fijada


func _on_btn_colapsar_pressed() -> void:
	colapsada = not colapsada


func _on_btn_cerrar_pressed() -> void:
	abierta = false
	emit_signal("estado_modificado", window_id)


func _actualizar_boton_fijar() -> void:
	if btn_fijar != null:
		btn_fijar.text = "📌" if fijada else "📍"
		btn_fijar.tooltip_text = "Desanclar ventana" if fijada else "Fijar en pantalla durante el juego"


func _actualizar_colapsado() -> void:
	if contenedor_contenido != null:
		contenedor_contenido.visible = not colapsada
	if btn_colapsar != null:
		btn_colapsar.text = "+" if colapsada else "_"
		btn_colapsar.tooltip_text = "Expandir contenido" if colapsada else "Minimizar contenido"
	# Reajustar tamaño automáticamente
	reset_size()


## Configura la apariencia según si estamos en Modo Edición o Modo Juego
func aplicar_modo_juego(en_modo_juego: bool) -> void:
	if en_modo_juego:
		# En modo juego, solo se muestra si está fijada
		visible = abierta and fijada
		if visible:
			# Semitransparente pero interactiva
			modulate.a = 0.75
	else:
		# En modo edición, se muestra si está abierta
		visible = abierta
		modulate.a = 1.0


## Retorna el contenido para empaquetado o manipulación
func get_content_node() -> Container:
	return contenedor_contenido
