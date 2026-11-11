class_name MenuCinematica
extends RefCounted

## Administrador del flujo cinemático de cámara y transiciones cielo/bosque/opciones.

var estado: MenuConstantes.EstadoMenu = MenuConstantes.EstadoMenu.PRESENTACION
var habilitar_presentacion: bool = true
var multiplicador_velocidad_skip: float = 4.0

var camara: Camera2D
var animador: AnimationPlayer
var presentacion: Control
var fondo_presentacion: Sprite2D
var textos_nodo: Control
var efecto_motion_blur: ColorRect
var menu_opciones: MenuOpciones
var menu_creditos: MenuCreditos


func inicializar_nodos(
	p_camara: Camera2D,
	p_animador: AnimationPlayer,
	p_presentacion: Control,
	p_fondo_presentacion: Sprite2D,
	p_textos_nodo: Control,
	p_efecto_motion_blur: ColorRect = null,
	p_menu_opciones: MenuOpciones = null,
	p_menu_creditos: MenuCreditos = null
) -> void:
	camara = p_camara
	animador = p_animador
	presentacion = p_presentacion
	fondo_presentacion = p_fondo_presentacion
	textos_nodo = p_textos_nodo
	efecto_motion_blur = p_efecto_motion_blur
	menu_opciones = p_menu_opciones
	menu_creditos = p_menu_creditos

	# En plataforma Web, desactivar Motion Blur para evitar el lag de compilación
	# de hint_screen_texture y el consecuente tartamudeo en el audio de WebAssembly.
	if efecto_motion_blur != null and (OS.has_feature("web") or OS.get_name() == "Web"):
		efecto_motion_blur.visible = false
		efecto_motion_blur.material = null

	if menu_opciones != null:
		menu_opciones.modulate.a = 0.0
		menu_opciones.visible = false
	if menu_creditos != null:
		menu_creditos.modulate.a = 0.0
		menu_creditos.visible = false


func iniciar_presentacion(es_editor: bool, en_grupo_test: bool) -> void:
	if not habilitar_presentacion or (es_editor and not en_grupo_test):
		estado = MenuConstantes.EstadoMenu.MENU_ACTIVO
		if camara != null:
			camara.position = Vector2(540.0, 540.0)
		if presentacion != null:
			presentacion.modulate.a = 0.0
		if fondo_presentacion != null:
			fondo_presentacion.modulate.a = 0.0
		if textos_nodo != null:
			textos_nodo.modulate.a = 1.0
		if menu_opciones != null:
			menu_opciones.modulate.a = 0.0
			menu_opciones.visible = false
			menu_opciones.desactivar()
		if menu_creditos != null:
			menu_creditos.modulate.a = 0.0
			menu_creditos.visible = false
			menu_creditos.desactivar()
		return

	estado = MenuConstantes.EstadoMenu.PRESENTACION
	if camara != null:
		camara.position = Vector2(540.0, -540.0)
	if presentacion != null:
		presentacion.modulate.a = 1.0
	if fondo_presentacion != null:
		fondo_presentacion.modulate.a = 1.0
	if textos_nodo != null:
		textos_nodo.modulate.a = 0.0
	if menu_opciones != null:
		menu_opciones.modulate.a = 0.0
		menu_opciones.visible = false
		menu_opciones.desactivar()
	if menu_creditos != null:
		menu_creditos.modulate.a = 0.0
		menu_creditos.visible = false
		menu_creditos.desactivar()

	if animador != null and animador.has_animation("esperando_inicio"):
		animador.speed_scale = 1.0
		animador.play("esperando_inicio")


func iniciar_descenso(on_terminada_cb: Callable) -> void:
	if estado != MenuConstantes.EstadoMenu.PRESENTACION:
		return

	estado = MenuConstantes.EstadoMenu.CINEMATICA_BAJANDO
	if animador != null and animador.has_animation("bajar_al_bosque"):
		animador.speed_scale = 1.0
		animador.play("bajar_al_bosque")
	else:
		on_terminada_cb.call(&"bajar_al_bosque")


func regresar_a_presentacion(on_terminada_cb: Callable) -> void:
	estado = MenuConstantes.EstadoMenu.CINEMATICA_SUBIENDO

	if animador != null and animador.has_animation("bajar_al_bosque"):
		animador.speed_scale = 1.0
		animador.play_backwards("bajar_al_bosque")
	else:
		on_terminada_cb.call(&"bajar_al_bosque")


func ir_a_opciones(on_terminada_cb: Callable) -> void:
	estado = MenuConstantes.EstadoMenu.TRANSICION_OPCIONES
	if menu_opciones != null:
		menu_opciones.visible = true
	_ejecutar_animacion_panel("ir_a_opciones", on_terminada_cb, false)


