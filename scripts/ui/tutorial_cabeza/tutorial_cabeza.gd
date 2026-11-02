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

@export_group("Estilos Nativos")
@export var estilo_fondo: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_tutorial_fondo.tres"):
	get: return vista_ctrl.sb_fondo if vista_ctrl != null else null
	set(val):
		if vista_ctrl != null:
			vista_ctrl.sb_fondo = val
			vista_ctrl._aplicar_estilos_base()

@export var estilo_badge_inactivo: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_badge_inactivo.tres"):
	get: return vista_ctrl.sb_badge_inactivo if vista_ctrl != null else null
	set(val):
		if vista_ctrl != null:
			vista_ctrl.sb_badge_inactivo = val
			vista_ctrl._aplicar_estilos_base()

@export var estilo_badge_activo: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_badge_activo.tres"):
	get: return vista_ctrl.sb_badge_activo if vista_ctrl != null else null
	set(val):
		if vista_ctrl != null:
			vista_ctrl.sb_badge_activo = val

@export var estilo_badge_dive: StyleBoxFlat = preload("res://recursos/ui/tutorial/sb_badge_dive.tres"):
	get: return vista_ctrl.sb_badge_dive if vista_ctrl != null else null
	set(val):
		if vista_ctrl != null:
			vista_ctrl.sb_badge_dive = val

@export_group("Colores")
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

# Sub-controladores modulares
var estado_ctrl: TutorialEstadoController = TutorialEstadoController.new()
var vista_ctrl: TutorialVistaController = TutorialVistaController.new()

# Acceso y conveniencia de paso actual
var paso_actual: Paso:
	get: return estado_ctrl.paso_actual if estado_ctrl != null else Paso.PASO_1_MOVIMIENTO
	set(v):
		if estado_ctrl != null:
			estado_ctrl.paso_actual = v
			if vista_ctrl != null:
				vista_ctrl.actualizar_visibilidad_pasos(v)


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
	if tree != null:
		var maain = tree.get_first_node_in_group("director_juego")
		if maain == null and tree.root != null:
			maain = tree.root.find_child("Maain", true, false)
		if maain != null and maain.has_signal("nota_recogida"):
			if not maain.is_connected("nota_recogida", Callable(self, "_on_nota_recogida")):
				maain.connect("nota_recogida", Callable(self, "_on_nota_recogida"))


func _unhandled_input(event: InputEvent) -> void:
	if estado_ctrl.cerrando:
		return
	if event is InputEventMouseMotion:
		estado_ctrl.registrar_movimiento_raton(event.relative.length())
		vista_ctrl.actualizar_estilo_raton(estado_ctrl)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or estado_ctrl.cerrando:
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
	if estado_ctrl.cerrando:
		return
	estado_ctrl.cerrando = true
	tutorial_visto = true
	vista_ctrl.animar_cierre_forzado(queue_free)


func ejecutar_fast_path() -> void:
	estado_ctrl.activar_fast_path()


func completar_tutorial_estandar() -> void:
	estado_ctrl.completar_tutorial_estandar()
