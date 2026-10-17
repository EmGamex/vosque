class_name DebugPhysicsController
extends RefCounted

## Controlador de calibración de físicas, sliders y escalado proporcional.

var fisicas_desplegadas: bool = false
var vel_normal_defecto: float = 800.0
var vel_sprint_defecto: float = 1000.0
var acel_defecto: float = 5000.0
var fric_defecto: float = 5000.0
var dive_vel_defecto: float = 1200.0

var escalado_proporcional_activo: bool = true
var actualizando_sliders_en_cadena: bool = false
var valores_defecto_inicializados: bool = false


func toggle_desplegar(btn: Button, panel: PanelContainer) -> void:
	fisicas_desplegadas = not fisicas_desplegadas
	if panel != null:
		panel.visible = fisicas_desplegadas
	if btn != null:
		btn.text = "▼ Ajustes de Velocidad y Físicas (Ocultar)" if fisicas_desplegadas else "▶ Ajustes de Velocidad y Físicas (Desplegar)"


func set_proporcional(activo: bool, cfg: Node) -> void:
	escalado_proporcional_activo = activo
	if cfg != null:
		cfg.escalado_proporcional_activo = activo


func inicializar_valores(target: CharacterBody2D, cfg: Node, ui: Dictionary) -> void:
	if target == null or valores_defecto_inicializados:
		return

	if cfg != null and cfg.fisicas_personalizadas:
		if "speed" in target: target.set("speed", cfg.vel_normal)
		if "sprint_speed" in target: target.set("sprint_speed", cfg.vel_sprint)
		if "acceleration" in target: target.set("acceleration", cfg.acel)
		if "friction" in target: target.set("friction", cfg.fric)
		if "dive_speed" in target: target.set("dive_speed", cfg.dive_vel)

		_asignar_slider(ui.get("slider_vel_normal"), cfg.vel_normal)
		_asignar_label(ui.get("val_slider_vel_normal"), "%.0f px/s" % cfg.vel_normal)

		_asignar_slider(ui.get("slider_vel_sprint"), cfg.vel_sprint)
		_asignar_label(ui.get("val_slider_vel_sprint"), "%.0f px/s" % cfg.vel_sprint)

		_asignar_slider(ui.get("slider_acel"), cfg.acel)
		_asignar_label(ui.get("val_slider_acel"), "%.0f px/s²" % cfg.acel)

		_asignar_slider(ui.get("slider_fric"), cfg.fric)
		_asignar_label(ui.get("val_slider_fric"), "%.0f px/s²" % cfg.fric)

		_asignar_slider(ui.get("slider_dive_vel"), cfg.dive_vel)
		_asignar_label(ui.get("val_slider_dive_vel"), "%.0f px/s" % cfg.dive_vel)
	else:
		if "speed" in target:
			vel_normal_defecto = float(target.get("speed"))
			_asignar_slider(ui.get("slider_vel_normal"), vel_normal_defecto)
			_asignar_label(ui.get("val_slider_vel_normal"), "%.0f px/s" % vel_normal_defecto)

		if "sprint_speed" in target:
			vel_sprint_defecto = float(target.get("sprint_speed"))
			_asignar_slider(ui.get("slider_vel_sprint"), vel_sprint_defecto)
			_asignar_label(ui.get("val_slider_vel_sprint"), "%.0f px/s" % vel_sprint_defecto)

		if "acceleration" in target:
			acel_defecto = float(target.get("acceleration"))
			_asignar_slider(ui.get("slider_acel"), acel_defecto)
			_asignar_label(ui.get("val_slider_acel"), "%.0f px/s²" % acel_defecto)

		if "friction" in target:
			fric_defecto = float(target.get("friction"))
			_asignar_slider(ui.get("slider_fric"), fric_defecto)
			_asignar_label(ui.get("val_slider_fric"), "%.0f px/s²" % fric_defecto)

		if "dive_speed" in target:
			dive_vel_defecto = float(target.get("dive_speed"))
			_asignar_slider(ui.get("slider_dive_vel"), dive_vel_defecto)
			_asignar_label(ui.get("val_slider_dive_vel"), "%.0f px/s" % dive_vel_defecto)

	var check_prop: CheckBox = ui.get("check_proporcional")
	if check_prop != null:
		check_prop.button_pressed = escalado_proporcional_activo

	valores_defecto_inicializados = true


