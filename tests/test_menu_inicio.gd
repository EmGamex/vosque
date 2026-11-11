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

	assert_eq(menu.get("opcion_actual"), 1, "La opción inicial debe ser Jugar (1)")
	assert_false(menu.get("bloqueado"), "El menú no debe arrancar bloqueado")

	var seleccion = menu.get("seleccion")
	assert_true(seleccion != null, "Debe existir el controlador seleccion")
	var datos_opciones: Dictionary = seleccion.datos_opciones
	assert_true(datos_opciones.has(0), "Debe contener OPCIONES (0)")
	assert_true(datos_opciones.has(1), "Debe contener JUGAR (1)")
	assert_true(datos_opciones.has(2), "Debe contener CREDITOS (2)")

	var arbol_visual: Sprite2D = menu.get_node_or_null("Arboles/ArbolVisual") as Sprite2D
	assert_true(arbol_visual != null, "Debe existir el nodo ArbolVisual")
	assert_true(arbol_visual.material is ShaderMaterial, "ArbolVisual debe tener asignado ShaderMaterial")
	assert_true(datos_opciones[1].has("textura"), "Debe contener textura de JUGAR")

	var montana_1: Sprite2D = menu.get_node_or_null("Fondos/Montaña1") as Sprite2D
	assert_true(montana_1 != null, "Debe existir el nodo Fondos/Montaña1")
	assert_eq(montana_1.position, Vector2(0.0, 244.0), "Montaña 1 debe estar centrada horizontalmente en x=0")

	menu.free()


func test_navegacion_ciclica() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	# Estado inicial: JUGAR (1)
	assert_eq(menu.get("opcion_actual"), 1)

	# Navegar a la derecha (+1) -> CREDITOS (2)
	menu._navegar(1)
	assert_eq(menu.get("opcion_actual"), 2, "Navegar +1 desde JUGAR debe ir a CREDITOS")

	# Navegar a la derecha (+1) cíclico -> OPCIONES (0)
	menu._navegar(1)
	assert_eq(menu.get("opcion_actual"), 0, "Navegar +1 desde CREDITOS debe ciclar a OPCIONES")

	# Navegar a la izquierda (-1) cíclico -> CREDITOS (2)
	menu._navegar(-1)
	assert_eq(menu.get("opcion_actual"), 2, "Navegar -1 desde OPCIONES debe ciclar a CREDITOS")

	# Llamar a enfocar() debe restaurar a JUGAR (1)
	menu.enfocar()
	assert_eq(menu.get("opcion_actual"), 1, "enfocar() debe restablecer la opción a JUGAR")

	menu.free()


