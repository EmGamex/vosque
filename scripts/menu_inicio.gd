@tool
class_name MenuInicio
extends Control

## Menú de inicio interactivo con sistema de cinemática modular y linterna en primera persona.
## Dispone de dos lienzos espaciales continuos en el espacio 2D:
## - Zona superior (Cielo/Presentación): Logotipo y aviso "Presiona ENTER para comenzar".
## - Zona inferior (Bosque/Menú): Tres árboles iluminados por linterna (Opciones, Jugar, Créditos).
## La transición está orquestada por Camera2D y AnimationPlayer, permitiendo aceleración (skip)
## instantánea sin conflictos con las oscilaciones orgánicas.

signal jugar_solicitado
signal opciones_solicitado
signal creditos_solicitado

enum EstadoMenu { PRESENTACION, CINEMATICA_BAJANDO, MENU_ACTIVO }
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

@export_group("Cinemática de Inicio")
## Determina si al arrancar o volver al menú se reproduce la pantalla de inicio en el cielo.
@export var habilitar_presentacion: bool = true
## Multiplicador de velocidad al pulsar tecla durante la bajada para saltarla casi al instante.
@export var multiplicador_velocidad_skip: float = 10.0



@onready var _camara: Camera2D = $CamaraMenu
@onready var _animador: AnimationPlayer = $AnimadorCinematica
@onready var _presentacion: Control = $Presentacion
@onready var _fondo_presentacion: Sprite2D = $Fondos/FondoPresentacion

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

var _estado: EstadoMenu = EstadoMenu.PRESENTACION
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
	_conectar_animador()
	iniciar_presentacion()
	_actualizar_seleccion(false)


func _conectar_animador() -> void:
	if _animador != null and not _animador.animation_finished.is_connected(_on_animacion_terminada):
		_animador.animation_finished.connect(_on_animacion_terminada)




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


## Configura el estado inicial del menú. Si la cinemática está habilitada,
## posiciona la cámara en el cielo e inicia el bucle de presentación.
func iniciar_presentacion() -> void:
	_opcion_actual = Opcion.JUGAR
	_bloqueado = false

	if not habilitar_presentacion or (Engine.is_editor_hint() and not is_in_group("modo_test")):
		_estado = EstadoMenu.MENU_ACTIVO
		if _camara != null:
			_camara.position = Vector2(540.0, 540.0)
		if _presentacion != null:
			_presentacion.modulate.a = 0.0
		if _fondo_presentacion != null:
			_fondo_presentacion.modulate.a = 0.0
		if _textos_nodo != null:
			_textos_nodo.modulate.a = 1.0
		return

	_estado = EstadoMenu.PRESENTACION
	if _camara != null:
		_camara.position = Vector2(540.0, -540.0)
	if _presentacion != null:
		_presentacion.modulate.a = 1.0
	if _fondo_presentacion != null:
		_fondo_presentacion.modulate.a = 1.0
	if _textos_nodo != null:
		_textos_nodo.modulate.a = 0.0

	if _animador != null and _animador.has_animation("esperando_inicio"):
		_animador.speed_scale = 1.0
		_animador.play("esperando_inicio")


## Dispara el paneo descendente de cámara hacia el bosque con fundido de fondos.
func iniciar_descenso() -> void:
	if _estado != EstadoMenu.PRESENTACION:
		return

	_estado = EstadoMenu.CINEMATICA_BAJANDO
	if _animador != null and _animador.has_animation("bajar_al_bosque"):
		_animador.speed_scale = 1.0
		_animador.play("bajar_al_bosque")
	else:
		# Fallback de seguridad si no existe la animación
		_on_animacion_terminada(&"bajar_al_bosque")


## Acelera la animación de descenso para aterrizar casi al instante.
func skipear_cinematica() -> void:
	if _estado == EstadoMenu.CINEMATICA_BAJANDO and _animador != null and _animador.is_playing():
		_animador.speed_scale = multiplicador_velocidad_skip


func _on_animacion_terminada(nombre: StringName) -> void:
	if nombre == &"bajar_al_bosque":
		_estado = EstadoMenu.MENU_ACTIVO
		_bloqueado = false
		if _animador != null:
			_animador.speed_scale = 1.0
		if _camara != null:
			_camara.position = Vector2(540.0, 540.0)
		if _textos_nodo != null:
			_textos_nodo.modulate.a = 1.0
		_actualizar_seleccion(false)


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
	if Engine.is_editor_hint():
		return

	match _estado:
		EstadoMenu.PRESENTACION:
			if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("personaje-salto"):
				iniciar_descenso()
				get_viewport().set_input_as_handled()

		EstadoMenu.CINEMATICA_BAJANDO:
			if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("personaje-salto"):
				skipear_cinematica()
				get_viewport().set_input_as_handled()

		EstadoMenu.MENU_ACTIVO:
			if _bloqueado:
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


## Fija el foco inicial y restablece la presentación cinematográfica al volver al menú.
func enfocar() -> void:
	iniciar_presentacion()
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
