class_name DebugEnemyController
extends RefCounted

## Controlador de telemetría, visualización de IA y reubicación del enemigo.

var debug_dibujar_vectores_ia: bool = false


func restaurar_desde_config(cfg: Node, check_visual: CheckBox) -> void:
	if cfg == null:
		return
	debug_dibujar_vectores_ia = cfg.debug_dibujar_vectores_ia
	if check_visual != null:
		check_visual.set_pressed_no_signal(debug_dibujar_vectores_ia)


func set_visual_debug(activo: bool, enemigo: CharacterBody2D, cfg: Node) -> void:
	debug_dibujar_vectores_ia = activo
	if cfg != null:
		cfg.debug_dibujar_vectores_ia = activo
	if enemigo != null and is_instance_valid(enemigo):
		enemigo.set("debug_dibujar_rayo", activo)
		enemigo.queue_redraw()


func sincronizar_en_process(enemigo: CharacterBody2D) -> void:
	if enemigo != null and is_instance_valid(enemigo):
		if enemigo.get("debug_dibujar_rayo") != debug_dibujar_vectores_ia:
			enemigo.set("debug_dibujar_rayo", debug_dibujar_vectores_ia)


func reubicar_enemigo(enemigo: CharacterBody2D, jugador: CharacterBody2D) -> void:
	if enemigo == null or jugador == null:
		return
	var pos_p: Vector2 = jugador.global_position
	var nueva_pos: Vector2 = Vector2(-pos_p.x, -pos_p.y)
	if nueva_pos.length() < 300.0:
		nueva_pos = Vector2(600.0, 600.0)
	enemigo.global_position = nueva_pos
