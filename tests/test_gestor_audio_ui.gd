@tool
class_name TestGestorAudioUI
extends McpTestSuite

## Pruebas unitarias para GestorAudioUI y su integración con menús.

func suite_name() -> String:
	return "gestor_audio_ui"


func test_instanciacion_y_reproductores() -> void:
	var script: GDScript = load("res://scripts/core/gestor_audio_ui.gd")
	var gestor: Node = script.new()
	assert_true(gestor != null, "GestorAudioUI debe instanciarse")

	gestor._ready()

	assert_eq(gestor.process_mode, Node.PROCESS_MODE_ALWAYS, "Debe tener PROCESS_MODE_ALWAYS")

	var player_cursor: AudioStreamPlayer = gestor.get_node_or_null("PlayerCursor") as AudioStreamPlayer
	var player_accion: AudioStreamPlayer = gestor.get_node_or_null("PlayerAccion") as AudioStreamPlayer

	assert_true(player_cursor != null, "Debe existir PlayerCursor")
	assert_true(player_accion != null, "Debe existir PlayerAccion")

	assert_eq(player_cursor.bus, &"sfx", "PlayerCursor debe usar el bus sfx")
	assert_eq(player_accion.bus, &"sfx", "PlayerAccion debe usar el bus sfx")
	assert_eq(player_cursor.process_mode, Node.PROCESS_MODE_ALWAYS, "PlayerCursor debe ser PROCESS_MODE_ALWAYS")
	assert_eq(player_accion.process_mode, Node.PROCESS_MODE_ALWAYS, "PlayerAccion debe ser PROCESS_MODE_ALWAYS")

	# Probar llamadas a los métodos públicos para asegurar que no lancen errores
	gestor.reproducir_menu_seleccionar()
	assert_true(player_cursor.stream != null, "PlayerCursor debe tener stream asignado para seleccionar")

	gestor.reproducir_menu_aceptar()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para aceptar")

	gestor.reproducir_menu_retroceder()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para retroceder")

	gestor.reproducir_pausa_abrir()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para abrir pausa")

	gestor.reproducir_pausa_navegar()
	assert_true(player_cursor.stream != null, "PlayerCursor debe tener stream asignado para navegar pausa")

	gestor.reproducir_pausa_aceptar()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para aceptar pausa")

	gestor.reproducir_pausa_cerrar()
	assert_true(player_accion.stream != null, "PlayerAccion debe tener stream asignado para cerrar pausa")

	gestor.free()
