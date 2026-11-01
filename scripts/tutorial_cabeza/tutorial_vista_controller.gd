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

var badge_raton: PanelContainer
var icono_raton: TextureRect
var label_orientar: Label

var badge_espacio: PanelContainer
var label_accion_salto: Label

var badge_espacio_dive: PanelContainer
var label_accion_dive: Label

var badge_shift: PanelContainer
var label_accion_sprint: Label

# Colores configurables
var color_activo: Color = Color(0.70, 0.70, 0.72)
var color_inactivo: Color = Color(0.85, 0.85, 0.85, 0.90)

# Recursos StyleBox nativos
var sb_fondo: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_tutorial_fondo.tres")
var sb_badge_inactivo: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_badge_inactivo.tres")
var sb_badge_activo: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_badge_activo.tres")
var sb_badge_dive: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_badge_dive.tres")

# Animación y Tweens
var tween_cierre: Tween
var tween_pop: Tween
var flash_unisono: bool = false
var _raton_iluminado: bool = false


func inicializar(raiz: Node2D) -> void:
	nodo_raiz = raiz
	_resolver_nodos()
	_aplicar_estilos_base()
	centrar_contenedor()


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
	paso2_salto = nodo_raiz.get_node_or_null("Contenedor/Paso2_Salto") as HBoxContainer
	paso3_plancha_dive = nodo_raiz.get_node_or_null("Contenedor/Paso3_PlanchaDive") as HBoxContainer
	paso4_sprint = nodo_raiz.get_node_or_null("Contenedor/Paso4_Sprint") as HBoxContainer

	badge_w = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeW") as PanelContainer
	badge_a = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeA") as PanelContainer
	badge_s = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeS") as PanelContainer
	badge_d = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorWASD/BadgeD") as PanelContainer

	badge_raton = nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorRaton/BadgeRaton") as PanelContainer
	icono_raton = (nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorRaton/BadgeRaton/IconoRaton")
		if nodo_raiz.has_node("Contenedor/Paso1_Movimiento/ContenedorRaton/BadgeRaton/IconoRaton")
		else nodo_raiz.get_node_or_null("Contenedor/Paso1_Movimiento/ContenedorRaton/IconoRaton")) as TextureRect
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


func _aplicar_estilos_base() -> void:
	if contenedor != null and sb_fondo != null:
		contenedor.add_theme_stylebox_override("panel", sb_fondo)
	var badges = [badge_w, badge_a, badge_s, badge_d, badge_raton, badge_espacio, badge_espacio_dive, badge_shift]
	for b in badges:
		if b != null and sb_badge_inactivo != null:
			b.add_theme_stylebox_override("panel", sb_badge_inactivo)
	if icono_raton != null:
		icono_raton.modulate = Color.WHITE


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
		centrar_contenedor.call_deferred()


func actualizar_estilos_reactivos(estado: TutorialEstadoController) -> void:
	if estado.cerrando and flash_unisono:
		_aplicar_estilo_badge(badge_w, true, true)
		_aplicar_estilo_badge(badge_a, true, true)
		_aplicar_estilo_badge(badge_s, true, true)
		_aplicar_estilo_badge(badge_d, true, true)
		_aplicar_estilo_badge(badge_raton, true, true)
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
	_raton_iluminado = estado.raton_registrado or estado.raton_activo
	var activo: bool = flash_unisono or _raton_iluminado
	if badge_raton != null:
		_aplicar_estilo_badge(badge_raton, activo, flash_unisono)
	if icono_raton != null:
		icono_raton.modulate = Color.WHITE
	if label_orientar != null:
		label_orientar.add_theme_color_override("font_color", color_activo if activo else color_inactivo)


func animar_pop_transicion() -> void:
	if not nodo_raiz.is_inside_tree():
		return
	if tween_pop != null and tween_pop.is_valid():
		tween_pop.kill()
	tween_pop = nodo_raiz.create_tween()
	tween_pop.tween_property(nodo_raiz, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_pop.tween_property(nodo_raiz, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func animar_pulso_dive(callback_completado: Callable) -> void:
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
			if callback_completado.is_valid():
				callback_completado.call()
		)


func animar_fast_path(callback_fin: Callable) -> void:
	flash_unisono = true
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
