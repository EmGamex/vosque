@tool
class_name Personaje
extends CharacterBody2D

## Máquina de estados del personaje para evasión y control físico en Vosque.
## Fachada modular que coordina PersonajeEstaminaController, PersonajeLocomocionController y PersonajeVistaController.
enum Estado {
	REPOSO,
	CAMINANDO,
	SPRINT,
	FATIGA,
	SALTO,
	PLANCHA_AIRE,
	RECUPERANDOSE,
}

signal estamina_cambiada(actual: float, maxima: float, fatigado: bool)
signal estado_cambiado(nuevo_estado: Estado, nombre_estado: String)

@export_group("Físicas de Movimiento")
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var speed: float = 800.0
@export_range(50.0, 3000.0, 10.0, "suffix:px/s") var sprint_speed: float = 1000.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var acceleration: float = 5000.0
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var friction: float = 5000.0
@export_range(0.0, 100.0, 1.0, "suffix:px/s") var stop_threshold: float = 15.0

@export_group("Estamina y Fatiga")
@export_range(10.0, 500.0, 5.0) var max_stamina: float = 100.0
@export_range(0.0, 100.0, 1.0, "suffix:pts/s") var sprint_drain_rate: float = 25.0
@export_range(0.0, 100.0, 1.0, "suffix:pts/s") var stamina_regen_rate: float = 20.0
@export_range(0.0, 5.0, 0.1, "suffix:s") var stamina_regen_delay: float = 0.8
@export_range(0.0, 100.0, 1.0, "suffix:pts") var fatigue_recovery_threshold: float = 30.0

@export_group("Salto y Plancha (Dive)")
@export_range(0.0, 100.0, 1.0, "suffix:pts") var jump_stamina_cost: float = 20.0
@export_range(0.1, 2.0, 0.05, "suffix:s") var jump_duration: float = 0.45
@export_range(10.0, 200.0, 2.0, "suffix:px") var jump_height: float = 56.0
@export var shadow_min_scale: Vector2 = Vector2(0.6, 0.6)
@export_range(0.0, 100.0, 1.0, "suffix:pts") var dive_stamina_cost: float = 30.0
@export_range(100.0, 3000.0, 50.0, "suffix:px/s") var dive_speed: float = 1200.0
@export_range(0.1, 2.0, 0.05, "suffix:s") var dive_recovery_duration: float = 0.6
@export_range(0.0, 10000.0, 50.0, "suffix:px/s²") var dive_slide_friction: float = 2200.0

@export_group("Impulso por Nota")
@export_range(0.0, 1.0, 0.05) var note_stamina_restore_ratio: float = 0.5
@export_range(1.0, 2.0, 0.05) var note_speed_boost_multiplier: float = 1.2
@export_range(0.0, 5.0, 0.1, "suffix:s") var note_speed_boost_duration: float = 1.5
@export_range(0.0, 10.0, 0.1, "suffix:s") var note_no_stamina_drain_duration: float = 1.5
@export var note_boost_tint: Color = Color(0.75, 1.0, 0.9, 1.0)

@export_group("Audio")
@export_range(0.1, 1.0, 0.02, "suffix:s") var step_interval_base: float = 0.32

var estado_actual: Estado = Estado.REPOSO
var god_mode: bool = false
var sin_gasto_estamina: bool = false

var _estamina_ctrl := PersonajeEstaminaController.new()
var _locomocion_ctrl := PersonajeLocomocionController.new()
var _vista_ctrl := PersonajeVistaController.new()
var _audio_ctrl := PersonajeAudioController.new()

@onready var pivote_linterna: ControladorLinterna = get_node_or_null("PivoteLinterna") as ControladorLinterna

# Propiedades proxy para compatibilidad con debug_info, tests y herramientas.
var stamina: float:
	get: return _estamina_ctrl.stamina
	set(v): _estamina_ctrl.stamina = v

var fatigado: bool:
	get: return _estamina_ctrl.fatigado
	set(v): _estamina_ctrl.fatigado = v

@warning_ignore("unused_private_class_variable")
var _regen_timer: float:
	get: return _estamina_ctrl.regen_timer
	set(v): _estamina_ctrl.regen_timer = v

@warning_ignore("unused_private_class_variable")
var _tiempo_boost_nota: float:
	get: return _estamina_ctrl.tiempo_boost_nota
	set(v): _estamina_ctrl.tiempo_boost_nota = v

