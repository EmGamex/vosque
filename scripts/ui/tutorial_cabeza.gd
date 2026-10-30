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
	PASO_2_SALTO_DIVE,
	PASO_3_SPRINT,
	COMPLETADO
}

static var tutorial_visto: bool = false

@export var fuente: Font = preload("res://fuentes/raleway_bold.tres")
@export var color_fondo: Color = Color(0.08, 0.10, 0.15, 0.85)
@export var color_borde: Color = Color(0.30, 0.40, 0.55, 0.70)
@export var color_activo: Color = Color("#4ade80")
@export var color_inactivo: Color = Color(0.85, 0.90, 0.95, 0.90)
@export var color_acento_dorado: Color = Color("#fbbf24")

var paso_actual: Paso = Paso.PASO_1_MOVIMIENTO

# Estado de teclas / inputs
var _tecla_w_activa: bool = false
var _tecla_a_activa: bool = false
var _tecla_s_activa: bool = false
var _tecla_d_activa: bool = false
var _raton_activo: bool = false
var _tecla_espacio_activa: bool = false
var _tecla_shift_activa: bool = false

# Criterios de avance Paso 1
var _w_registrado: bool = false
var _a_registrado: bool = false
var _s_registrado: bool = false
var _d_registrado: bool = false
var _tiempo_desplazamiento: float = 0.0
var _tiempo_iluminacion_raton: float = 0.0

# Paso 2 - Contextual
var _en_el_aire: bool = false
var _dive_realizado: bool = false
var _salto_en_curso: bool = false

# Animaciones / Tweens
var _flash_unisono: bool = false
var _color_flash: Color = Color.WHITE
var _cerrando: bool = false
var _tween_cierre: Tween = null
var _tween_pop: Tween = null


static func reiniciar_tutorial() -> void:
	tutorial_visto = false


func _ready() -> void:
	z_index = 3
	if tutorial_visto and not Engine.is_editor_hint():
		queue_free()
		return

	scale = Vector2.ONE
	modulate.a = 1.0

	_conectar_padre()
	_conectar_director_juego()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _tween_cierre != null and _tween_cierre.is_valid():
			_tween_cierre.kill()
		if _tween_pop != null and _tween_pop.is_valid():
			_tween_pop.kill()


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
		if event.relative.length() >= 3.0:
			_raton_activo = true
			_tiempo_iluminacion_raton = 0.35
			queue_redraw()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _cerrando:
		return

	_actualizar_entradas(delta)
	_verificar_fast_path()

	match paso_actual:
		Paso.PASO_1_MOVIMIENTO:
			_procesar_paso_1(delta)
		Paso.PASO_2_SALTO_DIVE:
			_procesar_paso_2(delta)
		Paso.PASO_3_SPRINT:
			_procesar_paso_3(delta)

	queue_redraw()


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


func _verificar_fast_path() -> void:
	if paso_actual != Paso.PASO_1_MOVIMIENTO:
		return

	var hay_movimiento: bool = _tecla_w_activa or _tecla_a_activa or _tecla_s_activa or _tecla_d_activa
	var sprint_combinado: bool = _tecla_shift_activa and hay_movimiento
	var salto_directo: bool = Input.is_action_just_pressed("personaje-salto")

	if sprint_combinado or salto_directo:
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

	var todas_pulsadas: bool = _w_registrado and _a_registrado and _s_registrado and _d_registrado
	if todas_pulsadas or _tiempo_desplazamiento >= 0.8:
		_avanzar_paso(Paso.PASO_2_SALTO_DIVE)


func _procesar_paso_2(_delta: float) -> void:
	var padre = get_parent()
	if padre == null:
		return

	# Si está en el aire y pulsa salto -> se ejecuta plancha (dive)
	if _en_el_aire and Input.is_action_just_pressed("personaje-salto"):
		_dive_realizado = true
		_animar_pulso_dive()


func _procesar_paso_3(_delta: float) -> void:
	var padre = get_parent()
	if padre == null:
		return

	var estado_pj: int = padre.get("estado_actual") if "estado_actual" in padre else -1
	# 2 corresponde a Estado.SPRINT en Personaje
	if estado_pj == 2 or (_tecla_shift_activa and padre.velocity.length() > 50.0):
		completar_tutorial_estandar()


