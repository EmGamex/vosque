class_name PersonajeEstaminaController
extends RefCounted

## Subcontrolador de estamina, fatiga, regeneración e impulso temporal por nota.

var stamina: float = 100.0
var fatigado: bool = false
var regen_timer: float = 0.0
var tiempo_boost_nota: float = 0.0
var tiempo_sin_gasto_nota: float = 0.0


func inicializar(max_stamina: float) -> void:
	stamina = max_stamina
	fatigado = false
	regen_timer = 0.0
	tiempo_boost_nota = 0.0
	tiempo_sin_gasto_nota = 0.0


func esta_sin_gasto_activo(sin_gasto_debug: bool) -> bool:
	return sin_gasto_debug or tiempo_sin_gasto_nota > 0.0


func puede_pagar(costo: float, sin_gasto_estamina: bool) -> bool:
	return sin_gasto_estamina or stamina >= costo


func consumir_puntual(costo: float, regen_delay: float, sin_gasto_estamina: bool) -> bool:
	if sin_gasto_estamina:
		return false
	stamina = maxf(0.0, stamina - costo)
	regen_timer = regen_delay
	if stamina <= 0.0:
		stamina = 0.0
		fatigado = true
	return true


func drenar_continuo(tasa: float, delta: float, regen_delay: float, sin_gasto_estamina: bool) -> bool:
	return consumir_puntual(tasa * delta, regen_delay, sin_gasto_estamina)


func procesar_regeneracion(
	delta: float,
	max_stamina: float,
	regen_rate: float,
	recovery_threshold: float
) -> bool:
	if regen_timer > 0.0:
		regen_timer -= delta
		return false

	if stamina < max_stamina:
		stamina = minf(max_stamina, stamina + regen_rate * delta)
		if fatigado and stamina >= recovery_threshold:
			fatigado = false
		return true

	return false


func aplicar_impulso_nota(
	max_stamina: float,
	restore_ratio: float,
	boost_duration: float,
	no_drain_duration: float = 0.0
) -> void:
	var estamina_extra: float = max_stamina * restore_ratio
	stamina = minf(max_stamina, stamina + estamina_extra)
	regen_timer = 0.0
	fatigado = false
	tiempo_boost_nota = boost_duration
	tiempo_sin_gasto_nota = no_drain_duration


func actualizar_boost_nota(delta: float) -> bool:
	var tenia_impulso: bool = tiempo_boost_nota > 0.0 or tiempo_sin_gasto_nota > 0.0
	if tiempo_sin_gasto_nota > 0.0:
		tiempo_sin_gasto_nota = maxf(0.0, tiempo_sin_gasto_nota - delta)
	if tiempo_boost_nota > 0.0:
		tiempo_boost_nota = maxf(0.0, tiempo_boost_nota - delta)
	var tiene_impulso: bool = tiempo_boost_nota > 0.0 or tiempo_sin_gasto_nota > 0.0
	return tenia_impulso and not tiene_impulso


func limpiar_boost() -> void:
	tiempo_boost_nota = 0.0
	tiempo_sin_gasto_nota = 0.0


func obtener_factor_boost(multiplier: float) -> float:
	return multiplier if tiempo_boost_nota > 0.0 else 1.0
