class_name DebugTelemetryPresenter
extends RefCounted

## Presentador y formateador de telemetría hacia los componentes visuales de la interfaz.

const COLOR_INACTIVO := Color(0.30, 0.34, 0.42, 0.7)
const COLOR_ACTIVO := Color(0.39, 0.71, 0.96, 1.0)
const COLOR_VERDE := Color(0.40, 0.85, 0.45, 1.0)
const COLOR_ROJO := Color(0.95, 0.35, 0.35, 1.0)


func actualizar_mini_hud(labels: Dictionary, fps: int, mem_mb: float, sector: String, vel: float, stamina_txt: String) -> void:
	var l_fps: Label = labels.get("label_mini_fps")
	var l_cuad: Label = labels.get("label_mini_cuadrante")
	var l_vel: Label = labels.get("label_mini_vel")
	var l_stm: Label = labels.get("label_mini_estamina")

	if l_fps != null: l_fps.text = "FPS: %d (%0.1f MB)" % [fps, mem_mb]
	if l_cuad != null: l_cuad.text = "Sector: %s" % sector
	if l_vel != null: l_vel.text = "Vel: %.1f px/s" % vel
	if l_stm != null: l_stm.text = "Estamina: %s" % stamina_txt


func actualizar_tab_jugador(labels: Dictionary, jugador: CharacterBody2D, context: DebugContext, vel_actual: float, vel_max: float, acel: float, fric: float, estado_txt: String, estamina_txt: String, pos_jugador: Vector2, cuadrante_jugador: String) -> void:
	var lbl_vel: Label = labels.get("lbl_vel")
	var lbl_vel_max: Label = labels.get("lbl_vel_max")
	var lbl_acel: Label = labels.get("lbl_acel")
	var lbl_fric: Label = labels.get("lbl_fric")
	var lbl_estado: Label = labels.get("lbl_estado")
	var lbl_estamina: Label = labels.get("lbl_estamina")
	var lbl_pos_jugador: Label = labels.get("lbl_pos_jugador")
	var lbl_cuadrante_jugador: Label = labels.get("lbl_cuadrante_jugador")

	if lbl_vel != null:
		lbl_vel.text = "%.1f px/s (X: %.1f, Y: %.1f)" % [vel_actual, jugador.velocity.x if jugador else 0.0, jugador.velocity.y if jugador else 0.0]
	if lbl_vel_max != null: lbl_vel_max.text = "%.1f px/s" % vel_max
	if lbl_acel != null: lbl_acel.text = "%.1f px/s²" % acel
	if lbl_fric != null: lbl_fric.text = "%.1f px/s²" % fric
	if lbl_estado != null: lbl_estado.text = estado_txt
	if lbl_estamina != null: lbl_estamina.text = estamina_txt
	if lbl_pos_jugador != null: lbl_pos_jugador.text = "(%.1f, %.1f)" % [pos_jugador.x, pos_jugador.y]
	if lbl_cuadrante_jugador != null:
		lbl_cuadrante_jugador.text = "%s (Centro: %s)" % [cuadrante_jugador, context.obtener_centro_cuadrante(cuadrante_jugador)]


func actualizar_pad_direccional(flechas: Dictionary, dir: Vector2) -> void:
	var f_up: Label = flechas.get("flecha_up")
	var f_down: Label = flechas.get("flecha_down")
	var f_left: Label = flechas.get("flecha_left")
	var f_right: Label = flechas.get("flecha_right")

	if f_up != null: f_up.modulate = COLOR_ACTIVO if dir.y < -0.2 else COLOR_INACTIVO
	if f_down != null: f_down.modulate = COLOR_ACTIVO if dir.y > 0.2 else COLOR_INACTIVO
	if f_left != null: f_left.modulate = COLOR_ACTIVO if dir.x < -0.2 else COLOR_INACTIVO
	if f_right != null: f_right.modulate = COLOR_ACTIVO if dir.x > 0.2 else COLOR_INACTIVO


