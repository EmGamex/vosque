@tool
class_name MenuInicio
extends Control

## Menú de inicio interactivo con sistema de cinemática modular y linterna en primera persona.
## Dispone de dos lienzos espaciales continuos en el espacio 2D:
## - Zona superior (Cielo/Presentación): Logotipo y aviso "Presiona ENTER para comenzar".
## - Zona inferior (Bosque/Menú): Tres árboles iluminados por linterna (Opciones, Jugar, Créditos).
## Orquestador/Fachada modular que delega en controladores especializados bajo res://scripts/menu_inicio/.

signal jugar_solicitado
signal opciones_solicitado
signal creditos_solicitado

# Constantes y Enums re-exportados para compatibilidad
const EstadoMenu = MenuConstantes.EstadoMenu
const Opcion = MenuConstantes.Opcion
const ORDEN_OPCIONES = MenuConstantes.ORDEN_OPCIONES
const COLOR_SELECCIONADO = MenuConstantes.COLOR_SELECCIONADO
const COLOR_NO_SELECCIONADO = MenuConstantes.COLOR_NO_SELECCIONADO
const DURACION_TRANSICION = MenuConstantes.DURACION_TRANSICION
const TEXTURA_OPCIONES = MenuConstantes.TEXTURA_OPCIONES
const TEXTURA_JUGAR = MenuConstantes.TEXTURA_JUGAR
const TEXTURA_CREDITOS = MenuConstantes.TEXTURA_CREDITOS
const TEXTURAS_OPCIONES = MenuConstantes.TEXTURAS_OPCIONES

# ==========================================
# CONFIGURACIÓN CINEMÁTICA Y PARTÍCULAS (INSPECTOR)
# ==========================================
@export_group("Cinemática de Inicio")
@export var habilitar_presentacion: bool:
	get: return _cinematica.habilitar_presentacion if _cinematica != null else true
	set(v): if _cinematica != null: _cinematica.habilitar_presentacion = v

@export_range(1.5, 10.0, 0.5) var multiplicador_velocidad_skip: float:
	get: return _cinematica.multiplicador_velocidad_skip if _cinematica != null else 4.0
	set(v): if _cinematica != null: _cinematica.multiplicador_velocidad_skip = v

@export_group("Partículas y Ambiente")
@export_subgroup("Estrellas")
@export var habilitar_estrellas: bool:
	get: return _particulas.habilitar_estrellas if _particulas != null else true
	set(v):
		if _particulas != null:
			_particulas.habilitar_estrellas = v
			_particulas.aplicar_configuracion_estrellas()

@export_range(5, 200, 1) var estrellas_cantidad: int:
	get: return _particulas.estrellas_cantidad if _particulas != null else 55
	set(v):
		if _particulas != null:
			_particulas.estrellas_cantidad = v
			_particulas.aplicar_configuracion_estrellas()

@export_range(0.5, 15.0, 0.1) var estrellas_lifetime: float:
	get: return _particulas.estrellas_lifetime if _particulas != null else 4.5
	set(v):
		if _particulas != null:
			_particulas.estrellas_lifetime = v
			_particulas.aplicar_configuracion_estrellas()

@export_range(0.1, 2.0, 0.05) var estrellas_escala_min: float:
	get: return _particulas.estrellas_escala_min if _particulas != null else 0.35
	set(v):
		if _particulas != null:
			_particulas.estrellas_escala_min = v
			_particulas.aplicar_configuracion_estrellas()

@export_range(0.2, 3.0, 0.05) var estrellas_escala_max: float:
	get: return _particulas.estrellas_escala_max if _particulas != null else 0.95
	set(v):
		if _particulas != null:
			_particulas.estrellas_escala_max = v
			_particulas.aplicar_configuracion_estrellas()

@export var estrellas_color: Color:
	get: return _particulas.estrellas_color if _particulas != null else Color.WHITE
	set(v):
		if _particulas != null:
			_particulas.estrellas_color = v
			_particulas.aplicar_configuracion_estrellas()

@export_range(0.0, 0.5, 0.01) var estrellas_factor_parallax: float:
	get: return _particulas.estrellas_factor_parallax if _particulas != null else 0.08
	set(v): if _particulas != null: _particulas.estrellas_factor_parallax = v

@export_range(0.0, 0.5, 0.01) var estrellas_factor_rotacion: float:
	get: return _particulas.estrellas_factor_rotacion if _particulas != null else 0.06
	set(v): if _particulas != null: _particulas.estrellas_factor_rotacion = v

@export_subgroup("Nubes y Bruma")
@export var habilitar_nubes: bool:
	get: return _particulas.habilitar_nubes if _particulas != null else true
	set(v):
		if _particulas != null:
			_particulas.habilitar_nubes = v
			_particulas.aplicar_configuracion_nubes()

@export_range(1, 30, 1) var nubes_cantidad: int:
	get: return _particulas.nubes_cantidad if _particulas != null else 10
	set(v):
		if _particulas != null:
			_particulas.nubes_cantidad = v
			_particulas.aplicar_configuracion_nubes()

