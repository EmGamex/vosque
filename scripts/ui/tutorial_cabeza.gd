@tool
class_name TutorialCabeza
extends Node2D

## Tutorial diegético flotante anclado sobre la cabeza del personaje (Vector2(0, -90)).
## Controla el onboarding interactivo sin pausas ni ventanas emergentes.

signal paso_cambiado(nuevo_paso: Paso)
signal tutorial_completado(es_fast_path: bool)
signal fast_path_activado

enum Paso {
	PASO_1_MOVIMIENTO,
	PASO_2_SALTO,
	PASO_3_PLANCHA_DIVE,
	PASO_4_SPRINT,
	COMPLETADO
}

static var tutorial_visto: bool = false

@export var color_fondo: Color = Color(0.12, 0.12, 0.13, 0.88)
@export var color_borde: Color = Color.TRANSPARENT
@export var color_activo: Color = Color(0.70, 0.70, 0.72)
@export var color_inactivo: Color = Color(0.85, 0.85, 0.85, 0.90)
@export var color_acento_dorado: Color = Color(0.85, 0.85, 0.85)

var paso_actual: Paso = Paso.PASO_1_MOVIMIENTO

# Nodos del árbol de UI
@onready var contenedor: PanelContainer = get_node_or_null("Contenedor") as PanelContainer
@onready var paso1_movimiento: HBoxContainer = get_node_or_null("Contenedor/Paso1_Movimiento") as HBoxContainer
@onready var paso2_salto: HBoxContainer = get_node_or_null("Contenedor/Paso2_SaltoDive") as HBoxContainer
@onready var paso3_plancha_dive: HBoxContainer = get_node_or_null("Contenedor/Paso3_PlanchaDive") as HBoxContainer
@onready var paso4_sprint: HBoxContainer = get_node_or_null("Contenedor/Paso3_Sprint") as HBoxContainer

@onready var badge_w: PanelContainer = get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeW") as PanelContainer
@onready var badge_a: PanelContainer = get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeA") as PanelContainer
@onready var badge_s: PanelContainer = get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeS") as PanelContainer
@onready var badge_d: PanelContainer = get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeD") as PanelContainer

@onready var icono_raton: Control = get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorRaton/IconoRaton") as Control
@onready var label_orientar: Label = get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorRaton/LabelOrientar") as Label

@onready var badge_espacio: PanelContainer = get_node_or_null("Contenedor/Paso2_SaltoDive/BadgeEspacio") as PanelContainer
@onready var label_accion_salto: Label = get_node_or_null("Contenedor/Paso2_SaltoDive/LabelAccionSalto") as Label

@onready var badge_espacio_dive: PanelContainer = get_node_or_null("Contenedor/Paso3_PlanchaDive/BadgeEspacioDive") as PanelContainer
@onready var label_accion_dive: Label = get_node_or_null("Contenedor/Paso3_PlanchaDive/LabelAccionDive") as Label

@onready var badge_shift: PanelContainer = get_node_or_null("Contenedor/Paso3_Sprint/BadgeShift") as PanelContainer
@onready var label_accion_sprint: Label = get_node_or_null("Contenedor/Paso3_Sprint/LabelAccionSprint") as Label

# Estado de teclas / inputs
var _tecla_w_activa: bool = false
var _tecla_a_activa: bool = false
var _tecla_s_activa: bool = false
var _tecla_d_activa: bool = false
var _raton_activo: bool = false
var _tecla_espacio_activa: bool = false
var _tecla_shift_activa: bool = false

# Criterios de avance e iluminación persistente
var _w_registrado: bool = false
var _a_registrado: bool = false
var _s_registrado: bool = false
var _d_registrado: bool = false
var _raton_registrado: bool = false
var _salto_registrado: bool = false
var _dive_registrado: bool = false
var _sprint_registrado: bool = false

