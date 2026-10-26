class_name MenuSeleccion
extends RefCounted

## Administrador de selección de opciones, navegación e interpolación de shader/textos.

signal jugar_solicitado
signal opciones_solicitado
signal creditos_solicitado
signal offset_rotacion_cambiado(nuevo_offset: Vector2, nueva_rotacion: float, animar: bool)

var opcion_actual: MenuConstantes.Opcion = MenuConstantes.Opcion.JUGAR
var opcion_anterior: MenuConstantes.Opcion = MenuConstantes.Opcion.JUGAR
var bloqueado: bool = false
var datos_opciones: Dictionary = {}

var host_control: Control
var arbol_visual: Sprite2D
var material_arbol: ShaderMaterial
var texto_opciones: Label
var texto_jugar: Label
var texto_creditos: Label

var _tween: Tween


func inicializar_nodos(
	p_host: Control,
	p_arbol_visual: Sprite2D,
	p_texto_opciones: Label,
	p_texto_jugar: Label,
	p_texto_creditos: Label
) -> void:
	host_control = p_host
	arbol_visual = p_arbol_visual
	texto_opciones = p_texto_opciones
	texto_jugar = p_texto_jugar
	texto_creditos = p_texto_creditos

	if arbol_visual != null and arbol_visual.material is ShaderMaterial:
		material_arbol = arbol_visual.material as ShaderMaterial

	_inicializar_datos_opciones()


func _inicializar_datos_opciones() -> void:
	datos_opciones = {
		MenuConstantes.Opcion.OPCIONES: {
			"arbol": arbol_visual,
			"textura": MenuConstantes.TEXTURAS_OPCIONES[MenuConstantes.Opcion.OPCIONES],
			"texto": texto_opciones,
			"offset": Vector2(95.0, 0.0),
			"rotacion": deg_to_rad(1.2),
		},
		MenuConstantes.Opcion.JUGAR: {
			"arbol": arbol_visual,
			"textura": MenuConstantes.TEXTURAS_OPCIONES[MenuConstantes.Opcion.JUGAR],
			"texto": texto_jugar,
			"offset": Vector2.ZERO,
			"rotacion": 0.0,
		},
		MenuConstantes.Opcion.CREDITOS: {
			"arbol": arbol_visual,
			"textura": MenuConstantes.TEXTURAS_OPCIONES[MenuConstantes.Opcion.CREDITOS],
			"texto": texto_creditos,
			"offset": Vector2(-95.0, 0.0),
			"rotacion": deg_to_rad(-1.2),
		},
	}


func navegar(direccion: int) -> void:
	var total: int = MenuConstantes.ORDEN_OPCIONES.size()
	var indice_actual: int = MenuConstantes.ORDEN_OPCIONES.find(opcion_actual)
	if indice_actual == -1:
		indice_actual = 0

	var nuevo_indice: int = (indice_actual + direccion + total) % total
	var nueva_opcion: MenuConstantes.Opcion = MenuConstantes.ORDEN_OPCIONES[nuevo_indice]
	if nueva_opcion != opcion_actual:
		opcion_actual = nueva_opcion
		actualizar_seleccion(true)


func actualizar_seleccion(animar: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	var config_actual: Dictionary = datos_opciones.get(opcion_actual, {})
	var target_pos: Vector2 = config_actual.get("offset", Vector2.ZERO)
	var target_rot: float = config_actual.get("rotacion", 0.0)
	var nueva_textura: Texture2D = config_actual.get("textura")

	offset_rotacion_cambiado.emit(target_pos, target_rot, animar)

	if animar and host_control != null and host_control.is_inside_tree():
		_tween = host_control.create_tween().set_parallel(true)
		if host_control.has_method("_animar_offset_rotacion"):
			host_control.call("_animar_offset_rotacion", _tween, target_pos, target_rot)
	else:
		offset_rotacion_cambiado.emit(target_pos, target_rot, false)

	# Actualización tipográfica (escala y alpha de labels)
	for opcion_clave: MenuConstantes.Opcion in datos_opciones:
		var config: Dictionary = datos_opciones[opcion_clave]
		var seleccionado: bool = (opcion_clave == opcion_actual)
		var texto: Label = config.get("texto")
		if texto != null:
			var alpha_texto: float = MenuConstantes.COLOR_SELECCIONADO.a if seleccionado else MenuConstantes.COLOR_NO_SELECCIONADO.a
			var escala_texto: Vector2 = Vector2(1.08, 1.08) if seleccionado else Vector2(1.0, 1.0)
			if animar and host_control != null and host_control.is_inside_tree() and _tween != null:
				_tween.tween_property(texto, "self_modulate:a", alpha_texto, MenuConstantes.DURACION_TRANSICION)\
					.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				_tween.tween_property(texto, "scale", escala_texto, MenuConstantes.DURACION_TRANSICION)\
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				texto.self_modulate.a = alpha_texto
				texto.scale = escala_texto

	if arbol_visual == null:
		return

	if material_arbol == null and arbol_visual.material is ShaderMaterial:
		material_arbol = arbol_visual.material as ShaderMaterial

	if not animar or host_control == null or not host_control.is_inside_tree() or material_arbol == null:
		arbol_visual.texture = nueva_textura
		if material_arbol != null:
			material_arbol.set_shader_parameter("textura_anterior", nueva_textura)
			material_arbol.set_shader_parameter("progreso", 1.0)
		opcion_anterior = opcion_actual
		return

	# Transición limpia mediante Shader:
	var textura_previa: Texture2D = arbol_visual.texture
	if textura_previa == null:
		textura_previa = nueva_textura

	material_arbol.set_shader_parameter("textura_anterior", textura_previa)
	arbol_visual.texture = nueva_textura
	material_arbol.set_shader_parameter("progreso", 0.0)

	if _tween != null:
		_tween.tween_property(material_arbol, "shader_parameter/progreso", 1.0, MenuConstantes.DURACION_TRANSICION)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	opcion_anterior = opcion_actual


func confirmar_opcion() -> void:
	match opcion_actual:
		MenuConstantes.Opcion.JUGAR:
			bloqueado = true
			jugar_solicitado.emit()
		MenuConstantes.Opcion.OPCIONES:
			opciones_solicitado.emit()
		MenuConstantes.Opcion.CREDITOS:
			creditos_solicitado.emit()