func actualizar_tab_escenario(labels: Dictionary, escenario: Node2D, cuadrante_jugador: String) -> void:
	var lbl_estado: Label = labels.get("lbl_escenario_estado")
	var lbl_no: Label = labels.get("lbl_escenario_no")
	var lbl_ne: Label = labels.get("lbl_escenario_ne")
	var lbl_so: Label = labels.get("lbl_escenario_so")
	var lbl_se: Label = labels.get("lbl_escenario_se")

	if escenario != null:
		if lbl_estado != null: lbl_estado.text = "Escenario Activo: Cuadrante Jugador = %s" % cuadrante_jugador
		if "variantes_activas" in escenario:
			var vars: Dictionary = escenario.get("variantes_activas")
			if lbl_no != null: lbl_no.text = str(vars.get("NO", "Default"))
			if lbl_ne != null: lbl_ne.text = str(vars.get("NE", "Default"))
			if lbl_so != null: lbl_so.text = str(vars.get("SO", "Default"))
			if lbl_se != null: lbl_se.text = str(vars.get("SE", "Default"))
	else:
		if lbl_estado != null: lbl_estado.text = "Escenario: No instanciado (Modo Standalone)"
		if lbl_no != null: lbl_no.text = "Sector NO [-2160..0, -2160..0]"
		if lbl_ne != null: lbl_ne.text = "Sector NE [0..2160, -2160..0]"
		if lbl_so != null: lbl_so.text = "Sector SO [-2160..0, 0..2160]"
		if lbl_se != null: lbl_se.text = "Sector SE [0..2160, 0..2160]"


func actualizar_tab_enemigo(labels: Dictionary, enemigo: CharacterBody2D, pos_jugador: Vector2, context: DebugContext, debug_dibujar_vectores_ia: bool) -> void:
	var lbl_estado: Label = labels.get("lbl_enemigo_estado")
	var lbl_pos: Label = labels.get("lbl_enemigo_pos")
	var lbl_dist: Label = labels.get("lbl_enemigo_dist")
	var lbl_vel: Label = labels.get("lbl_enemigo_vel")
	var lbl_atascado: Label = labels.get("lbl_enemigo_atascado")

	if enemigo != null and is_instance_valid(enemigo):
		enemigo.set("debug_dibujar_rayo", debug_dibujar_vectores_ia)
		var pos_enemigo: Vector2 = enemigo.global_position
		var dist: float = pos_jugador.distance_to(pos_enemigo)
		var vel_enemigo: float = enemigo.velocity.length()

		if lbl_pos != null:
			lbl_pos.text = "(%.1f, %.1f) [%s]" % [pos_enemigo.x, pos_enemigo.y, context.calcular_cuadrante(pos_enemigo)]
		if lbl_dist != null: lbl_dist.text = "%.1f px" % dist
		if lbl_vel != null: lbl_vel.text = "%.1f px/s" % vel_enemigo

		var vision_txt := ""
		if "tiene_linea_vision" in enemigo:
			vision_txt = " (Visión directa)" if enemigo.get("tiene_linea_vision") else " (Obstruido)"

		if lbl_estado != null:
			lbl_estado.text = ("Persiguiendo objetivo" + vision_txt) if enemigo.get("objetivo") != null else "Sin objetivo"
		if lbl_atascado != null:
			lbl_atascado.text = "Colisión activa" if enemigo.is_on_wall() else "Libre / Transitable"
	else:
		if lbl_estado != null: lbl_estado.text = "No encontrado en escena"
		if lbl_pos != null: lbl_pos.text = "N/A"
		if lbl_dist != null: lbl_dist.text = "N/A"
		if lbl_vel != null: lbl_vel.text = "N/A"
		if lbl_atascado != null: lbl_atascado.text = "N/A"


func actualizar_tab_sistema(labels: Dictionary, fps: int, mem_mb: float) -> void:
	var lbl_fps: Label = labels.get("lbl_sys_fps")
	var lbl_mem: Label = labels.get("lbl_sys_mem")
	var lbl_ts: Label = labels.get("lbl_sys_timescale")

	if lbl_fps != null: lbl_fps.text = "%d FPS" % fps
	if lbl_mem != null: lbl_mem.text = "%.2f MB" % mem_mb
	if lbl_ts != null: lbl_ts.text = "%.2fx" % Engine.time_scale
