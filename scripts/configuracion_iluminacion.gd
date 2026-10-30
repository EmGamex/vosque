@tool
class_name ConfiguracionIluminacion
extends Resource

## Recurso de configuración centralizado para el sistema de iluminación 2D WebGL y linterna de Vosque.

# --- GRUPO AMBIENTE ---
@export_group("Ambiente")
@export var color_ambiente_inicial: Color = Color(0.40, 0.45, 0.60, 1.0):
	set(val):
		color_ambiente_inicial = val
		emit_changed()
		changed.emit()

@export var color_ambiente_final: Color = Color(0.18, 0.22, 0.32, 1.0):
	set(val):
		color_ambiente_final = val
		emit_changed()
		changed.emit()

@export var modular_con_notas: bool = true:
	set(val):
		modular_con_notas = val
		emit_changed()
		changed.emit()

@export_range(1, 20, 1) var max_notas_ambiente: int = 8:
	set(val):
		max_notas_ambiente = val
		emit_changed()
		changed.emit()

# --- GRUPO LINTERNA FRONTAL ---
@export_group("Linterna Frontal")
@export var color_linterna: Color = Color(1.0, 0.96, 0.88, 1.0):
	set(val):
		color_linterna = val
		emit_changed()
		changed.emit()

@export_range(0.0, 5.0, 0.1) var energia_base: float = 1.2:
	set(val):
		energia_base = val
		emit_changed()
		changed.emit()

@export_range(100.0, 2000.0, 50.0, "suffix:px") var alcance_px: float = 700.0:
	set(val):
		alcance_px = val
		emit_changed()
		changed.emit()

@export_range(10.0, 180.0, 5.0, "suffix:°") var apertura_grados: float = 60.0:
	set(val):
		apertura_grados = val
		emit_changed()
		changed.emit()

@export_range(0.01, 1.0, 0.05) var suavizado_borde: float = 0.25:
	set(val):
		suavizado_borde = val
		emit_changed()
		changed.emit()

@export_range(1.0, 30.0, 0.5, "suffix:rad/s") var velocidad_giro_teclado: float = 10.0:
	set(val):
		velocidad_giro_teclado = val
		emit_changed()
		changed.emit()

@export_range(0.1, 10.0, 0.1, "suffix:s") var tiempo_inactividad_raton: float = 1.5:
	set(val):
		tiempo_inactividad_raton = val
		emit_changed()
		changed.emit()

@export_range(0.5, 50.0, 0.5, "suffix:px") var umbral_movimiento_raton: float = 4.0:
	set(val):
		umbral_movimiento_raton = val
		emit_changed()
		changed.emit()

# --- GRUPO HALO CORPORAL ---
@export_group("Halo Corporal")
@export var color_halo: Color = Color(0.8, 0.85, 1.0, 1.0):
	set(val):
		color_halo = val
		emit_changed()
		changed.emit()

@export_range(0.0, 2.0, 0.05) var energia_halo: float = 0.5:
	set(val):
		energia_halo = val
		emit_changed()
		changed.emit()

@export_range(20.0, 400.0, 5.0, "suffix:px") var radio_halo_px: float = 140.0:
	set(val):
		radio_halo_px = val
		emit_changed()
		changed.emit()

# --- GRUPO FLICKER Y PERTURBACIÓN ---
@export_group("Flicker y Perturbación")
@export_range(0.0, 1.0, 0.01) var intensidad_flicker: float = 0.10:
	set(val):
		intensidad_flicker = val
		emit_changed()
		changed.emit()

@export_range(1.0, 60.0, 1.0, "suffix:Hz") var frecuencia_flicker: float = 24.0:
	set(val):
		frecuencia_flicker = val
		emit_changed()
		changed.emit()

@export_range(50.0, 1000.0, 10.0, "suffix:px") var distancia_estres_px: float = 300.0:
	set(val):
		distancia_estres_px = val
		emit_changed()
		changed.emit()

@export_range(0.01, 2.0, 0.01, "suffix:pts/s") var tasa_estres_camara: float = 0.12:
	set(val):
		tasa_estres_camara = val
		emit_changed()
		changed.emit()

@export var flicker_forzado_debug: bool = false:
	set(val):
		flicker_forzado_debug = val
		emit_changed()
		changed.emit()


## Calcula el color ambiente mediante interpolación lineal de acuerdo al número de notas recolectadas.
func calcular_color_ambiente(notas: int) -> Color:
	if not modular_con_notas or max_notas_ambiente <= 0:
		return color_ambiente_inicial
	var factor: float = clampf(float(notas) / float(max_notas_ambiente), 0.0, 1.0)
	return color_ambiente_inicial.lerp(color_ambiente_final, factor)