func test_senales_de_confirmacion() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	var senales_recibidas: Array[String] = []

	menu.connect("jugar_solicitado", func(): senales_recibidas.append("jugar"))
	menu.connect("opciones_solicitado", func(): senales_recibidas.append("opciones"))
	menu.connect("creditos_solicitado", func(): senales_recibidas.append("creditos"))

	# Confirmar estando en JUGAR (1)
	menu.set("opcion_actual", 1)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("jugar"), "Debe emitir jugar_solicitado")
	assert_true(menu.get("bloqueado"), "Confirmar Jugar debe bloquear el menú para evitar doble click")

	# Confirmar OPCIONES (0)
	menu.set("bloqueado", false)
	menu.set("opcion_actual", 0)
	menu._confirmar_opcion()
	assert_true(senales_recibidas.has("opciones"), "Debe emitir opciones_solicitado")

	# Confirmar CREDITOS (2)
	menu.set("opcion_actual", 2)
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

	# Comprobamos que capturó la posición del editor en el controlador de parallax
	var parallax = menu.get("parallax")
	assert_true(parallax != null, "Debe existir controlador parallax")
	assert_eq(parallax.pos_inicial_montana_1, posicion_custom, "Debe haber capturado la posición inicial del nodo")

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
	assert_eq(menu.get("estado"), 0, "Debe iniciar en estado PRESENTACION (0)")

	# Iniciar descenso
	menu.iniciar_descenso()
	assert_eq(menu.get("estado"), 1, "iniciar_descenso debe pasar a CINEMATICA_BAJANDO (1)")
	assert_eq(animador.speed_scale, 1.0, "Velocidad normal debe ser 1.0")

	# Probar skip de cinemática
	menu.skipear_cinematica()
	assert_eq(animador.speed_scale, menu.get("multiplicador_velocidad_skip"), "skipear_cinematica debe acelerar el animador")

	# Finalización de la animación de descenso
	menu._on_animacion_terminada(&"bajar_al_bosque")
	assert_eq(menu.get("estado"), 2, "Al terminar la animación debe pasar a MENU_ACTIVO (2)")
	assert_eq(animador.speed_scale, 1.0, "Velocidad debe restaurarse a 1.0")
	assert_eq(camara.position, Vector2(540.0, 540.0), "Cámara debe encuadrar el bosque (540, 540)")

	# Probar regreso a presentación (presionar Escape en MENU_ACTIVO)
	menu.regresar_a_presentacion()
	assert_eq(menu.get("estado"), 3, "regresar_a_presentacion debe pasar a CINEMATICA_SUBIENDO (3)")
	assert_true(menu.get("bloqueado"), "El menú debe bloquearse durante la cinemática de subida")

	# Probar skip de subida
	menu.skipear_cinematica()
	assert_eq(animador.speed_scale, menu.get("multiplicador_velocidad_skip"), "skipear debe acelerar la subida")

	# Finalización de la animación de subida
	menu._on_animacion_terminada(&"bajar_al_bosque")
	assert_eq(menu.get("estado"), 0, "Al terminar de subir debe volver a PRESENTACION (0)")
	assert_false(menu.get("bloqueado"), "El menú debe desbloquearse al llegar a PRESENTACION")
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
		var parallax = menu.get("parallax")
		assert_true(parallax != null, "Debe existir controlador parallax")
		parallax.offset_base = Vector2(95.0, 0.0)
		parallax.rotacion_base = deg_to_rad(1.2)
		menu._process(0.1)

		# Comprobar que el parallax desplaza y rota los emisores con la linterna
		assert_true(p_nubes.position != Vector2.ZERO, "Las nubes deben tener posición asignada")
		assert_true(p_estrellas.position != Vector2.ZERO, "Las estrellas deben tener posición asignada")
		assert_true(abs(p_nubes.rotation) > 0.0001, "Las nubes deben rotar con el parallax")
		assert_true(abs(p_estrellas.rotation) > 0.0001, "Las estrellas deben rotar con el parallax")

	menu.free()


func test_transicion_shader_crossfade() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	# Añadir temporalmente al árbol para permitir animación con tweens
	var root: Window = Engine.get_main_loop().root if Engine.get_main_loop() is SceneTree else null
	if root != null:
		root.add_child(menu)

	var arbol_visual: Sprite2D = menu.get_node_or_null("Arboles/ArbolVisual") as Sprite2D
	assert_true(arbol_visual != null, "Debe existir ArbolVisual")
	var mat: ShaderMaterial = arbol_visual.material as ShaderMaterial
	assert_true(mat != null, "Debe tener ShaderMaterial")

	var seleccion = menu.get("seleccion")
	assert_true(seleccion != null, "Debe existir controlador seleccion")
	var datos_opciones: Dictionary = seleccion.datos_opciones
	var tex_jugar: Texture2D = datos_opciones[1]["textura"]
	var tex_creditos: Texture2D = datos_opciones[2]["textura"]

	assert_eq(arbol_visual.texture, tex_jugar, "Textura inicial debe ser Jugar")
	assert_eq(mat.get_shader_parameter("progreso"), 1.0, "Progreso inicial debe ser 1.0")

	# Navegamos hacia Créditos (+1) con animación
	menu._navegar(1)

	# El shader debe configurar textura_anterior con Jugar, textura activa Créditos, y arrancar progreso en 0.0
	assert_eq(arbol_visual.texture, tex_creditos, "Textura del sprite debe actualizarse a Créditos")
	assert_eq(mat.get_shader_parameter("textura_anterior"), tex_jugar, "textura_anterior en shader debe ser Jugar")
	assert_eq(mat.get_shader_parameter("progreso"), 0.0, "Progreso al iniciar transición debe arrancar en 0.0")

	if root != null and menu.get_parent() == root:
		root.remove_child(menu)
	menu.free()