@export_range(0.0, 100.0, 1.0) var nubes_velocidad_x: float:
	get: return _particulas.nubes_velocidad_x if _particulas != null else 18.0
	set(v):
		if _particulas != null:
			_particulas.nubes_velocidad_x = v
			_particulas.aplicar_configuracion_nubes()

@export_range(3.0, 40.0, 0.5) var nubes_lifetime: float:
	get: return _particulas.nubes_lifetime if _particulas != null else 16.0
	set(v):
		if _particulas != null:
			_particulas.nubes_lifetime = v
			_particulas.aplicar_configuracion_nubes()

@export_range(0.5, 6.0, 0.1) var nubes_escala_min: float:
	get: return _particulas.nubes_escala_min if _particulas != null else 2.0
	set(v):
		if _particulas != null:
			_particulas.nubes_escala_min = v
			_particulas.aplicar_configuracion_nubes()

@export_range(1.0, 8.0, 0.1) var nubes_escala_max: float:
	get: return _particulas.nubes_escala_max if _particulas != null else 4.2
	set(v):
		if _particulas != null:
			_particulas.nubes_escala_max = v
			_particulas.aplicar_configuracion_nubes()

@export var nubes_color: Color:
	get: return _particulas.nubes_color if _particulas != null else Color(0.75, 0.82, 0.95, 0.16)
	set(v):
		if _particulas != null:
			_particulas.nubes_color = v
			_particulas.aplicar_configuracion_nubes()

@export_range(0.0, 0.5, 0.01) var nubes_factor_parallax: float:
	get: return _particulas.nubes_factor_parallax if _particulas != null else 0.16
	set(v): if _particulas != null: _particulas.nubes_factor_parallax = v

@export_range(0.0, 0.5, 0.01) var nubes_factor_rotacion: float:
	get: return _particulas.nubes_factor_rotacion if _particulas != null else 0.12
	set(v): if _particulas != null: _particulas.nubes_factor_rotacion = v

# Sub-controladores
var _cinematica: MenuCinematica = MenuCinematica.new()
var _particulas: MenuParticulas = MenuParticulas.new()
var _parallax: MenuParallax = MenuParallax.new()
var _seleccion: MenuSeleccion = MenuSeleccion.new()

# Proxies de acceso para pruebas y compatibilidad interna
var _opcion_actual: Opcion:
	get: return _seleccion.opcion_actual if _seleccion != null else Opcion.JUGAR
	set(v): if _seleccion != null: _seleccion.opcion_actual = v

var _bloqueado: bool:
	get: return _seleccion.bloqueado if _seleccion != null else false
	set(v): if _seleccion != null: _seleccion.bloqueado = v

var _datos_opciones: Dictionary:
	get: return _seleccion.datos_opciones if _seleccion != null else {}

var _estado: EstadoMenu:
	get: return _cinematica.estado if _cinematica != null else EstadoMenu.PRESENTACION
	set(v): if _cinematica != null: _cinematica.estado = v

var _offset_base: Vector2:
	get: return _parallax.offset_base if _parallax != null else Vector2.ZERO
	set(v): if _parallax != null: _parallax.offset_base = v

var _rotacion_base: float:
	get: return _parallax.rotacion_base if _parallax != null else 0.0
	set(v): if _parallax != null: _parallax.rotacion_base = v

@warning_ignore("unused_private_class_variable")
var _pos_inicial_montana_1: Vector2:
	get: return _parallax.pos_inicial_montana_1 if _parallax != null else Vector2.ZERO

# Nodos
@onready var _camara: Camera2D = $CamaraMenu
@onready var _animador: AnimationPlayer = $AnimadorCinematica
@onready var _presentacion: Control = $Presentacion
@onready var _fondo_presentacion: Sprite2D = $Fondos/FondoPresentacion
@onready var _fondos: Node2D = $Fondos
@onready var _fondo_degradado: Sprite2D = $Fondos/FondoDegradado
@onready var _montana_2: Sprite2D = $Fondos/Montaña2
@onready var _montana_1: Sprite2D = $Fondos/Montaña1
@onready var _arboles_tercera: Sprite2D = $Fondos/ArbolesTerceraDivision
@onready var _arboles_segunda: Sprite2D = $Fondos/ArbolesSegundaDivision
@onready var _arboles_nodo: Node2D = $Arboles
@onready var _textos_nodo: Control = $Textos
@onready var _arbol_visual: Sprite2D = $Arboles/ArbolVisual
@onready var _particulas_estrellas: CPUParticles2D = $Fondos/ParticulasEstrellas
@onready var _particulas_nubes: CPUParticles2D = $Fondos/ParticulasNubes
@onready var _texto_opciones: Label = $Textos/TextoOpciones
@onready var _texto_jugar: Label = $Textos/TextoJugar
@onready var _texto_creditos: Label = $Textos/TextoCreditos


