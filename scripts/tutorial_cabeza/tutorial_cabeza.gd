@tool
class_name TutorialCabeza
extends Node2D

## Tutorial diegético flotante anclado sobre la cabeza del personaje (Vector2(0, -90)).
## Orquestador/Fachada modular que coordina TutorialEstadoController y TutorialVistaController.

signal paso_cambiado(nuevo_paso: Paso)
signal tutorial_completado(es_fast_path: bool)
signal fast_path_activado

const Paso = TutorialEstadoController.Paso

static var tutorial_visto: bool = false

@export var color_fondo: Color:
	get: return vista_ctrl.color_fondo if vista_ctrl != null else Color(0.12, 0.12, 0.13, 0.88)
	set(val):
		if vista_ctrl != null:
			vista_ctrl.color_fondo = val
			vista_ctrl._crear_estilos_cacheados()

@export var color_activo: Color:
	get: return vista_ctrl.color_activo if vista_ctrl != null else Color(0.70, 0.70, 0.72)
	set(val):
		if vista_ctrl != null:
			vista_ctrl.color_activo = val

@export var color_inactivo: Color:
	get: return vista_ctrl.color_inactivo if vista_ctrl != null else Color(0.85, 0.85, 0.85, 0.90)
	set(val):
		if vista_ctrl != null:
			vista_ctrl.color_inactivo = val

@export var color_acento_dorado: Color:
	get: return vista_ctrl.color_acento_dorado if vista_ctrl != null else Color(0.85, 0.85, 0.85)
	set(val):
		if vista_ctrl != null:
			vista_ctrl.color_acento_dorado = val

# Sub-controladores modulares
var estado_ctrl: TutorialEstadoController = TutorialEstadoController.new()
var vista_ctrl: TutorialVistaController = TutorialVistaController.new()

# Acceso y compatibilidad delegada para tests e inspección
var paso_actual: Paso:
	get: return estado_ctrl.paso_actual if estado_ctrl != null else Paso.PASO_1_MOVIMIENTO
	set(v):
		if estado_ctrl != null:
			estado_ctrl.paso_actual = v
			if vista_ctrl != null:
				vista_ctrl.actualizar_visibilidad_pasos(v)

var _w_registrado: bool:
	get: return estado_ctrl.w_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.w_registrado = v

var _a_registrado: bool:
	get: return estado_ctrl.a_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.a_registrado = v

var _s_registrado: bool:
	get: return estado_ctrl.s_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.s_registrado = v

var _d_registrado: bool:
	get: return estado_ctrl.d_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.d_registrado = v

var _raton_registrado: bool:
	get: return estado_ctrl.raton_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.raton_registrado = v

var _salto_registrado: bool:
	get: return estado_ctrl.salto_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.salto_registrado = v

var _dive_registrado: bool:
	get: return estado_ctrl.dive_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.dive_registrado = v

var _sprint_registrado: bool:
	get: return estado_ctrl.sprint_registrado if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.sprint_registrado = v

var _en_el_aire: bool:
	get: return estado_ctrl.en_el_aire if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.en_el_aire = v

var _salto_en_curso: bool:
	get: return estado_ctrl.salto_en_curso if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.salto_en_curso = v

var _cerrando: bool:
	get: return estado_ctrl.cerrando if estado_ctrl != null else false
	set(v): if estado_ctrl != null: estado_ctrl.cerrando = v

var _flash_unisono: bool:
	get: return vista_ctrl.flash_unisono if vista_ctrl != null else false
	set(v): if vista_ctrl != null: vista_ctrl.flash_unisono = v


static func reiniciar_tutorial() -> void:
	tutorial_visto = false


func _ready() -> void:
	z_index = 3
	if tutorial_visto and not Engine.is_editor_hint():
		queue_free()
		return

	scale = Vector2.ONE
	modulate.a = 1.0

	_conectar_subcontroladores()
	vista_ctrl.inicializar(self)
	vista_ctrl.actualizar_visibilidad_pasos(estado_ctrl.paso_actual)

	_conectar_padre()
	_conectar_director_juego()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if vista_ctrl != null:
			vista_ctrl.limpiar()