var _distancia_raton_acumulada: float = 0.0
const UMBRAL_MOVIMIENTO_RATON: float = 30.0
var _tiempo_completado_paso_1: float = 0.0
var _tiempo_desplazamiento: float = 0.0
var _tiempo_iluminacion_raton: float = 0.0
var _tiempo_en_paso_actual: float = 0.0

# Seguimiento físico de estados
var _en_el_aire: bool = false
var _salto_en_curso: bool = false

# Animaciones / Tweens
var _flash_unisono: bool = false
var _color_flash: Color = Color.WHITE
var _cerrando: bool = false
var _tween_cierre: Tween = null
var _tween_pop: Tween = null

# Estilos cacheados
var _sb_fondo: StyleBoxFlat = null
var _sb_badge_inactivo: StyleBoxFlat = null
var _sb_badge_activo: StyleBoxFlat = null
var _sb_badge_dive: StyleBoxFlat = null


static func reiniciar_tutorial() -> void:
	tutorial_visto = false


func _ready() -> void:
	z_index = 3
	if tutorial_visto and not Engine.is_editor_hint():
		queue_free()
		return

	scale = Vector2.ONE
	modulate.a = 1.0

	_crear_estilos()
	_aplicar_estilos_base()
	_centrar_contenedor()
	_conectar_padre()
	_conectar_director_juego()

	if icono_raton != null and not icono_raton.draw.is_connected(_on_icono_raton_draw):
		icono_raton.draw.connect(_on_icono_raton_draw)

	_actualizar_visibilidad_pasos()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _tween_cierre != null and _tween_cierre.is_valid():
			_tween_cierre.kill()
		if _tween_pop != null and _tween_pop.is_valid():
			_tween_pop.kill()


func _crear_estilos() -> void:
	_sb_fondo = StyleBoxFlat.new()
	_sb_fondo.bg_color = color_fondo
	_sb_fondo.border_color = Color.TRANSPARENT
	_sb_fondo.set_border_width_all(0)
	_sb_fondo.set_corner_radius_all(0)
	_sb_fondo.content_margin_left = 8
	_sb_fondo.content_margin_right = 8
	_sb_fondo.content_margin_top = 4
	_sb_fondo.content_margin_bottom = 4

	_sb_badge_inactivo = StyleBoxFlat.new()
	_sb_badge_inactivo.bg_color = Color(0.20, 0.20, 0.22, 0.90)
	_sb_badge_inactivo.border_color = Color.TRANSPARENT
	_sb_badge_inactivo.set_border_width_all(0)
	_sb_badge_inactivo.set_corner_radius_all(0)
	_sb_badge_inactivo.content_margin_left = 6
	_sb_badge_inactivo.content_margin_right = 6
	_sb_badge_inactivo.content_margin_top = 2
	_sb_badge_inactivo.content_margin_bottom = 2

	_sb_badge_activo = StyleBoxFlat.new()
	_sb_badge_activo.bg_color = Color(0.38, 0.38, 0.40, 0.95)
	_sb_badge_activo.border_color = Color.TRANSPARENT
	_sb_badge_activo.set_border_width_all(0)
	_sb_badge_activo.set_corner_radius_all(0)
	_sb_badge_activo.content_margin_left = 6
	_sb_badge_activo.content_margin_right = 6
	_sb_badge_activo.content_margin_top = 2
	_sb_badge_activo.content_margin_bottom = 2

	_sb_badge_dive = StyleBoxFlat.new()
	_sb_badge_dive.bg_color = Color(0.48, 0.48, 0.50, 0.95)
	_sb_badge_dive.border_color = Color.TRANSPARENT
	_sb_badge_dive.set_border_width_all(0)
	_sb_badge_dive.set_corner_radius_all(0)
	_sb_badge_dive.content_margin_left = 6
	_sb_badge_dive.content_margin_right = 6
	_sb_badge_dive.content_margin_top = 2
	_sb_badge_dive.content_margin_bottom = 2


