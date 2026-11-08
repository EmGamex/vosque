class_name DebugWindowManager
extends RefCounted

## Gestor de ventanas para DebugMenu: controla visibilidad, posiciones,
## presets de organización rápida y persistencia de estado con DebugConfig.

signal visibilidad_cambiada(hay_visibles: bool)

var todas_las_ventanas: Array[DebugWindow] = []

# Referencias directas para presets rápidos
var win_jugador: DebugWindow
var win_fisicas: DebugWindow
var win_escenario: DebugWindow
var win_enemigo: DebugWindow
var win_audio: DebugWindow
var win_sistema: DebugWindow


func inicializar(ventanas: Array[DebugWindow]) -> void:
	todas_las_ventanas = ventanas
	for win in todas_las_ventanas:
		if win == null:
			continue
		var id = win.window_id
		if id.is_empty():
			# Fallback al nombre del nodo si no se ha llamado a _ready() todavía
			var n = win.name.to_lower()
			if "jugador" in n: id = "jugador"
			elif "fisica" in n: id = "fisicas"
			elif "escenario" in n: id = "escenario"
			elif "enemigo" in n: id = "enemigo"
			elif "audio" in n: id = "audio"
			elif "sistema" in n: id = "sistema"

		match id:
			"jugador": win_jugador = win
			"fisicas": win_fisicas = win
			"escenario": win_escenario = win
			"enemigo": win_enemigo = win
			"audio": win_audio = win
			"sistema": win_sistema = win


func conectar_eventos_ventanas(callback_estado_modificado: Callable) -> void:
	for win in todas_las_ventanas:
		if win != null and not win.estado_modificado.is_connected(callback_estado_modificado):
			win.estado_modificado.connect(callback_estado_modificado)


func guardar_estado_ventana(win_id: String, cfg: Node) -> void:
	if cfg == null:
		return
	for win in todas_las_ventanas:
		if win != null and win.window_id == win_id:
			cfg.guardar_estado_ventana(win_id, win.abierta, win.fijada, win.colapsada, win.global_position)
			break


func restaurar_desde_config(cfg: Node) -> void:
	if cfg == null:
		return

	var posiciones_defecto = {
		"jugador": Vector2(20, 60),
		"fisicas": Vector2(360, 60),
		"escenario": Vector2(20, 360),
		"enemigo": Vector2(400, 360),
		"audio": Vector2(740, 60),
		"sistema": Vector2(740, 360)
	}

	for win in todas_las_ventanas:
		if win != null:
			var pos_def: Vector2 = posiciones_defecto.get(win.window_id, Vector2(20, 60))
			var estado: Dictionary = cfg.obtener_estado_ventana(win.window_id, false, pos_def)
			win.abierta = estado.get("abierta", false)
			win.fijada = estado.get("fijada", false)
			win.colapsada = estado.get("colapsada", false)
			win.global_position = estado.get("posicion", pos_def)


func actualizar_visibilidad(en_edicion: bool, hay_overlays: bool, barra_dock: Control) -> bool:
	var hay_fijadas: bool = false
	for win in todas_las_ventanas:
		if win != null and win.abierta and win.fijada:
			hay_fijadas = true
			break

	var visible_total: bool = en_edicion or hay_overlays or hay_fijadas

	if barra_dock != null:
		barra_dock.visible = en_edicion

	for win in todas_las_ventanas:
		if win != null:
			win.aplicar_modo_juego(not en_edicion)

	return visible_total


func cerrar_todas_las_ventanas() -> void:
	for win in todas_las_ventanas:
		if win != null:
			win.abierta = false
			win.fijada = false


func ordenar_ventanas_en_mosaico(ancho_pantalla: float) -> void:
	var margen_x: float = 20.0
	var cursor_x: float = margen_x
	var cursor_y: float = 60.0

	for win in todas_las_ventanas:
		if win != null and win.abierta:
			if cursor_x + win.size.x > ancho_pantalla and cursor_x > margen_x:
				cursor_x = margen_x
				cursor_y += 320.0
			win.global_position = Vector2(cursor_x, cursor_y)
			cursor_x += win.size.x + 15.0


func aplicar_preset(index: int) -> void:
	match index:
		1: # Locomoción
			cerrar_todas_las_ventanas()
			if win_jugador != null: win_jugador.abierta = true; win_jugador.global_position = Vector2(20, 60)
			if win_fisicas != null: win_fisicas.abierta = true; win_fisicas.fijada = true; win_fisicas.global_position = Vector2(360, 60)
		2: # Caza & IA
			cerrar_todas_las_ventanas()
			if win_jugador != null: win_jugador.abierta = true; win_jugador.global_position = Vector2(20, 60)
			if win_enemigo != null: win_enemigo.abierta = true; win_enemigo.fijada = true; win_enemigo.global_position = Vector2(360, 60)
		3: # Mundo
			cerrar_todas_las_ventanas()
			if win_escenario != null: win_escenario.abierta = true; win_escenario.fijada = true; win_escenario.global_position = Vector2(20, 60)
		4: # Audio & Sistema
			cerrar_todas_las_ventanas()
			if win_audio != null: win_audio.abierta = true; win_audio.global_position = Vector2(20, 60)
			if win_sistema != null: win_sistema.abierta = true; win_sistema.global_position = Vector2(360, 60)
		5: # Cerrar Todas
			cerrar_todas_las_ventanas()
