@tool
class_name TestIluminacion
extends McpTestSuite

## Suite de pruebas automatizadas para el Sistema de Iluminación 2D WebGL y Linterna Frontal 360° (Issue #15).

func suite_name() -> String:
	return "iluminacion"


func test_configuracion_iluminacion_valores_y_reactividad() -> void:
	var cfg := ConfiguracionIluminacion.new()
	assert_eq(cfg.color_ambiente_inicial, Color(0.08, 0.10, 0.15, 1.0), "Color ambiente inicial debe ser penumbra azul petróleo")
	assert_eq(cfg.color_ambiente_final, Color(0.04, 0.05, 0.07, 1.0), "Color ambiente final debe ser noche cerrada")
	assert_eq(cfg.color_linterna, Color(1.0, 0.96, 0.88, 1.0), "Color linterna debe ser blanco cálido halógeno")
	assert_eq(cfg.energia_base, 1.2, "Energía base debe ser 1.2")
	assert_eq(cfg.alcance_px, 700.0, "Alcance debe ser 700 px")
	assert_eq(cfg.apertura_grados, 60.0, "Apertura debe ser 60°")
	assert_eq(cfg.velocidad_giro_teclado, 10.0, "Velocidad de giro por teclado debe ser 10 rad/s")
	assert_eq(cfg.radio_halo_px, 120.0, "Radio de halo debe ser 120 px")
	assert_eq(cfg.intensidad_flicker, 0.10, "Intensidad de flicker debe ser 10%")

	# Test interpolación de ambiente por notas
	var c0 := cfg.calcular_color_ambiente(0)
	assert_eq(c0, cfg.color_ambiente_inicial, "Con 0 notas debe ser color inicial")
	var c8 := cfg.calcular_color_ambiente(8)
	assert_eq(c8, cfg.color_ambiente_final, "Con 8 notas debe ser color final")
	var c4 := cfg.calcular_color_ambiente(4)
	assert_true(c4.r < c0.r and c4.r > c8.r, "A la mitad de notas debe interpolar linealmente")

	# Reactividad changed
	var estado := {"signal_emitida": false}
	cfg.changed.connect(func(): estado["signal_emitida"] = true)
	cfg.energia_base = 1.5
	assert_true(estado["signal_emitida"], "Modificar propiedad debe disparar changed")


func test_generador_textura_cono() -> void:
	var tex := GeneradorLuzCono.generar_textura_cono(700.0, 60.0, 0.25, 256)
	assert_true(tex != null, "Debe generar una ImageTexture")
	assert_eq(tex.get_width(), 256, "Ancho debe coincidir con resolución")
	assert_eq(tex.get_height(), 256, "Alto debe coincidir con resolución")

	var img := tex.get_image()
	assert_true(img != null, "ImageTexture debe proveer Image válida")

	# El ápice en (0, 128) debe ser blanco y opaco
	var pixel_origen := img.get_pixel(0, 128)
	assert_true(pixel_origen.a > 0.9, "El ápice debe ser opaco")

	# Píxel fuera del ángulo cónico (ej. arriba en x=100, y=10) debe ser transparente
	var pixel_fuera := img.get_pixel(100, 10)
	assert_eq(pixel_fuera.a, 0.0, "Píxel fuera de los 60° debe ser completamente transparente")


func test_jerarquia_y_presupuesto_personaje() -> void:
	var escena_personaje: PackedScene = load("res://escenas/personaje.tscn")
	assert_true(escena_personaje != null, "escenas/personaje.tscn debe poder cargarse")
	var inst := escena_personaje.instantiate() as CharacterBody2D
	assert_true(inst != null, "Debe instanciarse el personaje")

	var pivote: Node2D = inst.get_node_or_null("PivoteLinterna") as Node2D
	assert_true(pivote != null, "Debe existir PivoteLinterna en el personaje")
	assert_true(pivote is ControladorLinterna, "PivoteLinterna debe tener script ControladorLinterna")

	var linterna: PointLight2D = pivote.get_node_or_null("LinternaFrontal") as PointLight2D
	assert_true(linterna != null, "Debe existir LinternaFrontal en PivoteLinterna")
	assert_false(linterna.shadow_enabled, "Sombras dinámicas deben estar deshabilitadas (shadow_enabled=false)")
	assert_eq(linterna.blend_mode, PointLight2D.BLEND_MODE_ADD, "LinternaFrontal debe usar BLEND_MODE_ADD")

	var halo: Sprite2D = pivote.get_node_or_null("HaloCorporal") as Sprite2D
	assert_true(halo != null, "Debe existir HaloCorporal en PivoteLinterna")
	assert_true(halo.material is CanvasItemMaterial, "HaloCorporal debe tener CanvasItemMaterial")
	var mat := halo.material as CanvasItemMaterial
	assert_eq(mat.blend_mode, CanvasItemMaterial.BLEND_MODE_ADD, "HaloCorporal debe tener BLEND_MODE_ADD")

	inst.free()


