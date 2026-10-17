class_name DebugCheatsController
extends RefCounted

## Controlador para cheats de estamina infinita e invencibilidad (god mode).

var cheat_estamina_infinita: bool = false
var cheat_god_mode: bool = false


func restaurar_desde_config(cfg: Node, check_estamina: CheckBox, check_god: CheckBox) -> void:
	if cfg == null:
		return
	cheat_estamina_infinita = cfg.cheat_estamina_infinita
	cheat_god_mode = cfg.cheat_god_mode

	if check_estamina != null:
		check_estamina.set_pressed_no_signal(cheat_estamina_infinita)
	if check_god != null:
		check_god.set_pressed_no_signal(cheat_god_mode)


func set_estamina_infinita(activo: bool, target: CharacterBody2D, cfg: Node) -> void:
	cheat_estamina_infinita = activo
	if cfg != null:
		cfg.cheat_estamina_infinita = activo
	if target != null and "sin_gasto_estamina" in target:
		target.set("sin_gasto_estamina", activo)


func set_god_mode(activo: bool, target: CharacterBody2D, cfg: Node) -> void:
	cheat_god_mode = activo
	if cfg != null:
		cfg.cheat_god_mode = activo
	if target != null:
		if "god_mode" in target:
			target.set("god_mode", activo)
		target.set_collision_mask_value(4, not activo)


func aplicar_en_process(target: CharacterBody2D) -> void:
	if target == null or not is_instance_valid(target):
		return

	if "sin_gasto_estamina" in target:
		target.set("sin_gasto_estamina", cheat_estamina_infinita)
	elif cheat_estamina_infinita:
		if "stamina" in target:
			target.set("stamina", float(target.get("max_stamina")) if "max_stamina" in target else 100.0)
			if "fatigado" in target:
				target.set("fatigado", false)

	if "god_mode" in target:
		target.set("god_mode", cheat_god_mode)
