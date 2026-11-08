@tool
class_name MutadorSectores
extends RefCounted

## Administrador algorítmico y de transiciones visuales (fade) de la mutación espacial.
## Coordina con GestorSectores y EfectoNieblaMutacion la sustitución de cuadrantes lejanos.

signal mutacion_completada(cuadrante_activo: String)

var gestor_sectores: GestorSectores
var nodo_raiz: Node2D
var efecto_niebla: EfectoNieblaMutacion

var mutacion_en_progreso: bool = false
var mutacion_pendiente: bool = false
var swap_ejecutado_en_ciclo: bool = false
var tween_fade_sectores: Tween = null


func _init(p_nodo_raiz: Node2D = null, p_gestor: GestorSectores = null, p_niebla: EfectoNieblaMutacion = null) -> void:
	nodo_raiz = p_nodo_raiz
	gestor_sectores = p_gestor
	efecto_niebla = p_niebla


func abortar_mutacion() -> void:
	mutacion_pendiente = false
	mutacion_en_progreso = false
	restaurar_opacidad_sectores()
	if efecto_niebla != null and is_instance_valid(efecto_niebla):
		if efecto_niebla.has_method("abortar_inmediato"):
			efecto_niebla.abortar_inmediato()


func restaurar_opacidad_sectores() -> void:
	if tween_fade_sectores != null and tween_fade_sectores.is_valid():
		tween_fade_sectores.kill()
		tween_fade_sectores = null

	if gestor_sectores == null:
		return

	for sector in GestorSectores.SECTORES:
		var nodo_sector: Node2D = gestor_sectores.obtener_nodo_sector(sector)
		if nodo_sector != null:
			nodo_sector.modulate.a = 1.0


func mutar_con_neblina(
	pos_jugador: Vector2,
	catalogo: Array[PackedScene],
	callback_post_swap: Callable,
	duracion_cierre: float = -1.0,
	duracion_apertura: float = -1.0,
	pausa_oscuridad: float = -1.0
) -> void:
	if mutacion_en_progreso:
		mutacion_pendiente = true
		return
	mutacion_en_progreso = true
	swap_ejecutado_en_ciclo = false

	var dur_pausa_efectiva: float = pausa_oscuridad
	if dur_pausa_efectiva < 0.0 and efecto_niebla != null:
		dur_pausa_efectiva = efecto_niebla.pausa_oscuridad

	if efecto_niebla != null:
		await efecto_niebla.ejecutar_transicion(
			Callable(self, "ejecutar_mutacion_con_fade").bind(dur_pausa_efectiva, pos_jugador, catalogo, callback_post_swap),
			duracion_cierre,
			duracion_apertura,
			pausa_oscuridad
		)
		if not swap_ejecutado_en_ciclo:
			mutar_sectores_lejanos(pos_jugador, catalogo, [])
			if callback_post_swap.is_valid():
				callback_post_swap.call()
	else:
		mutar_sectores_lejanos(pos_jugador, catalogo, [])
		if callback_post_swap.is_valid():
			callback_post_swap.call()

	restaurar_opacidad_sectores()
	mutacion_en_progreso = false

	var cuadrante_activo: String = gestor_sectores.obtener_cuadrante(pos_jugador) if gestor_sectores != null else ""
	mutacion_completada.emit(cuadrante_activo)

	if mutacion_pendiente:
		mutacion_pendiente = false
		if nodo_raiz != null and nodo_raiz.has_method("mutar_con_neblina"):
			nodo_raiz.call_deferred("mutar_con_neblina", duracion_cierre, duracion_apertura, pausa_oscuridad)


