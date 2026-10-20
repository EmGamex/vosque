@tool
class_name TestEscenario
extends McpTestSuite

## Suite de pruebas para la infraestructura de arena 2x2, valla, variantes y mutación (Issue #3).

class MockPersonajeParaEscenario extends CharacterBody2D:
	var speed: float = 800.0
	var stamina: float = 100.0


func suite_name() -> String:
	return "escenario"


func test_dimensiones_y_valla_perimetral() -> void:
	var escena_escenario: PackedScene = load("res://escenas/escenario.tscn")
	assert_true(escena_escenario != null, "La escena escenario.tscn debe poder cargarse")
	var inst: Node2D = escena_escenario.instantiate() as Node2D
	assert_true(inst != null, "Debe instanciarse el escenario")

	var valla: StaticBody2D = inst.get_node_or_null("VallaPerimetral") as StaticBody2D
	assert_true(valla != null, "Debe existir VallaPerimetral")
	assert_eq(valla.collision_layer, 1, "VallaPerimetral debe estar en Capa 1 (Mundo_Alto)")
	assert_eq(valla.collision_mask, 0, "VallaPerimetral debe tener collision_mask = 0")

	var cn: CollisionShape2D = valla.get_node_or_null("ColisionNorte") as CollisionShape2D
	var cs: CollisionShape2D = valla.get_node_or_null("ColisionSur") as CollisionShape2D
	var co: CollisionShape2D = valla.get_node_or_null("ColisionOeste") as CollisionShape2D
	var ce: CollisionShape2D = valla.get_node_or_null("ColisionEste") as CollisionShape2D

	assert_true(cn != null, "Debe existir ColisionNorte")
	assert_true(cs != null, "Debe existir ColisionSur")
	assert_true(co != null, "Debe existir ColisionOeste")
	assert_true(ce != null, "Debe existir ColisionEste")

	assert_eq(cn.position, Vector2(0, -2160), "ColisionNorte debe estar en (0, -2160)")
	assert_eq(cs.position, Vector2(0, 2160), "ColisionSur debe estar en (0, 2160)")
	assert_eq(co.position, Vector2(-2160, 0), "ColisionOeste debe estar en (-2160, 0)")
	assert_eq(ce.position, Vector2(2160, 0), "ColisionEste debe estar en (2160, 0)")

	var r_norte = cn.shape as RectangleShape2D
	var r_sur = cs.shape as RectangleShape2D
	var r_oeste = co.shape as RectangleShape2D
	var r_este = ce.shape as RectangleShape2D

	assert_eq(r_norte.size, Vector2(4320, 64), "ColisionNorte debe medir 4320x64")
	assert_eq(r_sur.size, Vector2(4320, 64), "ColisionSur debe medir 4320x64")
	assert_eq(r_oeste.size, Vector2(64, 4320), "ColisionOeste debe medir 64x4320")
	assert_eq(r_este.size, Vector2(64, 4320), "ColisionEste debe medir 64x4320")

	inst.free()


func test_limites_camara() -> void:
	var escena_cam: PackedScene = load("res://escenas/camara.tscn")
	assert_true(escena_cam != null, "La escena camara.tscn debe poder cargarse")
	var cam: Camera2D = escena_cam.instantiate() as Camera2D
	assert_true(cam != null, "Debe instanciarse Camera2D")

	assert_eq(cam.limit_left, -2160, "limit_left debe ser -2160")
	assert_eq(cam.limit_top, -2160, "limit_top debe ser -2160")
	assert_eq(cam.limit_right, 2160, "limit_right debe ser 2160")
	assert_eq(cam.limit_bottom, 2160, "limit_bottom debe ser 2160")
	assert_eq(cam.process_callback, Camera2D.CAMERA2D_PROCESS_PHYSICS, "process_callback debe ser PHYSICS (0) para evitar temblor")

	cam.free()


