shader_type canvas_item;

// --- Configuración Geométrica de las Cápsulas ---
uniform int cantidad_filas : hint_range(2, 20) = 8;
uniform float radio_capsula : hint_range(0.005, 0.1) = 0.035;
uniform float largo_capsula : hint_range(0.1, 1.5) = 0.55;
uniform float espaciado_x : hint_range(0.4, 3.0) = 1.0;
uniform float variacion_filas : hint_range(0.0, 1.0) = 0.35;

// --- Movimiento y Velocidades ---
uniform float velocidad_desplazamiento : hint_range(-2.0, 2.0) = 0.25;
uniform float fase_desplazamiento = 0.0;
uniform bool alternar_sentido_filas = false;

// --- Colores y Velo de Cobertura ---
uniform vec4 color_niebla : source_color = vec4(0.85, 0.90, 0.98, 0.82);
uniform vec4 color_niebla_secundaria : source_color = vec4(0.65, 0.75, 0.88, 0.65);
uniform float opacidad_velo_fondo : hint_range(0.0, 1.0) = 0.45;
uniform float densidad_global : hint_range(0.0, 1.0) = 0.0;

// --- Halo de Visión del Jugador ---
uniform float radio_interno : hint_range(0.0, 3.5) = 2.0;
uniform float suavizado : hint_range(0.01, 1.0) = 0.25;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float aspecto = 1.0;

// SDF de cápsula horizontal lisa (segmento de recta con radio)
float sdf_capsula(vec2 p, vec2 a, vec2 b, float r) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h) - r;
}

// Pseudo-hash determinista para variar filas sin ruido costoso
float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

void fragment() {
	if (densidad_global <= 0.001) {
		COLOR = vec4(0.0);
	} else {
		// Cálculo del halo claro circular alrededor del jugador
		vec2 diff = UV - centro;
		diff.x *= aspecto;
		float dist = length(diff);
		float mascara_exterior = smoothstep(radio_interno, radio_interno + suavizado, dist);

		float altura_paso = 1.0 / float(cantidad_filas);
		float acum_primario = 0.0;
		float acum_secundario = 0.0;

		// Evaluar cada fila de cápsulas
		for (int i = 0; i < cantidad_filas; i++) {
			float fi = float(i);
			float y_centro = (fi + 0.5) * altura_paso;

			// Descartar si el fragmento está muy lejos verticalmente de esta fila
			float dy = abs(UV.y - y_centro);
			if (dy > altura_paso * 0.75) {
				continue;
			}

			// Variación pseudoaleatoria estable por fila
			float rnd1 = hash11(fi * 13.17);
			float rnd2 = hash11(fi * 47.63);

			float largo_f = largo_capsula * (1.0 + (rnd1 - 0.5) * variacion_filas);
			float espaciado_f = max(espaciado_x * (1.0 + (rnd2 - 0.5) * variacion_filas * 0.5), largo_f + 0.1);
			float radio_f = radio_capsula * (1.0 + (rnd2 - 0.5) * variacion_filas * 0.3);

			// Dirección y velocidad de desplazamiento
			float sentido = 1.0;
			if (alternar_sentido_filas && (i % 2 == 1)) {
				sentido = -1.0;
			}
			float factor_fila = sentido * (0.85 + rnd1 * 0.3);
			float desfase_x = rnd2 * espaciado_f;

			// Coordenada periódica X (usa fase_desplazamiento si se provee, o fallback con TIME)
			float x_offset = (fase_desplazamiento != 0.0) ? (fase_desplazamiento * factor_fila) : (TIME * velocidad_desplazamiento * factor_fila);
			float x_movido = UV.x - (x_offset + desfase_x);
			float celda_x = mod(x_movido, espaciado_f);

			vec2 p = vec2(celda_x, UV.y);
			vec2 p_inicio = vec2(espaciado_f * 0.1, y_centro);
			vec2 p_fin = vec2(espaciado_f * 0.1 + largo_f, y_centro);

			float d = sdf_capsula(p, p_inicio, p_fin, radio_f);
			float forma = step(d, 0.0);

			if (i % 2 == 0) {
				acum_primario = max(acum_primario, forma);
			} else {
				acum_secundario = max(acum_secundario, forma);
			}
		}

		acum_primario = clamp(acum_primario, 0.0, 1.0);
		acum_secundario = clamp(acum_secundario, 0.0, 1.0);

		// Mezcla de capas y colores
		vec4 color_geom = acum_primario * color_niebla + (acum_secundario * (1.0 - acum_primario)) * color_niebla_secundaria;

		// Velo de fondo que cubre uniformemente en el clímax de la mutación
		float velo = opacidad_velo_fondo * densidad_global;

		float alpha_total = clamp(color_geom.a + velo, 0.0, 1.0);
		vec3 rgb_final = mix(color_niebla_secundaria.rgb, color_niebla.rgb, clamp(acum_primario + 0.35, 0.0, 1.0));

		// Atenuación por el halo del jugador y la densidad global
		float alpha_final = alpha_total * densidad_global * mascara_exterior;

		COLOR = vec4(rgb_final, alpha_final);
	}
}