func _on_padre_estado_cambiado(nuevo_estado: int, _nombre_estado: String) -> void:
	# Estados según enum en Personaje:
	# 4: SALTO, 5: PLANCHA_AIRE, 0: REPOSO, 1: CAMINANDO, 2: SPRINT, 3: FATIGA, 6: RECUPERANDOSE
	if nuevo_estado == 4: # SALTO
		_salto_en_curso = true
		_en_el_aire = true
		queue_redraw()
	elif nuevo_estado == 5: # PLANCHA_AIRE
		_dive_realizado = true
		_en_el_aire = true
		_animar_pulso_dive()
	else:
		if _salto_en_curso:
			_salto_en_curso = false
			_en_el_aire = false
			if paso_actual == Paso.PASO_2_SALTO_DIVE:
				# Convalidar salto regular o dive al tocar suelo
				_avanzar_paso(Paso.PASO_3_SPRINT)
		elif _en_el_aire:
			_en_el_aire = false
			queue_redraw()


func _animar_pulso_dive() -> void:
	_color_flash = color_acento_dorado
	_flash_unisono = true
	if is_inside_tree():
		if _tween_pop != null and _tween_pop.is_valid():
			_tween_pop.kill()
		_tween_pop = create_tween()
		_tween_pop.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween_pop.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween_pop.tween_callback(func():
			_flash_unisono = false
			_color_flash = Color.WHITE
			if paso_actual == Paso.PASO_2_SALTO_DIVE:
				_avanzar_paso(Paso.PASO_3_SPRINT)
		)


