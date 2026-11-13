class_name PersonajeAudioController
extends RefCounted

## Subcontrolador de audio diegético 2D del personaje: pasos, salto y plancha.

const BUS_SFX: StringName = &"sfx"

var player_pasos: AudioStreamPlayer2D = null
var player_salto: AudioStreamPlayer2D = null
var player_plancha: AudioStreamPlayer2D = null

var _timer_paso: float = 0.0
var _estado_anterior: int = -1


func inicializar(host: Node2D) -> void:
	player_pasos = host.get_node_or_null("AudioPasos") as AudioStreamPlayer2D
	player_salto = host.get_node_or_null("AudioSalto") as AudioStreamPlayer2D
	player_plancha = host.get_node_or_null("AudioPlancha") as AudioStreamPlayer2D
	_timer_paso = 0.0
	_estado_anterior = -1


func on_estado_cambiado(nuevo_estado: Personaje.Estado) -> void:
	if nuevo_estado == _estado_anterior:
		return
	_estado_anterior = nuevo_estado

	match nuevo_estado:
		Personaje.Estado.SALTO:
			_reproducir_con_jitter(player_salto, 0.95, 1.05)
			_timer_paso = 0.0
		Personaje.Estado.PLANCHA_AIRE:
			_reproducir_con_jitter(player_plancha, 0.95, 1.05)
			_timer_paso = 0.0
		Personaje.Estado.REPOSO, Personaje.Estado.RECUPERANDOSE:
			_timer_paso = 0.0


func actualizar_pasos(
	delta: float,
	estado: Personaje.Estado,
	velocidad: float,
	stop_threshold: float,
	velocidad_referencia: float,
	intervalo_base: float
) -> void:
	var en_suelo_moviendo: bool = (
		estado == Personaje.Estado.CAMINANDO
		or estado == Personaje.Estado.SPRINT
		or estado == Personaje.Estado.FATIGA
	) and velocidad > stop_threshold

	if not en_suelo_moviendo:
		_timer_paso = 0.0
		return

	_timer_paso -= delta
	if _timer_paso <= 0.0:
		_reproducir_con_jitter(player_pasos, 0.92, 1.08)
		var factor_vel: float = clampf(velocidad / maxf(velocidad_referencia, 1.0), 0.5, 1.8)
		_timer_paso = intervalo_base / factor_vel


func detener_todo() -> void:
	_timer_paso = 0.0
	if player_pasos != null and player_pasos.playing:
		player_pasos.stop()


func _reproducir_con_jitter(player: AudioStreamPlayer2D, min_pitch: float, max_pitch: float) -> void:
	if player == null or player.stream == null:
		return
	player.pitch_scale = randf_range(min_pitch, max_pitch)
	player.play()