func _ready() -> void:
	if _textos_nodo != null:
		_textos_nodo.z_index = 10

	_cinematica.inicializar_nodos(_camara, _animador, _presentacion, _fondo_presentacion, _textos_nodo)
	_particulas.inicializar(self, _particulas_estrellas, _particulas_nubes)
	_parallax.inicializar_nodos(_fondos, _fondo_degradado, _montana_2, _montana_1, _arboles_tercera, _arboles_segunda, _arboles_nodo, _textos_nodo)
	_parallax.capturar_posiciones_iniciales(_particulas.obtener_particulas_estrellas(), _particulas.obtener_particulas_nubes())

	_seleccion.inicializar_nodos(self, _arbol_visual, _texto_opciones, _texto_jugar, _texto_creditos)
	_conectar_senales_submodulos()
	_conectar_animador()

	iniciar_presentacion()
	_actualizar_seleccion(false)


func _conectar_senales_submodulos() -> void:
	if not _seleccion.jugar_solicitado.is_connected(jugar_solicitado.emit):
		_seleccion.jugar_solicitado.connect(jugar_solicitado.emit)
	if not _seleccion.opciones_solicitado.is_connected(opciones_solicitado.emit):
		_seleccion.opciones_solicitado.connect(opciones_solicitado.emit)
	if not _seleccion.creditos_solicitado.is_connected(creditos_solicitado.emit):
		_seleccion.creditos_solicitado.connect(creditos_solicitado.emit)
	if not _seleccion.offset_rotacion_cambiado.is_connected(_on_offset_rotacion_cambiado):
		_seleccion.offset_rotacion_cambiado.connect(_on_offset_rotacion_cambiado)


func _conectar_animador() -> void:
	if _animador != null and not _animador.animation_finished.is_connected(_on_animacion_terminada):
		_animador.animation_finished.connect(_on_animacion_terminada)


func _on_offset_rotacion_cambiado(nuevo_offset: Vector2, nueva_rotacion: float, animar: bool) -> void:
	if not animar:
		_offset_base = nuevo_offset
		_rotacion_base = nueva_rotacion


func _animar_offset_rotacion(tween: Tween, target_pos: Vector2, target_rot: float) -> void:
	tween.tween_property(self, "_offset_base", target_pos, DURACION_TRANSICION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_rotacion_base", target_rot, DURACION_TRANSICION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func iniciar_presentacion() -> void:
	_seleccion.opcion_actual = Opcion.JUGAR
	_seleccion.bloqueado = false
	_cinematica.iniciar_presentacion(Engine.is_editor_hint(), is_in_group("modo_test"))


func iniciar_descenso() -> void:
	_cinematica.iniciar_descenso(_on_animacion_terminada)


func regresar_a_presentacion() -> void:
	if _estado != EstadoMenu.MENU_ACTIVO or _bloqueado:
		return
	_seleccion.bloqueado = true
	_seleccion.opcion_actual = Opcion.JUGAR
	_actualizar_seleccion(true)
	_cinematica.regresar_a_presentacion(_on_animacion_terminada)


func skipear_cinematica() -> void:
	_cinematica.skipear_cinematica()


func _on_animacion_terminada(nombre: StringName) -> void:
	var volvio_a_presentacion: bool = _cinematica.procesar_animacion_terminada(nombre)
	if nombre == &"bajar_al_bosque":
		_seleccion.bloqueado = false
		if volvio_a_presentacion:
			_seleccion.opcion_actual = Opcion.JUGAR
			_actualizar_seleccion(false)
		else:
			_actualizar_seleccion(false)


func enfocar() -> void:
	iniciar_presentacion()
	_actualizar_seleccion(false)


func _navegar(direccion: int) -> void:
	_seleccion.navegar(direccion)


func _actualizar_seleccion(animar: bool) -> void:
	_seleccion.actualizar_seleccion(animar)


func _confirmar_opcion() -> void:
	_seleccion.confirmar_opcion()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not is_in_group("modo_test"):
		return
	_parallax.procesar_balanceo(
		delta,
		_particulas.obtener_particulas_estrellas(),
		_particulas.obtener_particulas_nubes(),
		estrellas_factor_parallax,
		estrellas_factor_rotacion,
		nubes_factor_parallax,
		nubes_factor_rotacion
	)


func _unhandled_input(evento: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	match _estado:
		EstadoMenu.PRESENTACION:
			if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("personaje-salto"):
				iniciar_descenso()
				get_viewport().set_input_as_handled()

		EstadoMenu.CINEMATICA_BAJANDO, EstadoMenu.CINEMATICA_SUBIENDO:
			if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("personaje-salto"):
				skipear_cinematica()
				get_viewport().set_input_as_handled()

		EstadoMenu.MENU_ACTIVO:
			if _bloqueado:
				return

			if evento.is_action_pressed("ui_cancel"):
				regresar_a_presentacion()
				get_viewport().set_input_as_handled()
			elif evento.is_action_pressed("personaje-izquierda") or evento.is_action_pressed("ui_left"):
				_navegar(-1)
				get_viewport().set_input_as_handled()
			elif evento.is_action_pressed("personaje-derecha") or evento.is_action_pressed("ui_right"):
				_navegar(1)
				get_viewport().set_input_as_handled()
			elif evento.is_action_pressed("ui_accept") or evento.is_action_pressed("personaje-salto"):
				_confirmar_opcion()
				get_viewport().set_input_as_handled()
