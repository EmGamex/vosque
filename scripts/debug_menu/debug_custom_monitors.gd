class_name DebugCustomMonitors
extends RefCounted

## Gestor de monitores de depuración y rendimiento de Godot (Performance.add_custom_monitor).

var _monitores_registrados: Array[StringName] = []
var _context: DebugContext


func registrar(context: DebugContext) -> void:
	if not OS.is_debug_build() or Engine.is_editor_hint():
		return

	_context = context
	limpiar()

	_agregar_monitor("Vosque/Estamina Jugador", _monitor_estamina_jugador)
	_agregar_monitor("Vosque/Velocidad Jugador", _monitor_velocidad_jugador)
	_agregar_monitor("Vosque/Velocidad Enemigo", _monitor_velocidad_enemigo)
	_agregar_monitor("Vosque/Distancia Monstruo", _monitor_distancia_monstruo)
	_agregar_monitor("Vosque/Estado Jugador", _monitor_estado_jugador)


func limpiar() -> void:
	for id in _monitores_registrados:
		if Performance.has_custom_monitor(id):
			Performance.remove_custom_monitor(id)
	_monitores_registrados.clear()


func _agregar_monitor(nombre: StringName, callable: Callable) -> void:
	if not Performance.has_custom_monitor(nombre):
		Performance.add_custom_monitor(nombre, callable)
		_monitores_registrados.append(nombre)


func _monitor_estamina_jugador() -> float:
	if _context != null and _context.target_character != null and is_instance_valid(_context.target_character):
		if "stamina" in _context.target_character:
			return float(_context.target_character.get("stamina"))
	return 0.0


func _monitor_velocidad_jugador() -> float:
	if _context != null and _context.target_character != null and is_instance_valid(_context.target_character):
		return _context.target_character.velocity.length()
	return 0.0


func _monitor_velocidad_enemigo() -> float:
	if _context != null and _context.target_enemigo != null and is_instance_valid(_context.target_enemigo):
		return _context.target_enemigo.velocity.length()
	return 0.0


func _monitor_distancia_monstruo() -> float:
	if _context != null and _context.target_character != null and is_instance_valid(_context.target_character) and _context.target_enemigo != null and is_instance_valid(_context.target_enemigo):
		return _context.target_character.global_position.distance_to(_context.target_enemigo.global_position)
	return 0.0


func _monitor_estado_jugador() -> int:
	if _context != null and _context.target_character != null and is_instance_valid(_context.target_character):
		if "estado_actual" in _context.target_character:
			return int(_context.target_character.get("estado_actual"))
	return 0
