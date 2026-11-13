@tool
class_name TestNota
extends McpTestSuite

## Pruebas unitarias para la entidad coleccionable Nota (Issue #9).

func suite_name() -> String:
	return "nota"


func test_instanciacion_y_capas() -> void:
	var escena_nota: PackedScene = load("res://escenas/nota.tscn")
	assert_true(escena_nota != null, "La escena nota.tscn debe poder cargarse")
	var inst: Area2D = escena_nota.instantiate() as Area2D
	assert_true(inst != null, "La escena debe instanciarse como Area2D")

	# Capa 5 = 16 (Interactuables)
	assert_eq(inst.collision_layer, 16, "Nota debe estar en collision_layer = 16 (Capa 5)")
	# Capa 3 = 4 (Personaje)
	assert_true((inst.collision_mask & 4) != 0, "Nota debe monitorear Capa 3 (Personaje) con collision_mask = 4")
	assert_true(inst.monitoring, "monitoring debe ser true")
	assert_true(inst.monitorable, "monitorable debe ser true")

	inst.free()


func test_jerarquia_de_nodos_y_propiedades() -> void:
	var escena_nota: PackedScene = load("res://escenas/nota.tscn")
	var inst: Area2D = escena_nota.instantiate() as Area2D

	var visual: Sprite2D = inst.get_node_or_null("VisualPapel") as Sprite2D
	assert_true(visual != null, "Debe existir nodo hijo VisualPapel")
	assert_true(visual.texture != null, "VisualPapel debe tener textura asignada")

	var col: CollisionShape2D = inst.get_node_or_null("CollisionShape2D") as CollisionShape2D
	assert_true(col != null, "Debe existir nodo hijo CollisionShape2D")
	var circulo := col.shape as CircleShape2D
	assert_true(circulo != null, "El CollisionShape2D debe ser de tipo CircleShape2D")
	assert_eq(circulo.radius, 128.0, "El radio del círculo de colisión debe ser de 128 px")

	var luz: PointLight2D = inst.get_node_or_null("LuzBaliza") as PointLight2D
	assert_true(luz != null, "Debe existir nodo hijo LuzBaliza")
	assert_true(luz.texture != null, "LuzBaliza debe tener textura de halo asignada")
	assert_eq(luz.color, Color(1.0, 0.95, 0.8, 1.0), "Color de baliza debe ser pergamino cálido")
	assert_true(is_equal_approx(luz.energy, 0.8), "Energía base debe ser aproximadamente 0.8")

	var part: CPUParticles2D = inst.get_node_or_null("ParticulasRecogida") as CPUParticles2D
	assert_true(part != null, "Debe existir nodo hijo ParticulasRecogida")
	assert_eq(part.amount, 8, "Debe emitir 8 partículas")
	assert_eq(part.lifetime, 0.4, "Lifetime debe ser 0.4 s")
	assert_true(part.one_shot, "one_shot debe ser true")
	assert_false(part.emitting, "emitting inicial debe ser false")

	var sfx: AudioStreamPlayer2D = inst.get_node_or_null("SfxRevelacion") as AudioStreamPlayer2D
	assert_true(sfx != null, "Debe existir nodo hijo SfxRevelacion")
	assert_eq(sfx.bus, &"sfx", "SfxRevelacion debe usar el bus sfx")
	assert_eq(sfx.max_polyphony, 2, "SfxRevelacion debe tener max_polyphony = 2")
	assert_true(sfx.stream != null, "SfxRevelacion debe tener stream asignado")

	var sfx_rec: AudioStreamPlayer2D = inst.get_node_or_null("SfxRecoleccion") as AudioStreamPlayer2D
	assert_true(sfx_rec != null, "Debe existir nodo hijo SfxRecoleccion")
	assert_eq(sfx_rec.bus, &"sfx", "SfxRecoleccion debe usar el bus sfx")
	assert_eq(sfx_rec.max_polyphony, 2, "SfxRecoleccion debe tener max_polyphony = 2")
	assert_true(sfx_rec.stream != null, "SfxRecoleccion debe tener stream asignado")
	assert_true(inst.get("sfx_recoleccion") != null, "Nota debe exponer sfx_recoleccion asignable en el Inspector")

	inst.free()


