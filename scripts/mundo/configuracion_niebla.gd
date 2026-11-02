@tool
class_name ConfiguracionNiebla
extends Resource

## Recurso de configuración tipado para el efecto de niebla geométrica.

@export_group("Geometría de Cápsulas")
@export_range(2, 20, 1) var cantidad_filas: int = 8:
	set(val):
		cantidad_filas = val
		emit_changed()
		changed.emit()

@export_range(0.005, 0.1, 0.002) var radio_capsula: float = 0.035:
	set(val):
		radio_capsula = val
		emit_changed()

@export_range(0.1, 1.5, 0.05) var largo_capsula: float = 0.55:
	set(val):
		largo_capsula = val
		emit_changed()

@export_range(0.4, 3.0, 0.05) var espaciado_horizontal: float = 1.0:
	set(val):
		espaciado_horizontal = val
		emit_changed()

@export_range(0.0, 1.0, 0.05) var variacion_filas: float = 0.35:
	set(val):
		variacion_filas = val
		emit_changed()

@export_group("Movimiento y Velocidades")
@export_range(-2.0, 2.0, 0.05) var velocidad_desplazamiento: float = 0.25:
	set(val):
		velocidad_desplazamiento = val
		emit_changed()

@export_range(0.0, 10.0, 0.1) var multiplicador_velocidad_transicion: float = 2.5:
	set(val):
		multiplicador_velocidad_transicion = val
		emit_changed()

@export var alternar_sentido_filas: bool = false:
	set(val):
		alternar_sentido_filas = val
		emit_changed()

@export_group("Colores y Velo")
@export var color_niebla: Color = Color(0.85, 0.90, 0.98, 0.82):
	set(val):
		color_niebla = val
		emit_changed()

@export var color_niebla_secundaria: Color = Color(0.65, 0.75, 0.88, 0.65):
	set(val):
		color_niebla_secundaria = val
		emit_changed()

@export_range(0.0, 1.0, 0.05) var opacidad_velo_fondo: float = 0.45:
	set(val):
		opacidad_velo_fondo = val
		emit_changed()

@export_group("Halo de Visión del Jugador")
@export_range(0.01, 1.0, 0.01) var difuminado_borde: float = 0.25:
	set(val):
		difuminado_borde = val
		emit_changed()

@export_range(0.5, 3.5, 0.05) var radio_despejado: float = 2.0:
	set(val):
		radio_despejado = val
		emit_changed()

@export_range(0.0, 0.5, 0.01) var radio_cerrado: float = 0.15:
	set(val):
		radio_cerrado = val
		emit_changed()

@export var centro_pantalla: Vector2 = Vector2(0.5, 0.5):
	set(val):
		centro_pantalla = val
		emit_changed()

@export_group("Tiempos de Transición")
@export_range(0.1, 10.0, 0.1, "suffix:s") var duracion_cierre: float = 1.2:
	set(val):
		duracion_cierre = val
		emit_changed()

@export_range(0.0, 5.0, 0.1, "suffix:s") var pausa_oscuridad: float = 1.5:
	set(val):
		pausa_oscuridad = val
		emit_changed()

@export_range(0.1, 10.0, 0.1, "suffix:s") var duracion_apertura: float = 1.2:
	set(val):
		duracion_apertura = val
		emit_changed()

@export_group("Curvas de Animación")
@export var tipo_transicion: Tween.TransitionType = Tween.TRANS_SINE:
	set(val):
		tipo_transicion = val
		emit_changed()

@export var tipo_ease_cierre: Tween.EaseType = Tween.EASE_IN_OUT:
	set(val):
		tipo_ease_cierre = val
		emit_changed()

@export var tipo_ease_apertura: Tween.EaseType = Tween.EASE_OUT:
	set(val):
		tipo_ease_apertura = val
		emit_changed()