func on_vel_normal_changed(value: float, target: CharacterBody2D, cfg: Node, ui: Dictionary) -> void:
	_asignar_label(ui.get("val_slider_vel_normal"), "%.0f px/s" % value)
	if target != null and "speed" in target:
		target.set("speed", value)

	if escalado_proporcional_activo and not actualizando_sliders_en_cadena and vel_normal_defecto > 0.0:
		actualizando_sliders_en_cadena = true
		var ratio: float = value / vel_normal_defecto

		var nuevo_sprint: float = clampf(vel_sprint_defecto * ratio, 50.0, 4000.0)
		var slider_sprint: HSlider = ui.get("slider_vel_sprint")
		if slider_sprint != null:
			slider_sprint.value = nuevo_sprint
		elif target != null and "sprint_speed" in target:
			target.set("sprint_speed", nuevo_sprint)

		var nueva_acel: float = clampf(acel_defecto * ratio, 100.0, 20000.0)
		var slider_acel: HSlider = ui.get("slider_acel")
		if slider_acel != null:
			slider_acel.value = nueva_acel
		elif target != null and "acceleration" in target:
			target.set("acceleration", nueva_acel)

		var nueva_fric: float = clampf(fric_defecto * ratio, 100.0, 20000.0)
		var slider_fric: HSlider = ui.get("slider_fric")
		if slider_fric != null:
			slider_fric.value = nueva_fric
		elif target != null and "friction" in target:
			target.set("friction", nueva_fric)

		var nuevo_dive: float = clampf(dive_vel_defecto * ratio, 100.0, 4000.0)
		var slider_dive: HSlider = ui.get("slider_dive_vel")
		if slider_dive != null:
			slider_dive.value = nuevo_dive
		elif target != null and "dive_speed" in target:
			target.set("dive_speed", nuevo_dive)

		actualizando_sliders_en_cadena = false

	if not actualizando_sliders_en_cadena:
		guardar_en_config(cfg, ui)


func on_vel_sprint_changed(value: float, target: CharacterBody2D, cfg: Node, ui: Dictionary) -> void:
	_asignar_label(ui.get("val_slider_vel_sprint"), "%.0f px/s" % value)
	if target != null and "sprint_speed" in target:
		target.set("sprint_speed", value)
	if not actualizando_sliders_en_cadena:
		guardar_en_config(cfg, ui)


func on_acel_changed(value: float, target: CharacterBody2D, cfg: Node, ui: Dictionary) -> void:
	_asignar_label(ui.get("val_slider_acel"), "%.0f px/s²" % value)
	if target != null and "acceleration" in target:
		target.set("acceleration", value)
	if not actualizando_sliders_en_cadena:
		guardar_en_config(cfg, ui)


func on_fric_changed(value: float, target: CharacterBody2D, cfg: Node, ui: Dictionary) -> void:
	_asignar_label(ui.get("val_slider_fric"), "%.0f px/s²" % value)
	if target != null and "friction" in target:
		target.set("friction", value)
	if not actualizando_sliders_en_cadena:
		guardar_en_config(cfg, ui)


func on_dive_vel_changed(value: float, target: CharacterBody2D, cfg: Node, ui: Dictionary) -> void:
	_asignar_label(ui.get("val_slider_dive_vel"), "%.0f px/s" % value)
	if target != null and "dive_speed" in target:
		target.set("dive_speed", value)
	if not actualizando_sliders_en_cadena:
		guardar_en_config(cfg, ui)


func reset_velocidades(target: CharacterBody2D, cfg: Node, ui: Dictionary) -> void:
	actualizando_sliders_en_cadena = true
	var s_norm: HSlider = ui.get("slider_vel_normal")
	var s_spr: HSlider = ui.get("slider_vel_sprint")
	var s_ac: HSlider = ui.get("slider_acel")
	var s_fr: HSlider = ui.get("slider_fric")
	var s_dv: HSlider = ui.get("slider_dive_vel")

	if s_norm != null: s_norm.value = vel_normal_defecto
	if s_spr != null: s_spr.value = vel_sprint_defecto
	if s_ac != null: s_ac.value = acel_defecto
	if s_fr != null: s_fr.value = fric_defecto
	if s_dv != null: s_dv.value = dive_vel_defecto

	if target != null:
		if "speed" in target: target.set("speed", vel_normal_defecto)
		if "sprint_speed" in target: target.set("sprint_speed", vel_sprint_defecto)
		if "acceleration" in target: target.set("acceleration", acel_defecto)
		if "friction" in target: target.set("friction", fric_defecto)
		if "dive_speed" in target: target.set("dive_speed", dive_vel_defecto)

	actualizando_sliders_en_cadena = false

	if cfg != null:
		cfg.resetear_velocidades(vel_normal_defecto, vel_sprint_defecto, acel_defecto, fric_defecto, dive_vel_defecto)


func guardar_en_config(cfg: Node, ui: Dictionary) -> void:
	if cfg == null:
		return
	var s_norm: HSlider = ui.get("slider_vel_normal")
	var s_spr: HSlider = ui.get("slider_vel_sprint")
	var s_ac: HSlider = ui.get("slider_acel")
	var s_fr: HSlider = ui.get("slider_fric")
	var s_dv: HSlider = ui.get("slider_dive_vel")

	cfg.fisicas_personalizadas = true
	cfg.vel_normal = s_norm.value if s_norm != null else vel_normal_defecto
	cfg.vel_sprint = s_spr.value if s_spr != null else vel_sprint_defecto
	cfg.acel = s_ac.value if s_ac != null else acel_defecto
	cfg.fric = s_fr.value if s_fr != null else fric_defecto
	cfg.dive_vel = s_dv.value if s_dv != null else dive_vel_defecto


func _asignar_slider(slider: HSlider, val: float) -> void:
	if slider != null:
		slider.set_value_no_signal(val)


func _asignar_label(label: Label, txt: String) -> void:
	if label != null:
		label.text = txt
