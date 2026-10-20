class_name DebugScenarioController
extends RefCounted

## Controlador de cámara cenital (God View), mutaciones de escenario y capas vectoriales de dibujo.

const ZOOM_GOD_VIEW := Vector2(0.225, 0.225)

var god_view_activo: bool = false
var debug_dibujar_cuadrantes: bool = false
var debug_dibujar_corredores: bool = false


func restaurar_desde_config(cfg: Node, check_god_view: CheckBox, check_corr: CheckBox, check_cuad: CheckBox) -> void:
	if cfg == null:
		return
	god_view_activo = cfg.god_view_activo
	debug_dibujar_cuadrantes = cfg.debug_dibujar_cuadrantes
	debug_dibujar_corredores = cfg.debug_dibujar_corredores

	if check_god_view != null:
		check_god_view.set_pressed_no_signal(god_view_activo)
	if check_corr != null:
		check_corr.set_pressed_no_signal(debug_dibujar_corredores)
	if check_cuad != null:
		check_cuad.set_pressed_no_signal(debug_dibujar_cuadrantes)


func inicializar_camaras(context: DebugContext) -> void:
	if god_view_activo:
		if context.target_camara_dios != null:
			context.target_camara_dios.enabled = true
			context.target_camara_dios.make_current()
			if context.target_camara != null:
				context.target_camara.enabled = false
		elif context.target_camara != null:
			context.target_camara.zoom = ZOOM_GOD_VIEW
			context.target_camara.position_smoothing_enabled = false
			context.target_camara.global_position = Vector2.ZERO
	else:
		if context.target_camara_dios != null:
			context.target_camara_dios.enabled = false
		if context.target_camara != null:
			context.target_camara.enabled = true
			context.target_camara.make_current()


func set_god_view(activo: bool, context: DebugContext, cfg: Node) -> void:
	god_view_activo = activo
	if cfg != null:
		cfg.god_view_activo = activo

	# Prioridad 1: Configuración de dos cámaras dedicadas
	if context.target_camara_dios != null:
		if activo:
			context.target_camara_dios.enabled = true
			context.target_camara_dios.make_current()
			if context.target_camara != null:
				context.target_camara.enabled = false
		else:
			if context.target_camara != null:
				context.target_camara.enabled = true
				context.target_camara.make_current()
				context.target_camara.reset_smoothing()
			context.target_camara_dios.enabled = false
		return

	# Prioridad 2: Fallback mono-cámara seguro
	if context.target_camara == null:
		return

	if activo:
		context.target_camara.zoom = ZOOM_GOD_VIEW
		context.target_camara.position_smoothing_enabled = false
		context.target_camara.global_position = Vector2.ZERO
	else:
		context.target_camara.zoom = context.camara_zoom_original
		context.target_camara.position_smoothing_enabled = true
		if context.target_character != null:
			context.target_camara.global_position = context.target_character.global_position
		context.target_camara.reset_smoothing()


func set_dibujar_corredores(activo: bool, cfg: Node) -> void:
	debug_dibujar_corredores = activo
	if cfg != null:
		cfg.debug_dibujar_corredores = activo


func set_dibujar_cuadrantes(activo: bool, cfg: Node) -> void:
	debug_dibujar_cuadrantes = activo
	if cfg != null:
		cfg.debug_dibujar_cuadrantes = activo


func forzar_mutacion(escenario: Node2D) -> void:
	if escenario != null and escenario.has_method("mutar_con_neblina"):
		escenario.call("mutar_con_neblina")
	elif escenario != null and escenario.has_method("mutar_sectores_lejanos"):
		escenario.call("mutar_sectores_lejanos")
	elif escenario != null and escenario.has_method("forzar_mutacion"):
		escenario.call("forzar_mutacion")
	else:
		print("[DebugMenu] Forzar mutación invocado (Escenario aún no conectado o método ausente)")
