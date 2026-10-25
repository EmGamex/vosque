@tool
class_name TestMenuInicio
extends McpTestSuite

## Pruebas unitarias para MenuInicio (arquitectura, navegación por señales y parallax).

func suite_name() -> String:
	return "menu_inicio"


func _crear_instancia_menu() -> Control:
	var escena: PackedScene = load("res://escenas/menu_inicio.tscn")
	var menu: Control = escena.instantiate() as Control
	return menu


func test_instanciacion_y_nodos_base() -> void:
	var menu: Control = _crear_instancia_menu()
	assert_true(menu != null, "La escena debe instanciarse")

	menu._ready()

	assert_eq(menu.get("_opcion_actual"), 1, "La opción inicial debe ser Jugar (1)")
	assert_false(menu.get("_bloqueado"), "El menú no debe arrancar bloqueado")

	var datos_opciones: Dictionary = menu.get("_datos_opciones")
	assert_true(datos_opciones.has(0), "Debe contener OPCIONES (0)")
	assert_true(datos_opciones.has(1), "Debe contener JUGAR (1)")
	assert_true(datos_opciones.has(2), "Debe contener CREDITOS (2)")

	var arbol_jugar: Sprite2D = datos_opciones[1]["arbol"]
	var arbol_opciones: Sprite2D = datos_opciones[0]["arbol"]
	assert_eq(arbol_jugar.modulate.a, 1.0, "Árbol Jugar debe tener alpha 1.0 al estar seleccionado")
	assert_eq(arbol_opciones.modulate.a, 0.0, "Árbol Opciones debe tener alpha 0.0 al no estar seleccionado")

	menu.free()


func test_navegacion_ciclica() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	# Estado inicial: JUGAR (1)
	assert_eq(menu.get("_opcion_actual"), 1)

	# Navegar a la derecha (+1) -> CREDITOS (2)
	menu._navegar(1)
	assert_eq(menu.get("_opcion_actual"), 2, "Navegar +1 desde JUGAR debe ir a CREDITOS")

	# Navegar a la derecha (+1) cíclico -> OPCIONES (0)
	menu._navegar(1)
	assert_eq(menu.get("_opcion_actual"), 0, "Navegar +1 desde CREDITOS debe ciclar a OPCIONES")

	# Navegar a la izquierda (-1) cíclico -> CREDITOS (2)
	menu._navegar(-1)
	assert_eq(menu.get("_opcion_actual"), 2, "Navegar -1 desde OPCIONES debe ciclar a CREDITOS")

	# Llamar a enfocar() debe restaurar a JUGAR (1)
	menu.enfocar()
	assert_eq(menu.get("_opcion_actual"), 1, "enfocar() debe restablecer la opción a JUGAR")

	menu.free()


func test_senales_de_confirmacion() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	var senales_recibidas: Array[String] = []

	menu.connect("jugar_solicitado", func(): senales_recibidas.append("jugar"))
	menu.connect("opciones_solicitado", func(): senales_recibidas.append("opciones"))
	menu.connect("creditos_solicitado", func(): senales_recibidas.append("creditos"))

	# Confirmar estando en JUGAR (1)
	menu.set("_opcion_actual", 1)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("jugar"), "Debe emitir jugar_solicitado")
	assert_true(menu.get("_bloqueado"), "Confirmar Jugar debe bloquear el menú para evitar doble click")

	# Confirmar OPCIONES (0)
	menu.set("_bloqueado", false)
	menu.set("_opcion_actual", 0)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("opciones"), "Debe emitir opciones_solicitado")

	# Confirmar CREDITOS (2)
	menu.set("_opcion_actual", 2)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("creditos"), "Debe emitir creditos_solicitado")

	menu.free()


