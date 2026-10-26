class_name MenuCinematica
extends RefCounted

## Administrador del flujo cinemático de cámara y transiciones cielo/bosque.

var estado: MenuConstantes.EstadoMenu = MenuConstantes.EstadoMenu.PRESENTACION
var habilitar_presentacion: bool = true
var multiplicador_velocidad_skip: float = 4.0

var camara: Camera2D
var animador: AnimationPlayer
var presentacion: Control
var fondo_presentacion: Sprite2D
var textos_nodo: Control


func inicializar_nodos(
	p_camara: Camera2D,
	p_animador: AnimationPlayer,
	p_presentacion: Control,
	p_fondo_presentacion: Sprite2D,
	p_textos_nodo: Control
) -> void:
	camara = p_camara
	animador = p_animador
	presentacion = p_presentacion
	fondo_presentacion = p_fondo_presentacion
	textos_nodo = p_textos_nodo


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


func skipear_cinematica() -> void:
	if (estado == MenuConstantes.EstadoMenu.CINEMATICA_BAJANDO or estado == MenuConstantes.EstadoMenu.CINEMATICA_SUBIENDO) and animador != null and animador.is_playing():
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
	return false
