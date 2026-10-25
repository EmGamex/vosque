shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
// progress: 0.0 = totalmente abierto (visible), 1.0 = totalmente cerrado (pantalla negra)
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float smoothness : hint_range(0.0, 0.2) = 0.02;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float aspect_ratio = 1.0;

void fragment() {
	vec2 uv = UV;
	// Corrección de relación de aspecto pivotada en el centro
	uv.x = (uv.x - center.x) * aspect_ratio + center.x;

	// Distancia máxima para cubrir las esquinas completamente en 0.0
	float max_radius = 1.0 * max(aspect_ratio, 1.0);
	float radius = (1.0 - progress) * (max_radius * 0.75 + smoothness);

	float dist = distance(uv, center);
	float alpha = smoothstep(radius - smoothness, radius + smoothness, dist);
	COLOR = vec4(color.rgb, color.a * alpha);
}
