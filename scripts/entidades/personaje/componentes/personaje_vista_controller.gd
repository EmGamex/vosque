class_name PersonajeVistaController
extends RefCounted

## Subcontrolador visual del personaje: eje Z simulado, inclinación procedural, animación 8D y feedback de notas.

var visual: Node2D = null
var sprite: AnimatedSprite2D = null
var sombra: Node2D = null
var indicador_estamina: Node2D = null
var tutorial_cabeza: Node2D = null

var _host: Node2D = null
var _tween_feedback_nota: Tween = null
var _fase_rebote: float = 0.0
var _offset_rebote_actual: float = 0.0


func inicializar(host: Node2D) -> void:
	_host = host
	visual = host.get_node_or_null("Visual") as Node2D
	sprite = host.get_node_or_null("Visual/Sprite2D") as AnimatedSprite2D
	sombra = host.get_node_or_null("Sombra") as Node2D
	indicador_estamina = host.get_node_or_null("IndicadorEstamina") as Node2D
	tutorial_cabeza = host.get_node_or_null("TutorialCabeza") as Node2D


func limpiar() -> void:
	if _tween_feedback_nota != null and _tween_feedback_nota.is_valid():
		_tween_feedback_nota.kill()
	_tween_feedback_nota = null


func aplicar_elevacion_eje_z(
	jump_height: float,
	factor_altura: float,
	shadow_min_scale: Vector2 = Vector2(0.6, 0.6)
) -> void:
	if visual != null:
		visual.position.y = -jump_height * factor_altura
	if sombra != null:
		sombra.scale = Vector2.ONE.lerp(shadow_min_scale, factor_altura)
	if indicador_estamina != null and is_instance_valid(indicador_estamina):
		indicador_estamina.position.y = -60.0 - jump_height * factor_altura
	if tutorial_cabeza != null and is_instance_valid(tutorial_cabeza):
		tutorial_cabeza.position.y = -90.0 - jump_height * factor_altura


func restaurar_visuales_eje_z() -> void:
	resetear_rebote_carrera()
	if visual != null:
		visual.position = Vector2.ZERO
		visual.rotation = 0.0
	if sombra != null:
		sombra.scale = Vector2.ONE
	if indicador_estamina != null and is_instance_valid(indicador_estamina):
		indicador_estamina.position = Vector2(0, -60)
	if tutorial_cabeza != null and is_instance_valid(tutorial_cabeza):
		tutorial_cabeza.position = Vector2(0, -90)


func resetear_rebote_carrera() -> void:
	_fase_rebote = 0.0
	_offset_rebote_actual = 0.0


