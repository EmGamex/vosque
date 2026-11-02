@tool
class_name NieblaMaterialController
extends RefCounted

## Controlador especializado en la gestión y parametrización segura del ShaderMaterial de niebla.

var material_shader: ShaderMaterial


func inicializar_material(color_rect: ColorRect, es_editor: bool, previsualizar: bool, config: ConfiguracionNiebla) -> ShaderMaterial:
	if color_rect != null and color_rect.material is ShaderMaterial:
		# Duplicar el material para evitar contaminar el recurso .tres en disco
		material_shader = color_rect.material.duplicate() as ShaderMaterial
		color_rect.material = material_shader
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		actualizar_parametros_estaticos(config)
		if not es_editor or not previsualizar:
			actualizar_radio_interno(config.radio_despejado if config != null else 2.0)
			actualizar_densidad(0.0)
	return material_shader


func actualizar_parametros_estaticos(config: ConfiguracionNiebla) -> void:
	if material_shader == null or config == null:
		return

	material_shader.set_shader_parameter("cantidad_filas", config.cantidad_filas)
	material_shader.set_shader_parameter("radio_capsula", config.radio_capsula)
	material_shader.set_shader_parameter("largo_capsula", config.largo_capsula)
	material_shader.set_shader_parameter("espaciado_x", config.espaciado_horizontal)
	material_shader.set_shader_parameter("variacion_filas", config.variacion_filas)
	material_shader.set_shader_parameter("velocidad_desplazamiento", config.velocidad_desplazamiento)
	material_shader.set_shader_parameter("alternar_sentido_filas", config.alternar_sentido_filas)
	material_shader.set_shader_parameter("color_niebla", config.color_niebla)
	material_shader.set_shader_parameter("color_niebla_secundaria", config.color_niebla_secundaria)
	material_shader.set_shader_parameter("opacidad_velo_fondo", config.opacidad_velo_fondo)
	material_shader.set_shader_parameter("suavizado", config.difuminado_borde)


func actualizar_radio_interno(radio: float) -> void:
	if material_shader != null:
		material_shader.set_shader_parameter("radio_interno", radio)


func actualizar_densidad(densidad: float) -> void:
	if material_shader != null:
		material_shader.set_shader_parameter("densidad_global", densidad)


func actualizar_fase_desplazamiento(fase: float) -> void:
	if material_shader != null:
		material_shader.set_shader_parameter("fase_desplazamiento", fase)


func actualizar_foco(centro: Vector2, aspecto: float) -> void:
	if material_shader != null:
		material_shader.set_shader_parameter("centro", centro)
		material_shader.set_shader_parameter("aspecto", aspecto)


func aplicar_previsualizacion(activa: bool, densidad: float, config: ConfiguracionNiebla) -> void:
	if material_shader == null:
		return

	if activa:
		actualizar_densidad(densidad)
		actualizar_radio_interno(config.radio_cerrado if config != null else 0.15)
	else:
		actualizar_densidad(0.0)
		actualizar_radio_interno(config.radio_despejado if config != null else 2.0)
