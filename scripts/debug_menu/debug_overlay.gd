@tool
extends Node2D

@export var menu_debug: DebugMenu


func _draw() -> void:
	if menu_debug == null:
		if get_parent() is DebugMenu:
			menu_debug = get_parent() as DebugMenu
		elif get_parent().get_parent() is DebugMenu:
			menu_debug = get_parent().get_parent() as DebugMenu

	if menu_debug == null:
		return

	# Si DebugOverlay está dentro de un CanvasLayer, las funciones draw_* usan coordenadas de pantalla (viewport).
	# Para alinear las figuras con los objetos del mundo (y responder al movimiento/zoom de Camera2D):
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		draw_set_transform_matrix(cam.get_canvas_transform())
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Factor de escala según el zoom de la cámara para que las líneas mantengan grosor en pantalla
	var factor_zoom: float = cam.zoom.x if (cam != null and cam.zoom.x > 0.01) else 1.0
	var grosor_corredor: float = maxf(2.0, 3.5 / factor_zoom)
	var grosor_ejes: float = maxf(3.0, 5.0 / factor_zoom)
	var grosor_perimetro: float = maxf(3.0, 6.0 / factor_zoom)
	var tamano_fuente: int = int(clampf(24.0 / factor_zoom, 24.0, 52.0))

	# 1. Dibujar Corredores de Seguridad de 160 px (80 px a cada lado de X=0 e Y=0)
	if menu_debug.debug_dibujar_corredores:
		var color_corredor := Color(0.2, 0.8, 0.4, 0.18)
		var color_borde := Color(0.2, 0.9, 0.5, 0.7)

		# Franja vertical (X entre -80 y +80, Y entre -1080 y +1080)
		var rect_v := Rect2(Vector2(-80, -1080), Vector2(160, 2160))
		draw_rect(rect_v, color_corredor, true)
		draw_rect(rect_v, color_borde, false, grosor_corredor)

		# Franja horizontal (Y entre -80 y +80, X entre -1080 y +1080)
		var rect_h := Rect2(Vector2(-1080, -80), Vector2(2160, 160))
		draw_rect(rect_h, color_corredor, true)
		draw_rect(rect_h, color_borde, false, grosor_corredor)

	# 2. Dibujar Ejes Divisores de Cuadrantes (X=0, Y=0) y Límites Perimetrales
	if menu_debug.debug_dibujar_cuadrantes:
		# Eje vertical (Y)
		draw_line(Vector2(0, -1080), Vector2(0, 1080), Color(0.35, 0.75, 1.0, 0.9), grosor_ejes)
		# Eje horizontal (X)
		draw_line(Vector2(-1080, 0), Vector2(1080, 0), Color(0.35, 0.75, 1.0, 0.9), grosor_ejes)

		# Marco perimetral de la arena 2160x2160
		draw_rect(Rect2(-1080, -1080, 2160, 2160), Color(1.0, 0.82, 0.2, 0.85), false, grosor_perimetro)

		# Etiquetas de cuadrantes
		draw_string(ThemeDB.fallback_font, Vector2(-600, -540), "SECTOR NO", HORIZONTAL_ALIGNMENT_CENTER, -1, tamano_fuente, Color(0.85, 0.92, 1.0, 0.75))
		draw_string(ThemeDB.fallback_font, Vector2(480, -540), "SECTOR NE", HORIZONTAL_ALIGNMENT_CENTER, -1, tamano_fuente, Color(0.85, 0.92, 1.0, 0.75))
		draw_string(ThemeDB.fallback_font, Vector2(-600, 540), "SECTOR SO", HORIZONTAL_ALIGNMENT_CENTER, -1, tamano_fuente, Color(0.85, 0.92, 1.0, 0.75))
		draw_string(ThemeDB.fallback_font, Vector2(480, 540), "SECTOR SE", HORIZONTAL_ALIGNMENT_CENTER, -1, tamano_fuente, Color(0.85, 0.92, 1.0, 0.75))