func _aplicar_estilos_base() -> void:
	if contenedor != null and _sb_fondo != null:
		contenedor.add_theme_stylebox_override("panel", _sb_fondo)

	var badges = [badge_w, badge_a, badge_s, badge_d, badge_espacio, badge_espacio_dive, badge_shift]
	for b in badges:
		if b != null and _sb_badge_inactivo != null:
			b.add_theme_stylebox_override("panel", _sb_badge_inactivo)


func _centrar_contenedor() -> void:
	if contenedor == null:
		return
	contenedor.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	contenedor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	contenedor.position = -contenedor.size * 0.5
	if not contenedor.resized.is_connected(_on_contenedor_resized):
		contenedor.resized.connect(_on_contenedor_resized)


func _on_contenedor_resized() -> void:
	if contenedor != null:
		contenedor.position = -contenedor.size * 0.5


func _conectar_padre() -> void:
	var padre = get_parent()
	if padre != null:
		if padre.has_signal("estado_cambiado"):
			if not padre.is_connected("estado_cambiado", Callable(self, "_on_padre_estado_cambiado")):
				padre.connect("estado_cambiado", Callable(self, "_on_padre_estado_cambiado"))


func _conectar_director_juego() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree != null and tree.root != null:
		var maain = tree.root.find_child("Maain", true, false)
		if maain != null and maain.has_signal("nota_recogida"):
			if not maain.is_connected("nota_recogida", Callable(self, "_on_nota_recogida")):
				maain.connect("nota_recogida", Callable(self, "_on_nota_recogida"))


func _unhandled_input(event: InputEvent) -> void:
	if _cerrando:
		return

	if event is InputEventMouseMotion:
		var mov: float = event.relative.length()
		if mov >= 1.0:
			_raton_activo = true
			_tiempo_iluminacion_raton = 0.35
			_distancia_raton_acumulada += mov
			if _distancia_raton_acumulada >= UMBRAL_MOVIMIENTO_RATON:
				_raton_registrado = true
			_actualizar_estilo_raton()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _cerrando:
		return

	_tiempo_en_paso_actual += delta
	_actualizar_entradas(delta)
	_verificar_fast_path()

	match paso_actual:
		Paso.PASO_1_MOVIMIENTO:
			_procesar_paso_1(delta)
		Paso.PASO_2_SALTO:
			_procesar_paso_2(delta)
		Paso.PASO_3_PLANCHA_DIVE:
			_procesar_paso_3(delta)
		Paso.PASO_4_SPRINT:
			_procesar_paso_4(delta)

	_actualizar_estilos_reactivos()


func _actualizar_entradas(delta: float) -> void:
	_tecla_w_activa = Input.is_action_pressed("personaje-arriba")
	_tecla_s_activa = Input.is_action_pressed("personaje-abajo")
	_tecla_a_activa = Input.is_action_pressed("personaje-izquierda")
	_tecla_d_activa = Input.is_action_pressed("personaje-derecha")
	_tecla_espacio_activa = Input.is_action_pressed("personaje-salto")
	_tecla_shift_activa = (
		Input.is_action_pressed("sprint")
		or (InputMap.has_action("personaje-sprint") and Input.is_action_pressed("personaje-sprint"))
	)

	if _tiempo_iluminacion_raton > 0.0:
		_tiempo_iluminacion_raton -= delta
		if _tiempo_iluminacion_raton <= 0.0:
			_raton_activo = false
			_actualizar_estilo_raton()


