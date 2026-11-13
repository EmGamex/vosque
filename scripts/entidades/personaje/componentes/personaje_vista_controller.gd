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
	if visual != null:
		visual.position = Vector2.ZERO
		visual.rotation = 0.0
	if sombra != null:
		sombra.scale = Vector2.ONE
	if indicador_estamina != null and is_instance_valid(indicador_estamina):
		indicador_estamina.position = Vector2(0, -60)
	if tutorial_cabeza != null and is_instance_valid(tutorial_cabeza):
		tutorial_cabeza.position = Vector2(0, -90)


func actualizar_procedural_suelo(en_sprint: bool, direction: Vector2) -> void:
	if visual == null:
		return
	visual.position = Vector2.ZERO
	if en_sprint and direction.x != 0.0:
		visual.rotation = deg_to_rad(5.0 * signf(direction.x))
	else:
		visual.rotation = 0.0


func actualizar_animacion(
	direction: Vector2,
	is_moving: bool,
	ultima_direccion: Vector2,
	en_reposo: bool
) -> void:
	if sprite == null:
		return

	var dir: Vector2 = direction if is_moving else ultima_direccion
	if dir.x < -0.05:
		sprite.flip_h = true
	elif dir.x > 0.05:
		sprite.flip_h = false

	var abs_x: float = absf(dir.x)
	var abs_y: float = absf(dir.y)

	if not is_moving and en_reposo:
		if abs_x > abs_y:
			reproducir_animacion_con_fallback(&"idle-lado", [&"idle", &"lado", &"idle-arriba"])
		elif dir.y > 0.0:
			reproducir_animacion_con_fallback(&"idle-abajo", [&"idle", &"idle-arriba", &"arriba"])
		else:
			reproducir_animacion_con_fallback(&"idle-arriba", [&"idle", &"arriba"])
		return

	if abs_x > 0.3 and abs_y > 0.3:
		if dir.y > 0.0:
			reproducir_animacion_con_fallback(&"diagonal-abajo", [&"diagonal-arriba", &"diagonal", &"lado"])
		else:
			reproducir_animacion_con_fallback(&"diagonal-arriba", [&"diagonal", &"lado"])
	elif abs_y > abs_x:
		if dir.y > 0.0:
			reproducir_animacion_con_fallback(&"abajo", [&"idle-abajo", &"diagonal-abajo", &"lado"])
		else:
			reproducir_animacion_con_fallback(&"arriba", [&"idle-arriba", &"idle"])
	else:
		reproducir_animacion_con_fallback(&"lado", [&"idle-lado", &"diagonal-arriba"])


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
