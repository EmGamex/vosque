extends Node

## Singleton / Autoload global para persistir las configuraciones del menú de debug.
## Evita que se reinicien al recargar la partida, morir o cambiar de escena.

# Modo de visualización F3 (0: OCULTO, 1: MINI_HUD, 2: COMPLETO)
var modo_actual: int = 0

# Cheats
var cheat_estamina_infinita: bool = false
var cheat_god_mode: bool = false

# Overlays de visualización espacial e IA
var debug_dibujar_cuadrantes: bool = false
var debug_dibujar_corredores: bool = false
var debug_dibujar_vectores_ia: bool = false

# Cámara Cenital (God View)
var god_view_activo: bool = false

# Efectos visuales de escenario
var niebla_desactivada: bool = false
var flicker_forzado: bool = false

# Ajustes de físicas y velocidades modificados por sliders (null si no han sido modificados)
var fisicas_personalizadas: bool = false
var vel_normal: float = 800.0
var vel_sprint: float = 1000.0
var acel: float = 5000.0
var fric: float = 5000.0
var dive_vel: float = 1200.0
var escalado_proporcional_activo: bool = true
var time_scale: float = 1.0

# Persistencia de estado de las ventanas del DebugWindowManager
# Formato: { "window_id": { "abierta": bool, "fijada": bool, "colapsada": bool, "posicion": Vector2 } }
var ventanas_estado: Dictionary = {}

# Persistencia de ventana externa independiente (Pop-out Window)
var ventana_desacoplada: bool = false
var ventana_externa_pos: Vector2i = Vector2i(80, 80)
var ventana_externa_size: Vector2i = Vector2i(1120, 750)


func guardar_geometria_ventana_externa(pos: Vector2i, tam: Vector2i) -> void:
	ventana_externa_pos = pos
	ventana_externa_size = tam


func guardar_estado_ventana(window_id: String, abierta: bool, fijada: bool, colapsada: bool, posicion: Vector2) -> void:
	ventanas_estado[window_id] = {
		"abierta": abierta,
		"fijada": fijada,
		"colapsada": colapsada,
		"posicion": posicion
	}


func obtener_estado_ventana(window_id: String, defecto_abierta: bool = false, defecto_pos: Vector2 = Vector2.ZERO) -> Dictionary:
	if ventanas_estado.has(window_id):
		return ventanas_estado[window_id]
	return {
		"abierta": defecto_abierta,
		"fijada": false,
		"colapsada": false,
		"posicion": defecto_pos
	}


func resetear_velocidades(vel_n: float, vel_s: float, ac: float, fr: float, dive: float) -> void:
	fisicas_personalizadas = false
	vel_normal = vel_n
	vel_sprint = vel_s
	acel = ac
	fric = fr
	dive_vel = dive