func _actualizar_estilos_reactivos() -> void:
	if _cerrando and _flash_unisono:
		_aplicar_estilo_badge(badge_w, true, _color_flash)
		_aplicar_estilo_badge(badge_a, true, _color_flash)
		_aplicar_estilo_badge(badge_s, true, _color_flash)
		_aplicar_estilo_badge(badge_d, true, _color_flash)
		_aplicar_estilo_badge(badge_espacio, true, _color_flash)
		_aplicar_estilo_badge(badge_espacio_dive, true, _color_flash)
		_aplicar_estilo_badge(badge_shift, true, _color_flash)
		return

	match paso_actual:
		Paso.PASO_1_MOVIMIENTO:
			# Los botones se mantienen iluminados si ya fueron presionados (_*_registrado o activo)
			_aplicar_estilo_badge(badge_w, _w_registrado or _tecla_w_activa)
			_aplicar_estilo_badge(badge_a, _a_registrado or _tecla_a_activa)
			_aplicar_estilo_badge(badge_s, _s_registrado or _tecla_s_activa)
			_aplicar_estilo_badge(badge_d, _d_registrado or _tecla_d_activa)
			_actualizar_estilo_raton()
		Paso.PASO_2_SALTO:
			_aplicar_estilo_badge(badge_espacio, _salto_registrado or _tecla_espacio_activa)
		Paso.PASO_3_PLANCHA_DIVE:
			if _dive_registrado:
				_aplicar_estilo_badge(badge_espacio_dive, true, color_acento_dorado)
			else:
				_aplicar_estilo_badge(badge_espacio_dive, _en_el_aire or _tecla_espacio_activa)
		Paso.PASO_4_SPRINT:
			_aplicar_estilo_badge(badge_shift, _sprint_registrado or _tecla_shift_activa)


func _aplicar_estilo_badge(badge: PanelContainer, activo: bool, color_override: Color = Color.TRANSPARENT) -> void:
	if badge == null:
		return
	var sb: StyleBoxFlat = null
	if color_override != Color.TRANSPARENT:
		sb = StyleBoxFlat.new()
		sb.bg_color = color_override
		sb.border_color = Color.TRANSPARENT
		sb.set_border_width_all(0)
		sb.set_corner_radius_all(0)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
	elif activo:
		sb = _sb_badge_activo
	else:
		sb = _sb_badge_inactivo

	if sb != null:
		badge.add_theme_stylebox_override("panel", sb)


func _actualizar_estilo_raton() -> void:
	if icono_raton != null:
		icono_raton.queue_redraw()
	if label_orientar != null:
		var iluminado = _raton_registrado or _raton_activo
		label_orientar.add_theme_color_override("font_color", color_activo if iluminado else color_inactivo)


func _verificar_fast_path() -> void:
	if paso_actual != Paso.PASO_1_MOVIMIENTO:
		return

	var hay_movimiento: bool = _tecla_w_activa or _tecla_a_activa or _tecla_s_activa or _tecla_d_activa
	var sprint_combinado: bool = _tecla_shift_activa and hay_movimiento

	if sprint_combinado:
		ejecutar_fast_path()