func test_estado_inicial_oculto_y_guarda_recoleccion() -> void:
	var escena_nota: PackedScene = load("res://escenas/nota.tscn")
	var inst: Nota = escena_nota.instantiate() as Nota
	inst._visual_papel = inst.get_node_or_null("VisualPapel") as Sprite2D
	inst._luz_baliza = inst.get_node_or_null("LuzBaliza") as PointLight2D
	inst._particulas_recogida = inst.get_node_or_null("ParticulasRecogida") as CPUParticles2D
	inst._ready()

	assert_false(inst.esta_revelada(), "La nota debe iniciar con _revelada = false")
	assert_false(inst._visual_papel.visible, "VisualPapel debe iniciar invisible")
	assert_false(inst._luz_baliza.visible, "LuzBaliza debe iniciar invisible")

	var senal_recolectada: Array = []
	inst.recolectada.connect(func(pos: Vector2): senal_recolectada.append(pos))
	inst.recolectar()
	assert_false(inst.esta_recolectada(), "No debe recolectarse mientras no esté revelada")
	assert_eq(senal_recolectada.size(), 0, "No debe emitirse recolectada si está oculta")

	inst.free()


func test_animacion_procedural_process() -> void:
	var escena_nota: PackedScene = load("res://escenas/nota.tscn")
	var inst: Nota = escena_nota.instantiate() as Nota
	var visual: Sprite2D = inst.get_node_or_null("VisualPapel") as Sprite2D
	var luz: PointLight2D = inst.get_node_or_null("LuzBaliza") as PointLight2D
	inst._visual_papel = visual
	inst._luz_baliza = luz
	inst.revelar()

	# Simular avance de tiempo tras revelación
	inst._process(0.2)
	assert_true(absf(visual.position.y) <= 4.001, "La flotación vertical debe mantenerse dentro de +-4 px")
	assert_true(luz.energy >= 0.649 and luz.energy <= 0.951, "La energía de la luz debe mantenerse entre 0.65 y 0.95")

	inst._process(0.5)
	assert_true(absf(visual.position.y) <= 4.001, "La flotación vertical debe mantenerse dentro de +-4 px")
	assert_true(luz.energy >= 0.649 and luz.energy <= 0.951, "La energía de la luz debe mantenerse entre 0.65 y 0.95")

	inst.free()


func test_protocolo_recoleccion() -> void:
	var escena_nota: PackedScene = load("res://escenas/nota.tscn")
	var inst: Nota = escena_nota.instantiate() as Nota
	inst.position = Vector2(100, 200)

	var visual: Sprite2D = inst.get_node_or_null("VisualPapel") as Sprite2D
	var luz: PointLight2D = inst.get_node_or_null("LuzBaliza") as PointLight2D
	var part: CPUParticles2D = inst.get_node_or_null("ParticulasRecogida") as CPUParticles2D

	# Simular inicialización de variables de nodo
	inst._visual_papel = visual
	inst._luz_baliza = luz
	inst._particulas_recogida = part

	var senal_revelada: Array = []
	inst.revelada.connect(func(pos: Vector2): senal_revelada.append(pos))
	inst.revelar()
	assert_true(inst.esta_revelada(), "esta_revelada() debe ser true tras revelar()")
	assert_true(visual.visible, "VisualPapel debe encenderse al revelar")
	assert_true(luz.visible, "LuzBaliza debe encenderse al revelar")
	assert_eq(senal_revelada.size(), 1, "Debe emitirse revelada exactamente 1 vez")

	# Idempotencia de revelar()
	inst.revelar()
	assert_eq(senal_revelada.size(), 1, "revelar() debe ser idempotente")

	var senal_emitida: Array = []
	inst.recolectada.connect(func(pos: Vector2): senal_emitida.append(pos))

	inst.recolectar()

	assert_eq(senal_emitida.size(), 1, "Debe emitirse la señal recolectada exactamente 1 vez")
	assert_eq(senal_emitida[0], inst.global_position, "La posición emitida debe ser la global_position")
	assert_false(visual.visible, "VisualPapel debe ocultarse al recolectar")
	assert_false(luz.visible, "LuzBaliza debe ocultarse al recolectar")
	assert_true(part.emitting, "ParticulasRecogida debe activarse")

	# Idempotencia: segundo intento no emite de nuevo
	inst.recolectar()
	assert_eq(senal_emitida.size(), 1, "No debe duplicarse la emisión en un segundo intento")

	inst.free()
