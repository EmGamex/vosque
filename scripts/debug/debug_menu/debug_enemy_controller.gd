class_name DebugEnemyController
extends RefCounted

## Controlador de telemetría, visualización de IA y reubicación del enemigo.

var debug_dibujar_vectores_ia: bool = false
var ia_pausada: bool = false


func restaurar_desde_config(cfg: Node, check_visual: CheckBox, check_pausar_ia: CheckBox = null) -> void:
	if cfg == null:
		return
	debug_dibujar_vectores_ia = cfg.debug_dibujar_vectores_ia
	ia_pausada = cfg.debug_pausar_ia_enemigo
	if check_visual != null:
		check_visual.set_pressed_no_signal(debug_dibujar_vectores_ia)
	if check_pausar_ia != null:
		check_pausar_ia.set_pressed_no_signal(ia_pausada)


func set_visual_debug(activo: bool, enemigo: CharacterBody2D, cfg: Node) -> void:
	debug_dibujar_vectores_ia = activo
	if cfg != null:
		cfg.debug_dibujar_vectores_ia = activo
	if enemigo != null and is_instance_valid(enemigo):
		enemigo.set("debug_dibujar_rayo", activo)
		enemigo.queue_redraw()


func set_ia_pausada(activo: bool, enemigo: CharacterBody2D, cfg: Node) -> void:
	ia_pausada = activo
	if cfg != null:
		cfg.debug_pausar_ia_enemigo = activo
	if enemigo != null and is_instance_valid(enemigo):
		enemigo.set("ia_pausada", activo)
		if activo:
			enemigo.velocity = Vector2.ZERO


func sincronizar_en_process(enemigo: CharacterBody2D) -> void:
	if enemigo != null and is_instance_valid(enemigo):
		if enemigo.get("debug_dibujar_rayo") != debug_dibujar_vectores_ia:
			enemigo.set("debug_dibujar_rayo", debug_dibujar_vectores_ia)
		if enemigo.get("ia_pausada") != ia_pausada:
			enemigo.set("ia_pausada", ia_pausada)
			if ia_pausada:
				enemigo.velocity = Vector2.ZERO


func reubicar_enemigo(enemigo: CharacterBody2D, jugador: CharacterBody2D) -> void:
	if enemigo == null or jugador == null:
		return
	var pos_p: Vector2 = jugador.global_position
	var nueva_pos: Vector2 = Vector2(-pos_p.x, -pos_p.y)
	if nueva_pos.length() < 300.0:
		nueva_pos = Vector2(600.0, 600.0)
	enemigo.global_position = nueva_pos
