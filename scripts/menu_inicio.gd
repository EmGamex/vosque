@tool
class_name MenuInicio
extends Control

## Menú de inicio interactivo con efecto inmersivo de linterna en primera persona.
## Desplaza la vista para encuadrar y dar énfasis cinematográfico al árbol seleccionado,
## manteniendo pivotes unificados y margen amplio. Emite señales hacia el orquestador
## superior ("Signal Up") y tolera ejecución aislada.

signal jugar_solicitado
signal opciones_solicitado
signal creditos_solicitado

enum Opcion { OPCIONES, JUGAR, CREDITOS }

const ORDEN_OPCIONES: Array[Opcion] = [Opcion.OPCIONES, Opcion.JUGAR, Opcion.CREDITOS]

const COLOR_SELECCIONADO: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_NO_SELECCIONADO: Color = Color(1.0, 1.0, 1.0, 0.16)
const DURACION_TRANSICION: float = 0.35

# Factores de parallax para cada capa de fondo
const FACTOR_PARALLAX_DEGRADADO: float = 0.08
const FACTOR_PARALLAX_MONTANA_2: float = 0.22
const FACTOR_PARALLAX_MONTANA_1: float = 0.45

# Rotaciones parallax
const FACTOR_ROTACION_DEGRADADO: float = 0.06
const FACTOR_ROTACION_MONTANA_2: float = 0.18
const FACTOR_ROTACION_MONTANA_1: float = 0.35

@onready var _fondos: Node2D = $Fondos
@onready var _fondo_degradado: Sprite2D = $Fondos/FondoDegradado
@onready var _montana_2: Sprite2D = $Fondos/Montaña2
@onready var _montana_1: Sprite2D = $Fondos/Montaña1
@onready var _arboles_nodo: Node2D = $Arboles
@onready var _textos_nodo: Control = $Textos

@onready var _arbol_opciones: Sprite2D = $Arboles/ArbolOpciones
@onready var _arbol_jugar: Sprite2D = $Arboles/ArbolJugar
@onready var _arbol_creditos: Sprite2D = $Arboles/ArbolCreditos

@onready var _texto_opciones: Label = $Textos/TextoOpciones
@onready var _texto_jugar: Label = $Textos/TextoJugar
@onready var _texto_creditos: Label = $Textos/TextoCreditos

var _opcion_actual: Opcion = Opcion.JUGAR
var _datos_opciones: Dictionary = {}

var _tween: Tween
var _tiempo: float = 0.0
var _bloqueado: bool = false

# Offset y rotación base por la opción seleccionada
var _offset_base: Vector2 = Vector2.ZERO
var _rotacion_base: float = 0.0

# Posiciones y rotaciones base capturadas del editor para no sobreescribir la escena
var _pos_inicial_fondos: Vector2 = Vector2.ZERO
var _pos_inicial_degradado: Vector2 = Vector2.ZERO
var _pos_inicial_montana_2: Vector2 = Vector2.ZERO
var _pos_inicial_montana_1: Vector2 = Vector2.ZERO
var _pos_inicial_arboles: Vector2 = Vector2.ZERO
var _pos_inicial_textos: Vector2 = Vector2.ZERO


func _ready() -> void:
	_capturar_posiciones_iniciales()
	_inicializar_datos_opciones()
	_actualizar_seleccion(false)


func _capturar_posiciones_iniciales() -> void:
	if _fondos != null:
		_pos_inicial_fondos = _fondos.position
	if _fondo_degradado != null:
		_pos_inicial_degradado = _fondo_degradado.position
	if _montana_2 != null:
		_pos_inicial_montana_2 = _montana_2.position
	if _montana_1 != null:
		_pos_inicial_montana_1 = _montana_1.position
	if _arboles_nodo != null:
		_pos_inicial_arboles = _arboles_nodo.position
	if _textos_nodo != null:
		_pos_inicial_textos = _textos_nodo.position