func test_deteccion_analitica_cono() -> void:
	var pivote := ControladorLinterna.new()
	var cfg := ConfiguracionIluminacion.new()
	cfg.alcance_px = 700.0
	cfg.apertura_grados = 60.0
	cfg.distancia_estres_px = 300.0
	pivote.config = cfg

	pivote.position = Vector2.ZERO
	pivote.rotation = 0.0 # Apuntando hacia +X

	# Caso 1: Punto enfrente a 400 px (dentro del haz)
	var res1 := pivote.evaluar_posicion_en_haz(Vector2(400.0, 0.0))
	assert_true(res1["en_haz"], "Punto a 400 px frente a la linterna debe estar en haz")
	assert_false(res1["en_rango_critico"], "Punto a 400 px no debe ser crítico (<300 px)")

	# Caso 2: Punto a 200 px enfrente (crítico)
	var res2 := pivote.evaluar_posicion_en_haz(Vector2(200.0, 0.0))
	assert_true(res2["en_haz"], "Punto a 200 px debe estar en haz")
	assert_true(res2["en_rango_critico"], "Punto a 200 px debe ser crítico (<300 px)")

	# Caso 3: Punto a 800 px enfrente (fuera por distancia > 700 px)
	var res3 := pivote.evaluar_posicion_en_haz(Vector2(800.0, 0.0))
	assert_false(res3["en_haz"], "Punto a 800 px no debe estar en haz")

	# Caso 4: Punto a 400 px a 45° (fuera de cono de 60°, o sea > 30°)
	var res4 := pivote.evaluar_posicion_en_haz(Vector2(400.0, 400.0))
	assert_false(res4["en_haz"], "Punto a 45° no debe estar en haz")

	pivote.free()


func test_flicker_electromagnetico() -> void:
	var pivote := ControladorLinterna.new()
	var cfg := ConfiguracionIluminacion.new()
	cfg.energia_base = 1.2
	cfg.intensidad_flicker = 0.10
	cfg.frecuencia_flicker = 24.0
	cfg.flicker_forzado_debug = true
	pivote.config = cfg

	var linterna := PointLight2D.new()
	linterna.name = "LinternaFrontal"
	pivote.add_child(linterna)
	pivote.linterna = linterna

	var energias: Array[float] = []
	pivote.flicker_actualizado.connect(func(e): energias.append(e))

	for i in range(10):
		pivote._procesar_deteccion_y_flicker(0.02)

	assert_true(energias.size() > 0, "Debe haber emitido actualizaciones de flicker")
	for e in energias:
		assert_true(e >= 1.2 * 0.89 and e <= 1.2 * 1.11, "Energía modulada debe estar dentro del +/-10% de 1.2")

	pivote.free()


func test_canvas_modulate_escenario() -> void:
	var escena_escenario: PackedScene = load("res://escenas/escenario.tscn")
	assert_true(escena_escenario != null, "escenas/escenario.tscn debe poder cargarse")
	var inst := escena_escenario.instantiate() as Escenario
	assert_true(inst != null, "Debe instanciarse el escenario")

	var cm: CanvasModulate = inst.get_node_or_null("CanvasModulate") as CanvasModulate
	assert_true(cm != null, "Debe existir CanvasModulate en escenario.tscn")

	inst._inicializar_iluminacion_ambiental()
	var color_inicial: Color = cm.color
	var color_esperado_inicial: Color = inst.config_iluminacion.calcular_color_ambiente(0) if inst.config_iluminacion != null else Color(0.08, 0.10, 0.15, 1.0)
	assert_true(color_inicial.is_equal_approx(color_esperado_inicial), "Color inicial de CanvasModulate debe ser aproximado a color_ambiente_inicial")

	inst.actualizar_iluminacion_ambiental(8, 0.0)
	var color_esperado_final: Color = inst.config_iluminacion.calcular_color_ambiente(8) if inst.config_iluminacion != null else Color(0.04, 0.05, 0.07, 1.0)
	assert_true(cm.color.is_equal_approx(color_esperado_final), "Con 8 notas debe ser color final aproximado a color_ambiente_final")

	inst.free()


func test_presupuesto_webgl_maximo_dos_luces() -> void:
	var escena_main: PackedScene = load("res://escenas/maain.tscn")
	assert_true(escena_main != null, "escenas/maain.tscn debe poder cargarse")
	var main_node: Node2D = escena_main.instantiate() as Node2D
	assert_true(main_node != null, "Debe instanciarse maain.tscn")

	# Contar todos los PointLight2D en la jerarquía inicial
	var luces: Array[Node] = main_node.find_children("", "PointLight2D", true, false)
	var luces_activas: int = 0
	for l in luces:
		var pl := l as PointLight2D
		if pl != null and pl.enabled and pl.visible:
			luces_activas += 1

	# En reposo solo debe estar la LinternaFrontal (y cuando haya nota en escena, máximo 2)
	assert_true(luces_activas <= 2, "El presupuesto de PointLight2D activas nunca debe superar 2 (activo: %d)" % luces_activas)

	main_node.free()
