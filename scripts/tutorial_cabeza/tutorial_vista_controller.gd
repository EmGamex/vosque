@tool
class_name TutorialVistaController
extends RefCounted

## Sub-controlador visual, de estilos y animaciones del TutorialCabeza.
## Gestiona StyleBoxes cacheados en memoria (cero asignaciones por frame),
## visibilidad de contenedores, dibujo de glifo de ratón y Tweens de feedback.

const Paso = TutorialEstadoController.Paso

# Referencias de nodos de UI
var nodo_raiz: Node2D
var contenedor: PanelContainer
var paso1_movimiento: HBoxContainer
var paso2_salto: HBoxContainer
var paso3_plancha_dive: HBoxContainer
var paso4_sprint: HBoxContainer

var badge_w: PanelContainer
var badge_a: PanelContainer
var badge_s: PanelContainer
var badge_d: PanelContainer

var icono_raton: Control
var label_orientar: Label

var badge_espacio: PanelContainer
var label_accion_salto: Label

var badge_espacio_dive: PanelContainer
var label_accion_dive: Label

var badge_shift: PanelContainer
var label_accion_sprint: Label

# Colores configurables
var color_fondo: Color = Color(0.12, 0.12, 0.13, 0.88)
var color_activo: Color = Color(0.70, 0.70, 0.72)
var color_inactivo: Color = Color(0.85, 0.85, 0.85, 0.90)
var color_acento_dorado: Color = Color(0.85, 0.85, 0.85)

# StyleBoxes cacheados (sin asignaciones por frame)
var sb_fondo: StyleBoxFlat
var sb_badge_inactivo: StyleBoxFlat
var sb_badge_activo: StyleBoxFlat
var sb_badge_dive: StyleBoxFlat
var sb_raton: StyleBoxFlat

# Animación y Tweens
var tween_cierre: Tween
var tween_pop: Tween
var flash_unisono: bool = false
var color_flash: Color = Color.WHITE


func inicializar(raiz: Node2D) -> void:
	nodo_raiz = raiz
	_resolver_nodos()
	_crear_estilos_cacheados()
	_aplicar_estilos_base()
	centrar_contenedor()

	if icono_raton != null and not icono_raton.draw.is_connected(dibujar_icono_raton):
		icono_raton.draw.connect(dibujar_icono_raton)


func limpiar() -> void:
	if tween_cierre != null and tween_cierre.is_valid():
		tween_cierre.kill()
	if tween_pop != null and tween_pop.is_valid():
		tween_pop.kill()


func _resolver_nodos() -> void:
	if nodo_raiz == null:
		return
	contenedor = nodo_raiz.get_node_or_null("Contenedor") as PanelContainer
	paso1_movimiento = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento") as HBoxContainer
	
	# Soporta compatibilidad con nombres nuevos y previos durante la transición
	paso2_salto = (nodo_raiz.get_node_or_null("Contenedor/Paso2_Salto")
		if nodo_raiz.has_node("Contenedor/Paso2_Salto")
		else nodo_raiz.get_node_or_null("Contenedor/Paso2_SaltoDive")) as HBoxContainer
	
	paso3_plancha_dive = nodo_raiz.get_node_or_null("Contenedor/Paso3_PlanchaDive") as HBoxContainer
	
	paso4_sprint = (nodo_raiz.get_node_or_null("Contenedor/Paso4_Sprint")
		if nodo_raiz.has_node("Contenedor/Paso4_Sprint")
		else nodo_raiz.get_node_or_null("Contenedor/Paso3_Sprint")) as HBoxContainer

	badge_w = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeW") as PanelContainer
	badge_a = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeA") as PanelContainer
	badge_s = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeS") as PanelContainer
	badge_d = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeD") as PanelContainer

	icono_raton = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorRaton/IconoRaton") as Control
	label_orientar = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorRaton/LabelOrientar") as Label

	if paso2_salto != null:
		badge_espacio = paso2_salto.get_node_or_null("BadgeEspacio") as PanelContainer
		label_accion_salto = paso2_salto.get_node_or_null("LabelAccionSalto") as Label

	if paso3_plancha_dive != null:
		badge_espacio_dive = paso3_plancha_dive.get_node_or_null("BadgeEspacioDive") as PanelContainer
		label_accion_dive = paso3_plancha_dive.get_node_or_null("LabelAccionDive") as Label

	if paso4_sprint != null:
		badge_shift = paso4_sprint.get_node_or_null("BadgeShift") as PanelContainer
		label_accion_sprint = paso4_sprint.get_node_or_null("LabelAccionSprint") as Label