func regresar_de_opciones(on_terminada_cb: Callable) -> void:
	estado = MenuConstantes.EstadoMenu.TRANSICION_OPCIONES
	if menu_opciones != null:
		menu_opciones.desactivar()
	_ejecutar_animacion_panel("ir_a_opciones", on_terminada_cb, true)


func ir_a_creditos(on_terminada_cb: Callable) -> void:
	estado = MenuConstantes.EstadoMenu.TRANSICION_CREDITOS
	if menu_creditos != null:
		menu_creditos.visible = true
	_ejecutar_animacion_panel("ir_a_creditos", on_terminada_cb, false)


func regresar_de_creditos(on_terminada_cb: Callable) -> void:
	estado = MenuConstantes.EstadoMenu.TRANSICION_CREDITOS
	if menu_creditos != null:
		menu_creditos.desactivar()
	_ejecutar_animacion_panel("ir_a_creditos", on_terminada_cb, true)


func _ejecutar_animacion_panel(nombre_anim: String, on_terminada_cb: Callable, reversa: bool) -> void:
	if animador != null and animador.has_animation(nombre_anim):
		animador.speed_scale = 1.0
		if reversa:
			animador.play_backwards(nombre_anim)
		else:
			animador.play(nombre_anim)
	else:
		on_terminada_cb.call(StringName(nombre_anim))


func skipear_cinematica() -> void:
	if (estado == MenuConstantes.EstadoMenu.CINEMATICA_BAJANDO or \
		estado == MenuConstantes.EstadoMenu.CINEMATICA_SUBIENDO or \
		estado == MenuConstantes.EstadoMenu.TRANSICION_OPCIONES or \
		estado == MenuConstantes.EstadoMenu.TRANSICION_CREDITOS) and \
		animador != null and animador.is_playing():
		animador.speed_scale = multiplicador_velocidad_skip


func procesar_animacion_terminada(nombre: StringName) -> bool:
	if nombre == &"bajar_al_bosque":
		if estado == MenuConstantes.EstadoMenu.CINEMATICA_SUBIENDO:
			estado = MenuConstantes.EstadoMenu.PRESENTACION
			if animador != null:
				animador.speed_scale = 1.0
			if camara != null:
				camara.position = Vector2(540.0, -540.0)
			if presentacion != null:
				presentacion.modulate.a = 1.0
			if fondo_presentacion != null:
				fondo_presentacion.modulate.a = 1.0
			if textos_nodo != null:
				textos_nodo.modulate.a = 0.0
			if animador != null and animador.has_animation("esperando_inicio"):
				animador.play("esperando_inicio")
			return true # Volvió a presentación
		else:
			estado = MenuConstantes.EstadoMenu.MENU_ACTIVO
			if animador != null:
				animador.speed_scale = 1.0
			if camara != null:
				camara.position = Vector2(540.0, 540.0)
			if textos_nodo != null:
				textos_nodo.modulate.a = 1.0
			return false # Llegó a menú activo

	elif nombre == &"ir_a_opciones":
		if animador != null:
			animador.speed_scale = 1.0
		if estado == MenuConstantes.EstadoMenu.TRANSICION_OPCIONES:
			# Comprobamos si la cámara llegó a la izquierda (-540) o volvió al centro (540)
			if camara != null and camara.position.x < 0.0:
				estado = MenuConstantes.EstadoMenu.EN_OPCIONES
				if menu_opciones != null:
					menu_opciones.visible = true
					menu_opciones.modulate.a = 1.0
					menu_opciones.activar()
				if menu_creditos != null:
					menu_creditos.visible = false
				if textos_nodo != null:
					textos_nodo.modulate.a = 0.0
			else:
				estado = MenuConstantes.EstadoMenu.MENU_ACTIVO
				if menu_opciones != null:
					menu_opciones.modulate.a = 0.0
					menu_opciones.visible = false
					menu_opciones.desactivar()
				if textos_nodo != null:
					textos_nodo.modulate.a = 1.0

	elif nombre == &"ir_a_creditos":
		if animador != null:
			animador.speed_scale = 1.0
		if estado == MenuConstantes.EstadoMenu.TRANSICION_CREDITOS:
			# Comprobamos si la cámara llegó a la derecha (1620) o volvió al centro (540)
			if camara != null and camara.position.x > 1080.0:
				estado = MenuConstantes.EstadoMenu.EN_CREDITOS
				if menu_creditos != null:
					menu_creditos.visible = true
					menu_creditos.modulate.a = 1.0
					menu_creditos.activar()
				if menu_opciones != null:
					menu_opciones.visible = false
				if textos_nodo != null:
					textos_nodo.modulate.a = 0.0
			else:
				estado = MenuConstantes.EstadoMenu.MENU_ACTIVO
				if menu_creditos != null:
					menu_creditos.modulate.a = 0.0
					menu_creditos.visible = false
					menu_creditos.desactivar()
				if textos_nodo != null:
					textos_nodo.modulate.a = 1.0

	return false
