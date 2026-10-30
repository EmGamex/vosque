@tool
class_name TutorialEstadoController
extends RefCounted

## Sub-controlador de lógica, entradas y progresión del TutorialCabeza.
## Encapsula la máquina de estados, el seguimiento de teclas, ratón y transiciones.

signal paso_avanzado(nuevo_paso: Paso)
signal tutorial_finalizado(es_fast_path: bool)
signal fast_path_detectado
signal dive_ejecutado

enum Paso {
	PASO_1_MOVIMIENTO,
	PASO_2_SALTO,
	PASO_3_PLANCHA_DIVE,
	PASO_4_SPRINT,
	COMPLETADO
}

const UMBRAL_MOVIMIENTO_RATON: float = 30.0
const TIEMPO_GRACIA_PASO_1: float = 0.35

var paso_actual: Paso = Paso.PASO_1_MOVIMIENTO
var cerrando: bool = false

# Registro de requisitos
var w_registrado: bool = false
var a_registrado: bool = false
var s_registrado: bool = false
var d_registrado: bool = false
var raton_registrado: bool = false
var salto_registrado: bool = false
var dive_registrado: bool = false
var sprint_registrado: bool = false

# Estado de teclas en el frame actual
var tecla_w_activa: bool = false
var tecla_a_activa: bool = false
var tecla_s_activa: bool = false
var tecla_d_activa: bool = false
var tecla_espacio_activa: bool = false
var tecla_shift_activa: bool = false
var raton_activo: bool = false

# Temporizadores y acumuladores
var distancia_raton_acumulada: float = 0.0
var tiempo_iluminacion_raton: float = 0.0
var tiempo_en_paso_actual: float = 0.0
var tiempo_completado_paso_1: float = 0.0
var tiempo_desplazamiento: float = 0.0

# Estado físico
var en_el_aire: bool = false
var salto_en_curso: bool = false


func reiniciar() -> void:
	paso_actual = Paso.PASO_1_MOVIMIENTO
	cerrando = false
	w_registrado = false
	a_registrado = false
	s_registrado = false
	d_registrado = false
	raton_registrado = false
	salto_registrado = false
	dive_registrado = false
	sprint_registrado = false
	distancia_raton_acumulada = 0.0
	tiempo_iluminacion_raton = 0.0
	tiempo_en_paso_actual = 0.0
	tiempo_completado_paso_1 = 0.0
	tiempo_desplazamiento = 0.0
	en_el_aire = false
	salto_en_curso = false


func registrar_movimiento_raton(mov: float) -> void:
	if cerrando or mov <= 0.0:
		return
	raton_activo = true
	tiempo_iluminacion_raton = 0.35
	distancia_raton_acumulada += mov
	if distancia_raton_acumulada >= UMBRAL_MOVIMIENTO_RATON:
		raton_registrado = true


func procesar_entradas_y_progreso(delta: float, velocidad_padre: Vector2, estado_padre: int) -> void:
	if cerrando:
		return

	tiempo_en_paso_actual += delta

	# Actualizar teclas activas
	tecla_w_activa = Input.is_action_pressed("personaje-arriba")
	tecla_s_activa = Input.is_action_pressed("personaje-abajo")
	tecla_a_activa = Input.is_action_pressed("personaje-izquierda")
	tecla_d_activa = Input.is_action_pressed("personaje-derecha")
	tecla_espacio_activa = Input.is_action_pressed("personaje-salto")
	tecla_shift_activa = (
		Input.is_action_pressed("sprint")
		or (InputMap.has_action("personaje-sprint") and Input.is_action_pressed("personaje-sprint"))
	)

	if tiempo_iluminacion_raton > 0.0:
		tiempo_iluminacion_raton -= delta
		if tiempo_iluminacion_raton <= 0.0:
			raton_activo = false

	_verificar_fast_path()

	match paso_actual:
		Paso.PASO_1_MOVIMIENTO:
			_procesar_paso_1(delta, velocidad_padre)
		Paso.PASO_2_SALTO:
			pass
		Paso.PASO_3_PLANCHA_DIVE:
			pass
		Paso.PASO_4_SPRINT:
			_procesar_paso_4(velocidad_padre, estado_padre)


func _verificar_fast_path() -> void:
	if paso_actual != Paso.PASO_1_MOVIMIENTO or cerrando:
		return
	var hay_movimiento: bool = tecla_w_activa or tecla_a_activa or tecla_s_activa or tecla_d_activa
	if tecla_shift_activa and hay_movimiento:
		activar_fast_path()


func activar_fast_path() -> void:
	if cerrando:
		return
	cerrando = true
	fast_path_detectado.emit()
	tutorial_finalizado.emit(true)


func _procesar_paso_1(delta: float, velocidad_padre: Vector2) -> void:
	if tecla_w_activa: w_registrado = true
	if tecla_a_activa: a_registrado = true
	if tecla_s_activa: s_registrado = true
	if tecla_d_activa: d_registrado = true

	if velocidad_padre.length() > 30.0:
		tiempo_desplazamiento += delta

	var todo_completado: bool = (
		w_registrado and a_registrado and s_registrado and d_registrado and raton_registrado
	)
	if todo_completado:
		tiempo_completado_paso_1 += delta
		if tiempo_completado_paso_1 >= TIEMPO_GRACIA_PASO_1:
			avanzar_paso(Paso.PASO_2_SALTO)


func _procesar_paso_4(velocidad_padre: Vector2, estado_padre: int) -> void:
	var en_sprint: bool = (estado_padre == 2) or (tecla_shift_activa and velocidad_padre.length() > 50.0)
	if en_sprint:
		sprint_registrado = true
		completar_tutorial_estandar()


func procesar_cambio_estado_personaje(nuevo_estado: int) -> void:
	# Mapeado a Personaje.Estado: SALTO = 4, PLANCHA_AIRE = 5
	if nuevo_estado == 4: # SALTO
		salto_en_curso = true
		en_el_aire = true
		if paso_actual == Paso.PASO_2_SALTO:
			salto_registrado = true
	elif nuevo_estado == 5: # PLANCHA_AIRE
		if paso_actual == Paso.PASO_3_PLANCHA_DIVE:
			dive_registrado = true
			en_el_aire = true
			dive_ejecutado.emit()
	else:
		if salto_en_curso:
			salto_en_curso = false
			en_el_aire = false
			if paso_actual == Paso.PASO_2_SALTO:
				avanzar_paso(Paso.PASO_3_PLANCHA_DIVE)
			elif paso_actual == Paso.PASO_3_PLANCHA_DIVE and dive_registrado:
				avanzar_paso(Paso.PASO_4_SPRINT)
		elif en_el_aire:
			en_el_aire = false
			if paso_actual == Paso.PASO_3_PLANCHA_DIVE and dive_registrado:
				avanzar_paso(Paso.PASO_4_SPRINT)


func avanzar_paso(siguiente_paso: Paso) -> void:
	if cerrando or paso_actual == siguiente_paso:
		return
	paso_actual = siguiente_paso
	tiempo_en_paso_actual = 0.0
	if paso_actual == Paso.PASO_3_PLANCHA_DIVE:
		dive_registrado = false
		salto_en_curso = false
		en_el_aire = false
	paso_avanzado.emit(paso_actual)


func completar_tutorial_estandar() -> void:
	if cerrando:
		return
	cerrando = true
	paso_actual = Paso.COMPLETADO
	tutorial_finalizado.emit(false)
