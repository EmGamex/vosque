shader_type canvas_item;
render_mode blend_mix;

// Shader de disolución y mezcla directa para árboles del Menú Principal.
// Interpola directamente el color y canal alfa a nivel de píxel evitando la caída de opacidad
// combinada y garantizando que las áreas cubiertas se mantengan 100% opacas.

uniform sampler2D textura_anterior : hint_default_transparent, filter_linear;
uniform float progreso : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 col_actual = texture(TEXTURE, UV);

	if (progreso >= 0.9999) {
		COLOR = col_actual;
	} else if (progreso <= 0.0001) {
		COLOR = texture(textura_anterior, UV);
	} else {
		vec4 col_anterior = texture(textura_anterior, UV);
		COLOR = mix(col_anterior, col_actual, clamp(progreso, 0.0, 1.0));
	}
}