func _avanzar_paso(siguiente_paso: Paso) -> void:
	if _cerrando:
		return
	paso_actual = siguiente_paso
	paso_cambiado.emit(paso_actual)

	# Micro-pop de transición de paso
	if is_inside_tree():
		if _tween_pop != null and _tween_pop.is_valid():
			_tween_pop.kill()
		_tween_pop = create_tween()
		_tween_pop.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_tween_pop.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	queue_redraw()


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
		# Pulso de confirmación general
		_tween_cierre.tween_property(self, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween_cierre.parallel().tween_property(self, "_color_flash", color_activo, 0.12)
		_tween_cierre.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		# Fade-out en 0.4s
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
# RENDERIZADO PROCEDURAL (_draw)
# -----------------------------------------------------------------------------

func _draw() -> void:
	if modulate.a <= 0.001:
		return

	match paso_actual:
		Paso.PASO_1_MOVIMIENTO:
			_dibujar_paso_1()
		Paso.PASO_2_SALTO_DIVE:
			_dibujar_paso_2()
		Paso.PASO_3_SPRINT:
			_dibujar_paso_3()
		Paso.COMPLETADO:
			pass


func _dibujar_pastilla_fondo(ancho: float, alto: float) -> Rect2:
	var rect = Rect2(-ancho * 0.5, -alto * 0.5, ancho, alto)
	var sb = StyleBoxFlat.new()
	sb.bg_color = color_fondo
	sb.set_border_width_all(1)
	sb.border_color = color_borde if not _flash_unisono else _color_flash
	sb.set_corner_radius_all(8)
	draw_style_box(sb, rect)
	return rect


func _dibujar_badge_tecla(pos: Vector2, tamano: Vector2, texto: String, activo: bool) -> void:
	var rect = Rect2(pos - tamano * 0.5, tamano)
	var sb = StyleBoxFlat.new()
	if _flash_unisono:
		sb.bg_color = _color_flash.lerp(Color(0.2, 0.2, 0.2, 0.9), 0.2)
		sb.border_color = _color_flash
	elif activo:
		sb.bg_color = Color(0.18, 0.55, 0.35, 0.95)
		sb.border_color = color_activo
	else:
		sb.bg_color = Color(0.14, 0.18, 0.25, 0.90)
		sb.border_color = Color(0.35, 0.45, 0.55, 0.80)

	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	draw_style_box(sb, rect)

	if fuente != null:
		var col_texto: Color = Color.WHITE if (activo or _flash_unisono) else color_inactivo
		var font_size: int = 12
		var str_sz: Vector2 = fuente.get_string_size(texto, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_pos = Vector2(rect.position.x, rect.position.y + (tamano.y + str_sz.y * 0.6) * 0.5 - 2.0)
		draw_string(fuente, text_pos, texto, HORIZONTAL_ALIGNMENT_CENTER, tamano.x, font_size, col_texto)


func _dibujar_glifo_raton(pos: Vector2, activo: bool) -> void:
	var col: Color = color_activo if (activo or _flash_unisono) else Color(0.70, 0.78, 0.88, 0.85)

	# Cuerpo del ratón
	var r_cuerpo = Rect2(pos.x - 6, pos.y - 8, 12, 16)
	var sb_raton = StyleBoxFlat.new()
	sb_raton.bg_color = Color(0.14, 0.18, 0.25, 0.90)
	sb_raton.border_color = col
	sb_raton.set_border_width_all(1)
	sb_raton.corner_radius_top_left = 5
	sb_raton.corner_radius_top_right = 5
	sb_raton.corner_radius_bottom_left = 3
	sb_raton.corner_radius_bottom_right = 3
	draw_style_box(sb_raton, r_cuerpo)

	# Divisor de botones
	draw_line(Vector2(pos.x, pos.y - 8), Vector2(pos.x, pos.y - 2), col, 1.0)

	# Flechas radiales sutiles de orientación
	var dist: float = 12.0
	var tam: float = 2.5
	# Arriba
	draw_line(Vector2(pos.x, pos.y - dist), Vector2(pos.x - tam, pos.y - dist + tam), col, 1.0)
	draw_line(Vector2(pos.x, pos.y - dist), Vector2(pos.x + tam, pos.y - dist + tam), col, 1.0)
	# Abajo
	draw_line(Vector2(pos.x, pos.y + dist), Vector2(pos.x - tam, pos.y + dist - tam), col, 1.0)
	draw_line(Vector2(pos.x, pos.y + dist), Vector2(pos.x + tam, pos.y + dist - tam), col, 1.0)
	# Izquierda
	draw_line(Vector2(pos.x - dist, pos.y), Vector2(pos.x - dist + tam, pos.y - tam), col, 1.0)
	draw_line(Vector2(pos.x - dist, pos.y), Vector2(pos.x - dist + tam, pos.y + tam), col, 1.0)
	# Derecha
	draw_line(Vector2(pos.x + dist, pos.y), Vector2(pos.x + dist - tam, pos.y - tam), col, 1.0)
	draw_line(Vector2(pos.x + dist, pos.y), Vector2(pos.x + dist - tam, pos.y + tam), col, 1.0)


func _dibujar_paso_1() -> void:
	var ancho: float = 230.0
	var alto: float = 34.0
	_dibujar_pastilla_fondo(ancho, alto)

	# Badges WASD
	var tam_badge = Vector2(20, 20)
	_dibujar_badge_tecla(Vector2(-90, 0), tam_badge, "W", _tecla_w_activa)
	_dibujar_badge_tecla(Vector2(-66, 0), tam_badge, "A", _tecla_a_activa)
	_dibujar_badge_tecla(Vector2(-42, 0), tam_badge, "S", _tecla_s_activa)
	_dibujar_badge_tecla(Vector2(-18, 0), tam_badge, "D", _tecla_d_activa)

	# Separador vertical sutil
	draw_line(Vector2(2, -10), Vector2(2, 10), Color(0.3, 0.4, 0.5, 0.4), 1.0)

	# Glifo de ratón y texto Orientar
	_dibujar_glifo_raton(Vector2(24, 0), _raton_activo)

	if fuente != null:
		var col_texto: Color = color_activo if _raton_activo else color_inactivo
		var font_size: int = 12
		draw_string(fuente, Vector2(44, 4), "Orientar", HORIZONTAL_ALIGNMENT_LEFT, 60, font_size, col_texto)


func _dibujar_paso_2() -> void:
	var texto_accion: String = "Plancha (Dive)" if _en_el_aire else "Saltar"
	var ancho: float = 180.0 if _en_el_aire else 150.0
	var alto: float = 34.0
	_dibujar_pastilla_fondo(ancho, alto)

	var tam_badge = Vector2(64, 20)
	var x_badge: float = -ancho * 0.5 + 40.0
	_dibujar_badge_tecla(Vector2(x_badge, 0), tam_badge, "Espacio", _tecla_espacio_activa or _dive_realizado)

	if fuente != null:
		var col_texto: Color = color_acento_dorado if _dive_realizado else (color_activo if _tecla_espacio_activa else color_inactivo)
		var font_size: int = 12
		draw_string(fuente, Vector2(x_badge + 40.0, 4), texto_accion, HORIZONTAL_ALIGNMENT_LEFT, 90, font_size, col_texto)


func _dibujar_paso_3() -> void:
	var ancho: float = 140.0
	var alto: float = 34.0
	_dibujar_pastilla_fondo(ancho, alto)

	var tam_badge = Vector2(50, 20)
	var x_badge: float = -ancho * 0.5 + 34.0
	_dibujar_badge_tecla(Vector2(x_badge, 0), tam_badge, "Shift", _tecla_shift_activa)

	if fuente != null:
		var col_texto: Color = color_activo if _tecla_shift_activa else color_inactivo
		var font_size: int = 12
		draw_string(fuente, Vector2(x_badge + 34.0, 4), "Correr", HORIZONTAL_ALIGNMENT_LEFT, 60, font_size, col_texto)
