shader_type canvas_item;

// Shader de Motion Blur vertical / direccional para cinemáticas 2D.
// Aplica un desenfoque por muestras en el eje de movimiento sobre screen_texture.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float intensidad : hint_range(0.0, 0.1) = 0.0;
uniform vec2 direccion = vec2(0.0, 1.0);
uniform int muestras : hint_range(3, 16) = 8;

void fragment() {
	if (intensidad <= 0.0001) {
		COLOR = texture(screen_texture, SCREEN_UV);
	} else {
		vec4 color_acumulado = vec4(0.0);
		float total = 0.0;
		vec2 dir_desplazamiento = normalize(direccion) * intensidad;

		for (int i = 0; i < muestras; i++) {
			float t = (float(i) / float(muestras - 1)) - 0.5;
			vec2 offset = dir_desplazamiento * t;
			color_acumulado += texture(screen_texture, SCREEN_UV + offset);
			total += 1.0;
		}
		COLOR = color_acumulado / total;
	}
}