func test_variantes_capas_y_corredores() -> void:
	var rutas: Array[String] = [
		"res://escenas/sectores/variantes/variante_claro_rocoso.tscn",
		"res://escenas/sectores/variantes/variante_bosque_denso.tscn",
		"res://escenas/sectores/variantes/variante_sendero_troncos.tscn",
	]

	for ruta in rutas:
		var pack: PackedScene = load(ruta) as PackedScene
		assert_true(pack != null, "Debe existir la variante: " + ruta)
		var nodo_var: Node2D = pack.instantiate() as Node2D
		assert_true(nodo_var != null, "Debe instanciarse variante: " + ruta)

		var altos: StaticBody2D = nodo_var.get_node_or_null("ObstaculosAltos") as StaticBody2D
		var bajos: StaticBody2D = nodo_var.get_node_or_null("ObstaculosBajos") as StaticBody2D
		var puntos: Node2D = nodo_var.get_node_or_null("PuntosDeNota") as Node2D

		assert_true(altos != null, "Debe existir ObstaculosAltos en " + ruta)
		assert_eq(altos.collision_layer, 1, "ObstaculosAltos debe estar en Capa 1")

		assert_true(bajos != null, "Debe existir ObstaculosBajos en " + ruta)
		assert_eq(bajos.collision_layer, 2, "ObstaculosBajos debe estar en Capa 2")

		assert_true(puntos != null, "Debe existir PuntosDeNota en " + ruta)
		var markers: Array[Node] = puntos.find_children("", "Marker2D", false, false)
		assert_true(markers.size() >= 2, "Debe haber al menos 2 marcadores de nota en " + ruta)

		# Comprobar que ningún obstáculo invada la zona de corredor de seguridad (rango seguro [-960, 960])
		for col in altos.find_children("", "CollisionShape2D", true, false):
			var cs = col as CollisionShape2D
			assert_true(absf(cs.position.x) <= 960.0, "Obstáculo alto no debe invadir corredor X: " + cs.name)
			assert_true(absf(cs.position.y) <= 960.0, "Obstáculo alto no debe invadir corredor Y: " + cs.name)

		for col in bajos.find_children("", "CollisionShape2D", true, false):
			var cs = col as CollisionShape2D
			assert_true(absf(cs.position.x) <= 960.0, "Obstáculo bajo no debe invadir corredor X: " + cs.name)
			assert_true(absf(cs.position.y) <= 960.0, "Obstáculo bajo no debe invadir corredor Y: " + cs.name)

		nodo_var.free()


func test_mutacion_sectores_lejanos() -> void:
	var escena_escenario: PackedScene = load("res://escenas/escenario.tscn")
	var esc: Escenario = escena_escenario.instantiate() as Escenario

	var dummy_jugador := MockPersonajeParaEscenario.new()
	dummy_jugador.global_position = Vector2(-500, -500) # Sector NO
	esc.objetivo_jugador = dummy_jugador

	# Añadimos a un árbol temporal para simular ready y tree
	var root := Node2D.new()
	root.add_child(dummy_jugador)
	root.add_child(esc)
	esc._ready()

	# El cuadrante activo inicial debe ser NO
	assert_eq(esc.obtener_cuadrante_jugador(dummy_jugador.global_position), "NO", "Jugador debe estar en NO")
	var var_no_inicial: String = esc.variantes_activas.get("NO", "")

	# Ejecutamos mutación
	esc.mutar_sectores_lejanos()

	# El sector NO del jugador no debe haber sido alterado
	assert_eq(esc.variantes_activas.get("NO"), var_no_inicial, "El sector del jugador (NO) NO debe mutar")

	# Los otros 3 sectores deben tener variantes asignadas válidas
	assert_true(not esc.variantes_activas.get("NE", "").is_empty(), "Sector NE debe tener variante")
	assert_true(not esc.variantes_activas.get("SO", "").is_empty(), "Sector SO debe tener variante")
	assert_true(not esc.variantes_activas.get("SE", "").is_empty(), "Sector SE debe tener variante")

	root.free()


func test_efecto_niebla_mutacion() -> void:
	var escena_escenario: PackedScene = load("res://escenas/escenario.tscn")
	var esc: Escenario = escena_escenario.instantiate() as Escenario
	assert_true(esc != null, "Debe instanciarse el escenario")

	var efecto_niebla: EfectoNieblaMutacion = esc.get_node_or_null("EfectoNieblaMutacion") as EfectoNieblaMutacion
	assert_true(efecto_niebla != null, "Escenario debe contener EfectoNieblaMutacion")
	assert_eq(efecto_niebla.layer, 15, "EfectoNieblaMutacion debe estar en layer 15")

	# Verificar variables exportadas configurables
	assert_eq(efecto_niebla.duracion_cierre, 1.3, "duracion_cierre por defecto debe ser 1.3s")
	assert_eq(efecto_niebla.pausa_oscuridad, 0.4, "pausa_oscuridad por defecto debe ser 0.4s")
	assert_eq(efecto_niebla.duracion_apertura, 1.3, "duracion_apertura por defecto debe ser 1.3s")
	assert_eq(efecto_niebla.radio_despejado, 1.3, "radio_despejado por defecto debe ser 1.3")
	assert_eq(efecto_niebla.radio_cerrado, 0.05, "radio_cerrado por defecto debe ser 0.05")
	assert_eq(efecto_niebla.centro_pantalla, Vector2(0.5, 0.5), "centro_pantalla debe ser (0.5, 0.5)")
	assert_true("objetivo_jugador" in efecto_niebla, "efecto_niebla debe soportar objetivo_jugador")

	esc.free()


