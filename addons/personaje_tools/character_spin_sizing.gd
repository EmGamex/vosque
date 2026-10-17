@tool
extends RefCounted

## Utilidades sin estado para dimensionar un SpinBox según su rango y sufijo.
## Al no guardar estado no le afectan las recargas en caliente del editor.

const PADDING_SPIN := 12.0


static func ajustar_ancho(spin: SpinBox) -> void:
	if spin == null:
		return
	var sufijo := spin.get_suffix()
	var ancho_texto := 0.0
	for valor in [spin.min_value, spin.max_value]:
		var muestra := _formatear_valor(valor, spin.step) + sufijo
		ancho_texto = maxf(ancho_texto, _ancho_texto_spin(spin, muestra))
	var ancho := ancho_texto + _ancho_cromo_spin(spin) + PADDING_SPIN
	spin.custom_minimum_size.x = maxf(spin.custom_minimum_size.x, ancho)
	spin.update_minimum_size()


static func _formatear_valor(valor: float, paso: float) -> String:
	return String.num(valor, _decimales_de_paso(paso))


static func _decimales_de_paso(paso: float) -> int:
	if paso <= 0.0:
		return 0
	var decimales := 0
	var probado := paso
	while decimales < 6 and not is_equal_approx(probado, roundf(probado)):
		probado *= 10.0
		decimales += 1
	return decimales


static func _ancho_texto_spin(spin: SpinBox, muestra: String) -> float:
	var line := spin.get_line_edit()
	if line == null:
		return 0.0
	var fuente := line.get_theme_font("font")
	if fuente == null:
		return 0.0
	var tamano := line.get_theme_font_size("font_size")
	return fuente.get_string_size(muestra, HORIZONTAL_ALIGNMENT_LEFT, -1, tamano).x


static func _ancho_cromo_spin(spin: SpinBox) -> float:
	var ancho := 0.0
	if spin.has_theme_constant("buttons_width"):
		ancho += float(spin.get_theme_constant("buttons_width"))
	if spin.has_theme_constant("field_and_buttons_separation"):
		ancho += float(spin.get_theme_constant("field_and_buttons_separation"))
	var line := spin.get_line_edit()
	if line != null:
		var estilo := line.get_theme_stylebox("normal")
		if estilo != null:
			ancho += estilo.get_minimum_size().x
	return ancho