func test_iconos_menu_opacidad_y_organizacion() -> void:
	var menu: Control = _crear_instancia_menu()
	menu._ready()

	# 1. Comprobar que los nodos de iconos existen reorganizados bajo Textos/Iconos
	var icono_conf: Sprite2D = menu.get_node_or_null("Textos/Iconos/IconoConfiguracion") as Sprite2D
	var icono_jugar: Sprite2D = menu.get_node_or_null("Textos/Iconos/IconoJugar") as Sprite2D
	var icono_cred: Sprite2D = menu.get_node_or_null("Textos/Iconos/IconoCreditos") as Sprite2D

	assert_true(icono_conf != null, "Debe existir Textos/Iconos/IconoConfiguracion")
	assert_true(icono_jugar != null, "Debe existir Textos/Iconos/IconoJugar")
	assert_true(icono_cred != null, "Debe existir Textos/Iconos/IconoCreditos")

	# 2. Inicialmente la opción es JUGAR: JUGAR debe tener alpha 1.0, y las no seleccionadas alpha 0.16
	assert_true(is_equal_approx(icono_jugar.self_modulate.a, 1.0), "IconoJugar debe tener alpha 1.0 al estar seleccionado")
	assert_true(is_equal_approx(icono_conf.self_modulate.a, 0.16), "IconoConfiguracion debe tener alpha 0.16 al no estar seleccionado")
	assert_true(is_equal_approx(icono_cred.self_modulate.a, 0.16), "IconoCreditos debe tener alpha 0.16 al no estar seleccionado")

	# 3. Navegar a CREDITOS (+1)
	menu._navegar(1)
	assert_true(is_equal_approx(icono_cred.self_modulate.a, 1.0), "IconoCreditos debe tener alpha 1.0 al seleccionarse")
	assert_true(is_equal_approx(icono_jugar.self_modulate.a, 0.16), "IconoJugar debe pasar a alpha 0.16 al deseleccionarse")
	assert_true(is_equal_approx(icono_conf.self_modulate.a, 0.16), "IconoConfiguracion debe permanecer en alpha 0.16")

	# 4. Navegar a OPCIONES (+1 cíclico)
	menu._navegar(1)
	assert_true(is_equal_approx(icono_conf.self_modulate.a, 1.0), "IconoConfiguracion debe tener alpha 1.0 al seleccionarse")
	assert_true(is_equal_approx(icono_cred.self_modulate.a, 0.16), "IconoCreditos debe pasar a alpha 0.16 al deseleccionarse")
	assert_true(is_equal_approx(icono_jugar.self_modulate.a, 0.16), "IconoJugar debe permanecer en alpha 0.16")

	menu.free()


func test_animacion_ir_a_opciones_estira_fondos_y_no_arboles() -> void:
	var menu: Control = _crear_instancia_menu()
	var animador: AnimationPlayer = menu.get_node_or_null("AnimadorCinematica") as AnimationPlayer
	assert_true(animador != null, "Debe existir AnimadorCinematica")
	assert_true(animador.has_animation("ir_a_opciones"), "Debe existir la animación ir_a_opciones")

	var anim: Animation = animador.get_animation("ir_a_opciones")
	var pistas_scale_fondos: Array[String] = []
	var pistas_arboles: Array[String] = []
	var escala_final_montana_1: float = 0.0

	for i in range(anim.get_track_count()):
		var ruta: String = str(anim.track_get_path(i))
		if "scale" in ruta:
			if "Fondos" in ruta:
				pistas_scale_fondos.append(ruta)
			if "Arbol" in ruta or "arbol" in ruta:
				pistas_arboles.append(ruta)
		if ruta == "Fondos/Montaña1:scale:x":
			var key_count: int = anim.track_get_key_count(i)
			if key_count > 0:
				escala_final_montana_1 = float(anim.track_get_key_value(i, key_count - 1))

	assert_true(pistas_scale_fondos.has("Fondos/FondoDegradado:scale:x"), "FondoDegradado debe tener pista de escala X")
	assert_true(pistas_scale_fondos.has("Fondos/Montaña2:scale:x"), "Montaña2 debe tener pista de escala X")
	assert_true(pistas_scale_fondos.has("Fondos/Montaña1:scale:x"), "Montaña1 debe tener pista de escala X")
	assert_true(escala_final_montana_1 >= 1.25, "Montaña 1 debe escalar al menos a 1.25 para cubrir la pantalla en opciones sin mostrar el borde del sprite")
	assert_eq(pistas_arboles.size(), 0, "No debe estirarse ningún nodo relacionado a los árboles")

	menu.free()


