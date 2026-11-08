@tool
class_name GestorIluminacionAmbiental
extends RefCounted

## Administrador del nodo CanvasModulate y transiciones de luz según la recolección de notas.

const RUTA_CONFIG_DEFECTO: String = "res://recursos/iluminacion/config_iluminacion_defecto.tres"


func inicializar_iluminacion(
	modulador: CanvasModulate,
	config: ConfiguracionIluminacion
) -> ConfiguracionIluminacion:
	var cfg_efectiva: ConfiguracionIluminacion = config
	if cfg_efectiva == null:
		if ResourceLoader.exists(RUTA_CONFIG_DEFECTO):
			cfg_efectiva = load(RUTA_CONFIG_DEFECTO) as ConfiguracionIluminacion
		else:
			cfg_efectiva = ConfiguracionIluminacion.new()

	if modulador != null and cfg_efectiva != null:
		modulador.color = cfg_efectiva.calcular_color_ambiente(0)

	return cfg_efectiva


func actualizar_iluminacion_ambiental(
	nodo_contexto: Node2D,
	modulador: CanvasModulate,
	config: ConfiguracionIluminacion,
	notas_recolectadas: int,
	duracion_transicion: float = 1.0
) -> void:
	if modulador == null or config == null:
		return

	var color_objetivo: Color = config.calcular_color_ambiente(notas_recolectadas)
	if duracion_transicion > 0.0 and nodo_contexto != null and nodo_contexto.is_inside_tree():
		var tween := nodo_contexto.create_tween()
		tween.tween_property(modulador, "color", color_objetivo, duracion_transicion)
	else:
		modulador.color = color_objetivo