func test_parallax_respeta_posiciones_capturadas() -> void:
	var menu: Control = _crear_instancia_menu()

	# Modificamos la posición de un nodo antes de _ready() simulando un cambio en el editor
	var montana: Sprite2D = menu.get_node("Fondos/Montaña1") as Sprite2D
	var posicion_custom: Vector2 = Vector2(-20.0, 310.0)
	montana.position = posicion_custom

	menu._ready()

	# Comprobamos que capturó la posición del editor
	assert_eq(menu.get("_pos_inicial_montana_1"), posicion_custom, "Debe haber capturado la posición inicial del nodo")

	# Corremos un frame de _process
	menu.add_to_group("modo_test")
	menu._process(0.1)

	# La posición actual debe ser la inicial más el delta de parallax (no Vector2(-4, 244) hardcodeado)
	var diferencia: Vector2 = montana.position - posicion_custom
	assert_true(diferencia.length() < 50.0, "El desplazamiento debe estar acotado al parallax alrededor de la posición custom")
	assert_true(montana.position != Vector2(-4.0, 244.0), "No debe haber sido forzado a la constante anterior")

	menu.free()


func test_nodos_y_estado_cinematica() -> void:
	var menu: Control = _crear_instancia_menu()
	menu.add_to_group("modo_test")
	menu._ready()

	# Comprobar presencia de los nuevos nodos cinemáticos
	var camara: Camera2D = menu.get_node_or_null("CamaraMenu") as Camera2D
	var animador: AnimationPlayer = menu.get_node_or_null("AnimadorCinematica") as AnimationPlayer
	var presentacion: Control = menu.get_node_or_null("Presentacion") as Control
	var fondo_pres: Sprite2D = menu.get_node_or_null("Fondos/FondoPresentacion") as Sprite2D

	assert_true(camara != null, "Debe existir CamaraMenu")
	assert_true(animador != null, "Debe existir AnimadorCinematica")
	assert_true(presentacion != null, "Debe existir Presentacion")
	assert_true(fondo_pres != null, "Debe existir FondoPresentacion")

	assert_true(animador.has_animation("esperando_inicio"), "Debe tener animación esperando_inicio")
	assert_true(animador.has_animation("bajar_al_bosque"), "Debe tener animación bajar_al_bosque")

	# Estado inicial debe ser PRESENTACION
	assert_eq(menu.get("_estado"), 0, "Debe iniciar en estado PRESENTACION (0)")

	# Iniciar descenso
	menu.iniciar_descenso()
	assert_eq(menu.get("_estado"), 1, "iniciar_descenso debe pasar a CINEMATICA_BAJANDO (1)")
	assert_eq(animador.speed_scale, 1.0, "Velocidad normal debe ser 1.0")

	# Probar skip de cinemática
	menu.skipear_cinematica()
	assert_eq(animador.speed_scale, menu.get("multiplicador_velocidad_skip"), "skipear_cinematica debe acelerar el animador")

	# Finalización de la animación de descenso
	menu._on_animacion_terminada(&"bajar_al_bosque")
	assert_eq(menu.get("_estado"), 2, "Al terminar la animación debe pasar a MENU_ACTIVO (2)")
	assert_eq(animador.speed_scale, 1.0, "Velocidad debe restaurarse a 1.0")
	assert_eq(camara.position, Vector2(540.0, 540.0), "Cámara debe encuadrar el bosque (540, 540)")

	# Probar regreso a presentación (presionar Escape en MENU_ACTIVO)
	menu.regresar_a_presentacion()
	assert_eq(menu.get("_estado"), 3, "regresar_a_presentacion debe pasar a CINEMATICA_SUBIENDO (3)")
	assert_true(menu.get("_bloqueado"), "El menú debe bloquearse durante la cinemática de subida")

	# Probar skip de subida
	menu.skipear_cinematica()
	assert_eq(animador.speed_scale, menu.get("multiplicador_velocidad_skip"), "skipear debe acelerar la subida")

	# Finalización de la animación de subida
	menu._on_animacion_terminada(&"bajar_al_bosque")
	assert_eq(menu.get("_estado"), 0, "Al terminar de subir debe volver a PRESENTACION (0)")
	assert_false(menu.get("_bloqueado"), "El menú debe desbloquearse al llegar a PRESENTACION")
	assert_eq(camara.position, Vector2(540.0, -540.0), "Cámara debe encuadrar el cielo (540, -540)")
	assert_eq(presentacion.modulate.a, 1.0, "Presentación debe restaurar opacidad 1.0")
	var textos: Control = menu.get_node_or_null("Textos") as Control
	if textos != null:
		assert_eq(textos.modulate.a, 0.0, "Textos de opciones deben estar en 0.0 al volver a inicio")

	menu.free()


