class_name DebugSystemController
extends RefCounted

## Controlador de escala temporal del motor, reinicio de escena y pausa.


func set_time_scale(scale: float, cfg: Node) -> void:
	Engine.time_scale = scale
	if cfg != null:
		cfg.time_scale = scale


func reiniciar_escena(tree: SceneTree) -> void:
	if tree != null:
		tree.paused = false
		tree.reload_current_scene()


func toggle_pausa(tree: SceneTree, pausar: bool) -> void:
	if tree != null:
		tree.paused = pausar