func _crear_estilos_cacheados() -> void:
	sb_fondo = StyleBoxFlat.new()
	sb_fondo.bg_color = color_fondo
	sb_fondo.border_color = Color.TRANSPARENT
	sb_fondo.set_border_width_all(0)
	sb_fondo.set_corner_radius_all(0)
	sb_fondo.content_margin_left = 8
	sb_fondo.content_margin_right = 8
	sb_fondo.content_margin_top = 4
	sb_fondo.content_margin_bottom = 4

	sb_badge_inactivo = StyleBoxFlat.new()
	sb_badge_inactivo.bg_color = Color(0.20, 0.20, 0.22, 0.90)
	sb_badge_inactivo.border_color = Color.TRANSPARENT
	sb_badge_inactivo.set_border_width_all(0)
	sb_badge_inactivo.set_corner_radius_all(0)
	sb_badge_inactivo.content_margin_left = 6
	sb_badge_inactivo.content_margin_right = 6
	sb_badge_inactivo.content_margin_top = 2
	sb_badge_inactivo.content_margin_bottom = 2

	sb_badge_activo = StyleBoxFlat.new()
	sb_badge_activo.bg_color = Color(0.38, 0.38, 0.40, 0.95)
	sb_badge_activo.border_color = Color.TRANSPARENT
	sb_badge_activo.set_border_width_all(0)
	sb_badge_activo.set_corner_radius_all(0)
	sb_badge_activo.content_margin_left = 6
	sb_badge_activo.content_margin_right = 6
	sb_badge_activo.content_margin_top = 2
	sb_badge_activo.content_margin_bottom = 2

	sb_badge_dive = StyleBoxFlat.new()
	sb_badge_dive.bg_color = Color(0.48, 0.48, 0.50, 0.95)
	sb_badge_dive.border_color = Color.TRANSPARENT
	sb_badge_dive.set_border_width_all(0)
	sb_badge_dive.set_corner_radius_all(0)
	sb_badge_dive.content_margin_left = 6
	sb_badge_dive.content_margin_right = 6
	sb_badge_dive.content_margin_top = 2
	sb_badge_dive.content_margin_bottom = 2

	sb_raton = StyleBoxFlat.new()
	sb_raton.bg_color = Color(0.20, 0.20, 0.22, 0.90)
	sb_raton.border_color = Color.TRANSPARENT
	sb_raton.set_border_width_all(0)
	sb_raton.set_corner_radius_all(0)


func _aplicar_estilos_base() -> void:
	if contenedor != null and sb_fondo != null:
		contenedor.add_theme_stylebox_override("panel", sb_fondo)
	var badges = [badge_w, badge_a, badge_s, badge_d, badge_espacio, badge_espacio_dive, badge_shift]
	for b in badges:
		if b != null and sb_badge_inactivo != null:
			b.add_theme_stylebox_override("panel", sb_badge_inactivo)


func centrar_contenedor() -> void:
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


func actualizar_visibilidad_pasos(paso_actual: Paso) -> void:
	if paso1_movimiento != null:
		paso1_movimiento.visible = (paso_actual == Paso.PASO_1_MOVIMIENTO)
	if paso2_salto != null:
		paso2_salto.visible = (paso_actual == Paso.PASO_2_SALTO)
	if paso3_plancha_dive != null:
		paso3_plancha_dive.visible = (paso_actual == Paso.PASO_3_PLANCHA_DIVE)
	if paso4_sprint != null:
		paso4_sprint.visible = (paso_actual == Paso.PASO_4_SPRINT)

	if contenedor != null:
		nodo_raiz.call_deferred("_centrar_contenedor_deferred")


func actualizar_estilos_reactivos(estado: TutorialEstadoController) -> void:
	if estado.cerrando and flash_unisono:
		_aplicar_estilo_badge(badge_w, true, true)
		_aplicar_estilo_badge(badge_a, true, true)
		_aplicar_estilo_badge(badge_s, true, true)
		_aplicar_estilo_badge(badge_d, true, true)
		_aplicar_estilo_badge(badge_espacio, true, true)
		_aplicar_estilo_badge(badge_espacio_dive, true, true)
		_aplicar_estilo_badge(badge_shift, true, true)
		return

	match estado.paso_actual:
		Paso.PASO_1_MOVIMIENTO:
			_aplicar_estilo_badge(badge_w, estado.w_registrado or estado.tecla_w_activa)
			_aplicar_estilo_badge(badge_a, estado.a_registrado or estado.tecla_a_activa)
			_aplicar_estilo_badge(badge_s, estado.s_registrado or estado.tecla_s_activa)
			_aplicar_estilo_badge(badge_d, estado.d_registrado or estado.tecla_d_activa)
			actualizar_estilo_raton(estado)
		Paso.PASO_2_SALTO:
			_aplicar_estilo_badge(badge_espacio, estado.salto_registrado or estado.tecla_espacio_activa)
		Paso.PASO_3_PLANCHA_DIVE:
			if estado.dive_registrado:
				_aplicar_estilo_badge(badge_espacio_dive, true, false, true)
			else:
				_aplicar_estilo_badge(badge_espacio_dive, estado.en_el_aire or estado.tecla_espacio_activa)
		Paso.PASO_4_SPRINT:
			_aplicar_estilo_badge(badge_shift, estado.sprint_registrado or estado.tecla_shift_activa)