func test_animacion_ir_a_creditos_estira_fondos_y_cobertura_derecha() -> void:
	var menu: Control = _crear_instancia_menu()
	var animador: AnimationPlayer = menu.get_node_or_null("AnimadorCinematica") as AnimationPlayer
	assert_true(animador != null, "Debe existir AnimadorCinematica")
	assert_true(animador.has_animation("ir_a_creditos"), "Debe existir la animación ir_a_creditos")

	var anim: Animation = animador.get_animation("ir_a_creditos")
	var pistas_scale_fondos: Array[String] = []
	var pistas_arboles: Array[String] = []
	var escala_final_degradado: float = 0.0
	var escala_final_montana_1: float = 0.0
	var destino_camara_x: float = 0.0

	for i in range(anim.get_track_count()):
		var ruta: String = str(anim.track_get_path(i))
		if ruta == "CamaraMenu:position:x":
			assert_eq(anim.track_get_type(i), Animation.TYPE_BEZIER, "Pista de cámara debe ser bezier")
			var key_count: int = anim.track_get_key_count(i)
			if key_count > 0:
				destino_camara_x = anim.bezier_track_get_key_value(i, key_count - 1)
		if "scale" in ruta:
			if "Fondos" in ruta:
				pistas_scale_fondos.append(ruta)
			if "Arbol" in ruta or "arbol" in ruta:
				pistas_arboles.append(ruta)
		if ruta == "Fondos/FondoDegradado:scale:x":
			var key_count: int = anim.track_get_key_count(i)
			if key_count > 0:
				escala_final_degradado = float(anim.track_get_key_value(i, key_count - 1))
		if ruta == "Fondos/Montaña1:scale:x":
			var key_count: int = anim.track_get_key_count(i)
			if key_count > 0:
				escala_final_montana_1 = float(anim.track_get_key_value(i, key_count - 1))

	assert_eq(destino_camara_x, 1620.0, "La cámara debe desplazarse a x=1620.0 en créditos")
	assert_true(pistas_scale_fondos.has("Fondos/FondoDegradado:scale:x"), "FondoDegradado debe tener pista de escala X")
	assert_true(pistas_scale_fondos.has("Fondos/Montaña2:scale:x"), "Montaña2 debe tener pista de escala X")
	assert_true(pistas_scale_fondos.has("Fondos/Montaña1:scale:x"), "Montaña1 debe tener pista de escala X")
	assert_true(escala_final_degradado >= 1.35, "Fondo degradado debe escalar al menos a 1.35 para cubrir la derecha")
	assert_true(escala_final_montana_1 >= 1.25, "Montaña 1 debe escalar al menos a 1.25 para cubrir la pantalla en créditos")
	assert_eq(pistas_arboles.size(), 0, "No debe estirarse ningún nodo relacionado a los árboles")

	menu.free()