func actualizar_procedural_suelo(
	en_sprint: bool,
	direction: Vector2,
	delta: float = 0.0,
	estado_actual: Personaje.Estado = Personaje.Estado.REPOSO,
	velocidad_actual: float = 0.0,
	stop_threshold: float = 15.0,
	velocidad_referencia: float = 800.0,
	intervalo_paso_base: float = 0.32,
	rebote_habilitado: bool = true,
	altura_rebote_caminar: float = 4.0,
	altura_rebote_sprint: float = 6.5,
	escala_sombra_rebote: float = 0.94,
	velocidad_retorno_rebote: float = 18.0
) -> void:
	if visual == null:
		return

	var en_movimiento_suelo: bool = (
		estado_actual == Personaje.Estado.CAMINANDO
		or estado_actual == Personaje.Estado.SPRINT
		or estado_actual == Personaje.Estado.FATIGA
	) and velocidad_actual > stop_threshold

	var amplitud_maxima: float = maxf(altura_rebote_caminar, altura_rebote_sprint)
	if rebote_habilitado and en_movimiento_suelo and delta > 0.0:
		var factor_vel: float = clampf(velocidad_actual / maxf(velocidad_referencia, 1.0), 0.5, 1.8)
		var intervalo_actual: float = maxf(intervalo_paso_base / factor_vel, 0.05)
		_fase_rebote = fmod(_fase_rebote + (PI / intervalo_actual) * delta, TAU)

		var amplitud_estado: float = altura_rebote_caminar
		if estado_actual == Personaje.Estado.SPRINT:
			amplitud_estado = altura_rebote_sprint
		elif estado_actual == Personaje.Estado.FATIGA:
			amplitud_estado = altura_rebote_caminar * 0.7

		var escala_arranque: float = clampf(velocidad_actual / maxf(velocidad_referencia, 1.0), 0.0, 1.0)
		_offset_rebote_actual = absf(sin(_fase_rebote)) * amplitud_estado * escala_arranque
	else:
		_offset_rebote_actual = lerpf(_offset_rebote_actual, 0.0, clampf(delta * velocidad_retorno_rebote, 0.0, 1.0))
		if _offset_rebote_actual <= 0.05 or delta <= 0.0:
			_offset_rebote_actual = 0.0
			_fase_rebote = 0.0

	visual.position = Vector2(0.0, -_offset_rebote_actual)
	if sombra != null:
		var factor_sombra: float = clampf(_offset_rebote_actual / maxf(amplitud_maxima, 0.01), 0.0, 1.0)
		sombra.scale = Vector2.ONE.lerp(Vector2(escala_sombra_rebote, escala_sombra_rebote), factor_sombra)

	if en_sprint and direction.x != 0.0:
		visual.rotation = deg_to_rad(5.0 * signf(direction.x))
	else:
		visual.rotation = 0.0


func actualizar_animacion(
	direction: Vector2,
	is_moving: bool,
	ultima_direccion: Vector2,
	estado_actual: Personaje.Estado,
	velocidad_actual: float = 0.0,
	velocidad_referencia: float = 800.0
) -> void:
	if sprite == null:
		return

	var dir: Vector2 = direction if is_moving else ultima_direccion
	if dir.x < -0.05:
		sprite.flip_h = true
	elif dir.x > 0.05:
		sprite.flip_h = false

	match estado_actual:
		Personaje.Estado.SALTO:
			sprite.speed_scale = 1.0
			reproducir_animacion_con_fallback(&"salto", [&"saltar", &"correr", &"idle"])
		Personaje.Estado.PLANCHA_AIRE, Personaje.Estado.RECUPERANDOSE:
			sprite.speed_scale = 1.0
			reproducir_animacion_con_fallback(&"plancha", [&"correr", &"idle"])
		Personaje.Estado.REPOSO:
			sprite.speed_scale = 1.0
			reproducir_animacion_con_fallback(&"idle", [&"correr"])
		_:
			if is_moving:
				var factor_vel: float = clampf(
					(velocidad_actual / maxf(velocidad_referencia, 1.0)) * 1.25,
					1.0,
					1.8
				)
				sprite.speed_scale = factor_vel
				reproducir_animacion_con_fallback(&"correr", [&"idle"])
			else:
				sprite.speed_scale = 1.0
				reproducir_animacion_con_fallback(&"idle", [&"correr"])


func reproducir_animacion_con_fallback(
	anim_principal: StringName,
	fallbacks: Array[StringName]
) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return

	var candidatas: Array[StringName] = [anim_principal]
	candidatas.append_array(fallbacks)

	for anim in candidatas:
		if sprite.sprite_frames.has_animation(anim):
			if sprite.sprite_frames.get_frame_count(anim) > 0:
				if sprite.animation != anim or not sprite.is_playing():
					sprite.play(anim)
				return


func ejecutar_feedback_visual_nota(tint: Color) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	limpiar()
	visual.modulate = tint
	if _host != null and _host.is_inside_tree():
		_tween_feedback_nota = _host.create_tween()
		_tween_feedback_nota.tween_property(visual, "scale", Vector2(1.12, 1.12), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_tween_feedback_nota.tween_property(visual, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func restaurar_feedback_nota() -> void:
	limpiar()
	if visual != null and is_instance_valid(visual):
		visual.modulate = Color.WHITE
		visual.scale = Vector2.ONE