func _aplicar_estilo_badge(badge: PanelContainer, activo: bool, es_flash: bool = false, es_dive: bool = false) -> void:
	if badge == null:
		return
	var sb: StyleBoxFlat = sb_badge_inactivo
	if es_dive:
		sb = sb_badge_dive
	elif activo or es_flash:
		sb = sb_badge_activo
	badge.add_theme_stylebox_override("panel", sb)


func actualizar_estilo_raton(estado: TutorialEstadoController) -> void:
	if icono_raton != null:
		icono_raton.queue_redraw()
	if label_orientar != null:
		var iluminado = estado.raton_registrado or estado.raton_activo
		label_orientar.add_theme_color_override("font_color", color_activo if iluminado else color_inactivo)


func dibujar_icono_raton() -> void:
	if icono_raton == null:
		return

	var pos = icono_raton.size * 0.5
	var estado_ctrl = nodo_raiz.get("estado_ctrl") as TutorialEstadoController
	var iluminado: bool = flash_unisono
	if estado_ctrl != null:
		iluminado = iluminado or estado_ctrl.raton_registrado or estado_ctrl.raton_activo
	var col: Color = Color(0.9, 0.9, 0.9) if iluminado else Color(0.60, 0.60, 0.60, 0.85)

	# Silueta limpia y sobria del ratón
	var r_cuerpo = Rect2(pos.x - 5, pos.y - 7, 10, 14)
	if sb_raton != null:
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
	icono_raton.draw_line(Vector2(pos.x + dist, pos.y), Vector2(pos.x + dist + tam, pos.y + tam), col, 1.0)


func animar_pop_transicion() -> void:
	if not nodo_raiz.is_inside_tree():
		return
	if tween_pop != null and tween_pop.is_valid():
		tween_pop.kill()
	tween_pop = nodo_raiz.create_tween()
	tween_pop.tween_property(nodo_raiz, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_pop.tween_property(nodo_raiz, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func animar_pulso_dive(callback_completado: Callable) -> void:
	color_flash = color_acento_dorado
	flash_unisono = true
	if nodo_raiz.is_inside_tree():
		if tween_pop != null and tween_pop.is_valid():
			tween_pop.kill()
		tween_pop = nodo_raiz.create_tween()
		tween_pop.tween_property(nodo_raiz, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_pop.tween_property(nodo_raiz, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween_pop.tween_interval(0.15)
		tween_pop.tween_callback(func():
			flash_unisono = false
			color_flash = Color.WHITE
			if callback_completado.is_valid():
				callback_completado.call()
		)


func animar_fast_path(callback_fin: Callable) -> void:
	flash_unisono = true
	color_flash = color_activo
	if tween_cierre != null and tween_cierre.is_valid():
		tween_cierre.kill()
	if nodo_raiz.is_inside_tree():
		tween_cierre = nodo_raiz.create_tween().set_parallel(true)
		tween_cierre.tween_property(nodo_raiz, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_cierre.tween_property(nodo_raiz, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_cierre.chain().tween_callback(callback_fin)
	else:
		callback_fin.call()


func animar_cierre_estandar(callback_fin: Callable) -> void:
	if tween_cierre != null and tween_cierre.is_valid():
		tween_cierre.kill()
	if nodo_raiz.is_inside_tree():
		tween_cierre = nodo_raiz.create_tween()
		tween_cierre.tween_property(nodo_raiz, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween_cierre.tween_property(nodo_raiz, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween_cierre.tween_property(nodo_raiz, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween_cierre.tween_callback(callback_fin)
	else:
		callback_fin.call()


func animar_cierre_forzado(callback_fin: Callable) -> void:
	if tween_cierre != null and tween_cierre.is_valid():
		tween_cierre.kill()
	if nodo_raiz.is_inside_tree():
		tween_cierre = nodo_raiz.create_tween()
		tween_cierre.tween_property(nodo_raiz, "modulate:a", 0.0, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween_cierre.tween_callback(callback_fin)
	else:
		callback_fin.call()