func test_protocolo_anti_atascamiento_enemigo() -> void:
	var escena_escenario: PackedScene = load("res://escenas/escenario.tscn")
	var esc: Escenario = escena_escenario.instantiate() as Escenario

	var escena_enemigo: PackedScene = load("res://escenas/enemigo.tscn")
	var dummy_enemigo: Enemigo = escena_enemigo.instantiate() as Enemigo
	dummy_enemigo.global_position = Vector2(500, 500) # Sector SE
	esc.objetivo_enemigo = dummy_enemigo

	var root := Node2D.new()
	root.add_child(dummy_enemigo)
	root.add_child(esc)
	esc._ready()

	# Simulamos que el enemigo se encuentra atrapado y necesita reubicación
	var pos_segura: Vector2 = esc._obtener_punto_seguro_en_sector("SE", dummy_enemigo.global_position)
	assert_true(pos_segura != Vector2.ZERO, "Debe encontrar un punto seguro en SE")
	assert_true(pos_segura.x > 0 and pos_segura.y > 0, "El punto seguro debe estar en el cuadrante SE")

	root.free()


func test_salto_jugador_sobre_capa_2() -> void:
	var escena_personaje: PackedScene = load("res://escenas/personaje.tscn")
	assert_true(escena_personaje != null, "La escena personaje.tscn debe poder cargarse")
	var p: Personaje = escena_personaje.instantiate() as Personaje

	var root := Node2D.new()
	root.add_child(p)

	# En reposo/suelo, colisiona con Capa 1 y Capa 2
	assert_true(p.get_collision_mask_value(1), "En suelo debe colisionar con Capa 1")
	assert_true(p.get_collision_mask_value(2), "En suelo debe colisionar con Capa 2")

	# Iniciar salto libre
	p._iniciar_salto_libre()
	assert_true(p.get_collision_mask_value(1), "En salto debe seguir colisionando con Capa 1")
	assert_false(p.get_collision_mask_value(2), "En salto DEBE ignorar Capa 2 (Obstaculos_Bajos)")

	# Finalizar salto libre
	p._finalizar_salto_libre(false)
	assert_true(p.get_collision_mask_value(1), "Al aterrizar debe restaurar Capa 1")
	assert_true(p.get_collision_mask_value(2), "Al aterrizar debe restaurar Capa 2")

	root.free()


func test_tileset_scenes_collection_y_tilemap_layer() -> void:
	var tileset: TileSet = load("res://recursos/tilesets/tileset_obstaculos.tres")
	assert_true(tileset != null, "El tileset_obstaculos.tres debe existir y cargar")

	# Asegurar o configurar fuente de colecciones de escenas si no existe
	var source: TileSetScenesCollectionSource = null
	if tileset.get_source_count() > 0:
		source = tileset.get_source(tileset.get_source_id(0)) as TileSetScenesCollectionSource

	if source == null:
		source = TileSetScenesCollectionSource.new()
		var arbol_scene: PackedScene = load("res://escenas/obstaculos/arbol.tscn")
		var roca_scene: PackedScene = load("res://escenas/obstaculos/roca.tscn")
		var tronco_scene: PackedScene = load("res://escenas/obstaculos/tronco_bajo.tscn")
		assert_true(arbol_scene != null, "arbol.tscn debe cargar")
		assert_true(roca_scene != null, "roca.tscn debe cargar")
		assert_true(tronco_scene != null, "tronco_bajo.tscn debe cargar")

		source.create_scene_tile(arbol_scene)
		source.create_scene_tile(roca_scene)
		source.create_scene_tile(tronco_scene)
		tileset.add_source(source)
		ResourceSaver.save(tileset, "res://recursos/tilesets/tileset_obstaculos.tres")

	assert_true(source != null, "Debe existir TileSetScenesCollectionSource en tileset")
	assert_true(source.get_scene_tiles_count() >= 3, "Debe contener al menos 3 escenas registradas (árbol, roca, tronco)")

	# Probar instanciación de un TileMapLayer con este TileSet
	var layer := TileMapLayer.new()
	layer.tile_set = tileset
	layer.y_sort_enabled = true
	assert_eq(layer.tile_set, tileset, "TileMapLayer debe tener asignado tileset_obstaculos")
	layer.free()