@warning_ignore("unused_private_class_variable")
var _tiempo_aire: float:
	get: return _locomocion_ctrl.tiempo_aire
	set(v): _locomocion_ctrl.tiempo_aire = v

@warning_ignore("unused_private_class_variable")
var _duracion_aire_actual: float:
	get: return _locomocion_ctrl.duracion_aire_actual
	set(v): _locomocion_ctrl.duracion_aire_actual = v

@warning_ignore("unused_private_class_variable")
var _visual: Node2D:
	get: return _vista_ctrl.visual


func _notification(what: int) -> void:
	if what == NOTIFICATION_UNPAUSED:
		_locomocion_ctrl.bloquear_salto_un_frame = true
	elif what == NOTIFICATION_PREDELETE:
		_vista_ctrl.limpiar()


## Fuerza la limpieza de cualquier intento de salto residual acumulado en pausa o transiciones.
func consumir_buffer_salto() -> void:
	_locomocion_ctrl.bloquear_salto_un_frame = true
	Input.action_release("personaje-salto")
	Input.action_release("ui_accept")


## Detiene el movimiento y procesamiento del personaje al ser capturado.
func detener_por_captura() -> void:
	_estamina_ctrl.limpiar_boost()
	_vista_ctrl.restaurar_feedback_nota()
	_audio_ctrl.detener_todo()
	velocity = Vector2.ZERO
	set_physics_process(false)


## Restaura estamina parcial, limpia fatiga y activa un boost temporal de velocidad y sin gasto de estamina al recoger una nota.
func aplicar_impulso_nota() -> void:
	_estamina_ctrl.aplicar_impulso_nota(
		max_stamina,
		note_stamina_restore_ratio,
		note_speed_boost_duration,
		note_no_stamina_drain_duration
	)
	if estado_actual == Estado.FATIGA:
		_cambiar_estado(Estado.CAMINANDO if velocity.length() >= stop_threshold else Estado.REPOSO)
	emitir_estamina_cambiada()
	_vista_ctrl.ejecutar_feedback_visual_nota(note_boost_tint)


func _ready() -> void:
	add_to_group("jugador")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_locomocion_ctrl.inicializar()
	_vista_ctrl.inicializar(self)
	_estamina_ctrl.inicializar(max_stamina)
	_audio_ctrl.inicializar(self)
	restaurar_mascara_colision_suelo()
	emitir_estamina_cambiada()
	estado_cambiado.emit(estado_actual, obtener_nombre_estado())


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_physics_process_logica(delta)


func _physics_process_logica(delta: float) -> void:
	_locomocion_ctrl.procesar_frame(self, delta, _estamina_ctrl, _vista_ctrl)
	_audio_ctrl.actualizar_pasos(
		delta,
		estado_actual,
		velocity.length(),
		stop_threshold,
		speed,
		step_interval_base
	)


func emitir_estamina_cambiada() -> void:
	estamina_cambiada.emit(_estamina_ctrl.stamina, max_stamina, _estamina_ctrl.fatigado)


func restaurar_mascara_colision_suelo() -> void:
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)


func _iniciar_salto_libre() -> void:
	_locomocion_ctrl.iniciar_salto_libre(self, _estamina_ctrl)


func _finalizar_salto_libre(is_moving: bool) -> void:
	_locomocion_ctrl.finalizar_salto_libre(self, _estamina_ctrl, _vista_ctrl, is_moving)


func cambiar_estado(nuevo_estado: Estado) -> void:
	if estado_actual == nuevo_estado:
		return
	estado_actual = nuevo_estado
	_audio_ctrl.on_estado_cambiado(nuevo_estado)
	estado_cambiado.emit(estado_actual, obtener_nombre_estado())


func _cambiar_estado(nuevo_estado: Estado) -> void:
	cambiar_estado(nuevo_estado)


func obtener_nombre_estado() -> String:
	match estado_actual:
		Estado.REPOSO:
			return "REPOSO"
		Estado.CAMINANDO:
			return "CAMINANDO"
		Estado.SPRINT:
			return "SPRINT"
		Estado.FATIGA:
			return "FATIGA"
		Estado.SALTO:
			return "SALTO"
		Estado.PLANCHA_AIRE:
			return "PLANCHA_AIRE"
		Estado.RECUPERANDOSE:
			return "RECUPERANDOSE"
	return "DESCONOCIDO"