func _inicializar_datos_opciones() -> void:
	_datos_opciones = {
		Opcion.OPCIONES: {
			"arbol": _arbol_opciones,
			"texto": _texto_opciones,
			"offset": Vector2(95.0, 0.0),
			"rotacion": deg_to_rad(1.2),
		},
		Opcion.JUGAR: {
			"arbol": _arbol_jugar,
			"texto": _texto_jugar,
			"offset": Vector2.ZERO,
			"rotacion": 0.0,
		},
		Opcion.CREDITOS: {
			"arbol": _arbol_creditos,
			"texto": _texto_creditos,
			"offset": Vector2(-95.0, 0.0),
			"rotacion": deg_to_rad(-1.2),
		},
	}


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not is_in_group("modo_test"):
		# No procesar animación continua en el editor de escenas salvo en pruebas
		return

	_tiempo += delta

	# Respiración orgánica / Temblor natural de linterna en mano
	var sway_x: float = sin(_tiempo * 1.5) * 2.5 + sin(_tiempo * 0.7) * 1.0
	var sway_y: float = cos(_tiempo * 1.9) * 1.8
	var sway_rot: float = sin(_tiempo * 1.2) * deg_to_rad(0.18)

	var offset_total: Vector2 = _offset_base + Vector2(sway_x, sway_y)
	var rotacion_total: float = _rotacion_base + sway_rot

	# Árboles y textos sincronizados en primer plano (relativos a su posición en el editor)
	if _arboles_nodo != null:
		_arboles_nodo.position = _pos_inicial_arboles + offset_total
		_arboles_nodo.rotation = rotacion_total

	if _textos_nodo != null:
		_textos_nodo.position = _pos_inicial_textos + offset_total
		_textos_nodo.rotation = rotacion_total

	# Parallax multicapa en los fondos relativo a sus posiciones en el editor
	if _fondos != null:
		_fondos.position = _pos_inicial_fondos

	if _fondo_degradado != null:
		_fondo_degradado.position = _pos_inicial_degradado + (offset_total * FACTOR_PARALLAX_DEGRADADO)
		_fondo_degradado.rotation = rotacion_total * FACTOR_ROTACION_DEGRADADO

	if _montana_2 != null:
		_montana_2.position = _pos_inicial_montana_2 + (offset_total * FACTOR_PARALLAX_MONTANA_2)
		_montana_2.rotation = rotacion_total * FACTOR_ROTACION_MONTANA_2

	if _montana_1 != null:
		_montana_1.position = _pos_inicial_montana_1 + (offset_total * FACTOR_PARALLAX_MONTANA_1)
		_montana_1.rotation = rotacion_total * FACTOR_ROTACION_MONTANA_1


func _unhandled_input(evento: InputEvent) -> void:
	if _bloqueado or Engine.is_editor_hint():
		return

	if evento.is_action_pressed("personaje-izquierda") or evento.is_action_pressed("ui_left"):
		_navegar(-1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("personaje-derecha") or evento.is_action_pressed("ui_right"):
		_navegar(1)
		get_viewport().set_input_as_handled()
	elif evento.is_action_pressed("ui_accept") or evento.is_action_pressed("personaje-salto"):
		_confirmar_opcion()
		get_viewport().set_input_as_handled()


## Fija el foco inicial en la opción Jugar y desbloquea el menú.
func enfocar() -> void:
	_opcion_actual = Opcion.JUGAR
	_bloqueado = false
	_actualizar_seleccion(false)


func _navegar(direccion: int) -> void:
	var total: int = ORDEN_OPCIONES.size()
	var indice_actual: int = ORDEN_OPCIONES.find(_opcion_actual)
	if indice_actual == -1:
		indice_actual = 0

	var nuevo_indice: int = (indice_actual + direccion + total) % total
	var nueva_opcion: Opcion = ORDEN_OPCIONES[nuevo_indice]
	if nueva_opcion != _opcion_actual:
		_opcion_actual = nueva_opcion
		_actualizar_seleccion(true)


func _actualizar_seleccion(animar: bool) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()

	var config_actual: Dictionary = _datos_opciones.get(_opcion_actual, {})
	var target_pos: Vector2 = config_actual.get("offset", Vector2.ZERO)
	var target_rot: float = config_actual.get("rotacion", 0.0)

	if animar and is_inside_tree():
		_tween = create_tween().set_parallel(true)
		_tween.tween_property(self, "_offset_base", target_pos, DURACION_TRANSICION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(self, "_rotacion_base", target_rot, DURACION_TRANSICION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		_offset_base = target_pos
		_rotacion_base = target_rot

	for opcion_clave: Opcion in _datos_opciones:
		var config: Dictionary = _datos_opciones[opcion_clave]
		var seleccionado: bool = (opcion_clave == _opcion_actual)
		var arbol: Sprite2D = config.get("arbol")
		var texto: Label = config.get("texto")

		if arbol == null or texto == null:
			continue

		arbol.visible = true

		var alpha_luz: float = 1.0 if seleccionado else 0.0
		var alpha_texto: float = COLOR_SELECCIONADO.a if seleccionado else COLOR_NO_SELECCIONADO.a
		var escala_texto: Vector2 = Vector2(1.08, 1.08) if seleccionado else Vector2(1.0, 1.0)

		if animar and is_inside_tree():
			_tween.tween_property(arbol, "modulate:a", alpha_luz, DURACION_TRANSICION)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween.tween_property(texto, "self_modulate:a", alpha_texto, DURACION_TRANSICION)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_tween.tween_property(texto, "scale", escala_texto, DURACION_TRANSICION)\
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			arbol.modulate.a = alpha_luz
			texto.self_modulate.a = alpha_texto
			texto.scale = escala_texto


func _confirmar_opcion() -> void:
	match _opcion_actual:
		Opcion.JUGAR:
			_bloqueado = true
			jugar_solicitado.emit()
		Opcion.OPCIONES:
			opciones_solicitado.emit()
		Opcion.CREDITOS:
			creditos_solicitado.emit()
