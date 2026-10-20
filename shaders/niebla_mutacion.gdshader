shader_type canvas_item;

uniform vec4 color_niebla : source_color = vec4(0.04, 0.05, 0.08, 1.0);
uniform float radio_interno : hint_range(0.0, 1.5) = 1.3;
uniform float suavizado : hint_range(0.01, 1.0) = 0.45;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float aspecto = 1.0;

void fragment() {
	vec2 diff = UV - centro;
	diff.x *= aspecto;
	float dist = length(diff);
	float alpha = smoothstep(radio_interno, radio_interno + suavizado, dist);
	COLOR = vec4(color_niebla.rgb, alpha * color_niebla.a);
}