func ejecutar_fast_path() -> void:
	if _cerrando:
		return
	_cerrando = true
	_flash_unisono = true
	_color_flash = color_activo
	tutorial_visto = true

	fast_path_activado.emit()
	tutorial_completado.emit(true)

	if _tween_cierre != null and _tween_cierre.is_valid():
		_tween_cierre.kill()

	if is_inside_tree():
		_tween_cierre = create_tween().set_parallel(true)
		_tween_cierre.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_cierre.tween_property(self, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_cierre.chain().tween_callback(queue_free)
	else:
		modulate.a = 0.0
		queue_free()


func _procesar_paso_1(delta: float) -> void:
	if _tecla_w_activa: _w_registrado = true
	if _tecla_a_activa: _a_registrado = true
	if _tecla_s_activa: _s_registrado = true
	if _tecla_d_activa: _d_registrado = true

	var padre = get_parent()
	if padre != null and padre is CharacterBody2D:
		if padre.velocity.length() > 30.0:
			_tiempo_desplazamiento += delta

	var todo_completado: bool = (
		_w_registrado
		and _a_registrado
		and _s_registrado
		and _d_registrado
		and _raton_registrado
	)
	if todo_completado:
		_tiempo_completado_paso_1 += delta
		if _tiempo_completado_paso_1 >= 0.35:
			_avanzar_paso(Paso.PASO_2_SALTO)


func _procesar_paso_2(_delta: float) -> void:
	# El salto se completa cuando el personaje salta y toca tierra (en _on_padre_estado_cambiado)
	pass


func _procesar_paso_3(_delta: float) -> void:
	# El dive se detecta cuando el personaje entra en Estado.PLANCHA_AIRE (5)
	# a través de _on_padre_estado_cambiado, garantizando que no se confunda con el salto previo.
	pass


func _procesar_paso_4(_delta: float) -> void:
	var padre = get_parent()
	if padre == null:
		return

	var estado_pj: int = padre.get("estado_actual") if "estado_actual" in padre else -1
	if estado_pj == 2 or (_tecla_shift_activa and padre.velocity.length() > 50.0):
		_sprint_registrado = true
		completar_tutorial_estandar()


func _on_padre_estado_cambiado(nuevo_estado: int, _nombre_estado: String) -> void:
	if nuevo_estado == 4: # SALTO
		_salto_en_curso = true
		_en_el_aire = true
		if paso_actual == Paso.PASO_2_SALTO:
			_salto_registrado = true
	elif nuevo_estado == 5: # PLANCHA_AIRE
		if paso_actual == Paso.PASO_3_PLANCHA_DIVE:
			_dive_registrado = true
			_en_el_aire = true
			_animar_pulso_dive()
	else:
		if _salto_en_curso:
			_salto_en_curso = false
			_en_el_aire = false
			if paso_actual == Paso.PASO_2_SALTO:
				# Tras completar el salto regular, avanzamos al paso dedicado de Plancha/Dive
				_avanzar_paso(Paso.PASO_3_PLANCHA_DIVE)
			elif paso_actual == Paso.PASO_3_PLANCHA_DIVE:
				# Si ejecutó el dive con éxito y aterriza, avanzamos a Sprint
				if _dive_registrado:
					_avanzar_paso(Paso.PASO_4_SPRINT)
		elif _en_el_aire:
			_en_el_aire = false
			if paso_actual == Paso.PASO_3_PLANCHA_DIVE and _dive_registrado:
				_avanzar_paso(Paso.PASO_4_SPRINT)


func _animar_pulso_dive() -> void:
	_color_flash = color_acento_dorado
	_flash_unisono = true
	if is_inside_tree():
		if _tween_pop != null and _tween_pop.is_valid():
			_tween_pop.kill()
		_tween_pop = create_tween()
		_tween_pop.tween_property(self, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween_pop.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween_pop.tween_interval(0.15)
		_tween_pop.tween_callback(func():
			_flash_unisono = false
			_color_flash = Color.WHITE
			if paso_actual == Paso.PASO_3_PLANCHA_DIVE and _dive_registrado:
				_avanzar_paso(Paso.PASO_4_SPRINT)
		)


func _avanzar_paso(siguiente_paso: Paso) -> void:
	if _cerrando:
		return
	if paso_actual == siguiente_paso:
		return
	paso_actual = siguiente_paso
	_tiempo_en_paso_actual = 0.0
	if paso_actual == Paso.PASO_3_PLANCHA_DIVE:
		_dive_registrado = false
		_salto_en_curso = false
		_en_el_aire = false
	_actualizar_visibilidad_pasos()
	paso_cambiado.emit(paso_actual)

	if is_inside_tree():
		if _tween_pop != null and _tween_pop.is_valid():
			_tween_pop.kill()
		_tween_pop = create_tween()
		_tween_pop.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_pop.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _actualizar_visibilidad_pasos() -> void:
	if paso1_movimiento != null:
		paso1_movimiento.visible = (paso_actual == Paso.PASO_1_MOVIMIENTO)
	if paso2_salto != null:
		paso2_salto.visible = (paso_actual == Paso.PASO_2_SALTO)
	if paso3_plancha_dive != null:
		paso3_plancha_dive.visible = (paso_actual == Paso.PASO_3_PLANCHA_DIVE)
	if paso4_sprint != null:
		paso4_sprint.visible = (paso_actual == Paso.PASO_4_SPRINT)

	if contenedor != null:
		call_deferred("_centrar_contenedor")


func completar_tutorial_estandar() -> void:
	if _cerrando:
		return
	_cerrando = true
	paso_actual = Paso.COMPLETADO
	tutorial_visto = true

	tutorial_completado.emit(false)

	if _tween_cierre != null and _tween_cierre.is_valid():
		_tween_cierre.kill()

	if is_inside_tree():
		_tween_cierre = create_tween()
		_tween_cierre.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween_cierre.parallel().tween_property(self, "_color_flash", color_activo, 0.12)
		_tween_cierre.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween_cierre.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		_tween_cierre.tween_callback(queue_free)
	else:
		modulate.a = 0.0
		queue_free()


func _on_nota_recogida(_pos: Vector2, total: int) -> void:
	if total >= 1:
		forzar_salida_nota()


func forzar_salida_nota() -> void:
	if _cerrando:
		return
	_cerrando = true
	tutorial_visto = true

	if _tween_cierre != null and _tween_cierre.is_valid():
		_tween_cierre.kill()

	if is_inside_tree():
		_tween_cierre = create_tween()
		_tween_cierre.tween_property(self, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_cierre.tween_callback(queue_free)
	else:
		modulate.a = 0.0
		queue_free()


# -----------------------------------------------------------------------------
# DIBUJADO PROCEDURAL DEL GLIFO DE RATÓN
# -----------------------------------------------------------------------------

func _on_icono_raton_draw() -> void:
	if icono_raton == null:
		return

	var pos = icono_raton.size * 0.5
	var iluminado = _raton_registrado or _raton_activo or _flash_unisono
	var col: Color = Color(0.9, 0.9, 0.9) if iluminado else Color(0.60, 0.60, 0.60, 0.85)

	# Silueta limpia y sobria del ratón
	var r_cuerpo = Rect2(pos.x - 5, pos.y - 7, 10, 14)
	var sb_raton = StyleBoxFlat.new()
	sb_raton.bg_color = Color(0.20, 0.20, 0.22, 0.90)
	sb_raton.border_color = Color.TRANSPARENT
	sb_raton.set_border_width_all(0)
	sb_raton.set_corner_radius_all(0)
	icono_raton.draw_style_box(sb_raton, r_cuerpo)

	# Divisor de botones
	icono_raton.draw_line(Vector2(pos.x, pos.y - 7), Vector2(pos.x, pos.y - 2), col, 1.0)

	# Cuatro flechas limpias en cruz (+)
	var dist: float = 8.5
	var tam: float = 2.0
	# Arriba
	icono_raton.draw_line(Vector2(pos.x, pos.y - dist), Vector2(pos.x - tam, pos.y - dist + tam), col, 1.0)
	icono_raton.draw_line(Vector2(pos.x, pos.y - dist), Vector2(pos.x + tam, pos.y - dist + tam), col, 1.0)
	# Abajo
	icono_raton.draw_line(Vector2(pos.x, pos.y + dist), Vector2(pos.x - tam, pos.y + dist - tam), col, 1.0)
	icono_raton.draw_line(Vector2(pos.x, pos.y + dist), Vector2(pos.x + tam, pos.y + dist - tam), col, 1.0)
	# Izquierda
	icono_raton.draw_line(Vector2(pos.x - dist, pos.y), Vector2(pos.x - dist + tam, pos.y - tam), col, 1.0)
	icono_raton.draw_line(Vector2(pos.x - dist, pos.y), Vector2(pos.x - dist + tam, pos.y + tam), col, 1.0)
	# Derecha
	icono_raton.draw_line(Vector2(pos.x + dist, pos.y), Vector2(pos.x + dist - tam, pos.y - tam), col, 1.0)
	icono_raton.draw_line(Vector2(pos.x + dist, pos.y), Vector2(pos.x + dist - tam, pos.y + tam), col, 1.0)



