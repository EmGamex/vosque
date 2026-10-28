@tool
class_name GeneradorLuzCono
extends RefCounted

## Utilidad procedural para generar texturas de haz de luz cónico 2D con atenuación radial cuadrática y bordes suaves.

static func generar_textura_cono(
	_alcance_px: float = 700.0,
	apertura_grados: float = 60.0,
	suavizado_borde: float = 0.25,
	resolucion: int = 512
) -> ImageTexture:
	var img: Image = Image.create(resolucion, resolucion, false, Image.FORMAT_RGBA8)
	var mitad_res: float = float(resolucion) / 2.0
	var angulo_max_rad: float = deg_to_rad(apertura_grados * 0.5)
	var angulo_inner_rad: float = angulo_max_rad * (1.0 - clampf(suavizado_borde, 0.0, 0.99))
	var escala_radio: float = float(resolucion)

	# El ápice se ubica en el centro del borde izquierdo (x = 0, y = mitad_res) apuntando hacia +X
	for y in range(resolucion):
		var dy: float = float(y) - mitad_res
		for x in range(resolucion):
			var dx: float = float(x)
			if dx == 0.0 and dy == 0.0:
				img.set_pixel(x, y, Color(1, 1, 1, 1))
				continue

			var dist_px: float = sqrt(dx * dx + dy * dy)
			var r: float = dist_px / escala_radio
			if r > 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			var phi: float = absf(atan2(dy, dx))
			if phi > angulo_max_rad:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			# Atenuación radial cuadrática (1.0 - r)^2
			var factor_radial: float = (1.0 - r) * (1.0 - r)

			# Atenuación angular difuminada en bordes con smoothstep
			var factor_angular: float = 1.0
			if phi > angulo_inner_rad:
				var t_ang: float = (phi - angulo_inner_rad) / (angulo_max_rad - angulo_inner_rad)
				factor_angular = 1.0 - (t_ang * t_ang * (3.0 - 2.0 * t_ang)) # smoothstep invertido

			var opacidad: float = clampf(factor_radial * factor_angular, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, opacidad))

	return ImageTexture.create_from_image(img)