func test_flujo_estados_creditos() -> void:
	var menu: Control = _crear_instancia_menu()
	menu.add_to_group("modo_test")
	menu._ready()

	var menu_opciones: MenuOpciones = menu.get_node_or_null("MenuOpciones") as MenuOpciones
	var menu_creditos: MenuCreditos = menu.get_node_or_null("MenuCreditos") as MenuCreditos
	assert_true(menu_opciones != null, "Debe existir MenuOpciones")
	assert_true(menu_creditos != null, "Debe existir MenuCreditos")

	# Inicialmente ambos deben estar ocultos
	assert_false(menu_opciones.visible, "MenuOpciones debe iniciar con visible = false")
	assert_false(menu_creditos.visible, "MenuCreditos debe iniciar con visible = false")

	# Llevar a MENU_ACTIVO simulando fin de descenso
	menu.iniciar_descenso()
	menu._on_animacion_terminada(&"bajar_al_bosque")
	assert_eq(menu.get("estado"), 2, "Debe estar en MENU_ACTIVO")

	# Solicitar créditos: visible se activa para la animación
	menu.set("opcion_actual", 2)
	menu._confirmar_opcion()
	assert_eq(menu.get("estado"), 6, "Debe pasar a TRANSICION_CREDITOS (6)")
	assert_true(menu.get("bloqueado"), "Menú debe estar bloqueado durante la transición a créditos")
	assert_true(menu_creditos.visible, "MenuCreditos debe ser visible durante la transición")
	assert_false(menu_opciones.visible, "MenuOpciones debe permanecer oculto")

	# Simular llegada a la derecha (cámara en 1620)
	var camara: Camera2D = menu.get_node("CamaraMenu") as Camera2D
	camara.position = Vector2(1620.0, 540.0)
	menu._on_animacion_terminada(&"ir_a_creditos")
	assert_eq(menu.get("estado"), 7, "Debe pasar a EN_CREDITOS (7)")
	assert_true(menu_creditos.visible, "MenuCreditos debe permanecer visible en EN_CREDITOS")
	assert_false(menu_opciones.visible, "MenuOpciones debe permanecer oculto en EN_CREDITOS")

	# Volver de créditos
	menu._on_volver_de_creditos()
	assert_eq(menu.get("estado"), 6, "Debe volver a TRANSICION_CREDITOS (6)")

	# Simular regreso al centro (cámara en 540)
	camara.position = Vector2(540.0, 540.0)
	menu._on_animacion_terminada(&"ir_a_creditos")
	assert_eq(menu.get("estado"), 2, "Debe volver a MENU_ACTIVO (2)")
	assert_false(menu.get("bloqueado"), "Menú debe desbloquearse tras volver a MENU_ACTIVO")
	assert_false(menu_creditos.visible, "MenuCreditos debe volver a visible = false tras regresar")
	assert_false(menu_opciones.visible, "MenuOpciones debe permanecer visible = false")

	menu.free()


func test_flujo_estados_opciones() -> void:
	var menu: Control = _crear_instancia_menu()
	menu.add_to_group("modo_test")
	menu._ready()

	var menu_opciones: MenuOpciones = menu.get_node_or_null("MenuOpciones") as MenuOpciones
	var menu_creditos: MenuCreditos = menu.get_node_or_null("MenuCreditos") as MenuCreditos

	# Llevar a MENU_ACTIVO
	menu.iniciar_descenso()
	menu._on_animacion_terminada(&"bajar_al_bosque")

	# Solicitar opciones
	menu.set("opcion_actual", 0)
	menu._confirmar_opcion()
	assert_eq(menu.get("estado"), 4, "Debe pasar a TRANSICION_OPCIONES (4)")
	assert_true(menu_opciones.visible, "MenuOpciones debe ser visible durante la transición")
	assert_false(menu_creditos.visible, "MenuCreditos debe permanecer oculto")

	# Simular llegada a la izquierda (cámara en -540)
	var camara: Camera2D = menu.get_node("CamaraMenu") as Camera2D
	camara.position = Vector2(-540.0, 540.0)
	menu._on_animacion_terminada(&"ir_a_opciones")
	assert_eq(menu.get("estado"), 5, "Debe pasar a EN_OPCIONES (5)")
	assert_true(menu_opciones.visible, "MenuOpciones debe estar visible en EN_OPCIONES")
	assert_false(menu_creditos.visible, "MenuCreditos debe estar oculto en EN_OPCIONES")

	# Volver de opciones
	menu._on_volver_de_opciones()
	assert_eq(menu.get("estado"), 4, "Debe pasar a TRANSICION_OPCIONES (4)")

	# Simular regreso al centro
	camara.position = Vector2(540.0, 540.0)
	menu._on_animacion_terminada(&"ir_a_opciones")
	assert_eq(menu.get("estado"), 2, "Debe volver a MENU_ACTIVO (2)")
	assert_false(menu_opciones.visible, "MenuOpciones debe volver a visible = false tras regresar")
	assert_false(menu_creditos.visible, "MenuCreditos debe permanecer visible = false")

	menu.free()