func test_pistas_bezier_configuradas() -> void:
	var menu: Control = _crear_instancia_menu()
	var animador: AnimationPlayer = menu.get_node_or_null("AnimadorCinematica") as AnimationPlayer
	assert_true(animador != null, "Debe existir AnimadorCinematica")
	if animador != null and animador.has_animation("bajar_al_bosque"):
		var anim: Animation = animador.get_animation("bajar_al_bosque")
		var tiene_bezier_y: bool = false
		for i in range(anim.get_track_count()):
			if anim.track_get_path(i) == ^"CamaraMenu:position:y" and anim.track_get_type(i) == Animation.TYPE_BEZIER:
				tiene_bezier_y = true
				break
		assert_true(tiene_bezier_y, "La pista CamaraMenu:position:y debe ser de tipo TYPE_BEZIER")
	menu.free()


func test_particulas_cielo_y_configurabilidad() -> void:
	var menu: Control = _crear_instancia_menu()
	menu.add_to_group("modo_test")
	menu._ready()

	var p_estrellas: CPUParticles2D = menu.get_node_or_null("Fondos/ParticulasEstrellas") as CPUParticles2D
	var p_nubes: CPUParticles2D = menu.get_node_or_null("Fondos/ParticulasNubes") as CPUParticles2D

	assert_true(p_estrellas != null, "Debe existir el nodo Fondos/ParticulasEstrellas")
	assert_true(p_nubes != null, "Debe existir el nodo Fondos/ParticulasNubes")

	if p_estrellas != null and p_nubes != null:
		assert_true(p_estrellas.preprocess > 0.0, "Las estrellas deben tener preprocess para cargar pobladas")
		assert_true(p_nubes.preprocess > 0.0, "Las nubes deben tener preprocess para cargar pobladas")

		# Comprobar configurabilidad reactiva de estrellas
		menu.set("estrellas_cantidad", 28)
		assert_eq(p_estrellas.amount, 28, "Cambiar estrellas_cantidad debe actualizar el amount del emisor")

		menu.set("habilitar_estrellas", false)
		assert_false(p_estrellas.emitting, "Deshabilitar estrellas debe apagar emitting")

		menu.set("habilitar_estrellas", true)
		assert_true(p_estrellas.emitting, "Rehabilitar estrellas debe encender emitting")

		# Comprobar configurabilidad reactiva de nubes
		var color_prueba: Color = Color(0.5, 0.6, 0.9, 0.25)
		menu.set("nubes_color", color_prueba)
		assert_eq(p_nubes.color, color_prueba, "Cambiar nubes_color debe actualizar color del emisor")

		menu.set("nubes_cantidad", 14)
		assert_eq(p_nubes.amount, 14, "Cambiar nubes_cantidad debe actualizar amount del emisor")

		# Comprobar parallax en _process (traslación y rotación reactiva)
		menu.set("_offset_base", Vector2(95.0, 0.0))
		menu.set("_rotacion_base", deg_to_rad(1.2))
		menu._process(0.1)

		# Comprobar que el parallax desplaza y rota los emisores con la linterna
		assert_true(p_nubes.position != Vector2.ZERO, "Las nubes deben tener posición asignada")
		assert_true(p_estrellas.position != Vector2.ZERO, "Las estrellas deben tener posición asignada")
		assert_true(abs(p_nubes.rotation) > 0.0001, "Las nubes deben rotar con el parallax")
		assert_true(abs(p_estrellas.rotation) > 0.0001, "Las estrellas deben rotar con el parallax")

	menu.free()