func _conectar_subcontroladores() -> void:
	if not estado_ctrl.paso_avanzado.is_connected(_on_estado_paso_avanzado):
		estado_ctrl.paso_avanzado.connect(_on_estado_paso_avanzado)
	if not estado_ctrl.tutorial_finalizado.is_connected(_on_estado_tutorial_finalizado):
		estado_ctrl.tutorial_finalizado.connect(_on_estado_tutorial_finalizado)
	if not estado_ctrl.fast_path_detectado.is_connected(_on_estado_fast_path_detectado):
		estado_ctrl.fast_path_detectado.connect(_on_estado_fast_path_detectado)
	if not estado_ctrl.dive_ejecutado.is_connected(_on_estado_dive_ejecutado):
		estado_ctrl.dive_ejecutado.connect(_on_estado_dive_ejecutado)


func _conectar_padre() -> void:
	var padre = get_parent()
	if padre != null and padre.has_signal("estado_cambiado"):
		if not padre.is_connected("estado_cambiado", Callable(self, "_on_padre_estado_cambiado")):
			padre.connect("estado_cambiado", Callable(self, "_on_padre_estado_cambiado"))


func _conectar_director_juego() -> void:
	if not is_inside_tree():
		return
	var tree := get_tree()
	if tree != null and tree.root != null:
		var maain = tree.root.find_child("Maain", true, false)
		if maain != null and maain.has_signal("nota_recogida"):
			if not maain.is_connected("nota_recogida", Callable(self, "_on_nota_recogida")):
				maain.connect("nota_recogida", Callable(self, "_on_nota_recogida"))


func _unhandled_input(event: InputEvent) -> void:
	if _cerrando:
		return
	if event is InputEventMouseMotion:
		estado_ctrl.registrar_movimiento_raton(event.relative.length())
		vista_ctrl.actualizar_estilo_raton(estado_ctrl)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or _cerrando:
		return

	var vel_padre: Vector2 = Vector2.ZERO
	var est_padre: int = -1
	var padre = get_parent()
	if padre != null:
		if padre is CharacterBody2D:
			vel_padre = padre.velocity
		if "estado_actual" in padre:
			est_padre = padre.get("estado_actual")

	estado_ctrl.procesar_entradas_y_progreso(delta, vel_padre, est_padre)
	vista_ctrl.actualizar_estilos_reactivos(estado_ctrl)


func _on_padre_estado_cambiado(nuevo_estado: int, _nombre_estado: String) -> void:
	estado_ctrl.procesar_cambio_estado_personaje(nuevo_estado)


func _on_estado_paso_avanzado(nuevo_paso: Paso) -> void:
	vista_ctrl.actualizar_visibilidad_pasos(nuevo_paso)
	vista_ctrl.animar_pop_transicion()
	paso_cambiado.emit(nuevo_paso)


func _on_estado_dive_ejecutado() -> void:
	vista_ctrl.animar_pulso_dive(func():
		if estado_ctrl.paso_actual == Paso.PASO_3_PLANCHA_DIVE and estado_ctrl.dive_registrado:
			estado_ctrl.avanzar_paso(Paso.PASO_4_SPRINT)
	)


func _on_estado_fast_path_detectado() -> void:
	tutorial_visto = true
	fast_path_activado.emit()
	vista_ctrl.animar_fast_path(queue_free)


func _on_estado_tutorial_finalizado(es_fast_path: bool) -> void:
	tutorial_visto = true
	tutorial_completado.emit(es_fast_path)
	if not es_fast_path:
		vista_ctrl.animar_cierre_estandar(queue_free)


func _on_nota_recogida(_pos: Vector2, total: int) -> void:
	if total >= 1:
		forzar_salida_nota()


func forzar_salida_nota() -> void:
	if _cerrando:
		return
	estado_ctrl.cerrando = true
	tutorial_visto = true
	vista_ctrl.animar_cierre_forzado(queue_free)


func ejecutar_fast_path() -> void:
	estado_ctrl.activar_fast_path()


func completar_tutorial_estandar() -> void:
	estado_ctrl.completar_tutorial_estandar()


func _centrar_contenedor_deferred() -> void:
	if vista_ctrl != null:
		vista_ctrl.centrar_contenedor()


# Funciones de compatibilidad directa para tests unitarios
func _procesar_paso_1(delta: float) -> void:
	var vel = Vector2.ZERO
	var p = get_parent()
	if p != null and p is CharacterBody2D:
		vel = p.velocity
	estado_ctrl._procesar_paso_1(delta, vel)


func _actualizar_estilos_reactivos() -> void:
	if vista_ctrl != null and estado_ctrl != null:
		vista_ctrl.actualizar_estilos_reactivos(estado_ctrl)