func ejecutar_mutacion_con_fade(
	duracion_pausa: float,
	pos_jugador: Vector2,
	catalogo: Array[PackedScene],
	callback_post_swap: Callable
) -> void:
	if duracion_pausa <= 0.0 or efecto_niebla == null or efecto_niebla.desactivado or nodo_raiz == null or not nodo_raiz.is_inside_tree():
		swap_ejecutado_en_ciclo = true
		mutar_sectores_lejanos(pos_jugador, catalogo, [])
		if callback_post_swap.is_valid():
			callback_post_swap.call()
		return

	if tween_fade_sectores != null and tween_fade_sectores.is_valid():
		tween_fade_sectores.kill()
		tween_fade_sectores = null

	var cuadrante_actual: String = gestor_sectores.obtener_cuadrante(pos_jugador) if gestor_sectores != null else ""

	var sectores_a_mutar: Array[String] = []
	var nodos_a_mutar: Array[Node2D] = []
	for sector in GestorSectores.SECTORES:
		if sector != cuadrante_actual:
			sectores_a_mutar.append(sector)
			var nodo_sec: Node2D = gestor_sectores.obtener_nodo_sector(sector) if gestor_sectores != null else null
			if nodo_sec != null:
				nodos_a_mutar.append(nodo_sec)

	var mitad_pausa: float = duracion_pausa * 0.5
	tween_fade_sectores = nodo_raiz.create_tween()
	tween_fade_sectores.set_parallel(true)
	tween_fade_sectores.set_trans(Tween.TRANS_SINE)
	tween_fade_sectores.set_ease(Tween.EASE_IN_OUT)

	for nodo_sec in nodos_a_mutar:
		tween_fade_sectores.tween_property(nodo_sec, "modulate:a", 0.0, mitad_pausa)

	tween_fade_sectores.chain().tween_callback(func():
		swap_ejecutado_en_ciclo = true
		if OS.has_feature("web") or OS.get_name() == "Web":
			mutar_sectores_lejanos_progresivo(pos_jugador, catalogo, sectores_a_mutar)
		else:
			mutar_sectores_lejanos(pos_jugador, catalogo, sectores_a_mutar)
		if callback_post_swap.is_valid():
			callback_post_swap.call()
	)

	for nodo_sec in nodos_a_mutar:
		tween_fade_sectores.parallel().tween_property(nodo_sec, "modulate:a", 1.0, mitad_pausa)


func mutar_sectores_lejanos(
	pos_jugador: Vector2,
	catalogo: Array[PackedScene],
	sectores_permitidos: Array[String] = []
) -> String:
	if gestor_sectores == null or catalogo.is_empty():
		return ""

	var cuadrante_activo: String = gestor_sectores.obtener_cuadrante(pos_jugador)

	for sector in GestorSectores.SECTORES:
		if sector == cuadrante_activo:
			continue

		if not sectores_permitidos.is_empty() and not sectores_permitidos.has(sector):
			continue

		var variante_actual_nombre: String = gestor_sectores.variantes_activas.get(sector, "")
		var candidatos: Array[PackedScene] = []
		for var_scene in catalogo:
			if var_scene.resource_path.get_file().get_basename() != variante_actual_nombre:
				candidatos.append(var_scene)

		var elegida: PackedScene
		if not candidatos.is_empty():
			elegida = candidatos[randi() % candidatos.size()]
		else:
			elegida = catalogo[randi() % catalogo.size()]

		gestor_sectores.instanciar_variante_en_sector(sector, elegida)

	return cuadrante_activo


func mutar_sectores_lejanos_progresivo(
	pos_jugador: Vector2,
	catalogo: Array[PackedScene],
	sectores_permitidos: Array[String] = []
) -> String:
	if gestor_sectores == null or catalogo.is_empty():
		return ""

	var cuadrante_activo: String = gestor_sectores.obtener_cuadrante(pos_jugador)
	var arbol := nodo_raiz.get_tree() if nodo_raiz != null else null

	for sector in GestorSectores.SECTORES:
		if sector == cuadrante_activo:
			continue

		if not sectores_permitidos.is_empty() and not sectores_permitidos.has(sector):
			continue

		var variante_actual_nombre: String = gestor_sectores.variantes_activas.get(sector, "")
		var candidatos: Array[PackedScene] = []
		for var_scene in catalogo:
			if var_scene.resource_path.get_file().get_basename() != variante_actual_nombre:
				candidatos.append(var_scene)

		var elegida: PackedScene
		if not candidatos.is_empty():
			elegida = candidatos[randi() % candidatos.size()]
		else:
			elegida = catalogo[randi() % catalogo.size()]

		gestor_sectores.instanciar_variante_en_sector(sector, elegida)

		if arbol != null and not Engine.is_editor_hint():
			await arbol.process_frame

	return cuadrante_activo
